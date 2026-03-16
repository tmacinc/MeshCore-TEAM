// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:meshcore_team/models/capability_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable snapshot of a peer's advertised capabilities at a point in time.
class ContactCapabilityState {
  static const Duration staleTtl = Duration(hours: 12);

  final int capFlags;
  final DateTime observedAt;

  const ContactCapabilityState({
    required this.capFlags,
    required this.observedAt,
  });

  bool get isCustomFirmware =>
      (capFlags & CapabilityMessage.flagCustomFirmware) != 0;
  bool get supportsForwarding =>
      (capFlags & CapabilityMessage.flagForwardingCapable) != 0;
  bool get supportsAutonomous =>
      (capFlags & CapabilityMessage.flagAutonomousCapable) != 0;
  bool get autonomousEnabled =>
      (capFlags & CapabilityMessage.flagAutonomousEnabled) != 0;
  bool get smartForwardingActive =>
      (capFlags & CapabilityMessage.flagSmartForwardingActive) != 0;

  bool get isStale => DateTime.now().difference(observedAt) >= staleTtl;

  Map<String, dynamic> toJson() => {
        'flags': capFlags,
        'observedAtMs': observedAt.millisecondsSinceEpoch,
      };

  factory ContactCapabilityState.fromJson(Map<String, dynamic> json) {
    return ContactCapabilityState(
      capFlags: (json['flags'] as int?) ?? 0,
      observedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['observedAtMs'] as int?) ?? 0),
    );
  }

  @override
  String toString() =>
      'ContactCapabilityState(flags=0x${capFlags.toRadixString(16).padLeft(2, "0")}'
      ' customFw=$isCustomFirmware fwd=$supportsForwarding auto=$supportsAutonomous'
      ' stale=$isStale observedAt=$observedAt)';
}

/// Stores and retrieves per-peer capability state learned from `#CAP:` messages.
///
/// Keyed by sender name (the only reliable identifier in channel messages).
/// State expires after 12 hours. Expired or missing state should be treated
/// as stock firmware by all consumers.
///
/// Backed by SharedPreferences so capability info survives app restarts.
/// Stale entries are not deleted immediately — they are left in place and
/// reported as stale to consumers, which treats them as stock.
class ContactCapabilityService extends ChangeNotifier {
  static const String _prefsKey = 'contact_capability_state_v1';

  final SharedPreferences _prefs;

  // senderName -> latest state
  final Map<String, ContactCapabilityState> _states = {};

  ContactCapabilityService(this._prefs) {
    _loadFromPrefs();
  }

  // --- Public API ---

  /// Returns the capability state for [senderName], or null if never seen.
  /// Callers should check [ContactCapabilityState.isStale] before using.
  ContactCapabilityState? getByName(String senderName) => _states[senderName];

  /// Convenience: returns true if we have fresh, confirmed forwarding support
  /// for [senderName]. False means unknown, stale, or stock.
  bool hasConfirmedForwarding(String senderName) {
    final s = _states[senderName];
    return s != null && !s.isStale && s.supportsForwarding;
  }

  /// Convenience: returns true if we have fresh, confirmed autonomous support.
  bool hasConfirmedAutonomous(String senderName) {
    final s = _states[senderName];
    return s != null && !s.isStale && s.supportsAutonomous;
  }

  /// All known entries (may include stale). Iterate and check [isStale].
  Map<String, ContactCapabilityState> get allKnown => Map.unmodifiable(_states);

  /// Update capability state from an incoming parsed [CapabilityMessage].
  /// Always stores version 1 flags regardless of received version
  /// (forward-compatibility: unknown bits are stored but not interpreted).
  Future<void> updateFromMessage(
      String senderName, CapabilityMessage msg) async {
    final state = ContactCapabilityState(
      capFlags: msg.flags,
      observedAt: DateTime.now(),
    );
    _states[senderName] = state;
    debugPrint('[CapabilityService] 📡 Updated "$senderName": $state');
    notifyListeners();
    await _saveToPrefs();
  }

  // --- Persistence ---

  void _loadFromPrefs() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final state = ContactCapabilityState.fromJson(
            entry.value as Map<String, dynamic>);
        _states[entry.key] = state;
      }
      debugPrint(
          '[CapabilityService] 📂 Loaded ${_states.length} capability entries from prefs');
    } catch (e) {
      debugPrint('[CapabilityService] ⚠️ Failed to load from prefs: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final map = _states.map((name, state) => MapEntry(name, state.toJson()));
      await _prefs.setString(_prefsKey, jsonEncode(map));
    } catch (e) {
      debugPrint('[CapabilityService] ⚠️ Failed to save to prefs: $e');
    }
  }
}
