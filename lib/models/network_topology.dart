// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

/// Manages the network topology graph built from [TopologyMessage] (#T:)
/// neighbor bitmaps.
///
/// Maintains:
/// - a lexicographically sorted list of all known pub_key_prefixes
///   (12-char lowercase hex = first 6 bytes of a contact's public key)
/// - an adjacency map of observed direct-neighbor connections (60-min expiry)
///
/// Bit position i in a received neighbor bitmap corresponds to
/// [getAllNodes()[i]]. All devices must converge to the same sorted list for
/// bitmaps to decode consistently. Convergence happens naturally as #T:
/// messages arrive and each sender is added to the list.
class NetworkTopology {
  final List<String> _sortedPrefixes = [];
  final Map<String, Set<String>> _observedEdges = {};
  final Map<String, DateTime> _lastUpdateTime = {};

  static const Duration _neighborExpiry = Duration(hours: 1);

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  /// Register the local device's pub_key_prefix (12-char lowercase hex).
  /// Call this when SELF_INFO is received so our own node is always present.
  void registerLocalDevice(String pubKeyPrefix) {
    _addPrefix(pubKeyPrefix);
  }

  // ---------------------------------------------------------------------------
  // Ingest
  // ---------------------------------------------------------------------------

  /// Update graph from a received #T: message.
  ///
  /// 1. Adds [senderPrefix] to the sorted list if new.
  /// 2. Decodes the bitmap to find the sender's direct neighbors.
  /// 3. Adds newly discovered node prefixes.
  /// 4. Records the observed edges for [senderPrefix].
  void updateFromTelemetry(
    String senderPrefix,
    Uint8List neighborBitmap,
    int nodeCount,
  ) {
    _addPrefix(senderPrefix);

    if (nodeCount == 0 || neighborBitmap.isEmpty) {
      _cleanupStale();
      return;
    }

    final neighbors = parseNeighborBitmap(neighborBitmap, nodeCount);

    // Add newly discovered neighbor prefixes to the sorted list.
    var needsSort = false;
    for (final p in neighbors) {
      if (!_sortedPrefixes.contains(p)) {
        _sortedPrefixes.add(p);
        needsSort = true;
      }
    }
    if (needsSort) _sortedPrefixes.sort();

    _observedEdges[senderPrefix] = neighbors;
    _lastUpdateTime[senderPrefix] = DateTime.now();

    _cleanupStale();
  }

  // ---------------------------------------------------------------------------
  // Bitmap encode / decode
  // ---------------------------------------------------------------------------

  /// Decode a raw bitmap into the set of neighbor pub_key_prefixes.
  ///
  /// Each byte in [bitmap] has a +1 encoding offset (added during
  /// [buildNeighborBitmap] to avoid 0x00 in BLE transport). This method
  /// subtracts 1 before reading bits.
  ///
  /// Only resolves bit positions present in the current sorted list; unknown
  /// positions are silently skipped until convergence is reached.
  Set<String> parseNeighborBitmap(Uint8List bitmap, int nodeCount) {
    final result = <String>{};
    final limit = math.min(nodeCount, math.min(_sortedPrefixes.length, 32));
    for (var i = 0; i < limit; i++) {
      final byteIdx = i ~/ 8;
      final bitIdx = i % 8;
      if (byteIdx < bitmap.length) {
        // Remove +1 encoding offset, then check the bit.
        final byte = (bitmap[byteIdx] & 0xFF) - 1;
        if (byte >= 0 && ((byte >> bitIdx) & 1) == 1) {
          result.add(_sortedPrefixes[i]);
        }
      }
    }
    return result;
  }

  /// Build a neighbor bitmap for an outbound #T: message.
  ///
  /// [myNeighbors] is the set of pub_key_prefixes this device directly hears
  /// (typically from [NeighborTracker.getMyNeighbors]).
  ///
  /// Returns ceil(totalNodes/8) bytes where bit i is set when
  /// [_sortedPrefixes[i]] is in [myNeighbors]. Each byte has +1 offset
  /// applied to avoid 0x00 values in BLE transport.
  Uint8List buildNeighborBitmap(Set<String> myNeighbors) {
    // Ensure all neighbors are in the sorted list.
    var needsSort = false;
    for (final p in myNeighbors) {
      if (!_sortedPrefixes.contains(p)) {
        _sortedPrefixes.add(p);
        needsSort = true;
      }
    }
    if (needsSort) _sortedPrefixes.sort();

    if (_sortedPrefixes.isEmpty) return Uint8List(0);

    final bitmapSize = (_sortedPrefixes.length + 7) ~/ 8;
    final bitmap = Uint8List(bitmapSize);

    for (var i = 0; i < _sortedPrefixes.length; i++) {
      if (myNeighbors.contains(_sortedPrefixes[i])) {
        bitmap[i ~/ 8] |= (1 << (i % 8));
      }
    }

    // Add +1 offset per byte to avoid 0x00 in BLE transport.
    for (var i = 0; i < bitmap.length; i++) {
      bitmap[i] = (bitmap[i] + 1) & 0xFF;
    }

    return bitmap;
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Total number of known nodes (use as [nodeCount] in outbound packets).
  int getNodeCount() => _sortedPrefixes.length;

  /// All known pub_key_prefixes in sorted order.
  List<String> getAllNodes() => List.unmodifiable(_sortedPrefixes);

  /// Observed direct neighbors of [prefix] (non-stale entries only).
  Set<String> getNeighbors(String prefix) =>
      _observedEdges[prefix]?.toSet() ?? {};

  /// BFS reachability check over observed edges.
  bool hasPath(String source, String dest) {
    if (source == dest) return true;
    final visited = <String>{source};
    final queue = Queue<String>()..add(source);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final nb in _observedEdges[current] ?? const <String>{}) {
        if (nb == dest) return true;
        if (visited.add(nb)) queue.add(nb);
      }
    }
    return false;
  }

  /// Shortest hop distance between [source] and [dest], or null if unreachable.
  int? hopDistance(String source, String dest) {
    if (source == dest) return 0;
    final visited = <String, int>{source: 0};
    final queue = Queue<String>()..add(source);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final depth = visited[current]!;
      for (final nb in _observedEdges[current] ?? const <String>{}) {
        if (nb == dest) return depth + 1;
        if (!visited.containsKey(nb)) {
          visited[nb] = depth + 1;
          queue.add(nb);
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Reset all state (call on companion switch).
  void clear() {
    _sortedPrefixes.clear();
    _observedEdges.clear();
    _lastUpdateTime.clear();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _addPrefix(String prefix) {
    if (!_sortedPrefixes.contains(prefix)) {
      _sortedPrefixes.add(prefix);
      _sortedPrefixes.sort();
    }
  }

  void _cleanupStale() {
    final cutoff = DateTime.now().subtract(_neighborExpiry);
    final stale = _lastUpdateTime.entries
        .where((e) => e.value.isBefore(cutoff))
        .map((e) => e.key)
        .toList();
    for (final k in stale) {
      _observedEdges.remove(k);
      _lastUpdateTime.remove(k);
    }
  }
}
