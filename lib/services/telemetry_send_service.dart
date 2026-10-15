// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meshcore_team/ble/ble_service.dart';
import 'package:meshcore_team/database/daos/channels_dao.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/channel.dart' show ChannelDataKind;
import 'package:meshcore_team/models/telemetry_message.dart';
import 'package:meshcore_team/models/topology_message.dart';
import 'package:meshcore_team/models/network_topology.dart';
import 'package:meshcore_team/services/neighbor_tracker.dart';
import 'package:meshcore_team/services/phone_battery_service.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/companion_location_service.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/services/forwarding_policy_service.dart';
import 'package:meshcore_team/utils/location_settings.dart';
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
///
/// Position follows [CompanionLocationService]: the companion's fix while it
/// has a fresh one, otherwise the phone. In companion mode phone GPS is only
/// switched on while the companion has no fix.
class TelemetrySendService extends ChangeNotifier {
  static const Duration _minSendInterval = Duration(seconds: 15);
  static const Duration _phoneBatteryCacheTtl = Duration(seconds: 60);
  static const MethodChannel _nativeTelemetryChannel =
      MethodChannel('com.meshcore.team/mesh_ble');

  final SettingsService _settings;
  final BleService _bleService;
  final ChannelsDao _channelsDao;
  final ConnectionViewModel _connectionViewModel;
  final CompanionLocationService _companionLocation;
  final PhoneBatteryService _phoneBatteryService;
  final NetworkTopology _networkTopology;
  final NeighborTracker _neighborTracker;
  final ForwardingPolicyService? _forwardingPolicy;

  StreamSubscription<Position>? _positionSub;
  Timer? _periodicTimer;

  double? _phoneLatitude;
  double? _phoneLongitude;

  /// Android: whether the native sender currently holds a companion position
  /// we gave it, so the clear is only sent once per fallback.
  bool _nativeHasCompanionLocation = false;

  int? _lastCompanionBatteryMv;
  int? _lastPhoneBatteryMv;
  DateTime? _lastPhoneBatteryReadAt;

  DateTime _lastSendTime = DateTime.fromMillisecondsSinceEpoch(0);
  (double, double)? _lastSentLocation;

  int _telemetryIntervalSeconds = 60;

  bool _started = false;
  bool _syncWasComplete = false;

  TelemetrySendService({
    required SettingsService settings,
    required BleService bleService,
    required ChannelsDao channelsDao,
    required ConnectionViewModel connectionViewModel,
    required CompanionLocationService companionLocation,
    PhoneBatteryService? phoneBatteryService,
    NetworkTopology? networkTopology,
    NeighborTracker? neighborTracker,
    ForwardingPolicyService? forwardingPolicy,
  })  : _settings = settings,
        _bleService = bleService,
        _channelsDao = channelsDao,
        _connectionViewModel = connectionViewModel,
        _companionLocation = companionLocation,
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
    _companionLocation.addListener(_onCompanionLocationChanged);
    _forwardingPolicy?.addListener(_onForwardingPolicyChanged);

    _watchTrackingChannel();
    _applyConfigAndMaybeStart();
  }

  void _onSettingsChanged() {
    _watchTrackingChannel();
    _applyConfigAndMaybeStart();
  }

  StreamSubscription<ChannelData?>? _trackingChannelSub;
  String? _watchedChannelHash;
  bool? _trackingChannelOnRadio;

  /// Sending is skipped while the tracking channel isn't on the radio. When
  /// it is added (or lost), nothing about the settings or connection changes,
  /// so without this the sender only noticed at some later, unrelated event.
  void _watchTrackingChannel() {
    final hashHex = _settings.settings.telemetryChannelHash;
    if (hashHex == _watchedChannelHash) return;
    _watchedChannelHash = hashHex;
    _trackingChannelSub?.cancel();
    _trackingChannelSub = null;
    _trackingChannelOnRadio = null;

    final hash = hashHex == null ? null : _tryParseChannelHash(hashHex);
    if (hash == null) return;
    _trackingChannelSub = _channelsDao.watchChannel(hash).listen((channel) {
      final onRadio = channel?.isOnRadio;
      final changed =
          _trackingChannelOnRadio != null && onRadio != _trackingChannelOnRadio;
      _trackingChannelOnRadio = onRadio;
      if (changed) {
        debugPrint(
            '[TelemetrySend] 🔄 Tracking channel is ${onRadio == true ? 'now' : 'no longer'} on the radio');
        _applyConfigAndMaybeStart();
      }
    });
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
    // Re-apply config when sync first completes — channel lookup may have
    // failed at connect time because channels weren't synced yet.
    final syncNowComplete = _connectionViewModel.syncStatus.isComplete;
    if (syncNowComplete && !_syncWasComplete) {
      _syncWasComplete = true;
      _applyConfigAndMaybeStart();
    } else if (!syncNowComplete) {
      _syncWasComplete = false;
    }

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
  }

  /// Runs on every companion position update and on every companion ↔ phone
  /// switch.
  void _onCompanionLocationChanged() {
    if (!kIsWeb && Platform.isAndroid) {
      _syncCompanionLocationToNative();
      return;
    }

    // iOS/other: the Dart sender reads the companion position at send time.
    _updatePhoneStream();
    final lat = _companionLocation.latitude;
    final lon = _companionLocation.longitude;
    if (lat != null && lon != null) {
      _maybeSendForDistance(lat, lon, source: 'companion');
    }
  }

  /// Keeps the Android native sender's companion position in step with
  /// [CompanionLocationService].
  ///
  /// While the companion is in use, pushes on every update (even when the
  /// coordinates haven't changed) so the native timestamp stays fresh. When
  /// it isn't, clears the native copy so native switches to the phone
  /// straight away instead of waiting for the companion copy to age out.
  void _syncCompanionLocationToNative() {
    final lat = _companionLocation.latitude;
    final lon = _companionLocation.longitude;

    if (lat != null && lon != null) {
      _nativeHasCompanionLocation = true;
      unawaited(
          _nativeTelemetryChannel.invokeMethod('updateCompanionLocation', {
        'latitude': lat,
        'longitude': lon,
      }).catchError((Object e) {
        debugPrint('[TelemetrySend] ⚠️ updateCompanionLocation failed: $e');
      }));
      return;
    }

    if (!_nativeHasCompanionLocation) return;
    _nativeHasCompanionLocation = false;
    unawaited(_nativeTelemetryChannel
        .invokeMethod('clearCompanionLocation')
        .catchError((Object e) {
      debugPrint('[TelemetrySend] ⚠️ clearCompanionLocation failed: $e');
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

    // Not yet running — start up. A location-source change needs no restart:
    // the phone stream runs in both modes and the source is chosen per send.
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
    if (!channel.canBeTrackingChannel) {
      await _rejectIneligibleChannel(channel);
      return;
    }
    if (!channel.isOnRadio) {
      // Kept on the phone but not in a radio slot: there is no slot to send
      // on. Tracking resumes once the channel is added to the radio.
      debugPrint(
          '[TelemetrySend] ⏭️ "${channel.name}" is not on this radio; not sending');
      try {
        await _nativeTelemetryChannel.invokeMethod('stopNativeTelemetry');
      } catch (e) {
        debugPrint('[TelemetrySend] ⚠️ stopNativeTelemetry failed: $e');
      }
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
        ' (locationSource=${_settings.settings.locationSource})');

    _restartPeriodicTimer();
    _updatePhoneStream();
  }

  /// Phone GPS runs only while it is needed: always with location source =
  /// phone, and with source = companion only while the companion has no fresh
  /// fix (the fallback).
  void _updatePhoneStream() {
    final senderRunning = _periodicTimer != null;
    if (senderRunning && !_companionLocation.usingCompanion) {
      _startPhoneStream();
    } else {
      _stopPhoneStream();
    }
  }

  void _startPhoneStream() {
    if (_positionSub != null) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    debugPrint('[TelemetrySend] 📍 Phone GPS on');
    final locationSettings = buildAppLocationSettings(distanceFilter: 5);
    _positionSub =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(_handlePosition, onError: (Object error) {
      debugPrint('[TelemetrySend] ⚠️ Location stream error: $error');
    });
    unawaited(_seedCurrentPosition());
  }

  void _stopPhoneStream() {
    if (_positionSub == null) return;

    debugPrint('[TelemetrySend] 📍 Phone GPS off');
    _positionSub?.cancel();
    _positionSub = null;
    // Would be stale by the time the next fallback needs it.
    _phoneLatitude = null;
    _phoneLongitude = null;
  }

  /// The position to send right now: the companion's while it has a fresh
  /// fix, otherwise the phone's.
  (double, double, String)? _currentLocation() {
    final companionLat = _companionLocation.latitude;
    final companionLon = _companionLocation.longitude;
    if (companionLat != null && companionLon != null) {
      return (companionLat, companionLon, 'companion');
    }

    final phoneLat = _phoneLatitude;
    final phoneLon = _phoneLongitude;
    if (phoneLat != null && phoneLon != null) {
      return (phoneLat, phoneLon, 'phone');
    }
    return null;
  }

  Future<void> _seedCurrentPosition() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
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

    final location = _currentLocation();
    if (location == null) {
      debugPrint('[TelemetrySend] ⚠️ No location for periodic send');
      return;
    }

    debugPrint(
        '[TelemetrySend] 📡 PERIODIC send (TIME trigger, source=${location.$3})');
    await _trySendTelemetry(
      latitude: location.$1,
      longitude: location.$2,
      reason: 'PERIODIC',
      resetPeriodicTimer: false,
    );
  }

  void _handlePosition(Position position) {
    // A seed that resolves after the stream was stopped is no longer wanted.
    if (_positionSub == null) return;

    _phoneLatitude = position.latitude;
    _phoneLongitude = position.longitude;
    _maybeSendForDistance(position.latitude, position.longitude,
        source: 'phone');
  }

  void _maybeSendForDistance(double latitude, double longitude,
      {required String source}) {
    final minDistanceMeters = _settings.settings.telemetryMinDistanceMeters;
    if (minDistanceMeters <= 0) return;

    final lastSent = _lastSentLocation;
    if (lastSent == null) return;

    final distance = Geolocator.distanceBetween(
      lastSent.$1,
      lastSent.$2,
      latitude,
      longitude,
    );

    if (distance >= minDistanceMeters) {
      debugPrint(
          '[TelemetrySend] 📍 DISTANCE trigger ($source): moved ${distance.toInt()}m (threshold: ${minDistanceMeters}m)');
      unawaited(_trySendTelemetry(
        latitude: latitude,
        longitude: longitude,
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
    if (!channel.canBeTrackingChannel) {
      await _rejectIneligibleChannel(channel);
      return;
    }
    if (!channel.isOnRadio) {
      // Kept on the phone but not in a radio slot: there is no slot to send
      // on. Tracking resumes once the channel is added to the radio.
      debugPrint(
          '[TelemetrySend] ⏭️ "${channel.name}" is not on this radio; not sending');
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

  /// Tracking must never broadcast on a channel anyone can join. Clearing the
  /// setting stops sending and shows "none" in the picker, so a tracking
  /// channel saved before this check existed gets reset rather than used.
  Future<void> _rejectIneligibleChannel(ChannelData channel) async {
    debugPrint(
        '[TelemetrySend] 🚫 "${channel.name}" is public or hashtag - clearing tracking channel');
    await _settings.setTelemetryChannelHash(null);
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
    _trackingChannelSub?.cancel();

    if (_started) {
      _settings.removeListener(_onSettingsChanged);
      _bleService.removeListener(_onConnectionChanged);
      _connectionViewModel.removeListener(_onBatteryChanged);
      _companionLocation.removeListener(_onCompanionLocationChanged);
      _forwardingPolicy?.removeListener(_onForwardingPolicyChanged);
    }

    super.dispose();
  }
}
