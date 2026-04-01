// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'offline_map_areas_dao.g.dart';

/// DAO for managing downloaded offline map areas
/// Matches Android OfflineMapAreaDao functionality
@DriftAccessor(tables: [OfflineMapAreas])
class OfflineMapAreasDao extends DatabaseAccessor<AppDatabase>
    with _$OfflineMapAreasDaoMixin {
  OfflineMapAreasDao(super.db);

  Stream<List<OfflineMapAreaData>> watchAllAreas() {
    return (select(offlineMapAreas)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.downloadedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<OfflineMapAreaData>> getAllAreas() {
    return (select(offlineMapAreas)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.downloadedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<OfflineMapAreaData?> getAreaById(String id) {
    return (select(offlineMapAreas)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertArea(OfflineMapAreasCompanion area) {
    return into(offlineMapAreas).insert(area);
  }

  Future<int> deleteAreaById(String id) {
    return (delete(offlineMapAreas)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteAllAreas() {
    return delete(offlineMapAreas).go();
  }

  /// Find areas matching a provider and overlapping bounds (for import merge detection).
  Future<List<OfflineMapAreaData>> findByProviderAndOverlappingBounds({
    required String providerId,
    required double north,
    required double south,
    required double east,
    required double west,
  }) {
    return (select(offlineMapAreas)
          ..where((t) =>
              t.providerId.equals(providerId) &
              t.north.isBiggerOrEqualValue(south) &
              t.south.isSmallerOrEqualValue(north) &
              t.east.isBiggerOrEqualValue(west) &
              t.west.isSmallerOrEqualValue(east)))
        .get();
  }

  Stream<int> watchTotalStorageBytes() {
    final query = selectOnly(offlineMapAreas)
      ..addColumns([offlineMapAreas.sizeBytes.sum()]);

    return query
        .map((row) => (row.read(offlineMapAreas.sizeBytes.sum()) ?? 0))
        .watchSingle();
  }
}
