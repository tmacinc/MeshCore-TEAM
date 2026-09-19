// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
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
  final String notificationMode;
  final bool isFavorite;
  final String? companionDeviceKey;

  Channel({
    required this.hash,
    required this.name,
    required this.sharedKey,
    required this.isPublic,
    required this.shareLocation,
    required this.channelIndex,
    required this.createdAt,
    required this.notificationMode,
    required this.isFavorite,
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
      notificationMode: data.notificationMode,
      isFavorite: data.isFavorite,
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
      notificationMode: Value(notificationMode),
      isFavorite: Value(isFavorite),
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
    String? notificationMode,
    bool? isFavorite,
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
      notificationMode: notificationMode ?? this.notificationMode,
      isFavorite: isFavorite ?? this.isFavorite,
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

/// Derive the PSK for a hashtag channel from its name.
///
/// PSK = first 16 bytes of SHA256(name), where [name] includes the '#' prefix
/// (e.g. "#public"). This is the same derivation used by the reference firmware
/// so any device that knows the channel name arrives at the same AES key.
Uint8List hashtagChannelPsk(String name) {
  final digest = sha256.convert(utf8.encode(name));
  return Uint8List.fromList(digest.bytes.sublist(0, 16));
}

extension ChannelDataKind on ChannelData {
  /// True when the key is derived from the channel name, so anyone who knows
  /// (or guesses) the name can read the channel. Detected from the key rather
  /// than a stored flag so channels synced from firmware are covered too.
  bool get isHashtag {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final candidate = trimmed.startsWith('#') ? trimmed : '#$trimmed';
    final derived = hashtagChannelPsk(candidate);
    if (sharedKey.length != derived.length) return false;
    for (var i = 0; i < derived.length; i++) {
      if (sharedKey[i] != derived[i]) return false;
    }
    return true;
  }

  /// Location tracking may only use a private channel with a secret key:
  /// never the public channel and never a hashtag channel.
  bool get canBeTrackingChannel => !isPublic && !isHashtag;

  /// Whether the connected radio holds this channel, so it can send and
  /// receive on it. Channels the phone keeps without a radio slot are parked
  /// on negative sentinel slots; slot 0 is real (the public channel).
  bool get isOnRadio => firmwareConfirmed && channelIndex >= 0;
}
