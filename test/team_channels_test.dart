// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
//
// Team channels belong to the phone: they survive a radio that doesn't have
// them and a switch to a different radio, along with their history.
//
// Needs a native sqlite3 for the test runner (the app gets one from
// sqlite3_flutter_libs, which does not apply here):
//
//   flutter test test/team_channels_test.dart \
//     --dart-define=MBTILES_SQLITE_DLL=C:\Python314\DLLs\sqlite3.dll

import 'dart:ffi';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:sqlite3/open.dart';

const _dllPath = String.fromEnvironment('MBTILES_SQLITE_DLL');

const String _radioA = 'aaaa';
const String _radioB = 'bbbb';

void main() {
  if (_dllPath.isEmpty) {
    test('team channels (skipped: no DLL configured)', () {},
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

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  ChannelsCompanion channel({
    required int hash,
    required int index,
    bool isTeam = false,
    String companion = _radioA,
  }) =>
      ChannelsCompanion.insert(
        hash: Value(hash),
        name: 'Channel $hash',
        sharedKey: Uint8List(16),
        isPublic: index == 0,
        channelIndex: index,
        createdAt: 0,
        companionDeviceKey: Value(companion),
        isTeam: Value(isTeam),
      );

  Future<void> addMessage(int channelHash, {String companion = _radioA}) {
    return db.into(db.messages).insert(MessagesCompanion.insert(
          id: 'msg-$channelHash-$companion',
          senderId: Uint8List(32),
          channelHash: channelHash,
          content: 'hello',
          timestamp: 1000,
          isPrivate: false,
          deliveryStatus: 'SENT',
          isSentByMe: false,
          companionDeviceKey: Value(companion),
        ));
  }

  group('sync from the radio', () {
    test('a team channel the radio no longer has is kept, not deleted',
        () async {
      await db.into(db.channels).insert(channel(hash: 1, index: 1, isTeam: true));
      await db.into(db.channels).insert(channel(hash: 2, index: 2));

      // The radio reports only the ordinary channel.
      await db.channelsDao.replaceAllChannels([channel(hash: 2, index: 2)]);

      final all = await db.channelsDao.getAllChannelsOnce();
      expect(all.map((c) => c.hash), containsAll([1, 2]));

      final team = all.firstWhere((c) => c.hash == 1);
      expect(team.isTeam, isTrue);
      expect(team.firmwareConfirmed, isFalse);
      // A sentinel slot, which can never collide with a real one.
      expect(team.channelIndex, lessThan(0));
    });

    test('an ordinary channel the radio no longer has is dropped', () async {
      await db.into(db.channels).insert(channel(hash: 3, index: 3));

      await db.channelsDao.replaceAllChannels([]);

      expect(await db.channelsDao.getAllChannelsOnce(), isEmpty);
    });

    test('a team channel the radio still has keeps its slot', () async {
      await db.into(db.channels).insert(channel(hash: 1, index: 1, isTeam: true));

      await db.channelsDao.replaceAllChannels([channel(hash: 1, index: 1)]);

      final kept = (await db.channelsDao.getAllChannelsOnce()).single;
      expect(kept.isTeam, isTrue, reason: 'the team flag is the phone\'s, not the radio\'s');
      expect(kept.channelIndex, 1);
      expect(kept.firmwareConfirmed, isTrue);
    });
  });

  group('switching radio', () {
    test('team channels and their history survive; the rest does not',
        () async {
      await db.into(db.channels).insert(channel(hash: 1, index: 1, isTeam: true));
      await db.into(db.channels).insert(channel(hash: 2, index: 2));
      await addMessage(1);
      await addMessage(2);

      await db.channelsDao.deleteChannelsByCompanion(_radioA);
      await db.messagesDao.deleteMessagesByCompanion(_radioA);

      final channels = await db.channelsDao.getAllChannelsOnce();
      expect(channels.map((c) => c.hash), [1]);
      // Untied from the old radio, ready to be offered to the new one.
      expect(channels.single.companionDeviceKey, isNull);
      expect(channels.single.firmwareConfirmed, isFalse);

      final messages = await db.select(db.messages).get();
      expect(messages.map((m) => m.channelHash), [1]);
      expect(messages.single.companionDeviceKey, isNull);
    });

    test('kept history is visible on the next radio', () async {
      await db.into(db.channels).insert(channel(hash: 1, index: 1, isTeam: true));
      await addMessage(1);
      await db.channelsDao.deleteChannelsByCompanion(_radioA);
      await db.messagesDao.deleteMessagesByCompanion(_radioA);

      // The new radio reports the same channel: same key, so same hash.
      await db.channelsDao
          .replaceAllChannels([channel(hash: 1, index: 4, companion: _radioB)]);

      final shown =
          await db.messagesDao.watchMessagesByChannelAnyCompanion(1).first;
      expect(shown, hasLength(1));
    });
  });

  group('what the channel list shows', () {
    // Regression: after a radio switch, team channels were kept in the
    // database but untied from the old radio, and the list only showed
    // channels tied to the current radio - so they looked deleted.
    test('a team channel stays listed after switching radio', () async {
      await db.into(db.channels).insert(channel(hash: 1, index: 1, isTeam: true));
      await db.into(db.channels).insert(channel(hash: 2, index: 2));

      await db.channelsDao.deleteChannelsByCompanion(_radioA);
      // The new radio doesn't have the team channel.
      await db.channelsDao
          .replaceAllChannels([channel(hash: 3, index: 1, companion: _radioB)]);

      final listed = await db.channelsDao.getVisibleChannels(_radioB);
      expect(listed.map((c) => c.hash), containsAll([1, 3]));
      expect(listed.map((c) => c.hash), isNot(contains(2)));
    });

    test('a team channel the same radio dropped stays listed', () async {
      await db.into(db.channels).insert(channel(hash: 1, index: 1, isTeam: true));

      await db.channelsDao.replaceAllChannels([]);

      final listed = await db.channelsDao.getVisibleChannels(_radioA);
      expect(listed.map((c) => c.hash), [1]);
    });

    test('with no radio, only team channels are listed', () async {
      await db.into(db.channels).insert(channel(hash: 1, index: 1, isTeam: true));
      await db.into(db.channels).insert(channel(hash: 2, index: 2));

      final listed = await db.channelsDao.getVisibleChannels(null);
      expect(listed.map((c) => c.hash), [1]);
    });

    test('another radio\'s ordinary channels are not listed', () async {
      await db.into(db.channels)
          .insert(channel(hash: 2, index: 2, companion: _radioB));

      expect(await db.channelsDao.getVisibleChannels(_radioA), isEmpty);
    });

    test('slot allocation still sees only the radio\'s own channels',
        () async {
      await db.into(db.channels).insert(channel(hash: 1, index: 1, isTeam: true));
      await db.channelsDao.deleteChannelsByCompanion(_radioA);

      // An untied team channel has no slot on radio B.
      expect(await db.channelsDao.getChannelsByCompanion(_radioB), isEmpty);
    });
  });

  test('team history is pruned by age, other channels are left alone',
      () async {
    await db.into(db.channels).insert(channel(hash: 1, index: 1, isTeam: true));
    await db.into(db.channels).insert(channel(hash: 2, index: 2));
    await addMessage(1);
    await addMessage(2);

    final teamHashes = (await db.channelsDao.getTeamChannels())
        .map((c) => c.hash)
        .toList();
    final removed = await db.messagesDao
        .deleteMessagesInChannelsOlderThan(teamHashes, 2000);

    expect(removed, 1);
    final left = await db.select(db.messages).get();
    expect(left.map((m) => m.channelHash), [2]);
  });
}
