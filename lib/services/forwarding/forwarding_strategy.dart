// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:typed_data';

import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/telemetry_event.dart';
import 'package:meshcore_team/models/topology_event.dart';
import 'package:meshcore_team/services/contact_capability_service.dart';

class ForwardingDecision {
  final int maxHops;
  final List<Uint8List> prefixes;
  final String strategyMode;
  final String reason;

  /// Whether this node currently needs forwarding — broadcast in outgoing #TEL.
  final bool needsForwarding;

  /// Max path length this node has observed — broadcast in outgoing #TEL.
  final int maxPathObserved;

  const ForwardingDecision({
    required this.maxHops,
    required this.prefixes,
    required this.strategyMode,
    required this.reason,
    this.needsForwarding = false,
    this.maxPathObserved = 0,
  });
}

class ForwardingStrategyInput {
  final List<ContactData> contacts;

  /// Per-peer capability state keyed by sender name.
  /// Strategies should call [ContactCapabilityService.hasConfirmedForwarding]
  /// or inspect [ContactCapabilityState] directly. Missing or stale entries
  /// must be treated as stock firmware (no confirmed capability).
  final ContactCapabilityService capabilities;

  const ForwardingStrategyInput({
    required this.contacts,
    required this.capabilities,
  });
}

abstract class ForwardingStrategy {
  String get modeKey;

  /// Called by [ForwardingPolicyService] for every parsed #TEL event while
  /// this strategy is active. Strategies that maintain reactive state
  /// (e.g. ForwardingV1Strategy) override this; the default is a no-op.
  void onTelemetry(TelemetryEvent event) {}

  /// Called by [ForwardingPolicyService] for every parsed #T: topology event
  /// while this strategy is active. The default is a no-op; topology-aware
  /// strategies override this to update their internal graph model.
  void onTopology(TopologyEvent event) {}

  /// Compute the current forwarding decision from the latest contact snapshot.
  /// Called periodically and on contact-list changes.
  ForwardingDecision compute(ForwardingStrategyInput input);

  /// Called when the companion switches or the engine stops, so the strategy
  /// can reset any accumulated state.
  void reset() {}
}
