// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'peers_dao.g.dart';

/// A peer joined with its last known location.
class PeerWithLocation {
  final PeerData peer;
  final PeerLocationData location;

  const PeerWithLocation(this.peer, this.location);
}

/// DAO for peer identity, last known locations and the recent position trail.
@DriftAccessor(tables: [Peers, PeerLocations, PeerPositionHistory])
class PeersDao extends DatabaseAccessor<AppDatabase> with _$PeersDaoMixin {
  PeersDao(super.db);

  // --- Peers ---

  Future<List<PeerData>> getAllPeers() => select(peers).get();

  Future<PeerData?> getPeer(int id) =>
      (select(peers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertPeer(PeersCompanion peer) => into(peers).insert(peer);

  Future<void> updatePeer(int id, PeersCompanion changes) =>
      (update(peers)..where((t) => t.id.equals(id))).write(changes);

  /// Removes a peer and everything hanging off it. Messages keep their text
  /// but lose the sender link, since the peer they named is gone.
  Future<void> deletePeer(int id) {
    return transaction(() async {
      await (delete(peerPositionHistory)..where((t) => t.peerId.equals(id)))
          .go();
      await (delete(peerLocations)..where((t) => t.peerId.equals(id))).go();
      await (update(db.messages)..where((t) => t.senderPeerId.equals(id)))
          .write(const MessagesCompanion(senderPeerId: Value(null)));
      await (delete(peers)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Moves everything that references [dropId] onto [keepId], then deletes
  /// [dropId]. The newer of the two locations is kept.
  Future<void> mergePeers({required int keepId, required int dropId}) {
    return transaction(() async {
      final keepLoc = await getLocation(keepId);
      final dropLoc = await getLocation(dropId);
      if (dropLoc != null &&
          (keepLoc == null || dropLoc.lastSeen > keepLoc.lastSeen)) {
        await (delete(peerLocations)..where((t) => t.peerId.equals(keepId)))
            .go();
        await (update(peerLocations)..where((t) => t.peerId.equals(dropId)))
            .write(PeerLocationsCompanion(peerId: Value(keepId)));
      } else {
        await (delete(peerLocations)..where((t) => t.peerId.equals(dropId)))
            .go();
      }

      await (update(peerPositionHistory)
            ..where((t) => t.peerId.equals(dropId)))
          .write(PeerPositionHistoryCompanion(peerId: Value(keepId)));
      await (update(db.messages)..where((t) => t.senderPeerId.equals(dropId)))
          .write(MessagesCompanion(senderPeerId: Value(keepId)));
      await (delete(peers)..where((t) => t.id.equals(dropId))).go();
    });
  }

  // --- Locations ---

  Future<PeerLocationData?> getLocation(int peerId) =>
      (select(peerLocations)..where((t) => t.peerId.equals(peerId)))
          .getSingleOrNull();

  Future<void> upsertLocation(PeerLocationsCompanion location) =>
      into(peerLocations).insertOnConflictUpdate(location);

  Future<void> setHidden(int peerId, {required bool hidden}) {
    return (update(peerLocations)..where((t) => t.peerId.equals(peerId)))
        .write(PeerLocationsCompanion(
      isManuallyHidden: Value(hidden),
      hiddenAt: Value(hidden ? DateTime.now().millisecondsSinceEpoch : null),
    ));
  }

  /// All peers that have a location, with that location.
  Stream<List<PeerWithLocation>> watchPeersWithLocation() {
    final query = select(peerLocations).join([
      innerJoin(peers, peers.id.equalsExp(peerLocations.peerId)),
    ]);
    return query.watch().map((rows) => [
          for (final row in rows)
            PeerWithLocation(
              row.readTable(peers),
              row.readTable(peerLocations),
            ),
        ]);
  }

  // --- Position trail ---

  Future<PeerPositionData?> getLatestPosition(int peerId) {
    return (select(peerPositionHistory)
          ..where((t) => t.peerId.equals(peerId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<PeerPositionData>> getPositions(int peerId) {
    return (select(peerPositionHistory)
          ..where((t) => t.peerId.equals(peerId))
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]))
        .get();
  }

  Stream<List<PeerPositionData>> watchPositions(Set<int> peerIds) {
    return (select(peerPositionHistory)
          ..where((t) => t.peerId.isIn(peerIds))
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]))
        .watch();
  }

  Future<void> insertPosition(PeerPositionHistoryCompanion position) =>
      into(peerPositionHistory).insert(position);

  Future<void> deletePositions(List<int> ids) =>
      (delete(peerPositionHistory)..where((t) => t.id.isIn(ids))).go();

  Future<int> deletePositionsOlderThan(int timestampMs) {
    return (delete(peerPositionHistory)
          ..where((t) => t.timestamp.isSmallerThanValue(timestampMs)))
        .go();
  }
}
