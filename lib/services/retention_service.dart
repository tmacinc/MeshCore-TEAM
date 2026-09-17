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

  /// How long team channel history is kept. Team history follows the phone
  /// rather than a radio, so without a limit it would grow forever. Other
  /// channels keep their existing behaviour: they last until the channel is
  /// deleted or the radio is switched.
  static const Duration teamMessageRetention = Duration(days: 30);

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

      final teamChannels = await _database.channelsDao.getTeamChannels();
      final messageCutoff = DateTime.now()
          .subtract(teamMessageRetention)
          .millisecondsSinceEpoch;
      final oldMessages =
          await _database.messagesDao.deleteMessagesInChannelsOlderThan(
        teamChannels.map((c) => c.hash).toList(),
        messageCutoff,
      );
      if (oldMessages > 0) {
        debugPrint('[Retention] 🧹 Removed $oldMessages team messages');
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
