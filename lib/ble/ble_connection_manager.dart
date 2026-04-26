// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:meshcore_team/ble/ble_constants.dart';
import 'package:meshcore_team/ble/ble_protocol.dart';
import 'package:meshcore_team/ble/mesh_ble_device.dart';
import 'package:meshcore_team/utils/sync_trace.dart';

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
  static const String _syncTraceTag = '[SYNCTRACE][BLE]';
  static const bool _logRawBleFrames = false;

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

  // Contact stream trace state for correlating raw BLE frames with sync logic.
  int _traceExpectedContacts = 0;
  int _traceReceivedContacts = 0;
  bool _traceContactStreamActive = false;

  // iOS (flutter_blue_plus) state
  BluetoothDevice? _fbpDevice;
  BluetoothCharacteristic? _fbpRxChar;
  BluetoothCharacteristic? _fbpTxChar;
  bool _fbpWriteWithoutResponse = true; // updated at connect time based on characteristic properties
  StreamSubscription<BluetoothConnectionState>? _fbpConnectionSub;
  StreamSubscription<List<int>>? _fbpNotifySub;
  StreamSubscription<List<ScanResult>>? _fbpScanSub;

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
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

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
    if (_isAndroid) {
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

      debugPrint(
          '[BleManager] -> startScan timeoutMs=${timeout.inMilliseconds}');

      return _scanResultsController!.stream;
    } else if (_isIOS) {
      debugPrint('🔍 Starting iOS BLE scan for MeshCore devices...');
      _scanResultsController?.close();
      _scanResultsController = StreamController<MeshBleDevice>.broadcast();

      _setState(BleConnectionState.scanning);

      _scanTimeoutTimer?.cancel();
      _scanTimeoutTimer = Timer(timeout, () {
        stopScan();
      });

      _fbpScanSub?.cancel();
      _fbpScanSub = FlutterBluePlus.onScanResults.listen((results) {
        for (final r in results) {
          final name = r.device.advName.isNotEmpty
              ? r.device.advName
              : r.device.platformName;
          if (name.startsWith(BleConstants.deviceNamePrefix)) {
            final device = MeshBleDevice(
              address: r.device.remoteId.str,
              name: name,
            );
            if (_scanResultsController != null &&
                !_scanResultsController!.isClosed) {
              _scanResultsController!.add(device);
            }
          }
        }
      });

      // Launch scan asynchronously — wait for CoreBluetooth if needed.
      unawaited(_startIosScan(timeout));

      return _scanResultsController!.stream;
    } else {
      _setError('BLE is not supported on this platform');
      final controller = StreamController<MeshBleDevice>();
      controller.close();
      return controller.stream;
    }
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
      } else if (_isIOS) {
        await FlutterBluePlus.stopScan();
        _fbpScanSub?.cancel();
        _fbpScanSub = null;
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
  Future<bool> connect(MeshBleDevice device) async {
    if (_isAndroid) {
      return _connectAndroid(device);
    } else if (_isIOS) {
      return _connectIOS(device);
    } else {
      _setError('BLE is not supported on this platform');
      return false;
    }
  }

  Future<bool> _connectAndroid(MeshBleDevice device) async {
    debugPrint(
        '🔗 Connecting (native) to ${device.name} (${device.address})...');

    _pendingConnect?.complete(false);
    _pendingConnect = Completer<bool>();

    _deviceName = device.name;
    _deviceAddress = device.address;
    _setState(BleConnectionState.connecting);

    try {
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

      const connectTimeout = Duration(seconds: 120);

      final result = await _pendingConnect!.future.timeout(
        connectTimeout,
        onTimeout: () {
          debugPrint(
              '❌ Connection timeout after ${connectTimeout.inSeconds} seconds');
          _setError('Connection timeout');

          _pendingConnect?.complete(false);
          _pendingConnect = null;

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
      if (_state == BleConnectionState.connecting) {
        _setState(BleConnectionState.disconnected);
      }
      return false;
    } finally {
      _pendingConnect = null;
    }
  }

  Future<bool> _connectIOS(MeshBleDevice device) async {
    debugPrint(
        '🔗 Connecting (iOS) to ${device.name} (${device.address})...');

    _deviceName = device.name;
    _deviceAddress = device.address;
    _setState(BleConnectionState.connecting);

    // Stop scan
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;
    _fbpScanSub?.cancel();
    _fbpScanSub = null;
    try {
      await _scanResultsController?.close();
    } catch (_) {}
    _scanResultsController = null;

    try {
      final fbpDevice = BluetoothDevice.fromId(device.address);
      _fbpDevice = fbpDevice;

      // Monitor connection state for unexpected disconnections
      _fbpConnectionSub?.cancel();
      _fbpConnectionSub = fbpDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint('[BleManager] iOS: device disconnected');
          _cleanupIosConnection();
          _deviceName = null;
          _deviceAddress = null;
          _setState(BleConnectionState.disconnected);
        }
      });

      await fbpDevice.connect(
        license: License.free,
        timeout: const Duration(seconds: 120),
      );

      // Discover services
      final services = await fbpDevice.discoverServices();
      BluetoothService? nusService;
      for (final s in services) {
        if (s.uuid == Guid(BleConstants.serviceUuid)) {
          nusService = s;
          break;
        }
      }
      if (nusService == null) {
        throw Exception('NUS service not found');
      }

      // Find characteristics
      BluetoothCharacteristic? rxChar;
      BluetoothCharacteristic? txChar;
      for (final c in nusService.characteristics) {
        if (c.uuid == Guid(BleConstants.rxCharacteristicUuid)) {
          rxChar = c;
        } else if (c.uuid == Guid(BleConstants.txCharacteristicUuid)) {
          txChar = c;
        }
      }
      if (rxChar == null) throw Exception('RX characteristic not found');
      if (txChar == null) throw Exception('TX characteristic not found');

      _fbpRxChar = rxChar;
      _fbpTxChar = txChar;
      _fbpWriteWithoutResponse = rxChar.properties.writeWithoutResponse;

      // Enable notifications on TX characteristic
      await txChar.setNotifyValue(true);

      // Listen for incoming data
      _fbpNotifySub?.cancel();
      _fbpNotifySub = txChar.onValueReceived.listen((value) {
        _handleReceivedFrame(Uint8List.fromList(value));
      });

      debugPrint('✅ iOS BLE connected to ${device.name}');
      _setState(BleConnectionState.connected);
      return true;
    } catch (e) {
      debugPrint('❌ iOS connection error: $e');
      _setError('Connection failed: $e');
      _cleanupIosConnection();
      if (_state == BleConnectionState.connecting) {
        _setState(BleConnectionState.disconnected);
      }
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    debugPrint('🔌 Disconnecting...');
    debugPrint('[BleManager] disconnect() callsite\n${StackTrace.current}');
    _pendingDisconnect?.complete();
    _pendingDisconnect = Completer<void>();
    _setState(BleConnectionState.disconnecting);

    try {
      if (_isAndroid) {
        debugPrint('[BleManager] -> disconnect');
        await _methodChannel.invokeMethod('disconnect');
        await _pendingDisconnect!.future
            .timeout(const Duration(seconds: 10), onTimeout: () {});
      } else if (_isIOS) {
        // Save reference before cleanup nulls it.
        final device = _fbpDevice;
        _cleanupIosConnection();
        if (device != null) {
          await device.disconnect();
          debugPrint('[BleManager] iOS disconnect returned, '
              'isConnected=${device.isConnected}');
        }
      }
    } catch (e) {
      debugPrint('❌ Disconnect error: $e');
    } finally {
      // Diagnostic: check if flutter_blue_plus still holds the connection.
      if (_isIOS) {
        final stale = FlutterBluePlus.connectedDevices;
        if (stale.isNotEmpty) {
          debugPrint('[BleManager] ⚠️ Still connected after disconnect: '
              '${stale.map((d) => d.remoteId.str).join(", ")}');
          for (final d in stale) {
            debugPrint('[BleManager] Force-disconnecting stale device '
                '${d.remoteId.str}');
            try {
              await d.disconnect();
            } catch (_) {}
          }
        }
      }

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
        if (_logRawBleFrames) {
          debugPrint(
              '📤 Sending ${frame.length} bytes: ${BleFrameUtils.bytesToHex(frame)}');
        }

        if (_isAndroid) {
          await _methodChannel.invokeMethod('sendFrame', {
            'data': frame,
          });
        } else if (_isIOS) {
          if (_fbpRxChar == null) {
            throw Exception('RX characteristic not available');
          }
          await _fbpRxChar!.write(frame.toList(), withoutResponse: _fbpWriteWithoutResponse);
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
    if (_logRawBleFrames) {
      debugPrint(
          '📥 Received ${frame.length} bytes: ${BleFrameUtils.bytesToHex(frame)}');
    }

    if (frame.isNotEmpty) {
      final responseCode = frame[0];
      if (_logRawBleFrames) {
        final responseName = BleFrameUtils.getResponseName(responseCode);
        debugPrint('   Response: $responseName');
      }

      if (responseCode == BleConstants.respContactsStart) {
        _traceContactStreamActive = true;
        _traceReceivedContacts = 0;
        _traceExpectedContacts = frame.length >= 5
            ? frame[1] | (frame[2] << 8) | (frame[3] << 16) | (frame[4] << 24)
            : 0;
        syncTrace(
            '$_syncTraceTag contacts_start expected=${_traceExpectedContacts > 0 ? _traceExpectedContacts : 'unknown'} frameLen=${frame.length}');
      } else if (responseCode == BleConstants.respContact) {
        if (!_traceContactStreamActive) {
          _traceContactStreamActive = true;
        }
        _traceReceivedContacts += 1;
        final overrun = _traceExpectedContacts > 0 &&
            _traceReceivedContacts > _traceExpectedContacts;
        syncTrace(
            '$_syncTraceTag contact_frame index=$_traceReceivedContacts expected=${_traceExpectedContacts > 0 ? _traceExpectedContacts : 'unknown'} '
            'frameLen=${frame.length} overrun=$overrun');
      } else if (responseCode == BleConstants.respEndOfContacts) {
        syncTrace(
            '$_syncTraceTag end_of_contacts received=$_traceReceivedContacts expected=${_traceExpectedContacts > 0 ? _traceExpectedContacts : 'unknown'} frameLen=${frame.length}');
        _traceContactStreamActive = false;
        _traceExpectedContacts = 0;
        _traceReceivedContacts = 0;
      }
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

  Future<void> _startIosScan(Duration timeout) async {
    try {
      // Wait for CoreBluetooth to be ready — on first launch the adapter
      // state may briefly be 'unknown'.
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        debugPrint('[BleManager] Waiting for Bluetooth adapter...');
        final ready = await FlutterBluePlus.adapterState
            .firstWhere((s) => s == BluetoothAdapterState.on)
            .timeout(const Duration(seconds: 5), onTimeout: () {
          return BluetoothAdapterState.off;
        });
        if (ready != BluetoothAdapterState.on) {
          _setError('Bluetooth is not turned on');
          return;
        }
      }
      await FlutterBluePlus.startScan(
        withServices: [Guid(BleConstants.serviceUuid)],
        timeout: timeout,
      );
    } catch (e) {
      debugPrint('[BleManager] iOS startScan error: $e');
      _setError('Scan failed: $e');
    }
  }

  void _cleanupIosConnection() {
    _fbpNotifySub?.cancel();
    _fbpNotifySub = null;
    _fbpConnectionSub?.cancel();
    _fbpConnectionSub = null;
    _fbpRxChar = null;
    _fbpTxChar = null;
    _fbpDevice = null;
    _fbpWriteWithoutResponse = true;
  }

  @override
  void dispose() {
    _scanTimeoutTimer?.cancel();
    _platformEventsSub?.cancel();
    _scanResultsController?.close();
    _receivedFramesController.close();
    // iOS cleanup
    _fbpScanSub?.cancel();
    _cleanupIosConnection();
    super.dispose();
  }
}
