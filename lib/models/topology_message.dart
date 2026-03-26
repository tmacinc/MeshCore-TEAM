// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// #T: topology telemetry message (v2 format).
///
/// Wire format: `#T:` + **unpadded Base64** of the raw binary payload:
///   [lat:4B int32 BE, degrees×10^7]
///   [lon:4B int32 BE, degrees×10^7]
///   [companionBatt:1B, 0/1=unavailable, 2-254=(mV-2750)/6+2, 0xFF=autonomous]
///   [phoneBatt:1B,     same encoding]
///   [nodeCount:1B,     total known network size — determines bitmap length]
///   [neighborBitmap:ceil(nodeCount/8)B, raw bits — no offset needed under base64]
///
/// Base64 transport avoids null-byte (0x00) truncation by C-string firmware
/// layers, matching the approach used by #TEL: (v1).
///
/// The bitmap bit positions correspond to indices in the globally sorted
/// lexicographic pub_key_prefix list maintained by [NetworkTopology].
class TopologyMessage {
  static const String prefix = '#T:';

  // Battery encoding constants (matches TelemetryMessage v1 / Android app).
  static const int _battMinMv = 2750;
  static const int _battStepMv = 6;

  final double? latitude;
  final double? longitude;
  final int? companionBatteryMilliVolts;
  final int? phoneBatteryMilliVolts;

  /// Total size of the known network (number of entries in the sender's
  /// sorted prefix list). Determines how many bytes the bitmap uses.
  final int nodeCount;

  /// Raw neighbor bitmap bytes from the wire.
  /// Bit i set means the node at sorted-list position i is a direct neighbor
  /// of the sender.
  final Uint8List neighborBitmap;

  const TopologyMessage({
    required this.latitude,
    required this.longitude,
    required this.companionBatteryMilliVolts,
    required this.phoneBatteryMilliVolts,
    required this.nodeCount,
    required this.neighborBitmap,
  });

  static bool isTopologyMessage(String text) => text.startsWith(prefix);

  /// Parse a #T: channel message string.
  /// Returns null if the payload is malformed or too short.
  static TopologyMessage? parse(String text) {
    if (!text.startsWith(prefix)) return null;
    try {
      // Payload is Base64-encoded (unpadded). Re-pad then decode.
      final payloadString = text.substring(prefix.length);
      final padded = payloadString.padRight(
        payloadString.length + ((4 - (payloadString.length % 4)) % 4),
        '=',
      );
      final raw = base64.decode(padded);
      if (raw.length < 11) return null; // min: 4+4+1+1+1

      final data = ByteData.sublistView(Uint8List.fromList(raw));
      final latInt = data.getInt32(0, Endian.big);
      final lonInt = data.getInt32(4, Endian.big);
      final compEncoded = raw[8];
      final phoneEncoded = raw[9];
      final nodeCount = raw[10] & 0xFF;

      final bitmapSize = (nodeCount + 7) ~/ 8;
      if (raw.length < 11 + bitmapSize) return null;

      final neighborBitmap =
          Uint8List.fromList(raw.sublist(11, 11 + bitmapSize));

      return TopologyMessage(
        latitude: latInt / 1e7,
        longitude: lonInt / 1e7,
        companionBatteryMilliVolts: _decodeBattery(compEncoded),
        phoneBatteryMilliVolts: _decodeBattery(phoneEncoded),
        nodeCount: nodeCount,
        neighborBitmap: neighborBitmap,
      );
    } catch (_) {
      return null;
    }
  }

  /// Build a #T: binary string from position + pre-built neighbor bitmap.
  ///
  /// [neighborBitmap] and [nodeCount] must be obtained from
  /// [NetworkTopology.buildNeighborBitmap] and [NetworkTopology.getNodeCount].
  /// Returns a Base64-encoded string suitable for BLE channel message transport.
  static String createBinary({
    required double latitude,
    required double longitude,
    int? companionBatteryMilliVolts,
    int? phoneBatteryMilliVolts,
    required Uint8List neighborBitmap,
    required int nodeCount,
  }) {
    final payloadSize = 11 + neighborBitmap.length;
    final bytes = Uint8List(payloadSize);
    final data = ByteData.sublistView(bytes);

    data.setInt32(0, (latitude * 1e7).toInt(), Endian.big);
    data.setInt32(4, (longitude * 1e7).toInt(), Endian.big);
    bytes[8] = _encodeBattery(companionBatteryMilliVolts);
    bytes[9] = _encodeBattery(phoneBatteryMilliVolts);
    bytes[10] = nodeCount & 0xFF;
    bytes.setRange(11, payloadSize, neighborBitmap);

    // Unpadded Base64 keeps payload compact and avoids null-byte truncation.
    final encoded = base64.encode(bytes).replaceAll('=', '');

    debugPrint('[TELSEND #T:] lat=$latitude lon=$longitude'
        ' compBatt=${companionBatteryMilliVolts}mV (enc=0x${bytes[8].toRadixString(16)})'
        ' phoneBatt=${phoneBatteryMilliVolts}mV (enc=0x${bytes[9].toRadixString(16)})'
        ' nodeCount=$nodeCount bitmapLen=${neighborBitmap.length}'
        ' payload=$encoded');

    return prefix + encoded;
  }

  static int _encodeBattery(int? mv) {
    if (mv == null || mv == 0) return 1; // 1 = unavailable
    final clamped = mv.clamp(_battMinMv, _battMinMv + 252 * _battStepMv);
    // Clamp to 254 max — 0xFF (255) is reserved as the autonomous sentinel in #TEL:.
    // KEEP IN SYNC: MeshBleService.encodeBatteryVoltage (Kotlin/Android)
    //               TelemetryMessage._encodeBatteryVoltage (Dart)
    return ((clamped - _battMinMv) ~/ _battStepMv + 2).clamp(2, 254);
  }

  static int? _decodeBattery(int encoded) {
    if (encoded <= 1) return null;
    return _battMinMv + (encoded - 2) * _battStepMv;
  }
}
