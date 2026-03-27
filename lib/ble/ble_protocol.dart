// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
//
// Portions of this file (BufferReader, BufferWriter) were adapted from:
//   meshcore-open by zjs81
//   https://github.com/zjs81/meshcore-open
//   Copyright (c) 2025 zjs81 — MIT License
// The original MIT-licensed code is used here with modifications for TEAM-Flutter.

import 'dart:convert';
import 'dart:typed_data';

/// Buffer Reader - sequential binary data reader with pointer tracking
/// Borrowed from meshcore-open and simplified for TEAM
class BufferReader {
  int _pointer = 0;
  final Uint8List _buffer;

  BufferReader(Uint8List data) : _buffer = Uint8List.fromList(data);

  int get remaining => _buffer.length - _pointer;
  int get position => _pointer;
  bool get hasRemaining => remaining > 0;

  int readByte() => readBytes(1)[0];

  Uint8List readBytes(int count) {
    if (_pointer + count > _buffer.length) {
      throw Exception(
          'Buffer overflow: trying to read $count bytes, but only $remaining remaining');
    }
    final data = _buffer.sublist(_pointer, _pointer + count);
    _pointer += count;
    return data;
  }

  void skipBytes(int count) {
    _pointer += count;
  }

  Uint8List readRemainingBytes() => readBytes(remaining);

  String readString() {
    final bytes = readRemainingBytes();

    // #TEL: and #T: payloads are Base64-encoded (pure ASCII). Using latin1
    // decoding for them is harmless (ASCII range is identical in both
    // encodings) and avoids any risk of a multi-byte UTF-8 misparse.
    // NOTE: firmware prepends "SENDER: " to channel messages,
    // so the marker may not be at byte 0.
    // #TEL: = 0x23 0x54 0x45 0x4C 0x3A
    // #T:   = 0x23 0x54 0x3A
    const telMarker = <int>[0x23, 0x54, 0x45, 0x4C, 0x3A];
    const topoMarker = <int>[0x23, 0x54, 0x3A];
    bool containsMarker = false;
    if (bytes.length >= topoMarker.length) {
      for (int i = 0; i <= bytes.length - topoMarker.length; i++) {
        // Check #T: first (shorter), then #TEL: (longer; checked implicitly
        // since both share 0x23 0x54 prefix).
        if (bytes[i] == 0x23 && bytes[i + 1] == 0x54) {
          // Could be #T: or #TEL:
          if (i + 2 < bytes.length && bytes[i + 2] == 0x3A) {
            // #T: hit
            containsMarker = true;
            break;
          }
          if (i + 4 < bytes.length &&
              bytes[i + 2] == telMarker[2] &&
              bytes[i + 3] == telMarker[3] &&
              bytes[i + 4] == telMarker[4]) {
            // #TEL: hit
            containsMarker = true;
            break;
          }
        }
      }
    }

    if (containsMarker) {
      return latin1.decode(bytes);
    }

    // Prefer strict UTF-8 for normal messages.
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  String readCString(int maxLength) {
    final value = <int>[];
    int bytesRead = 0;

    while (bytesRead < maxLength && hasRemaining) {
      final byte = readByte();
      bytesRead++;
      if (byte == 0) break; // Stop at null terminator
      value.add(byte);
    }

    try {
      return utf8.decode(Uint8List.fromList(value), allowMalformed: true);
    } catch (e) {
      return String.fromCharCodes(value); // Latin-1 fallback
    }
  }

  int readUInt8() => readBytes(1).buffer.asByteData().getUint8(0);
  int readInt8() => readBytes(1).buffer.asByteData().getInt8(0);

  int readUInt16LE() =>
      readBytes(2).buffer.asByteData().getUint16(0, Endian.little);

  int readUInt32LE() =>
      readBytes(4).buffer.asByteData().getUint32(0, Endian.little);

  int readInt32LE() =>
      readBytes(4).buffer.asByteData().getInt32(0, Endian.little);

  /// Read 24-bit big-endian signed integer (used for GPS coordinates)
  int readInt24BE() {
    var value = (readByte() << 16) | (readByte() << 8) | readByte();
    if ((value & 0x800000) != 0) value -= 0x1000000;
    return value;
  }
}

/// Buffer Writer - accumulating binary data builder
/// Borrowed from meshcore-open and simplified for TEAM
class BufferWriter {
  final BytesBuilder _builder = BytesBuilder();

  Uint8List toBytes() => _builder.toBytes();
  int get length => _builder.length;

  void writeByte(int byte) => _builder.addByte(byte);
  void writeBytes(Uint8List bytes) => _builder.add(bytes);

  void writeUInt16LE(int num) {
    final bytes = Uint8List(2)
      ..buffer.asByteData().setUint16(0, num, Endian.little);
    writeBytes(bytes);
  }

  void writeUInt32LE(int num) {
    final bytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, num, Endian.little);
    writeBytes(bytes);
  }

  void writeInt32LE(int num) {
    final bytes = Uint8List(4)
      ..buffer.asByteData().setInt32(0, num, Endian.little);
    writeBytes(bytes);
  }

  void writeString(String string) =>
      writeBytes(Uint8List.fromList(utf8.encode(string)));

  void writeCString(String string, int maxLength) {
    final bytes = Uint8List(maxLength);
    final encoded = utf8.encode(string);
    for (var i = 0; i < maxLength - 1 && i < encoded.length; i++) {
      bytes[i] = encoded[i];
    }
    writeBytes(bytes);
  }
}

/// Frame utilities for BLE communication
class BleFrameUtils {
  /// Convert bytes to hex string for debugging
  static String bytesToHex(Uint8List bytes, {int? maxLength}) {
    final limit = maxLength ?? bytes.length;
    final displayBytes = bytes.take(limit);
    return displayBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  /// Get response code name for debugging
  static String getResponseName(int code) {
    const names = {
      0: 'OK',
      1: 'ERR',
      2: 'CONTACTS_START',
      3: 'CONTACT',
      4: 'END_OF_CONTACTS',
      5: 'SELF_INFO',
      6: 'SENT',
      7: 'CONTACT_MSG_RECV',
      8: 'CHANNEL_MSG_RECV',
      10: 'NO_MORE_MESSAGES',
      13: 'DEVICE_INFO',
      16: 'CONTACT_MSG_RECV_V3',
      17: 'CHANNEL_MSG_RECV_V3',
      18: 'CHANNEL_INFO',
      24: 'STATS',
      25: 'AUTOADD_CONFIG',
      26: 'ALLOWED_REPEAT_FREQ',
      27: 'AUTONOMOUS_SETTINGS',
      40: 'BATTERY_VOLTAGE',
      100: 'PUSH_NEW_MESSAGE',
      101: 'PUSH_CONTACT_UPDATE',
      102: 'PUSH_CHANNEL_UPDATE',
      103: 'PUSH_WAYPOINT_RECEIVED',
      104: 'PUSH_ACK_RECEIVED',
      // Push codes (async notifications)
      0x80: 'PUSH_ADVERT',
      0x81: 'PUSH_PATH_UPDATED',
      0x82: 'PUSH_SEND_CONFIRMED',
      0x83: 'PUSH_MSG_WAITING',
      0x88: 'PUSH_LOG_RX_DATA',
      0x8A: 'PUSH_NEW_ADVERT',
      0x8B: 'PUSH_TELEMETRY_RESPONSE',
    };
    return names[code] ?? 'UNKNOWN($code)';
  }

  /// Get command code name for debugging
  static String getCommandName(int code) {
    const names = {
      1: 'APP_START',
      2: 'SEND_TXT_MSG',
      3: 'SEND_CHANNEL_TXT_MSG',
      4: 'GET_CONTACTS',
      5: 'GET_DEVICE_TIME',
      6: 'SET_DEVICE_TIME',
      7: 'SEND_SELF_ADVERT',
      8: 'SET_ADVERT_NAME',
      10: 'SYNC_NEXT_MESSAGE',
      14: 'SET_ADVERT_LATLON',
      31: 'GET_CHANNEL',
      32: 'SET_CHANNEL',
      15: 'REMOVE_CONTACT',
      9: 'ADD_UPDATE_CONTACT',
      22: 'DEVICE_QUERY',
      39: 'SEND_TELEMETRY_REQ',
      57: 'SEND_ANON_REQ',
      58: 'SET_AUTOADD_CONFIG',
      59: 'GET_AUTOADD_CONFIG',
      60: 'GET_ALLOWED_REPEAT_FREQ',
      72: 'GET_RADIO_SETTINGS',
      73: 'SET_MAX_HOPS',
      74: 'SET_FORWARD_LIST',
      75: 'GET_AUTONOMOUS_SETTINGS',
      76: 'SET_AUTONOMOUS_SETTINGS',
    };
    return names[code] ?? 'UNKNOWN($code)';
  }
}
