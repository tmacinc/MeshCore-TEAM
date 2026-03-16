// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'database/database.dart';
import 'services/settings_service.dart';
import 'services/map_tile_cache_service.dart';
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

// Global navigator key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kDebugMode) {
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

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false, // Request later
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
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
    );
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
      if (settingsService.settings.serviceWasRunning &&
          !settingsService.settings.manualDisconnect) {
        final lastDevice = settingsService.settings.lastConnectedDevice;
        if (lastDevice != null && lastDevice.isNotEmpty) {
          print(
              '🔄 Service was running - starting auto-reconnect to $lastDevice');
          await meshConnectionService.startService();
          await reconnectionManager.startReconnecting(lastDevice);
        }
      }
    }

    // Launch app
    final mapTileCacheService = MapTileCacheService();

    runApp(TeamFlutterApp(
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
    NotificationResponse details, AppDatabase database) async {
  print('📬 Notification tapped: ${details.payload}');

  final payload = NotificationPayload.fromJson(details.payload);
  if (payload == null) {
    print('⚠️ Failed to parse notification payload');
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
            const SnackBar(
              content: Text('Direct messages are disabled for repeaters'),
            ),
          );
          return;
        }
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DirectMessageScreen(contact: contact),
          ),
        );
        print('✅ Navigated to DM with ${contact.name}');
      }
    } else if (payload.type == 'channel_message') {
      // Navigate to channel chat screen
      final channelHash = payload.data['channelHash'] as int?;
      if (channelHash == null) return;

      final channel = await database.channelsDao.getChannelByHash(channelHash);
      if (channel != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChannelChatScreen(channel: channel),
          ),
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
            value: telemetrySendService),

        // Forwarding policy manager (no UI; runs while tracking/camp mode are active)
        ChangeNotifierProvider<ForwardingPolicyService>.value(
            value: forwardingPolicyService),

        // Peer capability tracking (populated from #CAP: channel messages)
        ChangeNotifierProvider<ContactCapabilityService>.value(
            value: contactCapabilityService),

        // Capability publisher (sends #CAP: on discovery and settings change)
        Provider<CapabilityPublisher>.value(value: capabilityPublisher),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'TEAM Flutter',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const DeepLinkListener(
          child: _PermissionGate(),
        ),
      ),
    );
  }
}

/// Permission Gate - Shows permissions screen or main app based on permission status
class _PermissionGate extends StatefulWidget {
  const _PermissionGate();

  @override
  State<_PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<_PermissionGate> {
  bool _permissionsGranted = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  /// Check if all required permissions are already granted
  Future<void> _checkPermissions() async {
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
    setState(() {
      _permissionsGranted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Show loading screen while checking permissions
      return const Scaffold(
        body: Center(
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
