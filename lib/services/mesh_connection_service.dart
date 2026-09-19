// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:meshcore_team/ble/ble_connection_manager.dart';
import 'package:meshcore_team/l10n/app_localizations.dart';
import 'package:meshcore_team/models/app_language.dart';
import 'package:meshcore_team/ble/reconnection_manager.dart';
import 'package:meshcore_team/ble/reconnection_state.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/services/foreground_task_handler.dart';
import 'package:meshcore_team/utils/notification_payload.dart';

/// Mesh Connection Service
/// Manages foreground service, wake lock, and auto-reconnection
/// Matches Android MeshConnectionService functionality
class MeshConnectionService extends ChangeNotifier {
  final BleConnectionManager _bleManager;
  final ReconnectionManager _reconnectionManager;
  final SettingsService _settings;
  final FlutterLocalNotificationsPlugin? _notifications;

  static const int _connectionNotificationId = 1001;

  /// iOS notification category carrying the "Stop" action, registered at app
  /// init in main.dart via [DarwinNotificationCategory].
  static const String iosNotificationCategoryId = 'mesh_connection';

  /// Action id for the notification "Stop" button.
  static const String stopActionId = 'stop_mesh';

  bool _isServiceRunning = false;
  bool _isWakeLockEnabled = false;
  ReceivePort? _receivePort;

  /// Whether the persistent iOS notification is currently visible. Used so we
  /// only alert (banner) on the first show and update quietly afterwards,
  /// avoiding the reconnect-retry notification spam.
  bool _iosNotificationVisible = false;

  /// Stored lifecycle listener so it can be added once and removed on stop,
  /// instead of leaking an anonymous closure on every startService().
  VoidCallback? _lifecycleListener;

  bool get isServiceRunning => _isServiceRunning;
  bool get isWakeLockEnabled => _isWakeLockEnabled;

  /// True while the background service is running but the companion is not
  /// connected — i.e. an auto-reconnect is in progress (or waiting to retry).
  /// The UI uses this to offer a "Stop reconnecting" affordance.
  bool get isReconnecting => _isServiceRunning && !_bleManager.isConnected;

  MeshConnectionService({
    required BleConnectionManager bleManager,
    required ReconnectionManager reconnectionManager,
    required SettingsService settings,
    FlutterLocalNotificationsPlugin? notifications,
  })  : _bleManager = bleManager,
        _reconnectionManager = reconnectionManager,
        _settings = settings,
        _notifications = notifications {
    _initialize();
  }

  /// Strings for the user's language, resolved without a [BuildContext].
  ///
  /// The foreground-service notification is built far from the widget tree,
  /// so it looks the locale up the same way [MessageNotificationService] does.
  AppLocalizations get _l10n =>
      lookupAppLocalizations(AppLanguage.localeFor(_settings.settings.localeCode));

  /// Initialize the service
  Future<void> _initialize() async {
    debugPrint('[MeshService] Initializing...');

    // Initialize foreground task
    if (Platform.isIOS) {
      await _initializeForegroundTask();
    }

    // Monitor connection state changes via ChangeNotifier
    _bleManager.addListener(_onConnectionStateChanged);

    // Monitor reconnection state changes via ChangeNotifier
    _reconnectionManager.addListener(_onReconnectionStateChanged);

    debugPrint('[MeshService] ✅ Initialized');
  }

  /// Initialize flutter_foreground_task
  Future<void> _initializeForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'mesh_connection_channel',
        channelName: _l10n.meshConnectionChannelName,
        channelDescription: _l10n.meshConnectionChannelDescription,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000, // 5 seconds
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true, // CRITICAL for keeping CPU awake
        allowWifiLock: false,
      ),
    );

    debugPrint('[MeshService] Foreground task initialized');
  }

  /// Start the foreground service
  Future<void> startService() async {
    if (_isServiceRunning) {
      debugPrint('[MeshService] Service already running');
      return;
    }

    debugPrint('[MeshService] Starting foreground service...');

    try {
      if (Platform.isAndroid) {
        await _bleManager.startNativeService();
        _isServiceRunning = true;
        await _settings.setServiceWasRunning(true);
        debugPrint('[MeshService] ✅ Native BLE service started (Android)');
        notifyListeners();
        return;
      }

      // Start foreground task
      final started = await FlutterForegroundTask.startService(
        notificationTitle: _l10n.meshNetworkActive,
        notificationText: _l10n.connectingToCompanionDevice,
        callback: foregroundTaskEntryPoint,
      );

      if (!started) {
        debugPrint('[MeshService] ❌ Failed to start foreground task');
        return;
      }

      // Set up receive port for messages from foreground task
      _receivePort = FlutterForegroundTask.receivePort;
      _receivePort?.listen((message) {
        _handleForegroundTaskMessage(message);
      });

      // Enable wake lock
      await _enableWakeLock();

      // Mark service as running
      _isServiceRunning = true;
      await _settings.setServiceWasRunning(true);

      // Show initial iOS connection notification
      if (Platform.isIOS) {
        _updateNotification(_bleManager.state, _reconnectionManager.state);
      }

      // Start monitoring connection/reconnection state
      _monitorServiceLifecycle();

      debugPrint('[MeshService] ✅ Foreground service started');
      notifyListeners();
    } catch (e) {
      debugPrint('[MeshService] ❌ Error starting service: $e');
    }
  }

  /// Stop the foreground service
  Future<void> stopService() async {
    if (!_isServiceRunning) {
      debugPrint('[MeshService] Service not running');
      // On iOS there's no foreground service, but the BLE connection
      // may still be active (or a reconnect loop may be running). Tear it
      // down directly.
      _reconnectionManager.stopReconnecting();
      if (_bleManager.isConnected) {
        debugPrint('[MeshService] BLE still connected — disconnecting');
        await _bleManager.disconnect();
      }
      if (Platform.isIOS) {
        await _bleManager.disableIosStateRestoration();
        await _removeIOSConnectionNotification();
      }
      return;
    }

    debugPrint('[MeshService] Stopping foreground service...');

    try {
      if (Platform.isAndroid) {
        await _bleManager.stopNativeService();
        _isServiceRunning = false;
        await _settings.setServiceWasRunning(false);
        debugPrint('[MeshService] ✅ Native BLE service stopped (Android)');
        notifyListeners();
        return;
      }

      // Disable wake lock
      await _disableWakeLock();

      // Stop reconnection
      _reconnectionManager.stopReconnecting();

      // Stop monitoring so we don't leak listeners across start/stop cycles
      _stopMonitoringServiceLifecycle();

      // Disconnect BLE
      if (_bleManager.isConnected) {
        await _bleManager.disconnect();
      }

      // Opt back out of iOS state restoration so the OS won't relaunch the app
      // to restore the BLE session after this explicit stop.
      if (Platform.isIOS) {
        await _bleManager.disableIosStateRestoration();
      }

      // Stop foreground task
      await FlutterForegroundTask.stopService();

      // Remove iOS connection notification
      if (Platform.isIOS) {
        await _removeIOSConnectionNotification();
      }

      // Mark service as not running
      _isServiceRunning = false;
      await _settings.setServiceWasRunning(false);

      _receivePort?.close();
      _receivePort = null;

      debugPrint('[MeshService] ✅ Foreground service stopped');
      notifyListeners();
    } catch (e) {
      debugPrint('[MeshService] ❌ Error stopping service: $e');
    }
  }

  /// Enable wake lock
  Future<void> _enableWakeLock() async {
    if (_isWakeLockEnabled) return;

    try {
      await WakelockPlus.enable();
      _isWakeLockEnabled = true;
      debugPrint('[MeshService] 🔄 Wake lock enabled (indefinite)');
    } catch (e) {
      debugPrint('[MeshService] ❌ Failed to enable wake lock: $e');
    }
  }

  /// Disable wake lock
  Future<void> _disableWakeLock() async {
    if (!_isWakeLockEnabled) return;

    try {
      // wakelock_plus clears FLAG_KEEP_SCREEN_ON on disable; skip if our setting owns it
      if (!_settings.settings.keepScreenOnLock) {
        await WakelockPlus.disable();
      }
      _isWakeLockEnabled = false;
      debugPrint('[MeshService] 🔄 Wake lock disabled');
    } catch (e) {
      debugPrint('[MeshService] ❌ Failed to disable wake lock: $e');
    }
  }

  /// Handle connection state changes
  BleConnectionState _previousConnectionState = BleConnectionState.disconnected;

  void _onConnectionStateChanged() {
    final state = _bleManager.state;
    debugPrint('[MeshService] Connection state changed: $state');

    // Update notification based on state
    _updateNotification(state, _reconnectionManager.state);

    switch (state) {
      case BleConnectionState.connected:
        // Stop reconnection when connected
        _reconnectionManager.stopReconnecting();

        // Save device address and clear manual disconnect immediately on connect
        // so _handleDisconnection has a target even if sync never completes.
        final deviceAddress = _bleManager.deviceAddress;
        if (deviceAddress != null && deviceAddress.isNotEmpty) {
          debugPrint('[MeshService] Saving last connected device: $deviceAddress');
          _settings.setLastConnectedDevice(deviceAddress);
          _settings.setManualDisconnect(false);
        }

        // Enable wake lock
        _enableWakeLock();
        break;

      case BleConnectionState.disconnected:
        // Only auto-reconnect if we were previously connected (not mid-connect).
        // A disconnect during connecting is a failed attempt, not a drop.
        if (_previousConnectionState == BleConnectionState.connected) {
          _handleDisconnection();
        }
        break;

      default:
        break;
    }

    _previousConnectionState = state;

    // Notify UI so affordances tied to connection/reconnecting state rebuild.
    notifyListeners();
  }

  /// Handle reconnection state changes
  void _onReconnectionStateChanged() {
    final reconnectionState = _reconnectionManager.state;
    debugPrint('[MeshService] Reconnection state changed: $reconnectionState');

    // Update notification
    _updateNotification(_bleManager.state, reconnectionState);

    // Notify UI so the "Stop reconnecting" affordance rebuilds.
    notifyListeners();
  }

  /// Handle disconnection and start auto-reconnect if appropriate
  Future<void> _handleDisconnection() async {
    debugPrint('[MeshService] Handling disconnection...');

    // Check manual disconnect flag
    if (_settings.settings.manualDisconnect) {
      debugPrint('[MeshService] Manual disconnect - not auto-reconnecting');
      return;
    }

    // Check auto-reconnect enabled
    if (!_settings.settings.autoReconnectEnabled) {
      debugPrint('[MeshService] Auto-reconnect disabled');
      return;
    }

    // Get last connected device
    final lastDevice = _settings.settings.lastConnectedDevice;
    if (lastDevice == null || lastDevice.isEmpty) {
      debugPrint('[MeshService] No last connected device');
      return;
    }

    // Start reconnection
    debugPrint('[MeshService] Starting auto-reconnect to $lastDevice');
    await _reconnectionManager.startReconnecting(lastDevice);
  }

  /// Update foreground notification based on connection and reconnection state
  void _updateNotification(
    BleConnectionState connectionState,
    ReconnectionState reconnectionState,
  ) {
    if (!_isServiceRunning) return;
    // Android handles its own notification via native MeshBleService
    if (Platform.isAndroid) return;

    final l10n = _l10n;
    String title = l10n.meshNetwork;
    String text = '';

    if (reconnectionState != ReconnectionState.idle) {
      // Reconnection in progress - show device name
      final deviceName =
          _settings.settings.lastConnectedDevice ?? l10n.meshDevice;
      title = l10n.meshNetworkReconnecting;
      text = l10n.reconnectingToDevice(deviceName);
    } else {
      // Normal connection state
      switch (connectionState) {
        case BleConnectionState.connected:
          final deviceName = _bleManager.deviceName ?? l10n.meshDevice;
          title = l10n.meshNetworkActive;
          text = l10n.connectedToDevice(deviceName);
          break;
        case BleConnectionState.connecting:
          title = l10n.meshNetworkConnecting;
          text = l10n.establishingConnection;
          break;
        case BleConnectionState.disconnected:
          title = l10n.meshNetworkDisconnected;
          text = l10n.deviceDisconnected;
          break;
        case BleConnectionState.scanning:
          title = l10n.meshNetworkScanning;
          text = l10n.searchingForDevices;
          break;
        case BleConnectionState.error:
          title = l10n.meshNetworkError;
          text = _bleManager.errorMessage ?? l10n.connectionError;
          break;
        default:
          title = l10n.meshNetwork;
          text = l10n.inactive;
      }
    }

    if (Platform.isIOS) {
      _showIOSConnectionNotification(title, text);
    } else {
      FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    }
  }

  /// Show or update a single persistent connection notification on iOS.
  ///
  /// Reuses one notification id so status changes (connecting, reconnecting,
  /// connected) update the same Notification-Center entry rather than posting a
  /// new banner each time.  Only the first show alerts (banner); subsequent
  /// updates are passive so the reconnect-retry loop doesn't spam the user.
  /// Carries the `mesh_connection` category so the "Stop" action button is
  /// attached.
  Future<void> _showIOSConnectionNotification(String title, String text) async {
    if (_notifications == null) return;

    final firstShow = !_iosNotificationVisible;

    final iosDetails = DarwinNotificationDetails(
      // Alert (banner) only on the first show; update quietly afterwards.
      // interruptionLevel is the lever that silences background updates:
      // `passive` adds/updates the entry in Notification Center without
      // re-alerting, which stops the reconnect-retry spam.
      presentAlert: firstShow,
      presentBadge: false,
      presentSound: false,
      interruptionLevel:
          firstShow ? InterruptionLevel.active : InterruptionLevel.passive,
      categoryIdentifier: iosNotificationCategoryId,
    );

    final details = NotificationDetails(iOS: iosDetails);

    await _notifications.show(
      _connectionNotificationId,
      title,
      text,
      details,
      payload: NotificationPayload.meshConnection().toJson(),
    );
    _iosNotificationVisible = true;
  }

  /// Remove the iOS connection notification
  Future<void> _removeIOSConnectionNotification() async {
    if (_notifications == null) return;
    await _notifications.cancel(_connectionNotificationId);
    _iosNotificationVisible = false;
  }

  /// Handle messages from foreground task
  void _handleForegroundTaskMessage(dynamic message) {
    if (message is Map) {
      final type = message['type'] as String?;

      if (type == 'disconnect_requested') {
        debugPrint('[MeshService] Disconnect requested from notification');
        _triggerManualDisconnect();
      }
    }
  }

  /// Monitor connection and reconnection state to manage service lifecycle
  /// Matches Android TEAM MeshConnectionService behavior
  void _monitorServiceLifecycle() {
    debugPrint('[MeshService] 🔍 Starting lifecycle monitoring...');

    // Add the shared listener once. Adding a fresh anonymous closure on every
    // startService() leaked listeners that were never removed.
    if (_lifecycleListener != null) return;

    _lifecycleListener = () {
      _checkIfServiceShouldStop();
    };
    _bleManager.addListener(_lifecycleListener!);
    _reconnectionManager.addListener(_lifecycleListener!);
  }

  /// Remove the lifecycle listener added by [_monitorServiceLifecycle].
  void _stopMonitoringServiceLifecycle() {
    final listener = _lifecycleListener;
    if (listener == null) return;
    _bleManager.removeListener(listener);
    _reconnectionManager.removeListener(listener);
    _lifecycleListener = null;
  }

  /// Check if service should stop itself
  /// Only stops when:
  /// 1. Manual disconnect flag is set, OR
  /// 2. Disconnected AND not reconnecting AND no auto-reconnect configured
  Future<void> _checkIfServiceShouldStop() async {
    if (!_isServiceRunning) return;

    final manualDisconnect = _settings.settings.manualDisconnect;
    final bleState = _bleManager.state;
    final reconnectionState = _reconnectionManager.state;

    // Don't stop if actively reconnecting (matches Android onTaskRemoved logic)
    if (reconnectionState == ReconnectionState.scanning ||
        reconnectionState == ReconnectionState.connecting ||
        reconnectionState == ReconnectionState.waiting) {
      debugPrint('[MeshService] 🔄 Reconnecting - keeping service alive');
      return;
    }

    // Don't stop if connected
    if (bleState == BleConnectionState.connected) {
      debugPrint('[MeshService] ✅ Connected - keeping service alive');
      return;
    }

    // Stop only if manual disconnect
    if (manualDisconnect) {
      debugPrint(
          '[MeshService] 🛑 Manual disconnect detected - stopping service');
      await stopService();
      return;
    }

    // If disconnected but auto-reconnect is enabled, keep service alive
    if (bleState == BleConnectionState.disconnected &&
        reconnectionState == ReconnectionState.idle &&
        !_settings.settings.autoReconnectEnabled) {
      debugPrint(
          '[MeshService] 💤 Disconnected with no auto-reconnect - stopping service');
      await stopService();
    }
  }

  /// Fully stop the service from a notification action (Stop button or swipe).
  /// Sets the manual-disconnect flag, stops reconnection, disconnects BLE, opts
  /// out of iOS state restoration, and stops the service so it stays stopped.
  /// Public so the notification-response handler in main.dart can invoke it.
  Future<void> stopFromNotification() => _triggerManualDisconnect();

  /// Trigger manual disconnect from notification button
  /// Matches Android TEAM manual disconnect flow
  Future<void> _triggerManualDisconnect() async {
    debugPrint(
        '[MeshService] 🔴 Manual disconnect triggered from notification');

    // Set manual disconnect flag
    await _settings.setManualDisconnect(true);

    // Stop reconnection
    _reconnectionManager.stopReconnecting();

    // Disconnect BLE
    await _bleManager.disconnect();

    // Stop service (disables restoration + removes notification)
    await stopService();
  }

  @override
  void dispose() {
    _bleManager.removeListener(_onConnectionStateChanged);
    _reconnectionManager.removeListener(_onReconnectionStateChanged);
    _stopMonitoringServiceLifecycle();
    _receivePort?.close();
    super.dispose();
  }
}
