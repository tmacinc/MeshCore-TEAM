// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
//
// Covers the v12 migration: the per-radio contact_display_states table is
// replaced by peers + peer_locations, and every last known position survives.
//
// Needs a native sqlite3 for the test runner (the app gets one from
// sqlite3_flutter_libs, which does not apply here):
//
//   flutter test test/peer_migration_test.dart \
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

const int _channelHash = 4660; // 0x1234
const int _channelIndex = 2;
const String _companionKey =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _radioKeyHex =
    '1111111111111111111111111111111111111111111111111111111111111111';

Uint8List _bytes(String hex) {
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

/// Builds a database that looks like a v9 install: the peer tables are gone,
/// messages has no sender_peer_id, and the legacy display-state tables hold
/// the data the migration has to carry over.
Future<void> _writeLegacyDatabase(File file) async {
  final db = AppDatabase.forTesting(NativeDatabase(file));

  await db.into(db.channels).insert(ChannelsCompanion.insert(
        hash: const Value(_channelHash),
        name: 'Team',
        sharedKey: Uint8List(16),
        isPublic: false,
        channelIndex: _channelIndex,
        createdAt: 0,
        companionDeviceKey: const Value(_companionKey),
      ));
  await db.into(db.contacts).insert(ContactsCompanion.insert(
        publicKey: _bytes(_radioKeyHex),
        hash: 7,
        name: const Value('Scout'),
        lastSeen: 1000,
        companionBatteryMilliVolts: const Value(4100),
        phoneBatteryMilliVolts: const Value(3900),
        companionDeviceKey: const Value(_companionKey),
      ));
  await db.close();

  final raw = sqlite3.open(file.path);
  raw.execute('DROP TABLE heard_adverts');
  raw.execute('DROP TABLE peer_position_history');
  raw.execute('DROP TABLE peer_locations');
  raw.execute('DROP TABLE peers');
  raw.execute('ALTER TABLE messages DROP COLUMN sender_peer_id');
  raw.execute('''
    CREATE TABLE contact_display_states (
      public_key_hex TEXT NOT NULL PRIMARY KEY,
      companion_device_key TEXT NOT NULL,
      last_seen INTEGER NOT NULL,
      last_latitude REAL,
      last_longitude REAL,
      last_channel_idx INTEGER NOT NULL,
      last_path_len INTEGER NOT NULL,
      is_manually_hidden INTEGER NOT NULL DEFAULT 0,
      hidden_at INTEGER,
      name TEXT,
      first_seen INTEGER NOT NULL,
      total_telemetry_received INTEGER NOT NULL DEFAULT 0,
      is_autonomous_device INTEGER NOT NULL DEFAULT 0
    )''');
  raw.execute('''
    CREATE TABLE contact_position_histories (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      public_key_hex TEXT NOT NULL,
      companion_device_key TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      accuracy REAL,
      channel_idx INTEGER NOT NULL,
      path_len INTEGER NOT NULL,
      battery_voltage REAL,
      bin_level INTEGER NOT NULL,
      is_aggregated INTEGER NOT NULL
    )''');

  // A mesh member, and a radio-less Team Link member under a synthetic key.
  raw.execute(
    'INSERT INTO contact_display_states (public_key_hex, companion_device_key, '
    'last_seen, last_latitude, last_longitude, last_channel_idx, last_path_len, '
    'is_manually_hidden, name, first_seen, total_telemetry_received) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      _radioKeyHex.toUpperCase(),
      _companionKey,
      5000,
      51.5,
      -0.12,
      _channelIndex,
      2,
      1,
      'Scout',
      1000,
      42,
    ],
  );
  raw.execute(
    'INSERT INTO contact_display_states (public_key_hex, companion_device_key, '
    'last_seen, last_latitude, last_longitude, last_channel_idx, last_path_len, '
    'is_manually_hidden, name, first_seen, total_telemetry_received) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      'CLOUD:U:1A2B3C4D5E6F7788',
      _companionKey,
      6000,
      48.0,
      2.35,
      _channelIndex,
      0,
      0,
      'Relay',
      2000,
      7,
    ],
  );
  raw.execute('PRAGMA user_version = 9');
  raw.dispose();
}

void main() {
  if (_dllPath.isEmpty) {
    test('peer migration (skipped: no DLL configured)', () {},
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
  late AppDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('peer_migration');
    file = File('${dir.path}/meshcore_team.db');
    await _writeLegacyDatabase(file);
    db = AppDatabase.forTesting(NativeDatabase(file));
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('every last known position survives the upgrade', () async {
    final located = await db.peersDao.watchPeersWithLocation().first;

    expect(located.length, 2);
    // The peer tables arrived in v12; later versions must still migrate.
    expect(db.schemaVersion, greaterThanOrEqualTo(12));
  });

  test('a mesh member keeps its key, name, position and battery', () async {
    final located = await db.peersDao.watchPeersWithLocation().first;
    final scout =
        located.firstWhere((m) => m.peer.radioName == 'Scout');

    expect(scout.peer.radioPublicKey, _bytes(_radioKeyHex));
    expect(scout.peer.radioKeyPrefix, '111111111111');
    expect(scout.peer.isTeamMember, isTrue);
    // The channel slot index is replaced by the radio-independent hash.
    expect(scout.location.lastChannelHash, _channelHash);
    expect(scout.location.lastLatitude, 51.5);
    expect(scout.location.lastPathLen, 2);
    expect(scout.location.totalTelemetryReceived, 42);
    expect(scout.location.isManuallyHidden, isTrue);
    expect(scout.location.companionBatteryMilliVolts, 4100);
    expect(scout.location.phoneBatteryMilliVolts, 3900);
  });

  test('a Team Link member becomes a peer with an app identity, no radio key',
      () async {
    final located = await db.peersDao.watchPeersWithLocation().first;
    final relay = located.firstWhere((m) => m.peer.radioName == 'Relay');

    expect(relay.peer.radioPublicKey, isNull);
    expect(relay.peer.appIdentityId, '1a2b3c4d5e6f7788');
    expect(relay.location.lastLongitude, 2.35);
  });

  test('the legacy tables are gone and messages gained sender_peer_id',
      () async {
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final names = tables.map((r) => r.read<String>('name')).toSet();

    expect(names, isNot(contains('contact_display_states')));
    expect(names, isNot(contains('contact_position_histories')));
    expect(names,
        containsAll(['peers', 'peer_locations', 'peer_position_history']));
    expect(names, contains('heard_adverts'));

    final columns =
        await db.customSelect('PRAGMA table_info(messages)').get();
    expect(
      columns.map((r) => r.read<String>('name')),
      contains('sender_peer_id'),
    );
  });
}
