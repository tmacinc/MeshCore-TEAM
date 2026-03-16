// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:meshcore_team/models/telemetry_event.dart';
import 'package:meshcore_team/models/topology_event.dart';
import 'package:meshcore_team/services/forwarding/forwarding_strategy.dart';
import 'package:meshcore_team/services/forwarding/forwarding_v1_strategy.dart';

class TopologyForwardingStrategy implements ForwardingStrategy {
  final ForwardingV1Strategy _fallback;

  TopologyForwardingStrategy({
    required ForwardingV1Strategy fallback,
  }) : _fallback = fallback;

  @override
  String get modeKey => 'topology';

  /// Forward TEL events to the V1 fallback so its state stays current
  /// while topology strategy is active.
  @override
  void onTelemetry(TelemetryEvent event) => _fallback.onTelemetry(event);

  /// Forward topology events to the V1 fallback so its state stays current.
  /// Actual topology-aware routing decisions are deferred to Item 10 design discussion.
  @override
  void onTopology(TopologyEvent event) => _fallback.onTopology(event);

  @override
  void reset() => _fallback.reset();

  @override
  ForwardingDecision compute(ForwardingStrategyInput input) {
    final fallbackDecision = _fallback.compute(input);

    return ForwardingDecision(
      maxHops: fallbackDecision.maxHops,
      prefixes: fallbackDecision.prefixes,
      strategyMode: modeKey,
      reason:
          'Topology strategy skeleton active; currently falling back to ForwardingV1 until #T graph model is implemented',
    );
  }
}
