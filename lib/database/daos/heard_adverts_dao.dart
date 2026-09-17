// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'heard_adverts_dao.g.dart';

/// DAO for adverts the radio heard but did not store.
@DriftAccessor(tables: [HeardAdverts, Contacts])
class HeardAdvertsDao extends DatabaseAccessor<AppDatabase>
    with _$HeardAdvertsDaoMixin {
  HeardAdvertsDao(super.db);

  /// Records an advert, or refreshes one already listed. A newer advert
  /// clears an earlier dismissal, so the node reappears when it is heard
  /// again rather than staying hidden forever.
  Future<void> record({
    required Uint8List publicKey,
    required String name,
    required int advertType,
    required int lastAdvertTimestamp,
    double? latitude,
    double? longitude,
  }) async {
    final existing = await (select(heardAdverts)
          ..where((t) => t.publicKey.equals(publicKey)))
        .getSingleOrNull();

    final isNewer = existing == null ||
        lastAdvertTimestamp > existing.lastAdvertTimestamp;

    await into(heardAdverts).insertOnConflictUpdate(HeardAdvertsCompanion(
      publicKey: Value(publicKey),
      name: Value(name),
      advertType: Value(advertType),
      latitude: Value(latitude),
      longitude: Value(longitude),
      lastHeard: Value(DateTime.now().millisecondsSinceEpoch),
      lastAdvertTimestamp: Value(lastAdvertTimestamp),
      dismissedAt: isNewer
          ? const Value(null)
          : Value(existing.dismissedAt),
    ));
  }

  /// Nodes worth offering: not dismissed, and not already a contact.
  Stream<List<HeardAdvertData>> watchPending() {
    final query = select(heardAdverts)
      ..where((t) => t.dismissedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.lastHeard, mode: OrderingMode.desc),
      ]);

    return query.watch().asyncMap((rows) async {
      if (rows.isEmpty) return rows;
      final known = (await select(contacts).get())
          .map((c) => _hex(c.publicKey))
          .toSet();
      return rows.where((r) => !known.contains(_hex(r.publicKey))).toList();
    });
  }

  Future<void> dismiss(Uint8List publicKey) {
    return (update(heardAdverts)..where((t) => t.publicKey.equals(publicKey)))
        .write(HeardAdvertsCompanion(
      dismissedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> remove(Uint8List publicKey) {
    return (delete(heardAdverts)..where((t) => t.publicKey.equals(publicKey)))
        .go();
  }

  Future<int> deleteOlderThan(int timestampMs) {
    return (delete(heardAdverts)
          ..where((t) => t.lastHeard.isSmallerThanValue(timestampMs)))
        .go();
  }

  /// Keeps the list bounded on a busy mesh: drops the oldest beyond [limit].
  Future<void> trimTo(int limit) async {
    final all = await (select(heardAdverts)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastHeard, mode: OrderingMode.desc),
          ]))
        .get();
    if (all.length <= limit) return;

    for (final row in all.skip(limit)) {
      await remove(row.publicKey);
    }
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
