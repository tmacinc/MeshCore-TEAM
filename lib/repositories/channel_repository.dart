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
import 'package:meshcore_team/models/sync_status.dart';
import 'package:meshcore_team/models/unread_models.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:drift/drift.dart' as drift;

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
class ChannelRepository {
  final BleConnectionManager _bleManager;
  final ChannelsDao _channelsDao;
  final SettingsService _settingsService;

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

  /// Create a new private channel with a random PSK.
  /// Matches Android createPrivateChannel(): finds next available index and registers with firmware when connected.
  Future<ChannelData> createPrivateChannel(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Channel name cannot be empty');
    }

    final companionKey = _settingsService.settings.currentCompanionPublicKey;
    if (companionKey == null || companionKey.isEmpty) {
      throw StateError('No companion selected');
    }

    // Generate random 16-byte PSK
    final rnd = Random.secure();
    final psk =
        Uint8List.fromList(List<int>.generate(16, (_) => rnd.nextInt(256)));
    final hash = _calculateHash(psk);

    // Check if channel already exists
    final existing = await _channelsDao.getChannelByHash(hash);
    if (existing != null) {
      return existing;
    }

    // Find next available channel index for this companion
    final existingChannels =
        await _channelsDao.getChannelsByCompanion(companionKey);
    final usedIndices = existingChannels.map((c) => c.channelIndex).toSet();
    final nextIndex = _nextAvailablePrivateIndex(usedIndices);
    if (nextIndex == null) {
      throw StateError(
          'Maximum number of channels ($_maxPrivateChannels) reached');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final channelCompanion = ChannelsCompanion.insert(
      hash: drift.Value(hash),
      name: trimmedName,
      sharedKey: psk,
      isPublic: false,
      shareLocation: const drift.Value(true),
      channelIndex: nextIndex,
      createdAt: now,
      companionDeviceKey: drift.Value(companionKey),
    );

    // Firmware is source of truth: register first when connected
    if (_bleManager.isConnected) {
      final result = await _registerChannelWithFirmware(
        channelIndex: nextIndex,
        name: trimmedName,
        psk: psk,
      );
      if (!result.isSuccess) {
        if (result.errorCode == 3) {
          throw StateError(
              'Maximum number of channels reached. Delete an existing channel before creating a new one.');
        }
        throw StateError(
            'Failed to register channel with firmware (error ${result.errorCode ?? 'unknown'})');
      }
      await Future.delayed(const Duration(milliseconds: 300));
    } else {
      debugPrint(
          '[Channel] ⚠️ Not connected - channel created in local DB only, will sync on reconnect');
    }

    await _channelsDao.upsertChannel(channelCompanion);
    final created = await _channelsDao.getChannelByHash(hash);
    if (created == null) {
      throw StateError('Channel creation failed');
    }
    return created;
  }

  /// Import a channel from meshcore:// URL or raw key.
  /// Matches Android importChannel(): accepts URL in either field or legacy name + key (base64/hex).
  Future<ChannelData?> importChannel(String nameOrUrl, String keyData) async {
    try {
      final companionKey = _settingsService.settings.currentCompanionPublicKey;
      if (companionKey == null || companionKey.isEmpty) {
        throw StateError('No companion selected');
      }

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

      // If channel already exists, return it
      final existing = await _channelsDao.getChannelByHash(hash);
      if (existing != null) return existing;

      // Find next available channel index for this companion
      final existingChannels =
          await _channelsDao.getChannelsByCompanion(companionKey);
      final usedIndices = existingChannels.map((c) => c.channelIndex).toSet();
      final nextIndex = _nextAvailablePrivateIndex(usedIndices);
      if (nextIndex == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch;
      final channelCompanion = ChannelsCompanion.insert(
        hash: drift.Value(hash),
        name: channelName,
        sharedKey: psk,
        isPublic: false,
        shareLocation: const drift.Value(true),
        channelIndex: nextIndex,
        createdAt: now,
        companionDeviceKey: drift.Value(companionKey),
      );

      // Firmware is source of truth: register first when connected
      if (_bleManager.isConnected) {
        final result = await _registerChannelWithFirmware(
          channelIndex: nextIndex,
          name: channelName,
          psk: psk,
        );
        if (!result.isSuccess) {
          return null;
        }
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        debugPrint(
            '[Channel] ⚠️ Not connected - channel imported to local DB only, will sync on reconnect');
      }

      await _channelsDao.upsertChannel(channelCompanion);
      return _channelsDao.getChannelByHash(hash);
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
  /// TEAM behavior: firmware is source of truth, so we clear the firmware slot
  /// first via CMD_SET_CHANNEL with empty name + zero PSK, then delete locally.
  Future<void> deletePrivateChannel(ChannelData channel) async {
    if (channel.isPublic || channel.channelIndex == 0) {
      throw StateError('Public channel cannot be deleted');
    }

    final companionKey = _settingsService.settings.currentCompanionPublicKey;
    if (companionKey == null || companionKey.isEmpty) {
      throw StateError('No companion selected');
    }

    // Safety: prevent deleting a channel row that belongs to a different companion.
    if (channel.companionDeviceKey != null &&
        channel.companionDeviceKey!.isNotEmpty &&
        channel.companionDeviceKey != companionKey) {
      throw StateError('Channel belongs to a different companion');
    }

    // Ensure we actually remove it from the companion device.
    if (!_bleManager.isConnected) {
      throw StateError('Connect to the companion device to delete channels');
    }

    debugPrint(
        '[Channel] 🗑️ Deleting private channel "${channel.name}" at index ${channel.channelIndex} (hash=${channel.hash})');

    // Clear from firmware first.
    final clearResult = await _registerChannelWithFirmware(
      channelIndex: channel.channelIndex,
      name: '',
      psk: Uint8List(16),
    );
    if (!clearResult.isSuccess) {
      throw StateError(
          'Failed to delete channel from companion (error ${clearResult.errorCode ?? 'unknown'})');
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // If this channel is selected for telemetry, clear the setting.
    final telemetryHashHex = channel.hash.toRadixString(16).toLowerCase();
    if (_settingsService.settings.telemetryChannelHash?.toLowerCase() ==
        telemetryHashHex) {
      await _settingsService.setTelemetryChannelHash(null);
    }

    // Delete messages first, then channel.
    await _channelsDao.attachedDatabase.messagesDao
        .deleteMessagesByChannelForCompanion(channel.hash, companionKey);
    await _channelsDao.deleteChannelForCompanion(channel.hash, companionKey);

    debugPrint(
        '[Channel] ✅ Deleted private channel "${channel.name}" (index ${channel.channelIndex})');
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
    if (a.startsWith(prefix)) return a.trim();
    if (b.startsWith(prefix)) return b.trim();
    return null;
  }

  _ParsedChannelLink? _parseMeshcoreChannelUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final nameRaw = uri.queryParameters['name'];
      final secret = uri.queryParameters['secret'];
      if (nameRaw == null || secret == null) return null;

      // Team Android exports names using URLEncoder (spaces become '+'), so decode '+' -> ' '.
      final channelName = nameRaw.replaceAll('+', ' ').trim();
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

    // Reset progress tracking
    _updateProgress(ChannelSyncProgress(
      currentCount: 0,
      totalCount: maxChannels,
      isComplete: false,
    ));

    try {
      final fetchedChannels = <ChannelsCompanion>[];
      bool reachedEndOfTable = false;

      // Subscribe to incoming frames to route responses
      _frameSubscription = _bleManager.receivedFrames.listen((frame) {
        if (frame.isEmpty) return;
        _routeResponse(frame);
      });

      // Probe each channel index
      for (int index = 0; index < maxChannels; index++) {
        if (reachedEndOfTable) break;

        bool channelFetched = false;

        // Retry up to 3 times per channel index
        for (int attempt = 1; attempt <= 3; attempt++) {
          debugPrint(
              '[ChannelSync] Fetching channel index $index - attempt $attempt/3');

          // Send CMD_GET_CHANNEL
          final cmd = BleCommands.buildGetChannel(index);
          final sendSuccess = await _bleManager.sendFrame(cmd);

          if (!sendSuccess) {
            debugPrint(
                '[ChannelSync] Failed to send CMD_GET_CHANNEL for index $index');
            await Future.delayed(const Duration(milliseconds: 300));
            continue;
          }

          // Wait for CHANNEL_INFO or ERROR response
          final result = await _waitForChannelOrError(index, timeoutMs: 2000);

          if (result.isChannel) {
            final channelInfo = result.channel!;
            if (channelInfo.name.isNotEmpty) {
              // Channel exists in firmware - add to our list
              final pskBytes = _base64ToBytes(channelInfo.psk);
              final hash = _calculateHash(pskBytes);
              final companionKey =
                  _settingsService.settings.currentCompanionPublicKey;

              // Warn if companion key is not set
              if (companionKey == null || companionKey.isEmpty) {
                debugPrint(
                    '[ChannelSync] ⚠️ WARNING: Companion key not set! Channel will not be tagged properly.');
              }

              final channelEntity = ChannelsCompanion.insert(
                hash: drift.Value(hash),
                name: channelInfo.name,
                sharedKey: pskBytes,
                isPublic: index == 0,
                shareLocation: const drift.Value(false), // Default to false
                channelIndex: index,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                companionDeviceKey: drift.Value(companionKey),
              );
              fetchedChannels.add(channelEntity);
              debugPrint(
                  '[ChannelSync] ✅ Channel $index \'${channelInfo.name}\' fetched (hash=$hash, companion=${companionKey?.substring(0, 8)})');
            } else {
              debugPrint(
                  '[ChannelSync] Channel index $index is empty (no channel registered)');
            }
            channelFetched = true;
            break;
          } else if (result.isError) {
            // Check if it's ERR_CODE_NOT_FOUND (0x01)
            if (result.errorCode == 0x01) {
              debugPrint(
                  '[ChannelSync] Reached end of channel table at index $index (ERR_CODE_NOT_FOUND)');
              reachedEndOfTable = true;
              channelFetched = true;
              break;
            }
            debugPrint(
                '[ChannelSync] ⚠️ Firmware ERR while fetching channel $index: code=${result.errorCode}');
            if (attempt < 3) {
              await Future.delayed(const Duration(milliseconds: 300));
            }
          } else {
            // Timeout
            debugPrint(
                '[ChannelSync] ⚠️ Timeout waiting for channel $index response, attempt $attempt/3');
            if (attempt < 3) {
              await Future.delayed(const Duration(milliseconds: 300));
            }
          }
        }

        if (!channelFetched) {
          debugPrint(
              '[ChannelSync] ⚠️ Could not fetch channel index $index after 3 attempts, continuing...');
        }

        // Update progress
        _updateProgress(ChannelSyncProgress(
          currentCount: index + 1,
          totalCount: maxChannels,
          isComplete: false,
        ));

        // Small delay between channel requests
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Cleanup frame subscription
      await _frameSubscription?.cancel();
      _frameSubscription = null;

      debugPrint(
          '[ChannelSync] ✅ Fetch complete: ${fetchedChannels.length} channels retrieved from firmware');
      debugPrint(
          '[COMPANION-SYNC] [ChannelSync] Tagging channels with companion: ${_settingsService.settings.currentCompanionPublicKey?.substring(0, 16)}...');

      // FIRMWARE IS SOURCE OF TRUTH - Delete all local channels, then insert fetched ones
      // Note: We delete ALL channels, not just for this companion, to ensure clean state
      final allChannels = await _channelsDao.getAllChannels();
      for (final channel in allChannels) {
        await _channelsDao.deleteChannel(channel.hash);
      }
      debugPrint('[ChannelSync] 🗑️ Deleted all local channels');

      await Future.delayed(const Duration(milliseconds: 100));

      // Insert fetched channels
      for (final channel in fetchedChannels) {
        await _channelsDao.upsertChannel(channel);
        debugPrint(
            '[ChannelSync] 💾 Saved: \'${channel.name.value}\' (index=${channel.channelIndex.value})');
      }

      // Mark sync as complete
      _updateProgress(ChannelSyncProgress(
        currentCount: fetchedChannels.length,
        totalCount: maxChannels,
        isComplete: true,
      ));

      debugPrint(
          '[ChannelSync] ✅ Database updated with ${fetchedChannels.length} channels from firmware (SOURCE OF TRUTH)');
      return true;
    } catch (e) {
      debugPrint('[ChannelSync] ❌ Channel fetch failed with exception: $e');
      _updateProgress(ChannelSyncProgress(totalCount: maxChannels, isComplete: true));
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
        _channelResponseController.add(response);
      }
      return;
    }

    // Error response
    if (responseCode == BleConstants.respErr) {
      if (frame.length >= 2) {
        final errorCode = frame[1];
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
        completer.complete(_ChannelFetchResult.error(null));
      }
      channelSub?.cancel();
      errorSub?.cancel();
    });

    return completer.future;
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
  Stream<List<ChannelData>> getAllChannels() {
    return _settingsService.currentCompanionPublicKeyStream
        .switchMap((companionKey) {
      if (companionKey != null && companionKey.isNotEmpty) {
        return _channelsDao.watchChannelsByCompanion(companionKey);
      } else {
        // No companion selected - return empty list
        return Stream.value([]);
      }
    });
  }

  /// Watch channels with unread counts for current companion
  /// Auto-switches when currentCompanionPublicKey changes
  Stream<List<ChannelWithUnread>> watchChannelsWithUnread() {
    return _settingsService.currentCompanionPublicKeyStream
        .switchMap((companionKey) {
      if (companionKey != null && companionKey.isNotEmpty) {
        return _channelsDao.watchChannelsWithUnreadByCompanion(companionKey);
      } else {
        // No companion selected - return empty list
        return Stream.value([]);
      }
    });
  }

  /// Dispose resources
  void dispose() {
    _frameSubscription?.cancel();
    _syncProgressController.close();
    _channelResponseController.close();
    _errorResponseController.close();
  }
}
