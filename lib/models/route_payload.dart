import 'dart:convert';

import 'package:latlong2/latlong.dart';

const String kRoutePayloadPrefix = 'ROUTE_V1:';

/// Preset colors available for routes.
const List<int> kRouteColorPresets = [
  0xFF673AB7, // deepPurple (default)
  0xFFF44336, // red
  0xFF2196F3, // blue
  0xFF4CAF50, // green
  0xFFFF9800, // orange
  0xFFE91E63, // pink
  0xFF009688, // teal
  0xFF795548, // brown
  0xFF607D8B, // blueGrey
  0xFFFFEB3B, // yellow
];

class RoutePayload {
  final String description;
  final List<LatLng> points;
  final int? colorValue;

  const RoutePayload({
    required this.description,
    required this.points,
    this.colorValue,
  });
}

String encodeRoutePayload({
  required String description,
  required List<LatLng> points,
  int? colorValue,
}) {
  final payload = <String, dynamic>{
    'description': description,
    'points': [
      for (final p in points)
        {
          'lat': p.latitude,
          'lon': p.longitude,
        },
    ],
    if (colorValue != null) 'color': colorValue,
  };

  return '$kRoutePayloadPrefix${jsonEncode(payload)}';
}

RoutePayload decodeRoutePayload(
  String rawDescription, {
  required double fallbackLatitude,
  required double fallbackLongitude,
}) {
  final trimmed = rawDescription.trim();
  if (!trimmed.startsWith(kRoutePayloadPrefix)) {
    return RoutePayload(
      description: rawDescription,
      points: [LatLng(fallbackLatitude, fallbackLongitude)],
    );
  }

  final jsonPart = trimmed.substring(kRoutePayloadPrefix.length);
  try {
    final decoded = jsonDecode(jsonPart);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Route payload is not an object');
    }

    final desc = (decoded['description'] as String?) ?? '';
    final colorRaw = decoded['color'];
    final colorValue = colorRaw is int ? colorRaw : null;
    final pointsRaw = decoded['points'];
    final points = <LatLng>[];
    if (pointsRaw is List) {
      for (final item in pointsRaw) {
        if (item is! Map) continue;
        final latNum = item['lat'];
        final lonNum = item['lon'];
        final lat = latNum is num ? latNum.toDouble() : null;
        final lon = lonNum is num ? lonNum.toDouble() : null;
        if (lat == null || lon == null) continue;
        points.add(LatLng(lat, lon));
      }
    }

    if (points.isEmpty) {
      points.add(LatLng(fallbackLatitude, fallbackLongitude));
    }

    return RoutePayload(
        description: desc, points: points, colorValue: colorValue);
  } catch (_) {
    return RoutePayload(
      description: rawDescription,
      points: [LatLng(fallbackLatitude, fallbackLongitude)],
    );
  }
}

String encodeRouteCoordinatesForMesh(List<LatLng> points) {
  return points
      .map((p) =>
          '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}')
      .join('~');
}

List<LatLng> decodeRouteCoordinatesFromMesh(String? encoded) {
  if (encoded == null || encoded.trim().isEmpty) return const <LatLng>[];

  final points = <LatLng>[];
  final chunks = encoded.split('~');
  for (final chunk in chunks) {
    final parts = chunk.split(',');
    if (parts.length != 2) continue;

    final lat = double.tryParse(parts[0]);
    final lon = double.tryParse(parts[1]);
    if (lat == null || lon == null) continue;
    points.add(LatLng(lat, lon));
  }
  return points;
}
