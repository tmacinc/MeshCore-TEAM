// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:typed_data';
import 'dart:convert';
import 'package:meshcore_team/ble/ble_constants.dart';
import 'package:meshcore_team/ble/ble_protocol.dart';

/// BLE Command Builders
/// Serializes commands to send to MeshCore companion device
class BleCommands {
  /// Build SET_DEVICE_TIME command
  /// Format: [cmd=6][uint32 unix seconds, little-endian]
  static Uint8List buildSetDeviceTime(int unixSeconds) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSetDeviceTime);
    final bytes = ByteData(4)..setUint32(0, unixSeconds, Endian.little);
    writer.writeBytes(bytes.buffer.asUint8List());
    return writer.toBytes();
  }

  /// Build DEVICE_QUERY command
  /// Queries device capabilities (max contacts, max channels, firmware version, etc.)
  /// Format: [cmd][app_ver]
  static Uint8List buildDeviceQuery() {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdDeviceQuery); // 22
    writer.writeByte(3); // App version / protocol version
    return writer.toBytes();
  }

  /// Build APP_START command
  /// Initializes the BLE session and retrieves self info
  /// Format: [cmd][app_ver][reserved x6][app_name...]
  static Uint8List buildAppStart(
      {String appName = 'TEAMFlutter', int appVersion = 3}) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdAppStart);
    writer.writeByte(appVersion); // App version
    writer.writeBytes(Uint8List(6)); // 6 reserved bytes
    writer.writeCString(appName, 32); // App name (max 32 chars)
    return writer.toBytes();
  }

  /// Build GET_CONTACTS command
  /// Retrieves all contacts from the device
  /// Build GET_CONTACTS command.
  ///
  /// [since]: optional Unix timestamp (seconds). When non-zero the firmware
  /// only streams contacts whose `lastmod > since`, enabling incremental sync.
  /// Format: [cmd]                        — full sync
  ///         [cmd][uint32 LE since]       — incremental sync
  static Uint8List buildGetContacts({int since = 0}) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdGetContacts);
    if (since > 0) {
      writer.writeUInt32LE(since);
    }
    return writer.toBytes();
  }

  /// Build SEND_TEXT_MESSAGE command (direct message)
  /// recipientPublicKey: 32-byte public key (only first 6 bytes used)
  /// message: UTF-8 text message
  /// timestamp: Unix timestamp (seconds since epoch)
  /// attempt: Retry attempt number (0-3)
  /// Format: [cmd][txt_type][attempt][4-byte timestamp][6-byte publicKey PREFIX][text]\0
  static Uint8List buildSendDirectMessage(
    List<int> recipientPublicKey,
    String message, {
    int? timestamp,
    int attempt = 0,
  }) {
    final ts = timestamp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSendTxtMsg);
    writer.writeByte(0); // TXT_TYPE_PLAIN = 0
    writer.writeByte(attempt);
    writer.writeInt32LE(ts); // 4-byte timestamp
    writer.writeBytes(Uint8List.fromList(
        recipientPublicKey.sublist(0, 6))); // Only first 6 bytes!
    writer.writeString(message); // Text message
    writer.writeByte(0); // Null terminator
    return writer.toBytes();
  }

  /// Build SEND_CHANNEL_TEXT_MESSAGE command
  /// channelIndex: channel index (0-based)
  /// message: UTF-8 text message
  /// timestamp: Unix timestamp (seconds since epoch)
  /// Format: [cmd][txt_type][channelIndex][4-byte timestamp][text]
  static Uint8List buildSendChannelMessage(
    int channelIndex,
    String message, {
    int? timestamp,
  }) {
    final ts = timestamp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSendChannelTxtMsg);
    writer.writeByte(0); // TXT_TYPE_PLAIN = 0
    writer.writeByte(channelIndex);
    writer.writeInt32LE(ts); // 4-byte timestamp

    // #TEL: (v1) payload is Base64 (pure ASCII).
    // #T:   (v2) payload is Base64 (pure ASCII).
    // Both are safe to encode as latin1 (identical to UTF-8 in ASCII range).
    if (message.startsWith('#TEL:') || message.startsWith('#T:')) {
      writer.writeBytes(Uint8List.fromList(latin1.encode(message)));
    } else {
      writer.writeString(
          message); // Text message (no null terminator for channel messages)
    }
    return writer.toBytes();
  }

  /// Build SYNC_NEXT_MESSAGE command
  /// Retrieves next unsynced message from device
  static Uint8List buildSyncNextMessage() {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSyncNextMessage);
    return writer.toBytes();
  }

  /// Build GET_CHANNEL command
  /// channelIndex: channel index (0-based)
  static Uint8List buildGetChannel(int channelIndex) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdGetChannel);
    writer.writeByte(channelIndex);
    return writer.toBytes();
  }

  /// Build SET_CHANNEL command
  /// Creates or updates a channel
  /// channelIndex: channel index (0-based)
  /// name: channel name (max 32 bytes, null-padded)
  /// psk: pre-shared key (16 bytes)
  /// Format: [cmd][channelIndex][32-byte name][16-byte PSK]
  static Uint8List buildSetChannel(
      int channelIndex, String name, Uint8List psk) {
    if (psk.length != 16) {
      throw ArgumentError('PSK must be exactly 16 bytes');
    }
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSetChannel);
    writer.writeByte(channelIndex);
    // Write name as fixed 32-byte field (null-padded)
    final nameBytes = name.codeUnits.take(32).toList();
    writer.writeBytes(Uint8List.fromList(nameBytes));
    // Pad to 32 bytes
    for (int i = nameBytes.length; i < 32; i++) {
      writer.writeByte(0);
    }
    writer.writeBytes(psk); // 16-byte PSK
    return writer.toBytes();
  }

  /// Build REMOVE_CONTACT command
  /// publicKey: 32-byte public key of contact to remove
  static Uint8List buildRemoveContact(List<int> publicKey) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdRemoveContact);
    writer.writeBytes(Uint8List.fromList(publicKey)); // 32 bytes
    return writer.toBytes();
  }

  /// Build RESET_PATH command
  /// Clears the stored out-path for a contact on the firmware side, forcing
  /// the next send to that contact to use flood routing.
  /// publicKey: full 32-byte public key of the contact
  /// Format: [cmd][32-byte pubkey]
  static Uint8List buildResetPath(List<int> publicKey) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdResetPath);
    writer.writeBytes(Uint8List.fromList(publicKey)); // 32 bytes
    return writer.toBytes();
  }

  /// Build ADD_UPDATE_CONTACT command
  /// publicKey: 32-byte public key
  /// name: contact name (max 32 bytes)
  /// type: Advertisement type (1 = ADV_TYPE_CHAT)
  /// isRepeater: Whether contact is a repeater
  /// isRoomServer: Whether contact is a room server
  /// isDirect: Whether contact is direct (0 hops)
  /// hopCount: Number of hops to contact
  /// latitude: Contact latitude (optional)
  /// longitude: Contact longitude (optional)
  /// lastSeen: Last seen timestamp in milliseconds
  /// Format: [cmd][32-pubkey][type][flags][path_len][64-path][32-name][4-timestamp][4-lat][4-lon][4-lastmod]
  /// Total: 148 bytes
  /// Build CMD_SET_OTHER_PARAMS (38).
  ///
  /// The firmware rewrites all of these together, so every value must be
  /// passed, not just the one being changed. Read the current ones from
  /// RESP_SELF_INFO.
  ///
  /// [manualAddContacts] bit 0 set = stop auto-adding every contact heard.
  static Uint8List buildSetOtherParams({
    required int manualAddContacts,
    required int telemetryModes,
    required int advertLocPolicy,
    required int multiAcks,
  }) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSetOtherParams);
    writer.writeByte(manualAddContacts & 0xFF);
    writer.writeByte(telemetryModes & 0xFF);
    writer.writeByte(advertLocPolicy & 0xFF);
    writer.writeByte(multiAcks & 0xFF);
    return writer.toBytes();
  }

  /// Build CMD_GET_AUTO_ADD_CONFIG (59).
  static Uint8List buildGetAutoAddConfig() {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdGetAutoAddConfig);
    return writer.toBytes();
  }

  /// Build CMD_SET_AUTO_ADD_CONFIG (58). Per-type auto-add bits, consulted
  /// only when manual-add is on: 0x01 overwrite-oldest, 0x02 chat,
  /// 0x04 repeater, 0x08 room server, 0x10 sensor.
  static Uint8List buildSetAutoAddConfig(int config) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSetAutoAddConfig);
    writer.writeByte(config & 0xFF);
    return writer.toBytes();
  }

  /// Turns a PUSH_NEW_ADVERT (0x8A) frame into CMD_ADD_UPDATE_CONTACT.
  ///
  /// The firmware sends that push only when it did NOT store the contact
  /// (manual-add mode, past the auto-add hop limit, or a full contact table),
  /// and its payload is byte-identical to the add-contact command from byte 1
  /// on: pubkey, type, flags, out_path_len, out_path, name, last_advert,
  /// lat, lon, lastmod. So adding the contact in software is the same bytes
  /// with a different opcode, which keeps the radio's own values (including
  /// the unknown/flood path) exactly as the advert delivered them.
  static Uint8List buildAddUpdateContactFromAdvert(Uint8List pushFrame) {
    final frame = Uint8List.fromList(pushFrame);
    frame[0] = BleConstants.cmdAddUpdateContact;
    return frame;
  }

  /// Build CMD_ADD_UPDATE_CONTACT (9) for a contact whose key we already
  /// hold — used to carry team contacts onto a newly paired radio.
  ///
  /// Layout after the opcode: pubkey(32), type, flags, out_path_len,
  /// out_path(64), name(32), last_advert(4), lat(4), lon(4).
  ///
  /// The route is sent as unknown (0xFF) so the radio floods until it learns
  /// one. Sending a hop count with an empty path instead would hand the radio
  /// a route that goes nowhere. Flags are the firmware's contact flags, not
  /// repeater/room-server bits — those live in [type].
  static Uint8List buildAddUpdateContact({
    required List<int> publicKey,
    required String name,
    int type = 1, // ADV_TYPE_CHAT
    int flags = 0,
    int? lastAdvertTimestamp,
    double? latitude,
    double? longitude,
  }) {
    const outPathUnknown = 0xFF;

    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdAddUpdateContact);
    writer.writeBytes(Uint8List.fromList(publicKey));
    writer.writeByte(type);
    writer.writeByte(flags);
    writer.writeByte(outPathUnknown);
    writer.writeBytes(Uint8List(64)); // empty path

    // Name: UTF-8, null-padded to 32 bytes, truncated on a byte boundary.
    final nameBytes = utf8.encode(name).take(31).toList();
    final nameField = Uint8List(32);
    nameField.setRange(0, nameBytes.length, nameBytes);
    writer.writeBytes(nameField);

    writer.writeInt32LE(
        lastAdvertTimestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000);
    writer.writeInt32LE(((latitude ?? 0) * 1e6).round());
    writer.writeInt32LE(((longitude ?? 0) * 1e6).round());
    return writer.toBytes();
  }

  /// Build SEND_SELF_ADVERT command
  /// Broadcast telemetry/discovery message
  /// [flood]: when true the advert is flood-routed (multi-hop); when false it
  ///         is sent as a zero-hop local broadcast only.
  /// Format: [cmd][flood_flag]
  static Uint8List buildSendSelfAdvert({bool flood = true}) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSendSelfAdvert);
    writer.writeByte(flood ? 1 : 0);
    return writer.toBytes();
  }

  /// Build SET_ADVERT_NAME command
  /// name: device name to advertise (max 32 bytes, null-padded)
  /// Format: [cmd][32-byte name]
  static Uint8List buildSetAdvertName(String name) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSetAdvertName);
    // Write name as fixed 32-byte field (null-padded)
    final nameBytes = name.codeUnits.take(32).toList();
    writer.writeBytes(Uint8List.fromList(nameBytes));
    // Pad to 32 bytes
    for (int i = nameBytes.length; i < 32; i++) {
      writer.writeByte(0);
    }
    return writer.toBytes();
  }

  /// Build SET_ADVERT_LATLON command
  /// latitude: degrees (-90 to 90)
  /// longitude: degrees (-180 to 180)
  /// Format: [cmd][4-byte lat * 1000000][4-byte lon * 1000000]
  static Uint8List buildSetAdvertLatLon(double latitude, double longitude) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSetAdvertLatLon);
    writer
        .writeInt32LE((latitude * 1000000).round()); // Convert to microdegrees
    writer
        .writeInt32LE((longitude * 1000000).round()); // Convert to microdegrees
    return writer.toBytes();
  }

  /// Build REBOOT command
  /// Matches Android TEAM: [cmd]['reboot' UTF-8]
  static Uint8List buildReboot() {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdReboot);
    writer.writeBytes(Uint8List.fromList(utf8.encode('reboot')));
    return writer.toBytes();
  }

  /// Build SET_RADIO_PARAMS command
  /// Sets LoRa radio parameters
  static Uint8List buildSetRadioParams({
    required double frequencyMHz,
    required double bandwidthKHz,
    required int spreadingFactor,
    required int codingRate,
    bool enableClientRepeat = false,
  }) {
    final frequencyKHz = (frequencyMHz * 1000).round();
    final bandwidthHz = (bandwidthKHz * 1000).round();

    if (frequencyKHz < 300 || frequencyKHz > 2500000) {
      throw ArgumentError(
          'Frequency must be 300-2500000 kHz (got $frequencyKHz)');
    }
    if (bandwidthHz < 7000 || bandwidthHz > 500000) {
      throw ArgumentError(
          'Bandwidth must be 7000-500000 Hz (got $bandwidthHz)');
    }
    if (spreadingFactor < 5 || spreadingFactor > 12) {
      throw ArgumentError(
          'Spreading factor must be 5-12 (got $spreadingFactor)');
    }
    if (codingRate < 5 || codingRate > 8) {
      throw ArgumentError('Coding rate must be 5-8 (got $codingRate)');
    }

    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSetRadioParams);
    writer.writeUInt32LE(frequencyKHz);
    writer.writeUInt32LE(bandwidthHz);
    writer.writeByte(spreadingFactor);
    writer.writeByte(codingRate);
    writer.writeByte(enableClientRepeat ? 1 : 0);
    return writer.toBytes();
  }

  /// Build SET_RADIO_TX_POWER command
  /// txPower: transmit power in dBm
  static Uint8List buildSetRadioTxPower(int txPower) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSetRadioTxPower);
    writer.writeByte(txPower);
    return writer.toBytes();
  }

  /// Build SET_MAX_HOPS command
  /// maxHops: maximum hop count for flood routing
  static Uint8List buildSetMaxHops(int maxHops) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSetMaxHops);
    writer.writeByte(maxHops);
    return writer.toBytes();
  }

  /// Build SET_FORWARD_LIST command
  /// pubKeyPrefixes: list of 6-byte public key prefixes
  /// Format: [cmd][count][prefix1..prefixN]
  static Uint8List buildSetForwardList(List<Uint8List> pubKeyPrefixes) {
    if (pubKeyPrefixes.length > 255) {
      throw ArgumentError('Forward list count must be <= 255');
    }

    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSetForwardList);
    writer.writeByte(pubKeyPrefixes.length);

    for (final prefix in pubKeyPrefixes) {
      if (prefix.length < 6) {
        throw ArgumentError(
            'Each forward-list entry must include at least 6 bytes');
      }
      writer.writeBytes(Uint8List.fromList(prefix.sublist(0, 6)));
    }

    return writer.toBytes();
  }

  /// Build GET_AUTONOMOUS_SETTINGS command
  static Uint8List buildGetAutonomousSettings() {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdGetAutonomousSettings);
    return writer.toBytes();
  }

  /// Build SET_AUTONOMOUS_SETTINGS command
  /// Format: [cmd][enabled][channel_hash][interval_sec u16 LE][min_distance_m u16 LE]
  static Uint8List buildSetAutonomousSettings({
    required bool enabled,
    required int channelHash,
    required int intervalSec,
    required int minDistanceMeters,
  }) {
    if (channelHash < 0 || channelHash > 255) {
      throw ArgumentError('channelHash must be 0..255');
    }
    if (intervalSec < 0 || intervalSec > 65535) {
      throw ArgumentError('intervalSec must be 0..65535');
    }
    if (minDistanceMeters < 0 || minDistanceMeters > 65535) {
      throw ArgumentError('minDistanceMeters must be 0..65535');
    }

    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSetAutonomousSettings);
    writer.writeByte(enabled ? 1 : 0);
    writer.writeByte(channelHash);
    writer.writeUInt16LE(intervalSec);
    writer.writeUInt16LE(minDistanceMeters);
    return writer.toBytes();
  }

  /// Build SEND_TELEMETRY_REQ command
  /// Request self-telemetry from companion device (GPS, battery, etc.)
  /// Format: [cmd][3 reserved bytes]
  /// Total: 4 bytes
  /// Note: This queries the companion device itself, not a remote contact
  static Uint8List buildSendTelemetryReq() {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSendTelemetryReq);
    writer.writeBytes(Uint8List(3)); // 3 reserved bytes
    return writer.toBytes();
  }

  /// Build SET_CUSTOM_VAR command
  /// Format: [cmd][ASCII "key:value"]
  /// Firmware null-terminates the frame buffer, so no null terminator is needed here.
  static Uint8List buildSetCustomVar(String key, String value) {
    final writer = BufferWriter();
    writer.writeByte(BleConstants.cmdSetCustomVar);
    writer.writeString('$key:$value');
    return writer.toBytes();
  }
}
