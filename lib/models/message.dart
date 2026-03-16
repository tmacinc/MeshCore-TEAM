// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:meshcore_team/database/database.dart';

/// Message model representing a chat message (DM or channel)
/// Matches Android MessageEntity
class Message {
  final String id;
  final Uint8List senderId;
  final String? senderName;
  final int channelHash;
  final String content;
  final int timestamp;
  final bool isPrivate;
  final Uint8List? ackChecksum;
  final String deliveryStatus;
  final int heardByCount;
  final int attempt;
  final bool isSentByMe;
  final String? companionDeviceKey;

  Message({
    required this.id,
    required this.senderId,
    this.senderName,
    required this.channelHash,
    required this.content,
    required this.timestamp,
    required this.isPrivate,
    this.ackChecksum,
    required this.deliveryStatus,
    required this.heardByCount,
    required this.attempt,
    required this.isSentByMe,
    this.companionDeviceKey,
  });

  /// Create Message from database MessageData
  factory Message.fromData(MessageData data) {
    return Message(
      id: data.id,
      senderId: data.senderId,
      senderName: data.senderName,
      channelHash: data.channelHash,
      content: data.content,
      timestamp: data.timestamp,
      isPrivate: data.isPrivate,
      ackChecksum: data.ackChecksum,
      deliveryStatus: data.deliveryStatus,
      heardByCount: data.heardByCount,
      attempt: data.attempt,
      isSentByMe: data.isSentByMe,
      companionDeviceKey: data.companionDeviceKey,
    );
  }

  /// Convert to MessagesCompanion for database insertion
  MessagesCompanion toCompanion() {
    return MessagesCompanion.insert(
      id: id,
      senderId: senderId,
      senderName: senderName != null ? Value(senderName) : const Value.absent(),
      channelHash: channelHash,
      content: content,
      timestamp: timestamp,
      isPrivate: isPrivate,
      ackChecksum:
          ackChecksum != null ? Value(ackChecksum) : const Value.absent(),
      deliveryStatus: deliveryStatus,
      heardByCount: Value(heardByCount),
      attempt: Value(attempt),
      isSentByMe: isSentByMe,
      companionDeviceKey: companionDeviceKey != null
          ? Value(companionDeviceKey)
          : const Value.absent(),
    );
  }

  /// Sender public key as hex string
  String get senderIdHex {
    return senderId.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Sender display name (uses name if available, otherwise truncated key)
  String get senderDisplayName {
    if (senderName != null && senderName!.isNotEmpty) {
      return senderName!;
    }
    return senderIdHex.substring(0, 8);
  }

  /// ACK checksum as hex string (if available)
  String? get ackChecksumHex {
    if (ackChecksum == null) return null;
    return ackChecksum!.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Message type label
  String get typeLabel => isPrivate ? 'DM' : 'Channel';

  /// Timestamp as DateTime
  DateTime get timestampAsDateTime {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Delivery status enum
  DeliveryStatus get status {
    switch (deliveryStatus.toUpperCase()) {
      case 'SENDING':
        return DeliveryStatus.sending;
      case 'SENT':
        return DeliveryStatus.sent;
      case 'DELIVERED':
        return DeliveryStatus.delivered;
      default:
        return DeliveryStatus.sending;
    }
  }

  /// Whether message is still being sent
  bool get isSending => status == DeliveryStatus.sending;

  /// Whether message was successfully sent
  bool get wasSent =>
      status == DeliveryStatus.sent || status == DeliveryStatus.delivered;

  /// Whether message was delivered (ACK received)
  bool get wasDelivered => status == DeliveryStatus.delivered;

  Message copyWith({
    String? id,
    Uint8List? senderId,
    String? senderName,
    int? channelHash,
    String? content,
    int? timestamp,
    bool? isPrivate,
    Uint8List? ackChecksum,
    String? deliveryStatus,
    int? heardByCount,
    int? attempt,
    bool? isSentByMe,
    String? companionDeviceKey,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      channelHash: channelHash ?? this.channelHash,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isPrivate: isPrivate ?? this.isPrivate,
      ackChecksum: ackChecksum ?? this.ackChecksum,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      heardByCount: heardByCount ?? this.heardByCount,
      attempt: attempt ?? this.attempt,
      isSentByMe: isSentByMe ?? this.isSentByMe,
      companionDeviceKey: companionDeviceKey ?? this.companionDeviceKey,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Message) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Message delivery status
enum DeliveryStatus {
  sending, // Currently being sent
  sent, // Successfully sent to companion device
  delivered, // ACK received from recipient
}
