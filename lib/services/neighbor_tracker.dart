// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

/// Tracks which contacts this device can directly hear (any packet type).
///
/// Called whenever any channel packet is received. Used to populate the
/// neighbor bitmap in outbound [TopologyMessage] (#T:) payloads.
///
/// Unlike [NetworkTopology] (which tracks the full network adjacency graph),
/// this class only tracks MY direct neighbors — contacts whose packets I
/// personally receive over BLE.
///
/// Entries expire after 60 minutes of silence, matching the Android reference
/// implementation (NeighborTracker.kt).
class NeighborTracker {
  final Map<String, DateTime> _lastHeardTime = {};

  static const Duration _expiry = Duration(hours: 1);

  /// Record that a packet was received from [pubKeyPrefix].
  ///
  /// [pubKeyPrefix] must be a 12-char lowercase hex string
  /// (first 6 bytes of the sender's public key).
  void onPacketReceived(String pubKeyPrefix) {
    _lastHeardTime[pubKeyPrefix] = DateTime.now();
  }

  /// Returns all currently active neighbors, removing stale entries first.
  Set<String> getMyNeighbors() {
    final cutoff = DateTime.now().subtract(_expiry);
    _lastHeardTime.removeWhere((_, t) => t.isBefore(cutoff));
    return Set.unmodifiable(_lastHeardTime.keys);
  }

  /// Whether [pubKeyPrefix] is currently a direct neighbor.
  bool isNeighbor(String pubKeyPrefix) =>
      getMyNeighbors().contains(pubKeyPrefix);

  /// Number of active direct neighbors.
  int get neighborCount => getMyNeighbors().length;

  /// Reset all state (call on companion switch).
  void clear() => _lastHeardTime.clear();
}
