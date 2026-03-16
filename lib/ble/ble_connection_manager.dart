// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:meshcore_team/ble/ble_constants.dart';
import 'package:meshcore_team/ble/ble_protocol.dart';
import 'package:meshcore_team/ble/mesh_ble_device.dart';

/// BLE Connection State
enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
  error,
}

/// BLE Connection Manager
/// Handles scanning, connecting, and communicating with MeshCore companion radios
class BleConnectionManager extends ChangeNotifier {
  static const MethodChannel _methodChannel =
      MethodChannel('com.meshcore.team/mesh_ble');
  static const EventChannel _eventChannel =
      EventChannel('com.meshcore.team/mesh_ble_events');

  // Connection state
  BleConnectionState _state = BleConnectionState.disconnected;
  String? _errorMessage;

  String? _deviceName;
  String? _deviceAddress;

  // Frame communication
  final StreamController<Uint8List> _receivedFramesController =
      StreamController<Uint8List>.broadcast();
  DateTime? _lastWriteTime;
  Future<void> _writeChain = Future.value();

  // Scan results (active scan session)
  StreamController<MeshBleDevice>? _scanResultsController;
  Timer? _scanTimeoutTimer;

  // Platform events
  StreamSubscription<dynamic>? _platformEventsSub;

  // Pending connect/disconnect
  Completer<bool>? _pendingConnect;
  Completer<void>? _pendingDisconnect;

  // Getters
  BleConnectionState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _state == BleConnectionState.connected;
  bool get isConnecting => _state == BleConnectionState.connecting;
  bool get isScanning => _state == BleConnectionState.scanning;
  String? get deviceName => _deviceName;
  String? get deviceAddress => _deviceAddress;
  Stream<Uint8List> get receivedFrames => _receivedFramesController.stream;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  BleConnectionManager() {
    if (_isAndroid) {
      _platformEventsSub = _eventChannel
          .receiveBroadcastStream()
          .listen(_handlePlatformEvent, onError: _handlePlatformError);
      // Prime initial status (service may already be connected)
      unawaited(refreshStatus());
    }
  }

  Future<void> startNativeService() async {
    if (!_isAndroid) return;
    try {
      debugPrint('[BleManager] -> startService');
      await _methodChannel.invokeMethod('startService');
    } catch (_) {
      // Best-effort; non-Android platforms will ignore.
    }
  }

  Future<void> stopNativeService() async {
    if (!_isAndroid) return;
    try {
      debugPrint('[BleManager] -> stopService');
      await _methodChannel.invokeMethod('stopService');
    } catch (_) {
      // Best-effort
    }
  }

  Future<void> refreshStatus() async {
    if (!_isAndroid) return;
    try {
      debugPrint('[BleManager] -> getStatus');
      final status =
          await _methodChannel.invokeMapMethod<String, dynamic>('getStatus');
      if (status != null) {
        _applyStatus(status);
      }
    } catch (e) {
      debugPrint('[BleManager] refreshStatus error: $e');
    }
  }

  /// Scan for MeshCore devices
  /// Returns a stream of discovered devices
  Stream<MeshBleDevice> startScan(
      {Duration timeout = const Duration(seconds: 10)}) {
    if (!_isAndroid) {
      _setError('Native BLE service is only supported on Android');
      final controller = StreamController<MeshBleDevice>();
      controller.close();
      return controller.stream;
    }
    debugPrint('🔍 Starting native BLE scan for MeshCore devices...');
    _scanResultsController?.close();
    _scanResultsController = StreamController<MeshBleDevice>.broadcast();

    _setState(BleConnectionState.scanning);

    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = Timer(timeout, () {
      stopScan();
    });

    unawaited(_methodChannel.invokeMethod('startScan', {
      'timeoutMs': timeout.inMilliseconds,
    }));

    debugPrint('[BleManager] -> startScan timeoutMs=${timeout.inMilliseconds}');

    return _scanResultsController!.stream;
  }

  /// Stop scanning
  Future<void> stopScan() async {
    debugPrint('🛑 Stopping BLE scan');
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;

    try {
      if (_isAndroid) {
        debugPrint('[BleManager] -> stopScan');
        await _methodChannel.invokeMethod('stopScan');
      }
    } catch (e) {
      debugPrint('[BleManager] stopScan error: $e');
    }

    await _scanResultsController?.close();
    _scanResultsController = null;

    if (_state == BleConnectionState.scanning) {
      _setState(BleConnectionState.disconnected);
    }
  }

  /// Connect to a MeshCore device
  /// Handles bonding/pairing during GATT connection (simplified for FlutterBluePlus)
  Future<bool> connect(MeshBleDevice device) async {
    if (!_isAndroid) {
      _setError('Native BLE service is only supported on Android');
      return false;
    }
    debugPrint(
        '🔗 Connecting (native) to ${device.name} (${device.address})...');

    _pendingConnect?.complete(false);
    _pendingConnect = Completer<bool>();

    _deviceName = device.name;
    _deviceAddress = device.address;
    _setState(BleConnectionState.connecting);

    try {
      // Don't invoke native stopScan here: it can emit a transient native
      // "disconnected" status while we are mid-connect (scan -> connect).
      // We'll stop scan locally and let the native connect path stop scanning
      // without emitting a disconnect transition.
      _scanTimeoutTimer?.cancel();
      _scanTimeoutTimer = null;
      try {
        await _scanResultsController?.close();
      } catch (_) {
        // ignore
      }
      _scanResultsController = null;

      await startNativeService();
      debugPrint('[BleManager] -> connect address=${device.address}');
      await _methodChannel.invokeMethod('connect', {
        'address': device.address,
      });

      // Pairing/bonding may require user interaction and can exceed short timeouts.
      // Keep this in sync with the native service's connect timeout.
      const connectTimeout = Duration(seconds: 120);

      final result = await _pendingConnect!.future.timeout(
        connectTimeout,
        onTimeout: () {
          debugPrint(
              '❌ Connection timeout after ${connectTimeout.inSeconds} seconds');
          _setError('Connection timeout');

          // Ensure the pending connect completes, so callers don't observe a
          // connect() returning while a later native status event completes the
          // old completer.
          _pendingConnect?.complete(false);
          _pendingConnect = null;

          // Force disconnect to clean up
          debugPrint(
              '[BleManager] connect timeout -> disconnect()\n${StackTrace.current}');
          disconnect();
          return false;
        },
      );

      return result;
    } catch (e) {
      debugPrint('❌ Connection error: $e');
      _setError('Connection failed: $e');
      // Ensure state is reset
      if (_state == BleConnectionState.connecting) {
        _setState(BleConnectionState.disconnected);
      }
      return false;
    } finally {
      _pendingConnect = null;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    debugPrint('🔌 Disconnecting (native)...');
    debugPrint('[BleManager] disconnect() callsite\n${StackTrace.current}');
    _pendingDisconnect?.complete();
    _pendingDisconnect = Completer<void>();
    _setState(BleConnectionState.disconnecting);

    try {
      if (_isAndroid) {
        debugPrint('[BleManager] -> disconnect');
        await _methodChannel.invokeMethod('disconnect');
      }
      await _pendingDisconnect!.future
          .timeout(const Duration(seconds: 10), onTimeout: () {});
    } catch (e) {
      debugPrint('❌ Disconnect error: $e');
    } finally {
      _lastWriteTime = null;
      _deviceName = null;
      _deviceAddress = null;
      if (_state != BleConnectionState.connected) {
        _setState(BleConnectionState.disconnected);
      }
      _pendingDisconnect = null;
    }
  }

  /// Send a frame to the device
  Future<bool> sendFrame(Uint8List frame) async {
    return _withWriteLock(() async {
      if (!isConnected) {
        debugPrint('❌ Cannot send frame: not connected');
        return false;
      }

      if (frame.length > BleConstants.maxFrameSize) {
        debugPrint(
            '❌ Frame too large: ${frame.length} bytes (max ${BleConstants.maxFrameSize})');
        return false;
      }

      // Enforce minimum write interval
      final now = DateTime.now();
      if (_lastWriteTime != null) {
        final elapsed = now.difference(_lastWriteTime!).inMilliseconds;
        if (elapsed < BleConstants.minWriteIntervalMs) {
          final delay = BleConstants.minWriteIntervalMs - elapsed;
          await Future.delayed(Duration(milliseconds: delay));
        }
      }

      try {
        debugPrint(
            '📤 Sending ${frame.length} bytes: ${BleFrameUtils.bytesToHex(frame)}');

        if (_isAndroid) {
          await _methodChannel.invokeMethod('sendFrame', {
            'data': frame,
          });
        }
        _lastWriteTime = DateTime.now();
        return true;
      } catch (e) {
        debugPrint('❌ Write error: $e');
        return false;
      }
    });
  }

  Future<T> _withWriteLock<T>(Future<T> Function() action) {
    final chained = _writeChain.then((_) => action());
    _writeChain = chained.then((_) {}, onError: (_) {});
    return chained;
  }

  /// Handle received frame
  void _handleReceivedFrame(Uint8List frame) {
    debugPrint(
        '📥 Received ${frame.length} bytes: ${BleFrameUtils.bytesToHex(frame)}');

    if (frame.isNotEmpty) {
      final responseCode = frame[0];
      final responseName = BleFrameUtils.getResponseName(responseCode);
      debugPrint('   Response: $responseName');
    }

    _receivedFramesController.add(frame);
  }

  void _handlePlatformEvent(dynamic event) {
    if (event is! Map) return;
    final type = event['type'];

    switch (type) {
      case 'scan':
        final name = (event['name'] as String?) ?? '';
        final address = (event['address'] as String?) ?? '';
        if (address.isEmpty) return;
        if (_scanResultsController != null &&
            !_scanResultsController!.isClosed) {
          _scanResultsController!
              .add(MeshBleDevice(address: address, name: name));
        }
        break;
      case 'frame':
        final data = event['data'];
        if (data is Uint8List) {
          _handleReceivedFrame(data);
        } else if (data is List) {
          _handleReceivedFrame(Uint8List.fromList(data.cast<int>()));
        }
        break;
      case 'status':
        final status = event['status'];
        if (status is Map) {
          debugPrint('[BleManager] ⬅️ status event: $status');
          _applyStatus(status.cast<String, dynamic>());
        }
        break;
      case 'log':
        final level = (event['level'] as String?) ?? 'I';
        final msg = (event['msg'] as String?) ?? '';
        final extra = event['extra'];
        final ts = event['ts'];
        debugPrint(
            '[Native][$level] $msg ${extra is Map ? extra : ''} ${ts != null ? '(ts=$ts)' : ''}');
        break;
      default:
        break;
    }
  }

  void _handlePlatformError(Object error) {
    debugPrint('[BleManager] Platform event error: $error');
  }

  void _applyStatus(Map<String, dynamic> status) {
    final stateStr = (status['state'] as String?) ?? 'disconnected';
    final deviceName = status['deviceName'] as String?;
    final deviceAddress = status['deviceAddress'] as String?;
    final error = status['errorMessage'] as String?;

    _deviceName = deviceName;
    _deviceAddress = deviceAddress;

    if (error != null && error.isNotEmpty) {
      _errorMessage = error;
    }

    final mappedState = _mapState(stateStr);

    if (_state != mappedState || (error != null && error.isNotEmpty)) {
      debugPrint(
        '[BleManager] applyStatus ${_state.name} -> ${mappedState.name} '
        'addr=${deviceAddress ?? '-'} name=${deviceName ?? '-'} err=${error ?? '-'}',
      );
    }
    if (mappedState == BleConnectionState.connected) {
      if (_pendingConnect != null) {
        debugPrint('[BleManager] completing pendingConnect(true)');
      }
      _pendingConnect?.complete(true);
      _pendingConnect = null;
    } else if (mappedState == BleConnectionState.disconnected) {
      if (_pendingDisconnect != null) {
        debugPrint('[BleManager] completing pendingDisconnect()');
      }
      _pendingDisconnect?.complete();
      _pendingDisconnect = null;
    } else if (mappedState == BleConnectionState.error) {
      debugPrint('[BleManager] error state: ${_errorMessage ?? error ?? ''}');
      _pendingConnect?.complete(false);
      _pendingConnect = null;
      _pendingDisconnect?.complete();
      _pendingDisconnect = null;
    }

    // Only update state at the end, after completing completers.
    if (_state != mappedState) {
      _state = mappedState;
      notifyListeners();
    } else if (error != null && error.isNotEmpty) {
      notifyListeners();
    }
  }

  BleConnectionState _mapState(String stateStr) {
    switch (stateStr) {
      case 'scanning':
        return BleConnectionState.scanning;
      case 'connecting':
        return BleConnectionState.connecting;
      case 'connected':
        return BleConnectionState.connected;
      case 'disconnecting':
        return BleConnectionState.disconnecting;
      case 'error':
        return BleConnectionState.error;
      case 'disconnected':
      default:
        return BleConnectionState.disconnected;
    }
  }

  /// Set state and notify listeners
  void _setState(BleConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Set error state
  void _setError(String message) {
    _state = BleConnectionState.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanTimeoutTimer?.cancel();
    _platformEventsSub?.cancel();
    _scanResultsController?.close();
    _receivedFramesController.close();
    super.dispose();
  }
}
