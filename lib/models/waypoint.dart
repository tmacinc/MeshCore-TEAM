// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:drift/drift.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:latlong2/latlong.dart';

/// Waypoint model for marking important locations
/// Matches Android Waypoint entity
class Waypoint {
  final String id;
  final String? meshId;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final WaypointType waypointType;
  final String creatorNodeId;
  final int createdAt;
  final bool isReceived;
  final bool isVisible;
  final bool isNew;

  Waypoint({
    required this.id,
    this.meshId,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.waypointType,
    required this.creatorNodeId,
    required this.createdAt,
    required this.isReceived,
    required this.isVisible,
    required this.isNew,
  });

  /// Create Waypoint from database WaypointData
  factory Waypoint.fromData(WaypointData data) {
    return Waypoint(
      id: data.id,
      meshId: data.meshId,
      name: data.name,
      description: data.description,
      latitude: data.latitude,
      longitude: data.longitude,
      waypointType: WaypointType.fromString(data.waypointType),
      creatorNodeId: data.creatorNodeId,
      createdAt: data.createdAt,
      isReceived: data.isReceived,
      isVisible: data.isVisible,
      isNew: data.isNew,
    );
  }

  /// Convert to WaypointsCompanion for database insertion
  WaypointsCompanion toCompanion() {
    return WaypointsCompanion.insert(
      id: id,
      meshId: meshId != null ? Value(meshId) : const Value.absent(),
      name: name,
      description: Value(description),
      latitude: latitude,
      longitude: longitude,
      waypointType: waypointType.name.toUpperCase(),
      creatorNodeId: creatorNodeId,
      createdAt: createdAt,
      isReceived: Value(isReceived),
      isVisible: Value(isVisible),
      isNew: Value(isNew),
    );
  }

  /// Get LatLng for map display
  LatLng get location => LatLng(latitude, longitude);

  /// Created at as DateTime
  DateTime get createdAtDateTime {
    return DateTime.fromMillisecondsSinceEpoch(createdAt);
  }

  /// Whether this waypoint was created by the user (not received)
  bool get isUserCreated => !isReceived;

  /// Waypoint icon emoji
  String get icon => waypointType.icon;

  /// Waypoint type display name
  String get typeDisplayName => waypointType.displayName;

  Waypoint copyWith({
    String? id,
    String? meshId,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    WaypointType? waypointType,
    String? creatorNodeId,
    int? createdAt,
    bool? isReceived,
    bool? isVisible,
    bool? isNew,
  }) {
    return Waypoint(
      id: id ?? this.id,
      meshId: meshId ?? this.meshId,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      waypointType: waypointType ?? this.waypointType,
      creatorNodeId: creatorNodeId ?? this.creatorNodeId,
      createdAt: createdAt ?? this.createdAt,
      isReceived: isReceived ?? this.isReceived,
      isVisible: isVisible ?? this.isVisible,
      isNew: isNew ?? this.isNew,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Waypoint) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types of waypoints with display names and emoji icons
/// Matches Android WaypointType enum
enum WaypointType {
  camp('Camp', '⛺'),
  meetup('Meetup', '📍'),
  danger('Danger', '⚠️'),
  game('Game Area', '🦌'),
  stand('Deer Stand', '🪑'),
  water('Water', '💧'),
  vehicle('Vehicle', '🚗'),
  custom('Custom', '📌');

  final String displayName;
  final String icon;

  const WaypointType(this.displayName, this.icon);

  /// Parse from string (case-insensitive)
  static WaypointType fromString(String value) {
    final normalized = value.toUpperCase();
    for (final type in WaypointType.values) {
      if (type.name.toUpperCase() == normalized) {
        return type;
      }
    }
    return WaypointType.custom;
  }
}
