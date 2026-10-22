// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
//
// Covers the upgrade to schema 16, the clean start for 1.2: radio mirrors and
// everything learned about teammates are cleared, the user's own data is kept.
//
// The 1.1.7 database is built from the exact DDL a 1.1.7 install writes
// (schema 9), not from today's tables: migration steps that read through
// today's schema are what broke the upgrade from 1.1.7.
//
// Needs a native sqlite3 for the test runner (the app gets one from
// sqlite3_flutter_libs, which does not apply here):
//
//   flutter test test/upgrade_clean_start_test.dart \
//     --dart-define=MBTILES_SQLITE_DLL=C:\Python314\DLLs\sqlite3.dll

import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

const _dllPath = String.fromEnvironment('MBTILES_SQLITE_DLL');

const String _radioKeyHex =
    '7be168ea918661f70d2ff9cd68a44a47e646b20b2515d3ccd27ce04850322a73';
const String _teammateKeyHex =
    'd8aef9b400f2154669f0cb69c80595082e96b86c879bc1f1476b9c7d0371c29a';
const int _teamChannelHash = 845718843;

/// Schema 9, as written by a 1.1.7 install.
const _v9Schema = [
  'CREATE TABLE "ack_records" ("message_id" TEXT NOT NULL, "acker_public_key" BLOB NOT NULL, "received_at" INTEGER NOT NULL, "snr" INTEGER NULL, "rssi" INTEGER NULL, "companion_device_key" TEXT NULL, PRIMARY KEY ("message_id", "acker_public_key"))',
  'CREATE TABLE "channels" ("hash" INTEGER NOT NULL, "name" TEXT NOT NULL, "shared_key" BLOB NOT NULL, "is_public" INTEGER NOT NULL CHECK ("is_public" IN (0, 1)), "share_location" INTEGER NOT NULL DEFAULT 0 CHECK ("share_location" IN (0, 1)), "channel_index" INTEGER NOT NULL, "created_at" INTEGER NOT NULL, "notification_mode" TEXT NOT NULL DEFAULT \'normal\', "is_favorite" INTEGER NOT NULL DEFAULT 0 CHECK ("is_favorite" IN (0, 1)), "companion_device_key" TEXT NULL, PRIMARY KEY ("hash"))',
  'CREATE TABLE "companion_devices" ("public_key_hex" TEXT NOT NULL, "name" TEXT NOT NULL, "first_connected" INTEGER NOT NULL, "last_connected" INTEGER NOT NULL, "connection_count" INTEGER NOT NULL DEFAULT 1, PRIMARY KEY ("public_key_hex"))',
  'CREATE TABLE "contact_display_states" ("public_key_hex" TEXT NOT NULL, "companion_device_key" TEXT NOT NULL, "last_seen" INTEGER NOT NULL, "last_latitude" REAL NULL, "last_longitude" REAL NULL, "last_channel_idx" INTEGER NOT NULL, "last_path_len" INTEGER NOT NULL, "is_manually_hidden" INTEGER NOT NULL DEFAULT 0 CHECK ("is_manually_hidden" IN (0, 1)), "hidden_at" INTEGER NULL, "name" TEXT NULL, "first_seen" INTEGER NOT NULL, "total_telemetry_received" INTEGER NOT NULL DEFAULT 0, "is_autonomous_device" INTEGER NOT NULL DEFAULT 0 CHECK ("is_autonomous_device" IN (0, 1)), PRIMARY KEY ("public_key_hex"))',
  'CREATE TABLE "contact_position_histories" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "public_key_hex" TEXT NOT NULL, "companion_device_key" TEXT NOT NULL, "timestamp" INTEGER NOT NULL, "latitude" REAL NOT NULL, "longitude" REAL NOT NULL, "accuracy" REAL NULL, "channel_idx" INTEGER NOT NULL, "path_len" INTEGER NOT NULL, "battery_voltage" REAL NULL, "bin_level" INTEGER NOT NULL, "is_aggregated" INTEGER NOT NULL CHECK ("is_aggregated" IN (0, 1)))',
  'CREATE TABLE "contacts" ("public_key" BLOB NOT NULL, "hash" INTEGER NOT NULL, "name" TEXT NULL, "latitude" REAL NULL, "longitude" REAL NULL, "last_seen" INTEGER NOT NULL, "companion_battery_milli_volts" INTEGER NULL, "phone_battery_milli_volts" INTEGER NULL, "is_repeater" INTEGER NOT NULL DEFAULT 0 CHECK ("is_repeater" IN (0, 1)), "is_room_server" INTEGER NOT NULL DEFAULT 0 CHECK ("is_room_server" IN (0, 1)), "is_direct" INTEGER NOT NULL DEFAULT 0 CHECK ("is_direct" IN (0, 1)), "hop_count" INTEGER NOT NULL DEFAULT -1, "last_telemetry_channel_idx" INTEGER NULL, "last_telemetry_timestamp" INTEGER NULL, "is_out_of_range" INTEGER NOT NULL DEFAULT 0 CHECK ("is_out_of_range" IN (0, 1)), "is_autonomous_device" INTEGER NOT NULL DEFAULT 0 CHECK ("is_autonomous_device" IN (0, 1)), "companion_device_key" TEXT NULL, "is_favorite" INTEGER NOT NULL DEFAULT 0 CHECK ("is_favorite" IN (0, 1)), PRIMARY KEY ("public_key"))',
  'CREATE TABLE "imported_overlay_maps" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "dir_path" TEXT NOT NULL, "tile_count" INTEGER NOT NULL, "imported_at" INTEGER NOT NULL, "is_visible" INTEGER NOT NULL DEFAULT 1 CHECK ("is_visible" IN (0, 1)), "bounds_north" REAL NOT NULL, "bounds_south" REAL NOT NULL, "bounds_east" REAL NOT NULL, "bounds_west" REAL NOT NULL, "layer_type" TEXT NOT NULL DEFAULT \'kmz\', "min_zoom" INTEGER NULL, "max_zoom" INTEGER NULL, "opacity" REAL NOT NULL DEFAULT 1.0, "size_bytes" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"))',
  'CREATE TABLE "messages" ("id" TEXT NOT NULL, "sender_id" BLOB NOT NULL, "sender_name" TEXT NULL, "channel_hash" INTEGER NOT NULL, "content" TEXT NOT NULL, "timestamp" INTEGER NOT NULL, "is_private" INTEGER NOT NULL CHECK ("is_private" IN (0, 1)), "ack_checksum" BLOB NULL, "delivery_status" TEXT NOT NULL, "heard_by_count" INTEGER NOT NULL DEFAULT 0, "attempt" INTEGER NOT NULL DEFAULT 0, "is_sent_by_me" INTEGER NOT NULL CHECK ("is_sent_by_me" IN (0, 1)), "is_read" INTEGER NOT NULL DEFAULT 0 CHECK ("is_read" IN (0, 1)), "companion_device_key" TEXT NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "offline_map_areas" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "provider_id" TEXT NOT NULL, "north" REAL NOT NULL, "south" REAL NOT NULL, "east" REAL NOT NULL, "west" REAL NOT NULL, "min_zoom" INTEGER NOT NULL, "max_zoom" INTEGER NOT NULL, "tile_count" INTEGER NOT NULL, "downloaded_at" INTEGER NOT NULL, "size_bytes" INTEGER NOT NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "waypoints" ("id" TEXT NOT NULL, "mesh_id" TEXT NULL, "name" TEXT NOT NULL, "description" TEXT NOT NULL DEFAULT \'\', "latitude" REAL NOT NULL, "longitude" REAL NOT NULL, "waypoint_type" TEXT NOT NULL, "creator_node_id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "is_received" INTEGER NOT NULL DEFAULT 0 CHECK ("is_received" IN (0, 1)), "is_visible" INTEGER NOT NULL DEFAULT 1 CHECK ("is_visible" IN (0, 1)), "is_new" INTEGER NOT NULL DEFAULT 0 CHECK ("is_new" IN (0, 1)), PRIMARY KEY ("id"))',
];

/// What a 1.1.7 phone holds after using its own radio and, once, a
/// teammate's: the teammate's radio is in companion_devices, and the teammate
/// is a contact with a last known position on the team channel.
void _writeV9Database(File file) {
  final raw = sqlite3.open(file.path);
  for (final ddl in _v9Schema) {
    raw.execute(ddl);
  }
  raw.execute(
      'INSERT INTO companion_devices VALUES (?, ?, 0, 0, 4), (?, ?, 0, 0, 1)',
      [_radioKeyHex, 'R1-Radio', _teammateKeyHex, 'R2-Radio']);
  raw.execute(
      'INSERT INTO channels (hash, name, shared_key, is_public, channel_index, '
      'created_at, companion_device_key) VALUES (?, ?, ?, 0, 3, 0, ?)',
      [_teamChannelHash, 'UpgradeTest', List.filled(16, 1), _radioKeyHex]);
  raw.execute(
      'INSERT INTO contacts (public_key, hash, name, last_seen, '
      'companion_device_key) VALUES (?, 7, ?, 1000, ?)',
      [_hexBytes(_teammateKeyHex), 'R2-Radio', _radioKeyHex]);
  raw.execute(
      'INSERT INTO contact_display_states (public_key_hex, '
      'companion_device_key, last_seen, last_latitude, last_longitude, '
      'last_channel_idx, last_path_len, name, first_seen, '
      'total_telemetry_received) VALUES (?, ?, 5000, 44.8, -75.5, 3, 0, ?, '
      '1000, 42)',
      [_teammateKeyHex, _radioKeyHex, 'R2-Radio']);
  _insertUserData(raw);
  raw.execute('PRAGMA user_version = 9');
  raw.dispose();
}

/// Rows the clean start must keep. Same columns in schema 9 and 16.
void _insertUserData(Database raw) {
  raw.execute(
      'INSERT INTO messages (id, sender_id, sender_name, channel_hash, '
      'content, timestamp, is_private, delivery_status, is_sent_by_me) '
      'VALUES (?, ?, ?, ?, ?, 1, 0, ?, 1)',
      ['m1', List.filled(32, 0), 'R1-Radio', _teamChannelHash, 'beep', 'SENT']);
  raw.execute(
      'INSERT INTO waypoints (id, name, latitude, longitude, waypoint_type, '
      'creator_node_id, created_at) VALUES (?, ?, 44.8, -75.5, ?, ?, 1)',
      ['w1', 'keepMe', 'CUSTOM', 'me']);
  raw.execute(
      'INSERT INTO offline_map_areas VALUES '
      '(?, ?, ?, 45, 44, -75, -76, 10, 14, 169, 1, 1337513)',
      ['a1', 'map', 'osm']);
  raw.execute(
      'INSERT INTO imported_overlay_maps (id, name, dir_path, tile_count, '
      'imported_at, bounds_north, bounds_south, bounds_east, bounds_west) '
      'VALUES (?, ?, ?, 4, 1, 45, 44, -75, -76)',
      ['o1', 'trails', '/overlays/o1']);
}

Uint8List _hexBytes(String hex) => Uint8List.fromList([
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ]);

Future<Set<String>> _tableNames(AppDatabase db) async => (await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get())
    .map((r) => r.read<String>('name'))
    .toSet();

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

Future<void> _expectCleanStart(AppDatabase db) async {
  final version = await db.customSelect('PRAGMA user_version').getSingle();
  expect(version.data.values.single, db.schemaVersion);

  for (final table in const [
    'contacts',
    'channels',
    'companion_devices',
    'peers',
    'peer_locations',
    'peer_position_history',
    'heard_adverts',
  ]) {
    expect(await _count(db, table), 0, reason: '$table should be cleared');
  }

  final message = await db.messagesDao.getMessageById('m1');
  expect(message?.content, 'beep');
  expect(message?.senderPeerId, isNull);
  expect((await db.waypointsDao.getAllWaypoints()).single.name, 'keepMe');
  expect((await db.offlineMapAreasDao.getAllAreas()).single.tileCount, 169);
  expect(await _count(db, 'imported_overlay_maps'), 1);
}

void main() {
  if (_dllPath.isEmpty) {
    test('upgrade clean start (skipped: no DLL configured)', () {},
        skip: 'Pass --dart-define=MBTILES_SQLITE_DLL');
    return;
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    open.overrideFor(
        OperatingSystem.windows, () => DynamicLibrary.open(_dllPath));
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open(_dllPath));
  });

  late Directory dir;
  late File file;
  AppDatabase? db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('upgrade_clean_start');
    file = File('${dir.path}/meshcore_team.db');
  });

  tearDown(() async {
    await db?.close();
    db = null;
    await dir.delete(recursive: true);
  });

  test('1.1.7 database upgrades to a clean start', () async {
    _writeV9Database(file);
    db = AppDatabase.forTesting(NativeDatabase(file));

    await _expectCleanStart(db!);
    final names = await _tableNames(db!);
    expect(names, isNot(contains('contact_display_states')));
    expect(names, isNot(contains('contact_position_histories')));
  });

  // Builds up to beta5 crashed in the v12 step on this database and left it
  // at version 9 with the peer tables already created. The next launch has
  // to finish the upgrade rather than fail again.
  test('a 1.1.7 database left half-migrated still upgrades', () async {
    _writeV9Database(file);
    final raw = sqlite3.open(file.path);
    raw.execute('CREATE TABLE "peers" ("id" INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, "radio_public_key" BLOB NULL UNIQUE, '
        '"radio_key_prefix" TEXT NULL, "app_identity_id" TEXT NULL UNIQUE, '
        '"radio_name" TEXT NULL, "alias" TEXT NULL, "alias_updated_at" '
        'INTEGER NULL, "cap_flags" INTEGER NULL, "cap_observed_at" INTEGER '
        'NULL, "is_team_member" INTEGER NOT NULL DEFAULT 0, '
        '"last_team_channel_hash" INTEGER NULL, "first_seen" INTEGER NOT NULL, '
        '"last_seen" INTEGER NOT NULL)');
    raw.execute("INSERT INTO peers (radio_name, first_seen, last_seen) "
        "VALUES ('R2-Radio', 1000, 5000)");
    raw.dispose();
    db = AppDatabase.forTesting(NativeDatabase(file));

    await _expectCleanStart(db!);
  });

  test('a 1.2 beta database (schema 15) upgrades to a clean start', () async {
    final beta = AppDatabase.forTesting(NativeDatabase(file));
    await beta.customStatement('SELECT 1'); // create the current schema
    await beta.close();
    final raw = sqlite3.open(file.path);
    raw.execute(
        'INSERT INTO companion_devices VALUES (?, ?, 0, 0, 1)',
        [_teammateKeyHex, 'R2-Radio']);
    raw.execute(
        'INSERT INTO channels (hash, name, shared_key, is_public, '
        'channel_index, created_at, companion_device_key, is_team) '
        'VALUES (?, ?, ?, 0, 3, 0, ?, 1)',
        [_teamChannelHash, 'UpgradeTest', List.filled(16, 1), _radioKeyHex]);
    raw.execute(
        'INSERT INTO contacts (public_key, hash, name, last_seen) '
        'VALUES (?, 7, ?, 1000)',
        [_hexBytes(_teammateKeyHex), 'R2-Radio']);
    raw.execute("INSERT INTO peers (id, radio_name, first_seen, last_seen) "
        "VALUES (1, 'R2-Radio', 1000, 5000)");
    raw.execute('INSERT INTO peer_locations (peer_id, last_seen, '
        'last_channel_hash, last_path_len, first_seen) VALUES (1, 5000, ?, 0, '
        '1000)', [_teamChannelHash]);
    _insertUserData(raw);
    raw.execute('UPDATE messages SET sender_peer_id = 1');
    raw.execute('PRAGMA user_version = 15');
    raw.dispose();
    db = AppDatabase.forTesting(NativeDatabase(file));

    await _expectCleanStart(db!);
  });
}
