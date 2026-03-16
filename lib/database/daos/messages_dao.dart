// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'messages_dao.g.dart';

/// DAO for managing chat messages
/// Matches Android MessageDao functionality
@DriftAccessor(tables: [Messages])
class MessagesDao extends DatabaseAccessor<AppDatabase>
    with _$MessagesDaoMixin {
  MessagesDao(super.db);

  /// Get all messages for a channel, ordered by timestamp
  Future<List<MessageData>> getMessagesByChannel(int channelHash) {
    return (select(messages)
          ..where((t) => t.channelHash.equals(channelHash))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Get messages for a channel for a specific companion
  Future<List<MessageData>> getMessagesByChannelForCompanion(
      int channelHash, String companionKey) {
    return (select(messages)
          ..where((t) =>
              t.channelHash.equals(channelHash) &
              t.companionDeviceKey.equals(companionKey))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Get messages for a private conversation (DM)
  /// Queries by contact hash and isPrivate flag (matches Android implementation)
  Future<List<MessageData>> getPrivateMessages(int contactHash) {
    return (select(messages)
          ..where((t) =>
              t.isPrivate.equals(true) & t.channelHash.equals(contactHash))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Get private messages for a specific companion
  Future<List<MessageData>> getPrivateMessagesForCompanion(
      int contactHash, String companionKey) {
    return (select(messages)
          ..where((t) =>
              t.isPrivate.equals(true) &
              t.channelHash.equals(contactHash) &
              t.companionDeviceKey.equals(companionKey))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Get a single message by ID
  Future<MessageData?> getMessageById(String id) {
    return (select(messages)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new message and return the inserted data
  Future<MessageData?> insertMessage(MessagesCompanion message) async {
    try {
      await into(messages).insert(message);
      // Query the inserted message by ID
      return await getMessageById(message.id.value);
    } catch (e) {
      // Return null on error (e.g., duplicate key)
      return null;
    }
  }

  /// Update message delivery status
  Future<void> updateDeliveryStatus(String id, String status) {
    return (update(messages)..where((t) => t.id.equals(id)))
        .write(MessagesCompanion(
      deliveryStatus: Value(status),
    ));
  }

  /// Increment heard-by count (when we receive an ACK)
  Future<void> incrementHeardByCount(String id) async {
    final msg = await getMessageById(id);
    if (msg != null) {
      await (update(messages)..where((t) => t.id.equals(id)))
          .write(MessagesCompanion(
        heardByCount: Value(msg.heardByCount + 1),
      ));
    }
  }

  /// Get message by ACK checksum (for matching ACK responses)
  Future<MessageData?> getMessageByAckChecksum(Uint8List checksum) {
    return (select(messages)..where((t) => t.ackChecksum.equals(checksum)))
        .getSingleOrNull();
  }

  /// Update retry attempt number
  Future<void> updateAttempt(String id, int attempt) {
    return (update(messages)..where((t) => t.id.equals(id)))
        .write(MessagesCompanion(
      attempt: Value(attempt),
    ));
  }

  /// Update ACK checksum (after receiving RESP_CODE_SENT from firmware)
  Future<void> updateMessageAckChecksum(String id, Uint8List checksum) {
    return (update(messages)..where((t) => t.id.equals(id)))
        .write(MessagesCompanion(
      ackChecksum: Value(checksum),
    ));
  }

  /// Mark message as delivered (at least one ACK received)
  Future<void> markDelivered(String id) {
    return (update(messages)..where((t) => t.id.equals(id)))
        .write(MessagesCompanion(
      deliveryStatus: const Value('DELIVERED'),
    ));
  }

  /// Get messages pending delivery (SENDING status)
  Future<List<MessageData>> getPendingMessages() {
    return (select(messages)
          ..where((t) => t.deliveryStatus.equals('SENDING'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Get messages sent by me
  Future<List<MessageData>> getMyMessages() {
    return (select(messages)
          ..where((t) => t.isSentByMe.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Delete a message
  Future<int> deleteMessage(String id) {
    return (delete(messages)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all messages for a channel
  Future<int> deleteMessagesByChannel(int channelHash) {
    return (delete(messages)..where((t) => t.channelHash.equals(channelHash)))
        .go();
  }

  /// Delete all messages for a channel for a specific companion device
  Future<int> deleteMessagesByChannelForCompanion(
      int channelHash, String companionKey) {
    return (delete(messages)
          ..where((t) =>
              t.channelHash.equals(channelHash) &
              t.companionDeviceKey.equals(companionKey)))
        .go();
  }

  /// Delete all messages for a companion device
  Future<int> deleteMessagesByCompanion(String companionKey) {
    return (delete(messages)
          ..where((t) => t.companionDeviceKey.equals(companionKey)))
        .go();
  }

  /// Delete messages older than a timestamp
  Future<int> deleteMessagesOlderThan(int timestamp) {
    return (delete(messages)
          ..where((t) => t.timestamp.isSmallerThanValue(timestamp)))
        .go();
  }

  /// Watch messages for a channel (stream)
  Stream<List<MessageData>> watchMessagesByChannel(int channelHash) {
    return (select(messages)
          ..where((t) => t.channelHash.equals(channelHash))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watch messages for a channel for a specific companion (stream)
  Stream<List<MessageData>> watchMessagesByChannelForCompanion(
      int channelHash, String companionKey) {
    return (select(messages)
          ..where((t) =>
              t.channelHash.equals(channelHash) &
              t.companionDeviceKey.equals(companionKey))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watch private messages (stream)
  /// Queries by contact hash and isPrivate flag (matches Android implementation)
  Stream<List<MessageData>> watchPrivateMessages(int contactHash) {
    return (select(messages)
          ..where((t) =>
              t.isPrivate.equals(true) & t.channelHash.equals(contactHash))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watch private messages for a specific companion (stream)
  Stream<List<MessageData>> watchPrivateMessagesForCompanion(
      int contactHash, String companionKey) {
    return (select(messages)
          ..where((t) =>
              t.isPrivate.equals(true) &
              t.channelHash.equals(contactHash) &
              t.companionDeviceKey.equals(companionKey))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watch a single message (stream)
  Stream<MessageData?> watchMessage(String id) {
    return (select(messages)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Watch pending messages (stream)
  Stream<List<MessageData>> watchPendingMessages() {
    return (select(messages)
          ..where((t) => t.deliveryStatus.equals('SENDING'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watch all messages (stream) - used to trigger updates in other DAOs
  /// Watches the messages table and emits whenever any message changes
  Stream<List<MessageData>> watchAllMessages() {
    return (select(messages)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Get message count for a channel
  Future<int> getMessageCountByChannel(int channelHash) async {
    final query = selectOnly(messages)
      ..addColumns([messages.id.count()])
      ..where(messages.channelHash.equals(channelHash));

    final result = await query.getSingle();
    return result.read(messages.id.count()) ?? 0;
  }

  /// Get message count for a contact (private conversation / DM)
  Future<int> getMessageCountByContact(int contactHash) async {
    final query = selectOnly(messages)
      ..addColumns([messages.id.count()])
      ..where(messages.channelHash.equals(contactHash) &
          messages.isPrivate.equals(true));

    final result = await query.getSingle();
    return result.read(messages.id.count()) ?? 0;
  }

  /// Get message count for a contact (private conversation / DM) for a specific companion
  Future<int> getMessageCountByContactForCompanion(
      int contactHash, String companionKey) async {
    final query = selectOnly(messages)
      ..addColumns([messages.id.count()])
      ..where(messages.channelHash.equals(contactHash) &
          messages.isPrivate.equals(true) &
          messages.companionDeviceKey.equals(companionKey));

    final result = await query.getSingle();
    return result.read(messages.id.count()) ?? 0;
  }

  /// Get unread message count for a channel
  Future<int> getUnreadCountByChannel(int channelHash) async {
    final query = selectOnly(messages)
      ..addColumns([messages.id.count()])
      ..where(messages.channelHash.equals(channelHash) &
          messages.isPrivate.equals(false) &
          messages.isRead.equals(false) &
          messages.isSentByMe.equals(false));

    final result = await query.getSingle();
    return result.read(messages.id.count()) ?? 0;
  }

  /// Get unread message count for a contact (private messages)
  Future<int> getUnreadCountByContact(int contactHash) async {
    final query = selectOnly(messages)
      ..addColumns([messages.id.count()])
      ..where(messages.channelHash.equals(contactHash) &
          messages.isPrivate.equals(true) &
          messages.isRead.equals(false) &
          messages.isSentByMe.equals(false));

    final result = await query.getSingle();
    return result.read(messages.id.count()) ?? 0;
  }

  /// Get unread message count for a contact (private messages) for a specific companion
  Future<int> getUnreadCountByContactForCompanion(
      int contactHash, String companionKey) async {
    final query = selectOnly(messages)
      ..addColumns([messages.id.count()])
      ..where(messages.channelHash.equals(contactHash) &
          messages.isPrivate.equals(true) &
          messages.isRead.equals(false) &
          messages.isSentByMe.equals(false) &
          messages.companionDeviceKey.equals(companionKey));

    final result = await query.getSingle();
    return result.read(messages.id.count()) ?? 0;
  }

  /// Mark all messages in a channel as read
  Future<void> markChannelMessagesAsRead(int channelHash) {
    return (update(messages)
          ..where((t) =>
              t.channelHash.equals(channelHash) & t.isPrivate.equals(false)))
        .write(MessagesCompanion(
      isRead: const Value(true),
    ));
  }

  /// Mark all messages from a contact as read (private messages)
  Future<void> markContactMessagesAsRead(int contactHash) {
    return (update(messages)
          ..where((t) =>
              t.channelHash.equals(contactHash) & t.isPrivate.equals(true)))
        .write(MessagesCompanion(
      isRead: const Value(true),
    ));
  }

  /// Mark all contact messages as read (all private messages)
  Future<void> markAllContactMessagesAsRead() {
    return (update(messages)..where((t) => t.isPrivate.equals(true)))
        .write(MessagesCompanion(
      isRead: const Value(true),
    ));
  }

  /// Get the first unread message timestamp for a channel (for divider)
  Future<int?> getFirstUnreadTimestampByChannel(int channelHash) async {
    final query = select(messages)
      ..where((t) =>
          t.channelHash.equals(channelHash) &
          t.isPrivate.equals(false) &
          t.isRead.equals(false) &
          t.isSentByMe.equals(false))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc)
      ])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.timestamp;
  }

  /// Get the first unread message timestamp for a contact (for divider)
  Future<int?> getFirstUnreadTimestampByContact(int contactHash) async {
    final query = select(messages)
      ..where((t) =>
          t.channelHash.equals(contactHash) &
          t.isPrivate.equals(true) &
          t.isRead.equals(false) &
          t.isSentByMe.equals(false))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc)
      ])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.timestamp;
  }

  /// Get total unread count across all channels
  Future<int> getTotalUnreadChannelCount() async {
    final query = selectOnly(messages)
      ..addColumns([messages.id.count()])
      ..where(messages.isPrivate.equals(false) &
          messages.isRead.equals(false) &
          messages.isSentByMe.equals(false));

    final result = await query.getSingle();
    return result.read(messages.id.count()) ?? 0;
  }

  /// Get total unread count across all contacts
  Future<int> getTotalUnreadContactCount() async {
    final query = selectOnly(messages)
      ..addColumns([messages.id.count()])
      ..where(messages.isPrivate.equals(true) &
          messages.isRead.equals(false) &
          messages.isSentByMe.equals(false));

    final result = await query.getSingle();
    return result.read(messages.id.count()) ?? 0;
  }
}
