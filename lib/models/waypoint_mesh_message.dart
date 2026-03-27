// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:latlong2/latlong.dart';

import 'package:meshcore_team/models/route_payload.dart';

/// TEAM-compatible waypoint sharing message.
///
/// Format (new): `#WAY:meshId|name|lat|lon|description|type|routeCoords`
/// Format (legacy): `#WAY:name|lat|lon|description|type`
class WaypointMeshMessage {
  static const String prefix = '#WAY:';

  final String? meshId;
  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final String type;
  final List<LatLng> routePoints;

  const WaypointMeshMessage({
    required this.meshId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.type,
    this.routePoints = const <LatLng>[],
  });

  static bool isWaypointMessage(String content) => content.startsWith(prefix);

  static WaypointMeshMessage? parse(String content) {
    if (!content.startsWith(prefix)) return null;

    final data = content.substring(prefix.length);
    final parts = data.split('|');

    // Support both new format (with meshId) and legacy format (without).
    if (parts.length >= 6) {
      final lat = double.tryParse(parts[2]);
      final lon = double.tryParse(parts[3]);
      if (lat == null || lon == null) return null;

      return WaypointMeshMessage(
        meshId: parts[0].isEmpty ? null : parts[0],
        name: parts[1],
        latitude: lat,
        longitude: lon,
        description: parts[4],
        type: parts[5],
        routePoints: decodeRouteCoordinatesFromMesh(
          parts.length >= 7 ? parts[6] : null,
        ),
      );
    }

    if (parts.length >= 5) {
      final lat = double.tryParse(parts[1]);
      final lon = double.tryParse(parts[2]);
      if (lat == null || lon == null) return null;

      return WaypointMeshMessage(
        meshId: null,
        name: parts[0],
        latitude: lat,
        longitude: lon,
        description: parts[3],
        type: parts[4],
      );
    }

    return null;
  }

  String encode() {
    final mesh = meshId ?? '';
    final encodedRoute = routePoints.isEmpty
        ? ''
        : encodeRouteCoordinatesForMesh(routePoints);
    return '$prefix$mesh|$name|$latitude|$longitude|$description|$type|$encodedRoute';
  }
}
