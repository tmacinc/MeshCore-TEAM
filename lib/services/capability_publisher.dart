// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meshcore_team/ble/ble_service.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/database/daos/channels_dao.dart';
import 'package:meshcore_team/database/daos/contacts_dao.dart';
import 'package:meshcore_team/models/capability_message.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';

/// Publishes `#CAP:` capability advertisements on the telemetry channel.
///
/// Two publish triggers:
/// - **Post-discovery**: +2 min after a new/updated contact appears in the
///   contact list, detected by watching the DB (same mechanism as
///   [ForwardingPolicyService]). All devices see the same advert events so
///   all independently schedule and publish.
/// - **Capability change**: +1 min debounce after firmware reconnect or
///   settings change that affects the local capability flags.
///
/// No periodic keepalive. State is assumed stable until an event occurs.
/// Consumers treat missing/stale (>12h) [#CAP] as stock firmware.
class CapabilityPublisher {
  static const Duration _discoveryDelay = Duration(minutes: 2);
  static const Duration _changeDelay = Duration(minutes: 1);

  final SettingsService _settings;
  final ConnectionViewModel _connectionViewModel;
  final BleService _bleService;
  final ContactsDao _contactsDao;
  final ChannelsDao _channelsDao;

  bool _started = false;
  String? _activeCompanionKey;

  StreamSubscription<String?>? _companionKeySub;
  StreamSubscription<List<ContactData>>? _contactsSub;

  final Set<String> _knownContactHashes = {};

  Timer? _discoveryTimer;
  Timer? _changeTimer;

  // Track last-published flags to suppress no-op changes.
  int? _lastPublishedFlags;

  CapabilityPublisher({
    required SettingsService settings,
    required ConnectionViewModel connectionViewModel,
    required BleService bleService,
    required ContactsDao contactsDao,
    required ChannelsDao channelsDao,
  })  : _settings = settings,
        _connectionViewModel = connectionViewModel,
        _bleService = bleService,
        _contactsDao = contactsDao,
        _channelsDao = channelsDao;

  void start() {
    if (_started) return;
    _started = true;

    _settings.addListener(_onSettingsOrCapabilityChanged);
    _connectionViewModel.addListener(_onSettingsOrCapabilityChanged);

    _companionKeySub =
        _settings.currentCompanionPublicKeyStream.listen(_switchCompanion);
  }

  void dispose() {
    _discoveryTimer?.cancel();
    _changeTimer?.cancel();
    _contactsSub?.cancel();
    _companionKeySub?.cancel();

    if (_started) {
      _settings.removeListener(_onSettingsOrCapabilityChanged);
      _connectionViewModel.removeListener(_onSettingsOrCapabilityChanged);
    }
  }

  // --- Listeners ---

  void _onSettingsOrCapabilityChanged() {
    _scheduleChangePublish();
  }

  void _switchCompanion(String? companionKey) {
    if (_activeCompanionKey == companionKey) return;
    _activeCompanionKey = companionKey;

    _contactsSub?.cancel();
    _contactsSub = null;
    _knownContactHashes.clear();

    if (companionKey == null || companionKey.isEmpty) return;

    _contactsSub =
        _contactsDao.watchContactsByCompanion(companionKey).listen(_onContacts);
  }

  void _onContacts(List<ContactData> contacts) {
    final incomingHashes = contacts.map((c) => _hexKey(c.publicKey)).toSet();

    final isNewContact = incomingHashes.any(
      (h) => !_knownContactHashes.contains(h),
    );

    _knownContactHashes
      ..clear()
      ..addAll(incomingHashes);

    if (isNewContact) {
      _scheduleDiscoveryPublish();
    }
  }

  // --- Scheduling ---

  void _scheduleDiscoveryPublish() {
    // Reset the discovery timer on every new contact; the 2 min window starts
    // fresh from the most recent discovery event.
    _discoveryTimer?.cancel();
    _discoveryTimer = Timer(_discoveryDelay, () {
      _discoveryTimer = null;
      _publish(trigger: 'discovery');
    });
    debugPrint(
        '[CapabilityPublisher] 🕑 Discovery publish scheduled in ${_discoveryDelay.inMinutes} min');
  }

  void _scheduleChangePublish() {
    // Debounce: reset on every change within the window.
    _changeTimer?.cancel();
    _changeTimer = Timer(_changeDelay, () {
      _changeTimer = null;
      _publish(trigger: 'change');
    });
  }

  // --- Publish ---

  Future<void> _publish({required String trigger}) async {
    if (!_connectionViewModel.isConnected) {
      debugPrint(
          '[CapabilityPublisher] ⏭️ Skip publish ($trigger): not connected');
      return;
    }

    final channelHashHex = _settings.settings.telemetryChannelHash;
    if (channelHashHex == null || channelHashHex.isEmpty) {
      debugPrint(
          '[CapabilityPublisher] ⏭️ Skip publish ($trigger): no telemetry channel');
      return;
    }

    final channelHash = _tryParseChannelHash(channelHashHex);
    if (channelHash == null) return;

    final channel = await _channelsDao.getChannelByHash(channelHash);
    if (channel == null) {
      debugPrint(
          '[CapabilityPublisher] ⏭️ Skip publish ($trigger): channel not found');
      return;
    }

    final caps = _connectionViewModel.deviceCapabilities;
    final appSettings = _settings.settings;

    final msg = CapabilityMessage.fromLocalState(
      supportsForwarding: caps?.supportsForwarding ?? false,
      supportsAutonomous: caps?.supportsAutonomous ?? false,
      autonomousEnabled: _connectionViewModel.currentAutonomousEnabled ?? false,
      smartForwardingActive: appSettings.smartForwardingEnabled &&
          appSettings.campModeEnabled &&
          (caps?.supportsForwarding ?? false),
    );

    // Suppress if flags haven't changed since last publish.
    if (msg.flags == _lastPublishedFlags) {
      debugPrint(
          '[CapabilityPublisher] ⏭️ Skip publish ($trigger): flags unchanged (0x${msg.flags.toRadixString(16)})');
      return;
    }

    final ok = await _bleService.sendChannelMessage(
      channel.channelIndex,
      msg.encode(),
    );

    if (ok) {
      _lastPublishedFlags = msg.flags;
      debugPrint(
          '[CapabilityPublisher] ✅ Published #CAP ($trigger): ${msg.encode()}');
    } else {
      debugPrint('[CapabilityPublisher] ❌ Failed to publish #CAP ($trigger)');
    }
  }

  // --- Helpers ---

  String _hexKey(List<int> key) =>
      key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  int? _tryParseChannelHash(String hashHex) {
    final cleaned = hashHex.trim().toLowerCase().replaceFirst('0x', '');
    if (cleaned.isEmpty) return null;
    if (!RegExp(r'^[0-9a-f]+$').hasMatch(cleaned)) return null;
    try {
      return int.parse(cleaned, radix: 16);
    } catch (_) {
      return null;
    }
  }
}
