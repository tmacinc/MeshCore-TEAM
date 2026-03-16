// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:meshcore_team/database/database.dart';

/// Channel model representing a public or private communication channel
/// Matches Android ChannelEntity
class Channel {
  final int hash;
  final String name;
  final Uint8List sharedKey;
  final bool isPublic;
  final bool shareLocation;
  final int channelIndex;
  final int createdAt;
  final bool muteNotifications;
  final String? companionDeviceKey;

  Channel({
    required this.hash,
    required this.name,
    required this.sharedKey,
    required this.isPublic,
    required this.shareLocation,
    required this.channelIndex,
    required this.createdAt,
    required this.muteNotifications,
    this.companionDeviceKey,
  });

  /// Create Channel from database ChannelData
  factory Channel.fromData(ChannelData data) {
    return Channel(
      hash: data.hash,
      name: data.name,
      sharedKey: data.sharedKey,
      isPublic: data.isPublic,
      shareLocation: data.shareLocation,
      channelIndex: data.channelIndex,
      createdAt: data.createdAt,
      muteNotifications: data.muteNotifications,
      companionDeviceKey: data.companionDeviceKey,
    );
  }

  /// Convert to ChannelsCompanion for database insertion
  ChannelsCompanion toCompanion() {
    return ChannelsCompanion.insert(
      hash: Value(hash),
      name: name,
      sharedKey: sharedKey,
      isPublic: isPublic,
      channelIndex: channelIndex,
      createdAt: createdAt,
      shareLocation: Value(shareLocation),
      muteNotifications: Value(muteNotifications),
      companionDeviceKey: companionDeviceKey != null
          ? Value(companionDeviceKey)
          : const Value.absent(),
    );
  }

  /// Shared key as hex string (32 characters)
  String get sharedKeyHex {
    return sharedKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Channel type label for UI
  String get typeLabel => isPublic ? 'Public' : 'Private';

  /// Channel slot description (e.g., "Slot 0 (Public)")
  String get slotDescription {
    if (channelIndex == 0) {
      return 'Slot 0 (Public)';
    }
    return 'Slot $channelIndex (Private)';
  }

  /// Whether this is the default public channel (slot 0)
  bool get isDefaultPublic => channelIndex == 0 && isPublic;

  Channel copyWith({
    int? hash,
    String? name,
    Uint8List? sharedKey,
    bool? isPublic,
    bool? shareLocation,
    int? channelIndex,
    int? createdAt,
    bool? muteNotifications,
    String? companionDeviceKey,
  }) {
    return Channel(
      hash: hash ?? this.hash,
      name: name ?? this.name,
      sharedKey: sharedKey ?? this.sharedKey,
      isPublic: isPublic ?? this.isPublic,
      shareLocation: shareLocation ?? this.shareLocation,
      channelIndex: channelIndex ?? this.channelIndex,
      createdAt: createdAt ?? this.createdAt,
      muteNotifications: muteNotifications ?? this.muteNotifications,
      companionDeviceKey: companionDeviceKey ?? this.companionDeviceKey,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Channel) return false;
    return hash == other.hash;
  }

  @override
  int get hashCode => hash.hashCode;
}
