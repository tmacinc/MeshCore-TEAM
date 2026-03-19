// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:meshcore_team/models/telemetry_event.dart';
import 'package:meshcore_team/models/topology_event.dart';
import 'package:meshcore_team/services/forwarding/forwarding_strategy.dart';

/// V1 forwarding strategy driven by incoming #TEL events.
///
/// Algorithm:
///   • Only contacts that have sent at least one #TEL are tracked.
///     Contacts without a TEL entry are ignored entirely.
///   • Forwarding ACTIVATES (from off) when any tracked contact:
///       - reports [needsForwarding]=true in its last #TEL, OR
///       - has not been heard for longer than [_staleThreshold].
///     maxHops = max(observedPathLen across tracked contacts) + 1,
///     clamped to [1.._maxHopsCeiling].
///   • Hold-down STARTS when forwarding is on AND ALL tracked contacts
///     report [maxPathObserved]=0 in their TEL — meaning the entire
///     network agrees it is in a zero-hop condition.  maxHops is held
///     at its current value during the hold to let the network converge.
///   • If forwarding is re-triggered during the hold, the hold is cancelled
///     and forwarding resumes immediately.
///   • After the hold expires without a re-trigger: SET_MAX_HOPS = 0.
///
/// V1 does NOT use SET_FORWARD_LIST — the firmware handles routing internally
/// based solely on maxHops.  The forward list is a V2 concept.
class ForwardingV1Strategy implements ForwardingStrategy {
  static const Duration _staleThreshold = Duration(minutes: 5);
  static const Duration _holdDuration = Duration(minutes: 5);
  static const int _maxHopsCeiling = 4;

  /// Called when internal state changes and a fresh [compute] push is needed
  /// (e.g. hold-down timer expired).  Wired by [ForwardingPolicyService].
  final VoidCallback? onStateChanged;

  ForwardingV1Strategy({this.onStateChanged});

  // Per-contact TEL signals keyed by sender name.
  final Map<String, _V1ContactState> _contactStates = {};

  // Current advisory maxHops value — 0 means forwarding disabled.
  int _currentMaxHops = 0;

  bool _holdActive = false;
  Timer? _holdTimer;

  @override
  String get modeKey => 'forwardingV1';

  /// Update per-contact TEL state on every received #TEL event.
  @override
  void onTelemetry(TelemetryEvent event) {
    _contactStates[event.senderName] = _V1ContactState(
      needsForwarding: event.telemetry.needsForwarding,
      remoteMaxPathObserved: event.telemetry.maxPathObserved,
      // Store the path length WE observed when receiving this packet.
      // This is our direct measurement of network connectivity, not what
      // the remote contact reported.
      observedPathLen: event.pathLen,
      lastReceived: event.receivedAt,
    );
  }

  /// V1 strategy does not use topology data; no-op.
  @override
  void onTopology(TopologyEvent event) {}

  // The needsForwarding and maxPathObserved values we will advertise in our
  // next outgoing #TEL, updated on every compute() call.
  bool _advertiseNeedsForwarding = false;
  int _advertiseMaxPathObserved = 0;

  bool get currentNeedsForwarding => _advertiseNeedsForwarding;
  int get currentMaxPathObserved => _advertiseMaxPathObserved;

  @override
  ForwardingDecision compute(ForwardingStrategyInput input) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final staleMs = _staleThreshold.inMilliseconds;

    int maxObserved = 0;
    bool anyRemoteNeedsForwarding = false;
    bool anyStale = false;
    // True when every tracked contact's last TEL reports maxPathObserved=0,
    // meaning the whole network agrees it is in a zero-hop condition.
    bool allRemoteMaxPathZero = true;
    bool hasTracked = false;

    for (final contact in input.contacts) {
      final name = contact.name ?? '';
      final telState = _contactStates[name];

      // Only track contacts that have sent at least one #TEL.
      if (telState == null) continue;
      hasTracked = true;

      final isStale =
          (nowMs - telState.lastReceived.millisecondsSinceEpoch) > staleMs;
      if (isStale) anyStale = true;
      if (telState.needsForwarding) anyRemoteNeedsForwarding = true;

      if (telState.observedPathLen > maxObserved) {
        maxObserved = telState.observedPathLen;
      }
      if (telState.remoteMaxPathObserved > 0) {
        allRemoteMaxPathZero = false;
      }
    }

    if (!hasTracked) allRemoteMaxPathZero = false;

    _advertiseMaxPathObserved = maxObserved;

    if (_currentMaxHops == 0) {
      // --- FORWARDING IS OFF ---
      // Activate when any remote reports needsForwarding=true OR any
      // contact is stale (lost contact — assume they may need relaying).
      if (anyRemoteNeedsForwarding || anyStale) {
        _cancelHold();
        _currentMaxHops = (maxObserved + 1).clamp(1, _maxHopsCeiling);
        _advertiseNeedsForwarding = true;
        return _decision(
            'Forwarding active: maxObserved=$maxObserved → maxHops=$_currentMaxHops');
      }
      _advertiseNeedsForwarding = false;
      return _decision('No forwarding needed; engine at baseline');
    } else {
      // --- FORWARDING IS ON ---
      // Once ALL contacts report remoteMaxPathObserved=0 the network is in
      // a zero-hop condition.  Start the hold-down timer and advertise
      // needsForwarding=false so peers can begin their own hold-downs.
      if (allRemoteMaxPathZero) {
        _advertiseNeedsForwarding = false;
        if (!_holdActive) _startHold();
        return _decision(
            'Hold-down active; maintaining maxHops=$_currentMaxHops until hold expires');
      }
      // Still multi-hop activity — cancel any hold, update maxHops.
      _cancelHold();
      _currentMaxHops = (maxObserved + 1).clamp(1, _maxHopsCeiling);
      _advertiseNeedsForwarding = true;
      return _decision(
          'Forwarding active: maxObserved=$maxObserved → maxHops=$_currentMaxHops');
    }
  }

  void _startHold() {
    _holdActive = true;
    _holdTimer?.cancel();
    _holdTimer = Timer(_holdDuration, () {
      _holdActive = false;
      _currentMaxHops = 0;
      debugPrint('[ForwardingV1] Hold-down expired — dropping to maxHops=0');
      onStateChanged?.call();
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _holdActive = false;
  }

  ForwardingDecision _decision(String reason) {
    return ForwardingDecision(
      maxHops: _currentMaxHops,
      prefixes: const <Uint8List>[], // V1 does not use the forward list.
      strategyMode: modeKey,
      reason: reason,
      needsForwarding: _advertiseNeedsForwarding,
      maxPathObserved: _advertiseMaxPathObserved,
    );
  }

  @override
  void reset() {
    _cancelHold();
    _contactStates.clear();
    _currentMaxHops = 0;
    _advertiseNeedsForwarding = false;
    _advertiseMaxPathObserved = 0;
    debugPrint('[ForwardingV1] State reset');
  }
}

class _V1ContactState {
  final bool needsForwarding;
  // The maxPathObserved value the remote contact reported in its TEL.
  final int remoteMaxPathObserved;
  // The path length WE observed when receiving this contact's last #TEL.
  final int observedPathLen;
  final DateTime lastReceived;

  const _V1ContactState({
    required this.needsForwarding,
    required this.remoteMaxPathObserved,
    required this.observedPathLen,
    required this.lastReceived,
  });
}
