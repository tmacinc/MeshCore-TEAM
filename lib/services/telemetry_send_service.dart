// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meshcore_team/ble/ble_service.dart';
import 'package:meshcore_team/database/daos/channels_dao.dart';
import 'package:meshcore_team/models/telemetry_message.dart';
import 'package:meshcore_team/models/topology_message.dart';
import 'package:meshcore_team/models/network_topology.dart';
import 'package:meshcore_team/services/neighbor_tracker.dart';
import 'package:meshcore_team/services/phone_battery_service.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/services/forwarding_policy_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';

/// Sends TEAM-compatible telemetry (`#TEL:`) based on user settings.
///
/// Mirrors Android TEAM's OR logic:
/// - TIME trigger: periodic send every N seconds (even if stationary)
/// - DISTANCE trigger: immediate send when moved >= threshold
///
/// Includes a 15s minimum send interval rate limiter to avoid GPS jitter.
class TelemetrySendService extends ChangeNotifier {
  static const Duration _minSendInterval = Duration(seconds: 15);
  static const Duration _phoneBatteryCacheTtl = Duration(seconds: 60);
  static const MethodChannel _nativeTelemetryChannel =
      MethodChannel('com.meshcore.team/mesh_ble');

  final SettingsService _settings;
  final BleService _bleService;
  final ChannelsDao _channelsDao;
  final ConnectionViewModel _connectionViewModel;
  final PhoneBatteryService _phoneBatteryService;
  final NetworkTopology _networkTopology;
  final NeighborTracker _neighborTracker;
  final ForwardingPolicyService? _forwardingPolicy;

  StreamSubscription<Position>? _positionSub;
  Timer? _periodicTimer;

  double? _lastLatitude;
  double? _lastLongitude;

  int? _lastCompanionBatteryMv;
  int? _lastPhoneBatteryMv;
  DateTime? _lastPhoneBatteryReadAt;

  DateTime _lastSendTime = DateTime.fromMillisecondsSinceEpoch(0);
  (double, double)? _lastSentLocation;

  int _telemetryIntervalSeconds = 60;

  bool _started = false;

  TelemetrySendService({
    required SettingsService settings,
    required BleService bleService,
    required ChannelsDao channelsDao,
    required ConnectionViewModel connectionViewModel,
    PhoneBatteryService? phoneBatteryService,
    NetworkTopology? networkTopology,
    NeighborTracker? neighborTracker,
    ForwardingPolicyService? forwardingPolicy,
  })  : _settings = settings,
        _bleService = bleService,
        _channelsDao = channelsDao,
        _connectionViewModel = connectionViewModel,
        _phoneBatteryService = phoneBatteryService ?? PhoneBatteryService(),
        _networkTopology = networkTopology ?? NetworkTopology(),
        _neighborTracker = neighborTracker ?? NeighborTracker(),
        _forwardingPolicy = forwardingPolicy;

  void start() {
    if (_started) return;
    _started = true;

    _settings.addListener(_onSettingsChanged);
    _bleService.addListener(_onConnectionChanged);
    _connectionViewModel.addListener(_onBatteryChanged);

    _applyConfigAndMaybeStart();
  }

  void _onSettingsChanged() {
    _applyConfigAndMaybeStart();
  }

  void _onConnectionChanged() {
    _applyConfigAndMaybeStart();
  }

  void _onBatteryChanged() {
    final voltage = _connectionViewModel.companionBatteryVoltage;
    if (voltage == null) return;

    final mv = (voltage * 1000).round();
    if (_lastCompanionBatteryMv == mv) return;
    _lastCompanionBatteryMv = mv;

    if (!kIsWeb && Platform.isAndroid) {
      _applyConfigAndMaybeStart();
    }
  }

  bool get _isEnabledInSettings {
    final s = _settings.settings;
    return s.telemetryEnabled && (s.telemetryChannelHash?.isNotEmpty ?? false);
  }

  void _applyConfigAndMaybeStart() {
    unawaited(_applyConfigAndMaybeStartAsync());
  }

  Future<void> _applyConfigAndMaybeStartAsync() async {
    final s = _settings.settings;
    final intervalChanged =
        _telemetryIntervalSeconds != s.telemetryIntervalSeconds;
    _telemetryIntervalSeconds = s.telemetryIntervalSeconds;

    if (!kIsWeb && Platform.isAndroid) {
      await _applyAndroidNativeTelemetryConfig();
      _stopInternal();
      return;
    }

    if (!_isEnabledInSettings || !_bleService.isConnected) {
      _stopInternal();
      return;
    }

    if (_positionSub == null) {
      _startInternal();
      return;
    }

    if (intervalChanged) {
      debugPrint(
          '[TelemetrySend] ⏱️ Interval changed; restarting periodic timer');
      _restartPeriodicTimer();
    }
  }

  Future<void> _applyAndroidNativeTelemetryConfig() async {
    if (!_isEnabledInSettings || !_bleService.isConnected) {
      try {
        await _nativeTelemetryChannel.invokeMethod('stopNativeTelemetry');
      } catch (e) {
        debugPrint('[TelemetrySend] ⚠️ stopNativeTelemetry failed: $e');
      }
      return;
    }

    final channelHashHex = _settings.settings.telemetryChannelHash;
    if (channelHashHex == null || channelHashHex.isEmpty) {
      return;
    }

    final channelHash = _tryParseChannelHash(channelHashHex);
    if (channelHash == null) {
      debugPrint('[TelemetrySend] ❌ Invalid channel hash: $channelHashHex');
      return;
    }

    final channel = await _channelsDao.getChannelByHash(channelHash);
    if (channel == null) {
      debugPrint(
          '[TelemetrySend] ❌ Channel not found for hash: $channelHashHex');
      return;
    }

    try {
      await _nativeTelemetryChannel.invokeMethod('configureNativeTelemetry', {
        'enabled': true,
        'channelIndex': channel.channelIndex,
        'intervalSeconds': _settings.settings.telemetryIntervalSeconds,
        'minDistanceMeters': _settings.settings.telemetryMinDistanceMeters,
        'companionBatteryMilliVolts': _lastCompanionBatteryMv,
        'needsForwarding': _forwardingPolicy?.currentNeedsForwarding ?? false,
        'maxPathObserved': _forwardingPolicy?.currentMaxPathObserved ?? 0,
      });
      debugPrint(
          '[TelemetrySend] ✅ Native telemetry configured (channelIndex=${channel.channelIndex})');
    } catch (e) {
      debugPrint('[TelemetrySend] ❌ configureNativeTelemetry failed: $e');
    }
  }

  Future<void> _startInternal() async {
    debugPrint('[TelemetrySend] ▶️ Starting telemetry sender');

    // Seed cached GPS ASAP, like MapScreen.
    unawaited(_seedCurrentPosition());

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSub =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(_handlePosition, onError: (Object error) {
      debugPrint('[TelemetrySend] ⚠️ Location stream error: $error');
    });

    _restartPeriodicTimer();
  }

  Future<void> _seedCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _handlePosition(position);
    } catch (e) {
      debugPrint('[TelemetrySend] ⚠️ Failed to seed current location: $e');
    }
  }

  void _restartPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer(
      Duration(seconds: _telemetryIntervalSeconds),
      _handlePeriodicTimer,
    );
  }

  Future<void> _handlePeriodicTimer() async {
    // Re-schedule first, to emulate a loop even if send takes time.
    _restartPeriodicTimer();

    final lat = _lastLatitude;
    final lon = _lastLongitude;
    if (lat == null || lon == null) {
      debugPrint('[TelemetrySend] ⚠️ No cached location for periodic send');
      return;
    }

    debugPrint('[TelemetrySend] 📡 PERIODIC send (TIME trigger)');
    await _trySendTelemetry(
      latitude: lat,
      longitude: lon,
      reason: 'PERIODIC',
      resetPeriodicTimer: false,
    );
  }

  void _handlePosition(Position position) {
    _lastLatitude = position.latitude;
    _lastLongitude = position.longitude;

    final minDistanceMeters = _settings.settings.telemetryMinDistanceMeters;
    if (minDistanceMeters <= 0) return;

    final lastSent = _lastSentLocation;
    if (lastSent == null) return;

    final distance = Geolocator.distanceBetween(
      lastSent.$1,
      lastSent.$2,
      position.latitude,
      position.longitude,
    );

    if (distance >= minDistanceMeters) {
      debugPrint(
          '[TelemetrySend] 📍 DISTANCE trigger: moved ${distance.toInt()}m (threshold: ${minDistanceMeters}m)');
      unawaited(_trySendTelemetry(
        latitude: position.latitude,
        longitude: position.longitude,
        reason: 'DISTANCE',
        resetPeriodicTimer: true,
      ));
    }
  }

  Future<int?> _getPhoneBatteryMvCached() async {
    final lastAt = _lastPhoneBatteryReadAt;
    final cached = _lastPhoneBatteryMv;
    if (lastAt != null && cached != null) {
      if (DateTime.now().difference(lastAt) <= _phoneBatteryCacheTtl) {
        return cached;
      }
    }

    try {
      final mv = await _phoneBatteryService.getEstimatedBatteryMilliVolts();
      _lastPhoneBatteryMv = mv;
      _lastPhoneBatteryReadAt = DateTime.now();
      return mv;
    } catch (_) {
      return cached;
    }
  }

  Future<void> _trySendTelemetry({
    required double latitude,
    required double longitude,
    required String reason,
    required bool resetPeriodicTimer,
  }) async {
    if (!_isEnabledInSettings) return;
    if (!_bleService.isConnected) return;

    final now = DateTime.now();
    final sinceLast = now.difference(_lastSendTime);
    if (sinceLast < _minSendInterval) {
      debugPrint(
          '[TelemetrySend] ⏳ Rate-limited (${_minSendInterval.inSeconds}s): ${(_minSendInterval - sinceLast).inSeconds}s remaining');
      return;
    }

    final channelHashHex = _settings.settings.telemetryChannelHash;
    if (channelHashHex == null || channelHashHex.isEmpty) return;

    final channelHash = _tryParseChannelHash(channelHashHex);
    if (channelHash == null) {
      debugPrint('[TelemetrySend] ❌ Invalid channel hash: $channelHashHex');
      return;
    }

    final channel = await _channelsDao.getChannelByHash(channelHash);
    if (channel == null) {
      debugPrint(
          '[TelemetrySend] ❌ Channel not found for hash: $channelHashHex');
      return;
    }

    final phoneBatteryMv = await _getPhoneBatteryMvCached();

    final myNeighbors = _neighborTracker.getMyNeighbors();
    final bitmap = _networkTopology.buildNeighborBitmap(myNeighbors);
    final nodeCount = _networkTopology.getNodeCount();
    final message = TopologyMessage.createBinary(
      latitude: latitude,
      longitude: longitude,
      companionBatteryMilliVolts: _lastCompanionBatteryMv,
      phoneBatteryMilliVolts: phoneBatteryMv,
      neighborBitmap: bitmap,
      nodeCount: nodeCount,
    );

    final ok =
        await _bleService.sendChannelMessage(channel.channelIndex, message);
    if (!ok) {
      debugPrint('[TelemetrySend] ❌ Send failed ($reason)');
      return;
    }

    _lastSendTime = now;
    _lastSentLocation = (latitude, longitude);

    if (resetPeriodicTimer) {
      _restartPeriodicTimer();
    }

    debugPrint(
        '[TelemetrySend] ✅ Sent ($reason) on channelIndex=${channel.channelIndex}');
  }

  int? _tryParseChannelHash(String hashHex) {
    final cleaned = hashHex.trim().toLowerCase().replaceFirst('0x', '');
    if (cleaned.isEmpty) return null;

    final isHex = RegExp(r'^[0-9a-f]+$').hasMatch(cleaned);
    if (!isHex) return null;

    try {
      return int.parse(cleaned, radix: 16);
    } catch (_) {
      return null;
    }
  }

  void _stopInternal() {
    if (_positionSub == null && _periodicTimer == null) return;

    debugPrint('[TelemetrySend] ⏹️ Stopping telemetry sender');
    _positionSub?.cancel();
    _positionSub = null;

    _periodicTimer?.cancel();
    _periodicTimer = null;

    // Keep last cached location/battery; Android TEAM keeps cached values.
  }

  @override
  void dispose() {
    _stopInternal();

    if (_started) {
      _settings.removeListener(_onSettingsChanged);
      _bleService.removeListener(_onConnectionChanged);
      _connectionViewModel.removeListener(_onBatteryChanged);
    }

    super.dispose();
  }
}
