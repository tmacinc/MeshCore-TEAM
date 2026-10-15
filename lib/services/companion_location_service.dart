// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';

/// Decides whether this device's own position comes from the companion
/// radio's GPS or from the phone.
///
/// With location source = companion, the companion is used only while it has
/// a fresh GPS fix. Whenever it doesn't (no fix, fix lost, stale, or not
/// connected), the whole app — map and telemetry — falls back to the phone,
/// which is the more reliable source.
///
/// Also owns the companion telemetry poll that supplies those fixes. It lives
/// here rather than in the map so it keeps running when the map isn't being
/// drawn (backgrounded, another tab, screen off).
class CompanionLocationService extends ChangeNotifier {
  static const Duration pollInterval = Duration(seconds: 2);

  /// A companion fix older than this is treated as no fix.
  static const Duration maxFixAge = Duration(seconds: 10);

  final SettingsService _settings;
  final ConnectionViewModel _connectionViewModel;

  Timer? _pollTimer;
  bool _usingCompanion = false;
  DateTime? _notifiedFixTime;
  bool _started = false;

  CompanionLocationService({
    required SettingsService settings,
    required ConnectionViewModel connectionViewModel,
  })  : _settings = settings,
        _connectionViewModel = connectionViewModel;

  bool get wantsCompanion =>
      _settings.settings.locationSource == LocationSource.companion;

  /// True while the companion's position should be used. False means use the
  /// phone.
  bool get usingCompanion => _usingCompanion;

  /// Companion position, or null whenever the phone should be used instead.
  double? get latitude =>
      _usingCompanion ? _connectionViewModel.companionLatitude : null;
  double? get longitude =>
      _usingCompanion ? _connectionViewModel.companionLongitude : null;

  void start() {
    if (_started) return;
    _started = true;

    _settings.addListener(_update);
    _connectionViewModel.addListener(_update);
    _update();
  }

  void _update() {
    final shouldPoll = wantsCompanion && _connectionViewModel.isConnected;
    if (shouldPoll && _pollTimer == null) {
      _pollTimer = Timer.periodic(pollInterval, (_) {
        unawaited(_connectionViewModel.requestCompanionTelemetry());
        // Re-check fix age every tick so a fix that stops refreshing (no
        // telemetry responses at all) still falls back to the phone.
        _update();
      });
      unawaited(_connectionViewModel.requestCompanionTelemetry());
    } else if (!shouldPoll && _pollTimer != null) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }

    final fixTime = _connectionViewModel.companionGpsFixTime;
    final hasFreshFix = _connectionViewModel.hasCompanionGpsFix &&
        fixTime != null &&
        DateTime.now().difference(fixTime) < maxFixAge;
    final using = shouldPoll && hasFreshFix;

    // Notify on every switch, and on every new fix while the companion is in
    // use, so listeners can follow its position without also watching
    // ConnectionViewModel.
    final switched = using != _usingCompanion;
    final newFix = using && fixTime != _notifiedFixTime;
    if (!switched && !newFix) return;

    _usingCompanion = using;
    _notifiedFixTime = using ? fixTime : null;
    if (switched) {
      debugPrint('[CompanionLocation] 📍 '
          '${using ? 'Using companion GPS' : 'Using phone GPS'}'
          ' (wantsCompanion=$wantsCompanion'
          ' connected=${_connectionViewModel.isConnected}'
          ' hasFix=${_connectionViewModel.hasCompanionGpsFix}'
          ' fixAgeMs=${fixTime == null ? null : DateTime.now().difference(fixTime).inMilliseconds})');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_started) {
      _settings.removeListener(_update);
      _connectionViewModel.removeListener(_update);
    }
    super.dispose();
  }
}
