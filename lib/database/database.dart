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

part 'database.g.dart';

// Type aliases for convenience
typedef Contact = ContactData;
typedef Channel = ChannelData;
typedef Message = MessageData;
typedef Waypoint = WaypointData;
typedef CompanionDevice = CompanionDeviceData;
typedef ContactDisplayState = ContactDisplayStateData;
typedef ContactPositionHistory = ContactPositionHistoryData;
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
    ContactDisplayStates,
    ContactPositionHistories,
    AckRecords,
    OfflineMapAreas,
  ],
  daos: [
    ContactsDao,
    ChannelsDao,
    MessagesDao,
    WaypointsDao,
    AckRecordsDao,
    CompanionDevicesDao,
    OfflineMapAreasDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Test constructor for in-memory database
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
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

          // Migration from schema version 6 to 7: Add isAutonomousDevice to contact_display_states
          if (from <= 6 && to >= 7) {
            await m.addColumn(
                contactDisplayStates, contactDisplayStates.isAutonomousDevice);
            print(
                '[Migration] Added isAutonomousDevice to contact_display_states table');
          }
        },
      );
}

/// Opens a connection to the database
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'meshcore_team.db'));
    return NativeDatabase(file);
  });
}
