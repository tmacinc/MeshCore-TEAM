// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:meshcore_team/ble/ble_connection_manager.dart';
import 'package:meshcore_team/ble/ble_commands.dart';
import 'package:meshcore_team/ble/ble_responses.dart';
import 'package:meshcore_team/ble/mesh_ble_device.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:drift/drift.dart' as drift;

/// BLE Service
/// High-level service for managing BLE communication with MeshCore companion device
/// Integrates with database to sync contacts, messages, and channels
class BleService extends ChangeNotifier {
  final BleConnectionManager _connectionManager;
  final AppDatabase _database;

  StreamSubscription<Uint8List>? _frameSubscription;
  SelfInfoResponse? _selfInfo;

  // Getters
  BleConnectionState get connectionState => _connectionManager.state;
  bool get isConnected => _connectionManager.isConnected;
  String? get deviceName => _connectionManager.deviceName;
  String? get deviceAddress => _connectionManager.deviceAddress;
  SelfInfoResponse? get selfInfo => _selfInfo;

  BleService({
    required BleConnectionManager connectionManager,
    required AppDatabase database,
  })  : _connectionManager = connectionManager,
        _database = database {
    // Listen for connection state changes
    _connectionManager.addListener(_onConnectionStateChanged);
  }

  /// Start scanning for MeshCore devices
  Stream<MeshBleDevice> startScan(
      {Duration timeout = const Duration(seconds: 10)}) {
    return _connectionManager.startScan(timeout: timeout);
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await _connectionManager.stopScan();
  }

  /// Connect to a MeshCore device
  Future<bool> connect(MeshBleDevice device) async {
    final success = await _connectionManager.connect(device);
    if (success) {
      // Subscribe to incoming frames
      _frameSubscription?.cancel();
      _frameSubscription =
          _connectionManager.receivedFrames.listen(_handleFrame);

      // Send APP_START command to initialize session
      await sendAppStart();
    }
    return success;
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    await _frameSubscription?.cancel();
    _frameSubscription = null;
    _selfInfo = null;
    await _connectionManager.disconnect();
    notifyListeners();
  }

  /// Send APP_START command
  Future<bool> sendAppStart() async {
    debugPrint('📤 Sending APP_START command');
    final frame = BleCommands.buildAppStart();
    return await _connectionManager.sendFrame(frame);
  }

  /// Ensure selfInfo is available, request it if needed
  /// Returns true if selfInfo is available or successfully fetched
  Future<bool> ensureSelfInfo(
      {Duration timeout = const Duration(seconds: 3)}) async {
    if (_selfInfo != null) return true;

    debugPrint('[BleService] ⌛ Requesting selfInfo...');

    // Send APP_START to get SELF_INFO response
    final sent = await sendAppStart();
    if (!sent) {
      debugPrint('[BleService] ❌ Failed to send APP_START');
      return false;
    }

    // Wait for response (with timeout)
    final startTime = DateTime.now();
    while (_selfInfo == null) {
      if (DateTime.now().difference(startTime) > timeout) {
        debugPrint('[BleService] ⌛ Timeout waiting for selfInfo');
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    debugPrint('[BleService] ✅ SelfInfo received');
    return true;
  }

  /// Send GET_CONTACTS command
  Future<bool> sendGetContacts() async {
    debugPrint('📤 Sending GET_CONTACTS command');
    final frame = BleCommands.buildGetContacts();
    return await _connectionManager.sendFrame(frame);
  }

  /// Send direct message
  Future<bool> sendDirectMessage(
      List<int> recipientPublicKey, String message) async {
    debugPrint('📤 Sending DM');
    final frame =
        BleCommands.buildSendDirectMessage(recipientPublicKey, message);
    return await _connectionManager.sendFrame(frame);
  }

  /// Send channel message
  Future<bool> sendChannelMessage(int channelIndex, String message) async {
    debugPrint('📤 Sending channel message');
    final frame = BleCommands.buildSendChannelMessage(channelIndex, message);
    return await _connectionManager.sendFrame(frame);
  }

  /// Sync next message from device
  Future<bool> syncNextMessage() async {
    debugPrint('📤 Syncing next message');
    final frame = BleCommands.buildSyncNextMessage();
    return await _connectionManager.sendFrame(frame);
  }

  /// Send SEND_SELF_ADVERT to trigger advertisement exchange / discovery.
  Future<bool> sendSelfAdvert() async {
    debugPrint('📤 Sending SEND_SELF_ADVERT');
    final frame = BleCommands.buildSendSelfAdvert();
    return await _connectionManager.sendFrame(frame);
  }

  /// Get channel info
  Future<bool> getChannel(int channelIndex) async {
    debugPrint('📤 Getting channel info');
    final frame = BleCommands.buildGetChannel(channelIndex);
    return await _connectionManager.sendFrame(frame);
  }

  /// Set channel info
  /// psk should be 16-byte Uint8List
  Future<bool> setChannel(int channelIndex, String name, Uint8List psk) async {
    debugPrint('📤 Setting channel: $name');
    final frame = BleCommands.buildSetChannel(channelIndex, name, psk);
    return await _connectionManager.sendFrame(frame);
  }

  /// Remove contact
  Future<bool> removeContact(List<int> publicKey) async {
    debugPrint('📤 Removing contact');
    final frame = BleCommands.buildRemoveContact(publicKey);
    return await _connectionManager.sendFrame(frame);
  }

  ///Add or update contact
  Future<bool> addUpdateContact({
    required List<int> publicKey,
    required String name,
    int type = 1,
    bool isRepeater = false,
    bool isRoomServer = false,
    bool isDirect = true,
    int hopCount = 0,
    double? latitude,
    double? longitude,
    int? lastSeen,
  }) async {
    debugPrint('📤 Adding/updating contact: $name');
    final frame = BleCommands.buildAddUpdateContact(
      publicKey: publicKey,
      name: name,
      type: type,
      isRepeater: isRepeater,
      isRoomServer: isRoomServer,
      isDirect: isDirect,
      hopCount: hopCount,
      latitude: latitude,
      longitude: longitude,
      lastSeen: lastSeen,
    );
    return await _connectionManager.sendFrame(frame);
  }

  /// Get radio settings
  Future<bool> getRadioSettings() async {
    // Updated firmware embeds radio settings in RESP_SELF_INFO (APP_START).
    // Some older protocol variants had a separate "radio settings" response,
    // but upstream now uses response codes 24/25/26 for stats/autoadd/repeat.
    debugPrint('📤 Refreshing self info (includes radio settings)');
    final frame = BleCommands.buildAppStart();
    return await _connectionManager.sendFrame(frame);
  }

  /// Handle incoming frame
  void _handleFrame(Uint8List frame) async {
    final response = BleResponseParser.parse(frame);
    if (response == null) {
      debugPrint('⚠️ Failed to parse response');
      return;
    }

    debugPrint('📥 Received response: ${response.runtimeType}');

    // Handle different response types
    try {
      if (response is SelfInfoResponse) {
        await _handleSelfInfo(response);
      } else if (response is ContactResponse) {
        await _handleContact(response);
      } else if (response is ChannelInfoResponse) {
        await _handleChannelInfo(response);
      } else if (response is ContactMessageReceivedResponse) {
        await _handleContactMessage(response);
      } else if (response is ChannelMessageReceivedResponse) {
        await _handleChannelMessage(response);
      } else if (response is MessageSentResponse) {
        debugPrint('✅ Message sent');
      } else if (response is SendConfirmedPush) {
        await _handleSendConfirmed(response);
      } else if (response is OkResponse) {
        debugPrint('✅ OK response received');
      }
    } catch (e) {
      debugPrint('❌ Error handling response: $e');
    }
  }

  /// Handle SELF_INFO response
  Future<void> _handleSelfInfo(SelfInfoResponse response) async {
    debugPrint('ℹ️ Self Info: ${response.name}');
    debugPrint('   Frequency: ${response.frequencyMHz} MHz');
    debugPrint('   Bandwidth: ${response.bandwidthKHz} kHz');
    debugPrint(
        '   SF: ${response.spreadingFactor}, CR: ${response.codingRate}');
    debugPrint(
        '   TX Power: ${response.txPower} dBm (max: ${response.maxTxPower})');
    debugPrint('   Position: ${response.latitude}, ${response.longitude}');
    if (response.isCustomFirmware) {
      debugPrint(
          '   Custom Firmware: forwarding=${response.supportsForwarding}, autonomous=${response.supportsAutonomous}');
    }

    _selfInfo = response;
    notifyListeners();
  }

  /// Handle CONTACT response
  Future<void> _handleContact(ContactResponse response) async {
    debugPrint('👤 Contact: ${response.name}');

    // Upsert contact to database
    await _database.contactsDao.upsertContact(
      ContactsCompanion(
        publicKey: drift.Value(response.publicKey),
        name: drift.Value(response.name),
        latitude: drift.Value(response.latitude),
        longitude: drift.Value(response.longitude),
        lastSeen: drift.Value(response.lastSeen),
        isRepeater: drift.Value(response.isRepeater),
        isRoomServer: drift.Value(response.isRoomServer),
        isDirect: drift.Value(response.isDirect),
        hopCount: drift.Value(response.hopCount),
      ),
    );
    // TODO: Store SNR in ContactPositionHistories
  }

  /// Handle CHANNEL_INFO response
  Future<void> _handleChannelInfo(ChannelInfoResponse response) async {
    debugPrint('📣 Channel: ${response.name}');

    // TODO: Store channel info (need channelHash computation from PSK)
//    await _database.channelsDao.upsertChannel(
    //      ChannelsCompanion(
    //        name: drift.Value(response.name),
    //      ),
    //   );
  }

  /// Handle CONTACT_MESSAGE_RECV_V3 response
  Future<void> _handleContactMessage(
      ContactMessageReceivedResponse response) async {
    debugPrint('💬 Contact Message: ${response.text}');

    // TODO: Insert message to database (need UUID generation and full mapping)
    // This will be implemented in Week 4 when we build the messaging UI
    debugPrint('   MessageID: ${response.messageId}');
    debugPrint('   SNR: ${response.snr}, PathLength: ${response.pathLength}');
  }

  /// Handle CHANNEL_MESSAGE_RECV_V3 response
  Future<void> _handleChannelMessage(
      ChannelMessageReceivedResponse response) async {
    debugPrint('📣 Channel Message: ${response.text}');

    // TODO: Insert message to database (need UUID generation and full mapping)
    // This will be implemented in Week 4 when we build the messaging UI
    debugPrint('   MessageID: ${response.messageId}');
    debugPrint('   Channel Index: ${response.channelIndex}');
    debugPrint('   SNR: ${response.snr}, PathLength: ${response.pathLength}');
  }

  /// Handle SEND_CONFIRMED push
  Future<void> _handleSendConfirmed(SendConfirmedPush response) async {
    debugPrint('✅ Send Confirmed: RTT=${response.roundTripTimeMs}ms');
  }

  /// Handle connection state changes
  void _onConnectionStateChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _connectionManager.removeListener(_onConnectionStateChanged);
    super.dispose();
  }
}
