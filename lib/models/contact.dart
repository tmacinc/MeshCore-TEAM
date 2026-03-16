// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:latlong2/latlong.dart';

/// Contact model representing a mesh network node
/// Matches Android NodeEntity
class Contact {
  final Uint8List publicKey;
  final int hash;
  final String? name;
  final double? latitude;
  final double? longitude;
  final int lastSeen;
  final int? companionBatteryMilliVolts;
  final int? phoneBatteryMilliVolts;
  final bool isRepeater;
  final bool isRoomServer;
  final bool isDirect;
  final int hopCount;
  final int? lastTelemetryChannelIdx;
  final int? lastTelemetryTimestamp;
  final bool isOutOfRange;
  final String? companionDeviceKey;

  Contact({
    required this.publicKey,
    required this.hash,
    this.name,
    this.latitude,
    this.longitude,
    required this.lastSeen,
    this.companionBatteryMilliVolts,
    this.phoneBatteryMilliVolts,
    required this.isRepeater,
    required this.isRoomServer,
    required this.isDirect,
    required this.hopCount,
    this.lastTelemetryChannelIdx,
    this.lastTelemetryTimestamp,
    required this.isOutOfRange,
    this.companionDeviceKey,
  });

  /// Create Contact from database ContactData
  factory Contact.fromData(ContactData data) {
    return Contact(
      publicKey: data.publicKey,
      hash: data.hash,
      name: data.name,
      latitude: data.latitude,
      longitude: data.longitude,
      lastSeen: data.lastSeen,
      companionBatteryMilliVolts: data.companionBatteryMilliVolts,
      phoneBatteryMilliVolts: data.phoneBatteryMilliVolts,
      isRepeater: data.isRepeater,
      isRoomServer: data.isRoomServer,
      isDirect: data.isDirect,
      hopCount: data.hopCount,
      lastTelemetryChannelIdx: data.lastTelemetryChannelIdx,
      lastTelemetryTimestamp: data.lastTelemetryTimestamp,
      isOutOfRange: data.isOutOfRange,
      companionDeviceKey: data.companionDeviceKey,
    );
  }

  /// Convert to ContactsCompanion for database insertion
  ContactsCompanion toCompanion() {
    return ContactsCompanion.insert(
      publicKey: publicKey,
      hash: hash,
      name: name != null ? Value(name) : const Value.absent(),
      latitude: latitude != null ? Value(latitude) : const Value.absent(),
      longitude: longitude != null ? Value(longitude) : const Value.absent(),
      lastSeen: lastSeen,
      companionBatteryMilliVolts: companionBatteryMilliVolts != null
          ? Value(companionBatteryMilliVolts)
          : const Value.absent(),
      phoneBatteryMilliVolts: phoneBatteryMilliVolts != null
          ? Value(phoneBatteryMilliVolts)
          : const Value.absent(),
      isRepeater: Value(isRepeater),
      isRoomServer: Value(isRoomServer),
      isDirect: Value(isDirect),
      hopCount: Value(hopCount),
      lastTelemetryChannelIdx: lastTelemetryChannelIdx != null
          ? Value(lastTelemetryChannelIdx)
          : const Value.absent(),
      lastTelemetryTimestamp: lastTelemetryTimestamp != null
          ? Value(lastTelemetryTimestamp)
          : const Value.absent(),
      isOutOfRange: Value(isOutOfRange),
      companionDeviceKey: companionDeviceKey != null
          ? Value(companionDeviceKey)
          : const Value.absent(),
    );
  }

  /// Public key as hex string (64 characters)
  String get publicKeyHex {
    return publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Display name (uses name if available, otherwise truncated public key)
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    return publicKeyHex.substring(0, 8);
  }

  /// Check if contact has valid GPS coordinates
  bool get hasLocation => latitude != null && longitude != null;

  /// Get LatLng for map display (null if no location)
  LatLng? get location {
    if (!hasLocation) return null;
    return LatLng(latitude!, longitude!);
  }

  /// Get connectivity status for map color coding
  /// - DIRECT (Green): 0 hops, direct radio contact
  /// - RELAYED (Yellow): 1-3 hops through repeaters
  /// - DISTANT (Orange): 4+ hops, weak connection
  /// - OFFLINE (Red): Not heard recently (5-10 min)
  /// - OUT_OF_RANGE (Gray): Confirmed out of range (10+ min)
  ConnectivityStatus getConnectivityStatus({int staleThresholdMs = 300000}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastSeen = now - lastSeen;

    if (isOutOfRange) {
      return ConnectivityStatus.outOfRange;
    }

    if (timeSinceLastSeen > staleThresholdMs) {
      return ConnectivityStatus.offline;
    }

    if (hopCount == 0 && isDirect) {
      return ConnectivityStatus.direct;
    }

    if (hopCount >= 1 && hopCount <= 3) {
      return ConnectivityStatus.relayed;
    }

    return ConnectivityStatus.distant;
  }

  /// Get time since last seen in seconds
  int get timeSinceLastSeenSeconds {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((now - lastSeen) / 1000).floor();
  }

  /// Get formatted battery voltage (e.g., "3.7V")
  String? get companionBatteryFormatted {
    if (companionBatteryMilliVolts == null) return null;
    return '${(companionBatteryMilliVolts! / 1000).toStringAsFixed(1)}V';
  }

  String? get phoneBatteryFormatted {
    if (phoneBatteryMilliVolts == null) return null;
    return '${(phoneBatteryMilliVolts! / 1000).toStringAsFixed(1)}V';
  }

  Contact copyWith({
    Uint8List? publicKey,
    int? hash,
    String? name,
    double? latitude,
    double? longitude,
    int? lastSeen,
    int? companionBatteryMilliVolts,
    int? phoneBatteryMilliVolts,
    bool? isRepeater,
    bool? isRoomServer,
    bool? isDirect,
    int? hopCount,
    int? lastTelemetryChannelIdx,
    int? lastTelemetryTimestamp,
    bool? isOutOfRange,
    String? companionDeviceKey,
  }) {
    return Contact(
      publicKey: publicKey ?? this.publicKey,
      hash: hash ?? this.hash,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastSeen: lastSeen ?? this.lastSeen,
      companionBatteryMilliVolts:
          companionBatteryMilliVolts ?? this.companionBatteryMilliVolts,
      phoneBatteryMilliVolts:
          phoneBatteryMilliVolts ?? this.phoneBatteryMilliVolts,
      isRepeater: isRepeater ?? this.isRepeater,
      isRoomServer: isRoomServer ?? this.isRoomServer,
      isDirect: isDirect ?? this.isDirect,
      hopCount: hopCount ?? this.hopCount,
      lastTelemetryChannelIdx:
          lastTelemetryChannelIdx ?? this.lastTelemetryChannelIdx,
      lastTelemetryTimestamp:
          lastTelemetryTimestamp ?? this.lastTelemetryTimestamp,
      isOutOfRange: isOutOfRange ?? this.isOutOfRange,
      companionDeviceKey: companionDeviceKey ?? this.companionDeviceKey,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Contact) return false;
    return publicKeyHex == other.publicKeyHex;
  }

  @override
  int get hashCode => publicKeyHex.hashCode;
}

/// Connectivity status for map visualization
enum ConnectivityStatus {
  direct, // Green: 0 hops, direct radio contact
  relayed, // Yellow: 1-3 hops through repeaters
  distant, // Orange: 4+ hops, weak connection
  offline, // Red: Not heard recently (5-10 min)
  outOfRange, // Gray: Confirmed out of range (10+ min)
}
