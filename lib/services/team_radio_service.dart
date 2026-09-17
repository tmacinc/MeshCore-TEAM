// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meshcore_team/ble/ble_commands.dart';
import 'package:meshcore_team/ble/ble_connection_manager.dart';
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
/// repeater 0x04, room server 0x08, sensor 0x10). This clears only the chat
/// bit, so infrastructure is still picked up automatically and the user's own
/// choices for it are untouched.
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
  /// Auto-add config bits (firmware `AUTO_ADD_*`).
  static const int autoAddChatBit = 0x02;

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

    final firstPrepare = _preparedCompanionKey != companionKey;
    _preparedCompanionKey = companionKey;
    unawaited(_prepare(companionKey, pushContacts: firstPrepare));
  }

  Future<void> _prepare(String companionKey,
      {required bool pushContacts}) async {
    _busy = true;
    try {
      await _applyAutoAddPolicy();
      if (pushContacts) await _pushTeamContacts(companionKey);
    } catch (e) {
      debugPrint('[TeamRadio] ⚠️ Setup failed: $e');
      _preparedCompanionKey = null;
    } finally {
      _busy = false;
    }
  }

  // --- Auto-add ---

  /// Turns chat auto-add off while tracking is on, and back on afterwards.
  /// The saved value is kept per radio, because it is the radio's setting and
  /// other MeshCore apps share it.
  /// Turns the radio's blanket auto-add off for other people's devices.
  /// Idempotent: a radio already set that way is left alone, so reconnecting
  /// doesn't rewrite its settings.
  Future<void> _applyAutoAddPolicy() async {
    final selfInfo = _bleService.selfInfo;
    if (selfInfo == null) return;

    final config = await _bleService.fetchAutoAddConfig();
    if (config == null) {
      debugPrint('[TeamRadio] ⏭️ Radio did not report its auto-add config');
      return;
    }

    final alreadyManaged =
        !selfInfo.autoAddsAllContacts && (config & autoAddChatBit) == 0;
    if (alreadyManaged) return;

    if (selfInfo.autoAddsAllContacts) {
      await _setOtherParams(selfInfo, manualAddContacts: 1);
    }
    if ((config & autoAddChatBit) != 0) {
      // Only the chat bit: repeater, room-server and sensor auto-add are the
      // user's choice and stay as they were.
      await _bleService.setAutoAddConfig(config & ~autoAddChatBit);
    }
    debugPrint('[TeamRadio] 🚫 Radio auto-add for people is now off');
  }

  Future<void> _setOtherParams(
    SelfInfoResponse selfInfo, {
    required int manualAddContacts,
  }) async {
    await _bleManager.sendFrame(BleCommands.buildSetOtherParams(
      manualAddContacts: manualAddContacts,
      // Sent back unchanged: the firmware rewrites all of them together.
      telemetryModes: selfInfo.telemetryModes,
      advertLocPolicy: selfInfo.advertLocPolicy,
      multiAcks: selfInfo.multiAcks,
    ));
  }

  // --- Team contacts ---

  Future<void> _pushTeamContacts(String companionKey) async {
    final teamPeers = _peers.all
        .where((p) => p.isTeamMember && p.radioPublicKey != null)
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
