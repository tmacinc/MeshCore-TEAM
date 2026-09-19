// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_team/ble/ble_commands.dart';
import 'package:meshcore_team/ble/ble_constants.dart';
import 'package:meshcore_team/ble/ble_responses.dart';

/// Firmware layout after the opcode byte (MyMesh::updateContactFromFrame):
/// pubkey(32), type, flags, out_path_len, out_path(64), name(32),
/// last_advert(4), lat(4), lon(4).
const int _pubKeyOffset = 1;
const int _typeOffset = 33;
const int _flagsOffset = 34;
const int _outPathLenOffset = 35;
const int _outPathOffset = 36;
const int _nameOffset = 100;
const int _lastAdvertOffset = 132;

Uint8List _key(int seed) =>
    Uint8List.fromList(List.generate(32, (i) => (seed + i) & 0xFF));

void main() {
  group('buildAddUpdateContact', () {
    test('lays the fields out where the firmware reads them', () {
      final frame = BleCommands.buildAddUpdateContact(
        publicKey: _key(1),
        name: 'Scout',
        lastAdvertTimestamp: 0x01020304,
      );

      expect(frame[0], BleConstants.cmdAddUpdateContact);
      expect(frame.sublist(_pubKeyOffset, _pubKeyOffset + 32), _key(1));
      expect(frame[_typeOffset], 1); // ADV_TYPE_CHAT
      expect(frame[_flagsOffset], 0);
      expect(frame.length, greaterThanOrEqualTo(_lastAdvertOffset + 12));

      final name = utf8.decode(
        frame
            .sublist(_nameOffset, _nameOffset + 32)
            .takeWhile((b) => b != 0)
            .toList(),
      );
      expect(name, 'Scout');

      // Little-endian timestamp.
      expect(frame.sublist(_lastAdvertOffset, _lastAdvertOffset + 4),
          [0x04, 0x03, 0x02, 0x01]);
    });

    test('sends an unknown route, not a fake one', () {
      // A hop count with an all-zero path would give the radio a route to
      // nowhere; 0xFF means "unknown", so it floods until it learns one.
      final frame = BleCommands.buildAddUpdateContact(
        publicKey: _key(1),
        name: 'Scout',
      );

      expect(frame[_outPathLenOffset], 0xFF);
      expect(frame.sublist(_outPathOffset, _outPathOffset + 64),
          everyElement(0));
    });

    test('encodes the name as UTF-8 and never splits a character', () {
      final frame = BleCommands.buildAddUpdateContact(
        publicKey: _key(1),
        name: 'Ünïcødé',
      );

      final bytes = frame
          .sublist(_nameOffset, _nameOffset + 32)
          .takeWhile((b) => b != 0)
          .toList();
      expect(utf8.decode(bytes), 'Ünïcødé');
    });

    test('a very long name stays inside its 32-byte field', () {
      final frame = BleCommands.buildAddUpdateContact(
        publicKey: _key(1),
        name: 'N' * 80,
      );

      // The field must stay null-terminated for the firmware's string copy.
      expect(frame[_nameOffset + 31], 0);
      expect(frame.length, greaterThanOrEqualTo(_lastAdvertOffset + 12));
    });
  });

  group('buildAddUpdateContactFromAdvert', () {
    test('re-uses the push frame, changing only the opcode', () {
      // PUSH_NEW_ADVERT carries the same layout, so adding the contact in
      // software is the same bytes with a different first byte.
      final push = Uint8List(1 + 32 + 3 + 64 + 32 + 16);
      push[0] = BleConstants.pushCodeNewAdvert;
      push.setRange(_pubKeyOffset, _pubKeyOffset + 32, _key(5));
      push[_typeOffset] = 1;
      push[_outPathLenOffset] = 0xFF;
      push.setRange(_nameOffset, _nameOffset + 5, utf8.encode('Scout'));

      final frame = BleCommands.buildAddUpdateContactFromAdvert(push);

      expect(frame[0], BleConstants.cmdAddUpdateContact);
      expect(frame.sublist(1), push.sublist(1));
      // The push itself is left untouched.
      expect(push[0], BleConstants.pushCodeNewAdvert);
    });

    test('the record it carries parses back to the same contact', () {
      final push = Uint8List(1 + 32 + 3 + 64 + 32 + 16);
      push[0] = BleConstants.pushCodeNewAdvert;
      push.setRange(_pubKeyOffset, _pubKeyOffset + 32, _key(5));
      push[_typeOffset] = 1;
      push[_outPathLenOffset] = 0xFF;
      push.setRange(_nameOffset, _nameOffset + 5, utf8.encode('Scout'));

      final contact = BleResponseParser.parseContactRecord(push)!;

      expect(contact.name, 'Scout');
      expect(contact.publicKey, _key(5));
    });

    test('a truncated push frame is rejected rather than parsed', () {
      expect(BleResponseParser.parseContactRecord(Uint8List(20)), isNull);
      // One byte short of a whole record: lastmod would be missing.
      expect(BleResponseParser.parseContactRecord(Uint8List(147)), isNull);
    });
  });
}
