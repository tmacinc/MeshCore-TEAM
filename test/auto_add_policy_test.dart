// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
//
// The two firmware prefs interact in a way that is easy to get wrong:
// `manual_add_contacts` clear means "add every advert" and `autoadd_config`
// is ignored entirely. Both default to 0, so setting the manual flag on a
// stock radio would stop it adding repeaters, room servers and sensors too.

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_team/services/team_radio_service.dart';

/// Mirrors the firmware's `shouldAutoAddContactType`.
bool firmwareWouldAutoAdd({
  required int manualAddContacts,
  required int autoAddConfig,
  required int advertType,
}) {
  if ((manualAddContacts & 1) == 0) return true;
  switch (advertType) {
    case 1:
      return (autoAddConfig & TeamRadioService.autoAddChatBit) != 0;
    case 2:
      return (autoAddConfig & TeamRadioService.autoAddRepeaterBit) != 0;
    case 3:
      return (autoAddConfig & TeamRadioService.autoAddRoomServerBit) != 0;
    case 4:
      return (autoAddConfig & TeamRadioService.autoAddSensorBit) != 0;
    default:
      return false;
  }
}

/// The config the service will write, given what the radio reports.
int wantedConfig({required bool addsEverything, required int config}) {
  return addsEverything
      ? (config & TeamRadioService.autoAddOverwriteOldestBit) |
          TeamRadioService.autoAddInfrastructureBits
      : config & ~TeamRadioService.autoAddChatBit;
}

void main() {
  group('a stock radio (adds everything, config 0)', () {
    const config = 0;
    final applied = wantedConfig(addsEverything: true, config: config);

    test('stops adding people', () {
      expect(
        firmwareWouldAutoAdd(
            manualAddContacts: 1, autoAddConfig: applied, advertType: 1),
        isFalse,
      );
    });

    test('still adds repeaters, room servers and sensors', () {
      for (final type in [2, 3, 4]) {
        expect(
          firmwareWouldAutoAdd(
              manualAddContacts: 1, autoAddConfig: applied, advertType: type),
          isTrue,
          reason: 'advert type $type should still be added',
        );
      }
    });
  });

  group('a radio already in per-type mode', () {
    // The user wants repeaters and people, nothing else.
    const config =
        TeamRadioService.autoAddRepeaterBit | TeamRadioService.autoAddChatBit;
    final applied = wantedConfig(addsEverything: false, config: config);

    test('stops adding people', () {
      expect(
        firmwareWouldAutoAdd(
            manualAddContacts: 1, autoAddConfig: applied, advertType: 1),
        isFalse,
      );
    });

    test('keeps the types the user chose, and only those', () {
      expect(
        firmwareWouldAutoAdd(
            manualAddContacts: 1, autoAddConfig: applied, advertType: 2),
        isTrue,
      );
      // Room servers were off before and stay off: not ours to turn on.
      expect(
        firmwareWouldAutoAdd(
            manualAddContacts: 1, autoAddConfig: applied, advertType: 3),
        isFalse,
      );
    });
  });

  test('overwrite-oldest is carried over, not dropped', () {
    const config = TeamRadioService.autoAddOverwriteOldestBit;

    final applied = wantedConfig(addsEverything: true, config: config);

    expect(applied & TeamRadioService.autoAddOverwriteOldestBit, isNonZero);
  });

  test('a radio already set the way we want needs no write', () {
    final config = TeamRadioService.autoAddInfrastructureBits;

    expect(wantedConfig(addsEverything: false, config: config), config);
  });
}
