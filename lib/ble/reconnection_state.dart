// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

/// Reconnection states for BLE device auto-reconnection
enum ReconnectionState {
  /// Not reconnecting
  idle,

  /// Waiting before next attempt (backoff delay)
  waiting,

  /// Actively scanning for device
  scanning,

  /// Attempting to connect to device
  connecting,

  /// Auto-reconnect is disabled
  disabled,
}

extension ReconnectionStateExtension on ReconnectionState {
  String get displayName {
    switch (this) {
      case ReconnectionState.idle:
        return 'Idle';
      case ReconnectionState.waiting:
        return 'Waiting to retry...';
      case ReconnectionState.scanning:
        return 'Scanning for device...';
      case ReconnectionState.connecting:
        return 'Reconnecting...';
      case ReconnectionState.disabled:
        return 'Reconnection disabled';
    }
  }
}
