// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:typed_data';

import 'package:meshcore_team/models/telemetry_message.dart';

/// A parsed #TEL event received from the channel.
///
/// Emitted by [MessageRepository.telemetryStream] after every successfully
/// parsed telemetry channel message.  Strategies subscribe to this stream
/// rather than polling the contact DB for forwarding signals.
class TelemetryEvent {
  /// Display name of the sender as reported in the channel message.
  final String senderName;

  /// Local peer the sender resolved to.
  final int peerId;

  /// The sender's radio key, when known. Null for a sender only known by name.
  final Uint8List? radioPublicKey;

  /// Parsed telemetry payload including [needsForwarding] and
  /// [maxPathObserved] forwarding signals.
  final TelemetryMessage telemetry;

  /// Number of hops the packet took to reach this device (0 = direct).
  final int pathLen;

  /// Wall-clock time this event was received.
  final DateTime receivedAt;

  const TelemetryEvent({
    required this.senderName,
    required this.peerId,
    required this.radioPublicKey,
    required this.telemetry,
    required this.pathLen,
    required this.receivedAt,
  });
}
