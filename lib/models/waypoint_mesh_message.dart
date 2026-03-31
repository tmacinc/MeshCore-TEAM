// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:meshcore_team/models/route_payload.dart';

/// TEAM-compatible waypoint sharing message.
///
/// Format (new): `#WAY:meshId|name|lat|lon|description|type|routeCoords`
/// Format (legacy): `#WAY:name|lat|lon|description|type`
///
/// Multi-part route messages (when route coords exceed single-message limit):
/// Part 1:   `#WAY:meshId|name|lat|lon|description|type|routeCoords_chunk|1/N`
/// Part 2+:  `#WRC:meshId|routeCoords_chunk|2/N`
///
/// Route color is encoded as a `@C:AARRGGBB` prefix in the description field.
/// Older clients without color support will display the prefix as part of the
/// description text — harmless and fully backward-compatible.

/// Prefix a description with the route color tag (if non-null).
String _addColorPrefix(String description, int? colorValue) {
  if (colorValue == null) return description;
  return '@C:${colorValue.toRadixString(16).padLeft(8, '0').toUpperCase()}$description';
}

/// Strip an optional `@C:AARRGGBB` prefix from a description.
({String description, int? colorValue}) _stripColorPrefix(String raw) {
  final match = RegExp(r'^@C:([0-9A-Fa-f]{8})').firstMatch(raw);
  if (match == null) return (description: raw, colorValue: null);
  final hex = match.group(1)!;
  final value = int.tryParse(hex, radix: 16);
  return (description: raw.substring(match.end), colorValue: value);
}

class WaypointMeshMessage {
  static const String prefix = '#WAY:';

  final String? meshId;
  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final String type;
  final List<LatLng> routePoints;
  final int? colorValue;

  const WaypointMeshMessage({
    required this.meshId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.type,
    this.routePoints = const <LatLng>[],
    this.colorValue,
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

      final rawDesc = parts[4];
      final (:description, :colorValue) = _stripColorPrefix(rawDesc);

      return WaypointMeshMessage(
        meshId: parts[0].isEmpty ? null : parts[0],
        name: parts[1],
        latitude: lat,
        longitude: lon,
        description: description,
        type: parts[5],
        routePoints: decodeRouteCoordinatesFromMesh(
          parts.length >= 7 ? parts[6] : null,
        ),
        colorValue: colorValue,
      );
    }

    if (parts.length >= 5) {
      final lat = double.tryParse(parts[1]);
      final lon = double.tryParse(parts[2]);
      if (lat == null || lon == null) return null;

      final rawDesc = parts[3];
      final (:description, :colorValue) = _stripColorPrefix(rawDesc);

      return WaypointMeshMessage(
        meshId: null,
        name: parts[0],
        latitude: lat,
        longitude: lon,
        description: description,
        type: parts[4],
        colorValue: colorValue,
      );
    }

    return null;
  }

  /// Check if a `#WAY:` message has multi-part indicator (8th field = "1/N").
  static ({bool isMultiPart, int totalParts})? parsePartInfo(String content) {
    if (!content.startsWith(prefix)) return null;
    final parts = content.substring(prefix.length).split('|');
    if (parts.length < 8) return null;
    final partField = parts[7];
    final match = RegExp(r'^(\d+)/(\d+)$').firstMatch(partField);
    if (match == null) return null;
    final total = int.parse(match.group(2)!);
    return (isMultiPart: total > 1, totalParts: total);
  }

  String encode() {
    final mesh = meshId ?? '';
    final encodedRoute =
        routePoints.isEmpty ? '' : encodeRouteCoordinatesForMesh(routePoints);
    final desc = _addColorPrefix(description, colorValue);
    return '$prefix$mesh|$name|$latitude|$longitude|$desc|$type|$encodedRoute';
  }

  /// Encode with a multi-part indicator appended.
  String encodeWithPartInfo(String routeChunk, int partNum, int totalParts) {
    final mesh = meshId ?? '';
    final desc = _addColorPrefix(description, colorValue);
    return '$prefix$mesh|$name|$latitude|$longitude|$desc|$type|$routeChunk|$partNum/$totalParts';
  }

  /// Split this message into multiple frames if it exceeds [maxBytes].
  /// Returns a list of ready-to-send message strings.
  /// If it fits in a single frame, returns a single-element list (no part info).
  List<String> splitForMesh(int maxBytes) {
    final single = encode();
    debugPrint(
        '[WaypointSplit] 📏 Single encode: ${utf8.encode(single).length} bytes, limit=$maxBytes');
    debugPrint('[WaypointSplit] 📝 Full encoded: $single');
    if (utf8.encode(single).length <= maxBytes) {
      debugPrint('[WaypointSplit] ✅ Fits in single frame');
      return [single];
    }

    // Build the base message without route coordinates to measure overhead.
    final mesh = meshId ?? '';
    final desc = _addColorPrefix(description, colorValue);
    final basePart = '$prefix$mesh|$name|$latitude|$longitude|$desc|$type|';
    // Reserve space for part info suffix like "|1/10" (max "|NN/NN" = 6 chars)
    const partInfoReserve = 6;

    final baseBytes = utf8.encode(basePart).length;
    final firstChunkMaxBytes = maxBytes - baseBytes - partInfoReserve;

    // For continuation messages: `#WRC:meshId|routeChunk|2/N`
    final contPrefix = '${WaypointRouteContinuation.prefix}$mesh|';
    final contPrefixBytes = utf8.encode(contPrefix).length;
    final contChunkMaxBytes = maxBytes - contPrefixBytes - partInfoReserve;

    if (firstChunkMaxBytes <= 0 || contChunkMaxBytes <= 0) {
      // Base message itself is too large; send what we can.
      return [single];
    }

    final fullCoords =
        routePoints.isEmpty ? '' : encodeRouteCoordinatesForMesh(routePoints);
    final coordBytes = utf8.encode(fullCoords);
    debugPrint(
        '[WaypointSplit] 📐 Coords: ${coordBytes.length} bytes, firstChunkMax=$firstChunkMaxBytes, contChunkMax=$contChunkMaxBytes');
    debugPrint('[WaypointSplit] 📝 Full coords: $fullCoords');

    // Split coordinate bytes into chunks respecting '~' boundaries.
    final chunks = <String>[];
    var offset = 0;
    var isFirst = true;
    while (offset < coordBytes.length) {
      final limit = isFirst ? firstChunkMaxBytes : contChunkMaxBytes;
      var end = offset + limit;
      if (end >= coordBytes.length) {
        end = coordBytes.length;
      } else {
        // Back up to the last '~' separator to avoid splitting a coordinate.
        final slice = utf8.decode(coordBytes.sublist(offset, end));
        final lastSep = slice.lastIndexOf('~');
        if (lastSep > 0) {
          end = offset + utf8.encode(slice.substring(0, lastSep + 1)).length;
        }
      }
      chunks.add(utf8.decode(coordBytes.sublist(offset, end)));
      offset = end;
      isFirst = false;
    }

    if (chunks.isEmpty) return [single];

    final totalParts = chunks.length;
    final messages = <String>[];

    // First message: full WAY with first chunk + part info.
    messages.add(
      '$basePart${chunks[0]}|1/$totalParts',
    );

    // Continuation messages.
    for (var i = 1; i < chunks.length; i++) {
      messages.add(
        '$contPrefix${chunks[i]}|${i + 1}/$totalParts',
      );
    }

    for (var i = 0; i < messages.length; i++) {
      debugPrint(
          '[WaypointSplit] 📦 Part ${i + 1}/$totalParts (${utf8.encode(messages[i]).length} bytes): ${messages[i]}');
    }

    return messages;
  }
}

/// Continuation message for multi-part route coordinates.
///
/// Format: `#WRC:meshId|routeCoords_chunk|partNum/totalParts`
class WaypointRouteContinuation {
  static const String prefix = '#WRC:';

  final String meshId;
  final String routeChunk;
  final int partNum;
  final int totalParts;

  const WaypointRouteContinuation({
    required this.meshId,
    required this.routeChunk,
    required this.partNum,
    required this.totalParts,
  });

  static bool isContinuationMessage(String content) =>
      content.startsWith(prefix);

  static WaypointRouteContinuation? parse(String content) {
    if (!content.startsWith(prefix)) return null;
    final data = content.substring(prefix.length);
    final parts = data.split('|');
    if (parts.length < 3) return null;

    final meshId = parts[0];
    final routeChunk = parts[1];
    final partField = parts[2];

    final match = RegExp(r'^(\d+)/(\d+)$').firstMatch(partField);
    if (match == null) return null;

    return WaypointRouteContinuation(
      meshId: meshId,
      routeChunk: routeChunk,
      partNum: int.parse(match.group(1)!),
      totalParts: int.parse(match.group(2)!),
    );
  }
}
