// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'l10n/app_localizations.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'database/database.dart';
import 'models/app_settings.dart';
import 'services/settings_service.dart';
import 'theme/night_theme.dart';
import 'services/map_tile_cache_service.dart';
import 'services/kmz_import_service.dart';
import 'services/mbtiles_import_service.dart';
import 'services/mbtiles_registry.dart';
import 'services/message_notification_service.dart';
import 'services/mesh_connection_service.dart';
import 'ble/ble_connection_manager.dart';
import 'ble/ble_service.dart';
import 'ble/reconnection_manager.dart';
import 'repositories/contact_repository.dart';
import 'repositories/channel_repository.dart';
import 'repositories/message_repository.dart';
import 'models/network_topology.dart';
import 'services/neighbor_tracker.dart';
import 'viewmodels/connection_viewmodel.dart';
import 'services/telemetry_send_service.dart';
import 'services/forwarding_policy_service.dart';
import 'services/contact_capability_service.dart';
import 'services/capability_publisher.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/direct_message_screen.dart';
import 'screens/channel_chat_screen.dart';
import 'screens/permissions_screen.dart';
import 'utils/notification_payload.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/deep_link_listener.dart';
import 'services/debug_log_service.dart';

// Global navigator key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Reference to the mesh connection service, set once created in main(). Used by
// the notification-response handler (which is registered before the service
// exists) to route the "Stop" notification action to a full stop.
MeshConnectionService? _meshServiceRef;

const bool isBetaBuild = bool.fromEnvironment('BETA');
const String _forceLocale = String.fromEnvironment('FORCE_LOCALE');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode || isBetaBuild) {
    installDebugLogInterceptor();
  }

  if (!kDebugMode && !isBetaBuild) {
    debugPrint = (String? message, {int? wrapWidth}) {};
    await runZonedGuarded(
      () async {
        await _runAppStartup();
      },
      (error, stackTrace) {
        // Intentionally suppress console logging in release builds.
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          // Intentionally suppress print() in release builds.
        },
      ),
    );
    return;
  }

  await _runAppStartup();
}

Future<void> _runAppStartup() async {
  print('🚀 TEAM Flutter starting...');
  print('✅ Flutter binding initialized');

  try {
    // Initialize the database
    print('📦 Initializing database...');
    final database = AppDatabase();
    print('✅ Database initialized');

    // Initialize SharedPreferences for settings
    print('⚙️ Loading settings...');
    final prefs = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('⚠️ SharedPreferences timeout!');
        throw Exception('SharedPreferences initialization timeout');
      },
    );
    final settingsService = SettingsService(prefs);
    print('✅ Settings loaded');

    // Initialize notification plugin
    print('🔔 Initializing notifications...');
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false, // Request later
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        // Persistent mesh-connection notification with a "Stop" action so the
        // user can kill a stuck reconnect. customDismissAction reports swipes.
        DarwinNotificationCategory(
          MeshConnectionService.iosNotificationCategoryId,
          actions: [
            DarwinNotificationAction.plain(
              MeshConnectionService.stopActionId,
              'Stop',
              options: {
                DarwinNotificationActionOption.foreground,
                DarwinNotificationActionOption.destructive,
              },
            ),
          ],
          options: {DarwinNotificationCategoryOption.customDismissAction},
        ),
      ],
    );
    const initializationSettingsLinux = LinuxInitializationSettings(
      defaultActionName: 'Open notification');
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      linux: initializationSettingsLinux,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) =>
          _handleNotificationTap(details, database),
    );
    print('✅ Notifications initialized');

    // Initialize message notification service
    print('📬 Initializing message notification service...');
    final messageNotificationService = MessageNotificationService(
      notifications: flutterLocalNotificationsPlugin,
      settings: settingsService,
    );
    await messageNotificationService.initialize();
    print('✅ Message notification service initialized');

    // Initialize BLE Connection Manager
    print('📡 Initializing BLE manager...');
    final bleManager = BleConnectionManager();
    // NOTE: iOS CoreBluetooth state restoration is intentionally NOT enabled
    // here. FlutterBluePlus.setOptions(restoreState: true) creates the
    // CBCentralManager, which surfaces the iOS Bluetooth / "find devices on
    // your local network" prompt. Calling it during startup made that prompt
    // appear *before* the permission screen. It is deferred to
    // _PermissionGate._startDeferredReconnect(), which runs after the gate and
    // still before the first BLE connect.
    print('✅ BLE manager initialized');

    // Initialize BLE Service
    print('🔧 Initializing BLE service...');
    final bleService = BleService(
      connectionManager: bleManager,
      database: database,
    );
    print('✅ BLE service initialized');

    // Initialize Reconnection Manager
    print('🔄 Initializing reconnection manager...');
    final reconnectionManager = ReconnectionManager(
      connectionManager: bleManager,
      settings: settingsService,
    );
    print('✅ Reconnection manager initialized');

    // Initialize Mesh Connection Service
    print('🌐 Initializing mesh connection service...');
    final meshConnectionService = MeshConnectionService(
      bleManager: bleManager,
      reconnectionManager: reconnectionManager,
      settings: settingsService,
      notifications: flutterLocalNotificationsPlugin,
    );
    _meshServiceRef = meshConnectionService;
    print('✅ Mesh connection service initialized');

    // Initialize Repositories
    print('📚 Initializing repositories...');
    final contactRepository = ContactRepository(
      bleManager: bleManager,
      contactsDao: database.contactsDao,
      settingsService: settingsService,
    );

    final channelRepository = ChannelRepository(
      bleManager: bleManager,
      channelsDao: database.channelsDao,
      settingsService: settingsService,
    );

    final contactCapabilityService = ContactCapabilityService(prefs);

    final networkTopology = NetworkTopology();
    final neighborTracker = NeighborTracker();

    final messageRepository = MessageRepository(
      bleManager: bleManager,
      bleService: bleService,
      database: database,
      messagesDao: database.messagesDao,
      channelsDao: database.channelsDao,
      contactsDao: database.contactsDao,
      contactRepository: contactRepository,
      notificationService: messageNotificationService,
      settingsService: settingsService,
      capabilityService: contactCapabilityService,
      networkTopology: networkTopology,
      neighborTracker: neighborTracker,
    );
    print('✅ Repositories initialized');

    // Initialize Connection ViewModel
    print('🎛️ Initializing connection view model...');
    final connectionViewModel = ConnectionViewModel(
      bleManager: bleManager,
      contactRepository: contactRepository,
      channelRepository: channelRepository,
      messageRepository: messageRepository,
      meshConnectionService: meshConnectionService,
      settingsService: settingsService,
      database: database,
    );
    print('✅ Connection view model initialized');

    // ForwardingPolicyService must be created first so TelemetrySendService
    // can read its currentNeedsForwarding / currentMaxPathObserved state.
    final forwardingPolicyService = ForwardingPolicyService(
      settings: settingsService,
      connectionViewModel: connectionViewModel,
      contactsDao: database.contactsDao,
      capabilityService: contactCapabilityService,
      messageRepository: messageRepository,
      database: database,
      networkTopology: networkTopology,
    )..start();

    // Initialize Telemetry sender (settings-driven, TEAM-compatible #T:)
    final telemetrySendService = TelemetrySendService(
      settings: settingsService,
      bleService: bleService,
      channelsDao: database.channelsDao,
      connectionViewModel: connectionViewModel,
      networkTopology: networkTopology,
      neighborTracker: neighborTracker,
      forwardingPolicy: forwardingPolicyService,
    )..start();

    final capabilityPublisher = CapabilityPublisher(
      settings: settingsService,
      connectionViewModel: connectionViewModel,
      bleService: bleService,
      contactsDao: database.contactsDao,
      channelsDao: database.channelsDao,
    )..start();

    // Startup reconnect behavior:
    // - Android: native foreground service owns BLE and reconnection.
    // - Others: keep existing Dart-based auto-reconnect.
    if (Platform.isAndroid) {
      if (settingsService.settings.serviceWasRunning &&
          !settingsService.settings.manualDisconnect) {
        await meshConnectionService.startService();
      }
      await bleManager.refreshStatus();
    } else {
      // iOS: defer auto-reconnect until after the permission gate.
      // Touching FlutterBluePlus here creates CBCentralManager which
      // triggers the iOS local-network prompt before the user has
      // granted permissions.  The permission gate calls
      // _startDeferredReconnect() once all permissions are granted.
    }

    // Launch app
    final mapTileCacheService = MapTileCacheService();

    runApp(
      TeamFlutterApp(
        database: database,
        settingsService: settingsService,
        bleManager: bleManager,
        contactRepository: contactRepository,
        channelRepository: channelRepository,
        messageRepository: messageRepository,
        connectionViewModel: connectionViewModel,
        messageNotificationService: messageNotificationService,
        meshConnectionService: meshConnectionService,
        reconnectionManager: reconnectionManager,
        mapTileCacheService: mapTileCacheService,
        telemetrySendService: telemetrySendService,
        forwardingPolicyService: forwardingPolicyService,
        contactCapabilityService: contactCapabilityService,
        capabilityPublisher: capabilityPublisher,
      ));
    print('✅ App launched');
  } catch (e, stackTrace) {
    print('❌ ERROR during initialization: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

/// Handle notification tap to navigate to specific chat
void _handleNotificationTap(
  NotificationResponse details,
  AppDatabase database) async {print('📬 Notification tapped: ${details.payload} action=${details.actionId}');

  // Mesh-connection "Stop" action button, or a swipe-dismiss of the persistent
  // mesh notification → fully stop the service (kills a stuck reconnect).
  // iOS reports a custom dismiss via the Apple dismiss action identifier.
  const iosDismissActionId = 'com.apple.UNNotificationDismissActionIdentifier';
  if (details.actionId == MeshConnectionService.stopActionId ||
      details.actionId == iosDismissActionId) {
    print('🛑 Mesh Stop action received — stopping service');
    await _meshServiceRef?.stopFromNotification();
    return;
  }

  final payload = NotificationPayload.fromJson(details.payload);
  if (payload == null) {
    print('⚠️ Failed to parse notification payload');
    return;
  }

  // A tap on the persistent mesh notification body just opens the app.
  if (payload.type == 'mesh_connection') {
    print('📬 Mesh connection notification tapped — opening app');
    return;
  }

  print('📬 Payload type: ${payload.type}, data: ${payload.data}');

  // Wait for navigator to be ready
  await Future.delayed(const Duration(milliseconds: 100));

  final context = navigatorKey.currentContext;
  if (context == null) {
    print('⚠️ Navigator context not available');
    return;
  }

  try {
    if (payload.type == 'direct_message') {
      // Navigate to direct message screen
      final contactHash = payload.data['contactHash'] as int?;
      if (contactHash == null) return;

      final contact = await database.contactsDao.getContactByHash(contactHash);
      if (contact != null) {
        if (contact.isRepeater) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,)!.directMessagesDisabledForRepeaters),
            ),
          );
          return;
        }
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => DirectMessageScreen(contact: contact),
          ),
          (route) => route.isFirst,
        );
        print('✅ Navigated to DM with ${contact.name}');
      }
    } else if (payload.type == 'channel_message') {
      // Navigate to channel chat screen
      final channelHash = payload.data['channelHash'] as int?;
      if (channelHash == null) return;

      final channel = await database.channelsDao.getChannelByHash(channelHash);
      if (channel != null) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ChannelChatScreen(channel: channel),
          ),
          (route) => route.isFirst,
        );
        print('✅ Navigated to channel ${channel.name}');
      }
    } else if (payload.type == 'waypoint') {
      // TODO: Navigate to waypoint screen
      print('📍 Waypoint navigation not yet implemented');
    }
  } catch (e) {
    print('❌ Error navigating from notification: $e');
  }
}

class TeamFlutterApp extends StatelessWidget {
  final AppDatabase database;
  final SettingsService settingsService;
  final BleConnectionManager bleManager;
  final ContactRepository contactRepository;
  final ChannelRepository channelRepository;
  final MessageRepository messageRepository;
  final ConnectionViewModel connectionViewModel;
  final MessageNotificationService messageNotificationService;
  final MeshConnectionService meshConnectionService;
  final ReconnectionManager reconnectionManager;
  final MapTileCacheService mapTileCacheService;
  final TelemetrySendService telemetrySendService;
  final ForwardingPolicyService forwardingPolicyService;
  final ContactCapabilityService contactCapabilityService;
  final CapabilityPublisher capabilityPublisher;

  const TeamFlutterApp({
    super.key,
    required this.database,
    required this.settingsService,
    required this.bleManager,
    required this.contactRepository,
    required this.channelRepository,
    required this.messageRepository,
    required this.connectionViewModel,
    required this.messageNotificationService,
    required this.meshConnectionService,
    required this.reconnectionManager,
    required this.mapTileCacheService,
    required this.telemetrySendService,
    required this.forwardingPolicyService,
    required this.contactCapabilityService,
    required this.capabilityPublisher,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Database provider
        Provider<AppDatabase>.value(value: database),

        // Offline map tile cache
        Provider<MapTileCacheService>.value(value: mapTileCacheService),

        // KMZ imported map service
        Provider<KmzImportService>(create: (_) => KmzImportService()),

        // MBTiles imported map service, plus the registry that owns the open
        // SQLite handles so the map and manage screens share them.
        Provider<MbtilesImportService>(create: (_) => MbtilesImportService()),
        Provider<MbtilesRegistry>(
          create: (_) => MbtilesRegistry(),
          dispose: (_, registry) => registry.closeAll(),
        ),

        // Settings service provider
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),

        // BLE Connection Manager
        ChangeNotifierProvider<BleConnectionManager>.value(value: bleManager),

        // Repositories
        Provider<ContactRepository>.value(value: contactRepository),
        Provider<ChannelRepository>.value(value: channelRepository),
        Provider<MessageRepository>.value(value: messageRepository),

        // Connection ViewModel
        ChangeNotifierProvider<ConnectionViewModel>.value(
          value: connectionViewModel),

        // Services
        Provider<MessageNotificationService>.value(
          value: messageNotificationService),
        ChangeNotifierProvider<MeshConnectionService>.value(
          value: meshConnectionService),
        ChangeNotifierProvider<ReconnectionManager>.value(
          value: reconnectionManager),

        // Telemetry sender (no UI; driven by settings)
        ChangeNotifierProvider<TelemetrySendService>.value(
          value: telemetrySendService,
        ),

        // Forwarding policy manager (no UI; runs while tracking/camp mode are active)
        ChangeNotifierProvider<ForwardingPolicyService>.value(
          value: forwardingPolicyService),

        // Peer capability tracking (populated from #CAP: channel messages)
        ChangeNotifierProvider<ContactCapabilityService>.value(
          value: contactCapabilityService),

        // Capability publisher (sends #CAP: on discovery and settings change)
        Provider<CapabilityPublisher>.value(value: capabilityPublisher),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) {
          final appTheme = settings.settings.appTheme;
          final isNighttime = appTheme == AppThemeMode.nighttime;
          SystemChrome.setEnabledSystemUIMode(
            isNighttime ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
          );
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'TEAM Flutter',
            locale: _forceLocale.isNotEmpty ? Locale(_forceLocale) : null,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.grey,
              ),
              useMaterial3: true,
            ),
            darkTheme: isNighttime
                ? _nighttimeTheme() : ThemeData(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: Colors.blue,
                      brightness: Brightness.dark,
                    ),
                    appBarTheme: const AppBarTheme(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    bottomNavigationBarTheme:
                        const BottomNavigationBarThemeData(
                          selectedItemColor: Colors.blue,
                          unselectedItemColor: Colors.grey,
                        ),
                    useMaterial3: true,
                  ),
            themeMode: switch (appTheme) {
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
              AppThemeMode.nighttime => ThemeMode.dark,
              _ => ThemeMode.system,
            },
            builder: (context, child) => Listener(
              onPointerDown: (event) {
                if (event.buttons & kBackMouseButton != 0) {
                  navigatorKey.currentState?.maybePop();
                }
              },
              child: child!,
            ),
            home: const DeepLinkListener(child: _PermissionGate(),
            ),
          );
        },
      ),
    );
  }
}

ThemeData _nighttimeTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: NightColors.primary,
    brightness: Brightness.dark,
  );
  final scheme = base.copyWith(
    surface: NightColors.surfaceLow,
    onSurface: NightColors.onSurface,
    surfaceVariant: NightColors.surfaceHigh,
    onSurfaceVariant: NightColors.onSurfaceVariant,
    surfaceContainerLowest: NightColors.background,
    surfaceContainerLow: NightColors.surfaceLow,
    surfaceContainer: NightColors.surface,
    surfaceContainerHigh: const Color(0xFF170000),
    surfaceContainerHighest: NightColors.surfaceHigh,
    primary: NightColors.primary,
    onPrimary: NightColors.onPrimary,
    primaryContainer: NightColors.dim,
    onPrimaryContainer: NightColors.onSurface,
    secondary: const Color(0xFF6B0000),
    onSecondary: NightColors.onSurface,
    outline: NightColors.dim,
    outlineVariant: NightColors.dimmer,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: NightColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: NightColors.appBarBg,
      foregroundColor: NightColors.onSurface,
    ),
    iconTheme: const IconThemeData(color: NightColors.onSurface),
    hintColor: NightColors.onSurfaceVariant,
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? NightColors.primary
            : NightColors.dimmest,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? NightColors.onSurface
            : NightColors.dim),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : NightColors.dim,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: NightColors.primary,
      inactiveTrackColor: NightColors.dimmest,
      thumbColor: NightColors.primary,
      overlayColor: Color(0x1F8B0000),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: NightColors.dim),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: NightColors.primary, width: 2),
      ),
      disabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: NightColors.dimmer),
      ),
      labelStyle: TextStyle(color: NightColors.onSurfaceVariant),
      hintStyle: TextStyle(color: NightColors.dim),
    ),
    disabledColor: NightColors.dimmer,
    dialogTheme: const DialogThemeData(
      backgroundColor: NightColors.surface),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: NightColors.appBarBg,
      selectedItemColor: NightColors.onSurface,
      unselectedItemColor: NightColors.dim,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: NightColors.surfaceHigh,
      foregroundColor: NightColors.onSurface,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: NightColors.surfaceHigh,
      contentTextStyle: TextStyle(color: NightColors.onSurface),
      actionTextColor: NightColors.primary,
    ),
    useMaterial3: true,
  );
}

/// Permission Gate - Shows permissions screen or main app based on permission status
class _PermissionGate extends StatefulWidget {
  const _PermissionGate();

  @override
  State<_PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<_PermissionGate>
    with WidgetsBindingObserver {
  bool _permissionsGranted = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permissions when the user returns to the app — covers the case
    // where they left to grant (or re-grant) permissions in Android Settings.
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  /// Check if all required permissions are already granted
  Future<void> _checkPermissions() async {
    // Desktop platforms don't use runtime permissions
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() {
        _permissionsGranted = true;
        _isChecking = false;
      });
      return;
    }

    try {
      bool allGranted = true;

      // Check Bluetooth permissions
      if (Platform.isAndroid) {
        final bluetoothScan = await Permission.bluetoothScan.status;
        final bluetoothConnect = await Permission.bluetoothConnect.status;
        if (!bluetoothScan.isGranted || !bluetoothConnect.isGranted) {
          allGranted = false;
        }
      } else if (Platform.isIOS) {
        final bluetooth = await Permission.bluetooth.status;
        if (!bluetooth.isGranted) {
          allGranted = false;
        }
      }

      // Check Location permission
      final location = await Permission.location.status;
      if (!location.isGranted) {
        allGranted = false;
      }

      // Check Notification permission
      final notification = await Permission.notification.status;
      if (!notification.isGranted) {
        allGranted = false;
      }

      debugPrint(
        '🔐 Permissions check: ${allGranted ? "✅ Granted" : "❌ Not granted"}');

      if (allGranted) {
        unawaited(_startDeferredReconnect());
      }

      setState(() {
        _permissionsGranted = allGranted;
        _isChecking = false;
      });
    } catch (e) {
      debugPrint('⚠️ Error checking permissions: $e');
      setState(() {
        _permissionsGranted = false;
        _isChecking = false;
      });
    }
  }

  void _onPermissionsGranted() {
    unawaited(_startDeferredReconnect());
    setState(() {
      _permissionsGranted = true;
    });
  }

  /// Enable deferred iOS BLE options and start auto-reconnect, both of which
  /// were deferred until after the permission gate.
  Future<void> _startDeferredReconnect() async {
    if (Platform.isAndroid) return; // Android native service handles reconnect

    // iOS: enable CoreBluetooth state restoration now (deferred from startup so
    // the OS Bluetooth / Local Network prompt doesn't appear before the
    // permission screen). This creates the CBCentralManager, so it must run
    // before the first BLE connect below — but only now that we're past the
    // gate. Applied regardless of whether an auto-reconnect follows, so a later
    // manual connect is also covered.
    final bleManager = context.read<BleConnectionManager>();
    await bleManager.enableIosStateRestoration();
    if (!mounted) return;

    final settings = context.read<SettingsService>();
    if (!settings.settings.serviceWasRunning ||
        settings.settings.manualDisconnect) {
      return;
    }
    final lastDevice = settings.settings.lastConnectedDevice;
    if (lastDevice == null || lastDevice.isEmpty) return;

    debugPrint('🔄 Deferred reconnect: starting auto-reconnect to $lastDevice');
    final meshService = context.read<MeshConnectionService>();
    final reconnection = context.read<ReconnectionManager>();
    meshService.startService();
    reconnection.startReconnecting(lastDevice);
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Show loading screen while checking permissions
      return const Scaffold(
        body:Center(
          child: CircularProgressIndicator(),
          ),
          );
    }

    if (!_permissionsGranted) {
      // Show permissions screen if not granted
      return PermissionsScreen(
        onPermissionsGranted: _onPermissionsGranted,
        );
    }

    // Show main app if permissions granted
    return const MainNavigationScreen();
  }
}
