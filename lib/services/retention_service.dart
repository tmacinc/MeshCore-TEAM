// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meshcore_team/database/database.dart';

/// Removes local data past its fixed retention period.
///
/// Last known peer locations are never pruned: if a team member goes missing,
/// their last position is what matters.
class RetentionService {
  /// How long the position trail behind each team member is kept.
  static const Duration positionHistoryRetention = Duration(hours: 24);

  /// How long a node stays in the heard-nearby list after its last advert.
  static const Duration heardAdvertRetention = Duration(days: 7);

  static const Duration _interval = Duration(hours: 1);

  final AppDatabase _database;
  Timer? _timer;

  RetentionService(this._database);

  void start() {
    if (_timer != null) return;
    unawaited(prune());
    _timer = Timer.periodic(_interval, (_) => unawaited(prune()));
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> prune() async {
    try {
      final cutoff = DateTime.now()
          .subtract(positionHistoryRetention)
          .millisecondsSinceEpoch;
      final removed =
          await _database.peersDao.deletePositionsOlderThan(cutoff);
      if (removed > 0) {
        debugPrint('[Retention] 🧹 Removed $removed position points');
      }

      final advertCutoff = DateTime.now()
          .subtract(heardAdvertRetention)
          .millisecondsSinceEpoch;
      final staleAdverts =
          await _database.heardAdvertsDao.deleteOlderThan(advertCutoff);
      if (staleAdverts > 0) {
        debugPrint('[Retention] 🧹 Removed $staleAdverts heard adverts');
      }
    } catch (e) {
      debugPrint('[Retention] ⚠️ Prune failed: $e');
    }
  }
}
