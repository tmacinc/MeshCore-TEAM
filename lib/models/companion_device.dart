// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:drift/drift.dart';
import 'package:meshcore_team/database/database.dart';

/// CompanionDevice model tracking connected companion radios
/// Matches Android CompanionDeviceEntity
class CompanionDevice {
  final String publicKeyHex;
  final String name;
  final int firstConnected;
  final int lastConnected;
  final int connectionCount;

  CompanionDevice({
    required this.publicKeyHex,
    required this.name,
    required this.firstConnected,
    required this.lastConnected,
    required this.connectionCount,
  });

  /// Create CompanionDevice from database CompanionDeviceData
  factory CompanionDevice.fromData(CompanionDeviceData data) {
    return CompanionDevice(
      publicKeyHex: data.publicKeyHex,
      name: data.name,
      firstConnected: data.firstConnected,
      lastConnected: data.lastConnected,
      connectionCount: data.connectionCount,
    );
  }

  /// Convert to CompanionDevicesCompanion for database insertion
  CompanionDevicesCompanion toCompanion() {
    return CompanionDevicesCompanion.insert(
      publicKeyHex: publicKeyHex,
      name: name,
      firstConnected: firstConnected,
      lastConnected: lastConnected,
      connectionCount: Value(connectionCount),
    );
  }

  /// First connected as DateTime
  DateTime get firstConnectedDateTime {
    return DateTime.fromMillisecondsSinceEpoch(firstConnected);
  }

  /// Last connected as DateTime
  DateTime get lastConnectedDateTime {
    return DateTime.fromMillisecondsSinceEpoch(lastConnected);
  }

  /// Abbreviated public key for display (first 8 characters)
  String get publicKeyShort => publicKeyHex.substring(0, 8);

  /// Display name with abbreviated key
  String get displayNameWithKey => '$name ($publicKeyShort...)';

  CompanionDevice copyWith({
    String? publicKeyHex,
    String? name,
    int? firstConnected,
    int? lastConnected,
    int? connectionCount,
  }) {
    return CompanionDevice(
      publicKeyHex: publicKeyHex ?? this.publicKeyHex,
      name: name ?? this.name,
      firstConnected: firstConnected ?? this.firstConnected,
      lastConnected: lastConnected ?? this.lastConnected,
      connectionCount: connectionCount ?? this.connectionCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CompanionDevice) return false;
    return publicKeyHex == other.publicKeyHex;
  }

  @override
  int get hashCode => publicKeyHex.hashCode;
}
