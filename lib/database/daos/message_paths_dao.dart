// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'message_paths_dao.g.dart';

/// DAO for per-message radio path observations (see MessagePaths table doc).
@DriftAccessor(tables: [MessagePaths])
class MessagePathsDao extends DatabaseAccessor<AppDatabase>
    with _$MessagePathsDaoMixin {
  MessagePathsDao(super.db);

  /// Get all observed paths for a message, oldest first.
  Future<List<MessagePathData>> getPathsByMessage(String messageId) {
    return (select(messagePaths)
          ..where((t) => t.messageId.equals(messageId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.receivedAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Insert a newly-correlated path observation for a message. Silently
  /// ignores a conflict on the (messageId, pathBytes) unique constraint --
  /// correlation can run concurrently for the same message (delivered via
  /// PUSH and then again via a later sync), so this is the atomic
  /// alternative to an application-side check-then-insert race.
  Future<void> insertPath(MessagePathsCompanion path) {
    return into(messagePaths).insert(path, mode: InsertMode.insertOrIgnore);
  }

  /// Delete paths older than a timestamp (retention cleanup).
  Future<int> deletePathsOlderThan(int timestamp) {
    return (delete(messagePaths)
          ..where((t) => t.receivedAt.isSmallerThanValue(timestamp)))
        .go();
  }
}
