// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meshcore_team/ble/ble_commands.dart';
import 'package:meshcore_team/ble/ble_connection_manager.dart';
import 'package:meshcore_team/ble/ble_constants.dart';
import 'package:meshcore_team/ble/ble_responses.dart';
import 'package:meshcore_team/ble/ble_service.dart';
import 'package:meshcore_team/database/daos/contacts_dao.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/repositories/contact_repository.dart';
import 'package:meshcore_team/services/peer_directory.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';

/// Sets a radio up for team use on every connect.
///
/// **Team contacts follow you to a new radio.** Team identity lives on the
/// phone, so a radio that has never met the team can be given their contacts
/// directly instead of waiting for everyone's next advert. One flood advert
/// then tells the team about this radio, whose key they have never seen.
///
/// **The radio stops auto-adding other people's devices.** In firmware,
/// `manual_add_contacts` bit 0 clear means "store every advert you hear";
/// setting it defers to per-type bits in `autoadd_config` (chat 0x02,
/// repeater 0x04, room server 0x08, sensor 0x10). Both prefs default to 0, so
/// flipping the flag alone would stop a stock radio adding repeaters, room
/// servers and sensors as well — those bits are set explicitly, leaving
/// people as the only type that stops being added.
///
/// Nothing is lost by that: team members are added in software from the
/// PUSH_NEW_ADVERT the radio sends when it declines to store an advert, and
/// everyone else is listed under "Heard nearby" on the Contacts screen. What
/// it avoids is a small contact table filling up with passers-by.
///
/// The app does not put the setting back: managed contacts are how the app
/// works, so there is no saved state to restore and nothing to get out of
/// step. Someone who stops using TEAM can turn auto-add back on from any
/// MeshCore app. Documented for users in README §9.
class TeamRadioService {
  // Firmware AUTO_ADD_* bits (NodePrefs.autoadd_config). They are only
  // consulted when manual_add_contacts bit 0 is set; with it clear the radio
  // adds everything it hears, whatever these say.
  static const int autoAddOverwriteOldestBit = 0x01;
  static const int autoAddChatBit = 0x02;
  static const int autoAddRepeaterBit = 0x04;
  static const int autoAddRoomServerBit = 0x08;
  static const int autoAddSensorBit = 0x10;

  /// Everything except other people's devices.
  static const int autoAddInfrastructureBits =
      autoAddRepeaterBit | autoAddRoomServerBit | autoAddSensorBit;

  /// Leave room for strangers the user may still want; never fill the table.
  static const double _contactTableBudget = 0.75;

  final SettingsService _settings;
  final ConnectionViewModel _connectionViewModel;
  final BleService _bleService;
  final BleConnectionManager _bleManager;
  final ContactsDao _contactsDao;
  final ContactRepository _contactRepository;
  final PeerDirectory _peers;

  bool _started = false;
  bool _busy = false;
  String? _preparedCompanionKey;

  TeamRadioService({
    required SettingsService settings,
    required ConnectionViewModel connectionViewModel,
    required BleService bleService,
    required BleConnectionManager bleManager,
    required ContactsDao contactsDao,
    required ContactRepository contactRepository,
    required PeerDirectory peers,
  })  : _settings = settings,
        _connectionViewModel = connectionViewModel,
        _bleService = bleService,
        _bleManager = bleManager,
        _contactsDao = contactsDao,
        _contactRepository = contactRepository,
        _peers = peers;

  void start() {
    if (_started) return;
    _started = true;
    _settings.addListener(_onChanged);
    _connectionViewModel.addListener(_onChanged);
    _onChanged();
  }

  void dispose() {
    if (!_started) return;
    _settings.removeListener(_onChanged);
    _connectionViewModel.removeListener(_onChanged);
  }

  void _onChanged() {
    if (!_connectionViewModel.isConnected) {
      _preparedCompanionKey = null;
      return;
    }
    final companionKey = _settings.settings.currentCompanionPublicKey;
    if (companionKey == null || companionKey.isEmpty) return;
    if (_busy) return;
    // SELF_INFO carries the radio's current settings; wait for it.
    final selfInfo = _connectionViewModel.deviceCapabilities;
    if (selfInfo == null) return;
    if (_preparedCompanionKey == companionKey) return;

    _preparedCompanionKey = companionKey;
    unawaited(_prepare(companionKey, selfInfo));
  }

  Future<void> _prepare(String companionKey, SelfInfoResponse selfInfo) async {
    _busy = true;
    try {
      await _applyAutoAddPolicy(selfInfo);
      await _pushTeamContacts(companionKey, selfInfo);
    } catch (e) {
      debugPrint('[TeamRadio] ⚠️ Setup failed: $e');
      _preparedCompanionKey = null;
    } finally {
      _busy = false;
    }
  }

  // --- Auto-add ---

  /// Turns the radio's auto-add off for other people's devices, and leaves
  /// everything else being added as before.
  ///
  /// The two firmware prefs interact: with `manual_add_contacts` clear the
  /// radio adds every advert and ignores `autoadd_config` entirely. Both
  /// default to 0, so simply setting the manual flag on a stock radio would
  /// stop it adding repeaters, room servers and sensors too. Coming from that
  /// state we therefore set their bits explicitly, so the only thing that
  /// actually changes is people.
  ///
  /// Idempotent: a radio already set that way is left alone, so reconnecting
  /// doesn't rewrite its settings.
  Future<void> _applyAutoAddPolicy(SelfInfoResponse selfInfo) async {
    final reply = await _request(BleCommands.buildGetAutoAddConfig(),
        expect: BleConstants.respAutoAddConfig);
    final parsed = reply == null ? null : BleResponseParser.parse(reply);
    if (parsed is! AutoAddConfigResponse) {
      debugPrint(
          '[TeamRadio] ⚠️ Radio did not report its auto-add config; left as is');
      return;
    }
    final config = parsed.autoAddConfig;

    final addsEverything = selfInfo.autoAddsAllContacts;
    final wantedConfig = addsEverything
        // It was adding every type; keep doing that, minus people.
        ? (config & autoAddOverwriteOldestBit) | autoAddInfrastructureBits
        // Already per-type: keep the user's choices, minus people.
        : config & ~autoAddChatBit;

    if (!addsEverything && wantedConfig == config) {
      debugPrint(
          '[TeamRadio] ✅ Radio auto-add for people already off (config 0x${config.toRadixString(16)})');
      return;
    }

    // Per-type bits first: they only take effect once the manual flag is set,
    // so the radio never passes through a state that drops infrastructure.
    if (wantedConfig != config &&
        !await _command(BleCommands.buildSetAutoAddConfig(wantedConfig))) {
      debugPrint('[TeamRadio] ❌ Radio refused the auto-add config');
      return;
    }
    if (addsEverything &&
        !await _command(BleCommands.buildSetOtherParams(
          manualAddContacts: 1,
          // Sent back unchanged: the firmware rewrites all of them together.
          telemetryModes: selfInfo.telemetryModes,
          advertLocPolicy: selfInfo.advertLocPolicy,
          multiAcks: selfInfo.multiAcks,
        ))) {
      debugPrint('[TeamRadio] ❌ Radio refused the manual-add setting');
      return;
    }
    debugPrint(
        '[TeamRadio] 🚫 Radio auto-add for people off (config 0x${config.toRadixString(16)} → 0x${wantedConfig.toRadixString(16)}, manual add was ${addsEverything ? 'off' : 'on'})');
  }

  /// Sends [cmd] and returns the first frame whose code is [expect], or null
  /// on RESP_ERR or timeout. Listens before sending so a fast reply isn't
  /// missed.
  Future<Uint8List?> _request(Uint8List cmd,
      {required int expect, Duration timeout = const Duration(seconds: 3)}) async {
    final reply = Completer<Uint8List?>();
    final sub = _bleManager.receivedFrames.listen((frame) {
      if (frame.isEmpty || reply.isCompleted) return;
      if (frame[0] == expect) reply.complete(frame);
      if (frame[0] == BleConstants.respErr) reply.complete(null);
    });
    try {
      if (!await _bleManager.sendFrame(cmd)) return null;
      return await reply.future.timeout(timeout, onTimeout: () => null);
    } finally {
      await sub.cancel();
    }
  }

  Future<bool> _command(Uint8List cmd) async =>
      await _request(cmd, expect: BleConstants.respOk) != null;

  // --- Team contacts ---

  Future<void> _pushTeamContacts(
      String companionKey, SelfInfoResponse selfInfo) async {
    // Never the radio itself: after a radio swap, a teammate's old radio can
    // be the one this phone is now connected to.
    final selfKey = selfInfo.publicKey;
    final teamPeers = _peers.all
        .where((p) =>
            p.isTeamMember &&
            p.radioPublicKey != null &&
            !listEquals(p.radioPublicKey, selfKey))
        .toList();
    if (teamPeers.isEmpty) return;

    final contacts = await _contactsDao.getContactsByCompanion(companionKey);
    final known = contacts.map((c) => _hex(c.publicKey)).toSet();
    final missing = teamPeers
        .where((p) => !known.contains(_hex(p.radioPublicKey!)))
        .toList();
    if (missing.isEmpty) return;

    final capacity = _connectionViewModel.deviceInfo?.maxContacts ?? 0;
    final room = capacity <= 0
        ? missing.length
        : ((capacity * _contactTableBudget).floor() - contacts.length);
    if (room <= 0) {
      debugPrint(
          '[TeamRadio] ⚠️ No room for team contacts (${contacts.length}/$capacity)');
      return;
    }

    final toAdd = missing.take(room).toList();
    debugPrint('[TeamRadio] ➕ Adding ${toAdd.length} team contacts to this radio');

    for (final peer in toAdd) {
      final ok = await _bleService.addUpdateContact(
        publicKey: peer.radioPublicKey!,
        name: peer.radioName ?? '',
      );
      if (!ok) {
        debugPrint('[TeamRadio] ❌ Failed to add "${peer.radioName}"');
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    await _contactRepository.syncContactsComplete(since: 0);

    // This radio's key is new to the team, so tell them it exists. Their
    // stored contact for us still points at the old radio.
    await _bleService.sendSelfAdvert();
    debugPrint('[TeamRadio] 📤 Advertised this radio to the team');
  }

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
