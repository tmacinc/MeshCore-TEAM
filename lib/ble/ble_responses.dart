// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:meshcore_team/ble/ble_constants.dart';
import 'package:meshcore_team/ble/ble_protocol.dart';

/// Base response type
abstract class BleResponse {
  final int responseCode;
  BleResponse(this.responseCode);
}

/// OK response (respOk = 0)
class OkResponse extends BleResponse {
  OkResponse() : super(BleConstants.respOk);
}

/// Self Info response (respSelfInfo = 5)
/// Response to CMD_APP_START
class SelfInfoResponse extends BleResponse {
  final Uint8List publicKey; // 32 bytes
  final String name;
  final int txPower; // Current TX power (dBm)
  final int maxTxPower; // Device maximum TX power (dBm)
  final int frequencyHz; // Frequency in kHz
  final int bandwidthHz; // Bandwidth in Hz
  final int spreadingFactor; // 5-12
  final int codingRate; // 5-8
  final double latitude; // Device latitude
  final double longitude; // Device longitude
  final int capabilities; // Firmware capability flags (0 = stock)

  // Capability flags
  static const int capabilityForwarding = 0x01;
  static const int capabilityAutonomous = 0x02;

  SelfInfoResponse({
    required this.publicKey,
    required this.name,
    required this.txPower,
    required this.maxTxPower,
    required this.frequencyHz,
    required this.bandwidthHz,
    required this.spreadingFactor,
    required this.codingRate,
    required this.latitude,
    required this.longitude,
    required this.capabilities,
  }) : super(BleConstants.respSelfInfo);

  // Helper properties
  double get frequencyMHz => frequencyHz / 1000.0;
  double get bandwidthKHz => bandwidthHz / 1000.0;
  bool get supportsForwarding => (capabilities & capabilityForwarding) != 0;
  bool get supportsAutonomous => (capabilities & capabilityAutonomous) != 0;
  bool get isCustomFirmware => capabilities != 0;
}

/// Device info response (respDeviceInfo = 13)
/// Response to CMD_DEVICE_QUERY
class DeviceInfoResponse extends BleResponse {
  final int firmwareVersion;
  final int maxContacts;
  final int maxChannels;
  final int blePin;
  final String buildDate;
  final String manufacturer;
  final String versionString;

  DeviceInfoResponse({
    required this.firmwareVersion,
    required this.maxContacts,
    required this.maxChannels,
    required this.blePin,
    required this.buildDate,
    required this.manufacturer,
    required this.versionString,
  }) : super(BleConstants.respDeviceInfo);
}

/// Contact response (respContact = 3)
class ContactResponse extends BleResponse {
  final Uint8List publicKey; // 32 bytes
  final String name;
  final double? latitude; // null if no position
  final double? longitude; // null if no position
  final int lastSeen; // Unix timestamp (seconds)
  final int
      lastmod; // Firmware lastmod timestamp (seconds) — used for incremental sync
  final int snr; // Signal-to-noise ratio
  final bool isRepeater;
  final bool isRoomServer;
  final bool isDirect;
  final int hopCount;

  ContactResponse({
    required this.publicKey,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.lastSeen,
    required this.lastmod,
    required this.snr,
    required this.isRepeater,
    required this.isRoomServer,
    required this.isDirect,
    required this.hopCount,
  }) : super(BleConstants.respContact);
}

/// Channel Info response (respChannelInfo = 18)
class ChannelInfoResponse extends BleResponse {
  final int channelIndex; // 0-based channel index
  final String name;
  final String psk; // Base64 encoded 16-byte binary PSK

  ChannelInfoResponse({
    required this.channelIndex,
    required this.name,
    required this.psk,
  }) : super(BleConstants.respChannelInfo);
}

/// Contact Message Received V3 response (respContactMsgRecvV3 = 16)
class ContactMessageReceivedResponse extends BleResponse {
  final int messageId;
  final Uint8List senderPublicKey; // 32 bytes
  final Uint8List? receiverPublicKey; // 32 bytes, null if DM to self
  final int timestamp; // Unix timestamp
  final String text;
  final int snr;
  final int pathLength;
  final bool isFromSelf;

  ContactMessageReceivedResponse({
    required this.messageId,
    required this.senderPublicKey,
    this.receiverPublicKey,
    required this.timestamp,
    required this.text,
    required this.snr,
    required this.pathLength,
    required this.isFromSelf,
  }) : super(BleConstants.respContactMsgRecvV3);
}

/// Channel Message Received V3 response (respChannelMsgRecvV3 = 17)
class ChannelMessageReceivedResponse extends BleResponse {
  final int messageId;
  final int channelIndex; // 0-based channel index
  final Uint8List? senderPublicKey; // 32 bytes, null if anonymous
  final int timestamp; // Unix timestamp
  final String text;
  final int snr;
  final int pathLength;
  final bool isFromSelf;

  ChannelMessageReceivedResponse({
    required this.messageId,
    required this.channelIndex,
    this.senderPublicKey,
    required this.timestamp,
    required this.text,
    required this.snr,
    required this.pathLength,
    required this.isFromSelf,
  }) : super(BleConstants.respChannelMsgRecvV3);
}

/// Stats response (respStats = 24)
/// Format: [0x18][stats_type][payload...]
class StatsResponse extends BleResponse {
  final int statsType;
  final Uint8List payload;

  StatsResponse({
    required this.statsType,
    required this.payload,
  }) : super(BleConstants.respStats);
}

/// Auto-add config response (respAutoAddConfig = 25)
/// Format: [0x19][autoadd_config]
class AutoAddConfigResponse extends BleResponse {
  final int autoAddConfig;

  AutoAddConfigResponse({
    required this.autoAddConfig,
  }) : super(BleConstants.respAutoAddConfig);
}

/// Allowed repeat frequency response (respAllowedRepeatFreq = 26)
/// Format: [0x1A][lower u32][upper u32]...
class AllowedRepeatFreqResponse extends BleResponse {
  final List<({int lowerHz, int upperHz})> ranges;

  AllowedRepeatFreqResponse({
    required this.ranges,
  }) : super(BleConstants.respAllowedRepeatFreq);
}

/// Autonomous settings response (respAutonomousSettings = 27)
/// Format: [0x1B][enabled][channel_hash][interval_sec u16 LE][min_distance_m u16 LE]
class AutonomousSettingsResponse extends BleResponse {
  final bool enabled;
  final int channelHash;
  final int intervalSec;
  final int minDistanceMeters;

  AutonomousSettingsResponse({
    required this.enabled,
    required this.channelHash,
    required this.intervalSec,
    required this.minDistanceMeters,
  }) : super(BleConstants.respAutonomousSettings);
}

/// Message Sent response (respSent = 6)
/// Format: [0x06][flood flag][4-byte expected ACK][4-byte timeout ms]
class MessageSentResponse extends BleResponse {
  final bool success;
  final bool isFlood;
  final Uint8List? expectedAck; // 4 bytes - firmware calculates this
  final int? timeoutMs;

  MessageSentResponse({
    required this.success,
    this.isFlood = false,
    this.expectedAck,
    this.timeoutMs,
  }) : super(BleConstants.respSent);
}

/// Push: Send Confirmed (pushCodeSendConfirmed = 0x82)
/// Format: [0x82][4-byte ACK checksum][4-byte RTT ms]
class SendConfirmedPush extends BleResponse {
  final Uint8List ackChecksum; // 4 bytes
  final int roundTripTimeMs;

  SendConfirmedPush({
    required this.ackChecksum,
    required this.roundTripTimeMs,
  }) : super(BleConstants.pushCodeSendConfirmed);
}

/// BLE Response Parser
/// Parses BLE frames received from MeshCore companion device
class BleResponseParser {
  /// Parse a received frame into a typed response
  static BleResponse? parse(Uint8List frame) {
    if (frame.isEmpty) return null;

    final reader = BufferReader(frame);
    final responseCode = reader.readByte();

    // Debug logging for channel responses
    if (responseCode == BleConstants.respChannelInfo) {
      debugPrint(
          '[Parser] 🔧 Parsing RESP_CHANNEL_INFO(18), frame length: ${frame.length}');
    }

    try {
      switch (responseCode) {
        case BleConstants.respOk:
          return OkResponse();

        case BleConstants.respDeviceInfo:
          return _parseDeviceInfo(reader);

        case BleConstants.respSelfInfo:
          return _parseSelfInfo(reader);

        case BleConstants.respContact:
          return _parseContact(reader);

        case BleConstants.respChannelInfo:
          return _parseChannelInfo(reader);

        case BleConstants.respContactMsgRecvV3:
          return _parseContactMessageV3(reader);

        case BleConstants.respChannelMsgRecvV3:
          return _parseChannelMessageV3(reader);

        case BleConstants.respStats:
          return _parseStats(reader);

        case BleConstants.respAutoAddConfig:
          return _parseAutoAddConfig(reader);

        case BleConstants.respAllowedRepeatFreq:
          return _parseAllowedRepeatFreq(reader);

        case BleConstants.respAutonomousSettings:
          return _parseAutonomousSettings(reader);

        case BleConstants.respSent:
          return _parseMessageSent(reader);

        case BleConstants.pushCodeSendConfirmed:
          return _parseSendConfirmed(reader);

        default:
          return null;
      }
    } catch (e) {
      debugPrint('[Parser] ❌ Parse error for response code $responseCode: $e');
      return null;
    }
  }

  static DeviceInfoResponse _parseDeviceInfo(BufferReader reader) {
    final firmwareVersion = reader.readByte();
    final maxContactsRaw = reader.readByte();
    final maxContacts = maxContactsRaw * 2; // Firmware divides by 2
    final maxChannels = reader.readByte();

    final blePin = reader.readUInt32LE();
    final buildDate = reader.readCString(12);
    final manufacturer = reader.readCString(40);
    final versionString = reader.readCString(20);

    debugPrint(
        '[Parser] 📱 DEVICE_INFO: FW v$firmwareVersion, maxContacts=$maxContacts, maxChannels=$maxChannels');
    debugPrint(
        '[Parser]    Build: $buildDate, Mfr: $manufacturer, Ver: $versionString');

    return DeviceInfoResponse(
      firmwareVersion: firmwareVersion,
      maxContacts: maxContacts,
      maxChannels: maxChannels,
      blePin: blePin,
      buildDate: buildDate,
      manufacturer: manufacturer,
      versionString: versionString,
    );
  }

  static SelfInfoResponse _parseSelfInfo(BufferReader reader) {
    // Byte 1: adv_type (skip)
    reader.readByte();

    // Bytes 2-3: TX power settings
    final txPower = reader.readByte();
    final maxTxPower = reader.readByte();

    // Bytes 4-35: Public key (32 bytes)
    final publicKey = reader.readBytes(32);

    // Bytes 36-39: Latitude (int32 LE, * 1000000)
    final latitude = reader.readInt32LE() / 1e6;

    // Bytes 40-43: Longitude (int32 LE, * 1000000)
    final longitude = reader.readInt32LE() / 1e6;

    // Bytes 44-47: Flags (skip)
    reader.readBytes(4);

    // Bytes 48-51: Frequency Hz (uint32 LE)
    final frequencyHz = reader.readUInt32LE();

    // Bytes 52-55: Bandwidth Hz (uint32 LE)
    final bandwidthHz = reader.readUInt32LE();

    // Byte 56: Spreading factor
    final spreadingFactor = reader.readByte();

    // Byte 57: Coding rate
    final codingRate = reader.readByte();

    // Byte 58+: Node name (null-terminated string)
    final name = reader.readCString(64);

    // After name + null terminator: Capabilities byte (if present)
    final capabilities = reader.hasRemaining ? reader.readByte() : 0;

    return SelfInfoResponse(
      publicKey: publicKey,
      name: name,
      txPower: txPower,
      maxTxPower: maxTxPower,
      frequencyHz: frequencyHz,
      bandwidthHz: bandwidthHz,
      spreadingFactor: spreadingFactor,
      codingRate: codingRate,
      latitude: latitude,
      longitude: longitude,
      capabilities: capabilities,
    );
  }

  static ContactResponse _parseContact(BufferReader reader) {
    // Bytes 1-32: Public key
    final publicKey = reader.readBytes(32);
    final publicKeyHex =
        publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // Bytes 33-35: type, flags, path_len
    final contactType =
        reader.readByte(); // ADV_TYPE_* (see firmware AdvertDataHelpers.h)
    final flags = reader.readByte(); // ContactInfo.flags (firmware-defined)
    final outPathLen =
        reader.readInt8(); // ContactInfo.out_path_len (-1 = unknown)

    // In firmware, repeater/room-server identity is exclusively encoded via contactType:
    //   2 = ADV_TYPE_REPEATER, 3 = ADV_TYPE_ROOM  (see AdvertDataHelpers.h)
    // flags bit 0 is the firmware "favourite" bit — NOT a repeater indicator.
    // Using flags as a fallback incorrectly marks favourited chat contacts as repeaters.
    final isRepeater = contactType == 2;
    final isRoomServer = contactType == 3;

    final hopCount = outPathLen;
    final isDirect = hopCount == 0;

    // Bytes 36-99: path (64 bytes, skip)
    reader.readBytes(64);

    // Bytes 100-131: Name (32 bytes, null-terminated)
    final nameBytes = reader.readBytes(32);
    debugPrint(
        '[Parser] 🔍 Contact name bytes: ${nameBytes.take(32).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    int nullIndex = nameBytes.indexOf(0);
    final name = nullIndex >= 0
        ? String.fromCharCodes(nameBytes.sublist(0, nullIndex))
        : String.fromCharCodes(nameBytes).trim();
    debugPrint(
        '[Parser] 📝 Contact name parsed: "$name" (${name.length} chars) for key ${publicKeyHex.substring(0, 8)}');

    // Bytes 132-135: timestamp
    final lastSeen = reader.readUInt32LE();

    // Bytes 136-139: Latitude (int32 LE)
    final latInt = reader.readInt32LE();
    final latitude = latInt != 0 ? latInt / 1e6 : null;

    // Bytes 140-143: Longitude (int32 LE)
    final lonInt = reader.readInt32LE();
    final longitude = lonInt != 0 ? lonInt / 1e6 : null;

    // Bytes 144-147: lastmod (incremental sync filter)
    final lastmod = reader.readUInt32LE();

    final snr = reader.hasRemaining ? reader.readInt8() : 0;

    return ContactResponse(
      publicKey: publicKey,
      name: name,
      latitude: latitude,
      longitude: longitude,
      lastSeen: lastSeen,
      lastmod: lastmod,
      snr: snr,
      isRepeater: isRepeater,
      isRoomServer: isRoomServer,
      isDirect: isDirect,
      hopCount: hopCount,
    );
  }

  static ChannelInfoResponse _parseChannelInfo(BufferReader reader) {
    debugPrint(
        '[Parser] 🔧 _parseChannelInfo started, remaining bytes: ${reader.remaining}');

    final channelIndex = reader.readByte();
    debugPrint('[Parser] 🔧 Channel index: $channelIndex');

    // Name is a fixed 32-byte field (null-terminated within)
    final nameBytes = reader.readBytes(32);
    final nullIndex = nameBytes.indexOf(0);
    final name = nullIndex >= 0
        ? utf8.decode(nameBytes.sublist(0, nullIndex))
        : utf8.decode(nameBytes).trim();
    debugPrint('[Parser] 🔧 Channel name: "$name"');

    // PSK is a fixed 16-byte binary field
    final pskBytes = reader.readBytes(16);
    final psk = base64.encode(pskBytes);
    debugPrint('[Parser] 🔧 Channel PSK length: ${pskBytes.length} bytes');

    final response = ChannelInfoResponse(
      channelIndex: channelIndex,
      name: name,
      psk: psk,
    );

    debugPrint('[Parser] ✅ ChannelInfoResponse created successfully');
    return response;
  }

  static ContactMessageReceivedResponse _parseContactMessageV3(
      BufferReader reader) {
    // V3 Format: [resp_code][snr][reserved1][reserved2][6-byte sender_pubkey_prefix][path_len][txt_type][timestamp 4 bytes][text]
    final snr = reader.readInt8();
    reader.readByte(); // reserved1
    reader.readByte(); // reserved2
    final senderPubKeyPrefix = reader.readBytes(6); // 6-byte prefix
    final pathLength = reader.readByte();
    final txtType = reader.readByte(); // txt_type (ignored for now)
    final timestamp = reader.readUInt32LE();

    // Read remaining bytes as text
    final text = reader.readString();

    // Pad 6-byte prefix to 32 bytes
    final senderPublicKey = Uint8List(32);
    senderPublicKey.setRange(0, 6, senderPubKeyPrefix);

    return ContactMessageReceivedResponse(
      messageId: 0, // V3 doesn't have messageId
      senderPublicKey: senderPublicKey,
      receiverPublicKey: null,
      timestamp: timestamp,
      text: text,
      snr: snr,
      pathLength: pathLength,
      isFromSelf: false, // V3 doesn't indicate this
    );
  }

  static ChannelMessageReceivedResponse _parseChannelMessageV3(
      BufferReader reader) {
    // V3 Format: [resp_code][snr][reserved1][reserved2][channel_idx][path_len][txt_type][timestamp 4 bytes][text]
    final snr = reader.readInt8();
    reader.readByte(); // reserved1
    reader.readByte(); // reserved2
    final channelIndex = reader.readByte();
    final pathLength = reader.readByte();
    final txtType = reader.readByte(); // txt_type (ignored for now)
    final timestamp = reader.readUInt32LE();

    // Read remaining bytes as text
    final text = reader.readString();

    return ChannelMessageReceivedResponse(
      messageId: 0, // V3 doesn't have messageId
      channelIndex: channelIndex,
      senderPublicKey: null, // V3 doesn't include sender in channel messages
      timestamp: timestamp,
      text: text,
      snr: snr,
      pathLength: pathLength,
      isFromSelf: false, // V3 doesn't indicate this
    );
  }

  static StatsResponse _parseStats(BufferReader reader) {
    // stats_type is required
    final statsType = reader.readByte();
    final payload = reader.readRemainingBytes();
    return StatsResponse(statsType: statsType, payload: payload);
  }

  static AutoAddConfigResponse _parseAutoAddConfig(BufferReader reader) {
    final cfg = reader.readByte();
    return AutoAddConfigResponse(autoAddConfig: cfg);
  }

  static AllowedRepeatFreqResponse _parseAllowedRepeatFreq(
      BufferReader reader) {
    final ranges = <({int lowerHz, int upperHz})>[];
    while (reader.remaining >= 8) {
      final lower = reader.readUInt32LE();
      final upper = reader.readUInt32LE();
      ranges.add((lowerHz: lower, upperHz: upper));
    }
    return AllowedRepeatFreqResponse(ranges: ranges);
  }

  static AutonomousSettingsResponse _parseAutonomousSettings(
      BufferReader reader) {
    final enabled = reader.readByte() != 0;
    final channelHash = reader.readByte();
    final intervalSec = reader.readUInt16LE();
    final minDistanceMeters = reader.readUInt16LE();

    return AutonomousSettingsResponse(
      enabled: enabled,
      channelHash: channelHash,
      intervalSec: intervalSec,
      minDistanceMeters: minDistanceMeters,
    );
  }

  static MessageSentResponse _parseMessageSent(BufferReader reader) {
    // Format: [flood flag][4-byte expected ACK][4-byte timeout ms]
    // Note: response code (0x06) already consumed by parser
    final floodFlag = reader.readByte();
    final expectedAck = reader.readBytes(4);
    final timeoutMs = reader.readUInt32LE();

    return MessageSentResponse(
      success: true,
      isFlood: floodFlag != 0,
      expectedAck: expectedAck,
      timeoutMs: timeoutMs,
    );
  }

  static SendConfirmedPush _parseSendConfirmed(BufferReader reader) {
    // Format: [4-byte ACK checksum][4-byte RTT ms]
    // Note: response code (0x82) already consumed by parser
    final ackChecksum = reader.readBytes(4); // 4 bytes, not 16
    final roundTripTimeMs = reader.readUInt32LE();

    return SendConfirmedPush(
      ackChecksum: ackChecksum,
      roundTripTimeMs: roundTripTimeMs,
    );
  }
}
