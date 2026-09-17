// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:meshcore_team/ble/ble_service.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/database/daos/channels_dao.dart';
import 'package:meshcore_team/database/daos/contacts_dao.dart';
import 'package:meshcore_team/models/capability_message.dart';
import 'package:meshcore_team/models/channel.dart' show ChannelDataKind;
import 'package:meshcore_team/models/team_map_visibility.dart';
import 'package:meshcore_team/repositories/message_repository.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';

/// Publishes `#CAP:` capability advertisements on the telemetry channel.
///
/// Publish triggers:
/// - **Post-discovery**: +2 min after a new/updated contact appears in the
///   contact list, detected by watching the DB (same mechanism as
///   [ForwardingPolicyService]). All devices see the same advert events so
///   all independently schedule and publish.
/// - **Change**: +1 min debounce after a firmware reconnect, an alias or
///   radio-name change, or a settings change affecting the capability flags.
/// - **Periodic**: hourly with jitter, so state can't go stale (consumers
///   treat capability older than 12h as stock firmware) and members who
///   joined between events still learn our alias.
/// - **Request**: another member asked us to identify ourselves.
///
/// Also answers `#CAP:R:` advert requests aimed at this radio.
class CapabilityPublisher {
  static const Duration _discoveryDelay = Duration(minutes: 2);
  static const Duration _changeDelay = Duration(minutes: 1);
  static const Duration _periodicInterval = Duration(minutes: 60);
  static const Duration _periodicJitter = Duration(minutes: 5);

  /// Spread on replies to an advert request. Everyone who can't resolve a
  /// sender hears the same packet at the same instant, so an immediate reply
  /// from each of them would collide.
  static const Duration _respondJitter = Duration(seconds: 3);

  /// Requests arriving inside this window share one reply.
  static const Duration _respondMergeWindow = Duration(seconds: 10);

  final SettingsService _settings;
  final ConnectionViewModel _connectionViewModel;
  final BleService _bleService;
  final ContactsDao _contactsDao;
  final ChannelsDao _channelsDao;
  final MessageRepository _messageRepository;

  final Random _random = Random();

  bool _started = false;
  String? _activeCompanionKey;

  StreamSubscription<String?>? _companionKeySub;
  StreamSubscription<List<ContactData>>? _contactsSub;

  final Set<String> _knownContactHashes = {};

  Timer? _discoveryTimer;
  Timer? _changeTimer;
  Timer? _periodicTimer;
  Timer? _respondTimer;
  DateTime? _lastRespondedAt;
  StreamSubscription<CapabilityRequest>? _requestSub;

  // Everything that goes out in a #CAP:, to suppress no-op publishes.
  String? _lastPublishedSignature;

  CapabilityPublisher({
    required SettingsService settings,
    required ConnectionViewModel connectionViewModel,
    required BleService bleService,
    required ContactsDao contactsDao,
    required ChannelsDao channelsDao,
    required MessageRepository messageRepository,
  })  : _settings = settings,
        _connectionViewModel = connectionViewModel,
        _bleService = bleService,
        _contactsDao = contactsDao,
        _channelsDao = channelsDao,
        _messageRepository = messageRepository;

  void start() {
    if (_started) return;
    _started = true;

    _settings.addListener(_onSettingsOrCapabilityChanged);
    _connectionViewModel.addListener(_onSettingsOrCapabilityChanged);

    _companionKeySub =
        _settings.currentCompanionPublicKeyStream.listen(_switchCompanion);

    _requestSub = _messageRepository.capabilityRequestStream
        .listen(_onCapabilityRequest);

    _schedulePeriodicPublish();
  }

  void dispose() {
    _discoveryTimer?.cancel();
    _changeTimer?.cancel();
    _periodicTimer?.cancel();
    _respondTimer?.cancel();
    _contactsSub?.cancel();
    _companionKeySub?.cancel();
    _requestSub?.cancel();

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

  /// Refreshes state that would otherwise go stale after 12h, and gives
  /// members who joined between events a chance to learn our alias. Jittered
  /// so a whole group doesn't transmit at the same moment.
  void _schedulePeriodicPublish() {
    _periodicTimer?.cancel();
    final jitterMs = _random.nextInt(_periodicJitter.inMilliseconds * 2 + 1) -
        _periodicJitter.inMilliseconds;
    _periodicTimer = Timer(
      _periodicInterval + Duration(milliseconds: jitterMs),
      () {
        _periodicTimer = null;
        _publish(trigger: 'periodic', force: true);
        _schedulePeriodicPublish();
      },
    );
  }

  // --- Advert requests ---

  /// Someone can't resolve us and is asking us to advertise. The advert is
  /// signed by the radio, which a CAP is not, so it is the only way for them
  /// to add us as a contact.
  ///
  /// Requests that arrive together are answered once, and after a short random
  /// delay: everyone who can't resolve a sender hears the same telemetry at
  /// the same moment, so replying immediately would collide.
  void _onCapabilityRequest(CapabilityRequest request) {
    final selfName = _connectionViewModel.deviceName.trim();
    if (selfName.isEmpty || request.targetRadioName.trim() != selfName) return;

    // A stale key prefix means they have our old radio: still us, still answer.
    final sinceLast = _lastRespondedAt == null
        ? null
        : DateTime.now().difference(_lastRespondedAt!);
    if (_respondTimer != null ||
        (sinceLast != null && sinceLast < _respondMergeWindow)) {
      debugPrint(
          '[CapabilityPublisher] 🔁 Advert request merged into a recent reply');
      return;
    }

    final delayMs = _random.nextInt(_respondJitter.inMilliseconds);
    debugPrint(
        '[CapabilityPublisher] 📣 Advert requested by a peer - replying in ${delayMs}ms');
    _respondTimer = Timer(Duration(milliseconds: delayMs), () async {
      _respondTimer = null;
      _lastRespondedAt = DateTime.now();
      if (!_connectionViewModel.isConnected) return;
      await _bleService.sendSelfAdvert();
      await _publish(trigger: 'request', force: true);
    });
  }

  // --- Publish ---

  Future<void> _publish({required String trigger, bool force = false}) async {
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

    final channelHash = parseTrackingChannelHash(channelHashHex);
    if (channelHash == null) return;

    final channel = await _channelsDao.getChannelByHash(channelHash);
    if (channel == null) {
      debugPrint(
          '[CapabilityPublisher] ⏭️ Skip publish ($trigger): channel not found');
      return;
    }
    if (!channel.canBeTrackingChannel) {
      debugPrint(
          '[CapabilityPublisher] ⏭️ Skip publish ($trigger): channel is public or hashtag');
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
      radioKeyPrefix: _selfKeyPrefix(),
      alias: appSettings.teamAlias,
    );

    // Suppress no-op publishes. The alias, radio name and channel are part of
    // the signature: a rename or an alias change has to reach the team even
    // though the flags are unchanged.
    final signature =
        '${msg.flags}|${msg.radioKeyPrefix}|${msg.alias}|${_connectionViewModel.deviceName}|$channelHash';
    if (!force && signature == _lastPublishedSignature) {
      debugPrint(
          '[CapabilityPublisher] ⏭️ Skip publish ($trigger): nothing changed');
      return;
    }

    final ok = await _bleService.sendChannelMessage(
      channel.channelIndex,
      msg.encode(),
    );

    if (ok) {
      _lastPublishedSignature = signature;
      debugPrint(
          '[CapabilityPublisher] ✅ Published #CAP ($trigger): ${msg.encode()}');
    } else {
      debugPrint('[CapabilityPublisher] ❌ Failed to publish #CAP ($trigger)');
    }
  }

  // --- Helpers ---

  /// First 6 bytes of our own radio key, as 12 lower-case hex chars.
  String? _selfKeyPrefix() {
    final key = _connectionViewModel.deviceCapabilities?.publicKey;
    if (key == null || key.length < 6) return null;
    return _hexKey(key.take(6).toList());
  }

  String _hexKey(List<int> key) =>
      key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
