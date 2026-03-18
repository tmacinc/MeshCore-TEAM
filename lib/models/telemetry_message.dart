// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// TEAM Android-compatible telemetry message.
///
/// V2 payload (after prefix) is Base64 of 11 raw bytes:
/// [lat:4B][lon:4B][compBatt:1B][phoneBatt:1B][fwdStatus:1B]
///
/// IMPORTANT:
/// - Payload is Base64 to avoid null-byte/C-string truncation in transport.
/// - Battery and forwarding status bytes are offset to avoid 0x00 in raw bytes.
class TelemetryMessage {
  static const String prefix = '#TEL:';

  static const int binaryPayloadSize = 11;

  static const int _batteryVoltageMinMv = 2750;
  static const int _batteryVoltageMaxMv = 4280;
  static const int _batteryStepMv = 6;

  final double? latitude;
  final double? longitude;
  final int? companionBatteryMilliVolts;
  final int? phoneBatteryMilliVolts;

  final bool needsForwarding;
  final int maxPathObserved;

  /// True when [fwdStatus] byte is the autonomous sentinel (0xFF).
  /// Autonomous devices send this value to identify themselves without
  /// needing a separate #CAP: advertisement on every beacon.
  final bool isAutonomousDevice;

  const TelemetryMessage({
    required this.latitude,
    required this.longitude,
    required this.companionBatteryMilliVolts,
    required this.phoneBatteryMilliVolts,
    required this.needsForwarding,
    required this.maxPathObserved,
    this.isAutonomousDevice = false,
  });

  static bool isTelemetryMessage(String text) => text.startsWith(prefix);

  static TelemetryMessage? parse(String text) {
    if (!text.startsWith(prefix)) return null;

    final payloadString = text.substring(prefix.length);

    try {
      final normalized = payloadString.padRight(
        payloadString.length + ((4 - (payloadString.length % 4)) % 4),
        '=',
      );
      final raw = base64.decode(normalized);
      return _parseRawPayload(raw);
    } catch (_) {
      return null;
    }
  }

  /// Create a binary telemetry string compatible with TEAM Android.
  ///
  /// The returned String must be sent over BLE using latin1 encoding.
  static String createBinary({
    required double latitude,
    required double longitude,
    int? companionBatteryMilliVolts,
    int? phoneBatteryMilliVolts,
    bool needsForwarding = false,
    int maxPathObserved = 0,
  }) {
    final payload = Uint8List(binaryPayloadSize);
    final data = ByteData.sublistView(payload);

    final latInt = (latitude * 1e7).toInt();
    final lonInt = (longitude * 1e7).toInt();

    data.setInt32(0, latInt, Endian.big);
    data.setInt32(4, lonInt, Endian.big);
    payload[8] = _encodeBatteryVoltage(companionBatteryMilliVolts);
    payload[9] = _encodeBatteryVoltage(phoneBatteryMilliVolts);

    payload[10] = _encodeForwardingStatus(
        needsForwarding: needsForwarding, maxPathObserved: maxPathObserved);

    // Unpadded Base64 keeps payload compact and avoids transport truncation on 0x00.
    final encoded = base64.encode(payload).replaceAll('=', '');

    debugPrint('[TELSEND] lat=$latitude lon=$longitude'
        ' compBatt=${companionBatteryMilliVolts}mV (enc=0x${payload[8].toRadixString(16)})'
        ' phoneBatt=${phoneBatteryMilliVolts}mV (enc=0x${payload[9].toRadixString(16)})'
        ' fwdStatus=0x${payload[10].toRadixString(16)}'
        ' payload=$encoded');

    return prefix + encoded;
  }

  static TelemetryMessage? _parseRawPayload(List<int> bytes) {
    if (bytes.length != binaryPayloadSize) return null;

    final payload = Uint8List.fromList(bytes);
    final data = ByteData.sublistView(payload);

    try {
      final latInt = data.getInt32(0, Endian.big);
      final lonInt = data.getInt32(4, Endian.big);
      final compBatt = payload[8];
      final phoneBatt = payload[9];
      final fwdStatusRaw = payload[10];

      // phone battery 0xFF is the autonomous sentinel: device is in autonomous
      // mode with no phone attached. Normal encoded values are 0 (unknown)
      // or 1-254 (decoded from actual voltage).
      final isAutonomous = phoneBatt == 0xFF;

      final decoded = _decodeForwardingStatus(fwdStatusRaw);
      final needsForwarding = decoded.$1;
      final maxPathObserved = decoded.$2;

      debugPrint('[TELREC] raw bytes: compBatt=0x${compBatt.toRadixString(16)}'
          ' phoneBatt=0x${phoneBatt.toRadixString(16)}'
          ' fwdStatus=0x${fwdStatusRaw.toRadixString(16)}'
          ' isAutonomous=$isAutonomous'
          ' compBattDecoded=${_decodeBatteryVoltage(compBatt)}mV'
          ' phoneBattDecoded=${isAutonomous ? "N/A" : "${_decodeBatteryVoltage(phoneBatt)}mV"}'
          ' lat=${latInt / 1e7} lon=${lonInt / 1e7}');

      return TelemetryMessage(
        latitude: latInt / 1e7,
        longitude: lonInt / 1e7,
        companionBatteryMilliVolts: _decodeBatteryVoltage(compBatt),
        phoneBatteryMilliVolts:
            isAutonomous ? null : _decodeBatteryVoltage(phoneBatt),
        needsForwarding: needsForwarding,
        maxPathObserved: maxPathObserved,
        isAutonomousDevice: isAutonomous,
      );
    } catch (_) {
      return null;
    }
  }

  static int _encodeBatteryVoltage(int? millivolts) {
    if (millivolts == null || millivolts == 0) return 1;

    final clamped =
        millivolts.clamp(_batteryVoltageMinMv, _batteryVoltageMaxMv);
    final encoded = ((clamped - _batteryVoltageMinMv) ~/ _batteryStepMv) + 2;
    // Clamp to 254 max — 0xFF (255) is reserved as the autonomous sentinel.
    // KEEP IN SYNC: MeshBleService.encodeBatteryVoltage (Kotlin/Android)
    //               TopologyMessage._encodeBattery (Dart)
    return encoded.clamp(2, 254);
  }

  static int? _decodeBatteryVoltage(int encoded) {
    final value = encoded & 0xFF;
    if (value <= 1) return null;
    return _batteryVoltageMinMv + ((value - 2) * _batteryStepMv);
  }

  static int _encodeForwardingStatus({
    required bool needsForwarding,
    required int maxPathObserved,
  }) {
    final flag = needsForwarding ? 1 : 0;
    final path = maxPathObserved.clamp(0, 127);
    final encoded = ((path << 1) | flag) + 1;
    return encoded & 0xFF;
  }

  static (bool, int) _decodeForwardingStatus(int encoded) {
    final value = (encoded & 0xFF) - 1;
    final needsForwarding = (value & 0x01) == 1;
    final maxPathObserved = (value >> 1) & 0x7F;
    return (needsForwarding, maxPathObserved);
  }
}
