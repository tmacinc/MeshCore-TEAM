// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:meshcore_team/models/topology_message.dart';

/// A parsed #T: event received from the channel.
///
/// Emitted by [MessageRepository.topologyStream] after every successfully
/// parsed topology channel message. Forwarding strategies subscribe to this
/// stream to maintain an up-to-date view of the network graph.
class TopologyEvent {
  /// Display name of the sender as reported in the channel message.
  final String senderName;

  /// 12-char lowercase hex (first 6 bytes of the sender's public key).
  /// Used as the node identifier in [NetworkTopology].
  final String senderPubKeyHex;

  /// Parsed topology payload including the raw neighbor bitmap and position.
  final TopologyMessage message;

  /// Direct neighbors of the sender decoded from the bitmap after the topology
  /// graph was updated. May be empty if the sorted prefix list is not yet
  /// fully converged.
  final Set<String> neighbors;

  /// Number of hops the packet took to reach this device (0 = direct).
  final int pathLen;

  /// Wall-clock time this event was received.
  final DateTime receivedAt;

  const TopologyEvent({
    required this.senderName,
    required this.senderPubKeyHex,
    required this.message,
    required this.neighbors,
    required this.pathLen,
    required this.receivedAt,
  });
}
