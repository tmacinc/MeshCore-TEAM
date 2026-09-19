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
import 'package:meshcore_team/models/capability_message.dart';
import 'package:meshcore_team/services/peer_directory.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';

const _dllPath = String.fromEnvironment('MBTILES_SQLITE_DLL');

const int _trackingChannelHash = 0xABCD;

Uint8List _key(int seed) =>
    Uint8List.fromList(List.generate(32, (i) => (seed + i) & 0xFF));

String _hexPrefix(Uint8List key) =>
    key.take(6).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

String _hexKey(Uint8List key) =>
    key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

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

    test('a placeholder made during a rename is folded into the radio',
        () async {
      // B is known as "Scout". B renames the radio to "Ghost"; positions
      // arrive under "Ghost" before the advert, so a placeholder appears.
      final known = await resolve('Scout', contacts: [_contact('Scout', 1)]);
      final placeholder = await resolve('Ghost');
      expect(peers.all.length, 2);

      // The advert arrives: the radio's contact list now says "Ghost".
      await db.contactsDao.upsertContact(ContactsCompanion(
        publicKey: Value(_key(1)),
        hash: const Value(1),
        name: const Value('Ghost'),
        lastSeen: const Value(0),
        companionDeviceKey: const Value('radio'),
      ));
      await peers.syncWithRadioContactsForTest(
          await db.contactsDao.getContactsByCompanion('radio'));

      expect(peers.all.length, 1);
      expect(peers.all.single.id, known.peer.id);
      expect(peers.all.single.radioName, 'Ghost');
      expect(peers.byId(placeholder.peer.id), isNull);
    });

    test('a renamed radio keeps the same peer', () async {
      final before = await resolve('Scout', contacts: [_contact('Scout', 1)]);
      final after = await resolve('Ghost', contacts: [_contact('Ghost', 1)]);

      expect(after.peer.id, before.peer.id);
      expect(after.peer.radioName, 'Ghost');
      expect(peers.all.length, 1);
    });
  });

  group('recordCapability', () {
    test('stores flags and the alias from a v2 message', () async {
      final resolution = await resolve('Scout');

      final outcome = await peers.recordCapability(
        resolution.peer,
        CapabilityMessage.fromLocalState(
          supportsForwarding: true,
          radioKeyPrefix: '000102030405',
          alias: 'Bravo 2',
        ),
      );

      expect(outcome.keyMismatch, isFalse);
      expect(outcome.peer.alias, 'Bravo 2');
      expect(outcome.peer.capFlags, isNotNull);
      expect(outcome.peer.radioKeyPrefix, '000102030405');
      expect(peers.displayName(outcome.peer), 'Bravo 2');
    });

    test('a v1 message does not clear an alias we already have', () async {
      final resolution = await resolve('Scout');
      await peers.recordCapability(
        resolution.peer,
        CapabilityMessage.fromLocalState(alias: 'Bravo 2'),
      );

      final outcome = await peers.recordCapability(
        peers.byId(resolution.peer.id)!,
        const CapabilityMessage(version: 1, flags: 0x03),
      );

      expect(outcome.peer.alias, 'Bravo 2');
      expect(outcome.peer.capFlags, 0x03);
    });

    test('an empty alias clears the stored one', () async {
      final resolution = await resolve('Scout');
      await peers.recordCapability(resolution.peer,
          CapabilityMessage.fromLocalState(alias: 'Bravo 2'));

      final outcome = await peers.recordCapability(
        peers.byId(resolution.peer.id)!,
        CapabilityMessage.fromLocalState(alias: ''),
      );

      expect(outcome.peer.alias, isNull);
      expect(peers.displayName(outcome.peer), 'Scout');
    });

    test('a key prefix merges a placeholder into the peer holding that key',
        () async {
      // Known from the mesh under one name...
      final onRadio = await resolve('Scout', contacts: [_contact('Scout', 1)]);
      // ...and heard again under a name we can't resolve (e.g. renamed).
      final placeholder = await resolve('Ghost');
      expect(peers.all.length, 2);

      final outcome = await peers.recordCapability(
        placeholder.peer,
        CapabilityMessage.fromLocalState(
          radioKeyPrefix: _hexPrefix(_key(1)),
          alias: 'Bravo 2',
        ),
      );

      expect(peers.all.length, 1);
      expect(outcome.peer.id, onRadio.peer.id);
      expect(outcome.peer.radioPublicKey, _key(1));
      expect(outcome.peer.alias, 'Bravo 2');
    });

    test('a different key under a known name is reported as a mismatch',
        () async {
      final resolution =
          await resolve('Scout', contacts: [_contact('Scout', 1)]);

      final outcome = await peers.recordCapability(
        resolution.peer,
        CapabilityMessage.fromLocalState(
          radioKeyPrefix: 'ffffffffffff',
          alias: 'Bravo 2',
        ),
      );

      // They switched radios: the caller asks them to advertise.
      expect(outcome.keyMismatch, isTrue);
      expect(outcome.peer.radioPublicKey, _key(1));
    });
  });

  group('app identity', () {
    const ben = '1a2b3c4d5e6f7788';
    const other = '99aabbccddeeff00';

    Future<PeerData> benOnRadio1() async {
      final r = await resolve('Scout', contacts: [_contact('Scout', 1)]);
      final outcome = await peers.recordCapability(
        r.peer,
        CapabilityMessage.fromLocalState(
          radioKeyPrefix: _hexPrefix(_key(1)),
          appId: ben,
          alias: 'Ben',
        ),
      );
      return outcome.peer;
    }

    test('the first message with an app id claims the sender', () async {
      final peer = await benOnRadio1();

      expect(peer.appIdentityId, ben);
      expect(peers.byAppId(ben)!.id, peer.id);
    });

    test('the same phone on another radio stays the same person', () async {
      final before = await benOnRadio1();

      // Ben now uses a radio we have never heard, named "Ghost".
      final heard = await resolve('Ghost');
      expect(peers.all.length, 2);
      final outcome = await peers.recordCapability(
        heard.peer,
        CapabilityMessage.fromLocalState(
          radioKeyPrefix: _hexPrefix(_key(3)),
          appId: ben,
          alias: 'Ben',
        ),
      );

      expect(peers.all.length, 1);
      expect(outcome.peer.id, before.id);
      expect(outcome.peer.radioName, 'Ghost');
      // The old key is dropped; the new one isn't known until its advert.
      expect(outcome.peer.radioPublicKey, isNull);
      expect(outcome.peer.radioKeyPrefix, _hexPrefix(_key(3)));

      // Their next position finds them, not a new placeholder.
      final next = await resolve('Ghost');
      expect(next.peer.id, before.id);
      expect(peers.all.length, 1);

      // The advert arrives and binds the new radio's key to them.
      await peers.syncWithRadioContactsForTest([_contact('Ghost', 3)]);
      expect(peers.byId(before.id)!.radioPublicKey, _key(3));
    });

    test('a new radio and a new alias on the same phone is still one person',
        () async {
      final before = await benOnRadio1();

      final heard = await resolve('Ghost', contacts: [_contact('Ghost', 3)]);
      final outcome = await peers.recordCapability(
        heard.peer,
        CapabilityMessage.fromLocalState(
          radioKeyPrefix: _hexPrefix(_key(3)),
          appId: ben,
          alias: 'Benjamin',
        ),
      );

      expect(peers.all.length, 1);
      expect(outcome.peer.id, before.id);
      expect(outcome.peer.alias, 'Benjamin');
      expect(outcome.peer.radioPublicKey, _key(3));
      expect(outcome.keyMismatch, isFalse);
    });

    test('a radio passed to someone else moves to the new person', () async {
      final ben1 = await benOnRadio1();

      // Someone else now sends from Ben's old radio.
      final heard = await resolve('Scout', contacts: [_contact('Scout', 1)]);
      final outcome = await peers.recordCapability(
        heard.peer,
        CapabilityMessage.fromLocalState(
          radioKeyPrefix: _hexPrefix(_key(1)),
          appId: other,
          alias: 'Cara',
        ),
      );

      expect(peers.all.length, 2);
      expect(outcome.peer.id, isNot(ben1.id));
      expect(outcome.peer.appIdentityId, other);
      expect(outcome.peer.radioPublicKey, _key(1));
      expect(outcome.peer.alias, 'Cara');
      // Ben keeps his name, without the radio.
      final benNow = peers.byId(ben1.id)!;
      expect(benNow.alias, 'Ben');
      expect(benNow.radioPublicKey, isNull);
    });

    test('two phones are never merged by a shared radio name', () async {
      final ben1 = await benOnRadio1();
      await peers.recordCapability(
        (await resolve('Scout', contacts: [_contact('Scout', 1)])).peer,
        CapabilityMessage.fromLocalState(
          radioKeyPrefix: _hexPrefix(_key(1)),
          appId: other,
        ),
      );

      expect(peers.byAppId(ben)!.id, ben1.id);
      expect(peers.byAppId(other)!.id, isNot(ben1.id));
    });

    test('a teammate on the radio this phone connects to loses only the radio',
        () async {
      final ben1 = await benOnRadio1();

      final settings = SettingsService(await SharedPreferences.getInstance());
      final directory = PeerDirectory(
        peersDao: db.peersDao,
        contactsDao: db.contactsDao,
        settings: settings,
      );
      await directory.start();
      await settings.setCurrentCompanionPublicKey(_hexKey(_key(1)));
      await pumpEventQueue();
      // Serialized behind the release.
      await directory.resolveChannelSender(
        radioName: 'nobody',
        radioContacts: const [],
        channelHash: _trackingChannelHash,
        isTeamChannel: false,
      );

      final benNow = directory.byId(ben1.id)!;
      expect(benNow.radioPublicKey, isNull);
      expect(benNow.alias, 'Ben');
      expect(benNow.appIdentityId, ben);
      directory.dispose();
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

    test('two peers sharing an alias both show it and stay separate',
        () async {
      // Nothing stops two people choosing the same name. It's display only:
      // they remain two peers with their own radios.
      final first = await resolve('Scout', contacts: [_contact('Scout', 1)]);
      final second = await resolve('Ghost', contacts: [_contact('Ghost', 2)]);

      await peers.recordCapability(first.peer,
          CapabilityMessage.fromLocalState(alias: 'Bravo 2'));
      final outcome = await peers.recordCapability(second.peer,
          CapabilityMessage.fromLocalState(alias: 'Bravo 2'));

      expect(peers.displayName(peers.byId(first.peer.id)!), 'Bravo 2');
      expect(peers.displayName(outcome.peer), 'Bravo 2');
      expect(first.peer.id, isNot(second.peer.id));
      expect(peers.byRadioKey(_key(1))!.id, first.peer.id);
      expect(peers.byRadioKey(_key(2))!.id, second.peer.id);
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
