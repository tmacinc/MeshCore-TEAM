// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:meshcore_team/ble/ble_commands.dart';
import 'package:meshcore_team/ble/ble_connection_manager.dart';
import 'package:meshcore_team/ble/ble_constants.dart';
import 'package:meshcore_team/ble/ble_responses.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/database/daos/contacts_dao.dart';
import 'package:meshcore_team/models/sync_status.dart';
import 'package:meshcore_team/models/unread_models.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/utils/sync_trace.dart';
import 'package:drift/drift.dart' as drift;

/// Result returned by [ContactRepository.syncContactsComplete].
class ContactSyncResult {
  final bool success;

  /// Most-recent `lastmod` timestamp (seconds) from the firmware's
  /// END_OF_CONTACTS frame. Store this and pass it as `since` on the next
  /// incremental sync. 0 means the firmware did not return a value.
  final int mostRecentLastmod;

  const ContactSyncResult({
    required this.success,
    required this.mostRecentLastmod,
  });
}

/// Contact Repository
/// Manages contact sync and database operations
/// Matches Android ContactRepository.kt implementation
class ContactRepository {
  static const String _syncTraceTag = '[SYNCTRACE][CONTACT]';

  final BleConnectionManager _bleManager;
  final ContactsDao _contactsDao;
  final SettingsService _settingsService;

  Future<ContactSyncResult>? _activeSync;

  // Sync progress tracking
  final StreamController<ContactSyncProgress> _syncProgressController =
      StreamController<ContactSyncProgress>.broadcast();
  Stream<ContactSyncProgress> get syncProgress =>
      _syncProgressController.stream;

  ContactSyncProgress _currentProgress = const ContactSyncProgress();

  // Frame subscriptions
  StreamSubscription<Uint8List>? _frameSubscription;

  ContactRepository({
    required BleConnectionManager bleManager,
    required ContactsDao contactsDao,
    required SettingsService settingsService,
  })  : _bleManager = bleManager,
        _contactsDao = contactsDao,
        _settingsService = settingsService;

  /// Request contact list and wait for completion.
  ///
  /// [since]: Unix timestamp (seconds). When > 0 the firmware streams only
  /// contacts modified after that timestamp (incremental sync). Pass 0 for a
  /// full sync.
  ///
  /// Returns a [ContactSyncResult] with success flag and the most-recent
  /// `lastmod` returned by the firmware (use it as `since` next time).
  Future<ContactSyncResult> syncContactsComplete({int since = 0}) async {
    // Coalesce concurrent sync requests (e.g. PUSH_ADVERT + UI sync button).
    final existing = _activeSync;
    if (existing != null) {
      debugPrint('[ContactSync] 🔁 Sync already in progress - joining');
      return existing;
    }

    final future = _syncContactsCompleteInternal(since: since);
    _activeSync = future;

    try {
      return await future;
    } finally {
      if (identical(_activeSync, future)) {
        _activeSync = null;
      }
    }
  }

  Future<ContactSyncResult> _syncContactsCompleteInternal(
      {required int since}) async {
    final label = since > 0 ? 'incremental (since=$since)' : 'full';
    debugPrint('[ContactSync] 🔄 Starting $label contact sync...');
    syncTrace('$_syncTraceTag begin mode=$label since=$since');

    // Reset progress tracking
    _updateProgress(const ContactSyncProgress(
        currentCount: 0, totalCount: 0, isComplete: false));

    // Send CMD_GET_CONTACTS (with optional since filter)
    final frame = BleCommands.buildGetContacts(since: since);
    final success = await _bleManager.sendFrame(frame);
    if (!success) {
      debugPrint('[ContactSync] ❌ Failed to send CMD_GET_CONTACTS');
      syncTrace('$_syncTraceTag send_failed cmd=GET_CONTACTS since=$since');
      _updateProgress(const ContactSyncProgress(isComplete: true));
      return const ContactSyncResult(success: false, mostRecentLastmod: 0);
    }

    debugPrint('[ContactSync] CMD_GET_CONTACTS sent, collecting responses...');
    syncTrace('$_syncTraceTag cmd_sent cmd=GET_CONTACTS since=$since');

    try {
      return await _collectContacts(
        maxTotalTimeMs: 30000,
        noResponseTimeoutMs: 5000,
      );
    } catch (e) {
      debugPrint('[ContactSync] ❌ Contact sync failed: $e');
      syncTrace('$_syncTraceTag collect_failed error=$e');
      _updateProgress(const ContactSyncProgress(isComplete: true));
      return const ContactSyncResult(success: false, mostRecentLastmod: 0);
    }
  }

  /// Collect contacts from BLE stream
  ///
  /// Phase 1 (BLE receive): buffer all incoming ContactResponse objects in
  /// memory — no DB I/O so the BLE stream gets full priority.
  /// Phase 2 (DB write): build ContactsCompanion rows and write them all in a
  /// single transaction so SQLite commits once instead of N times.
  Future<ContactSyncResult> _collectContacts({
    required int maxTotalTimeMs,
    required int noResponseTimeoutMs,
  }) async {
    const countReachedGraceTimeoutMs = 1500;
    final syncStopwatch = Stopwatch()..start();
    final responseStopwatch = Stopwatch()..start();

    int contactCount = 0;
    // Total expected, parsed from CONTACTS_START frame. 0 = unknown (old firmware).
    int expectedTotal = 0;
    // Absolute deadline — extended once we know the true total.
    int effectiveMaxTotalMs = maxTotalTimeMs;
    bool endOfContactsReceived = false;
    bool contactsStartReceived = false;
    int mostRecentLastmod = 0;
    String completionReason = 'pending';

    final Completer<bool> completer = Completer<bool>();

    // Buffer received contacts — DB writes happen after the stream closes.
    final receivedContacts = <ContactResponse>[];

    // Subscribe to incoming frames
    _frameSubscription = _bleManager.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;

      final responseCode = frame[0];
      responseStopwatch
        ..reset()
        ..start();

      // Check for control codes
      if (responseCode == BleConstants.respContactsStart) {
        contactsStartReceived = true;
        // Firmware sends the total contact count as a little-endian uint32
        // in bytes [1..4] of the CONTACTS_START frame.
        if (frame.length >= 5) {
          expectedTotal =
              frame[1] | (frame[2] << 8) | (frame[3] << 16) | (frame[4] << 24);
          // Allow 200 ms per contact; clamp between 30 s and 120 s.
          effectiveMaxTotalMs = (expectedTotal * 200).clamp(30000, 120000);
          debugPrint(
              '[ContactSync] CONTACTS_START: expecting $expectedTotal contacts, '
              'timeout set to ${effectiveMaxTotalMs}ms');
          syncTrace(
              '$_syncTraceTag contacts_start expected=$expectedTotal timeoutMs=$effectiveMaxTotalMs');
          _updateProgress(ContactSyncProgress(
            currentCount: 0,
            totalCount: expectedTotal,
            isComplete: false,
          ));
        } else {
          debugPrint('[ContactSync] CONTACTS_START signal received (no count)');
          syncTrace('$_syncTraceTag contacts_start expected=unknown');
        }
        return;
      }

      if (responseCode == BleConstants.respEndOfContacts) {
        debugPrint('[ContactSync] ✅ END_OF_CONTACTS signal received');
        syncTrace(
            '$_syncTraceTag end_of_contacts receivedCount=$contactCount expected=${expectedTotal > 0 ? expectedTotal : 'unknown'}');
        endOfContactsReceived = true;
        if (!completer.isCompleted) {
          completionReason = 'end_of_contacts';
          completer.complete(true);
        }
        return;
      }

      // Buffer contact responses — no DB work here.
      if (responseCode == BleConstants.respContact) {
        final response = BleResponseParser.parse(frame);
        if (response is ContactResponse) {
          receivedContacts.add(response);
          contactCount++;

          // Track the highest lastmod across all received contacts.
          // This avoids depending on END_OF_CONTACTS which may arrive after
          // we've already completed on count match.
          if (response.lastmod > mostRecentLastmod) {
            mostRecentLastmod = response.lastmod;
          }

          final publicKeyPrefix = response.publicKey
              .take(6)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();

          // Update progress — show accurate total when known.
          _updateProgress(ContactSyncProgress(
            currentCount: contactCount,
            totalCount: expectedTotal > 0 ? expectedTotal : contactCount,
            isComplete: false,
          ));

          syncTrace(
              '$_syncTraceTag contact_received index=$contactCount expected=${expectedTotal > 0 ? expectedTotal : 'unknown'} '
              'name="${response.name}" keyPrefix=$publicKeyPrefix lastmod=${response.lastmod} '
              'endSeen=$endOfContactsReceived');

          if (expectedTotal > 0 && contactCount > expectedTotal) {
            syncTrace(
                '$_syncTraceTag overrun index=$contactCount expected=$expectedTotal name="${response.name}" keyPrefix=$publicKeyPrefix');
          }

          // Reaching the advertised count is not authoritative enough to end
          // the phase immediately. Some firmware/build combinations deliver
          // END_OF_CONTACTS slightly later, and moving on early lets channel
          // sync start while the radio is still flushing contact frames.
          if (expectedTotal > 0 &&
              contactCount >= expectedTotal &&
              !completer.isCompleted) {
            debugPrint(
                '[ContactSync] ✅ All $expectedTotal expected contacts received');
            syncTrace(
                '$_syncTraceTag expected_count_reached index=$contactCount expected=$expectedTotal endSeen=$endOfContactsReceived');
          }
        }
      }
    });

    // Monitor for timeouts
    Timer? timeoutTimer;
    timeoutTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final totalElapsed = syncStopwatch.elapsedMilliseconds;
      final timeSinceLastResponse = responseStopwatch.elapsedMilliseconds;

      // Absolute timeout
      if (totalElapsed > effectiveMaxTotalMs) {
        debugPrint('[ContactSync] ⏱️ Absolute timeout after ${totalElapsed}ms '
            '($contactCount/${expectedTotal > 0 ? expectedTotal : "?"} contacts)');
        syncTrace(
            '$_syncTraceTag timeout_absolute elapsedMs=$totalElapsed received=$contactCount expected=${expectedTotal > 0 ? expectedTotal : 'unknown'} '
            'contactsStart=$contactsStartReceived endSeen=$endOfContactsReceived');
        timer.cancel();
        if (!completer.isCompleted) {
          completionReason = 'absolute_timeout';
          completer.complete(contactCount > 0);
        }
        return;
      }

      // Once we have received the advertised count, wait briefly for the
      // END_OF_CONTACTS marker. If it never arrives, assume the stream is done
      // after a short quiet period instead of holding the UI for the full
      // absolute timeout.
      if (expectedTotal > 0 &&
          contactCount >= expectedTotal &&
          timeSinceLastResponse > countReachedGraceTimeoutMs) {
        syncTrace(
            '$_syncTraceTag timeout_count_grace quietMs=$timeSinceLastResponse received=$contactCount expected=$expectedTotal endSeen=$endOfContactsReceived');
        timer.cancel();
        if (!completer.isCompleted) {
          completionReason = 'count_reached_grace_timeout';
          completer.complete(true);
        }
        return;
      }

      // No-response timeout: only use as a fallback when the total is unknown
      // (e.g. very old firmware that omits the count in CONTACTS_START).
      if (expectedTotal == 0 &&
          contactCount > 0 &&
          timeSinceLastResponse > noResponseTimeoutMs) {
        debugPrint(
            '[ContactSync] ⏱️ No new contacts for ${timeSinceLastResponse}ms, '
            'assuming complete (unknown total)');
        syncTrace(
            '$_syncTraceTag timeout_quiet quietMs=$timeSinceLastResponse received=$contactCount expected=unknown');
        timer.cancel();
        if (!completer.isCompleted) {
          completionReason = 'quiet_timeout';
          completer.complete(true);
        }
        return;
      }

      // End of contacts signal received
      if (endOfContactsReceived) {
        timer.cancel();
      }
    });

    // Phase 1 complete — wait for BLE stream to finish.
    final success = await completer.future;

    // Cleanup BLE subscription before touching the DB.
    timeoutTimer?.cancel();
    final frameSubscription = _frameSubscription;
    if (frameSubscription != null) {
      await frameSubscription.cancel();
    }
    _frameSubscription = null;

    final receiveTime = syncStopwatch.elapsedMilliseconds;
    debugPrint(
        '[ContactSync] 📥 Received $contactCount contacts in ${receiveTime}ms — writing to DB...');
    syncTrace(
        '$_syncTraceTag receive_complete reason=$completionReason received=$contactCount expected=${expectedTotal > 0 ? expectedTotal : 'unknown'} '
        'contactsStart=$contactsStartReceived endSeen=$endOfContactsReceived receiveMs=$receiveTime mostRecentLastmod=$mostRecentLastmod');

    // Phase 2: bulk-write all buffered contacts in a single transaction.
    if (receivedContacts.isNotEmpty) {
      try {
        final companionKey =
            _settingsService.settings.currentCompanionPublicKey;
        if (companionKey == null || companionKey.isEmpty) {
          debugPrint(
              '[ContactSync] ⚠️ WARNING: Companion key not set! Contacts will not be tagged properly.');
        }

        final rows = receivedContacts.map((response) {
          return ContactsCompanion.insert(
            publicKey: response.publicKey,
            hash: _calculateHash(response.publicKey),
            name: drift.Value(response.name),
            latitude: drift.Value(response.latitude),
            longitude: drift.Value(response.longitude),
            lastSeen: response.lastSeen * 1000,
            isRepeater: drift.Value(response.isRepeater),
            isRoomServer: drift.Value(response.isRoomServer),
            isDirect: drift.Value(response.isDirect),
            hopCount: drift.Value(response.hopCount),
            companionDeviceKey: drift.Value(companionKey),
          );
        }).toList();

        await _contactsDao.bulkUpsertContacts(rows);
      } catch (e) {
        debugPrint('[ContactSync] ⚠️ Bulk DB write failed: $e');
      }
    }

    final totalTime = syncStopwatch.elapsedMilliseconds;
    debugPrint(
        '[ContactSync] ✅ Contact sync complete: $contactCount contacts in ${totalTime}ms');
    syncTrace(
        '$_syncTraceTag sync_complete success=$success received=$contactCount expected=${expectedTotal > 0 ? expectedTotal : 'unknown'} '
        'reason=$completionReason totalMs=$totalTime endSeen=$endOfContactsReceived');

    // Mark sync as complete
    _updateProgress(ContactSyncProgress(
      currentCount: contactCount,
      totalCount: contactCount,
      isComplete: true,
    ));

    return ContactSyncResult(
      success: success,
      mostRecentLastmod: mostRecentLastmod,
    );
  }

  /// Update sync progress and notify listeners
  void _updateProgress(ContactSyncProgress progress) {
    _currentProgress = progress;
    if (!_syncProgressController.isClosed) {
      _syncProgressController.add(progress);
    }
  }

  /// Calculate hash from public key (uses all bytes to reduce collisions)
  int _calculateHash(Uint8List publicKey) {
    if (publicKey.isEmpty) return 0;

    // Use a simple hash of all bytes instead of just first byte
    // This significantly reduces collisions compared to single-byte hash
    int hash = 0;
    for (int i = 0; i < publicKey.length; i++) {
      hash = (hash * 31 + publicKey[i]) & 0xFFFFFFFF; // Keep as 32-bit int
    }
    return hash;
  }

  /// Convert bytes to hex string
  String _bytesToHex(Uint8List bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Get all contacts for the current companion device
  /// Auto-switches when currentCompanionPublicKey changes
  /// Matches Android ContactRepository.getAllContacts()
  Stream<List<ContactData>> getAllContacts() {
    return _settingsService.currentCompanionPublicKeyStream
        .switchMap((companionKey) {
      if (companionKey != null && companionKey.isNotEmpty) {
        return _contactsDao.watchContactsByCompanion(companionKey);
      } else {
        return Stream.value([]);
      }
    });
  }

  /// Watch contacts with unread counts, filtered by current companion
  /// Auto-switches when currentCompanionPublicKey changes
  /// Returns contacts for the currently connected companion device only
  /// Uses rxdart's switchMap (equivalent to Android's flatMapLatest)
  Stream<List<ContactWithUnread>> watchContactsWithUnread() {
    return _settingsService.currentCompanionPublicKeyStream
        .switchMap((companionKey) {
      if (companionKey != null && companionKey.isNotEmpty) {
        return _contactsDao.watchContactsWithUnreadByCompanion(companionKey);
      } else {
        return Stream<List<ContactWithUnread>>.value([]);
      }
    });
  }

  /// Dispose resources
  void dispose() {
    _frameSubscription?.cancel();
    _syncProgressController.close();
  }
}
