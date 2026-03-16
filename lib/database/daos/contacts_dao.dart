// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:async';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';
import '../../models/unread_models.dart';

part 'contacts_dao.g.dart';

/// DAO for managing mesh network contacts (nodes)
/// Matches Android NodeDao functionality
@DriftAccessor(tables: [Contacts, Messages])
class ContactsDao extends DatabaseAccessor<AppDatabase>
    with _$ContactsDaoMixin {
  ContactsDao(super.db);

  /// Get all contacts ordered by last seen (most recent first)
  Future<List<ContactData>> getAllContacts() {
    return (select(contacts)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastSeen, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get contacts for a specific companion device
  Future<List<ContactData>> getContactsByCompanion(String companionKey) {
    return (select(contacts)
          ..where((t) => t.companionDeviceKey.equals(companionKey))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastSeen, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get a single contact by public key
  Future<ContactData?> getContactByPublicKey(Uint8List publicKey) {
    return (select(contacts)..where((t) => t.publicKey.equals(publicKey)))
        .getSingleOrNull();
  }

  /// Get a single contact by matching the first [prefixLength] bytes of the
  /// contact's public key.
  ///
  /// This is required for direct-message formats that only include a 6-byte
  /// public key prefix.
  Future<ContactData?> getContactByPublicKeyPrefix(
    Uint8List prefix, {
    int prefixLength = 6,
    String? companionKey,
  }) async {
    if (prefix.isEmpty) return null;
    if (prefixLength <= 0) return null;

    final effectivePrefixLength =
        prefixLength > prefix.length ? prefix.length : prefixLength;

    final query = select(contacts);
    if (companionKey != null && companionKey.isNotEmpty) {
      query.where((t) => t.companionDeviceKey.equals(companionKey));
    }

    final allContacts = await query.get();
    for (final contact in allContacts) {
      final pk = contact.publicKey;
      if (pk.length < effectivePrefixLength) continue;

      bool matches = true;
      for (int i = 0; i < effectivePrefixLength; i++) {
        if (pk[i] != prefix[i]) {
          matches = false;
          break;
        }
      }

      if (matches) {
        return contact;
      }
    }

    return null;
  }

  /// Get a single contact by hash (derived from full public key)
  /// Returns first match if multiple contacts have same hash
  Future<ContactData?> getContactByHash(int hash) {
    return (select(contacts)
          ..where((t) => t.hash.equals(hash))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastSeen, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get a single contact by hash for a specific companion.
  /// Prefer this over getContactByHash() when companion context is available.
  Future<ContactData?> getContactByHashForCompanion(
      int hash, String companionKey) {
    return (select(contacts)
          ..where((t) =>
              t.hash.equals(hash) & t.companionDeviceKey.equals(companionKey))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastSeen, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Insert or update a contact
  Future<int> upsertContact(ContactsCompanion contact) async {
    return await into(contacts).insertOnConflictUpdate(contact);
  }

  /// Insert or update a batch of contacts inside a single transaction.
  /// Much faster than calling upsertContact() in a loop because SQLite
  /// commits only once instead of N times.
  Future<void> bulkUpsertContacts(List<ContactsCompanion> rows) async {
    if (rows.isEmpty) return;
    await transaction(() async {
      for (final row in rows) {
        await into(contacts).insertOnConflictUpdate(row);
      }
    });
  }

  /// Update contact's last seen timestamp
  Future<void> updateLastSeen(Uint8List publicKey, int timestamp) {
    return (update(contacts)..where((t) => t.publicKey.equals(publicKey)))
        .write(ContactsCompanion(
      lastSeen: Value(timestamp),
    ));
  }

  /// Update contact's position
  Future<void> updatePosition(
    Uint8List publicKey,
    double latitude,
    double longitude,
  ) {
    return (update(contacts)..where((t) => t.publicKey.equals(publicKey)))
        .write(ContactsCompanion(
      latitude: Value(latitude),
      longitude: Value(longitude),
    ));
  }

  /// Update contact's hop count and direct status
  Future<void> updateHopInfo(
    Uint8List publicKey,
    int hopCount,
    bool isDirect,
  ) {
    return (update(contacts)..where((t) => t.publicKey.equals(publicKey)))
        .write(ContactsCompanion(
      hopCount: Value(hopCount),
      isDirect: Value(isDirect),
    ));
  }

  /// Mark contact as out of range (for adaptive forwarding)
  Future<void> markOutOfRange(Uint8List publicKey, bool isOutOfRange) {
    return (update(contacts)..where((t) => t.publicKey.equals(publicKey)))
        .write(ContactsCompanion(
      isOutOfRange: Value(isOutOfRange),
    ));
  }

  /// Update battery levels
  Future<void> updateBatteryLevels(
    Uint8List publicKey, {
    int? companionBattery,
    int? phoneBattery,
  }) {
    return (update(contacts)..where((t) => t.publicKey.equals(publicKey)))
        .write(ContactsCompanion(
      companionBatteryMilliVolts: companionBattery != null
          ? Value(companionBattery)
          : const Value.absent(),
      phoneBatteryMilliVolts:
          phoneBattery != null ? Value(phoneBattery) : const Value.absent(),
    ));
  }

  /// Update telemetry tracking info
  Future<void> updateTelemetryInfo(
    Uint8List publicKey,
    int channelIdx,
    int timestamp,
  ) {
    return (update(contacts)..where((t) => t.publicKey.equals(publicKey)))
        .write(ContactsCompanion(
      lastTelemetryChannelIdx: Value(channelIdx),
      lastTelemetryTimestamp: Value(timestamp),
    ));
  }

  /// Delete a contact
  Future<int> deleteContact(Uint8List publicKey) {
    return (delete(contacts)..where((t) => t.publicKey.equals(publicKey))).go();
  }

  /// Delete all contacts for a companion device
  Future<int> deleteContactsByCompanion(String companionKey) {
    return (delete(contacts)
          ..where((t) => t.companionDeviceKey.equals(companionKey)))
        .go();
  }

  /// Watch all contacts (stream)
  Stream<List<ContactData>> watchAllContacts() {
    return (select(contacts)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastSeen, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Watch contacts for a specific companion (stream)
  Stream<List<ContactData>> watchContactsByCompanion(String companionKey) {
    return (select(contacts)
          ..where((t) => t.companionDeviceKey.equals(companionKey))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastSeen, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Watch a single contact by public key (stream)
  Stream<ContactData?> watchContact(Uint8List publicKey) {
    return (select(contacts)..where((t) => t.publicKey.equals(publicKey)))
        .watchSingleOrNull();
  }

  /// Get contacts that are currently in range (not stale)
  Future<List<ContactData>> getActiveContacts(
      {int staleThresholdMs = 5 * 60 * 1000}) {
    final cutoffTime = DateTime.now().millisecondsSinceEpoch - staleThresholdMs;
    return (select(contacts)
          ..where((t) => t.lastSeen.isBiggerOrEqualValue(cutoffTime))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastSeen, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get contacts marked as out of range
  Future<List<ContactData>> getOutOfRangeContacts() {
    return (select(contacts)
          ..where((t) => t.isOutOfRange.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastSeen, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get all contacts with unread counts, sorted with unread first
  Future<List<ContactWithUnread>> getAllContactsWithUnread() async {
    final allContacts = await getAllContacts();
    final contactsWithStats =
        <({ContactData contact, int unreadCount, int messageCount})>[];

    for (final contact in allContacts) {
      final unreadCount =
          await db.messagesDao.getUnreadCountByContact(contact.hash);
      final messageCount =
          await db.messagesDao.getMessageCountByContact(contact.hash);
      contactsWithStats.add((
        contact: contact,
        unreadCount: unreadCount,
        messageCount: messageCount,
      ));
    }

    // Sort:
    // 1) Non-repeaters first, repeaters at bottom
    // 2) Within each group: unread first, then any-message history, then the rest.
    // 3) Within subgroups: higher unreadCount first, then lastSeen.
    contactsWithStats.sort((a, b) {
      if (a.contact.isRepeater != b.contact.isRepeater) {
        return a.contact.isRepeater ? 1 : -1;
      }

      final aHasUnread = a.unreadCount > 0;
      final bHasUnread = b.unreadCount > 0;
      if (aHasUnread != bHasUnread) {
        return bHasUnread ? 1 : -1;
      }

      final aHasMessages = a.messageCount > 0;
      final bHasMessages = b.messageCount > 0;
      if (aHasMessages != bHasMessages) {
        return bHasMessages ? 1 : -1;
      }

      if (a.unreadCount != b.unreadCount) {
        return b.unreadCount.compareTo(a.unreadCount);
      }

      return b.contact.lastSeen.compareTo(a.contact.lastSeen);
    });

    return contactsWithStats
        .map(
          (e) =>
              ContactWithUnread(contact: e.contact, unreadCount: e.unreadCount),
        )
        .toList(growable: false);
  }

  /// Watch all contacts with unread counts (stream)
  /// Reacts to changes in both contacts and messages tables
  Stream<List<ContactWithUnread>> watchAllContactsWithUnread() async* {
    // Manually merge streams using StreamController
    final controller = StreamController<void>();

    // Listen to contacts changes
    final contactsSub = watchAllContacts().listen((_) {
      if (!controller.isClosed) controller.add(null);
    });

    // Listen to messages changes
    final messagesSub = db.messagesDao.watchAllMessages().listen((_) {
      if (!controller.isClosed) controller.add(null);
    });

    // Emit initial value
    controller.add(null);

    try {
      await for (final _ in controller.stream) {
        final contactsList = await getAllContacts();
        final contactsWithStats =
            <({ContactData contact, int unreadCount, int messageCount})>[];

        for (final contact in contactsList) {
          final unreadCount =
              await db.messagesDao.getUnreadCountByContact(contact.hash);
          final messageCount =
              await db.messagesDao.getMessageCountByContact(contact.hash);
          contactsWithStats.add((
            contact: contact,
            unreadCount: unreadCount,
            messageCount: messageCount,
          ));
        }

        contactsWithStats.sort((a, b) {
          if (a.contact.isRepeater != b.contact.isRepeater) {
            return a.contact.isRepeater ? 1 : -1;
          }

          final aHasUnread = a.unreadCount > 0;
          final bHasUnread = b.unreadCount > 0;
          if (aHasUnread != bHasUnread) {
            return bHasUnread ? 1 : -1;
          }

          final aHasMessages = a.messageCount > 0;
          final bHasMessages = b.messageCount > 0;
          if (aHasMessages != bHasMessages) {
            return bHasMessages ? 1 : -1;
          }

          if (a.unreadCount != b.unreadCount) {
            return b.unreadCount.compareTo(a.unreadCount);
          }

          return b.contact.lastSeen.compareTo(a.contact.lastSeen);
        });

        yield contactsWithStats
            .map((e) => ContactWithUnread(
                contact: e.contact, unreadCount: e.unreadCount))
            .toList(growable: false);
      }
    } finally {
      await contactsSub.cancel();
      await messagesSub.cancel();
      await controller.close();
    }
  }

  /// Watch contacts with unread counts for a specific companion (stream)
  /// Reacts to changes in both contacts and messages tables
  Stream<List<ContactWithUnread>> watchContactsWithUnreadByCompanion(
      String companionKey) async* {
    // Manually merge streams using StreamController
    final controller = StreamController<void>();

    // Listen to contacts changes for this companion
    final contactsSub =
        watchContactsByCompanion(companionKey).listen((contacts) {
      if (!controller.isClosed) controller.add(null);
    });

    // Listen to messages changes
    final messagesSub = db.messagesDao.watchAllMessages().listen((_) {
      if (!controller.isClosed) controller.add(null);
    });

    // Emit initial value
    controller.add(null);

    try {
      await for (final _ in controller.stream) {
        final contactsList = await getContactsByCompanion(companionKey);
        final contactsWithStats =
            <({ContactData contact, int unreadCount, int messageCount})>[];

        for (final contact in contactsList) {
          final unreadCount = await db.messagesDao
              .getUnreadCountByContactForCompanion(contact.hash, companionKey);
          final messageCount = await db.messagesDao
              .getMessageCountByContactForCompanion(contact.hash, companionKey);
          contactsWithStats.add((
            contact: contact,
            unreadCount: unreadCount,
            messageCount: messageCount,
          ));
        }

        contactsWithStats.sort((a, b) {
          if (a.contact.isRepeater != b.contact.isRepeater) {
            return a.contact.isRepeater ? 1 : -1;
          }

          final aHasUnread = a.unreadCount > 0;
          final bHasUnread = b.unreadCount > 0;
          if (aHasUnread != bHasUnread) {
            return bHasUnread ? 1 : -1;
          }

          final aHasMessages = a.messageCount > 0;
          final bHasMessages = b.messageCount > 0;
          if (aHasMessages != bHasMessages) {
            return bHasMessages ? 1 : -1;
          }

          if (a.unreadCount != b.unreadCount) {
            return b.unreadCount.compareTo(a.unreadCount);
          }

          return b.contact.lastSeen.compareTo(a.contact.lastSeen);
        });

        yield contactsWithStats
            .map((e) => ContactWithUnread(
                contact: e.contact, unreadCount: e.unreadCount))
            .toList(growable: false);
      }
    } finally {
      await contactsSub.cancel();
      await messagesSub.cancel();
      await controller.close();
    }
  }
}
