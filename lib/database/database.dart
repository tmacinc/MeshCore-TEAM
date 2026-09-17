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
  int get schemaVersion => 12;

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
          // Migration from schema version 1 to 2: Add isRead column to Messages table
          if (from == 1 && to >= 2) {
            await m.addColumn(messages, messages.isRead);
          }

          // Migration from schema version 2 to 3: Fix isPrivate flag for channel messages
          if (from <= 2 && to >= 3) {
            // Get all channel hashes
            final channelHashes =
                await (select(channels)).map((c) => c.hash).get();

            // Update messages that belong to channels to have isPrivate=false
            for (final channelHash in channelHashes) {
              await (update(messages)
                    ..where((t) => t.channelHash.equals(channelHash)))
                  .write(MessagesCompanion(
                isPrivate: const Value(false),
              ));
            }

            print(
                '[Migration] Fixed isPrivate flag for ${channelHashes.length} channels');
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
          // contact_display_states. That table is replaced in v12 (below), and
          // the v12 copy doesn't read the column, so there is nothing to do.

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
          // radio-independent peer tables. Last known positions are copied
          // over; the short position trail is dropped.
          if (from <= 11 && to >= 12) {
            await m.createTable(peers);
            await m.createTable(peerLocations);
            await m.createTable(peerPositionHistory);
            await m.addColumn(messages, messages.senderPeerId);
            final copied = await _copyLegacyDisplayStates();
            await customStatement(
                'DROP TABLE IF EXISTS contact_position_histories');
            await customStatement('DROP TABLE IF EXISTS contact_display_states');
            print(
                '[Migration] v11->v12: peers created, $copied last known positions kept');
          }
        },
      );

  /// Copies each legacy contact_display_states row into a peer plus its last
  /// known location. Returns the number of rows copied.
  Future<int> _copyLegacyDisplayStates() async {
    final tables = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name = 'contact_display_states'",
    ).get();
    if (tables.isEmpty) return 0;

    final rows = await customSelect(
      'SELECT s.public_key_hex, s.last_seen, s.last_latitude, '
      's.last_longitude, s.last_path_len, s.is_manually_hidden, s.hidden_at, '
      's.name, s.first_seen, s.total_telemetry_received, '
      '(SELECT c.hash FROM channels c '
      ' WHERE c.channel_index = s.last_channel_idx '
      ' AND c.companion_device_key = s.companion_device_key LIMIT 1) '
      'AS channel_hash '
      'FROM contact_display_states s',
    ).get();

    var copied = 0;
    for (final row in rows) {
      final keyHex = row.read<String>('public_key_hex');
      final lastSeen = row.read<int>('last_seen');
      final firstSeen = row.read<int>('first_seen');

      // Team Link builds store radio-less peers under synthetic CLOUD: keys.
      Uint8List? radioKey;
      String? appId;
      if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(keyHex)) {
        radioKey = _hexToBytes(keyHex);
      } else if (keyHex.startsWith('CLOUD:U:')) {
        appId = keyHex.substring('CLOUD:U:'.length).toLowerCase();
      }

      if (radioKey != null) {
        final key = radioKey;
        final existing = await (select(peers)
              ..where((t) => t.radioPublicKey.equals(key)))
            .getSingleOrNull();
        if (existing != null) continue;
      }

      final channelHash = row.readNullable<int>('channel_hash');
      final peerId = await into(peers).insert(PeersCompanion.insert(
        radioPublicKey: Value(radioKey),
        radioKeyPrefix:
            Value(radioKey == null ? null : keyHex.substring(0, 12).toLowerCase()),
        appIdentityId: Value(appId),
        radioName: Value(row.readNullable<String>('name')),
        isTeamMember: const Value(true),
        lastTeamChannelHash: Value(channelHash),
        firstSeen: firstSeen,
        lastSeen: lastSeen,
      ));

      ContactData? contact;
      if (radioKey != null) {
        final key = radioKey;
        contact = await (select(contacts)
              ..where((t) => t.publicKey.equals(key))
              ..limit(1))
            .getSingleOrNull();
      }

      await into(peerLocations).insert(PeerLocationsCompanion.insert(
        peerId: Value(peerId),
        lastSeen: lastSeen,
        lastLatitude: Value(row.readNullable<double>('last_latitude')),
        lastLongitude: Value(row.readNullable<double>('last_longitude')),
        // 0 when the channel is gone: kept on record, not shown on the map.
        lastChannelHash: channelHash ?? 0,
        lastPathLen: row.read<int>('last_path_len'),
        companionBatteryMilliVolts: Value(contact?.companionBatteryMilliVolts),
        phoneBatteryMilliVolts: Value(contact?.phoneBatteryMilliVolts),
        isAutonomousDevice: Value(contact?.isAutonomousDevice ?? false),
        isManuallyHidden: Value(row.read<int>('is_manually_hidden') != 0),
        hiddenAt: Value(row.readNullable<int>('hidden_at')),
        firstSeen: firstSeen,
        totalTelemetryReceived:
            Value(row.read<int>('total_telemetry_received')),
      ));
      copied++;
    }
    return copied;
  }

  static Uint8List _hexToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
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
