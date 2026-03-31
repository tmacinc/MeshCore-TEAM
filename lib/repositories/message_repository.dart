// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:meshcore_team/ble/ble_commands.dart';
import 'package:meshcore_team/ble/ble_connection_manager.dart';
import 'package:meshcore_team/ble/ble_constants.dart';
import 'package:meshcore_team/ble/ble_responses.dart';
import 'package:meshcore_team/ble/ble_service.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/database/daos/messages_dao.dart';
import 'package:meshcore_team/database/daos/channels_dao.dart';
import 'package:meshcore_team/database/daos/contacts_dao.dart';
import 'package:meshcore_team/repositories/contact_repository.dart';
import 'package:meshcore_team/services/message_notification_service.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/models/capability_message.dart';
import 'package:meshcore_team/models/telemetry_message.dart';
import 'package:meshcore_team/models/waypoint.dart' as waypoint_model;
import 'package:meshcore_team/models/waypoint_mesh_message.dart';
import 'package:meshcore_team/models/route_payload.dart';
import 'package:meshcore_team/services/contact_capability_service.dart';
import 'package:meshcore_team/models/telemetry_event.dart';
import 'package:meshcore_team/models/topology_event.dart';
import 'package:meshcore_team/models/topology_message.dart';
import 'package:meshcore_team/models/network_topology.dart';
import 'package:meshcore_team/services/neighbor_tracker.dart';
import 'package:drift/drift.dart' as drift;

/// Message Repository
/// Handles message sync, sending, and database operations
/// Matches Android MessageRepository.kt implementation
///
/// MeshCore limits channel messages to 172 bytes at the BLE frame level,
/// but the firmware adds routing/encryption overhead that reduces the
/// effective text payload. Empirically the receiver truncates around 148
/// characters, so we use 140 as a safe ceiling.
class MessageRepository {
  static const int maxMeshMessageBytes = 140;

  final BleConnectionManager _bleManager;
  final BleService _bleService;
  final AppDatabase _database;
  final MessagesDao _messagesDao;
  final ChannelsDao _channelsDao;
  final ContactsDao _contactsDao;
  final ContactRepository _contactRepository;
  final MessageNotificationService _notificationService;
  final SettingsService _settingsService;
  final ContactCapabilityService _capabilityService;
  final NetworkTopology _networkTopology;
  final NeighborTracker _neighborTracker;
  final Uuid _uuid = const Uuid();

  // Frame subscriptions
  StreamSubscription<Uint8List>? _frameSubscription;

  // Push notification tracking
  bool _isListeningForPushes = false;

  // Prevent concurrent message sync loops
  bool _isSyncingMessages = false;

  // Coalesce push-triggered sync requests.
  Timer? _syncDebounceTimer;
  bool _syncRequestedWhileSyncing = false;

  // Waypoint de-dupe guard: the same #WAY message may be delivered via PUSH and
  // then again via sync. Also protects against concurrent handling races.
  static const Duration _recentWaypointTtl = Duration(seconds: 10);
  final Map<String, int> _recentWaypointKeysMs = <String, int>{};

  // Multi-part waypoint route reassembly buffer.
  // Key: "senderName:meshId", Value: map of partNum -> routeChunk.
  final Map<String, _WaypointPartBuffer> _waypointPartBuffers =
      <String, _WaypointPartBuffer>{};

  // Telemetry de-dupe guard: #TEL messages may also be delivered via PUSH and
  // then again via sync. Duplicates are mostly harmless but can cause extra
  // work/log spam.
  static const Duration _recentTelemetryTtl = Duration(seconds: 5);
  final Map<String, int> _recentTelemetryKeysMs = <String, int>{};

  // Broadcast stream of parsed #TEL events.
  final StreamController<TelemetryEvent> _telemetryStreamController =
      StreamController<TelemetryEvent>.broadcast();

  /// Stream of parsed #TEL events.
  Stream<TelemetryEvent> get telemetryStream =>
      _telemetryStreamController.stream;

  // Broadcast stream of parsed #T: topology events.
  final StreamController<TopologyEvent> _topologyStreamController =
      StreamController<TopologyEvent>.broadcast();

  /// Stream of parsed #T: topology events. Each emission corresponds to one
  /// successfully parsed topology channel message after de-duplication.
  Stream<TopologyEvent> get topologyStream => _topologyStreamController.stream;

  MessageRepository({
    required BleConnectionManager bleManager,
    required BleService bleService,
    required AppDatabase database,
    required MessagesDao messagesDao,
    required ChannelsDao channelsDao,
    required ContactsDao contactsDao,
    required ContactRepository contactRepository,
    required MessageNotificationService notificationService,
    required SettingsService settingsService,
    required ContactCapabilityService capabilityService,
    NetworkTopology? networkTopology,
    NeighborTracker? neighborTracker,
  })  : _networkTopology = networkTopology ?? NetworkTopology(),
        _neighborTracker = neighborTracker ?? NeighborTracker(),
        _bleManager = bleManager,
        _bleService = bleService,
        _database = database,
        _messagesDao = messagesDao,
        _channelsDao = channelsDao,
        _contactsDao = contactsDao,
        _contactRepository = contactRepository,
        _notificationService = notificationService,
        _settingsService = settingsService,
        _capabilityService = capabilityService;

  // Expose messagesDao for backward compatibility
  // TODO: Remove this after migrating all screens to use repository methods
  MessagesDao get messagesDao => _messagesDao;

  /// Watch messages for a channel, automatically filtered by current companion
  /// Auto-switches when currentCompanionPublicKey changes
  /// Matches Android MessageRepository.getMessagesByChannel()
  Stream<List<MessageData>> watchMessagesByChannel(int channelHash) {
    return _settingsService.currentCompanionPublicKeyStream
        .switchMap((companionKey) {
      if (companionKey != null && companionKey.isNotEmpty) {
        return _messagesDao.watchMessagesByChannelForCompanion(
            channelHash, companionKey);
      } else {
        // No companion selected - return empty list
        return Stream.value([]);
      }
    });
  }

  /// Watch private messages for a contact, automatically filtered by current companion
  /// Auto-switches when currentCompanionPublicKey changes
  /// Matches Android MessageRepository.getAllMessages() for DMs
  Stream<List<MessageData>> watchPrivateMessages(int contactHash) {
    return _settingsService.currentCompanionPublicKeyStream
        .switchMap((companionKey) {
      if (companionKey != null && companionKey.isNotEmpty) {
        return _messagesDao.watchPrivateMessagesForCompanion(
            contactHash, companionKey);
      } else {
        // No companion selected - return empty list
        return Stream.value([]);
      }
    });
  }

  /// Start listening for PUSH_MSG_WAITING (0x83) notifications
  /// When received, automatically triggers SYNC_NEXT_MESSAGE loop
  ///
  /// Matches Android implementation:
  /// - Device proactively sends PUSH_MSG_WAITING when new messages available
  /// - App responds with SYNC_NEXT_MESSAGE to retrieve each message
  /// - Continues until RESP_NO_MORE_MESSAGES received
  /// - Direct messages (code 16) are also pushed directly
  void startPushListener() {
    if (_isListeningForPushes) {
      debugPrint('[MessageSync] Already listening for push notifications');
      return;
    }

    debugPrint('[MessageSync] 🔔 Starting PUSH_MSG_WAITING listener...');
    _isListeningForPushes = true;

    _frameSubscription = _bleManager.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;

      final responseCode = frame[0];

      // Check for PUSH_MSG_WAITING (0x83) - channel messages
      if (responseCode == BleConstants.pushCodeMsgWaiting) {
        debugPrint(
            '[MessageSync] 🔔 PUSH_MSG_WAITING received - new messages available');
        _requestMessageSync(delay: Duration.zero, reason: 'PUSH_MSG_WAITING');
      }

      // Check for PUSH_LOG_RX_DATA (0x88) - LoRa packet received
      // Trigger sync to retrieve queued messages (direct messages may not send PUSH_MSG_WAITING)
      if (responseCode == BleConstants.pushCodeLogRxData) {
        debugPrint(
            '[MessageSync] 📡 PUSH_LOG_RX_DATA received - triggering message sync');
        // Small delay to let firmware queue the message
        _requestMessageSync(
            delay: const Duration(milliseconds: 100),
            reason: 'PUSH_LOG_RX_DATA');
      }

      // Check for PUSH_ADVERT (0x80) - contact advertisement received
      // Team parity:
      // - When an advert is received, do a complete contact sync
      // - If the sync increases contact count, send a reciprocal advert so the
      //   new peer can also add us.
      if (responseCode == BleConstants.pushCodeAdvert) {
        debugPrint('[🔍DISC] 📢 PUSH_ADVERT received - syncing contacts...');

        unawaited(() async {
          // Small delay to let firmware process the advert before we poll.
          await Future<void>.delayed(const Duration(milliseconds: 100));

          final companionKey =
              _settingsService.settings.currentCompanionPublicKey;
          final countBefore = (companionKey == null || companionKey.isEmpty)
              ? (await _contactsDao.getAllContacts()).length
              : (await _contactsDao.getContactsByCompanion(companionKey))
                  .length;

          final result = await _contactRepository.syncContactsComplete();

          if (!result.success) {
            debugPrint('[🔍DISC] ❌ Contact sync failed or timed out');
            return;
          }

          final countAfter = (companionKey == null || companionKey.isEmpty)
              ? (await _contactsDao.getAllContacts()).length
              : (await _contactsDao.getContactsByCompanion(companionKey))
                  .length;

          if (countAfter > countBefore) {
            debugPrint(
                '[🔍DISC] 📤 New contact detected ($countBefore → $countAfter) - sending reciprocal advert');
            await _bleService.sendSelfAdvert();
          } else {
            debugPrint('[🔍DISC] ✓ Existing contact - no reciprocal needed');
          }
        }());
      }

      // Check for PUSH_NEW_ADVERT (0x8A) - new advertisement notification.
      // Team parity: do a delayed contact sync (non-blocking).
      if (responseCode == BleConstants.pushCodeNewAdvert) {
        debugPrint(
            '[🔍DISC] 📣 PUSH_NEW_ADVERT received - syncing contacts...');
        unawaited(() async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await _contactRepository.syncContactsComplete();
        }());
      }

      // Check for PUSH_SEND_CONFIRMED (0x82) - message ACK received
      if (responseCode == BleConstants.pushCodeSendConfirmed) {
        debugPrint('[MessageSync] ✅ PUSH_SEND_CONFIRMED received');
        final response = BleResponseParser.parse(frame);
        if (response is SendConfirmedPush) {
          _handleSendConfirmed(response);
        }
      }

      // Check for direct messages pushed directly (code 16)
      if (responseCode == BleConstants.respContactMsgRecvV3) {
        debugPrint('[MessageSync] 📩 Direct message received (pushed)');
        final response = BleResponseParser.parse(frame);
        if (response is ContactMessageReceivedResponse) {
          _handleContactMessage(response);
        }
      }

      // Check for channel messages pushed directly (code 17)
      if (responseCode == BleConstants.respChannelMsgRecvV3) {
        debugPrint('[MessageSync] 📩 Channel message received (pushed)');
        final response = BleResponseParser.parse(frame);
        if (response is ChannelMessageReceivedResponse) {
          _handleChannelMessage(response);
        }
      }
    });
  }

  /// Actively pull any queued messages from firmware right now.
  /// Safe to call even if the push listener is already running.
  Future<int> syncMessagesNow() async {
    if (_isSyncingMessages) {
      debugPrint('[MessageSync] Message sync already in progress - skipping');
      return 0;
    }

    _isSyncingMessages = true;
    try {
      return await _syncMessagesInternal();
    } finally {
      _isSyncingMessages = false;
    }
  }

  /// Stop listening for push notifications
  void stopPushListener() {
    debugPrint('[MessageSync] 🛑 Stopping PUSH_MSG_WAITING listener');
    _isListeningForPushes = false;
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = null;
    _syncRequestedWhileSyncing = false;
    _frameSubscription?.cancel();
    _frameSubscription = null;
  }

  void _requestMessageSync({required Duration delay, required String reason}) {
    // Coalesce multiple push triggers into a single sync run.
    if (_isSyncingMessages) {
      _syncRequestedWhileSyncing = true;
      return;
    }

    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(delay, () {
      _syncDebounceTimer = null;
      unawaited(_runSyncWithTail(reason: reason));
    });
  }

  Future<void> _runSyncWithTail({required String reason}) async {
    await syncMessagesNow();

    // If pushes arrived while syncing, run one more pass to avoid missing
    // messages queued mid-sync.
    if (_syncRequestedWhileSyncing) {
      _syncRequestedWhileSyncing = false;
      _requestMessageSync(delay: Duration.zero, reason: 'TAIL($reason)');
    }
  }

  /// Sync messages from firmware
  /// Loops SYNC_NEXT_MESSAGE until RESP_NO_MORE_MESSAGES
  Future<int> _syncMessagesInternal() async {
    debugPrint('[MessageSync] 🔄 Syncing messages from firmware...');

    int messageCount = 0;
    bool hasMoreMessages = true;

    while (hasMoreMessages) {
      // Send SYNC_NEXT_MESSAGE
      final cmd = BleCommands.buildSyncNextMessage();
      final success = await _bleManager.sendFrame(cmd);

      if (!success) {
        debugPrint('[MessageSync] ❌ Failed to send SYNC_NEXT_MESSAGE');
        break;
      }

      // Wait for response (timeout 2 seconds)
      final response = await _waitForMessageResponse(timeoutMs: 2000);

      if (response == null) {
        // Either timeout or RESP_NO_MORE_MESSAGES (parser returns null for "no more").
        debugPrint('[MessageSync] ✅ No more messages (or timeout)');
        break;
      }

      if (response is ContactMessageReceivedResponse) {
        _handleContactMessage(response);
        messageCount++;
      } else if (response is ChannelMessageReceivedResponse) {
        _handleChannelMessage(response);
        messageCount++;
      } else {
        // RESP_NO_MORE_MESSAGES or unknown response
        debugPrint('[MessageSync] ✅ No more messages');
        hasMoreMessages = false;
      }

      // Small delay between requests
      await Future.delayed(const Duration(milliseconds: 100));
    }

    debugPrint(
        '[MessageSync] ✅ Message sync complete: $messageCount messages retrieved');

    return messageCount;
  }

  /// Wait for message response
  /// Wait for RESP_CODE_SENT response
  Future<MessageSentResponse?> _waitForSentResponse(
      {required int timeoutMs}) async {
    final completer = Completer<MessageSentResponse?>();

    StreamSubscription<Uint8List>? sub;
    sub = _bleManager.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;

      final responseCode = frame[0];

      if (responseCode == BleConstants.respSent) {
        final response = BleResponseParser.parse(frame);
        if (response is MessageSentResponse && !completer.isCompleted) {
          completer.complete(response);
          sub?.cancel();
        }
        return;
      }
    });

    // Timeout
    Future.delayed(Duration(milliseconds: timeoutMs), () {
      if (!completer.isCompleted) {
        completer.complete(null);
        sub?.cancel();
      }
    });

    return completer.future;
  }

  Future<BleResponse?> _waitForMessageResponse({required int timeoutMs}) async {
    final completer = Completer<BleResponse?>();

    StreamSubscription<Uint8List>? sub;
    sub = _bleManager.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;

      final responseCode = frame[0];

      // Contact message (DM)
      if (responseCode == BleConstants.respContactMsgRecvV3) {
        final response = BleResponseParser.parse(frame);
        if (!completer.isCompleted) {
          completer.complete(response);
        }
        sub?.cancel();
        return;
      }

      // Channel message
      if (responseCode == BleConstants.respChannelMsgRecvV3) {
        final response = BleResponseParser.parse(frame);
        if (!completer.isCompleted) {
          completer.complete(response);
        }
        sub?.cancel();
        return;
      }

      // No more messages
      if (responseCode == BleConstants.respNoMoreMessages) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        sub?.cancel();
        return;
      }
    });

    // Timeout
    Timer(Duration(milliseconds: timeoutMs), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      sub?.cancel();
    });

    return completer.future;
  }

  /// Handle PUSH_SEND_CONFIRMED (ACK) response
  /// Matches ACK checksum against sent messages and updates delivery status
  void _handleSendConfirmed(SendConfirmedPush ack) async {
    try {
      final ackHashHex = _bytesToHex(ack.ackChecksum);
      debugPrint(
          '[MessageSync] 🎯 Processing ACK: checksum=$ackHashHex, RTT=${ack.roundTripTimeMs}ms');

      // Find message with matching checksum
      final matchingMessage =
          await _messagesDao.getMessageByAckChecksum(ack.ackChecksum);

      if (matchingMessage != null) {
        debugPrint(
            '[MessageSync] ✅ ACK matched message: ${matchingMessage.id.substring(0, 8)}...');
        debugPrint(
            '[MessageSync]    Content: \'${matchingMessage.content.substring(0, matchingMessage.content.length > 30 ? 30 : matchingMessage.content.length)}...\'');
        debugPrint(
            '[MessageSync]    Current status: ${matchingMessage.deliveryStatus}');
        debugPrint(
            '[MessageSync]    Heard by: ${matchingMessage.heardByCount} devices');

        // Increment heard-by count
        final newCount = matchingMessage.heardByCount + 1;
        await _messagesDao.incrementHeardByCount(matchingMessage.id);

        // Update status to DELIVERED if still SENT
        if (matchingMessage.deliveryStatus != 'DELIVERED') {
          await _messagesDao.updateDeliveryStatus(
              matchingMessage.id, 'DELIVERED');
        }

        debugPrint(
            '[MessageSync] ✅ Message delivery confirmed: $newCount device(s) heard it');
      } else {
        debugPrint(
            '[MessageSync] ⚠️ No matching message found for ACK checksum: $ackHashHex');
      }
    } catch (e) {
      debugPrint('[MessageSync] ⚠️ Error handling ACK: $e');
    }
  }

  /// Handle received contact message (DM)
  void _handleContactMessage(ContactMessageReceivedResponse response) async {
    try {
      final companionKey = _settingsService.settings.currentCompanionPublicKey;

      const prefixLength = 6;
      final senderKey = response.senderPublicKey;

      // CONTACT_MSG_RECV_V3 only includes a 6-byte sender public-key prefix.
      // Our parser pads it to 32 bytes with zeros; exact matching will fail.
      final isPrefixOnly = senderKey.length >= prefixLength &&
          senderKey.sublist(prefixLength).every((b) => b == 0);

      final contact = isPrefixOnly
          ? await _contactsDao.getContactByPublicKeyPrefix(
              senderKey,
              prefixLength: prefixLength,
              companionKey: companionKey,
            )
          : await _contactsDao.getContactByPublicKey(senderKey);

      final resolvedSenderPublicKey = contact?.publicKey ?? senderKey;

      // For DMs, use the stored contact hash when available.
      // This keeps DM threads stable and avoids hashing the zero-padded prefix.
      final contactHash = contact?.hash ?? _calculateContactHash(senderKey);

      final senderName =
          contact?.name ?? 'User ${_bytesToHex(senderKey.sublist(0, 3))}';

      // Generate deterministic UUID to prevent duplicates
      // Same message (sender + timestamp + content) always gets same ID
      final messageId = _generateMessageId(
        // Use the raw sender key (prefix padded) for determinism across runs.
        senderId: senderKey,
        timestamp: response.timestamp,
        content: response.text,
        channelHash: contactHash,
      );

      final message = MessagesCompanion.insert(
        id: messageId,
        senderId: resolvedSenderPublicKey,
        senderName: drift.Value(senderName), // Store sender name in message
        channelHash: contactHash, // Use full contact hash for DMs
        content: response.text,
        timestamp: response.timestamp * 1000, // Convert to milliseconds
        isPrivate: true,
        isSentByMe: response.isFromSelf,
        isRead: drift.Value(response.isFromSelf), // Mark sent messages as read
        deliveryStatus: 'DELIVERED',
        companionDeviceKey:
            drift.Value(_settingsService.settings.currentCompanionPublicKey),
      );

      // Insert message (async, fire-and-forget)
      await _messagesDao.insertMessage(message).then((insertedMessage) async {
        // Show notification for received direct messages (not sent by me)
        if (!response.isFromSelf && insertedMessage != null) {
          await _notificationService.showMessageNotification(
            message: insertedMessage,
            channelName: senderName,
            isDirect: true,
          );
        }
      }).catchError((e) {
        if (!e.toString().contains('UNIQUE constraint')) {
          debugPrint('[MessageSync] ⚠️ Failed to save message: $e');
        }
      });
    } catch (e) {
      if (!e.toString().contains('UNIQUE constraint')) {
        debugPrint('[MessageSync] ⚠️ Failed to save message: $e');
      }
    }
  }

  /// Calculate contact hash from public key (matches ContactRepository hash calculation)
  int _calculateContactHash(Uint8List publicKey) {
    if (publicKey.isEmpty) return 0;

    // Use same hash algorithm as ContactRepository to ensure proper lookup
    int hash = 0;
    for (int i = 0; i < publicKey.length; i++) {
      hash = (hash * 31 + publicKey[i]) & 0xFFFFFFFF; // Keep as 32-bit int
    }
    return hash;
  }

  /// Handle received channel message
  /// Matches Android MessageViewModel.kt channel message handling
  void _handleChannelMessage(ChannelMessageReceivedResponse response) async {
    try {
      // Parse MeshCore format: "SENDER_NAME: MESSAGE"
      // The firmware prepends sender name/ID with colon separator
      String senderName;
      String messageContent;

      if (response.text.contains(': ')) {
        final separatorIndex = response.text.indexOf(': ');
        senderName = response.text.substring(0, separatorIndex);
        messageContent = response.text.substring(separatorIndex + 2);
      } else {
        // Fallback if no colon separator found
        senderName = 'Mesh User';
        messageContent = response.text;
      }

      debugPrint(
          '[MessageSync] 📩 Channel message from \'$senderName\': \'$messageContent\'');

      // Peer capability messages update per-contact capability state.
      // Do not store in chat.
      if (CapabilityMessage.isCapabilityMessage(messageContent)) {
        debugPrint(
            '[Capability] 📡 #CAP message from \'$senderName\': \'$messageContent\'');
        await _handleCapabilityChannelMessage(
          senderName: senderName,
          content: messageContent,
        );
        return;
      }

      // #T: topology messages (v2 telemetry): update graph model + contact DB.
      if (TopologyMessage.isTopologyMessage(messageContent)) {
        final key =
            'topo:$senderName:${response.channelIndex}:${messageContent.hashCode}';
        if (_shouldSuppressTelemetryKey(key)) {
          debugPrint('[Topology] 🔁 Duplicate #T: suppressed');
          return;
        }
        debugPrint(
            '[Topology] 🕸️ #T: message intercepted (not saved to chat)');
        await _handleTopologyChannelMessage(
          senderName: senderName,
          content: messageContent,
          pathLen: response.pathLength,
          receivedChannelIdx: response.channelIndex,
        );
        return;
      }

      // #TEL: telemetry messages (v1): update contact + map persistence.
      if (TelemetryMessage.isTelemetryMessage(messageContent)) {
        final key =
            'tel:$senderName:${response.channelIndex}:${messageContent.hashCode}';
        if (_shouldSuppressTelemetryKey(key)) {
          debugPrint('[TELREC] 🔁 Duplicate telemetry suppressed (recent key)');
          return;
        }
        debugPrint(
            '[TELREC] 📥 #TEL: message from $senderName on ch=${response.channelIndex} pathLen=${response.pathLength} payload=${messageContent}');
        await _handleTelemetryChannelMessage(
          senderName: senderName,
          content: messageContent,
          pathLen: response.pathLength,
          receivedChannelIdx: response.channelIndex,
        );
        return;
      }

      // TEAM waypoint sharing messages are sent as hidden structured payloads in channels.
      // Do not store them in chat; instead parse + store waypoint.
      if (WaypointMeshMessage.isWaypointMessage(messageContent)) {
        debugPrint(
            '[Waypoints] 📍 Waypoint message intercepted (not saved to chat)');
        await _handleWaypointChannelMessage(
          senderName: senderName,
          content: messageContent,
          isFromSelf: response.isFromSelf,
        );
        return;
      }

      // Multi-part route continuation messages.
      if (WaypointRouteContinuation.isContinuationMessage(messageContent)) {
        debugPrint(
            '[Waypoints] 📍 Route continuation message intercepted');
        await _handleWaypointRouteContinuation(
          senderName: senderName,
          content: messageContent,
          isFromSelf: response.isFromSelf,
        );
        return;
      }

      // Look up channel by index to get actual channel hash
      final channel =
          await _channelsDao.getChannelByIndex(response.channelIndex);

      if (channel == null) {
        debugPrint(
            '[MessageSync] ⚠️ No channel found for index ${response.channelIndex} - message dropped');
        return;
      }

      // Generate deterministic UUID to prevent duplicates
      // Use senderName in ID since we don't have actual senderId for channel messages
      final messageId = _generateMessageId(
        senderId: Uint8List.fromList(senderName.codeUnits), // Use name as seed
        timestamp: response.timestamp,
        content: messageContent,
        channelHash: channel.hash,
      );

      final message = MessagesCompanion.insert(
        id: messageId,
        senderId: Uint8List(32), // Unknown sender - use empty array
        senderName: drift.Value(senderName), // Store sender name from message
        channelHash: channel.hash, // Use actual channel hash, not index
        content: messageContent, // Content only, without sender prefix
        timestamp: response.timestamp * 1000, // Convert to milliseconds
        isPrivate:
            false, // Channel messages are never private (even in "private" channels)
        isSentByMe: response.isFromSelf,
        isRead: drift.Value(response.isFromSelf), // Mark sent messages as read
        deliveryStatus: 'RECEIVED',
        companionDeviceKey:
            drift.Value(_settingsService.settings.currentCompanionPublicKey),
      );

      // Insert message
      try {
        final insertedMessage = await _messagesDao.insertMessage(message);

        debugPrint(
            '[MessageSync] 💾 Saved channel message from $senderName (channel ${channel.name}, idx=${response.channelIndex})');

        // Show notification for received channel messages (not sent by me)
        if (!response.isFromSelf && insertedMessage != null) {
          await _notificationService.showMessageNotification(
            message: insertedMessage,
            channelName: channel.name,
            isDirect: false,
          );
          debugPrint(
              '[MessageSync] 🔔 Notification shown for channel message in ${channel.name}');
        }
      } catch (e) {
        // Silently ignore duplicate key errors (message already saved)
        if (!e.toString().contains('UNIQUE constraint')) {
          rethrow;
        } else {
          debugPrint(
              '[MessageSync] 🔄 Duplicate channel message ignored (already saved)');
          return;
        }
      }
    } catch (e) {
      debugPrint('[MessageSync] ⚠️ Error handling channel message: $e');
    }
  }

  static const double _duplicateWaypointLocationRadiusMeters = 20;

  bool _shouldSuppressWaypointKey(String key) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Opportunistic cleanup.
    _recentWaypointKeysMs.removeWhere(
      (_, ts) => (nowMs - ts) > _recentWaypointTtl.inMilliseconds,
    );

    final last = _recentWaypointKeysMs[key];
    if (last != null && (nowMs - last) <= _recentWaypointTtl.inMilliseconds) {
      return true;
    }

    _recentWaypointKeysMs[key] = nowMs;
    return false;
  }

  bool _shouldSuppressTelemetryKey(String key) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Opportunistic cleanup.
    _recentTelemetryKeysMs.removeWhere(
      (_, ts) => (nowMs - ts) > _recentTelemetryTtl.inMilliseconds,
    );

    final last = _recentTelemetryKeysMs[key];
    if (last != null && (nowMs - last) <= _recentTelemetryTtl.inMilliseconds) {
      return true;
    }

    _recentTelemetryKeysMs[key] = nowMs;
    return false;
  }

  double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  Future<void> _handleWaypointChannelMessage({
    required String senderName,
    required String content,
    required bool isFromSelf,
  }) async {
    debugPrint('[WaypointRX] 📥 Raw content (${content.length} chars): $content');
    final msg = WaypointMeshMessage.parse(content);
    if (msg == null) {
      debugPrint('[WaypointRX] ⚠️ Failed to parse waypoint payload');
      return;
    }
    debugPrint('[WaypointRX] ✅ Parsed: name=${msg.name}, type=${msg.type}, lat=${msg.latitude}, lon=${msg.longitude}, meshId=${msg.meshId}, routePoints=${msg.routePoints.length}, desc=${msg.description}');

    // If we sent this waypoint message ourselves, do not store it as a received
    // waypoint. We already have (or should have) a local copy and storing the
    // echo can create duplicates (especially when creator IDs differ).
    if (isFromSelf) {
      debugPrint('[Waypoints] ↩️ Ignoring self-sent waypoint message');
      return;
    }

    // Check for multi-part indicator (8th field like "1/3").
    final partInfo = WaypointMeshMessage.parsePartInfo(content);
    debugPrint('[WaypointRX] 🔍 partInfo=$partInfo');
    if (partInfo != null && partInfo.isMultiPart) {
      // This is part 1 of a multi-part route. Buffer it and wait for the rest.
      final meshId = (msg.meshId ?? '').trim();
      final bufferKey = '$senderName:$meshId';
      _waypointPartBuffers[bufferKey] = _WaypointPartBuffer(
        msg: msg,
        senderName: senderName,
        totalParts: partInfo.totalParts,
        receivedAt: DateTime.now(),
      );
      // Store part 1's raw route chunk text directly from the message
      // to preserve trailing '~' separators for correct reassembly.
      final contentParts =
          content.substring(WaypointMeshMessage.prefix.length).split('|');
      final rawRouteChunk = contentParts.length >= 7 ? contentParts[6] : '';
      _waypointPartBuffers[bufferKey]!.chunks[1] = rawRouteChunk;
      debugPrint(
          '[WaypointRX] 📦 Buffered part 1/${partInfo.totalParts} for meshId=$meshId, chunk="$rawRouteChunk"');
      _cleanupStalePartBuffers();
      return;
    }

    // Single-message waypoint (no multi-part). Process immediately.
    await _processReceivedWaypoint(msg: msg, senderName: senderName);
  }

  Future<void> _handleWaypointRouteContinuation({
    required String senderName,
    required String content,
    required bool isFromSelf,
  }) async {
    debugPrint('[WaypointRX] 📥 #WRC raw content (${content.length} chars): $content');
    if (isFromSelf) return;

    final cont = WaypointRouteContinuation.parse(content);
    if (cont == null) {
      debugPrint('[Waypoints] ⚠️ Failed to parse #WRC payload');
      return;
    }

    final bufferKey = '$senderName:${cont.meshId}';
    final buffer = _waypointPartBuffers[bufferKey];
    if (buffer == null) {
      debugPrint(
          '[Waypoints] ⚠️ No buffer for continuation (meshId=${cont.meshId})');
      return;
    }

    buffer.chunks[cont.partNum] = cont.routeChunk;
    debugPrint(
        '[WaypointRX] 📦 Received part ${cont.partNum}/${cont.totalParts} for meshId=${cont.meshId}, chunk="${cont.routeChunk}"');
    debugPrint(
        '[WaypointRX] 📊 Buffer has ${buffer.chunks.length}/${buffer.totalParts} parts: keys=${buffer.chunks.keys.toList()}');

    // Check if all parts arrived.
    if (buffer.chunks.length >= buffer.totalParts) {
      _waypointPartBuffers.remove(bufferKey);

      // Reassemble route coordinates in order.
      final sortedKeys = buffer.chunks.keys.toList()..sort();
      final fullCoords =
          sortedKeys.map((k) => buffer.chunks[k]!).join();
      debugPrint('[WaypointRX] 🔗 Joined coords (${fullCoords.length} chars): $fullCoords');
      // Remove trailing '~' if present from chunk boundaries.
      final trimmedCoords =
          fullCoords.endsWith('~') ? fullCoords.substring(0, fullCoords.length - 1) : fullCoords;
      debugPrint('[WaypointRX] ✂️ Trimmed coords: $trimmedCoords');
      final allPoints = decodeRouteCoordinatesFromMesh(trimmedCoords);
      debugPrint('[WaypointRX] 📍 Decoded ${allPoints.length} points');

      final reassembled = WaypointMeshMessage(
        meshId: buffer.msg.meshId,
        name: buffer.msg.name,
        latitude: buffer.msg.latitude,
        longitude: buffer.msg.longitude,
        description: buffer.msg.description,
        type: buffer.msg.type,
        routePoints: allPoints,
        colorValue: buffer.msg.colorValue,
      );

      debugPrint(
          '[WaypointRX] ✅ Reassembled ${allPoints.length} route points from ${buffer.totalParts} parts');
      debugPrint(
          '[WaypointRX] 📍 Reassembled msg: name=${reassembled.name}, type=${reassembled.type}, meshId=${reassembled.meshId}, points=${reassembled.routePoints.length}');
      await _processReceivedWaypoint(
        msg: reassembled,
        senderName: senderName,
      );
    }
  }

  /// Remove stale part buffers older than 60 seconds.
  void _cleanupStalePartBuffers() {
    final now = DateTime.now();
    _waypointPartBuffers.removeWhere(
      (_, buf) => now.difference(buf.receivedAt).inSeconds > 60,
    );
  }

  /// Core waypoint processing shared by single-message and reassembled
  /// multi-part waypoints.
  Future<void> _processReceivedWaypoint({
    required WaypointMeshMessage msg,
    required String senderName,
  }) async {
    debugPrint('[WaypointRX] 🔧 _processReceivedWaypoint: name=${msg.name}, type=${msg.type}, meshId=${msg.meshId}, lat=${msg.latitude}, lon=${msg.longitude}, routePoints=${msg.routePoints.length}, desc="${msg.description}"');
    for (var i = 0; i < msg.routePoints.length; i++) {
      debugPrint('[WaypointRX]   point[$i]: ${msg.routePoints[i].latitude}, ${msg.routePoints[i].longitude}');
    }
    // Suppress duplicates ASAP (before awaits) to avoid races.
    final meshIdKey = (msg.meshId ?? '').trim();
    final key = meshIdKey.isNotEmpty
        ? 'meshId:$senderName:$meshIdKey'
        : 'name:$senderName:${msg.name.hashCode}';
    if (_shouldSuppressWaypointKey(key)) {
      debugPrint('[Waypoints] 🔁 Duplicate waypoint suppressed (recent key)');
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final waypointsDao = _database.waypointsDao;
    final allWaypoints = await waypointsDao.getAllWaypoints();

    final incomingMeshId = (msg.meshId != null && msg.meshId!.trim().isNotEmpty)
        ? msg.meshId!.trim()
        : null;

    // Smart update: meshId + creator match.
    WaypointData? existing;
    if (incomingMeshId != null) {
      for (final w in allWaypoints) {
        if (w.meshId == incomingMeshId && w.creatorNodeId == senderName) {
          existing = w;
          break;
        }
      }
    }

    // Detect meshId collision with different creator.
    String finalMeshId = incomingMeshId ?? _uuid.v4();
    if (incomingMeshId != null) {
      for (final w in allWaypoints) {
        if (w.meshId == incomingMeshId && w.creatorNodeId != senderName) {
          finalMeshId = _uuid.v4();
          debugPrint(
              '[Waypoints] ⚠️ MeshId collision detected; using local meshId=$finalMeshId');
          break;
        }
      }
    }

    final isRouteMessage =
        msg.type.trim().toUpperCase() == waypoint_model.WaypointType.route.name.toUpperCase();
    final routePoints = isRouteMessage && msg.routePoints.isNotEmpty
        ? msg.routePoints
        : <latlong2.LatLng>[latlong2.LatLng(msg.latitude, msg.longitude)];
    final storedDescription = isRouteMessage
        ? encodeRoutePayload(description: msg.description, points: routePoints, colorValue: msg.colorValue)
        : msg.description;
    final anchorPoint = routePoints.first;

    if (existing != null) {
      await waypointsDao.updateWaypoint(
        existing.id,
        WaypointsCompanion(
          meshId: drift.Value(finalMeshId),
          name: drift.Value(msg.name),
          description: drift.Value(storedDescription),
          latitude: drift.Value(anchorPoint.latitude),
          longitude: drift.Value(anchorPoint.longitude),
          waypointType: drift.Value(msg.type.toUpperCase()),
          createdAt: drift.Value(nowMs),
          isNew: const drift.Value(true),
        ),
      );

      debugPrint(
          '[Waypoints] ✅ Updated existing waypoint: ${msg.name} (meshId=$finalMeshId)');
    } else {
      // Duplicate detection (inserts only):
      // - Same name (case-insensitive), OR
      // - Same location (within a small radius)
      final incomingNameNorm = msg.name.trim().toLowerCase();
      for (final w in allWaypoints) {
        final existingNameNorm = w.name.trim().toLowerCase();
        final nameMatch = incomingNameNorm.isNotEmpty &&
            existingNameNorm.isNotEmpty &&
            existingNameNorm == incomingNameNorm;

        final dist = _distanceMeters(
          w.latitude,
          w.longitude,
          msg.latitude,
          msg.longitude,
        );

        final locationMatch = dist <= _duplicateWaypointLocationRadiusMeters;

        if (nameMatch || locationMatch) {
          debugPrint(
              '[Waypoints] 🔄 Duplicate waypoint ignored (${dist.toStringAsFixed(1)}m)');
          return;
        }
      }

      final id = _uuid.v4();
      await waypointsDao.insertWaypoint(
        WaypointsCompanion.insert(
          id: id,
          meshId: drift.Value(finalMeshId),
          name: msg.name,
          description: drift.Value(storedDescription),
          latitude: anchorPoint.latitude,
          longitude: anchorPoint.longitude,
          waypointType: msg.type.toUpperCase(),
          creatorNodeId: senderName,
          createdAt: nowMs,
          isReceived: const drift.Value(true),
          isVisible: const drift.Value(true),
          isNew: const drift.Value(true),
        ),
      );

      debugPrint(
          '[Waypoints] ✅ Inserted received waypoint: ${msg.name} (meshId=$finalMeshId)');
    }

    // _processReceivedWaypoint is only called for non-self messages.
    final type = waypoint_model.WaypointType.fromString(msg.type);
    await _notificationService.showWaypointNotification(
      waypointName: msg.name,
      waypointType: type.displayName,
      creatorName: senderName,
    );
  }

  /// Send a TEAM-compatible waypoint share message (`#WAY:`) on the selected
  /// telemetry private channel. Does not store anything in chat.
  Future<bool> sendWaypointToMesh(WaypointData waypoint) async {
    final channelHashHex = _settingsService.settings.telemetryChannelHash;
    if (channelHashHex == null || channelHashHex.trim().isEmpty) {
      debugPrint('[Waypoints] ❌ No telemetry channel selected');
      return false;
    }

    int channelHash;
    try {
      final cleaned = channelHashHex.trim().toLowerCase().startsWith('0x')
          ? channelHashHex.trim().substring(2)
          : channelHashHex.trim();
      channelHash = int.parse(cleaned, radix: 16);
    } catch (e) {
      debugPrint(
          '[Waypoints] ❌ Invalid telemetry channel hash: $channelHashHex');
      return false;
    }

    final channel = await _channelsDao.getChannelByHash(channelHash);
    if (channel == null) {
      debugPrint('[Waypoints] ❌ Channel not found for hash: $channelHashHex');
      return false;
    }

    // Ensure waypoint has meshId (required for new format).
    String meshId = (waypoint.meshId ?? '').trim();
    if (meshId.isEmpty) {
      meshId = _uuid.v4();
      await _database.waypointsDao.updateWaypoint(
        waypoint.id,
        WaypointsCompanion(
          meshId: drift.Value(meshId),
        ),
      );
    }

    final isRoute = waypoint.waypointType.toUpperCase() ==
        waypoint_model.WaypointType.route.name.toUpperCase();

    final routePayload = decodeRoutePayload(
      waypoint.description,
      fallbackLatitude: waypoint.latitude,
      fallbackLongitude: waypoint.longitude,
    );

    final routePoints = isRoute
        ? routePayload.points
        : const <latlong2.LatLng>[];

    final routeAnchor = routePoints.isNotEmpty
        ? routePoints.first
        : latlong2.LatLng(waypoint.latitude, waypoint.longitude);

    final waypointMsg = WaypointMeshMessage(
      meshId: meshId,
      name: waypoint.name,
      latitude: routeAnchor.latitude,
      longitude: routeAnchor.longitude,
      description: isRoute ? routePayload.description : waypoint.description,
      type: waypoint.waypointType,
      routePoints: routePoints,
      colorValue: isRoute ? routePayload.colorValue : null,
    );

    final parts = waypointMsg.splitForMesh(maxMeshMessageBytes);

    debugPrint(
        '[Waypoints] 📤 Sending waypoint on channelIndex=${channel.channelIndex} (${parts.length} part(s))');

    for (var i = 0; i < parts.length; i++) {
      if (i > 0) {
        // Small delay between parts so the mesh can process each frame.
        await Future.delayed(const Duration(milliseconds: 200));
      }
      final ok =
          await _bleService.sendChannelMessage(channel.channelIndex, parts[i]);
      if (!ok) {
        debugPrint('[Waypoints] ❌ Failed to send part ${i + 1}/${parts.length}');
        return false;
      }
    }
    return true;
  }

  /// Send multiple waypoints sequentially.
  ///
  /// In practice, rapid back-to-back BLE writes can fail/drop on some devices.
  /// This helper adds a small inter-send delay and retries per waypoint.
  Future<({int okCount, int failCount})> sendWaypointsToMesh(
    List<WaypointData> waypoints, {
    Duration interSendDelay = const Duration(milliseconds: 250),
    int maxAttemptsPerWaypoint = 3,
  }) async {
    var okCount = 0;
    var failCount = 0;

    for (final waypoint in waypoints) {
      var sent = false;

      for (var attempt = 1; attempt <= maxAttemptsPerWaypoint; attempt++) {
        final ok = await sendWaypointToMesh(waypoint);
        if (ok) {
          sent = true;
          break;
        }

        // Exponential-ish backoff.
        await Future.delayed(
          Duration(milliseconds: interSendDelay.inMilliseconds * attempt),
        );
      }

      if (sent) {
        okCount++;
      } else {
        failCount++;
      }

      // Always yield a bit between waypoints.
      await Future.delayed(interSendDelay);
    }

    return (okCount: okCount, failCount: failCount);
  }

  Future<void> _handleCapabilityChannelMessage({
    required String senderName,
    required String content,
  }) async {
    final msg = CapabilityMessage.parse(content);
    if (msg == null) {
      debugPrint(
          '[Capability] ⚠️ Failed to parse #CAP payload from "$senderName"');
      return;
    }
    await _capabilityService.updateFromMessage(senderName, msg);
    debugPrint('[Capability] ✅ Stored capability for "$senderName": $msg');
  }

  Future<void> _handleTelemetryChannelMessage({
    required String senderName,
    required String content,
    required int pathLen,
    required int receivedChannelIdx,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final telemetry = TelemetryMessage.parse(content);
    if (telemetry == null) {
      debugPrint('[TELREC] ⚠️ Failed to parse telemetry payload: $content');
      return;
    }

    debugPrint(
        '[TELREC] ✅ Parsed from=$senderName lat=${telemetry.latitude}, lon=${telemetry.longitude}, compBatt=${telemetry.companionBatteryMilliVolts}mV, phoneBatt=${telemetry.phoneBatteryMilliVolts}mV, needsFwd=${telemetry.needsForwarding}, maxPath=${telemetry.maxPathObserved}, autonomous=${telemetry.isAutonomousDevice}');

    // Emit to forwarding strategies before any async DB work.
    _telemetryStreamController.add(TelemetryEvent(
      senderName: senderName,
      telemetry: telemetry,
      pathLen: pathLen,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(nowMs),
    ));

    final companionKey = _settingsService.settings.currentCompanionPublicKey;
    if (companionKey == null || companionKey.isEmpty) {
      debugPrint(
          '[TELREC] ⚠️ No companion context; ignoring telemetry from $senderName');
      return;
    }

    final contacts = await _contactsDao.getContactsByCompanion(companionKey);

    ContactData? contact;
    for (final c in contacts) {
      if ((c.name ?? '') == senderName) {
        contact = c;
        break;
      }
    }

    contact ??= _findBestContactMatch(contacts, senderName);

    if (contact == null) {
      debugPrint(
          '[TELREC] 📍 Unknown sender \'$senderName\' - triggering SEND_SELF_ADVERT');
      await _bleService.sendSelfAdvert();
      return;
    }

    debugPrint(
        '[TELREC] 👤 Matched contact name=\'${contact.name}\' hops=$pathLen channelIdx=$receivedChannelIdx');

    // Track as direct neighbor for outbound #T: bitmap.
    if (pathLen == 0) {
      final hexPrefix = contact.publicKey
          .take(6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toLowerCase();
      _neighborTracker.onPacketReceived(hexPrefix);
    }

    final updatedName = senderName;

    final updated = ContactsCompanion(
      publicKey: drift.Value(contact.publicKey),
      hash: drift.Value(contact.hash),
      name: drift.Value(updatedName),
      latitude: telemetry.latitude != null
          ? drift.Value(telemetry.latitude)
          : const drift.Value.absent(),
      longitude: telemetry.longitude != null
          ? drift.Value(telemetry.longitude)
          : const drift.Value.absent(),
      lastSeen: drift.Value(nowMs),
      companionBatteryMilliVolts: telemetry.companionBatteryMilliVolts != null
          ? drift.Value(telemetry.companionBatteryMilliVolts)
          : const drift.Value.absent(),
      phoneBatteryMilliVolts: telemetry.phoneBatteryMilliVolts != null
          ? drift.Value(telemetry.phoneBatteryMilliVolts)
          : const drift.Value.absent(),
      isDirect: drift.Value(pathLen == 0),
      hopCount: drift.Value(pathLen),
      isAutonomousDevice: drift.Value(telemetry.isAutonomousDevice),
      lastTelemetryChannelIdx: drift.Value(receivedChannelIdx),
      lastTelemetryTimestamp: drift.Value(nowMs),
      companionDeviceKey: drift.Value(companionKey),
    );

    await _contactsDao.upsertContact(updated);

    debugPrint('[TELREC] 💾 Contact updated (telemetry freshness + fields)');

    if (telemetry.latitude != null && telemetry.longitude != null) {
      final publicKeyHex = _bytesToHex(contact.publicKey).toUpperCase();
      await _upsertContactDisplayState(
        publicKeyHex: publicKeyHex,
        companionKey: companionKey,
        lastSeen: nowMs,
        latitude: telemetry.latitude!,
        longitude: telemetry.longitude!,
        channelIdx: receivedChannelIdx,
        pathLen: pathLen,
        name: updatedName,
        isAutonomousDevice: telemetry.isAutonomousDevice,
      );

      await _addPositionHistoryPoint(
        publicKeyHex: publicKeyHex,
        companionKey: companionKey,
        timestamp: nowMs,
        latitude: telemetry.latitude!,
        longitude: telemetry.longitude!,
        channelIdx: receivedChannelIdx,
        pathLen: pathLen,
      );

      debugPrint('[TELREC] 🗺️ Display state + history persisted');
    }
  }

  ContactData? _findBestContactMatch(
    List<ContactData> contacts,
    String senderName,
  ) {
    if (contacts.isEmpty) return null;

    final senderLower = senderName.toLowerCase();

    bool isDeviceIdLike(String name) {
      final hex8 = RegExp(r'^[A-Fa-f0-9]{8}$');
      if (hex8.hasMatch(name)) return true;
      final lowered = name.toLowerCase();
      return lowered.contains('meshcore') || lowered.contains('testunit');
    }

    bool isCustomNameLike(String name) {
      final hex8 = RegExp(r'^[A-Fa-f0-9]{8}$');
      final lowered = name.toLowerCase();
      if (hex8.hasMatch(name)) return false;
      if (lowered.contains('meshcore') || lowered.contains('testunit')) {
        return false;
      }
      return name.length < 20;
    }

    // DeviceId->Alias upgrade match.
    for (final c in contacts) {
      final existingName = c.name;
      if (existingName == null) continue;
      if (isDeviceIdLike(existingName) && isCustomNameLike(senderName)) {
        return c;
      }
    }

    // Partial match.
    for (final c in contacts) {
      final existing = (c.name ?? '').toLowerCase();
      if (existing.isEmpty) continue;
      if (existing.contains(senderLower) || senderLower.contains(existing)) {
        return c;
      }
    }

    return null;
  }

  Future<void> _upsertContactDisplayState({
    required String publicKeyHex,
    required String companionKey,
    required int lastSeen,
    required double latitude,
    required double longitude,
    required int channelIdx,
    required int pathLen,
    required String? name,
    bool isAutonomousDevice = false,
  }) async {
    final existing = await (_database.select(_database.contactDisplayStates)
          ..where((t) => t.publicKeyHex.equals(publicKeyHex)))
        .getSingleOrNull();

    if (existing != null) {
      await (_database.update(_database.contactDisplayStates)
            ..where((t) => t.publicKeyHex.equals(publicKeyHex)))
          .write(ContactDisplayStatesCompanion(
        companionDeviceKey: drift.Value(companionKey),
        lastSeen: drift.Value(lastSeen),
        lastLatitude: drift.Value(latitude),
        lastLongitude: drift.Value(longitude),
        lastChannelIdx: drift.Value(channelIdx),
        lastPathLen: drift.Value(pathLen),
        isManuallyHidden: const drift.Value(false),
        hiddenAt: const drift.Value.absent(),
        name: name != null ? drift.Value(name) : const drift.Value.absent(),
        isAutonomousDevice: drift.Value(isAutonomousDevice),
        totalTelemetryReceived:
            drift.Value(existing.totalTelemetryReceived + 1),
      ));
    } else {
      await _database.into(_database.contactDisplayStates).insert(
            ContactDisplayStatesCompanion.insert(
              publicKeyHex: publicKeyHex,
              companionDeviceKey: companionKey,
              lastSeen: lastSeen,
              lastLatitude: drift.Value(latitude),
              lastLongitude: drift.Value(longitude),
              lastChannelIdx: channelIdx,
              lastPathLen: pathLen,
              isManuallyHidden: const drift.Value(false),
              hiddenAt: const drift.Value.absent(),
              name:
                  name != null ? drift.Value(name) : const drift.Value.absent(),
              isAutonomousDevice: drift.Value(isAutonomousDevice),
              firstSeen: lastSeen,
              totalTelemetryReceived: const drift.Value(1),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
    }
  }

  static const int _binRaw = 0;
  static const int _bin5Min = 1;
  static const int _bin30Min = 2;
  static const int _bin1Hour = 3;

  static const int _maxRaw = 10;
  static const int _max5Min = 10;
  static const int _max30Min = 6;
  static const int _max1Hour = 4;

  Future<void> _addPositionHistoryPoint({
    required String publicKeyHex,
    required String companionKey,
    required int timestamp,
    required double latitude,
    required double longitude,
    required int channelIdx,
    required int pathLen,
  }) async {
    // De-dupe history inserts only (push + sync can deliver the same telemetry twice).
    // Never suppress telemetry processing as a whole, to preserve high refresh rates.
    final lastRaw = await (_database.select(_database.contactPositionHistories)
          ..where((t) =>
              t.publicKeyHex.equals(publicKeyHex) &
              t.companionDeviceKey.equals(companionKey) &
              t.binLevel.equals(_binRaw))
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.timestamp, mode: drift.OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (lastRaw != null &&
        lastRaw.timestamp == timestamp &&
        lastRaw.latitude == latitude &&
        lastRaw.longitude == longitude &&
        lastRaw.channelIdx == channelIdx &&
        lastRaw.pathLen == pathLen) {
      debugPrint('[TELREC] 🔁 Duplicate position point skipped');
      return;
    }

    await _database.into(_database.contactPositionHistories).insert(
          ContactPositionHistoriesCompanion.insert(
            publicKeyHex: publicKeyHex,
            companionDeviceKey: companionKey,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            channelIdx: channelIdx,
            pathLen: pathLen,
            binLevel: _binRaw,
            isAggregated: false,
          ),
        );

    await _performPositionHistoryBinning(publicKeyHex, companionKey);
  }

  Future<int> _countAtBinLevel(
    String publicKeyHex,
    String companionKey,
    int binLevel,
  ) async {
    final countExp = _database.contactPositionHistories.id.count();
    final query = _database.selectOnly(_database.contactPositionHistories)
      ..addColumns([countExp])
      ..where(
          _database.contactPositionHistories.publicKeyHex.equals(publicKeyHex) &
              _database.contactPositionHistories.companionDeviceKey
                  .equals(companionKey) &
              _database.contactPositionHistories.binLevel.equals(binLevel));

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<List<ContactPositionHistoryData>> _getOldestAtBinLevel({
    required String publicKeyHex,
    required String companionKey,
    required int binLevel,
    required int count,
  }) {
    return (_database.select(_database.contactPositionHistories)
          ..where((t) =>
              t.publicKeyHex.equals(publicKeyHex) &
              t.companionDeviceKey.equals(companionKey) &
              t.binLevel.equals(binLevel))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.timestamp)])
          ..limit(count))
        .get();
  }

  Future<void> _deleteHistoryIds(List<int> ids) async {
    if (ids.isEmpty) return;
    await (_database.delete(_database.contactPositionHistories)
          ..where((t) => t.id.isIn(ids)))
        .go();
  }

  ContactPositionHistoriesCompanion _averagePoints(
    List<ContactPositionHistoryData> points,
    int newBinLevel,
  ) {
    final avgLat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final avgLon =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

    final timestamps = points.map((p) => p.timestamp).toList()..sort();
    final medianTimestamp = timestamps[timestamps.length ~/ 2];

    final avgPathLen =
        (points.map((p) => p.pathLen).reduce((a, b) => a + b) / points.length)
            .round();

    final first = points.first;

    return ContactPositionHistoriesCompanion.insert(
      publicKeyHex: first.publicKeyHex,
      companionDeviceKey: first.companionDeviceKey,
      timestamp: medianTimestamp,
      latitude: avgLat,
      longitude: avgLon,
      accuracy: const drift.Value.absent(),
      channelIdx: first.channelIdx,
      pathLen: avgPathLen,
      batteryVoltage: const drift.Value.absent(),
      binLevel: newBinLevel,
      isAggregated: true,
    );
  }

  Future<void> _performPositionHistoryBinning(
    String publicKeyHex,
    String companionKey,
  ) async {
    final rawCount =
        await _countAtBinLevel(publicKeyHex, companionKey, _binRaw);
    if (rawCount > _maxRaw) {
      final oldest = await _getOldestAtBinLevel(
        publicKeyHex: publicKeyHex,
        companionKey: companionKey,
        binLevel: _binRaw,
        count: 5,
      );
      if (oldest.isNotEmpty) {
        await _database.into(_database.contactPositionHistories).insert(
              _averagePoints(oldest, _bin5Min),
            );
        await _deleteHistoryIds(oldest.map((p) => p.id).toList());
      }
    }

    final level1Count =
        await _countAtBinLevel(publicKeyHex, companionKey, _bin5Min);
    if (level1Count > _max5Min) {
      final oldest = await _getOldestAtBinLevel(
        publicKeyHex: publicKeyHex,
        companionKey: companionKey,
        binLevel: _bin5Min,
        count: 6,
      );
      if (oldest.isNotEmpty) {
        await _database.into(_database.contactPositionHistories).insert(
              _averagePoints(oldest, _bin30Min),
            );
        await _deleteHistoryIds(oldest.map((p) => p.id).toList());
      }
    }

    final level2Count =
        await _countAtBinLevel(publicKeyHex, companionKey, _bin30Min);
    if (level2Count > _max30Min) {
      final oldest = await _getOldestAtBinLevel(
        publicKeyHex: publicKeyHex,
        companionKey: companionKey,
        binLevel: _bin30Min,
        count: 2,
      );
      if (oldest.isNotEmpty) {
        await _database.into(_database.contactPositionHistories).insert(
              _averagePoints(oldest, _bin1Hour),
            );
        await _deleteHistoryIds(oldest.map((p) => p.id).toList());
      }
    }

    final level3Count =
        await _countAtBinLevel(publicKeyHex, companionKey, _bin1Hour);
    if (level3Count > _max1Hour) {
      final all = await _getOldestAtBinLevel(
        publicKeyHex: publicKeyHex,
        companionKey: companionKey,
        binLevel: _bin1Hour,
        count: 100,
      );
      if (all.length > _max1Hour) {
        final toDelete = all.take(all.length - _max1Hour);
        await _deleteHistoryIds(toDelete.map((p) => p.id).toList());
      }
    }
  }

  /// Convert bytes to hex string
  String _bytesToHex(Uint8List bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Send direct message to contact
  /// Returns message ID if successful, null if failed
  Future<String?> sendDirectMessage({
    required String recipientPublicKey,
    required int recipientHash,
    required String content,
  }) async {
    try {
      debugPrint(
          '[MessageRepository] 📤 Sending direct message to ${recipientPublicKey.substring(0, 8)}... (hash: $recipientHash)');

      final companionKey = _settingsService.settings.currentCompanionPublicKey;
      if (companionKey != null && companionKey.isNotEmpty) {
        final contact = await _contactsDao.getContactByHashForCompanion(
            recipientHash, companionKey);
        if (contact != null && contact.isRepeater) {
          debugPrint(
              '[MessageRepository] 🚫 Blocked DM to repeater contact (hash: $recipientHash)');
          return null;
        }
      }

      // Generate message ID and timestamp
      final messageId = _uuid.v4();
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

      // Get selfInfo for sender public key (optional - for display purposes)
      final selfInfo = _bleService.selfInfo;
      final senderPubKeyBytes = selfInfo?.publicKey ??
          Uint8List(32); // Empty 32-byte array if not available

      // Create message in database with SENDING status
      // Note: ackChecksum will be populated after firmware responds with RESP_CODE_SENT
      final message = MessagesCompanion(
        id: drift.Value(messageId),
        senderId: drift.Value(senderPubKeyBytes),
        senderName: const drift.Value.absent(),
        channelHash: drift.Value(recipientHash), // Use recipient hash for DMs
        content: drift.Value(content),
        timestamp: drift.Value(timestamp * 1000), // Store as milliseconds
        isPrivate: const drift.Value(true),
        isRead: const drift.Value(true), // Sent messages are already read
        ackChecksum:
            const drift.Value.absent(), // Will be set after RESP_CODE_SENT
        deliveryStatus: const drift.Value('SENDING'),
        heardByCount: const drift.Value(0),
        attempt: const drift.Value(0),
        isSentByMe: const drift.Value(true),
        companionDeviceKey:
            drift.Value(_settingsService.settings.currentCompanionPublicKey),
      );

      await _messagesDao.insertMessage(message);
      debugPrint('[MessageRepository] 💾 Message stored with ID $messageId');

      // Send via BLE - firmware will calculate the ACK checksum
      final recipientBytes = _hexToBytes(recipientPublicKey);
      final frameSuccess =
          await _bleService.sendDirectMessage(recipientBytes, content);

      if (!frameSuccess) {
        debugPrint('[MessageRepository] ❌ Failed to send BLE frame');
        return null;
      }

      // Wait for RESP_CODE_SENT from firmware (contains expectedAck calculated by firmware)
      debugPrint('[MessageRepository] ⏳ Waiting for RESP_CODE_SENT...');
      final sentResponse = await _waitForSentResponse(timeoutMs: 2000);

      if (sentResponse == null) {
        debugPrint('[MessageRepository] ⏱️ Timeout waiting for RESP_CODE_SENT');
        // Message may still have been sent, keep status as SENDING
        return messageId;
      }

      // Extract expectedAck from firmware response and update message
      if (sentResponse.expectedAck != null) {
        await _messagesDao.updateMessageAckChecksum(
            messageId, sentResponse.expectedAck!);
        debugPrint(
            '[MessageRepository] 🔐 ACK checksum stored: ${_bytesToHex(sentResponse.expectedAck!)}');
      }

      // Update status to SENT
      await _messagesDao.updateDeliveryStatus(messageId, 'SENT');
      debugPrint('[MessageRepository] ✅ Direct message sent successfully');
      return messageId;
    } catch (e) {
      debugPrint('[MessageRepository] ⚠️ Error sending direct message: $e');
      return null;
    }
  }

  /// Send channel message
  /// Returns message ID if successful, null if failed
  /// Note: Channel messages do NOT support ACK tracking (only direct messages do)
  Future<String?> sendChannelMessage({
    required int channelIndex,
    required int channelHash,
    required String content,
  }) async {
    try {
      debugPrint(
          '[MessageRepository] 📤 Sending channel message to channel $channelIndex');

      // Generate message ID and timestamp
      final messageId = _uuid.v4();
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

      // Get selfInfo for sender public key (optional - for display purposes)
      final selfInfo = _bleService.selfInfo;
      final senderPubKeyBytes = selfInfo?.publicKey ??
          Uint8List(32); // Empty 32-byte array if not available

      // Create message in database with SENDING status
      // Channel messages do NOT have ACK tracking
      final message = MessagesCompanion(
        id: drift.Value(messageId),
        senderId: drift.Value(senderPubKeyBytes),
        senderName: const drift.Value.absent(),
        channelHash: drift.Value(channelHash),
        content: drift.Value(content),
        timestamp: drift.Value(timestamp * 1000), // Store as milliseconds
        isPrivate: const drift.Value(false),
        isRead: const drift.Value(true), // Sent messages are already read
        ackChecksum: const drift.Value.absent(), // No ACK for channel messages
        deliveryStatus: const drift.Value('SENDING'),
        heardByCount: const drift.Value(0),
        attempt: const drift.Value(0),
        isSentByMe: const drift.Value(true),
        companionDeviceKey:
            drift.Value(_settingsService.settings.currentCompanionPublicKey),
      );

      await _messagesDao.insertMessage(message);
      debugPrint(
          '[MessageRepository] 💾 Channel message stored with ID $messageId');

      // Send via BLE
      final success =
          await _bleService.sendChannelMessage(channelIndex, content);

      if (success) {
        // Update status to SENT (no ACK tracking for channels)
        await _messagesDao.updateDeliveryStatus(messageId, 'SENT');
        debugPrint('[MessageRepository] ✅ Channel message sent successfully');
        return messageId;
      } else {
        debugPrint('[MessageRepository] ❌ Failed to send channel message');
        return null;
      }
    } catch (e) {
      debugPrint('[MessageRepository] ⚠️ Error sending channel message: $e');
      return null;
    }
  }

  /// Generate deterministic message ID to prevent duplicates
  /// Uses UUID v5 (name-based) with message properties as seed
  String _generateMessageId({
    required Uint8List senderId,
    required int timestamp,
    required String content,
    required int channelHash,
  }) {
    // Create a deterministic name string from message properties
    final senderHex = _bytesToHex(senderId);
    final name = '$senderHex:$timestamp:$channelHash:$content';

    // Use UUID v5 with DNS namespace (arbitrary choice, just need consistency)
    return _uuid.v5(Uuid.NAMESPACE_DNS, name);
  }

  /// Convert hex string to bytes
  Uint8List _hexToBytes(String hex) {
    if (hex.length % 2 != 0) {
      throw ArgumentError('Hex string length must be even');
    }

    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      final hexByte = hex.substring(i, i + 2);
      bytes.add(int.parse(hexByte, radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  Future<void> _handleTopologyChannelMessage({
    required String senderName,
    required String content,
    required int pathLen,
    required int receivedChannelIdx,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final msg = TopologyMessage.parse(content);
    if (msg == null) {
      debugPrint('[Topology] ⚠️ Failed to parse #T: payload');
      return;
    }

    debugPrint(
        '[Topology] ✅ Parsed lat=\${msg.latitude}, lon=\${msg.longitude}, nodeCount=\${msg.nodeCount}');

    final companionKey = _settingsService.settings.currentCompanionPublicKey;
    if (companionKey == null || companionKey.isEmpty) {
      debugPrint('[Topology] ⚠️ No companion context; ignoring #T: message');
      return;
    }

    final contacts = await _contactsDao.getContactsByCompanion(companionKey);
    ContactData? contact;
    for (final c in contacts) {
      if ((c.name ?? '') == senderName) {
        contact = c;
        break;
      }
    }
    contact ??= _findBestContactMatch(contacts, senderName);

    if (contact == null) {
      debugPrint(
          '[Topology] 📍 Unknown sender \'$senderName\' - triggering SEND_SELF_ADVERT');
      await _bleService.sendSelfAdvert();
      return;
    }

    // 12-char lowercase hex = first 6 bytes of the contact's public key.
    final pubKeyHex12 = contact.publicKey
        .take(6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toLowerCase();

    // Update graph — before emitting event so listeners see current neighbors.
    _networkTopology.updateFromTelemetry(
        pubKeyHex12, msg.neighborBitmap, msg.nodeCount);

    final neighbors = _networkTopology.getNeighbors(pubKeyHex12);

    // Track as direct neighbor for outbound #T: bitmap.
    if (pathLen == 0) _neighborTracker.onPacketReceived(pubKeyHex12);

    // Emit topology event to strategy layer.
    _topologyStreamController.add(TopologyEvent(
      senderName: senderName,
      senderPubKeyHex: pubKeyHex12,
      message: msg,
      neighbors: neighbors,
      pathLen: pathLen,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(nowMs),
    ));

    // DB update — same contact fields as #TEL: handler.
    final updated = ContactsCompanion(
      publicKey: drift.Value(contact.publicKey),
      hash: drift.Value(contact.hash),
      name: drift.Value(senderName),
      latitude: msg.latitude != null
          ? drift.Value(msg.latitude)
          : const drift.Value.absent(),
      longitude: msg.longitude != null
          ? drift.Value(msg.longitude)
          : const drift.Value.absent(),
      lastSeen: drift.Value(nowMs),
      companionBatteryMilliVolts: msg.companionBatteryMilliVolts != null
          ? drift.Value(msg.companionBatteryMilliVolts)
          : const drift.Value.absent(),
      phoneBatteryMilliVolts: msg.phoneBatteryMilliVolts != null
          ? drift.Value(msg.phoneBatteryMilliVolts)
          : const drift.Value.absent(),
      isDirect: drift.Value(pathLen == 0),
      hopCount: drift.Value(pathLen),
      lastTelemetryChannelIdx: drift.Value(receivedChannelIdx),
      lastTelemetryTimestamp: drift.Value(nowMs),
      companionDeviceKey: drift.Value(companionKey),
    );
    await _contactsDao.upsertContact(updated);

    if (msg.latitude != null && msg.longitude != null) {
      final publicKeyHex = _bytesToHex(contact.publicKey).toUpperCase();
      await _upsertContactDisplayState(
        publicKeyHex: publicKeyHex,
        companionKey: companionKey,
        lastSeen: nowMs,
        latitude: msg.latitude!,
        longitude: msg.longitude!,
        channelIdx: receivedChannelIdx,
        pathLen: pathLen,
        name: senderName,
      );
      await _addPositionHistoryPoint(
        publicKeyHex: publicKeyHex,
        companionKey: companionKey,
        timestamp: nowMs,
        latitude: msg.latitude!,
        longitude: msg.longitude!,
        channelIdx: receivedChannelIdx,
        pathLen: pathLen,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    stopPushListener();
    _telemetryStreamController.close();
    _topologyStreamController.close();
  }
}

/// Buffer for reassembling multi-part waypoint route messages.
class _WaypointPartBuffer {
  final WaypointMeshMessage msg;
  final String senderName;
  final int totalParts;
  final DateTime receivedAt;
  final Map<int, String> chunks = <int, String>{};

  _WaypointPartBuffer({
    required this.msg,
    required this.senderName,
    required this.totalParts,
    required this.receivedAt,
  });
}
