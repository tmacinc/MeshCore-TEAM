// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
//
// Needs a native sqlite3 for the test runner (the app gets one from
// sqlite3_flutter_libs, which does not apply here):
//
//   flutter test test/peer_directory_test.dart \
//     --dart-define=MBTILES_SQLITE_DLL=C:\Python314\DLLs\sqlite3.dll

import 'dart:ffi';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/services/peer_directory.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';

const _dllPath = String.fromEnvironment('MBTILES_SQLITE_DLL');

const int _trackingChannelHash = 0xABCD;

Uint8List _key(int seed) =>
    Uint8List.fromList(List.generate(32, (i) => (seed + i) & 0xFF));

ContactData _contact(String name, int seed) => ContactData(
      publicKey: _key(seed),
      hash: seed,
      name: name,
      lastSeen: 0,
      isRepeater: false,
      isRoomServer: false,
      isDirect: true,
      hopCount: 0,
      isOutOfRange: false,
      isAutonomousDevice: false,
      isFavorite: false,
    );

void main() {
  if (_dllPath.isEmpty) {
    test('peer directory (skipped: no DLL configured)', () {},
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

  late AppDatabase db;
  late PeerDirectory peers;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    peers = PeerDirectory(
      peersDao: db.peersDao,
      contactsDao: db.contactsDao,
      settings: SettingsService(await SharedPreferences.getInstance()),
    );
    await peers.start();
  });

  tearDown(() async {
    peers.dispose();
    await db.close();
  });

  Future<PeerResolution> resolve(
    String name, {
    List<ContactData> contacts = const [],
  }) {
    return peers.resolveChannelSender(
      radioName: name,
      radioContacts: contacts,
      channelHash: _trackingChannelHash,
      isTeamChannel: true,
    );
  }

  group('resolveChannelSender', () {
    test('an unknown sender becomes one placeholder peer, not several',
        () async {
      final first = await resolve('Scout');
      final second = await resolve('Scout');

      expect(first.state, PeerResolutionState.unresolved);
      expect(first.peer.radioPublicKey, isNull);
      expect(second.peer.id, first.peer.id);
      expect(peers.all.length, 1);
    });

    test('concurrent packets from a new sender create one peer', () async {
      final results = await Future.wait([
        resolve('Scout'),
        resolve('Scout'),
        resolve('Scout'),
      ]);

      expect(results.map((r) => r.peer.id).toSet().length, 1);
      expect(peers.all.length, 1);
    });

    test('a contact on the radio resolves and binds its key', () async {
      final result = await resolve('Scout', contacts: [_contact('Scout', 1)]);

      expect(result.state, PeerResolutionState.resolved);
      expect(result.contact, isNotNull);
      expect(result.peer.radioPublicKey, _key(1));
      expect(result.peer.isTeamMember, isTrue);
      expect(result.peer.lastTeamChannelHash, _trackingChannelHash);
    });

    test('a placeholder is bound to its key rather than duplicated', () async {
      final placeholder = await resolve('Scout');
      final bound = await resolve('Scout', contacts: [_contact('Scout', 1)]);

      expect(bound.peer.id, placeholder.peer.id);
      expect(bound.peer.radioPublicKey, _key(1));
      expect(peers.all.length, 1);
    });

    test('a near-miss name is not matched to another contact', () async {
      // The old fuzzy matcher bound "Scout" to any device-id-like contact,
      // overwriting an unrelated contact and suppressing discovery.
      final result = await resolve('Scout', contacts: [
        _contact('a1b2c3d4', 1),
        _contact('Scouting Party', 2),
      ]);

      expect(result.state, PeerResolutionState.unresolved);
      expect(result.peer.radioPublicKey, isNull);
    });

    test('a known key missing from this radio is knownNotOnRadio', () async {
      await resolve('Scout', contacts: [_contact('Scout', 1)]);

      final afterRadioSwitch = await resolve('Scout');

      expect(afterRadioSwitch.state, PeerResolutionState.knownNotOnRadio);
      expect(afterRadioSwitch.peer.radioPublicKey, _key(1));
      expect(peers.all.length, 1);
    });

    test('two radios sharing a name resolve as ambiguous', () async {
      final result = await resolve('Scout', contacts: [
        _contact('Scout', 1),
        _contact('Scout', 2),
      ]);

      expect(result.state, PeerResolutionState.ambiguous);
      expect(result.contact, isNotNull);
    });

    test('a renamed radio keeps the same peer', () async {
      final before = await resolve('Scout', contacts: [_contact('Scout', 1)]);
      final after = await resolve('Ghost', contacts: [_contact('Ghost', 1)]);

      expect(after.peer.id, before.peer.id);
      expect(after.peer.radioName, 'Ghost');
      expect(peers.all.length, 1);
    });
  });

  group('names', () {
    test('an alias is preferred, the radio name is the fallback', () async {
      final resolution = await resolve('Scout');
      final peer = resolution.peer;

      expect(peers.displayName(peer), 'Scout');
      expect(peers.meshName(peer), 'Scout');

      await db.peersDao
          .updatePeer(peer.id, const PeersCompanion(alias: Value('Bravo 2')));
      final aliased = (await db.peersDao.getPeer(peer.id))!;

      expect(peers.displayName(aliased), 'Bravo 2');
      // Anything transmitted keeps using the radio name.
      expect(peers.meshName(aliased), 'Scout');
    });

    test('a peer with no name at all falls back to a short id', () async {
      final id = await db.peersDao.insertPeer(PeersCompanion.insert(
        radioPublicKey: Value(_key(9)),
        firstSeen: 0,
        lastSeen: 0,
      ));
      final peer = (await db.peersDao.getPeer(id))!;

      expect(peers.displayName(peer), peers.shortId(peer));
      expect(peers.displayName(peer), isNotEmpty);
    });
  });
}
