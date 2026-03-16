/// Sync phase enumeration matching Android implementation
enum SyncPhase {
  idle,
  syncingContacts,
  syncingChannels,
  syncingMessages,
  complete,
}

/// Overall sync status with progress tracking
class SyncStatus {
  final SyncPhase phase;
  final int currentItem;
  final int totalItems;
  final bool isComplete;

  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.currentItem = 0,
    this.totalItems = 0,
    this.isComplete = false,
  });

  /// Calculate progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (totalItems > 0) {
      return currentItem / totalItems;
    }
    return 0.0;
  }

  SyncStatus copyWith({
    SyncPhase? phase,
    int? currentItem,
    int? totalItems,
    bool? isComplete,
  }) {
    return SyncStatus(
      phase: phase ?? this.phase,
      currentItem: currentItem ?? this.currentItem,
      totalItems: totalItems ?? this.totalItems,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  String toString() {
    return 'SyncStatus(phase: $phase, current: $currentItem, total: $totalItems, complete: $isComplete, progress: ${(progressPercentage * 100).toStringAsFixed(1)}%)';
  }
}

/// Contact sync progress tracking
class ContactSyncProgress {
  final int currentCount;
  final int totalCount;
  final bool isComplete;

  const ContactSyncProgress({
    this.currentCount = 0,
    this.totalCount = 0,
    this.isComplete = false,
  });

  ContactSyncProgress copyWith({
    int? currentCount,
    int? totalCount,
    bool? isComplete,
  }) {
    return ContactSyncProgress(
      currentCount: currentCount ?? this.currentCount,
      totalCount: totalCount ?? this.totalCount,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  String toString() {
    return 'ContactSyncProgress(current: $currentCount, total: $totalCount, complete: $isComplete)';
  }
}

/// Channel sync progress tracking
class ChannelSyncProgress {
  final int currentCount;
  final int totalCount;
  final bool isComplete;

  const ChannelSyncProgress({
    this.currentCount = 0,
    this.totalCount = 0,
    this.isComplete = false,
  });

  ChannelSyncProgress copyWith({
    int? currentCount,
    int? totalCount,
    bool? isComplete,
  }) {
    return ChannelSyncProgress(
      currentCount: currentCount ?? this.currentCount,
      totalCount: totalCount ?? this.totalCount,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  String toString() {
    return 'ChannelSyncProgress(current: $currentCount, total: $totalCount, complete: $isComplete)';
  }
}
