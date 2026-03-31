// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

/// Application settings model
/// Matches Android AppPreferences
class AppSettings {
  // Location settings
  final String locationSource; // 'phone' or 'companion'

  // Telemetry settings
  final bool telemetryEnabled;
  final String? telemetryChannelHash;
  final String? telemetryChannelName;
  final int telemetryIntervalSeconds; // 30-180s
  final int telemetryMinDistanceMeters; // 50-500m

  // Notification settings
  final bool notificationsEnabled;
  final bool notificationSoundEnabled;
  final bool notificationVibrateEnabled;

  // Map settings
  final String mapProvider; // 'mapnik', 'satellite', etc.
  final bool mapTrackUpMode; // true = track-up, false = north-up
  final double mapZoomLevel; // 10.0-18.0
  final bool mapShowTrackedUserNames;
  final bool mapShowWaypointNames;
  final bool mapShowContactPaths;
  final bool distanceRingsEnabled;
  final String distanceRingInterval; // '500m', '1km', '2km'

  // Connection settings
  final String? lastConnectedDevice;
  final bool autoReconnectEnabled;
  final bool manualDisconnect;
  final String? currentCompanionPublicKey;
  final bool campModeEnabled;
  final bool smartForwardingEnabled;
  final String forwardingAlgorithmMode;

  // Background location
  final bool backgroundLocationEnabled;

  // Battery optimization
  final bool batteryOptimizationRequested;

  // Service state
  final bool serviceWasRunning;

  const AppSettings({
    this.locationSource = LocationSource.phone,
    this.telemetryEnabled = false,
    this.telemetryChannelHash,
    this.telemetryChannelName,
    this.telemetryIntervalSeconds = 60,
    this.telemetryMinDistanceMeters = 100,
    this.notificationsEnabled = true,
    this.notificationSoundEnabled = true,
    this.notificationVibrateEnabled = true,
    this.mapProvider = 'mapnik',
    this.mapTrackUpMode = false,
    this.mapZoomLevel = 15.0,
    this.mapShowTrackedUserNames = true,
    this.mapShowWaypointNames = true,
    this.mapShowContactPaths = false,
    this.distanceRingsEnabled = false,
    this.distanceRingInterval = '500m',
    this.lastConnectedDevice,
    this.autoReconnectEnabled = false,
    this.manualDisconnect = false,
    this.currentCompanionPublicKey,
    this.campModeEnabled = false,
    this.smartForwardingEnabled = true,
    this.forwardingAlgorithmMode = ForwardingAlgorithmMode.forwardingV1,
    this.backgroundLocationEnabled = false,
    this.batteryOptimizationRequested = false,
    this.serviceWasRunning = false,
  });

  AppSettings copyWith({
    String? locationSource,
    bool? telemetryEnabled,
    String? telemetryChannelHash,
    String? telemetryChannelName,
    int? telemetryIntervalSeconds,
    int? telemetryMinDistanceMeters,
    bool? notificationsEnabled,
    bool? notificationSoundEnabled,
    bool? notificationVibrateEnabled,
    String? mapProvider,
    bool? mapTrackUpMode,
    double? mapZoomLevel,
    bool? mapShowTrackedUserNames,
    bool? mapShowWaypointNames,
    bool? mapShowContactPaths,
    bool? distanceRingsEnabled,
    String? distanceRingInterval,
    String? lastConnectedDevice,
    bool? autoReconnectEnabled,
    bool? manualDisconnect,
    String? currentCompanionPublicKey,
    bool? campModeEnabled,
    bool? smartForwardingEnabled,
    String? forwardingAlgorithmMode,
    bool? serviceWasRunning,
    bool? backgroundLocationEnabled,
    bool? batteryOptimizationRequested,
  }) {
    return AppSettings(
      locationSource: locationSource ?? this.locationSource,
      telemetryEnabled: telemetryEnabled ?? this.telemetryEnabled,
      telemetryChannelHash: telemetryChannelHash ?? this.telemetryChannelHash,
      telemetryChannelName: telemetryChannelName ?? this.telemetryChannelName,
      telemetryIntervalSeconds:
          telemetryIntervalSeconds ?? this.telemetryIntervalSeconds,
      telemetryMinDistanceMeters:
          telemetryMinDistanceMeters ?? this.telemetryMinDistanceMeters,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationSoundEnabled:
          notificationSoundEnabled ?? this.notificationSoundEnabled,
      notificationVibrateEnabled:
          notificationVibrateEnabled ?? this.notificationVibrateEnabled,
      mapProvider: mapProvider ?? this.mapProvider,
      mapTrackUpMode: mapTrackUpMode ?? this.mapTrackUpMode,
      mapZoomLevel: mapZoomLevel ?? this.mapZoomLevel,
      mapShowTrackedUserNames:
          mapShowTrackedUserNames ?? this.mapShowTrackedUserNames,
      mapShowWaypointNames: mapShowWaypointNames ?? this.mapShowWaypointNames,
      mapShowContactPaths: mapShowContactPaths ?? this.mapShowContactPaths,
      distanceRingsEnabled: distanceRingsEnabled ?? this.distanceRingsEnabled,
      distanceRingInterval: distanceRingInterval ?? this.distanceRingInterval,
      lastConnectedDevice: lastConnectedDevice ?? this.lastConnectedDevice,
      autoReconnectEnabled: autoReconnectEnabled ?? this.autoReconnectEnabled,
      manualDisconnect: manualDisconnect ?? this.manualDisconnect,
      currentCompanionPublicKey:
          currentCompanionPublicKey ?? this.currentCompanionPublicKey,
      campModeEnabled: campModeEnabled ?? this.campModeEnabled,
      smartForwardingEnabled:
          smartForwardingEnabled ?? this.smartForwardingEnabled,
      forwardingAlgorithmMode:
          forwardingAlgorithmMode ?? this.forwardingAlgorithmMode,
      backgroundLocationEnabled:
          backgroundLocationEnabled ?? this.backgroundLocationEnabled,
      batteryOptimizationRequested:
          batteryOptimizationRequested ?? this.batteryOptimizationRequested,
      serviceWasRunning: serviceWasRunning ?? this.serviceWasRunning,
    );
  }
}

/// Location source constants
class LocationSource {
  static const String phone = 'phone';
  static const String companion = 'companion';
}

/// Map provider constants
class MapProvider {
  static const String mapnik = 'mapnik'; // OpenStreetMap
  static const String satellite = 'satellite'; // Satellite imagery (legacy)

  // Additional providers (mirrors TEAM map provider options)
  static const String topo = 'topo';
  static const String usgsSat = 'usgs_sat';
  static const String usgsTopo = 'usgs_topo';
  static const String hot = 'hot';
  static const String esriSat = 'esri_sat';
  static const String carto = 'carto';

  // Legacy IDs from earlier Flutter iterations (normalized in UI/service)
  static const String openTopoLegacy = 'opentopo';
  static const String usgsSatelliteLegacy = 'usgs_satellite';
  static const String humanitarianLegacy = 'humanitarian';
  static const String esriSatelliteLegacy = 'esri_satellite';
  static const String cartoVoyagerLegacy = 'carto_voyager';
}

/// Distance ring interval constants
class DistanceRingInterval {
  static const String meters500 = '500m';
  static const String km1 = '1km';
  static const String km2 = '2km';
}

class ForwardingAlgorithmMode {
  static const String forwardingV1 = 'forwardingV1';
  static const String topology = 'topology';
  static const String auto = 'auto';

  static const Set<String> values = <String>{
    forwardingV1,
    topology,
    auto,
  };
}
