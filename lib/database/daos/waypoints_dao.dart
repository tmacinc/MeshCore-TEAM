// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'waypoints_dao.g.dart';

/// DAO for managing GPS waypoints
/// Matches Android WaypointDao functionality
@DriftAccessor(tables: [Waypoints])
class WaypointsDao extends DatabaseAccessor<AppDatabase>
    with _$WaypointsDaoMixin {
  WaypointsDao(super.db);

  /// Get all waypoints ordered by creation time
  Future<List<WaypointData>> getAllWaypoints() {
    return (select(waypoints)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get visible waypoints only
  Future<List<WaypointData>> getVisibleWaypoints() {
    return (select(waypoints)
          ..where((t) => t.isVisible.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get new (unviewed) waypoints
  Future<List<WaypointData>> getNewWaypoints() {
    return (select(waypoints)
          ..where((t) => t.isNew.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get waypoints by type
  Future<List<WaypointData>> getWaypointsByType(String type) {
    return (select(waypoints)
          ..where((t) => t.waypointType.equals(type))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get locally created waypoints
  Future<List<WaypointData>> getLocalWaypoints() {
    return (select(waypoints)
          ..where((t) => t.isReceived.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get received waypoints
  Future<List<WaypointData>> getReceivedWaypoints() {
    return (select(waypoints)
          ..where((t) => t.isReceived.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get a single waypoint by ID
  Future<WaypointData?> getWaypointById(String id) {
    return (select(waypoints)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get a waypoint by mesh ID (for deduplication)
  Future<WaypointData?> getWaypointByMeshId(String meshId) {
    return (select(waypoints)..where((t) => t.meshId.equals(meshId)))
        .getSingleOrNull();
  }

  /// Insert a new waypoint
  Future<void> insertWaypoint(WaypointsCompanion waypoint) {
    return into(waypoints).insert(waypoint);
  }

  /// Update waypoint
  Future<void> updateWaypoint(String id, WaypointsCompanion waypoint) {
    return (update(waypoints)..where((t) => t.id.equals(id))).write(waypoint);
  }

  /// Mark waypoint as viewed (no longer new)
  Future<void> markAsViewed(String id) {
    return (update(waypoints)..where((t) => t.id.equals(id)))
        .write(WaypointsCompanion(
      isNew: const Value(false),
    ));
  }

  /// Mark all waypoints as viewed
  Future<void> markAllAsViewed() {
    return (update(waypoints)..where((t) => t.isNew.equals(true)))
        .write(WaypointsCompanion(
      isNew: const Value(false),
    ));
  }

  /// Toggle waypoint visibility
  Future<void> toggleVisibility(String id, bool isVisible) {
    return (update(waypoints)..where((t) => t.id.equals(id)))
        .write(WaypointsCompanion(
      isVisible: Value(isVisible),
    ));
  }

  /// Delete a waypoint
  Future<int> deleteWaypoint(String id) {
    return (delete(waypoints)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all waypoints
  Future<int> deleteAllWaypoints() {
    return delete(waypoints).go();
  }

  /// Delete all received waypoints (bulk action)
  Future<int> deleteAllReceivedWaypoints() {
    return (delete(waypoints)..where((t) => t.isReceived.equals(true))).go();
  }

  /// Delete all local waypoints (bulk action)
  Future<int> deleteAllLocalWaypoints() {
    return (delete(waypoints)..where((t) => t.isReceived.equals(false))).go();
  }

  /// Watch all waypoints (stream)
  Stream<List<WaypointData>> watchAllWaypoints() {
    return (select(waypoints)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Watch visible waypoints (stream)
  Stream<List<WaypointData>> watchVisibleWaypoints() {
    return (select(waypoints)
          ..where((t) => t.isVisible.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Watch a single waypoint (stream)
  Stream<WaypointData?> watchWaypoint(String id) {
    return (select(waypoints)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Watch new waypoints count (stream)
  Stream<int> watchNewWaypointCount() {
    final query = selectOnly(waypoints)
      ..addColumns([waypoints.id.count()])
      ..where(waypoints.isNew.equals(true));

    return query
        .map((row) => row.read(waypoints.id.count()) ?? 0)
        .watchSingle();
  }

  /// Get waypoint count
  Future<int> getWaypointCount() async {
    final query = selectOnly(waypoints)..addColumns([waypoints.id.count()]);

    final result = await query.getSingle();
    return result.read(waypoints.id.count()) ?? 0;
  }
}
