// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:meshcore_team/ble/ble_connection_manager.dart';
import 'package:meshcore_team/ble/mesh_ble_device.dart';
import 'package:meshcore_team/ble/reconnection_state.dart';
import 'package:meshcore_team/services/settings_service.dart';

/// Manages automatic BLE reconnection with exponential backoff
/// Handles reconnection when device goes out of range, reboots, or loses connection
class ReconnectionManager extends ChangeNotifier {
  final BleConnectionManager _connectionManager;
  final SettingsService _settings;

  Timer? _reconnectionTimer;
  int _currentAttempt = 0;
  ReconnectionState _state = ReconnectionState.idle;
  String? _targetDeviceAddress;

  static const int _maxBackoffMs = 30000; // 30 seconds max
  static const Duration _scanTimeout = Duration(seconds: 10);

  ReconnectionState get state => _state;
  String? get targetDeviceAddress => _targetDeviceAddress;
  int get currentAttempt => _currentAttempt;

  ReconnectionManager({
    required BleConnectionManager connectionManager,
    required SettingsService settings,
  })  : _connectionManager = connectionManager,
        _settings = settings;

  /// Start reconnection attempts for a device
  /// Uses exponential backoff: 2s, 4s, 8s, 16s, 30s (max)
  Future<void> startReconnecting(String deviceAddress) async {
    debugPrint('[Reconnect] Starting auto-reconnect to $deviceAddress');

    // Check if auto-reconnect is enabled
    if (!_settings.settings.autoReconnectEnabled) {
      debugPrint('[Reconnect] Auto-reconnect disabled in settings');
      _setState(ReconnectionState.disabled);
      return;
    }

    // Check manual disconnect flag
    if (_settings.settings.manualDisconnect) {
      debugPrint('[Reconnect] Manual disconnect flag set - not reconnecting');
      _setState(ReconnectionState.idle);
      return;
    }

    // Already reconnecting to this device?
    if (_targetDeviceAddress == deviceAddress &&
        _state != ReconnectionState.idle) {
      debugPrint('[Reconnect] Already reconnecting to $deviceAddress');
      return;
    }

    _targetDeviceAddress = deviceAddress;
    _currentAttempt = 0;
    _settings.setAutoReconnectInProgress(true);
    _setState(ReconnectionState.idle);

    _startReconnectionLoop();
  }

  /// Stop all reconnection attempts
  void stopReconnecting() {
    debugPrint('[Reconnect] Stopping reconnection attempts');
    _settings.setAutoReconnectInProgress(false);
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    _targetDeviceAddress = null;
    _currentAttempt = 0;
    _setState(ReconnectionState.idle);
  }

  /// Calculate exponential backoff delay
  int _calculateBackoff(int attempt) {
    if (attempt == 0) return 0; // No delay for first attempt
    final backoffMs = (2000 * (1 << (attempt - 1))).clamp(0, _maxBackoffMs);
    return backoffMs;
  }

  /// Start the reconnection loop with exponential backoff
  void _startReconnectionLoop() {
    if (_targetDeviceAddress == null) return;

    _currentAttempt++;
    final backoffMs = _calculateBackoff(_currentAttempt);

    debugPrint(
        '[Reconnect] Attempt #$_currentAttempt (backoff: ${backoffMs}ms)');

    if (backoffMs > 0) {
      _setState(ReconnectionState.waiting);
      debugPrint('[Reconnect] Waiting ${backoffMs}ms before next attempt...');

      _reconnectionTimer = Timer(Duration(milliseconds: backoffMs), () {
        if (_connectionManager.isConnected) {
          debugPrint('[Reconnect] Already connected - stopping');
          stopReconnecting();
          return;
        }
        _attemptReconnection();
      });
    } else {
      _attemptReconnection();
    }
  }

  /// Attempt a single reconnection (scan + connect)
  Future<void> _attemptReconnection() async {
    if (_targetDeviceAddress == null) return;

    // On Android, the native foreground service owns reconnection.
    // Kick a single connect attempt and then stop the Dart reconnection loop.
    if (Platform.isAndroid) {
      debugPrint(
          '[Reconnect] Android native service handles reconnect; triggering connect()');
      _setState(ReconnectionState.connecting);
      await _connectionManager.connect(
        MeshBleDevice(address: _targetDeviceAddress!, name: ''),
      );
      stopReconnecting();
      return;
    }

    // Check if already connected
    if (_connectionManager.isConnected) {
      debugPrint('[Reconnect] Already connected - stopping');
      stopReconnecting();
      return;
    }

    // Start scanning
    _setState(ReconnectionState.scanning);
    debugPrint('[Reconnect] Scanning for device $_targetDeviceAddress...');

    try {
      MeshBleDevice? foundDevice;

      // Scan for the device with timeout
      final scanStream =
          _connectionManager.startScan(timeout: _scanTimeout).timeout(
                _scanTimeout,
                onTimeout: (sink) => sink.close(),
              );

      await for (final device in scanStream) {
        if (device.address.toUpperCase() ==
            _targetDeviceAddress!.toUpperCase()) {
          foundDevice = device;
          debugPrint('[Reconnect] Device found: ${device.name}');
          break;
        }
      }

      if (foundDevice != null) {
        // Device found - attempt connection
        _setState(ReconnectionState.connecting);
        debugPrint('[Reconnect] Attempting connection...');

        await _connectionManager.connect(foundDevice);

        // Check if connection succeeded
        if (_connectionManager.isConnected) {
          debugPrint('[Reconnect] ✅ Reconnection successful!');
          stopReconnecting();
          return;
        } else {
          debugPrint('[Reconnect] Connection attempt failed');
        }
      } else {
        debugPrint('[Reconnect] Device not found during scan');
      }
    } catch (e) {
      debugPrint('[Reconnect] Error during reconnection attempt: $e');
    }

    // Retry with backoff
    if (_targetDeviceAddress != null) {
      debugPrint('[Reconnect] Scheduling next attempt...');
      _startReconnectionLoop();
    }
  }

  /// Update state and notify listeners
  void _setState(ReconnectionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _reconnectionTimer?.cancel();
    super.dispose();
  }
}
