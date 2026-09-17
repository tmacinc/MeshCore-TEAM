// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/channel.dart';

ChannelData _channel({
  required String name,
  required Uint8List key,
  bool isPublic = false,
  int index = 1,
}) =>
    ChannelData(
      hash: 1,
      name: name,
      sharedKey: key,
      isPublic: isPublic,
      shareLocation: true,
      channelIndex: index,
      createdAt: 0,
      notificationMode: 'all',
      isFavorite: false,
      isTeam: false,
      firmwareConfirmed: true,
    );

void main() {
  final secretKey = Uint8List.fromList(List.generate(16, (i) => i + 1));

  group('ChannelDataKind', () {
    test('a channel whose key is derived from its name is a hashtag channel',
        () {
      final c = _channel(name: '#team', key: hashtagChannelPsk('#team'));
      expect(c.isHashtag, isTrue);
      expect(c.canBeTrackingChannel, isFalse);
    });

    test('hashtag detection tolerates a stored name without the # prefix', () {
      final c = _channel(name: 'team', key: hashtagChannelPsk('#team'));
      expect(c.isHashtag, isTrue);
    });

    test('a private channel with a secret key can be the tracking channel', () {
      final c = _channel(name: '#team', key: secretKey);
      expect(c.isHashtag, isFalse);
      expect(c.canBeTrackingChannel, isTrue);
    });

    test('the public channel can never be the tracking channel', () {
      final c = _channel(name: 'Public', key: secretKey, isPublic: true, index: 0);
      expect(c.canBeTrackingChannel, isFalse);
    });
  });
}
