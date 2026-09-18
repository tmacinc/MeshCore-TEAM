// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/channel.dart';
import 'package:meshcore_team/widgets/add_channel_to_radio.dart';

ChannelData _channel({
  required String name,
  required Uint8List key,
  bool isPublic = false,
  int index = 1,
  bool firmwareConfirmed = true,
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
      firmwareConfirmed: firmwareConfirmed,
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

  group('channelNeedsRadio', () {
    // Regression: the public channel sits in slot 0 and was shown as
    // "Not on this radio".
    test('the public channel in slot 0 is on the radio', () {
      final c = _channel(
          name: 'Public', key: secretKey, isPublic: true, index: 0);
      expect(channelNeedsRadio(c), isFalse);
    });

    test('a private channel in a real slot is on the radio', () {
      expect(channelNeedsRadio(_channel(name: 'Team', key: secretKey)),
          isFalse);
    });

    test('a channel parked on a sentinel slot needs the radio', () {
      final c = _channel(name: 'Team', key: secretKey, index: -1);
      expect(channelNeedsRadio(c), isTrue);
    });

    test('a channel the radio did not confirm needs the radio', () {
      final c = _channel(
          name: 'Team', key: secretKey, firmwareConfirmed: false);
      expect(channelNeedsRadio(c), isTrue);
    });
  });
}
