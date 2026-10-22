// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'daos/contacts_dao.dart';
import 'daos/channels_dao.dart';
import 'daos/messages_dao.dart';
import 'daos/waypoints_dao.dart';
import 'daos/ack_records_dao.dart';
import 'daos/companion_devices_dao.dart';
import 'daos/offline_map_areas_dao.dart';
import 'daos/imported_overlay_maps_dao.dart';
import 'daos/peers_dao.dart';
import 'daos/heard_adverts_dao.dart';

part 'database.g.dart';

// Type aliases for convenience
typedef Contact = ContactData;
typedef Channel = ChannelData;
typedef Message = MessageData;
typedef Waypoint = WaypointData;
typedef CompanionDevice = CompanionDeviceData;
typedef AckRecord = AckRecordData;

/// Main database class for TEAM-Flutter
///
/// Manages all database tables and DAOs for the mesh networking app.
/// Uses Drift (SQLite) for local data persistence.
///
/// Schema matches Android TEAM app (meshcore-team) exactly.
@DriftDatabase(
  tables: [
    Contacts,
    Channels,
    Messages,
    Waypoints,
    CompanionDevices,
    Peers,
    PeerLocations,
    PeerPositionHistory,
    HeardAdverts,
    AckRecords,
    OfflineMapAreas,
    ImportedOverlayMaps,
  ],
  daos: [
    ContactsDao,
    ChannelsDao,
    MessagesDao,
    WaypointsDao,
    AckRecordsDao,
    CompanionDevicesDao,
    OfflineMapAreasDao,
    ImportedOverlayMapsDao,
    PeersDao,
    HeardAdvertsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Test constructor for in-memory database
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  // Jumps 9 -> 12: the Team Link branch (D0sockets) already uses 10 and 11,
  // so dev skips them to keep the two branches mergeable. See
  // docs/alias-peer-identity-plan.md §3.5.
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // Converge the live schema onto what drift expects, whatever state
          // this database was left in (see _reconcileSchema).
          await _reconcileSchema();

          // Patch any NULLs left by a partial earlier migration.
          await customStatement(
            'UPDATE contacts SET is_favorite = 0 WHERE is_favorite IS NULL',
          );
          await customStatement(
            "UPDATE channels SET notification_mode = 'normal' WHERE notification_mode IS NULL",
          );
          await customStatement(
            'UPDATE channels SET is_favorite = 0 WHERE is_favorite IS NULL',
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // One transaction for every step: a step that throws leaves the
          // database at its old version, as it was, instead of half-migrated
          // and failing the same way on every launch.
          //
          // Steps use raw SQL for data. A typed query (select(contacts)...)
          // reads every column of the *current* schema, including ones a
          // later step hasn't added yet, and throws on an older database.
          await transaction(() => _upgrade(m, from, to));
        },
      );

  Future<void> _upgrade(Migrator m, int from, int to) async {
    // Migration from schema version 1 to 2: Add isRead column to Messages table
    if (from == 1 && to >= 2) {
      await m.addColumn(messages, messages.isRead);
    }

    // Migration from schema version 2 to 3: Fix isPrivate flag for channel messages
    if (from <= 2 && to >= 3) {
      await customStatement(
        'UPDATE messages SET is_private = 0 '
        'WHERE channel_hash IN (SELECT hash FROM channels)',
      );
      print('[Migration] Fixed isPrivate flag for channel messages');
    }

    // Migration from schema version 3 to 4: Add companionDeviceKey to AckRecords table
    if (from <= 3 && to >= 4) {
      await m.addColumn(ackRecords, ackRecords.companionDeviceKey);
      print('[Migration] Added companionDeviceKey to ack_records table');
    }

    // Migration from schema version 4 to 5: Add offline_map_areas table
    if (from <= 4 && to >= 5) {
      await m.createTable(offlineMapAreas);
      print('[Migration] Created offline_map_areas table');
    }

    // Migration from schema version 5 to 6: Add isAutonomousDevice to contacts
    if (from <= 5 && to >= 6) {
      await m.addColumn(contacts, contacts.isAutonomousDevice);
      print('[Migration] Added isAutonomousDevice to contacts table');
    }

    // Schema version 6 to 7 added is_autonomous_device to
    // contact_display_states. That table is dropped in v12 (below), so
    // there is nothing to do.

    // Migration from schema version 7 to 8: new tables, favorites, channel notification mode
    if (from <= 7 && to >= 8) {
      await m.createTable(importedOverlayMaps);
      await m.addColumn(contacts, contacts.isFavorite);
      await customStatement(
        "ALTER TABLE channels ADD COLUMN notification_mode TEXT NOT NULL DEFAULT 'normal'",
      );
      await customStatement(
        'ALTER TABLE channels ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
      );
      print('[Migration] v7->v8: importedOverlayMaps, favorites, channel notification mode');
    }

    // Migration from schema version 8 to 9: imported overlay maps gain a
    // layer-type discriminator so MBTiles and geospatial PDF imports can
    // share the table with the original KMZ rows. Existing rows keep the
    // 'kmz' default, so no data rewrite is needed.
    if (from <= 8 && to >= 9) {
      await m.addColumn(importedOverlayMaps, importedOverlayMaps.layerType);
      await m.addColumn(importedOverlayMaps, importedOverlayMaps.minZoom);
      await m.addColumn(importedOverlayMaps, importedOverlayMaps.maxZoom);
      await m.addColumn(importedOverlayMaps, importedOverlayMaps.opacity);
      await m.addColumn(importedOverlayMaps, importedOverlayMaps.sizeBytes);
      print('[Migration] v8->v9: imported_overlay_maps layer_type/zoom/opacity/size_bytes');
    }

    // Versions 10 and 11 belong to the Team Link branch (D0sockets); dev
    // never used them. Their additive changes are covered by
    // _reconcileSchema when that branch merges.

    // Migration to schema version 12: peer identity. Replaces the
    // per-radio contact_display_states / contact_position_histories with
    // radio-independent peer tables. Nothing is carried over: v16 starts
    // the peer tables empty.
    if (from <= 11 && to >= 12) {
      await m.createTable(peers);
      await m.createTable(peerLocations);
      await m.createTable(peerPositionHistory);
      await _addColumnIfMissing(m, messages, messages.senderPeerId);
      await customStatement(
          'DROP TABLE IF EXISTS contact_position_histories');
      await customStatement('DROP TABLE IF EXISTS contact_display_states');
      print('[Migration] v11->v12: peers created');
    }

    // Migration to schema version 13: adverts the radio declined to
    // store, listed for the user instead of being dropped.
    if (from <= 12 && to >= 13) {
      await m.createTable(heardAdverts);
      print('[Migration] v12->v13: heard_adverts');
    }

    // Migration to schema version 14: team channels are owned by the
    // phone, so they survive a radio switch and can be absent from the
    // radio's slots.
    if (from <= 13 && to >= 14) {
      await _addColumnIfMissing(m, channels, channels.isTeam);
      await _addColumnIfMissing(m, channels, channels.firmwareConfirmed);

      // The tracking channel is marked as a team channel by
      // ChannelRepository.markTrackingChannelAsTeam() at startup, which
      // is where the setting lives.
      print('[Migration] v13->v14: channels isTeam, firmwareConfirmed');
    }

    // Migration to schema version 15: repeaters can be hidden from the
    // map's repeater layer one at a time.
    if (from <= 14 && to >= 15) {
      await _addColumnIfMissing(m, contacts, contacts.hideOnMap);
      print('[Migration] v14->v15: contacts hideOnMap');
    }

    // Migration to schema version 16: a clean start for 1.2. What the
    // phone knows about radios and teammates is cleared, and comes back
    // from the radio on the next connection and from live traffic.
    // Data from 1.1.x or earlier 1.2 betas could otherwise hide
    // teammates: companion_devices lists every radio this phone has
    // used, which PeerDirectory treats as its own, and channel rows are
    // looked up by radio and slot. The user's own data (messages,
    // waypoints, offline areas, overlays) is kept.
    //
    // SettingsService clears the matching contact sync cursors, or the
    // next sync would only fetch contacts changed since the last one.
    if (from <= 15 && to >= 16) {
      for (final table in const [
        'peer_position_history',
        'peer_locations',
        'peers',
        'heard_adverts',
        'contacts',
        'channels',
        'companion_devices',
      ]) {
        await customStatement('DELETE FROM $table');
      }
      await customStatement('UPDATE messages SET sender_peer_id = NULL');
      print('[Migration] v15->v16: radio and peer data cleared');
    }
  }

  /// Adds a column unless the table already has it. A duplicate-column error
  /// aborts the whole migration, and the same column can legitimately already
  /// be there: the schema counter means different things on `dev` and the
  /// Team Link branch, so a database can arrive with part of a later version
  /// already applied.
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    final existing = (await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get())
        .map((row) => row.read<String>('name'))
        .toSet();
    if (existing.contains(column.name)) return;
    await m.addColumn(table, column);
  }

  /// Brings the live database up to the schema drift expects, regardless of
  /// the version it was last opened at or which branch's build wrote it.
  ///
  /// `schemaVersion` is a single counter, but `dev` and `D0sockets` advance it
  /// independently, so the integer alone cannot tell us which tables and
  /// columns a given database has. This inspects the database itself and adds
  /// whatever is missing.
  ///
  /// Additive only: it creates missing tables and columns, and never drops,
  /// renames, or retypes. Anything else needs an explicit [onUpgrade] step.
  /// New non-nullable columns must carry a default, and added columns must
  /// not be UNIQUE (SQLite can't add those with ALTER TABLE).
  Future<void> _reconcileSchema() async {
    final existingTables = (await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get())
        .map((row) => row.read<String>('name'))
        .toSet();

    final m = createMigrator();

    for (final table in allTables) {
      if (!existingTables.contains(table.actualTableName)) {
        await m.createTable(table);
        print('[Schema] Created missing table ${table.actualTableName}');
        continue;
      }

      final existingColumns = (await customSelect(
        'PRAGMA table_info(${table.actualTableName})',
      ).get())
          .map((row) => row.read<String>('name'))
          .toSet();

      for (final column in table.$columns) {
        if (!existingColumns.contains(column.name)) {
          await m.addColumn(table, column);
          print(
              '[Schema] Added missing column ${table.actualTableName}.${column.name}');
        }
      }
    }
  }
}

/// Opens a connection to the database
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'meshcore_team.db'));
    return NativeDatabase.createInBackground(file);
  });
}
