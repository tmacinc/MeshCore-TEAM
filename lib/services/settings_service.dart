// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meshcore_team/models/app_settings.dart';

/// Settings service managing app preferences via SharedPreferences
/// Matches Android AppPreferences functionality
class SettingsService extends ChangeNotifier {
  static const String _keyLocationSource = 'location_source';
  static const String _keyTelemetryEnabled = 'telemetry_enabled';
  static const String _keyTelemetryChannelHash = 'telemetry_channel_hash';
  static const String _keyTelemetryChannelName = 'telemetry_channel_name';
  static const String _keyTelemetryIntervalSeconds =
      'telemetry_interval_seconds';
  static const String _keyTelemetryMinDistanceMeters =
      'telemetry_min_distance_meters';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyNotificationSoundEnabled =
      'notification_sound_enabled';
  static const String _keyNotificationVibrateEnabled =
      'notification_vibrate_enabled';
  static const String _keyMapProvider = 'map_provider';
  static const String _keyMapTrackUpMode = 'map_track_up_mode';
  static const String _keyMapZoomLevel = 'map_zoom_level';
  static const String _keyMapShowTrackedUserNames =
      'map_show_tracked_user_names';
  static const String _keyMapShowWaypointNames =
      'map_show_waypoint_names';
  static const String _keyDistanceRingsEnabled = 'distance_rings_enabled';
  static const String _keyDistanceRingInterval = 'distance_ring_interval';
  static const String _keyLastConnectedDevice = 'last_connected_device';
  static const String _keyAutoReconnectEnabled = 'auto_reconnect_enabled';
  static const String _keyManualDisconnect = 'manual_disconnect';
  static const String _keyCurrentCompanionPublicKey =
      'current_companion_public_key';
  static const String _keyCampModeEnabled = 'camp_mode_enabled';
  static const String _keySmartForwardingEnabled = 'smart_forwarding_enabled';
  static const String _keyForwardingAlgorithmMode = 'forwarding_algorithm_mode';
  static const String _keyBackgroundLocationEnabled =
      'background_location_enabled';
  static const String _keyBatteryOptimizationRequested =
      'battery_optimization_requested';
  static const String _keyServiceWasRunning = 'service_was_running';
  static const String _keyContactLastmod = 'contact_lastmod';

  final SharedPreferences _prefs;
  AppSettings _settings = const AppSettings();
  bool _autoReconnectInProgress = false;

  // Stream controller for companion key changes (for reactive repository filtering)
  final StreamController<String?> _companionKeyController =
      StreamController<String?>.broadcast();

  SettingsService(this._prefs) {
    _loadSettings();
  }

  String _telemetryChannelHashKeyForCompanion(String companionPublicKeyHex) {
    return '${_keyTelemetryChannelHash}_$companionPublicKeyHex';
  }

  String _telemetryChannelNameKeyForCompanion(String companionPublicKeyHex) {
    return '${_keyTelemetryChannelName}_$companionPublicKeyHex';
  }

  String? _getTelemetryChannelHashForCompanion(String? companionPublicKeyHex) {
    if (companionPublicKeyHex == null || companionPublicKeyHex.isEmpty) {
      return _prefs.getString(_keyTelemetryChannelHash);
    }

    return _prefs.getString(
          _telemetryChannelHashKeyForCompanion(companionPublicKeyHex),
        ) ??
        _prefs.getString(_keyTelemetryChannelHash);
  }

  String? _getTelemetryChannelNameForCompanion(String? companionPublicKeyHex) {
    if (companionPublicKeyHex == null || companionPublicKeyHex.isEmpty) {
      return _prefs.getString(_keyTelemetryChannelName);
    }

    return _prefs.getString(
          _telemetryChannelNameKeyForCompanion(companionPublicKeyHex),
        ) ??
        _prefs.getString(_keyTelemetryChannelName);
  }

  /// Current settings
  AppSettings get settings => _settings;

  /// True while an automatic reconnect flow is actively trying to restore BLE.
  ///
  /// This is intentionally in-memory only (not persisted) so connection-time
  /// behavior can distinguish manual reconnects from background reconnects.
  bool get isAutoReconnectInProgress => _autoReconnectInProgress;

  void setAutoReconnectInProgress(bool isInProgress) {
    if (_autoReconnectInProgress == isInProgress) return;
    _autoReconnectInProgress = isInProgress;
    notifyListeners();
  }

  /// Stream of current companion public key changes
  /// Repositories use this to reactively filter data by companion
  /// Always emits current value immediately to new subscribers
  Stream<String?> get currentCompanionPublicKeyStream async* {
    // Emit current value immediately
    final currentKey = _settings.currentCompanionPublicKey;
    yield currentKey;

    // Then listen to updates
    await for (final key in _companionKeyController.stream) {
      yield key;
    }
  }

  /// Load all settings from SharedPreferences
  void _loadSettings() {
    final currentCompanionKey = _prefs.getString(_keyCurrentCompanionPublicKey);
    final telemetryChannelHash =
        _getTelemetryChannelHashForCompanion(currentCompanionKey);
    final telemetryChannelName =
        _getTelemetryChannelNameForCompanion(currentCompanionKey);

    _settings = AppSettings(
      locationSource:
          _prefs.getString(_keyLocationSource) ?? LocationSource.phone,
      telemetryEnabled: _prefs.getBool(_keyTelemetryEnabled) ?? false,
      telemetryChannelHash: telemetryChannelHash,
      telemetryChannelName: telemetryChannelName,
      telemetryIntervalSeconds:
          _prefs.getInt(_keyTelemetryIntervalSeconds) ?? 60,
      telemetryMinDistanceMeters:
          _prefs.getInt(_keyTelemetryMinDistanceMeters) ?? 100,
      notificationsEnabled: _prefs.getBool(_keyNotificationsEnabled) ?? true,
      notificationSoundEnabled:
          _prefs.getBool(_keyNotificationSoundEnabled) ?? true,
      notificationVibrateEnabled:
          _prefs.getBool(_keyNotificationVibrateEnabled) ?? true,
      mapProvider: _prefs.getString(_keyMapProvider) ?? MapProvider.mapnik,
      mapTrackUpMode: _prefs.getBool(_keyMapTrackUpMode) ?? false,
      mapZoomLevel: _prefs.getDouble(_keyMapZoomLevel) ?? 15.0,
      mapShowTrackedUserNames:
          _prefs.getBool(_keyMapShowTrackedUserNames) ?? true,
      mapShowWaypointNames:
          _prefs.getBool(_keyMapShowWaypointNames) ?? true,
      distanceRingsEnabled: _prefs.getBool(_keyDistanceRingsEnabled) ?? false,
      distanceRingInterval:
          _prefs.getString(_keyDistanceRingInterval) ?? '500m',
      lastConnectedDevice: _prefs.getString(_keyLastConnectedDevice),
      autoReconnectEnabled: _prefs.getBool(_keyAutoReconnectEnabled) ?? false,
      manualDisconnect: _prefs.getBool(_keyManualDisconnect) ?? false,
      currentCompanionPublicKey: currentCompanionKey,
      campModeEnabled: _prefs.getBool(_keyCampModeEnabled) ?? false,
      smartForwardingEnabled:
          _prefs.getBool(_keySmartForwardingEnabled) ?? true,
      forwardingAlgorithmMode: _sanitizeForwardingAlgorithmMode(
          _prefs.getString(_keyForwardingAlgorithmMode)),
      backgroundLocationEnabled:
          _prefs.getBool(_keyBackgroundLocationEnabled) ?? false,
      batteryOptimizationRequested:
          _prefs.getBool(_keyBatteryOptimizationRequested) ?? false,
      serviceWasRunning: _prefs.getBool(_keyServiceWasRunning) ?? false,
    );
  }

  /// Set location source ('phone' or 'companion')
  Future<void> setBackgroundLocationEnabled(bool enabled) async {
    await _prefs.setBool(_keyBackgroundLocationEnabled, enabled);
    _settings = _settings.copyWith(backgroundLocationEnabled: enabled);
    notifyListeners();
  }

  Future<void> setLocationSource(String source) async {
    await _prefs.setString(_keyLocationSource, source);
    _settings = _settings.copyWith(locationSource: source);
    notifyListeners();
  }

  /// Set telemetry enabled state
  Future<void> setTelemetryEnabled(bool enabled) async {
    await _prefs.setBool(_keyTelemetryEnabled, enabled);
    _settings = _settings.copyWith(telemetryEnabled: enabled);
    notifyListeners();
  }

  /// Set telemetry channel hash (hex string)
  Future<void> setTelemetryChannelHash(String? hash) async {
    final companionKey = _settings.currentCompanionPublicKey;

    // Persist per-companion if possible.
    if (companionKey != null && companionKey.isNotEmpty) {
      final perKey = _telemetryChannelHashKeyForCompanion(companionKey);
      if (hash != null) {
        await _prefs.setString(perKey, hash);
      } else {
        await _prefs.remove(perKey);
      }
    }

    // Also persist the legacy/global key for backward compatibility.
    if (hash != null) {
      await _prefs.setString(_keyTelemetryChannelHash, hash);
    } else {
      await _prefs.remove(_keyTelemetryChannelHash);

      if (companionKey != null && companionKey.isNotEmpty) {
        await _prefs.remove(_telemetryChannelNameKeyForCompanion(companionKey));
      }
      await _prefs.remove(_keyTelemetryChannelName);
    }
    _settings = _settings.copyWith(
      telemetryChannelHash: hash,
      telemetryChannelName:
          hash == null ? null : _settings.telemetryChannelName,
    );
    notifyListeners();
  }

  Future<void> setTelemetryChannelName(String? name) async {
    final companionKey = _settings.currentCompanionPublicKey;

    if (companionKey != null && companionKey.isNotEmpty) {
      final perKey = _telemetryChannelNameKeyForCompanion(companionKey);
      if (name != null && name.isNotEmpty) {
        await _prefs.setString(perKey, name);
      } else {
        await _prefs.remove(perKey);
      }
    }

    if (name != null && name.isNotEmpty) {
      await _prefs.setString(_keyTelemetryChannelName, name);
    } else {
      await _prefs.remove(_keyTelemetryChannelName);
    }

    _settings = _settings.copyWith(
      telemetryChannelName: (name != null && name.isNotEmpty) ? name : null,
    );
    notifyListeners();
  }

  /// Set telemetry interval in seconds (30-180s)
  Future<void> setTelemetryIntervalSeconds(int seconds) async {
    final clamped = seconds.clamp(30, 180);
    await _prefs.setInt(_keyTelemetryIntervalSeconds, clamped);
    _settings = _settings.copyWith(telemetryIntervalSeconds: clamped);
    notifyListeners();
  }

  /// Set minimum distance to trigger telemetry update (50-500m)
  Future<void> setTelemetryMinDistanceMeters(int meters) async {
    final clamped = meters.clamp(50, 500);
    await _prefs.setInt(_keyTelemetryMinDistanceMeters, clamped);
    _settings = _settings.copyWith(telemetryMinDistanceMeters: clamped);
    notifyListeners();
  }

  /// Set notifications enabled state
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationsEnabled, enabled);
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    notifyListeners();
  }

  /// Set notification sound enabled state
  Future<void> setNotificationSoundEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationSoundEnabled, enabled);
    _settings = _settings.copyWith(notificationSoundEnabled: enabled);
    notifyListeners();
  }

  /// Set notification vibrate enabled state
  Future<void> setNotificationVibrateEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationVibrateEnabled, enabled);
    _settings = _settings.copyWith(notificationVibrateEnabled: enabled);
    notifyListeners();
  }

  /// Set map provider ID
  Future<void> setMapProvider(String providerId) async {
    await _prefs.setString(_keyMapProvider, providerId);
    _settings = _settings.copyWith(mapProvider: providerId);
    notifyListeners();
  }

  /// Set map track-up mode (true = track-up, false = north-up)
  Future<void> setMapTrackUpMode(bool isTrackUp) async {
    await _prefs.setBool(_keyMapTrackUpMode, isTrackUp);
    _settings = _settings.copyWith(mapTrackUpMode: isTrackUp);
    notifyListeners();
  }

  /// Set map zoom level (10.0-18.0)
  Future<void> setMapZoomLevel(double zoom) async {
    await _prefs.setDouble(_keyMapZoomLevel, zoom);
    _settings = _settings.copyWith(mapZoomLevel: zoom);
    notifyListeners();
  }

  /// Set tracked-user labels on the map.
  Future<void> setMapShowTrackedUserNames(bool enabled) async {
    await _prefs.setBool(_keyMapShowTrackedUserNames, enabled);
    _settings = _settings.copyWith(mapShowTrackedUserNames: enabled);
    notifyListeners();
  }

  /// Set waypoint/route name labels on the map.
  Future<void> setMapShowWaypointNames(bool enabled) async {
    await _prefs.setBool(_keyMapShowWaypointNames, enabled);
    _settings = _settings.copyWith(mapShowWaypointNames: enabled);
    notifyListeners();
  }

  /// Set distance rings enabled state
  Future<void> setDistanceRingsEnabled(bool enabled) async {
    await _prefs.setBool(_keyDistanceRingsEnabled, enabled);
    _settings = _settings.copyWith(distanceRingsEnabled: enabled);
    notifyListeners();
  }

  /// Set distance ring interval ('500m', '1km', '2km')
  Future<void> setDistanceRingInterval(String interval) async {
    await _prefs.setString(_keyDistanceRingInterval, interval);
    _settings = _settings.copyWith(distanceRingInterval: interval);
    notifyListeners();
  }

  /// Set last connected device MAC address
  Future<void> setLastConnectedDevice(String? deviceAddress) async {
    if (deviceAddress != null) {
      await _prefs.setString(_keyLastConnectedDevice, deviceAddress);
    } else {
      await _prefs.remove(_keyLastConnectedDevice);
    }
    _settings = _settings.copyWith(lastConnectedDevice: deviceAddress);
    notifyListeners();
  }

  /// Set auto-reconnect enabled state
  Future<void> setAutoReconnectEnabled(bool enabled) async {
    await _prefs.setBool(_keyAutoReconnectEnabled, enabled);
    _settings = _settings.copyWith(autoReconnectEnabled: enabled);
    notifyListeners();
  }

  /// Set manual disconnect flag
  Future<void> setManualDisconnect(bool isManual) async {
    await _prefs.setBool(_keyManualDisconnect, isManual);
    _settings = _settings.copyWith(manualDisconnect: isManual);
    notifyListeners();
  }

  /// Set current companion device public key (hex string)
  Future<void> setCurrentCompanionPublicKey(String? publicKeyHex) async {
    // Update _settings synchronously FIRST so synchronous reads get new value immediately
    final telemetryHash = _getTelemetryChannelHashForCompanion(publicKeyHex);
    final telemetryName = _getTelemetryChannelNameForCompanion(publicKeyHex);
    _settings = _settings.copyWith(
      currentCompanionPublicKey: publicKeyHex,
      telemetryChannelHash: telemetryHash,
      telemetryChannelName: telemetryName,
    );
    _companionKeyController.add(publicKeyHex); // Notify repositories
    notifyListeners();

    // Save to SharedPreferences async (don't block on this)
    if (publicKeyHex != null) {
      await _prefs.setString(_keyCurrentCompanionPublicKey, publicKeyHex);
    } else {
      await _prefs.remove(_keyCurrentCompanionPublicKey);
    }
  }

  Future<void> setCampModeEnabled(bool enabled) async {
    await _prefs.setBool(_keyCampModeEnabled, enabled);
    _settings = _settings.copyWith(campModeEnabled: enabled);
    notifyListeners();
  }

  Future<void> setSmartForwardingEnabled(bool enabled) async {
    await _prefs.setBool(_keySmartForwardingEnabled, enabled);
    _settings = _settings.copyWith(smartForwardingEnabled: enabled);
    notifyListeners();
  }

  Future<void> setForwardingAlgorithmMode(String mode) async {
    final sanitized = _sanitizeForwardingAlgorithmMode(mode);
    await _prefs.setString(_keyForwardingAlgorithmMode, sanitized);
    _settings = _settings.copyWith(forwardingAlgorithmMode: sanitized);
    notifyListeners();
  }

  String _sanitizeForwardingAlgorithmMode(String? mode) {
    if (mode == null || !ForwardingAlgorithmMode.values.contains(mode)) {
      return ForwardingAlgorithmMode.forwardingV1;
    }
    return mode;
  }

  /// Set battery optimization requested flag
  Future<void> setBatteryOptimizationRequested(bool requested) async {
    await _prefs.setBool(_keyBatteryOptimizationRequested, requested);
    _settings = _settings.copyWith(batteryOptimizationRequested: requested);
    notifyListeners();
  }

  /// Set service was running flag (for health check)
  Future<void> setServiceWasRunning(bool wasRunning) async {
    await _prefs.setBool(_keyServiceWasRunning, wasRunning);
    _settings = _settings.copyWith(serviceWasRunning: wasRunning);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Contact incremental sync — per-companion lastmod timestamp
  // ---------------------------------------------------------------------------

  String _contactLastmodKeyForCompanion(String companionPublicKeyHex) =>
      '${_keyContactLastmod}_$companionPublicKeyHex';

  /// Returns the most-recent contact lastmod timestamp (seconds) previously
  /// stored for [companionPublicKeyHex], or 0 if not yet set.
  int getContactLastmod(String companionPublicKeyHex) {
    if (companionPublicKeyHex.isEmpty) return 0;
    return _prefs
            .getInt(_contactLastmodKeyForCompanion(companionPublicKeyHex)) ??
        0;
  }

  /// Persists the most-recent contact lastmod timestamp (seconds) so the next
  /// sync to the same companion can use it as the incremental `since` filter.
  Future<void> setContactLastmod(
      String companionPublicKeyHex, int lastmodSeconds) async {
    if (companionPublicKeyHex.isEmpty) return;
    await _prefs.setInt(
        _contactLastmodKeyForCompanion(companionPublicKeyHex), lastmodSeconds);
  }

  /// Clear all settings (reset to defaults)
  /// Clear all settings (reset to defaults)
  Future<void> clearAll() async {
    await _prefs.clear();
    _settings = const AppSettings();
    _companionKeyController.add(null);
    notifyListeners();
  }

  @override
  void dispose() {
    _companionKeyController.close();
    super.dispose();
  }
}
