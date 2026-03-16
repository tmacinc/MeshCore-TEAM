// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:meshcore_team/ble/ble_commands.dart';
import 'package:meshcore_team/ble/ble_connection_manager.dart';
import 'package:meshcore_team/ble/ble_constants.dart';
import 'package:meshcore_team/ble/ble_responses.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/sync_status.dart';
import 'package:meshcore_team/repositories/contact_repository.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import 'package:meshcore_team/repositories/message_repository.dart';
import 'package:meshcore_team/services/mesh_connection_service.dart';
import 'package:meshcore_team/services/settings_service.dart';

/// Connection View Model
/// Manages BLE connection lifecycle and orchestrates sequential sync
/// Matches Android ConnectionViewModel.kt implementation
class ConnectionViewModel extends ChangeNotifier {
  final BleConnectionManager _bleManager;
  final ContactRepository _contactRepository;
  final ChannelRepository _channelRepository;
  final MessageRepository _messageRepository;
  final MeshConnectionService _meshConnectionService;
  final SettingsService _settingsService;
  final AppDatabase _database;

  // Sync decision (per connection): full sync on first connect or companion switch.
  bool _shouldRunFullSyncForThisConnection = true;

  // Identity confirmation (TEAM behavior): mandatory on first connect or companion switch.
  bool _identityConfirmationRequired = false;
  bool get identityConfirmationRequired => _identityConfirmationRequired;

  // Sync state
  SyncStatus _syncStatus = const SyncStatus();
  SyncStatus get syncStatus => _syncStatus;

  // Device capabilities (from CMD_DEVICE_QUERY / RESP_SELF_INFO)
  SelfInfoResponse? _deviceCapabilities;
  SelfInfoResponse? get deviceCapabilities => _deviceCapabilities;

  // Firmware capabilities from CMD_DEVICE_QUERY (RESP_DEVICE_INFO)
  DeviceInfoResponse? _deviceInfo;
  DeviceInfoResponse? get deviceInfo => _deviceInfo;

  // Companion session ready flag (tracks when companion key is set)
  bool _companionSessionReady = false;

  int? _lastAutonomousSettingsErrorCode;
  int? get lastAutonomousSettingsErrorCode => _lastAutonomousSettingsErrorCode;

  // Cached autonomous enabled state (reflects firmware state after last get/set)
  bool? _currentAutonomousEnabled;
  bool? get currentAutonomousEnabled => _currentAutonomousEnabled;

  // Device name from firmware
  String get deviceName => _deviceCapabilities?.name ?? 'MeshCore Device';

  // Subscriptions - Keep frame subscription active during sync
  StreamSubscription<Uint8List>? _currentFrameSubscription;
  StreamSubscription<ContactSyncProgress>? _contactProgressSub;
  StreamSubscription<ChannelSyncProgress>? _channelProgressSub;

  // Battery polling
  Timer? _batteryTimer;
  int _batteryLevel = 0;
  int get batteryLevel => _batteryLevel;

  double? _companionBatteryVoltage;
  double? get companionBatteryVoltage => _companionBatteryVoltage;

  // Companion GPS (from telemetry Cayenne LPP)
  double? _companionLatitude;
  double? _companionLongitude;
  double? _companionAltitudeMeters;
  DateTime? _companionGpsFixTime;

  double? get companionLatitude => _companionLatitude;
  double? get companionLongitude => _companionLongitude;
  double? get companionAltitudeMeters => _companionAltitudeMeters;
  DateTime? get companionGpsFixTime => _companionGpsFixTime;
  bool get hasCompanionGpsFix =>
      _companionLatitude != null && _companionLongitude != null;

  // Connection state
  bool get isConnected => _bleManager.isConnected;

  /// Apply LoRa radio parameters (TEAM behavior)
  /// Sends CMD_SET_RADIO_PARAMS with frequency/bandwidth/SF/CR.
  Future<bool> setRadioParams({
    required double frequencyMHz,
    required double bandwidthKHz,
    required int spreadingFactor,
    required int codingRate,
    bool enableClientRepeat = false,
  }) async {
    if (!isConnected) return false;

    try {
      final cmd = BleCommands.buildSetRadioParams(
        frequencyMHz: frequencyMHz,
        bandwidthKHz: bandwidthKHz,
        spreadingFactor: spreadingFactor,
        codingRate: codingRate,
        enableClientRepeat: enableClientRepeat,
      );
      return await _bleManager.sendFrame(cmd);
    } catch (e) {
      debugPrint('[ConnectionVM] ❌ setRadioParams failed: $e');
      return false;
    }
  }

  /// Apply TX power (TEAM behavior)
  Future<bool> setTxPower(int powerDbm) async {
    if (!isConnected) return false;
    final cmd = BleCommands.buildSetRadioTxPower(powerDbm);
    return await _bleManager.sendFrame(cmd);
  }

  /// Set flood-route maximum hop count (CMD_SET_MAX_HOPS = 73)
  Future<bool> setMaxHops(int maxHops) async {
    if (!isConnected) return false;

    try {
      final cmd = BleCommands.buildSetMaxHops(maxHops);
      final result = await _sendCommandAwaitOkOrErr(cmd);
      if (!result.isSuccess) {
        debugPrint(
            '[ConnectionVM] ⚠️ setMaxHops failed (timeout=${result.isTimeout}, sendFailed=${result.isSendFailed}, err=${result.errorCode})');
      }
      return result.isSuccess;
    } catch (e) {
      debugPrint('[ConnectionVM] ❌ setMaxHops failed: $e');
      return false;
    }
  }

  /// Set forwarding whitelist as 6-byte public key prefixes (CMD_SET_FORWARD_LIST = 74)
  Future<bool> setForwardList(List<Uint8List> pubKeyPrefixes) async {
    if (!isConnected) return false;

    try {
      final cmd = BleCommands.buildSetForwardList(pubKeyPrefixes);
      final result = await _sendCommandAwaitOkOrErr(cmd);
      if (!result.isSuccess) {
        debugPrint(
            '[ConnectionVM] ⚠️ setForwardList failed (timeout=${result.isTimeout}, sendFailed=${result.isSendFailed}, err=${result.errorCode})');
      }
      return result.isSuccess;
    } catch (e) {
      debugPrint('[ConnectionVM] ❌ setForwardList failed: $e');
      return false;
    }
  }

  /// Read autonomous settings from firmware (CMD_GET_AUTONOMOUS_SETTINGS = 75)
  Future<AutonomousSettingsResponse?> getAutonomousSettings() async {
    if (!isConnected) return null;

    try {
      final cmd = BleCommands.buildGetAutonomousSettings();
      final response = await _sendCommandAwaitResponseOrErr(
        cmd,
        expectedResponseCode: BleConstants.respAutonomousSettings,
      );

      if (response is AutonomousSettingsResponse) {
        _currentAutonomousEnabled = response.enabled;
        notifyListeners();
        return response;
      }

      return null;
    } catch (e) {
      debugPrint('[ConnectionVM] ❌ getAutonomousSettings failed: $e');
      return null;
    }
  }

  /// Persist autonomous settings to firmware (CMD_SET_AUTONOMOUS_SETTINGS = 76)
  Future<bool> setAutonomousSettings({
    required bool enabled,
    required int channelHash,
    required int intervalSec,
    required int minDistanceMeters,
  }) async {
    if (!isConnected) return false;

    _lastAutonomousSettingsErrorCode = null;

    try {
      final cmd = BleCommands.buildSetAutonomousSettings(
        enabled: enabled,
        channelHash: channelHash,
        intervalSec: intervalSec,
        minDistanceMeters: minDistanceMeters,
      );

      final result = await _sendCommandAwaitOkOrErr(cmd);
      if (!result.isSuccess) {
        _lastAutonomousSettingsErrorCode = result.errorCode;
        debugPrint(
            '[ConnectionVM] ⚠️ setAutonomousSettings failed (timeout=${result.isTimeout}, sendFailed=${result.isSendFailed}, err=${result.errorCode})');
        return false;
      }

      final expectedEnabled = enabled;
      final expectedChannelHash = channelHash & 0xFF;
      final expectedInterval = intervalSec.clamp(10, 3600);
      final expectedMinDistance = minDistanceMeters.clamp(0, 5000);

      await Future.delayed(const Duration(milliseconds: 120));
      final applied = await getAutonomousSettings();
      // getAutonomousSettings() already updates _currentAutonomousEnabled and notifies
      if (applied == null) {
        _lastAutonomousSettingsErrorCode = -2;
        debugPrint(
            '[ConnectionVM] ⚠️ setAutonomousSettings verification failed: no response from GET_AUTONOMOUS_SETTINGS');
        return false;
      }

      final verified = applied.enabled == expectedEnabled &&
          applied.channelHash == expectedChannelHash &&
          applied.intervalSec == expectedInterval &&
          applied.minDistanceMeters == expectedMinDistance;

      if (!verified) {
        _lastAutonomousSettingsErrorCode = -3;
        debugPrint(
            '[ConnectionVM] ⚠️ setAutonomousSettings verification mismatch (expected: enabled=$expectedEnabled, channelHash=$expectedChannelHash, interval=$expectedInterval, minDistance=$expectedMinDistance; actual: enabled=${applied.enabled}, channelHash=${applied.channelHash}, interval=${applied.intervalSec}, minDistance=${applied.minDistanceMeters})');
      }

      return verified;
    } catch (e) {
      _lastAutonomousSettingsErrorCode = -4;
      debugPrint('[ConnectionVM] ❌ setAutonomousSettings failed: $e');
      return false;
    }
  }

  /// Apply radio settings and verify by polling SELF_INFO (CMD_APP_START)
  /// Mirrors TEAM: set params, set power, then poll and verify.
  Future<bool> applyRadioSettings({
    required double frequencyMHz,
    required double bandwidthKHz,
    required int spreadingFactor,
    required int codingRate,
    required int txPowerDbm,
    bool enableClientRepeat = false,
  }) async {
    if (!isConnected) return false;

    final paramsOk = await setRadioParams(
      frequencyMHz: frequencyMHz,
      bandwidthKHz: bandwidthKHz,
      spreadingFactor: spreadingFactor,
      codingRate: codingRate,
      enableClientRepeat: enableClientRepeat,
    );
    if (!paramsOk) return false;

    await Future.delayed(const Duration(milliseconds: 100));

    final powerOk = await setTxPower(txPowerDbm);
    if (!powerOk) return false;

    // Give device time to apply settings.
    await Future.delayed(const Duration(milliseconds: 500));

    return await _pollAndVerifyRadioSettings(
      expectedFreqMHz: frequencyMHz,
      expectedBwKHz: bandwidthKHz,
      expectedSF: spreadingFactor,
      expectedCR: codingRate,
      expectedTxPower: txPowerDbm,
      maxRetries: 20,
      delayMs: 500,
    );
  }

  ConnectionViewModel({
    required BleConnectionManager bleManager,
    required ContactRepository contactRepository,
    required ChannelRepository channelRepository,
    required MessageRepository messageRepository,
    required MeshConnectionService meshConnectionService,
    required SettingsService settingsService,
    required AppDatabase database,
  })  : _bleManager = bleManager,
        _contactRepository = contactRepository,
        _channelRepository = channelRepository,
        _messageRepository = messageRepository,
        _meshConnectionService = meshConnectionService,
        _settingsService = settingsService,
        _database = database {
    // Listen to connection state changes
    _bleManager.addListener(_onConnectionStateChanged);
  }

  Future<bool> _pollAndVerifyRadioSettings({
    required double expectedFreqMHz,
    required double expectedBwKHz,
    required int expectedSF,
    required int expectedCR,
    required int expectedTxPower,
    required int maxRetries,
    required int delayMs,
  }) async {
    bool closeEnough(double a, double b) => (a - b).abs() < 0.1;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      if (!isConnected) return false;

      final cmd = BleCommands.buildAppStart();
      await _bleManager.sendFrame(cmd);
      await Future.delayed(Duration(milliseconds: delayMs));

      final caps = _deviceCapabilities;
      if (caps == null) continue;

      final freqMatch = closeEnough(caps.frequencyMHz, expectedFreqMHz);
      final bwMatch = closeEnough(caps.bandwidthKHz, expectedBwKHz);
      final sfMatch = caps.spreadingFactor == expectedSF;
      final crMatch = caps.codingRate == expectedCR;
      final txMatch = caps.txPower == expectedTxPower;

      if (freqMatch && bwMatch && sfMatch && crMatch && txMatch) {
        debugPrint('[ConnectionVM] ✅ Radio settings verified');
        return true;
      }
    }

    debugPrint('[ConnectionVM] ❌ Radio settings verification timed out');
    return false;
  }

  Future<_AckResult> _sendCommandAwaitOkOrErr(
    Uint8List cmd, {
    int timeoutMs = 2000,
  }) async {
    final completer = Completer<_AckResult>();

    late final StreamSubscription<Uint8List> sub;
    sub = _bleManager.receivedFrames.listen((frame) {
      if (frame.isEmpty || completer.isCompleted) return;

      final responseCode = frame[0];
      if (responseCode == BleConstants.respOk) {
        completer.complete(const _AckResult.ok());
      } else if (responseCode == BleConstants.respErr) {
        final errCode = frame.length > 1 ? frame[1] : null;
        completer.complete(_AckResult.err(errCode));
      }
    });

    try {
      final sent = await _bleManager.sendFrame(cmd);
      if (!sent) {
        return const _AckResult.sendFailed();
      }

      Timer(Duration(milliseconds: timeoutMs), () {
        if (!completer.isCompleted) {
          completer.complete(const _AckResult.timeout());
        }
      });

      return await completer.future;
    } finally {
      await sub.cancel();
    }
  }

  Future<BleResponse?> _sendCommandAwaitResponseOrErr(
    Uint8List cmd, {
    required int expectedResponseCode,
    int timeoutMs = 2000,
  }) async {
    final completer = Completer<BleResponse?>();

    late final StreamSubscription<Uint8List> sub;
    sub = _bleManager.receivedFrames.listen((frame) {
      if (frame.isEmpty || completer.isCompleted) return;

      final responseCode = frame[0];
      if (responseCode == expectedResponseCode) {
        completer.complete(BleResponseParser.parse(frame));
      } else if (responseCode == BleConstants.respErr) {
        final errCode = frame.length > 1 ? frame[1] : null;
        debugPrint(
            '[ConnectionVM] ⚠️ Command returned ERR while waiting for $expectedResponseCode (err=$errCode)');
        completer.complete(null);
      }
    });

    try {
      final sent = await _bleManager.sendFrame(cmd);
      if (!sent) return null;

      Timer(Duration(milliseconds: timeoutMs), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      return await completer.future;
    } finally {
      await sub.cancel();
    }
  }

  /// Handle connection state changes
  void _onConnectionStateChanged() {
    if (_bleManager.state == BleConnectionState.connected) {
      debugPrint(
          '[ConnectionVM] 🔗 Device connected - triggering initial sync...');
      _performInitialSync();
    } else if (_bleManager.state == BleConnectionState.disconnected) {
      debugPrint('[ConnectionVM] 🔌 Device disconnected - stopping sync');
      _stopSync();
    }
  }

  /// Perform initial sync sequence after connection
  /// Matches Android ConnectionViewModel sync workflow:
  /// 1. Set up frame subscription (keep active during sync)
  /// 2. 500ms delay
  /// 3. CMD_DEVICE_QUERY (get capabilities)
  /// 4. 200ms delay
  /// 5. CMD_APP_START (initialize session)
  /// 6. Sequential sync: Contacts → Channels → Messages
  Future<void> _performInitialSync() async {
    try {
      debugPrint('[ConnectionVM] 🚀 Starting initial sync sequence...');

      // Reset companion session ready flag
      _companionSessionReady = false;

      // Default to unlocked; will be enabled once we detect new/switch companion.
      _identityConfirmationRequired = false;

      // Default to full sync until we confirm we're reconnecting to the same companion.
      _shouldRunFullSyncForThisConnection = true;

      // Reset sync status
      _updateSyncStatus(
          const SyncStatus(phase: SyncPhase.idle, isComplete: false));

      // Set up frame subscription for entire sync process (matches Android TEAM)
      _setupFrameSubscription();

      // Wait 500ms for connection to stabilize
      await Future.delayed(const Duration(milliseconds: 500));

      // Send CMD_DEVICE_QUERY to get firmware capabilities
      debugPrint('[ConnectionVM] 📡 Sending CMD_DEVICE_QUERY...');
      await _sendDeviceQuery();

      // Wait 200ms
      await Future.delayed(const Duration(milliseconds: 200));

      // Send CMD_APP_START to initialize session
      debugPrint('[ConnectionVM] 📡 Sending CMD_APP_START...');
      final appStartCmd = BleCommands.buildAppStart();
      await _bleManager.sendFrame(appStartCmd);

      // Wait for RESP_SELF_INFO + companion session tracking
      await _waitForSelfInfoAndCompanionSessionReady();

      if (_shouldRunFullSyncForThisConnection) {
        debugPrint(
            '[ConnectionVM] 🔄 Running FULL sync (contacts/channels/messages)');
        await _runFullSyncPhases();
      } else {
        final isAutoReconnect = _settingsService.isAutoReconnectInProgress;
        if (isAutoReconnect) {
          debugPrint(
              '[ConnectionVM] ↩️ Auto-reconnected to same companion: running CONTACTS + MESSAGES sync (skip channels)');
          await _runContactAndMessageSync();
        } else {
          debugPrint(
              '[ConnectionVM] 🔁 Manual reconnect to same companion: running incremental sync');
          await _runContactAndMessageSync();
        }
      }

      await _finalizeAfterSync();
    } catch (e) {
      debugPrint('[ConnectionVM] ❌ Initial sync failed: $e');
      _updateSyncStatus(
          const SyncStatus(phase: SyncPhase.idle, isComplete: true));
    }
  }

  /// Confirm/apply identity name (TEAM behavior)
  /// - Always updates local companion device record name
  /// - Only sends CMD_SET_ADVERT_NAME + CMD_REBOOT if name actually changed
  /// Returns true on success (or no-op), false if a rename attempt failed.
  Future<bool> confirmIdentityName(String name) async {
    String truncate31(String value) {
      if (value.length <= 31) return value;
      return value.substring(0, 31);
    }

    final trimmed = truncate31(name.trim());
    if (trimmed.isEmpty) return false;

    final currentName = truncate31(_deviceCapabilities?.name.trim() ?? '');

    final companionKey = _settingsService.settings.currentCompanionPublicKey;
    if (companionKey != null && companionKey.isNotEmpty) {
      try {
        await _database.companionDevicesDao.updateCompanionDevice(
          CompanionDevicesCompanion(
            publicKeyHex: drift.Value(companionKey),
            name: drift.Value(trimmed),
          ),
        );
      } catch (e) {
        debugPrint(
            '[ConnectionVM] ⚠️ Failed to update local identity name: $e');
      }
    }

    // If unchanged, just accept and unlock.
    if (trimmed == currentName) {
      _identityConfirmationRequired = false;
      notifyListeners();
      return true;
    }

    debugPrint(
        '[ConnectionVM] ✏️ Identity name changed: "$currentName" → "$trimmed"');

    final setNameCmd = BleCommands.buildSetAdvertName(trimmed);
    final setOk = await _bleManager.sendFrame(setNameCmd);
    if (!setOk) {
      debugPrint('[ConnectionVM] ❌ Failed to send CMD_SET_ADVERT_NAME');
      return false;
    }

    // Give firmware a moment to process, matches Android TEAM.
    await Future.delayed(const Duration(milliseconds: 500));

    final rebootCmd = BleCommands.buildReboot();
    final rebootOk = await _bleManager.sendFrame(rebootCmd);
    if (!rebootOk) {
      debugPrint('[ConnectionVM] ❌ Failed to send CMD_REBOOT');
      return false;
    }

    debugPrint('[ConnectionVM] ✅ Rename applied; reboot requested');

    // Unlock now; reboot/reconnect should be treated as a normal reconnect.
    _identityConfirmationRequired = false;
    notifyListeners();
    return true;
  }

  Future<void> _waitForSelfInfoAndCompanionSessionReady() async {
    final startTime = DateTime.now();
    while (_deviceCapabilities == null || !_companionSessionReady) {
      await Future.delayed(const Duration(milliseconds: 100));

      if (DateTime.now().difference(startTime).inSeconds > 5) {
        if (_deviceCapabilities == null) {
          debugPrint(
              '[ConnectionVM] ⚠️ App start timeout - no RESP_SELF_INFO received');
        }
        if (!_companionSessionReady) {
          debugPrint('[ConnectionVM] ⚠️ Companion session setup timeout');
        }
        break;
      }
    }
  }

  /// Set up frame subscription for sync process (matches Android TEAM approach)
  void _setupFrameSubscription() {
    _currentFrameSubscription?.cancel();
    _currentFrameSubscription = _bleManager.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;

      final responseCode = frame[0];

      // Handle telemetry responses (PUSH_CODE_TELEMETRY_RESPONSE = 0x8B)
      if (responseCode == BleConstants.pushCodeTelemetryResponse) {
        debugPrint(
            '[ConnectionVM] 📡 Telemetry frame received: ${frame.length} bytes'
            ' (payload ${frame.length - 8} bytes)');
        final parsed = _tryParseTelemetryFromTelemetryFrame(frame);
        if (parsed == null) {
          debugPrint(
              '[ConnectionVM] ⚠️ Telemetry frame parse returned null (too short or wrong code)');
          return;
        }

        bool changed = false;

        if (parsed.batteryVoltage != null &&
            parsed.batteryVoltage != _companionBatteryVoltage) {
          _companionBatteryVoltage = parsed.batteryVoltage;
          debugPrint(
              '[ConnectionVM] 🔋 Companion battery updated: ${parsed.batteryVoltage!.toStringAsFixed(2)}V');
          changed = true;
        }

        if (parsed.gpsFix != null) {
          final fix = parsed.gpsFix!;
          final posChanged = _companionLatitude != fix.latitude ||
              _companionLongitude != fix.longitude ||
              _companionAltitudeMeters != fix.altitudeMeters;
          _companionLatitude = fix.latitude;
          _companionLongitude = fix.longitude;
          _companionAltitudeMeters = fix.altitudeMeters;
          _companionGpsFixTime = parsed.timestamp;
          debugPrint(
              '[ConnectionVM] 📍 Companion GPS fix: ${fix.latitude.toStringAsFixed(6)},'
              ' ${fix.longitude.toStringAsFixed(6)} posChanged=$posChanged');
          // Always notify so the map reacts to refreshed fix time even when
          // the device is stationary.
          changed = true;
        } else {
          debugPrint(
              '[ConnectionVM] 📍 Telemetry contained no valid GPS record.'
              ' hadFix=${_companionLatitude != null || _companionLongitude != null}');
          if (_companionLatitude != null || _companionLongitude != null) {
            // Fix lost (companion sent 0/0 or no GPS record) — clear stored
            // coordinates so hasCompanionGpsFix becomes false and the map falls
            // back to phone GPS immediately.
            _companionLatitude = null;
            _companionLongitude = null;
            _companionAltitudeMeters = null;
            _companionGpsFixTime = null;
            debugPrint(
                '[ConnectionVM] 📍 Companion GPS fix lost — clearing position');
            changed = true;
          }
        }

        if (changed) {
          notifyListeners();
        }
      }

      // Handle RESP_DEVICE_INFO (firmware capabilities from CMD_DEVICE_QUERY)
      if (responseCode == BleConstants.respDeviceInfo) {
        final response = BleResponseParser.parse(frame);
        if (response is DeviceInfoResponse) {
          _deviceInfo = response;
          debugPrint(
              '[ConnectionVM] ✅ Device info received: FW v${response.firmwareVersion}');
          debugPrint(
              '[ConnectionVM]    Capabilities: maxContacts=${response.maxContacts}, maxChannels=${response.maxChannels}');
          // Don't use for device name (that comes from SELF_INFO)
        }
      }

      // Handle RESP_SELF_INFO (device capabilities from CMD_APP_START)
      if (responseCode == BleConstants.respSelfInfo) {
        final response = BleResponseParser.parse(frame);
        if (response is SelfInfoResponse) {
          _deviceCapabilities = response;
          debugPrint('[ConnectionVM] ✅ Device capabilities received');
          debugPrint('   Device Name: ${response.name}');
          debugPrint(
              '   Firmware: ${response.isCustomFirmware ? "Custom" : "Stock"}');
          debugPrint('   Forwarding: ${response.supportsForwarding}');
          debugPrint('   Autonomous: ${response.supportsAutonomous}');

          // Handle companion session tracking (fire and forget - we'll poll for _companionSessionReady)
          _handleCompanionSession(response.publicKey);
        }
      }

      // Handle ERR responses
      if (responseCode == BleConstants.respErr) {
        debugPrint(
            '[ConnectionVM] ⚠️ ERR response received (frame length: ${frame.length})');
        if (frame.length > 1) {
          debugPrint('[ConnectionVM] ⚠️ Error code: ${frame[1]}');
        }
      }

      // Let repositories handle their specific responses
      // (ContactRepository, ChannelRepository, MessageRepository will receive same stream)
    });
  }

  /// Send CMD_DEVICE_QUERY and wait for response
  /// Simplified - frame subscription already active from _setupFrameSubscription()
  Future<void> _sendDeviceQuery() async {
    // Send CMD_DEVICE_QUERY (cmd 22 + app version 3)
    final cmd = BleCommands.buildDeviceQuery();
    await _bleManager.sendFrame(cmd);

    // Wait for RESP_DEVICE_INFO (handled in _setupFrameSubscription)
    final startTime = DateTime.now();
    while (_deviceInfo == null) {
      await Future.delayed(const Duration(milliseconds: 100));

      if (DateTime.now().difference(startTime).inSeconds > 5) {
        debugPrint(
            '[ConnectionVM] ⚠️ Device query timeout - no RESP_DEVICE_INFO received');
        break;
      }
    }
  }

  /// Run FULL sequential sync phases (contacts → channels → messages)
  Future<void> _runFullSyncPhases() async {
    // Phase 1: Contact Sync
    debugPrint('[ConnectionVM] 📋 Phase 1: Syncing contacts...');
    _updateSyncStatus(const SyncStatus(phase: SyncPhase.syncingContacts));

    // Listen to contact sync progress
    _contactProgressSub = _contactRepository.syncProgress.listen((progress) {
      _updateSyncStatus(SyncStatus(
        phase: SyncPhase.syncingContacts,
        currentItem: progress.currentCount,
        totalItems: progress.totalCount,
        isComplete: false,
      ));
    });

    final contactsResult = await _contactRepository.syncContactsComplete();
    _contactProgressSub?.cancel();

    if (!contactsResult.success) {
      debugPrint('[ConnectionVM] ⚠️ Contact sync failed, continuing anyway...');
    } else if (contactsResult.mostRecentLastmod > 0) {
      final companionKey = _settingsService.settings.currentCompanionPublicKey;
      if (companionKey != null && companionKey.isNotEmpty) {
        await _settingsService.setContactLastmod(
            companionKey, contactsResult.mostRecentLastmod);
        debugPrint(
            '[ConnectionVM] 💾 Stored contact lastmod=${contactsResult.mostRecentLastmod}');
      }
    }

    debugPrint('[ConnectionVM] ✅ Phase 1 complete');

    // Phase 2: Channel Sync
    debugPrint('[ConnectionVM] 📺 Phase 2: Syncing channels...');
    _updateSyncStatus(const SyncStatus(phase: SyncPhase.syncingChannels));

    // Listen to channel sync progress
    _channelProgressSub = _channelRepository.syncProgress.listen((progress) {
      _updateSyncStatus(SyncStatus(
        phase: SyncPhase.syncingChannels,
        currentItem: progress.currentCount,
        totalItems: progress.totalCount,
        isComplete: false,
      ));
    });

    final maxChannels = _deviceCapabilities?.isCustomFirmware == true ? 8 : 4;

    // Prefer device-reported maxChannels from DEVICE_INFO; fall back to legacy heuristic.
    final reportedMaxChannels = _deviceInfo?.maxChannels;
    final channelCapacity =
        (reportedMaxChannels != null && reportedMaxChannels > 0)
            ? reportedMaxChannels
            : maxChannels;

    debugPrint('[ConnectionVM] 📺 Channel capacity: $channelCapacity');

    // Inform channel repository so create/import uses correct capacity.
    _channelRepository.updateMaxChannels(channelCapacity);

    final channelsSuccess = await _channelRepository.fetchChannelsFromFirmware(
        maxChannels: channelCapacity);
    _channelProgressSub?.cancel();

    if (!channelsSuccess) {
      debugPrint('[ConnectionVM] ⚠️ Channel sync failed, continuing anyway...');
    }

    debugPrint('[ConnectionVM] ✅ Phase 2 complete');

    // Phase 3: Message Sync (PUSH_MSG_WAITING listener)
    debugPrint('[ConnectionVM] 📨 Phase 3: Checking messages...');
    _updateSyncStatus(const SyncStatus(phase: SyncPhase.syncingMessages));

    // Start listening for PUSH_MSG_WAITING (device will push when messages available)
    _messageRepository.startPushListener();

    // Actively pull any queued messages now (some firmware won’t emit a PUSH immediately).
    final pulled = await _messageRepository.syncMessagesNow();
    debugPrint(
        '[ConnectionVM] ✅ Phase 3 complete: pulled $pulled messages (listener active)');

    // All phases complete
    _updateSyncStatus(
        const SyncStatus(phase: SyncPhase.complete, isComplete: true));
    debugPrint('[ConnectionVM] ✅ All sync phases complete');
  }

  /// Run incremental CONTACT + MESSAGE sync (skip channels).
  ///
  /// Used for reconnects to the same companion. Sends only the delta since
  /// the last sync using the stored `contact_lastmod` timestamp.
  Future<void> _runContactAndMessageSync() async {
    final companionKey = _settingsService.settings.currentCompanionPublicKey;
    final since = (companionKey != null && companionKey.isNotEmpty)
        ? _settingsService.getContactLastmod(companionKey)
        : 0;

    final label = since > 0 ? 'incremental (since=$since)' : 'full';
    debugPrint('[ConnectionVM] 📋 Reconnect: $label contact sync...');
    _updateSyncStatus(const SyncStatus(phase: SyncPhase.syncingContacts));

    _contactProgressSub = _contactRepository.syncProgress.listen((progress) {
      _updateSyncStatus(SyncStatus(
        phase: SyncPhase.syncingContacts,
        currentItem: progress.currentCount,
        totalItems: progress.totalCount,
        isComplete: false,
      ));
    });

    final contactsResult =
        await _contactRepository.syncContactsComplete(since: since);
    _contactProgressSub?.cancel();

    if (!contactsResult.success) {
      debugPrint('[ConnectionVM] ⚠️ Contact sync failed, continuing anyway...');
    } else if (contactsResult.mostRecentLastmod > 0) {
      if (companionKey != null && companionKey.isNotEmpty) {
        await _settingsService.setContactLastmod(
            companionKey, contactsResult.mostRecentLastmod);
        debugPrint(
            '[ConnectionVM] 💾 Stored contact lastmod=${contactsResult.mostRecentLastmod}');
      }
    }

    debugPrint('[ConnectionVM] 📨 Reconnect: checking messages...');
    _updateSyncStatus(const SyncStatus(phase: SyncPhase.syncingMessages));

    _messageRepository.startPushListener();
    final pulled = await _messageRepository.syncMessagesNow();
    debugPrint(
        '[ConnectionVM] ✅ Reconnect sync complete: pulled $pulled messages (channels skipped)');

    _updateSyncStatus(
        const SyncStatus(phase: SyncPhase.complete, isComplete: true));
  }

  Future<void> _finalizeAfterSync() async {
    // Start battery polling now that sync is complete
    _startBatteryPolling();

    // Fetch autonomous settings so UI reflects current firmware state immediately.
    debugPrint('[ConnectionVM] 📡 Fetching autonomous settings...');
    final autonomousState = await getAutonomousSettings();
    if (autonomousState != null) {
      debugPrint(
          '[ConnectionVM] ✅ Autonomous state: enabled=${autonomousState.enabled}');
    } else {
      debugPrint(
          '[ConnectionVM] ⚠️ Autonomous settings not available (stock firmware?)');
    }

    // Start foreground service and save connection state
    final deviceAddress = _bleManager.deviceAddress;
    if (deviceAddress != null && deviceAddress.isNotEmpty) {
      debugPrint('[ConnectionVM] 🌐 Starting foreground service...');
      await _meshConnectionService.startService();
      await _settingsService.setLastConnectedDevice(deviceAddress);
      await _settingsService.setManualDisconnect(false);
      debugPrint('[ConnectionVM] ✅ Foreground service started');
    }
  }

  /// Start battery polling (30 second interval)
  void _startBatteryPolling() {
    _batteryTimer?.cancel();
    debugPrint('[ConnectionVM] 🔋 Starting battery polling (30s interval)...');

    _batteryTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_bleManager.isConnected) {
        _pollBattery();
      }
    });

    // Poll immediately
    _pollBattery();
  }

  /// Poll battery level
  Future<void> _pollBattery() async {
    try {
      debugPrint(
          '[ConnectionVM] 🔋 Requesting companion telemetry (battery)...');
      final cmd = BleCommands.buildSendTelemetryReq();
      await _bleManager.sendFrame(cmd);
    } catch (e) {
      debugPrint('[ConnectionVM] ⚠️ Battery telemetry request failed: $e');
    }
  }

  /// Request a telemetry packet on-demand (used for companion GPS polling).
  Future<void> requestCompanionTelemetry() async {
    if (!_bleManager.isConnected) return;
    try {
      final cmd = BleCommands.buildSendTelemetryReq();
      await _bleManager.sendFrame(cmd);
    } catch (e) {
      debugPrint('[ConnectionVM] ⚠️ Telemetry request failed: $e');
    }
  }

  _ParsedTelemetry? _tryParseTelemetryFromTelemetryFrame(Uint8List frame) {
    // Format (from Android TEAM):
    // [0x8B][reserved][pub_key_prefix 6B][cayenne_lpp_payload N bytes]
    if (frame.length < 8) return null;
    if (frame[0] != BleConstants.pushCodeTelemetryResponse) return null;

    final payload = frame.sublist(8);
    return _tryParseTelemetryFromCayenneLpp(payload);
  }

  _ParsedTelemetry? _tryParseTelemetryFromCayenneLpp(Uint8List payload) {
    // CayenneLPP records: [channel 1B][type 1B][data N]
    // We decode battery voltage + GPS (lat/lon/alt). Unknown types are skipped
    // only when their size is known.
    //
    // LPP_SWITCH (0x8E) is the GPS fix qualifier sent by the companion firmware.
    // It appears after the GPS record in the frame. A value of 1 means the GPS
    // has a valid fix; 0 means no fix. If absent (older firmware), we fall back
    // to the coordinate sanity check (looksValid).

    double? batteryVoltage;
    _GpsFix? gpsFix;
    // null = not present in this frame (old firmware); true/false = fix/no-fix.
    bool? gpsFixSwitch;

    int offset = 0;
    while (offset + 2 <= payload.length) {
      // channel currently unused
      offset += 1;
      if (offset >= payload.length) break;
      final type = payload[offset];
      offset += 1;

      final size = _cayenneLppDataSize(type);
      if (size == null) {
        // Can't safely continue without knowing the size.
        break;
      }
      if (offset + size > payload.length) break;

      if (type == _CayenneLppTypes.analogInput && size == 2) {
        // Signed int16, 0.01V
        final high = payload[offset];
        final low = payload[offset + 1];
        int raw = ((high & 0xFF) << 8) | (low & 0xFF);
        if ((raw & 0x8000) != 0) raw = raw | 0xFFFF0000;
        batteryVoltage = raw / 100.0;
      } else if (type == _CayenneLppTypes.voltage && size == 2) {
        // Unsigned int16, 0.01V
        final high = payload[offset];
        final low = payload[offset + 1];
        final raw = ((high & 0xFF) << 8) | (low & 0xFF);
        batteryVoltage = raw / 100.0;
      } else if (type == _CayenneLppTypes.gps && size == 9) {
        final latRaw = _readInt24(payload, offset);
        final lonRaw = _readInt24(payload, offset + 3);
        final altRaw = _readInt24(payload, offset + 6);

        final lat = latRaw / 10000.0;
        final lon = lonRaw / 10000.0;
        final altMeters = altRaw / 100.0;

        final looksValid = lat >= -90.0 &&
            lat <= 90.0 &&
            lon >= -180.0 &&
            lon <= 180.0 &&
            !(lat.abs() < 0.0001 && lon.abs() < 0.0001);

        debugPrint(
            '[ConnectionVM] 🛰️ GPS record: rawLat=$latRaw rawLon=$lonRaw rawAlt=$altRaw'
            ' → lat=${lat.toStringAsFixed(6)}, lon=${lon.toStringAsFixed(6)}, alt=${altMeters.toStringAsFixed(1)}m'
            ' looksValid=$looksValid');

        if (looksValid) {
          gpsFix = _GpsFix(
            latitude: lat,
            longitude: lon,
            altitudeMeters: altMeters,
          );
        } else {
          debugPrint(
              '[ConnectionVM] ⚠️ GPS record rejected (no fix / 0,0 / out-of-range)');
        }
      } else if (type == _CayenneLppTypes.lppSwitch && size == 1) {
        gpsFixSwitch = payload[offset] != 0;
        debugPrint(
            '[ConnectionVM] 🛰️ GPS fix switch: ${gpsFixSwitch ? 'FIX' : 'NO FIX'}');
      }

      offset += size;
    }

    // Apply the fix switch as the authoritative qualifier when present.
    // • switch = true  → trust the GPS fix (firmware confirmed lock).
    // • switch = false → discard the GPS fix regardless of coordinates.
    // • switch absent  → keep looksValid result (older firmware fallback).
    if (gpsFixSwitch != null && !gpsFixSwitch) {
      if (gpsFix != null) {
        debugPrint(
            '[ConnectionVM] ⚠️ GPS fix discarded — companion reports no fix (switch=0)');
      }
      gpsFix = null;
    }

    if (batteryVoltage == null && gpsFix == null) return null;
    return _ParsedTelemetry(
      batteryVoltage: batteryVoltage,
      gpsFix: gpsFix,
      timestamp: DateTime.now(),
    );
  }

  int? _cayenneLppDataSize(int type) {
    switch (type) {
      case _CayenneLppTypes.digitalInput:
      case _CayenneLppTypes.digitalOutput:
      case _CayenneLppTypes.presence:
      case _CayenneLppTypes.humidity:
      case _CayenneLppTypes.lppSwitch:
        return 1;
      case _CayenneLppTypes.analogInput:
      case _CayenneLppTypes.analogOutput:
      case _CayenneLppTypes.illuminance:
      case _CayenneLppTypes.temperature:
      case _CayenneLppTypes.barometer:
      case _CayenneLppTypes.voltage:
        return 2;
      case _CayenneLppTypes.accelerometer:
      case _CayenneLppTypes.gyrometer:
        return 6;
      case _CayenneLppTypes.gps:
        return 9;
      default:
        return null;
    }
  }

  int _readInt24(Uint8List bytes, int offset) {
    final b0 = bytes[offset] & 0xFF;
    final b1 = bytes[offset + 1] & 0xFF;
    final b2 = bytes[offset + 2] & 0xFF;
    int value = (b0 << 16) | (b1 << 8) | b2;
    // Dart int is 64-bit. Sign-extend from bit 23 by setting all higher bits,
    // not just bits 24-31 as 0xFF000000 would do.
    if ((value & 0x800000) != 0) {
      value |= (-1 << 24);
    }
    return value;
  }

  /// Stop sync and cleanup
  void _stopSync() {
    debugPrint('[ConnectionVM] 🛑 Stopping sync...');

    _contactProgressSub?.cancel();
    _contactProgressSub = null;

    _channelProgressSub?.cancel();
    _channelProgressSub = null;

    _currentFrameSubscription?.cancel();
    _currentFrameSubscription = null;

    _batteryTimer?.cancel();
    _batteryTimer = null;

    _messageRepository.stopPushListener();

    // Ensure we never leave the app locked if the device disconnects.
    _identityConfirmationRequired = false;

    // DON'T stop foreground service here - let service manage its own lifecycle
    // Service will continue if reconnecting, only stops on manual disconnect
    // This matches Android TEAM behavior where service persists through disconnects

    // Clear device state
    _deviceCapabilities = null;
    _deviceInfo = null;
    _batteryLevel = 0;
    _companionBatteryVoltage = null;
    _companionLatitude = null;
    _companionLongitude = null;
    _companionAltitudeMeters = null;
    _companionGpsFixTime = null;
    _currentAutonomousEnabled = null;

    _updateSyncStatus(
        const SyncStatus(phase: SyncPhase.idle, isComplete: false));
  }

  /// Manually disconnect (user-initiated)
  /// Stops foreground service and sets manual disconnect flag
  Future<void> manualDisconnect() async {
    debugPrint('[ConnectionVM] 🔴 Manual disconnect requested');
    await _settingsService.setManualDisconnect(true);
    await _meshConnectionService.stopService();
  }

  /// Update sync status and notify listeners
  void _updateSyncStatus(SyncStatus status) {
    _syncStatus = status;
    notifyListeners();
  }

  /// Handle companion session tracking and switching
  /// Detects when connecting to a different companion device and clears session data
  /// Matches Android ConnectionViewModel companion switch detection
  Future<void> _handleCompanionSession(Uint8List publicKey) async {
    // Convert public key to hex string for storage
    final publicKeyHex =
        publicKey.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

    // Get previous companion key
    final previousCompanionKey =
        _settingsService.settings.currentCompanionPublicKey;

    // Check if this is a companion switch (different device from last time)
    final isCompanionSwitch =
        previousCompanionKey != null && previousCompanionKey != publicKeyHex;

    if (isCompanionSwitch) {
      debugPrint('[ConnectionVM] 🔄 Companion switch detected!');
      debugPrint(
          '[ConnectionVM]    Previous: ${previousCompanionKey.substring(0, 16)}...');
      debugPrint(
          '[ConnectionVM]    Current:  ${publicKeyHex.substring(0, 16)}...');
      debugPrint(
          '[ConnectionVM] 🗑️ Clearing session data for previous companion...');

      // Clear all session data for the previous companion
      _clearCompanionSessionData(previousCompanionKey);

      // Reset sync status so UI shows fresh sync
      _updateSyncStatus(
          const SyncStatus(phase: SyncPhase.idle, isComplete: false));

      _shouldRunFullSyncForThisConnection = true;
      _identityConfirmationRequired = true;
      notifyListeners();
    } else if (previousCompanionKey == null) {
      debugPrint('[ConnectionVM] 🆕 First companion connection');
      debugPrint(
          '[ConnectionVM]    Device: ${publicKeyHex.substring(0, 16)}...');

      _shouldRunFullSyncForThisConnection = true;
      _identityConfirmationRequired = true;
      notifyListeners();
    } else {
      debugPrint('[ConnectionVM] ✅ Reconnected to same companion');
      debugPrint(
          '[ConnectionVM]    Device: ${publicKeyHex.substring(0, 16)}...');

      _shouldRunFullSyncForThisConnection = false;
      _identityConfirmationRequired = false;
      notifyListeners();
    }

    // Update stored companion key (await to ensure it's set before sync starts)
    await _settingsService.setCurrentCompanionPublicKey(publicKeyHex);

    // Update or insert companion device record
    _updateCompanionDeviceRecord(publicKeyHex);

    // Mark companion session as ready
    _companionSessionReady = true;
  }

  /// Clear all session data for a specific companion device
  /// Matches Android ConnectionViewModel.clearCompanionSessionData()
  void _clearCompanionSessionData(String companionKey) {
    debugPrint(
        '[ConnectionVM] 🗑️ Clearing session data for companion: ${companionKey.substring(0, 16)}...');

    try {
      // Delete all contacts for this companion
      _database.contactsDao
          .deleteContactsByCompanion(companionKey)
          .then((count) {
        debugPrint('[ConnectionVM]    ✅ Deleted $count contacts');
      });

      // Delete all channels for this companion
      _database.channelsDao
          .deleteChannelsByCompanion(companionKey)
          .then((count) {
        debugPrint('[ConnectionVM]    ✅ Deleted $count channels');
      });

      // Delete all messages for this companion
      _database.messagesDao
          .deleteMessagesByCompanion(companionKey)
          .then((count) {
        debugPrint('[ConnectionVM]    ✅ Deleted $count messages');
      });

      // Delete all ACK records for this companion
      _database.ackRecordsDao
          .deleteAckRecordsByCompanion(companionKey)
          .then((count) {
        debugPrint('[ConnectionVM]    ✅ Deleted $count ACK records');
      });

      // Note: Waypoints are deliberately preserved (user-created, not companion-specific)
      // Matches Android TEAM behavior where waypoints persist across companion switches

      debugPrint('[ConnectionVM] ✅ Session data cleared successfully');
    } catch (e) {
      debugPrint('[ConnectionVM] ❌ Error clearing session data: $e');
    }
  }

  /// Update or insert companion device record in database
  void _updateCompanionDeviceRecord(String publicKeyHex) {
    if (_deviceCapabilities == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    _database.companionDevicesDao
        .getCompanionDevice(publicKeyHex)
        .then((existing) {
      if (existing != null) {
        // Update existing record
        _database.companionDevicesDao.updateCompanionDevice(
          CompanionDevicesCompanion(
            publicKeyHex: drift.Value(publicKeyHex),
            lastConnected: drift.Value(now),
            connectionCount: drift.Value(existing.connectionCount + 1),
          ),
        );
      } else {
        // Insert new record
        _database.companionDevicesDao.insertCompanionDevice(
          CompanionDevicesCompanion.insert(
            publicKeyHex: publicKeyHex,
            name: _deviceCapabilities!.name,
            firstConnected: now,
            lastConnected: now,
            connectionCount: const drift.Value(1),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _bleManager.removeListener(_onConnectionStateChanged);
    _stopSync();
    super.dispose();
  }
}

class _ParsedTelemetry {
  final double? batteryVoltage;
  final _GpsFix? gpsFix;
  final DateTime timestamp;

  const _ParsedTelemetry({
    required this.batteryVoltage,
    required this.gpsFix,
    required this.timestamp,
  });
}

class _AckResult {
  final bool isSuccess;
  final int? errorCode;
  final bool isTimeout;
  final bool isSendFailed;

  const _AckResult._({
    required this.isSuccess,
    this.errorCode,
    this.isTimeout = false,
    this.isSendFailed = false,
  });

  const _AckResult.ok() : this._(isSuccess: true);
  const _AckResult.timeout() : this._(isSuccess: false, isTimeout: true);
  const _AckResult.sendFailed() : this._(isSuccess: false, isSendFailed: true);
  const _AckResult.err(int? code) : this._(isSuccess: false, errorCode: code);
}

class _GpsFix {
  final double latitude;
  final double longitude;
  final double altitudeMeters;

  const _GpsFix({
    required this.latitude,
    required this.longitude,
    required this.altitudeMeters,
  });
}

class _CayenneLppTypes {
  static const int digitalInput = 0x00;
  static const int digitalOutput = 0x01;
  static const int analogInput = 0x02;
  static const int analogOutput = 0x03;

  static const int illuminance = 0x65;
  static const int presence = 0x66;
  static const int temperature = 0x67;
  static const int humidity = 0x68;

  static const int accelerometer = 0x71;
  static const int barometer = 0x73;

  // Non-standard in classic Cayenne LPP, but used by Android TEAM implementation.
  static const int voltage = 0x74;

  static const int gyrometer = 0x86;
  static const int gps = 0x88;

  // Extended CayenneLPP (ElectronicCats library, LPP_SWITCH = 142).
  static const int lppSwitch = 0x8E; // 1 byte, 0/1
}
