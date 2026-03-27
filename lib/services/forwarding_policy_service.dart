// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/database/daos/contacts_dao.dart';
import 'package:meshcore_team/database/daos/channels_dao.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/models/network_topology.dart';
import 'package:meshcore_team/models/topology_event.dart';
import 'package:meshcore_team/services/contact_capability_service.dart';
import 'package:meshcore_team/services/forwarding/forwarding_strategy.dart';
import 'package:meshcore_team/services/forwarding/forwarding_v1_strategy.dart';
import 'package:meshcore_team/services/forwarding/topology_forwarding_strategy.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import 'package:meshcore_team/repositories/message_repository.dart';
import 'package:meshcore_team/models/telemetry_event.dart';

class ForwardingPolicyService extends ChangeNotifier {
  static const Duration _periodicInterval = Duration(seconds: 60);
  static const Duration _minPushInterval = Duration(seconds: 20);

  /// Forwarding requires more than 2 group members (i.e. at least 2 other
  /// visible contacts besides yourself) to be useful.
  static const int _minGroupMembersForForwarding = 2;

  final SettingsService _settings;
  final ConnectionViewModel _connectionViewModel;
  final ContactsDao _contactsDao;
  final ContactCapabilityService _capabilityService;
  final MessageRepository _messageRepository;
  final AppDatabase _database;

  late final ForwardingV1Strategy _v1Strategy;
  late final TopologyForwardingStrategy _topologyStrategy;
  late final NetworkTopology _networkTopology;

  bool _started = false;
  String? _activeCompanionKey;

  Timer? _periodicTimer;
  StreamSubscription<String?>? _companionKeySub;
  StreamSubscription<List<ContactData>>? _contactsSub;
  StreamSubscription<TelemetryEvent>? _telemetrySub;
  StreamSubscription<TopologyEvent>? _topologySub;
  StreamSubscription<List<ContactDisplayStateData>>? _displayStatesSub;

  /// Nullable: null = not yet loaded (no filter applied), non-null = filtered set.
  Set<String>? _mapVisibleKeys;
  int? _trackingChannelIndex;
  List<ContactDisplayStateData> _latestDisplayStates = const [];

  List<ContactData> _latestContacts = const [];
  DateTime _lastPolicyPushAt = DateTime.fromMillisecondsSinceEpoch(0);
  String _lastPolicySignature = '';
  String _lastModeLog = '';

  int? _lastAppliedMaxHops;
  int? get lastAppliedMaxHops => _lastAppliedMaxHops;

  int _lastAppliedPrefixCount = 0;
  int get lastAppliedPrefixCount => _lastAppliedPrefixCount;

  String? _lastAppliedTrigger;
  String? get lastAppliedTrigger => _lastAppliedTrigger;

  String _lastAppliedStrategy = ForwardingAlgorithmMode.forwardingV1;
  String get lastAppliedStrategy => _lastAppliedStrategy;

  DateTime? _lastAppliedAt;
  DateTime? get lastAppliedAt => _lastAppliedAt;

  String? _lastPolicyError;
  String? get lastPolicyError => _lastPolicyError;

  /// The needsForwarding and maxPathObserved values the active strategy wants
  /// broadcast in the next outgoing #TEL packet.
  bool get currentNeedsForwarding => _v1Strategy.currentNeedsForwarding;
  int get currentMaxPathObserved => _v1Strategy.currentMaxPathObserved;

  bool get isPolicyEngineActive => _shouldRun;
  String get forwardingMode => _currentForwardingMode();
  String get selectedAlgorithmMode =>
      _settings.settings.forwardingAlgorithmMode;
  String get effectiveAlgorithmMode => _resolveStrategy().modeKey;

  /// True when the tracking channel has too few visible members for
  /// forwarding to be useful (≤2 total including yourself).
  bool get insufficientGroupMembers {
    final keys = _mapVisibleKeys;
    return keys == null || keys.length < _minGroupMembersForForwarding;
  }

  ForwardingPolicyService({
    required SettingsService settings,
    required ConnectionViewModel connectionViewModel,
    required ContactsDao contactsDao,
    required ContactCapabilityService capabilityService,
    required MessageRepository messageRepository,
    required AppDatabase database,
    required NetworkTopology networkTopology,
  })  : _settings = settings,
        _connectionViewModel = connectionViewModel,
        _contactsDao = contactsDao,
        _capabilityService = capabilityService,
        _messageRepository = messageRepository,
        _database = database,
        _networkTopology = networkTopology {
    _v1Strategy = ForwardingV1Strategy(
      onStateChanged: _onStrategyStateChanged,
    );
    _topologyStrategy = TopologyForwardingStrategy(fallback: _v1Strategy);
  }

  void start() {
    if (_started) return;
    _started = true;

    _settings.addListener(_onSettingsChanged);
    _connectionViewModel.addListener(_onConnectionChanged);

    _telemetrySub =
        _messageRepository.telemetryStream.listen(_onTelemetryEvent);

    _topologySub = _messageRepository.topologyStream.listen(_onTopologyEvent);

    // Watch all display states and filter map-visible ones reactively.
    _displayStatesSub = _database
        .select(_database.contactDisplayStates)
        .watch()
        .listen((states) {
      _latestDisplayStates = states;
      _rebuildMapVisibleKeys();
      if (_shouldRun) unawaited(_applyPolicyIfNeeded(trigger: 'displayStates'));
    });

    unawaited(_resolveAndCacheTrackingChannelIndex());

    _companionKeySub =
        _settings.currentCompanionPublicKeyStream.listen((companionKey) {
      _switchCompanion(companionKey);
    });

    _refreshLifecycle(trigger: 'start');
  }

  void _onTelemetryEvent(TelemetryEvent event) {
    _resolveStrategy().onTelemetry(event);
    if (_shouldRun) {
      unawaited(_applyPolicyIfNeeded(trigger: 'telemetry'));
    }
  }

  void _onTopologyEvent(TopologyEvent event) {
    _resolveStrategy().onTopology(event);
    if (_shouldRun) {
      unawaited(_applyPolicyIfNeeded(trigger: 'topology'));
    }
  }

  void _onStrategyStateChanged() {
    unawaited(_applyPolicyIfNeeded(trigger: 'hold_expired'));
  }

  void _onSettingsChanged() {
    unawaited(_resolveAndCacheTrackingChannelIndex());
    _refreshLifecycle(trigger: 'settings');
  }

  Future<void> _resolveAndCacheTrackingChannelIndex() async {
    final hashStr = _settings.settings.telemetryChannelHash;
    if (hashStr == null || hashStr.isEmpty) {
      _trackingChannelIndex = null;
      _rebuildMapVisibleKeys();
      return;
    }
    final hash = int.tryParse(hashStr) ??
        int.tryParse(hashStr.replaceFirst('0x', ''), radix: 16);
    if (hash == null) {
      _trackingChannelIndex = null;
      _rebuildMapVisibleKeys();
      return;
    }
    final channel = await _database.channelsDao.getChannelByHash(hash);
    _trackingChannelIndex = channel?.channelIndex;
    _rebuildMapVisibleKeys();
    if (_shouldRun) unawaited(_applyPolicyIfNeeded(trigger: 'channelResolved'));
  }

  void _rebuildMapVisibleKeys() {
    final companionKey = _activeCompanionKey;
    final channelIdx = _trackingChannelIndex;

    if (companionKey == null || companionKey.isEmpty || channelIdx == null) {
      _mapVisibleKeys = null;
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const cutoffMs = 12 * 60 * 60 * 1000; // 12 hours

    final visible = _latestDisplayStates.where((state) {
      if (state.companionDeviceKey != companionKey) return false;
      if (state.isManuallyHidden) return false;
      if (state.totalTelemetryReceived <= 0) return false;
      if (state.lastChannelIdx != channelIdx) return false;
      if (state.lastLatitude == null || state.lastLongitude == null)
        return false;
      return (nowMs - state.lastSeen) <= cutoffMs;
    });

    _mapVisibleKeys = {for (final s in visible) s.publicKeyHex};
  }

  void _onConnectionChanged() {
    _refreshLifecycle(trigger: 'connection');
  }

  bool get _firmwareSupportsForwarding {
    final capabilities = _connectionViewModel.deviceCapabilities;
    return capabilities != null &&
        capabilities.isCustomFirmware &&
        capabilities.supportsForwarding;
  }

  bool get _shouldRun {
    final appSettings = _settings.settings;
    if (!_connectionViewModel.isConnected) return false;
    if (!_firmwareSupportsForwarding) return false;
    if (!appSettings.telemetryEnabled) return false;
    // Non-camp: engine always active for custom firmware — no toggle required.
    if (!appSettings.campModeEnabled) return true;
    // Camp: engine active only when the smart forwarding toggle is on.
    return appSettings.smartForwardingEnabled;
  }

  String _currentForwardingMode() {
    final appSettings = _settings.settings;

    if (!_connectionViewModel.isConnected) {
      return 'DISABLED_DISCONNECTED';
    }
    if (!appSettings.telemetryEnabled) {
      return 'DISABLED_TRACKING_OFF';
    }

    final selected = appSettings.forwardingAlgorithmMode;
    final effective = _resolveStrategy().modeKey;

    if (appSettings.campModeEnabled) {
      if (_firmwareSupportsForwarding && appSettings.smartForwardingEnabled) {
        return 'CAMP_POLICY_ENGINE[$selected->$effective]';
      }
      return 'CAMP_DEFAULT_ROUTING';
    }

    // Non-camp
    if (_firmwareSupportsForwarding) {
      return 'POLICY_ENGINE[$selected->$effective]';
    }
    return 'DEFAULT_ROUTING';
  }

  void _logModeIfChanged({required String trigger}) {
    final mode = _currentForwardingMode();
    if (_lastModeLog == mode) return;
    _lastModeLog = mode;
    notifyListeners();
    debugPrint('[ForwardingPolicy] MODE=$mode (trigger=$trigger)');
  }

  void _refreshLifecycle({required String trigger}) {
    _logModeIfChanged(trigger: trigger);

    if (_shouldRun) {
      _startPeriodicIfNeeded();
      unawaited(_applyPolicyIfNeeded(trigger: trigger));
    } else {
      _stopPeriodic();
    }
  }

  void _startPeriodicIfNeeded() {
    if (_periodicTimer != null) return;
    _periodicTimer = Timer.periodic(_periodicInterval, (_) {
      unawaited(_applyPolicyIfNeeded(trigger: 'periodic'));
    });
  }

  void _stopPeriodic() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void _switchCompanion(String? companionKey) {
    if (_activeCompanionKey == companionKey) return;
    _activeCompanionKey = companionKey;

    _contactsSub?.cancel();
    _contactsSub = null;
    _latestContacts = const [];
    _mapVisibleKeys = null;
    _lastPolicySignature = '';
    _lastAppliedMaxHops = null;
    _lastAppliedPrefixCount = 0;
    _lastAppliedTrigger = null;
    _lastAppliedAt = null;
    _lastPolicyError = null;
    _lastAppliedStrategy = ForwardingAlgorithmMode.forwardingV1;
    _resolveStrategy().reset();
    _networkTopology.clear();
    notifyListeners();

    if (companionKey == null || companionKey.isEmpty) {
      return;
    }

    // Rebuild map-visible keys for the new companion immediately from cached states.
    _rebuildMapVisibleKeys();

    _contactsSub =
        _contactsDao.watchContactsByCompanion(companionKey).listen((contacts) {
      _latestContacts = contacts;
      if (_shouldRun) {
        unawaited(_applyPolicyIfNeeded(trigger: 'topology'));
      }
    });
  }

  Future<void> _applyPolicyIfNeeded({required String trigger}) async {
    if (!_shouldRun) return;

    final now = DateTime.now();
    final sinceLastPush = now.difference(_lastPolicyPushAt);
    if (sinceLastPush < _minPushInterval && trigger != 'periodic') {
      return;
    }

    // Forwarding requires more than 2 group members to be useful.
    if (insufficientGroupMembers) {
      final keys = _mapVisibleKeys;
      debugPrint('[ForwardingPolicy] ⏸️ Skipping: group too small'
          ' (${keys?.length ?? 0} visible contacts,'
          ' need $_minGroupMembersForForwarding)');
      return;
    }

    final decision = _computeDecision();
    final signature = _buildSignature(decision);

    if (signature == _lastPolicySignature && trigger != 'periodic') {
      return;
    }

    final maxHopsOk = await _connectionViewModel.setMaxHops(decision.maxHops);
    if (!maxHopsOk) {
      _lastPolicyError = 'Failed to set max hops';
      notifyListeners();
      debugPrint('[ForwardingPolicy] ❌ Failed to set max hops');
      return;
    }

    final forwardListOk =
        await _connectionViewModel.setForwardList(decision.prefixes);
    if (!forwardListOk) {
      _lastPolicyError = 'Failed to set forward list';
      notifyListeners();
      debugPrint('[ForwardingPolicy] ❌ Failed to set forward list');
      return;
    }

    _lastPolicyPushAt = now;
    _lastPolicySignature = signature;
    _lastAppliedMaxHops = decision.maxHops;
    _lastAppliedPrefixCount = decision.prefixes.length;
    _lastAppliedTrigger = trigger;
    _lastAppliedStrategy = decision.strategyMode;
    _lastAppliedAt = now;
    _lastPolicyError = null;
    notifyListeners();

    debugPrint(
      '[ForwardingPolicy] ✅ Applied policy: mode=${_currentForwardingMode()}, strategy=${decision.strategyMode}, reason=${decision.reason}, maxHops=${decision.maxHops}, prefixes=${decision.prefixes.length}, trigger=$trigger',
    );
  }

  ForwardingDecision _computeDecision() {
    final strategy = _resolveStrategy();
    final candidates = _mapVisibleContacts();
    return strategy.compute(ForwardingStrategyInput(
      contacts: candidates,
      capabilities: _capabilityService,
    ));
  }

  /// Returns the map-visible subset of [_latestContacts].
  /// Falls back to the full list if display states haven't loaded yet.
  List<ContactData> _mapVisibleContacts() {
    final keys = _mapVisibleKeys;
    if (keys == null || keys.isEmpty) return const [];
    return _latestContacts.where((c) {
      final hex = c.publicKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();
      return keys.contains(hex);
    }).toList(growable: false);
  }

  ForwardingStrategy _resolveStrategy() {
    final mode = _settings.settings.forwardingAlgorithmMode;

    switch (mode) {
      case ForwardingAlgorithmMode.topology:
        return _topologyStrategy;
      case ForwardingAlgorithmMode.auto:
        return _topologyStrategy;
      case ForwardingAlgorithmMode.forwardingV1:
      default:
        return _v1Strategy;
    }
  }

  String _buildSignature(ForwardingDecision decision) {
    final prefixHex = decision.prefixes
        .map((prefix) => prefix
            .map((value) => value.toRadixString(16).padLeft(2, '0'))
            .join())
        .join(',');
    return '${decision.strategyMode}|${decision.maxHops}|$prefixHex';
  }

  @override
  void dispose() {
    _stopPeriodic();
    _contactsSub?.cancel();
    _companionKeySub?.cancel();
    _telemetrySub?.cancel();
    _topologySub?.cancel();
    _displayStatesSub?.cancel();
    _resolveStrategy().reset();

    if (_started) {
      _settings.removeListener(_onSettingsChanged);
      _connectionViewModel.removeListener(_onConnectionChanged);
    }

    super.dispose();
  }
}
