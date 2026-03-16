// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'ack_records_dao.g.dart';

/// DAO for managing message acknowledgment records
/// Matches Android AckRecordDao functionality
@DriftAccessor(tables: [AckRecords])
class AckRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$AckRecordsDaoMixin {
  AckRecordsDao(super.db);

  /// Get all ACKs for a message
  Future<List<AckRecordData>> getAcksByMessage(String messageId) {
    return (select(ackRecords)
          ..where((t) => t.messageId.equals(messageId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.receivedAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Get a specific ACK record
  Future<AckRecordData?> getAck(String messageId, Uint8List ackerPublicKey) {
    return (select(ackRecords)
          ..where((t) =>
              t.messageId.equals(messageId) &
              t.ackerPublicKey.equals(ackerPublicKey)))
        .getSingleOrNull();
  }

  /// Insert a new ACK record
  Future<void> insertAck(AckRecordsCompanion ack) {
    return into(ackRecords).insert(ack, mode: InsertMode.insertOrIgnore);
  }

  /// Get ACK count for a message
  Future<int> getAckCount(String messageId) async {
    final query = selectOnly(ackRecords)
      ..addColumns([ackRecords.messageId.count()])
      ..where(ackRecords.messageId.equals(messageId));

    final result = await query.getSingle();
    return result.read(ackRecords.messageId.count()) ?? 0;
  }

  /// Check if an ACK exists
  Future<bool> hasAck(String messageId, Uint8List ackerPublicKey) async {
    final ack = await getAck(messageId, ackerPublicKey);
    return ack != null;
  }

  /// Delete ACKs for a message
  Future<int> deleteAcksByMessage(String messageId) {
    return (delete(ackRecords)..where((t) => t.messageId.equals(messageId)))
        .go();
  }

  /// Delete ACKs older than a timestamp
  Future<int> deleteAcksOlderThan(int timestamp) {
    return (delete(ackRecords)
          ..where((t) => t.receivedAt.isSmallerThanValue(timestamp)))
        .go();
  }

  /// Watch ACKs for a message (stream)
  Stream<List<AckRecordData>> watchAcksByMessage(String messageId) {
    return (select(ackRecords)
          ..where((t) => t.messageId.equals(messageId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.receivedAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watch ACK count for a message (stream)
  Stream<int> watchAckCount(String messageId) {
    final query = selectOnly(ackRecords)
      ..addColumns([ackRecords.messageId.count()])
      ..where(ackRecords.messageId.equals(messageId));

    return query
        .map((row) => row.read(ackRecords.messageId.count()) ?? 0)
        .watchSingle();
  }

  /// Get recent ACKs (last N)
  Future<List<AckRecordData>> getRecentAcks({int limit = 100}) {
    return (select(ackRecords)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.receivedAt, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
  }

  /// Delete all ACK records for a companion device
  Future<int> deleteAckRecordsByCompanion(String companionKey) {
    return (delete(ackRecords)
          ..where((t) => t.companionDeviceKey.equals(companionKey)))
        .go();
  }
}
