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
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/services/forwarding_policy_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';

/// Sends TEAM-compatible telemetry based on user settings.
///
/// The telemetry format is determined by the active forwarding strategy:
/// - `forwardingV1` → `#TEL:` (base64 payload, no topology bitmap)
/// - `topology`     → `#T:`   (raw binary payload with neighbor bitmap)
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
  String _currentLocationSource = LocationSource.phone;

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
    _forwardingPolicy?.addListener(_onForwardingPolicyChanged);

    _applyConfigAndMaybeStart();
  }

  void _onSettingsChanged() {
    _applyConfigAndMaybeStart();
  }

  void _onConnectionChanged() {
    _applyConfigAndMaybeStart();
  }

  void _onForwardingPolicyChanged() {
    // Push updated strategy / topology bitmap to the Android native sender.
    if (!kIsWeb && Platform.isAndroid) {
      _applyConfigAndMaybeStart();
    }
  }

  void _onBatteryChanged() {
    final voltage = _connectionViewModel.companionBatteryVoltage;
    if (voltage != null) {
      final mv = (voltage * 1000).round();
      if (_lastCompanionBatteryMv != mv) {
        _lastCompanionBatteryMv = mv;

        // On Android, push updated battery to the native telemetry sender.
        if (!kIsWeb && Platform.isAndroid) {
          _applyConfigAndMaybeStart();
        }
      }
    }

    // Push companion GPS coordinates to Android native telemetry layer.
    if (!kIsWeb && Platform.isAndroid) {
      _pushCompanionLocationIfNeeded();
      return;
    }

    // iOS/other: cache companion coordinates in Dart for the Dart sender.
    if (_currentLocationSource == LocationSource.companion) {
      final lat = _connectionViewModel.companionLatitude;
      final lon = _connectionViewModel.companionLongitude;
      if (lat != null && lon != null) {
        final prevLat = _lastLatitude;
        final prevLon = _lastLongitude;
        _lastLatitude = lat;
        _lastLongitude = lon;

        // Check distance trigger for companion position changes.
        final minDistanceMeters = _settings.settings.telemetryMinDistanceMeters;
        if (minDistanceMeters > 0 && prevLat != null && prevLon != null) {
          final distance = Geolocator.distanceBetween(
            prevLat,
            prevLon,
            lat,
            lon,
          );
          if (distance >= minDistanceMeters) {
            debugPrint('[TelemetrySend] 📍 DISTANCE trigger (companion): '
                'moved ${distance.toInt()}m');
            unawaited(_trySendTelemetry(
              latitude: lat,
              longitude: lon,
              reason: 'DISTANCE',
              resetPeriodicTimer: true,
            ));
          }
        }
      }
    }
  }

  /// Push companion GPS coordinates to the Android native telemetry layer so
  /// it can send telemetry using the companion's position when the user has
  /// selected "companion" as their location source.
  ///
  /// Always pushes (even when coordinates haven't changed) so the native
  /// timestamp stays fresh and the staleness guard doesn't discard the fix.
  void _pushCompanionLocationIfNeeded() {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_settings.settings.locationSource != LocationSource.companion) return;

    final lat = _connectionViewModel.companionLatitude;
    final lon = _connectionViewModel.companionLongitude;
    if (lat == null || lon == null) return;

    unawaited(_nativeTelemetryChannel.invokeMethod('updateCompanionLocation', {
      'latitude': lat,
      'longitude': lon,
    }).catchError((Object e) {
      debugPrint('[TelemetrySend] ⚠️ updateCompanionLocation failed: $e');
    }));
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

    // Android: delegate telemetry to the native foreground service so it
    // survives screen-off / Doze.  The Dart timer is only used on iOS.
    if (!kIsWeb && Platform.isAndroid) {
      await _applyAndroidNativeTelemetryConfig();
      _stopInternal();
      return;
    }

    // --- iOS / other: Dart-side telemetry sender ---

    if (!_isEnabledInSettings || !_bleService.isConnected) {
      _stopInternal();
      return;
    }

    final sourceChanged = _currentLocationSource != s.locationSource;
    _currentLocationSource = s.locationSource;

    if (sourceChanged) {
      _stopInternal();
      _startInternal();
      return;
    }

    // Not yet running — start up.
    final isRunning = _positionSub != null || _periodicTimer != null;
    if (!isRunning) {
      _startInternal();
      return;
    }

    if (intervalChanged) {
      debugPrint(
          '[TelemetrySend] ⏱️ Interval changed; restarting periodic timer');
      _restartPeriodicTimer();
    }
  }

  /// Configure the Android native foreground service telemetry sender.
  /// When telemetry is disabled or disconnected, tells the native side to stop.
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

    // Resolve topology data for current forwarding strategy.
    final strategyMode = _forwardingPolicy?.lastAppliedStrategy ??
        ForwardingAlgorithmMode.forwardingV1;
    Uint8List? neighborBitmap;
    int nodeCount = 0;
    if (strategyMode == ForwardingAlgorithmMode.topology) {
      final myNeighbors = _neighborTracker.getMyNeighbors();
      neighborBitmap = _networkTopology.buildNeighborBitmap(myNeighbors);
      nodeCount = _networkTopology.getNodeCount();
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
        'locationSource': _settings.settings.locationSource,
        'strategyMode': strategyMode,
        'neighborBitmap': neighborBitmap,
        'nodeCount': nodeCount,
      });
      debugPrint('[TelemetrySend] ✅ Native telemetry configured '
          '(channelIndex=${channel.channelIndex}, strategy=$strategyMode)');
    } catch (e) {
      debugPrint('[TelemetrySend] ❌ configureNativeTelemetry failed: $e');
    }
  }

  Future<void> _startInternal() async {
    debugPrint('[TelemetrySend] ▶️ Starting telemetry sender'
        ' (locationSource=$_currentLocationSource)');

    if (_currentLocationSource == LocationSource.companion) {
      // Seed from companion's last known position.
      _seedCompanionPosition();
    } else {
      // Phone GPS mode — subscribe to the platform location stream.
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
    }

    _restartPeriodicTimer();
  }

  /// Populate cached lat/lon from the companion device's last GPS fix.
  void _seedCompanionPosition() {
    final lat = _connectionViewModel.companionLatitude;
    final lon = _connectionViewModel.companionLongitude;
    if (lat != null && lon != null) {
      _lastLatitude = lat;
      _lastLongitude = lon;
    }
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

    // In companion mode, pull the latest coordinates from the view model each
    // tick so we pick up fresh GPS pushes from the mesh device.
    if (_currentLocationSource == LocationSource.companion) {
      _seedCompanionPosition();
    }

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

    // Choose telemetry format based on the active forwarding strategy.
    final useTopologyFormat = _forwardingPolicy?.lastAppliedStrategy ==
        ForwardingAlgorithmMode.topology;

    final String message;
    if (useTopologyFormat) {
      final myNeighbors = _neighborTracker.getMyNeighbors();
      final bitmap = _networkTopology.buildNeighborBitmap(myNeighbors);
      final nodeCount = _networkTopology.getNodeCount();
      message = TopologyMessage.createBinary(
        latitude: latitude,
        longitude: longitude,
        companionBatteryMilliVolts: _lastCompanionBatteryMv,
        phoneBatteryMilliVolts: phoneBatteryMv,
        neighborBitmap: bitmap,
        nodeCount: nodeCount,
      );
    } else {
      message = TelemetryMessage.createBinary(
        latitude: latitude,
        longitude: longitude,
        companionBatteryMilliVolts: _lastCompanionBatteryMv,
        phoneBatteryMilliVolts: phoneBatteryMv,
        needsForwarding: _forwardingPolicy?.currentNeedsForwarding ?? false,
        maxPathObserved: _forwardingPolicy?.currentMaxPathObserved ?? 0,
      );
    }

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
      _forwardingPolicy?.removeListener(_onForwardingPolicyChanged);
    }

    super.dispose();
  }
}
