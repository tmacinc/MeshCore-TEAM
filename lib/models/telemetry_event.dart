// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:meshcore_team/models/telemetry_message.dart';

/// A parsed #TEL event received from the channel.
///
/// Emitted by [MessageRepository.telemetryStream] after every successfully
/// parsed telemetry channel message.  Strategies subscribe to this stream
/// rather than polling the contact DB for forwarding signals.
class TelemetryEvent {
  /// Display name of the sender as reported in the channel message.
  final String senderName;

  /// Parsed telemetry payload including [needsForwarding] and
  /// [maxPathObserved] forwarding signals.
  final TelemetryMessage telemetry;

  /// Number of hops the packet took to reach this device (0 = direct).
  final int pathLen;

  /// Wall-clock time this event was received.
  final DateTime receivedAt;

  const TelemetryEvent({
    required this.senderName,
    required this.telemetry,
    required this.pathLen,
    required this.receivedAt,
  });
}
