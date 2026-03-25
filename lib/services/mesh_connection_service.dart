// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:meshcore_team/ble/ble_connection_manager.dart';
import 'package:meshcore_team/ble/reconnection_manager.dart';
import 'package:meshcore_team/ble/reconnection_state.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/services/foreground_task_handler.dart';

/// Mesh Connection Service
/// Manages foreground service, wake lock, and auto-reconnection
/// Matches Android MeshConnectionService functionality
class MeshConnectionService extends ChangeNotifier {
  final BleConnectionManager _bleManager;
  final ReconnectionManager _reconnectionManager;
  final SettingsService _settings;

  bool _isServiceRunning = false;
  bool _isWakeLockEnabled = false;
  ReceivePort? _receivePort;

  bool get isServiceRunning => _isServiceRunning;
  bool get isWakeLockEnabled => _isWakeLockEnabled;

  MeshConnectionService({
    required BleConnectionManager bleManager,
    required ReconnectionManager reconnectionManager,
    required SettingsService settings,
  })  : _bleManager = bleManager,
        _reconnectionManager = reconnectionManager,
        _settings = settings {
    _initialize();
  }

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
        channelName: 'Mesh Network Connection',
        channelDescription: 'Maintains mesh network connection in background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
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
        notificationTitle: 'Mesh network active',
        notificationText: 'Connecting to companion device...',
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
      // may still be active. Disconnect it directly.
      if (_bleManager.isConnected) {
        debugPrint('[MeshService] BLE still connected — disconnecting');
        await _bleManager.disconnect();
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

      // Stop foreground task
      await FlutterForegroundTask.stopService();

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
      await WakelockPlus.disable();
      _isWakeLockEnabled = false;
      debugPrint('[MeshService] 🔄 Wake lock disabled');
    } catch (e) {
      debugPrint('[MeshService] ❌ Failed to disable wake lock: $e');
    }
  }

  /// Handle connection state changes
  void _onConnectionStateChanged() {
    final state = _bleManager.state;
    debugPrint('[MeshService] Connection state changed: $state');

    // Update notification based on state
    _updateNotification(state, _reconnectionManager.state);

    switch (state) {
      case BleConnectionState.connected:
        // Stop reconnection when connected
        _reconnectionManager.stopReconnecting();

        // Enable wake lock
        _enableWakeLock();
        break;

      case BleConnectionState.disconnected:
        // Check if we should auto-reconnect
        _handleDisconnection();
        break;

      default:
        break;
    }
  }

  /// Handle reconnection state changes
  void _onReconnectionStateChanged() {
    final reconnectionState = _reconnectionManager.state;
    debugPrint('[MeshService] Reconnection state changed: $reconnectionState');

    // Update notification
    _updateNotification(_bleManager.state, reconnectionState);
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
    if (Platform.isAndroid) return;

    String title = 'Mesh network';
    String text = '';

    if (reconnectionState != ReconnectionState.idle) {
      // Reconnection in progress - show device name
      final deviceName = _settings.settings.lastConnectedDevice ?? 'device';
      title = 'Mesh network reconnecting';
      text = 'Reconnecting to $deviceName...';
    } else {
      // Normal connection state
      switch (connectionState) {
        case BleConnectionState.connected:
          final deviceName = _bleManager.deviceName ?? 'companion device';
          title = 'Mesh network active';
          text = 'Connected to $deviceName';
          break;
        case BleConnectionState.connecting:
          title = 'Mesh network connecting';
          text = 'Establishing connection...';
          break;
        case BleConnectionState.disconnected:
          title = 'Mesh network disconnected';
          text = 'Device disconnected';
          break;
        case BleConnectionState.scanning:
          title = 'Mesh network scanning';
          text = 'Searching for devices...';
          break;
        case BleConnectionState.error:
          title = 'Mesh network error';
          text = _bleManager.errorMessage ?? 'Connection error';
          break;
        default:
          title = 'Mesh network';
          text = 'Inactive';
      }
    }

    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
    );
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

    // Listen to BLE connection state changes
    _bleManager.addListener(() {
      _checkIfServiceShouldStop();
    });

    // Listen to reconnection state changes
    _reconnectionManager.addListener(() {
      _checkIfServiceShouldStop();
    });
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

    // Stop service (will be caught by _checkIfServiceShouldStop)
    await stopService();
  }

  @override
  void dispose() {
    _bleManager.removeListener(_onConnectionStateChanged);
    _reconnectionManager.removeListener(_onReconnectionStateChanged);
    _receivePort?.close();
    super.dispose();
  }
}
