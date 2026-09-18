// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import '../database.dart';
import '../tables.dart';
import '../../models/unread_models.dart';

part 'channels_dao.g.dart';

/// DAO for managing mesh network channels
/// Matches Android ChannelDao functionality
@DriftAccessor(tables: [Channels, Messages])
class ChannelsDao extends DatabaseAccessor<AppDatabase>
    with _$ChannelsDaoMixin {
  ChannelsDao(super.db);

  /// Get all channels ordered by channel index
  Future<List<ChannelData>> getAllChannels() {
    return (select(channels)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.channelIndex, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Get channels for a specific companion device
  Future<List<ChannelData>> getChannelsByCompanion(String companionKey) {
    return (select(channels)
          ..where((t) => t.companionDeviceKey.equals(companionKey))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.channelIndex, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Channels to show while [companionKey] is the connected radio: its own
  /// channels, plus every team channel whichever radio it came from.
  ///
  /// Team channels belong to the phone. After a radio switch they are untied
  /// from the old radio (companionDeviceKey null) and may not be on the new
  /// one yet, so filtering by radio alone would hide them — which looked
  /// exactly like the sync had deleted them.
  ///
  /// With no radio selected, [companionKey] is null and only team channels
  /// are shown. [getChannelsByCompanion] stays radio-only: slot allocation
  /// must only see the radio's own slots.
  Future<List<ChannelData>> getVisibleChannels(String? companionKey) {
    return (select(channels)
          ..where((t) => _visibleTo(t, companionKey))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.channelIndex, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Stream<List<ChannelData>> watchVisibleChannels(String? companionKey) {
    return (select(channels)
          ..where((t) => _visibleTo(t, companionKey))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.channelIndex, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Expression<bool> _visibleTo($ChannelsTable t, String? companionKey) {
    final isTeam = t.isTeam.equals(true);
    if (companionKey == null || companionKey.isEmpty) return isTeam;
    return t.companionDeviceKey.equals(companionKey) | isTeam;
  }

  /// Get a single channel by hash
  Future<ChannelData?> getChannelByHash(int hash) {
    return (select(channels)..where((t) => t.hash.equals(hash)))
        .getSingleOrNull();
  }

  /// Get a channel by firmware index
  Future<ChannelData?> getChannelByIndex(int index) {
    return (select(channels)..where((t) => t.channelIndex.equals(index)))
        .getSingleOrNull();
  }

  /// Get the public channel (index 0)
  Future<ChannelData?> getPublicChannel() {
    return (select(channels)
          ..where((t) => t.isPublic.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get all private channels
  Future<List<ChannelData>> getPrivateChannels() {
    return (select(channels)
          ..where((t) => t.isPublic.equals(false))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.channelIndex, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Insert or update a channel
  Future<int> upsertChannel(ChannelsCompanion channel) {
    return into(channels).insertOnConflictUpdate(channel);
  }

  /// Update channel name
  Future<List<ChannelData>> getAllChannelsOnce() => select(channels).get();

  /// A slot index for a channel the phone keeps but the radio doesn't hold.
  /// Negative, so it can never collide with a real slot (0 is the public
  /// channel), and unique among channels already parked.
  Future<int> nextSentinelIndex() async {
    final lowest = await (selectOnly(channels)
          ..addColumns([channels.channelIndex.min()]))
        .map((row) => row.read(channels.channelIndex.min()))
        .getSingleOrNull();
    final floor = (lowest == null || lowest > 0) ? 0 : lowest;
    return floor - 1;
  }

  /// Channels the phone keeps whatever the radio says: team channels, and
  /// channels created offline that no radio holds yet.
  static bool isPhoneOwned(ChannelData c) => c.isTeam || !c.firmwareConfirmed;

  Future<void> updateChannel(ChannelsCompanion changes) async {
    await (update(channels)..where((t) => t.hash.equals(changes.hash.value)))
        .write(changes);
  }

  Future<void> updateChannelName(int hash, String name) {
    return (update(channels)..where((t) => t.hash.equals(hash)))
        .write(ChannelsCompanion(
      name: Value(name),
    ));
  }

  /// Toggle location sharing for a channel
  Future<void> toggleLocationSharing(int hash, bool shareLocation) {
    return (update(channels)..where((t) => t.hash.equals(hash)))
        .write(ChannelsCompanion(
      shareLocation: Value(shareLocation),
    ));
  }

  /// Set favorite status for a channel
  Future<void> setFavorite(int hash, bool favorite) {
    return (update(channels)..where((t) => t.hash.equals(hash)))
        .write(ChannelsCompanion(isFavorite: Value(favorite)));
  }

  /// Set notification mode for a channel
  Future<void> setNotificationMode(int hash, String mode) {
    return (update(channels)..where((t) => t.hash.equals(hash)))
        .write(ChannelsCompanion(
      notificationMode: Value(mode),
    ));
  }

  /// Delete a channel
  Future<int> deleteChannel(int hash) {
    return (delete(channels)..where((t) => t.hash.equals(hash))).go();
  }

  /// Delete a channel for a specific companion device
  Future<int> deleteChannelForCompanion(int hash, String companionKey) {
    return (delete(channels)
          ..where((t) =>
              t.hash.equals(hash) & t.companionDeviceKey.equals(companionKey)))
        .go();
  }

  /// Delete all channels for a companion device
  /// Deletes a radio's channels when switching away from it. Team channels
  /// belong to the phone, so they are kept: they are untied from the old
  /// radio and marked as not on it, ready to be offered to the new one.
  Future<int> deleteChannelsByCompanion(String companionKey) async {
    return db.transaction(() async {
      var sentinelIndex = -1;
      final teamChannels = await (select(channels)
            ..where((t) =>
                t.companionDeviceKey.equals(companionKey) &
                (t.isTeam.equals(true) | t.firmwareConfirmed.equals(false))))
          .get();

      for (final channel in teamChannels) {
        await (update(channels)..where((t) => t.hash.equals(channel.hash)))
            .write(ChannelsCompanion(
          companionDeviceKey: const Value(null),
          firmwareConfirmed: const Value(false),
          channelIndex: Value(sentinelIndex--),
        ));
      }

      return (delete(channels)
            ..where((t) =>
                t.companionDeviceKey.equals(companionKey) &
                t.isTeam.equals(false) &
                t.firmwareConfirmed.equals(true)))
          .go();
    });
  }

  /// Delete all channels then insert replacements in a single transaction.
  /// Preserves user-set fields (notificationMode, isFavorite) across syncs.
  Future<void> setTeamFlag(int hash, bool isTeam) {
    return (update(channels)..where((t) => t.hash.equals(hash)))
        .write(ChannelsCompanion(isTeam: Value(isTeam)));
  }

  Future<List<ChannelData>> getTeamChannels() {
    return (select(channels)..where((t) => t.isTeam.equals(true))).get();
  }

  /// Replaces the channel list with what the radio reports.
  ///
  /// The radio is the source of truth for its own slots, with one exception:
  /// a team channel is owned by the phone. One the radio doesn't have is kept
  /// and marked [Channels.firmwareConfirmed] false, so its history survives a
  /// radio switch and the user can be offered to add it back.
  ///
  /// Those keep a negative sentinel slot index, matching the Team Link
  /// branch, so they can never collide with a real slot.
  Future<void> replaceAllChannels(List<ChannelsCompanion> replacements) {
    return db.transaction(() async {
      final existing = await select(channels).get();
      final preserved = {
        for (final c in existing)
          c.hash: (
            notificationMode: c.notificationMode,
            isFavorite: c.isFavorite,
            isTeam: c.isTeam,
          )
      };
      final fromFirmware = {for (final c in replacements) c.hash.value};

      // Kept even though the radio doesn't report them: team channels, and
      // channels created offline that were never pushed to a radio.
      final orphanedTeam = existing
          .where((c) => isPhoneOwned(c) && !fromFirmware.contains(c.hash))
          .toList();

      await delete(channels).go();

      for (final channel in replacements) {
        final saved = preserved[channel.hash.value];
        final merged = saved != null
            ? channel.copyWith(
                notificationMode: Value(saved.notificationMode),
                isFavorite: Value(saved.isFavorite),
                isTeam: Value(saved.isTeam),
              )
            : channel;
        await into(channels).insertOnConflictUpdate(merged);
      }

      var sentinelIndex = -1;
      for (final channel in orphanedTeam) {
        await into(channels).insertOnConflictUpdate(
          channel.toCompanion(false).copyWith(
                channelIndex: Value(sentinelIndex--),
                firmwareConfirmed: const Value(false),
              ),
        );
      }
    });
  }

  /// Watch all channels (stream)
  Stream<List<ChannelData>> watchAllChannels() {
    return (select(channels)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.channelIndex, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watch channels for a specific companion (stream)
  Stream<List<ChannelData>> watchChannelsByCompanion(String companionKey) {
    return (select(channels)
          ..where((t) => t.companionDeviceKey.equals(companionKey))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.channelIndex, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watch a single channel by hash (stream)
  Stream<ChannelData?> watchChannel(int hash) {
    return (select(channels)..where((t) => t.hash.equals(hash)))
        .watchSingleOrNull();
  }

  /// Watch the public channel (stream)
  Stream<ChannelData?> watchPublicChannel() {
    return (select(channels)
          ..where((t) => t.isPublic.equals(true))
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Get all channels with unread counts, sorted with unread first
  Future<List<ChannelWithUnread>> getAllChannelsWithUnread() async {
    final allChannels = await getAllChannels();
    final channelsWithUnread = <ChannelWithUnread>[];

    for (final channel in allChannels) {
      final unreadCount =
          await db.messagesDao.getUnreadCountByChannel(channel.hash);
      channelsWithUnread.add(ChannelWithUnread(
        channel: channel,
        unreadCount: unreadCount,
      ));
    }

    // Sort by unread count (descending), then by channel index (ascending)
    channelsWithUnread.sort((a, b) {
      if (a.unreadCount != b.unreadCount) {
        return b.unreadCount.compareTo(a.unreadCount);
      }
      return a.channel.channelIndex.compareTo(b.channel.channelIndex);
    });

    return channelsWithUnread;
  }

  Future<List<ChannelWithUnread>> _buildChannelsWithUnread(
      List<ChannelData> channelsList) async {
    final channelsWithUnread = <ChannelWithUnread>[];
    for (final channel in channelsList) {
      final unreadCount =
          await db.messagesDao.getUnreadCountByChannel(channel.hash);
      channelsWithUnread
          .add(ChannelWithUnread(channel: channel, unreadCount: unreadCount));
    }
    channelsWithUnread.sort((a, b) {
      if (a.unreadCount != b.unreadCount) {
        return b.unreadCount.compareTo(a.unreadCount);
      }
      return a.channel.channelIndex.compareTo(b.channel.channelIndex);
    });
    return channelsWithUnread;
  }

  /// Watch all channels with unread counts (stream)
  /// Reacts to changes in both channels and messages tables
  Stream<List<ChannelWithUnread>> watchAllChannelsWithUnread() async* {
    // Yield current state immediately — no debounce for first emit
    yield await _buildChannelsWithUnread(await getAllChannels());

    final controller = StreamController<void>();
    final channelsSub = watchAllChannels().listen((_) {
      if (!controller.isClosed) controller.add(null);
    });
    final messagesSub = db.messagesDao.watchMessageCount().listen((_) {
      if (!controller.isClosed) controller.add(null);
    });

    try {
      await for (final _ in controller.stream
          .debounceTime(const Duration(milliseconds: 500))) {
        yield await _buildChannelsWithUnread(await getAllChannels());
      }
    } finally {
      await channelsSub.cancel();
      await messagesSub.cancel();
      await controller.close();
    }
  }

  /// Watch channels with unread counts for a specific companion device
  Stream<List<ChannelWithUnread>> watchChannelsWithUnreadByCompanion(
      String? companionKey) async* {
    // Yield current state immediately — no debounce for first emit
    yield await _buildChannelsWithUnread(
        await getVisibleChannels(companionKey));

    final controller = StreamController<void>();
    final channelsSub = watchVisibleChannels(companionKey).listen((_) {
      if (!controller.isClosed) controller.add(null);
    });
    final messagesSub = db.messagesDao.watchMessageCount().listen((_) {
      if (!controller.isClosed) controller.add(null);
    });

    try {
      await for (final _ in controller.stream
          .debounceTime(const Duration(milliseconds: 500))) {
        yield await _buildChannelsWithUnread(
            await getVisibleChannels(companionKey));
      }
    } finally {
      await channelsSub.cancel();
      await messagesSub.cancel();
      await controller.close();
    }
  }
}
