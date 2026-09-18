// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:meshcore_team/ble/ble_commands.dart';
import 'package:meshcore_team/ble/ble_connection_manager.dart';
import 'package:meshcore_team/ble/ble_constants.dart';
import 'package:meshcore_team/ble/ble_responses.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/database/daos/channels_dao.dart';
import 'package:meshcore_team/models/channel.dart' as channel_model;
import 'package:meshcore_team/models/channel.dart' show ChannelDataKind;
import 'package:meshcore_team/models/team_map_visibility.dart';
import 'package:meshcore_team/models/sync_status.dart';
import 'package:meshcore_team/models/unread_models.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/utils/sync_trace.dart';
import 'package:drift/drift.dart' as drift;
import 'package:meshcore_team/l10n/app_localizations.dart';
import 'package:meshcore_team/models/app_language.dart';

/// Channel fetch result
class _ChannelFetchResult {
  final ChannelInfoResponse? channel;
  final int? errorCode;

  _ChannelFetchResult.channel(this.channel) : errorCode = null;
  _ChannelFetchResult.error(this.errorCode) : channel = null;

  bool get isChannel => channel != null;
  bool get isError => errorCode != null;
}

class _ParsedChannelLink {
  final String name;
  final Uint8List psk;

  const _ParsedChannelLink({
    required this.name,
    required this.psk,
  });
}

class _OkOrError {
  final bool isSuccess;
  final int? errorCode;
  final bool isTimeout;
  final bool isSendFailed;

  const _OkOrError._({
    required this.isSuccess,
    this.errorCode,
    this.isTimeout = false,
    this.isSendFailed = false,
  });

  const _OkOrError.ok() : this._(isSuccess: true);
  const _OkOrError.timeout() : this._(isSuccess: false, isTimeout: true);
  const _OkOrError.sendFailed() : this._(isSuccess: false, isSendFailed: true);
  const _OkOrError.err(int? code) : this._(isSuccess: false, errorCode: code);
}

/// Channel Repository
/// Manages channel sync and database operations
/// Matches Android ChannelRepository.kt implementation
/// Why a channel could not be put on the radio.
enum AddChannelToRadioError { notConnected, noSlots, failed }

class ChannelRepository {
  static const String _syncTraceTag = '[SYNCTRACE][CHANNEL]';
  static const int _channelFetchRetryAttempts = 3;
  static const Duration _channelFetchPipelineIdleWindow =
      Duration(milliseconds: 150);
  static const Duration _channelFetchPipelineMaxWait =
      Duration(milliseconds: 1200);

  final BleConnectionManager _bleManager;
  final ChannelsDao _channelsDao;
  final SettingsService _settingsService;

  /// Strings for the user's language.
  ///
  /// These messages are thrown as [StateError] and shown verbatim in a
  /// snackbar, so they have to be localized here rather than at the call site.
  AppLocalizations get _l10n => lookupAppLocalizations(
      AppLanguage.localeFor(_settingsService.settings.localeCode));

  // Default to 8 channels total, indices 1-7 private (0 is public)
  int _maxPrivateChannels = 7;

  // Sync progress tracking
  final StreamController<ChannelSyncProgress> _syncProgressController =
      StreamController<ChannelSyncProgress>.broadcast();
  Stream<ChannelSyncProgress> get syncProgress =>
      _syncProgressController.stream;

  ChannelSyncProgress _currentProgress = const ChannelSyncProgress();

  // Frame subscriptions
  StreamSubscription<Uint8List>? _frameSubscription;
  final StreamController<ChannelInfoResponse> _channelResponseController =
      StreamController<ChannelInfoResponse>.broadcast();
  final StreamController<int> _errorResponseController =
      StreamController<int>.broadcast();

  ChannelRepository({
    required BleConnectionManager bleManager,
    required ChannelsDao channelsDao,
    required SettingsService settingsService,
  })  : _bleManager = bleManager,
        _channelsDao = channelsDao,
        _settingsService = settingsService;

  /// Update maximum channel capacity based on device info.
  /// Matches Android behavior: maxPrivateChannels = maxChannels - 1 (index 0 reserved for Public)
  void updateMaxChannels(int maxChannels) {
    if (maxChannels <= 0) return;
    _maxPrivateChannels = max(0, maxChannels - 1);
    debugPrint(
        '[Channel] Updated maxPrivateChannels to $_maxPrivateChannels (firmware supports $maxChannels total)');
  }

  /// Derive PSK for a hashtag channel from its name. See [channel_model.hashtagChannelPsk].
  static Uint8List hashtagChannelPsk(String name) =>
      channel_model.hashtagChannelPsk(name);

  /// Create (or join) a hashtag channel whose PSK is derived from [name].
  ///
  /// [name] should start with '#' (the prefix is added automatically if absent).
  /// Because the key is fully derived from the name, any device that calls this
  /// with the same name ends up on the same encrypted channel — no QR exchange
  /// needed.
  Future<ChannelData> createHashtagChannel(String name) async {
    String normalised = name.trim();
    if (!normalised.startsWith('#')) {
      normalised = '#$normalised';
    }
    if (normalised.length < 2) {
      throw ArgumentError('Channel name cannot be empty');
    }

    final companionKey = _settingsService.settings.currentCompanionPublicKey;
    if (companionKey == null || companionKey.isEmpty) {
      throw StateError('No companion selected');
    }

    final psk = hashtagChannelPsk(normalised);
    final hash = _calculateHash(psk);

    // If already present (same companion or previously added) just return it.
    final existing = await _channelsDao.getChannelByHash(hash);
    if (existing != null) return existing;

    return _saveNewChannel(
      hash: hash,
      name: normalised,
      psk: psk,
      companionKey: companionKey,
      maxReachedMessage: _l10n.maxChannelsReachedJoin,
    );
  }

  /// Create a new private channel with a random PSK.
  /// Matches Android createPrivateChannel(): finds next available index and registers with firmware when connected.
  Future<ChannelData> createPrivateChannel(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Channel name cannot be empty');
    }

    // No radio needed: a private channel made without one is a team channel,
    // kept on the phone until it is added to a radio.
    final companionKey = _settingsService.settings.currentCompanionPublicKey;

    final rnd = Random.secure();
    final psk =
        Uint8List.fromList(List<int>.generate(16, (_) => rnd.nextInt(256)));
    final hash = _calculateHash(psk);

    final existing = await _channelsDao.getChannelByHash(hash);
    if (existing != null) {
      return existing;
    }

    return _saveNewChannel(
      hash: hash,
      name: trimmedName,
      psk: psk,
      companionKey: companionKey,
      maxReachedMessage: _l10n.maxChannelsReachedCreate,
    );
  }

  /// Import a channel from meshcore:// URL or raw key.
  /// Matches Android importChannel(): accepts URL in either field or legacy name + key (base64/hex).
  Future<ChannelData?> importChannel(String nameOrUrl, String keyData) async {
    try {
      final companionKey = _settingsService.settings.currentCompanionPublicKey;

      String channelName;
      Uint8List psk;

      final urlInput = _extractMeshcoreUrl(nameOrUrl, keyData);
      if (urlInput != null) {
        final parsed = _parseMeshcoreChannelUrl(urlInput);
        if (parsed == null) return null;
        channelName = parsed.name;
        psk = parsed.psk;
      } else {
        channelName = nameOrUrl.trim();
        if (channelName.isEmpty) return null;
        final cleanKey = keyData.replaceAll(RegExp(r'\s+'), '');
        final maybePsk = _parseLegacyKey(cleanKey);
        if (maybePsk == null) return null;
        psk = maybePsk;
      }

      if (psk.length != 16) return null;
      final hash = _calculateHash(psk);

      final existing = await _channelsDao.getChannelByHash(hash);
      if (existing != null) return existing;

      return await _saveNewChannel(
        hash: hash,
        name: channelName,
        psk: psk,
        companionKey: companionKey,
        maxReachedMessage: _l10n.maxChannelsReachedJoin,
      );
    } catch (_) {
      return null;
    }
  }

  /// Export channel as meshcore:// URL for QR code sharing.
  /// Format: meshcore://channel/add?name=<urlencoded>&secret=<hex32>
  String exportChannelKey(ChannelData channel) {
    final hexSecret = _bytesToHex(channel.sharedKey);
    final encodedName = _encodeNameForMeshcoreUrl(channel.name);
    return 'meshcore://channel/add?name=$encodedName&secret=$hexSecret';
  }

  /// Delete a private channel.
  ///
  /// Deletes a private channel.
  ///
  /// Connected, the firmware slot is cleared first: the radio is the source
  /// of truth for its own slots. A team channel can also be deleted with no
  /// radio connected, because it belongs to the phone — it goes with its
  /// history, and if the radio still holds the slot it returns on the next
  /// sync as an ordinary channel with no history, which is what "deleted on
  /// the phone" should look like.
  Future<void> deletePrivateChannel(ChannelData channel) async {
    if (channel.isPublic || channel.channelIndex == 0) {
      throw StateError('Public channel cannot be deleted');
    }

    final companionKey = _settingsService.settings.currentCompanionPublicKey;

    // Safety: prevent deleting a channel row that belongs to a different companion.
    if (companionKey != null &&
        channel.companionDeviceKey != null &&
        channel.companionDeviceKey!.isNotEmpty &&
        channel.companionDeviceKey != companionKey) {
      throw StateError('Channel belongs to a different companion');
    }

    final onRadio = channel.firmwareConfirmed && channel.channelIndex > 0;
    if (!_bleManager.isConnected) {
      // Only a channel the radio holds needs the radio to delete it.
      // The radio owns this one: deleting it here alone would just bring it
      // back on the next sync.
      if (!ChannelsDao.isPhoneOwned(channel)) {
        throw StateError(_l10n.deleteChannelNeedsRadio);
      }
    } else if (onRadio) {
      debugPrint(
          '[Channel] 🗑️ Deleting private channel "${channel.name}" at index ${channel.channelIndex} (hash=${channel.hash})');

      // Clear from firmware first.
      final clearResult = await _registerChannelWithFirmware(
        channelIndex: channel.channelIndex,
        name: '',
        psk: Uint8List(16),
      );
      if (!clearResult.isSuccess) {
        throw StateError(_l10n.failedToDeleteChannelFromCompanion(
            clearResult.errorCode?.toString() ?? _l10n.unknown));
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // If this channel is selected for telemetry, clear the setting.
    final telemetryHashHex = channel.hash.toRadixString(16).toLowerCase();
    if (_settingsService.settings.telemetryChannelHash?.toLowerCase() ==
        telemetryHashHex) {
      await _settingsService.setTelemetryChannelHash(null);
    }

    // Delete messages first, then the channel. A team channel's history is
    // not tied to one radio, so all of it goes.
    final messagesDao = _channelsDao.attachedDatabase.messagesDao;
    if (channel.isTeam || companionKey == null || companionKey.isEmpty) {
      await messagesDao.deleteMessagesByChannel(channel.hash);
      await _channelsDao.deleteChannel(channel.hash);
    } else {
      await messagesDao.deleteMessagesByChannelForCompanion(
          channel.hash, companionKey);
      await _channelsDao.deleteChannelForCompanion(channel.hash, companionKey);
    }

    debugPrint(
        '[Channel] ✅ Deleted private channel "${channel.name}" (index ${channel.channelIndex})');
  }

  /// Saves a newly created, joined or imported channel.
  ///
  /// Connected, it takes a free slot on the radio, which is the source of
  /// truth for its own slots.
  ///
  /// Not connected, there is no slot to take, so the phone keeps it: parked
  /// on a sentinel slot and marked not on the radio, ready to be offered to
  /// the radio when it is used. A private channel that exists only on the
  /// phone is exactly what a team channel is, so it becomes one. A hashtag
  /// channel can't — anyone can derive its key — so it is only kept pending.
  ///
  /// Before this, an offline channel claimed a real slot number it didn't
  /// have and was never pushed, so the next sync with the radio deleted it.
  Future<ChannelData> _saveNewChannel({
    required int hash,
    required String name,
    required Uint8List psk,
    required String? companionKey,
    required String maxReachedMessage,
  }) async {
    final hasRadio = companionKey != null && companionKey.isNotEmpty;
    final isHashtag = _isHashtagKey(name, psk);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_bleManager.isConnected && hasRadio) {
      final nextIndex = await _findFreeSlotOnRadio(companionKey);
      if (nextIndex == null) throw StateError(maxReachedMessage);

      final result = await _registerChannelWithFirmware(
        channelIndex: nextIndex,
        name: name,
        psk: psk,
      );
      if (!result.isSuccess) {
        if (result.errorCode == 3) throw StateError(maxReachedMessage);
        throw StateError(_l10n.failedToRegisterChannel(
            result.errorCode?.toString() ?? _l10n.unknown));
      }
      await Future.delayed(const Duration(milliseconds: 300));

      await _channelsDao.upsertChannel(ChannelsCompanion.insert(
        hash: drift.Value(hash),
        name: name,
        sharedKey: psk,
        isPublic: false,
        shareLocation: const drift.Value(true),
        channelIndex: nextIndex,
        createdAt: now,
        companionDeviceKey: drift.Value(companionKey),
      ));
    } else {
      // Without a radio, only a team channel can be shown (see
      // ChannelsDao.getVisibleChannels), and a hashtag channel can't be one.
      if (isHashtag && !hasRadio) throw StateError('No companion selected');

      debugPrint(
          '[Channel] Not connected - "$name" kept on the phone${isHashtag ? '' : ' as a team channel'}, not on the radio yet');
      await _channelsDao.upsertChannel(ChannelsCompanion.insert(
        hash: drift.Value(hash),
        name: name,
        sharedKey: psk,
        isPublic: false,
        shareLocation: const drift.Value(true),
        channelIndex: await _channelsDao.nextSentinelIndex(),
        createdAt: now,
        companionDeviceKey: drift.Value(hasRadio ? companionKey : null),
        isTeam: drift.Value(!isHashtag),
        firmwareConfirmed: const drift.Value(false),
      ));
    }

    final created = await _channelsDao.getChannelByHash(hash);
    if (created == null) throw StateError('Channel creation failed');
    return created;
  }

  /// Finds a slot that is empty on the radio itself.
  ///
  /// CMD_SET_CHANNEL overwrites a slot without asking, so trusting the
  /// phone's saved view of the radio is not enough: if it were stale, adding
  /// a channel would silently replace one of the radio's. Each candidate is
  /// read back from the radio first; one that turns out to be taken is
  /// skipped. Returns null when there is no free slot, and throws if the
  /// radio doesn't answer, rather than write to a slot of unknown contents.
  Future<int?> _findFreeSlotOnRadio(String? companionKey) async {
    final known = companionKey == null || companionKey.isEmpty
        ? await _channelsDao.getAllChannelsOnce()
        : await _channelsDao.getChannelsByCompanion(companionKey);
    final used = known
        .where((c) => c.channelIndex > 0 && c.firmwareConfirmed)
        .map((c) => c.channelIndex)
        .toSet();

    while (true) {
      final candidate = _nextAvailablePrivateIndex(used);
      if (candidate == null) return null;

      final free = await _isSlotFreeOnRadio(candidate);
      if (free == null) {
        throw StateError(_l10n.failedToAddChannel);
      }
      if (free) return candidate;

      debugPrint(
          '[Channel] ⚠️ Slot $candidate is taken on the radio though the phone had it free; skipping');
      used.add(candidate);
    }
  }

  /// Reads one slot from the radio: true if empty, false if it holds a
  /// channel, null if the radio didn't answer.
  Future<bool?> _isSlotFreeOnRadio(int index) async {
    final sub = _bleManager.receivedFrames.listen((frame) {
      if (frame.isNotEmpty) _routeResponse(frame);
    });
    try {
      final response = _waitForChannelOrError(index, timeoutMs: 2000);
      if (!await _bleManager.sendFrame(BleCommands.buildGetChannel(index))) {
        return null;
      }
      final result = await response;
      if (result.isChannel) return result.channel!.name.isEmpty;
      return null;
    } finally {
      await sub.cancel();
    }
  }

  static bool _isHashtagKey(String name, Uint8List psk) {
    final trimmed = name.trim();
    final candidate = trimmed.startsWith('#') ? trimmed : '#$trimmed';
    final derived = hashtagChannelPsk(candidate);
    if (derived.length != psk.length) return false;
    for (var i = 0; i < psk.length; i++) {
      if (derived[i] != psk[i]) return false;
    }
    return true;
  }

  /// True when a channel shown for the current radio is marked as not on it.
  Future<bool> hasChannelsAwaitingRadio() async {
    final companionKey = _settingsService.settings.currentCompanionPublicKey;
    final visible = await _channelsDao.getVisibleChannels(companionKey);
    return visible
        .any((c) => !c.firmwareConfirmed || c.channelIndex < 0);
  }

  /// Marks a channel as owned by the phone: kept across radio switches,
  /// offered to a radio that doesn't have it, and its history is kept.
  /// Refused for public and hashtag channels, whose key isn't a secret.
  Future<bool> setTeamChannel(ChannelData channel, bool isTeam) async {
    if (isTeam && !channel.canBeTrackingChannel) {
      debugPrint(
          '[Channel] ⏭️ "${channel.name}" cannot be a team channel (public or hashtag)');
      return false;
    }
    await _channelsDao.setTeamFlag(channel.hash, isTeam);
    debugPrint(
        '[Channel] ${isTeam ? '👥' : '🚪'} "${channel.name}" team=$isTeam');
    return true;
  }

  /// The tracking channel is a team channel by definition. Called at startup
  /// and whenever the tracking channel changes.
  Future<void> markTrackingChannelAsTeam() async {
    final hash = parseTrackingChannelHash(
        _settingsService.settings.telemetryChannelHash);
    if (hash == null) return;

    final channel = await _channelsDao.getChannelByHash(hash);
    if (channel == null || channel.isTeam) return;
    await setTeamChannel(channel, true);
  }

  int? _nextAvailablePrivateIndex(Set<int> usedIndices) {
    for (int idx = 1; idx <= _maxPrivateChannels; idx++) {
      if (!usedIndices.contains(idx)) return idx;
    }
    return null;
  }

  String _bytesToHex(Uint8List bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  Uint8List _hexToBytes(String hex) {
    final clean = hex.trim();
    if (clean.length % 2 != 0) {
      throw FormatException('Invalid hex length');
    }
    final out = Uint8List(clean.length ~/ 2);
    for (int i = 0; i < clean.length; i += 2) {
      out[i ~/ 2] = int.parse(clean.substring(i, i + 2), radix: 16);
    }
    return out;
  }

  String? _extractMeshcoreUrl(String a, String b) {
    const prefix = 'meshcore://channel/add?';
    final aTrimmed = a.trim();
    final bTrimmed = b.trim();
    if (aTrimmed.startsWith(prefix)) return aTrimmed;
    if (bTrimmed.startsWith(prefix)) return bTrimmed;
    return null;
  }

  _ParsedChannelLink? _parseMeshcoreChannelUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final nameRaw = uri.queryParameters['name'];
      final secret = uri.queryParameters['secret'];
      if (nameRaw == null || secret == null) return null;

      // Uri.queryParameters already decodes '+' to space via decodeQueryComponent.
      final channelName = nameRaw.trim();
      if (channelName.isEmpty) return null;

      Uint8List psk;
      if (secret.length == 32 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(secret)) {
        psk = _hexToBytes(secret.toLowerCase());
      } else {
        psk = Uint8List.fromList(base64.decode(secret));
      }
      if (psk.length != 16) return null;
      return _ParsedChannelLink(name: channelName, psk: psk);
    } catch (_) {
      return null;
    }
  }

  Uint8List? _parseLegacyKey(String cleanKey) {
    try {
      if (cleanKey.contains('+') ||
          cleanKey.contains('/') ||
          cleanKey.contains('=')) {
        return Uint8List.fromList(base64.decode(cleanKey));
      }
      if (cleanKey.length == 32 &&
          RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleanKey)) {
        return _hexToBytes(cleanKey.toLowerCase());
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _encodeNameForMeshcoreUrl(String name) {
    // Match Java URLEncoder behavior used by TEAM (space => '+')
    return Uri.encodeQueryComponent(name).replaceAll('%20', '+');
  }

  /// Puts a channel the phone owns into a slot on the connected radio.
  ///
  /// A team channel can exist with no radio holding it — after a radio
  /// switch, or when the radio's slots were full — but the radio does the
  /// encryption, so it has to be there to send or receive on that channel.
  ///
  /// Returns null on success, or a reason: [AddChannelToRadioError.noSlots]
  /// when the radio is full, [AddChannelToRadioError.notConnected], or
  /// [AddChannelToRadioError.failed].
  Future<AddChannelToRadioError?> addChannelToRadio(
      ChannelData channel) async {
    if (!_bleManager.isConnected) return AddChannelToRadioError.notConnected;

    final companionKey = _settingsService.settings.currentCompanionPublicKey;

    final int? index;
    try {
      index = await _findFreeSlotOnRadio(companionKey);
    } on StateError {
      return AddChannelToRadioError.failed;
    }
    if (index == null) return AddChannelToRadioError.noSlots;

    final result = await _registerChannelWithFirmware(
      channelIndex: index,
      name: channel.name,
      psk: channel.sharedKey,
    );
    if (!result.isSuccess) {
      debugPrint(
          '[Channel] ❌ Could not add "${channel.name}" to the radio (code=${result.errorCode})');
      return AddChannelToRadioError.failed;
    }

    await _channelsDao.updateChannel(ChannelsCompanion(
      hash: drift.Value(channel.hash),
      channelIndex: drift.Value(index),
      firmwareConfirmed: const drift.Value(true),
      companionDeviceKey: drift.Value(companionKey),
    ));
    debugPrint('[Channel] ✅ Added "${channel.name}" to the radio at $index');
    return null;
  }

  Future<_OkOrError> _registerChannelWithFirmware({
    required int channelIndex,
    required String name,
    required Uint8List psk,
  }) async {
    final completer = Completer<_OkOrError>();
    StreamSubscription<Uint8List>? sub;
    Timer? timer;

    void cleanup() {
      timer?.cancel();
      timer = null;
      sub?.cancel();
      sub = null;
    }

    // IMPORTANT: Subscribe BEFORE sending.
    // Firmware can respond very quickly; subscribing after send can miss OK/ERR.
    sub = _bleManager.receivedFrames.listen((frame) {
      if (frame.isEmpty || completer.isCompleted) return;
      final code = frame[0];
      if (code == BleConstants.respOk) {
        completer.complete(const _OkOrError.ok());
      } else if (code == BleConstants.respErr) {
        final err = frame.length >= 2 ? frame[1] : null;
        completer.complete(_OkOrError.err(err));
      }
    });

    timer = Timer(const Duration(milliseconds: 2000), () {
      if (!completer.isCompleted) {
        completer.complete(const _OkOrError.timeout());
      }
    });

    final cmd = BleCommands.buildSetChannel(channelIndex, name, psk);
    final sendSuccess = await _bleManager.sendFrame(cmd);
    if (!sendSuccess) {
      cleanup();
      return const _OkOrError.sendFailed();
    }

    final result = await completer.future;
    cleanup();
    return result;
  }

  /// Fetch all channels from firmware
  /// Loops through channel indices 0 to maxChannels
  /// Returns true if sync completed successfully
  ///
  /// Matches Android fetchChannelsFromFirmware() implementation:
  /// - Probes each channel index (0-7 by default)
  /// - Waits for RESP_CHANNEL_INFO or ERR_CODE_NOT_FOUND
  /// - Stops when ERR_CODE_NOT_FOUND received (end of table)
  /// - DELETES all local channels (firmware is source of truth)
  /// - Inserts fetched channels with companionDeviceKey tagging
  Future<bool> fetchChannelsFromFirmware({int maxChannels = 8}) async {
    debugPrint(
        '[ChannelSync] 🔄 Starting channel FETCH from firmware (max capacity: $maxChannels)...');
    syncTrace('$_syncTraceTag begin maxChannels=$maxChannels');

    // Reset progress tracking
    _updateProgress(ChannelSyncProgress(
      currentCount: 0,
      totalCount: maxChannels,
      isComplete: false,
    ));

    try {
      final fetchedChannels = <ChannelsCompanion>[];
      bool reachedEndOfTable = false;
      // Slots the radio didn't answer for. Their contents are unknown, so
      // whatever the phone had there is kept rather than treated as gone.
      final unreadSlots = <int>{};

      // Subscribe to incoming frames to route responses
      _frameSubscription = _bleManager.receivedFrames.listen((frame) {
        if (frame.isEmpty) return;
        _routeResponse(frame);
      });

      final initialResults =
          await _collectPipelinedChannelResults(maxChannels: maxChannels);

      for (int index = 0; index < maxChannels; index++) {
        if (reachedEndOfTable) break;

        _ChannelFetchResult? result = initialResults[index];
        int resolvedAttempt = result != null ? 1 : 0;

        if (result == null) {
          syncTrace('$_syncTraceTag probe index=$index phase=retry');
        }

        for (int attempt = 2;
            attempt <= _channelFetchRetryAttempts && result == null;
            attempt++) {
          debugPrint(
              '[ChannelSync] Fetching channel index $index - attempt $attempt/$_channelFetchRetryAttempts');
          syncTrace('$_syncTraceTag request index=$index attempt=$attempt');

          final cmd = BleCommands.buildGetChannel(index);
          final sendSuccess = await _bleManager.sendFrame(cmd);

          if (!sendSuccess) {
            debugPrint(
                '[ChannelSync] Failed to send CMD_GET_CHANNEL for index $index');
            syncTrace(
                '$_syncTraceTag send_failed index=$index attempt=$attempt');
            if (attempt < _channelFetchRetryAttempts) {
              await Future.delayed(const Duration(milliseconds: 300));
            }
            continue;
          }

          syncTrace(
              '$_syncTraceTag request_sent index=$index attempt=$attempt');

          final retryResult =
              await _waitForChannelOrError(index, timeoutMs: 2000);
          if (retryResult.isChannel || retryResult.isError) {
            result = retryResult;
            resolvedAttempt = attempt;
            break;
          }

          debugPrint(
              '[ChannelSync] ⚠️ Timeout waiting for channel $index response, attempt $attempt/$_channelFetchRetryAttempts');
          syncTrace(
              '$_syncTraceTag response_timeout index=$index attempt=$attempt');
          if (attempt < _channelFetchRetryAttempts) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }

        if (result?.isChannel == true) {
          final channelInfo = result!.channel!;
          syncTrace(
              '$_syncTraceTag response_channel index=$index attempt=$resolvedAttempt name="${channelInfo.name}"');

          if (channelInfo.name.isNotEmpty) {
            final pskBytes = _base64ToBytes(channelInfo.psk);
            final hash = _calculateHash(pskBytes);
            final companionKey =
                _settingsService.settings.currentCompanionPublicKey;

            if (companionKey == null || companionKey.isEmpty) {
              debugPrint(
                  '[ChannelSync] ⚠️ WARNING: Companion key not set! Channel will not be tagged properly.');
            }

            final channelEntity = ChannelsCompanion.insert(
              hash: drift.Value(hash),
              name: channelInfo.name,
              sharedKey: pskBytes,
              isPublic: index == 0,
              shareLocation: const drift.Value(false),
              channelIndex: index,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              companionDeviceKey: drift.Value(companionKey),
            );
            fetchedChannels.add(channelEntity);
            debugPrint(
                '[ChannelSync] ✅ Channel $index \'${channelInfo.name}\' fetched (hash=$hash, companion=${companionKey?.substring(0, 8)})');
            syncTrace(
                '$_syncTraceTag stored index=$index hash=$hash isPublic=${index == 0}');
          } else {
            debugPrint(
                '[ChannelSync] Channel index $index is empty (no channel registered)');
            syncTrace('$_syncTraceTag response_empty index=$index');
          }
        } else if (result?.isError == true) {
          if (result!.errorCode == 0x01) {
            debugPrint(
                '[ChannelSync] Reached end of channel table at index $index (ERR_CODE_NOT_FOUND)');
            syncTrace('$_syncTraceTag end_of_table index=$index code=1');
            reachedEndOfTable = true;
          } else {
            debugPrint(
                '[ChannelSync] ⚠️ Firmware ERR while fetching channel $index: code=${result.errorCode}');
            syncTrace(
                '$_syncTraceTag response_error index=$index attempt=${resolvedAttempt == 0 ? 1 : resolvedAttempt} code=${result.errorCode}');
          }
        } else {
          debugPrint(
              '[ChannelSync] ⚠️ Could not fetch channel index $index after $_channelFetchRetryAttempts attempts, continuing...');
          unreadSlots.add(index);
          syncTrace('$_syncTraceTag probe_failed index=$index');
        }

        _updateProgress(ChannelSyncProgress(
          currentCount: index + 1,
          totalCount: maxChannels,
          isComplete: false,
        ));
      }
      // Cleanup frame subscription
      await _frameSubscription?.cancel();
      _frameSubscription = null;

      debugPrint(
          '[ChannelSync] ✅ Fetch complete: ${fetchedChannels.length} channels retrieved from firmware');
      syncTrace(
          '$_syncTraceTag fetch_complete fetched=${fetchedChannels.length} reachedEndOfTable=$reachedEndOfTable');
      debugPrint(
          '[COMPANION-SYNC] [ChannelSync] Tagging channels with companion: ${_settingsService.settings.currentCompanionPublicKey?.substring(0, 16)}...');

      // FIRMWARE IS SOURCE OF TRUTH - Replace all local channels atomically
      await _channelsDao.replaceAllChannels(fetchedChannels,
          unreadSlots: unreadSlots);
      debugPrint(
          '[ChannelSync] 💾 Replaced all channels (${fetchedChannels.length} saved)');

      // Mark sync as complete
      _updateProgress(ChannelSyncProgress(
        currentCount: fetchedChannels.length,
        totalCount: maxChannels,
        isComplete: true,
      ));

      debugPrint(
          '[ChannelSync] ✅ Database updated with ${fetchedChannels.length} channels from firmware (SOURCE OF TRUTH)');
      syncTrace(
          '$_syncTraceTag sync_complete success=true saved=${fetchedChannels.length} maxChannels=$maxChannels');
      return true;
    } catch (e) {
      debugPrint('[ChannelSync] ❌ Channel fetch failed with exception: $e');
      syncTrace('$_syncTraceTag sync_complete success=false error=$e');
      _updateProgress(
          ChannelSyncProgress(totalCount: maxChannels, isComplete: true));
      return false;
    }
  }

  /// Route received frame to appropriate controller
  void _routeResponse(Uint8List frame) {
    if (frame.isEmpty) return;

    final responseCode = frame[0];

    // Channel info response
    if (responseCode == BleConstants.respChannelInfo) {
      final response = BleResponseParser.parse(frame);
      if (response is ChannelInfoResponse) {
        syncTrace(
            '$_syncTraceTag raw_channel_info index=${response.channelIndex} name="${response.name}"');
        _channelResponseController.add(response);
      }
      return;
    }

    // Error response
    if (responseCode == BleConstants.respErr) {
      if (frame.length >= 2) {
        final errorCode = frame[1];
        syncTrace('$_syncTraceTag raw_err code=$errorCode');
        _errorResponseController.add(errorCode);
      }
      return;
    }
  }

  /// Wait for channel info or error response for specific index
  Future<_ChannelFetchResult> _waitForChannelOrError(int expectedIndex,
      {required int timeoutMs}) async {
    final completer = Completer<_ChannelFetchResult>();

    // Listen for channel response
    StreamSubscription<ChannelInfoResponse>? channelSub;
    channelSub = _channelResponseController.stream.listen((response) {
      if (response.channelIndex == expectedIndex) {
        if (!completer.isCompleted) {
          completer.complete(_ChannelFetchResult.channel(response));
        }
        channelSub?.cancel();
      }
    });

    // Listen for error response
    StreamSubscription<int>? errorSub;
    errorSub = _errorResponseController.stream.listen((errorCode) {
      if (!completer.isCompleted) {
        completer.complete(_ChannelFetchResult.error(errorCode));
      }
      errorSub?.cancel();
      channelSub?.cancel();
    });

    // Timeout
    Timer(Duration(milliseconds: timeoutMs), () {
      if (!completer.isCompleted) {
        syncTrace(
            '$_syncTraceTag wait_timeout index=$expectedIndex timeoutMs=$timeoutMs');
        completer.complete(_ChannelFetchResult.error(null));
      }
      channelSub?.cancel();
      errorSub?.cancel();
    });

    return completer.future;
  }

  Future<Map<int, _ChannelFetchResult>> _collectPipelinedChannelResults(
      {required int maxChannels}) async {
    final results = <int, _ChannelFetchResult>{};
    final pendingIndices = <int>[];
    final completion = Completer<void>();

    StreamSubscription<ChannelInfoResponse>? channelSub;
    StreamSubscription<int>? errorSub;
    Timer? idleTimer;
    Timer? maxWaitTimer;

    void completeIfPending(String reason) {
      if (!completion.isCompleted) {
        syncTrace(
            '$_syncTraceTag pipeline_wait_complete reason=$reason pending=${pendingIndices.length} received=${results.length}');
        completion.complete();
      }
    }

    void scheduleIdleTimer() {
      idleTimer?.cancel();
      idleTimer = Timer(_channelFetchPipelineIdleWindow, () {
        completeIfPending('idle');
      });
    }

    void storeResult(int index, _ChannelFetchResult result) {
      if (results.containsKey(index)) {
        return;
      }
      results[index] = result;
      pendingIndices.remove(index);
      if (pendingIndices.isEmpty) {
        completeIfPending('all_received');
        return;
      }
      scheduleIdleTimer();
    }

    channelSub = _channelResponseController.stream.listen((response) {
      storeResult(response.channelIndex, _ChannelFetchResult.channel(response));
    });

    errorSub = _errorResponseController.stream.listen((errorCode) {
      if (pendingIndices.isEmpty) {
        syncTrace('$_syncTraceTag raw_err_unmatched code=$errorCode');
        return;
      }

      final index = pendingIndices.removeAt(0);
      syncTrace('$_syncTraceTag raw_err_assigned index=$index code=$errorCode');
      results[index] = _ChannelFetchResult.error(errorCode);
    });

    try {
      for (int index = 0; index < maxChannels; index++) {
        syncTrace('$_syncTraceTag probe index=$index phase=start');
        syncTrace('$_syncTraceTag request index=$index attempt=1');

        final cmd = BleCommands.buildGetChannel(index);
        final sendSuccess = await _bleManager.sendFrame(cmd);

        if (!sendSuccess) {
          syncTrace('$_syncTraceTag send_failed index=$index attempt=1');
          continue;
        }

        pendingIndices.add(index);
        syncTrace('$_syncTraceTag request_sent index=$index attempt=1');
      }

      if (pendingIndices.isEmpty) {
        completeIfPending('no_pending');
      } else {
        scheduleIdleTimer();
        maxWaitTimer = Timer(_channelFetchPipelineMaxWait, () {
          completeIfPending('max_wait');
        });
      }

      await completion.future;
    } finally {
      idleTimer?.cancel();
      maxWaitTimer?.cancel();
      await channelSub?.cancel();
      await errorSub?.cancel();
    }

    return results;
  }

  /// Convert base64 PSK to bytes
  Uint8List _base64ToBytes(String pskBase64) {
    try {
      return Uint8List.fromList(base64.decode(pskBase64));
    } catch (e) {
      debugPrint('[ChannelSync] ⚠️ Failed to decode PSK: $e');
      return Uint8List(16); // Return empty 16-byte key
    }
  }

  /// Calculate SHA256 hash from PSK (uses full hash for proper collision resistance)
  int _calculateHash(Uint8List pskBytes) {
    try {
      final digest = sha256.convert(pskBytes);
      // Use proper hash of all bytes instead of just first byte
      int hash = 0;
      for (int i = 0; i < digest.bytes.length; i++) {
        hash = (hash * 31 + digest.bytes[i]) & 0xFFFFFFFF; // Keep as 32-bit int
      }
      return hash;
    } catch (e) {
      debugPrint('[ChannelSync] ⚠️ Failed to calculate hash: $e');
      return 0;
    }
  }

  /// Update sync progress and notify listeners
  void _updateProgress(ChannelSyncProgress progress) {
    _currentProgress = progress;
    if (!_syncProgressController.isClosed) {
      _syncProgressController.add(progress);
    }
  }

  /// Get all channels for the current companion device
  /// Auto-switches when currentCompanionPublicKey changes
  /// Matches Android ChannelRepository.getAllChannels()
  /// Channels to offer the user: the connected radio's, plus team channels,
  /// which belong to the phone and are shown with or without a radio.
  Stream<List<ChannelData>> getAllChannels() {
    return _settingsService.currentCompanionPublicKeyStream.switchMap(
        (companionKey) => _channelsDao.watchVisibleChannels(companionKey));
  }

  /// Watch channels with unread counts for current companion
  /// Auto-switches when currentCompanionPublicKey changes
  Stream<List<ChannelWithUnread>> watchChannelsWithUnread() {
    return _settingsService.currentCompanionPublicKeyStream.switchMap(
        (companionKey) =>
            _channelsDao.watchChannelsWithUnreadByCompanion(companionKey));
  }

  /// Set favorite status for a channel
  Future<void> setFavorite(int hash, bool favorite) {
    return _channelsDao.setFavorite(hash, favorite);
  }

  /// Delete all private channels from the companion and local DB.
  Future<int> deleteAllPrivateChannels() async {
    final companionKey = _settingsService.settings.currentCompanionPublicKey;
    if (companionKey == null || companionKey.isEmpty) return 0;
    final privateChannels = await _channelsDao.getPrivateChannels();
    int count = 0;
    for (final channel in privateChannels) {
      try {
        await deletePrivateChannel(channel);
        count++;
      } catch (e) {
        debugPrint('[Channel] ⚠️ Failed to delete "${channel.name}": $e');
      }
    }
    return count;
  }

  /// Set notification mode for a channel
  Future<void> setNotificationMode(int hash, String mode) {
    return _channelsDao.setNotificationMode(hash, mode);
  }

  /// Dispose resources
  void dispose() {
    _frameSubscription?.cancel();
    _syncProgressController.close();
    _channelResponseController.close();
    _errorResponseController.close();
  }
}
