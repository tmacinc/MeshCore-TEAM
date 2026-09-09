// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import 'package:meshcore_team/l10n/app_localizations.dart';
import 'package:meshcore_team/models/app_language.dart';

/// A single georeferenced image tile extracted from a KMZ GroundOverlay.
class KmzTile {
  final String imagePath; // Absolute path to the extracted image file
  final double north;
  final double south;
  final double east;
  final double west;
  final double rotation; // Degrees, counter-clockwise. 0 for most maps.
  final int level; // KMZ pyramid level (1=lowest detail, 7=highest). -1 if unknown.

  const KmzTile({
    required this.imagePath,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    this.rotation = 0.0,
    this.level = -1,
  });

  /// Extracts the KMZ pyramid level from the tile image filename.
  /// Garmin Custom Maps encode level as "_L{n}_" in the filename.
  static int parseLevelFromFilename(String filename) {
    final match = RegExp(r'_L(\d+)_').firstMatch(p.basename(filename));
    if (match == null) return -1;
    return int.tryParse(match.group(1)!) ?? -1;
  }
}

/// Result of a successful KMZ import.
class KmzImportResult {
  final String mapId; // UUID used as folder name
  final String name;
  final String dirPath;
  final List<KmzTile> tiles;
  final double boundsNorth;
  final double boundsSouth;
  final double boundsEast;
  final double boundsWest;

  const KmzImportResult({
    required this.mapId,
    required this.name,
    required this.dirPath,
    required this.tiles,
    required this.boundsNorth,
    required this.boundsSouth,
    required this.boundsEast,
    required this.boundsWest,
  });
}

/// Service that imports Garmin-style KMZ files (GroundOverlay-based raster maps).
///
/// A Garmin Custom Map KMZ is a ZIP archive containing:
///   - doc.kml  — KML file with one or more <GroundOverlay> elements
///   - *.jpg / *.png  — the image tiles referenced by the KML
///
/// Each GroundOverlay specifies a <LatLonBox> bounding box and an optional
/// <rotation> value.  Large maps are tiled into many GroundOverlay entries.
class KmzImportService {
  /// Imports a KMZ file and extracts tiles to the app documents directory.
  ///
  /// Returns a [KmzImportResult] on success, or throws on failure.
  Future<KmzImportResult> importKmz(
    File kmzFile, {
    void Function(int done, int total)? onProgress,
  }) async {
    final bytes = await kmzFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Locate doc.kml (may be at root or inside a subdirectory)
    final kmlEntry = archive.files.firstWhere(
      (f) => f.isFile && p.basename(f.name).toLowerCase() == 'doc.kml',
      orElse: () => throw FormatException(
          lookupAppLocalizations(AppLanguage.localeFor()).kmzNoDocKml),
    );

    final kmlContent = String.fromCharCodes(kmlEntry.content as List<int>);
    final document = XmlDocument.parse(kmlContent);

    final overlays = document.findAllElements('GroundOverlay').toList();
    if (overlays.isEmpty) {
      throw FormatException(
          lookupAppLocalizations(AppLanguage.localeFor()).kmzNoGroundOverlay);
    }

    // Derive a map name: first GroundOverlay name, then KMZ filename
    final firstNameEl = overlays.first.findElements('name').firstOrNull;
    final mapName = (firstNameEl?.innerText.trim().isNotEmpty == true)
        ? firstNameEl!.innerText.trim()
        : p.basenameWithoutExtension(kmzFile.path);

    // Create output directory: {appDocuments}/imported_maps/{uuid}
    final mapId = _generateId();
    final docsDir = await getApplicationDocumentsDirectory();
    final dirPath = p.join(docsDir.path, 'imported_maps', mapId);
    await Directory(dirPath).create(recursive: true);

    // Build a lookup from archive filename → ArchiveFile for image extraction
    final archiveMap = <String, ArchiveFile>{};
    for (final f in archive.files) {
      if (f.isFile) {
        archiveMap[f.name] = f;
        // Also index by basename for relative references
        archiveMap[p.basename(f.name)] = f;
      }
    }

    // KML <href> paths are relative to the KML file's directory
    final kmlDir = p.dirname(kmlEntry.name);

    final tiles = <KmzTile>[];
    double? north, south, east, west;
    final totalOverlays = overlays.length;

    for (int i = 0; i < overlays.length; i++) {
      final overlay = overlays[i];
      onProgress?.call(i + 1, totalOverlays);

      final hrefEl = overlay
          .findElements('Icon')
          .expand((e) => e.findElements('href'))
          .firstOrNull;
      if (hrefEl == null) continue;
      final href = hrefEl.innerText.trim();
      if (href.isEmpty) continue;

      // Resolve the image path relative to the KML
      final resolved = kmlDir == '.' || kmlDir.isEmpty
          ? href
          : p.join(kmlDir, href).replaceAll('\\', '/');

      final imageEntry = archiveMap[resolved] ?? archiveMap[p.basename(href)];
      if (imageEntry == null) continue;

      // Extract image to output directory, preserving the original filename
      final imageFileName = p.basename(href);
      final imagePath = p.join(dirPath, imageFileName);
      final outFile = File(imagePath);
      // Multiple overlays might reference the same file — only write once
      if (!outFile.existsSync()) {
        await outFile.writeAsBytes(imageEntry.content as List<int>);
      }

      // Parse LatLonBox
      final llBox = overlay.findElements('LatLonBox').firstOrNull;
      if (llBox == null) continue;

      final tileNorth = _parseDouble(llBox, 'north');
      final tileSouth = _parseDouble(llBox, 'south');
      final tileEast = _parseDouble(llBox, 'east');
      final tileWest = _parseDouble(llBox, 'west');
      final tileRotation = _parseDouble(llBox, 'rotation', fallback: 0.0);

      if (tileNorth == null ||
          tileSouth == null ||
          tileEast == null ||
          tileWest == null) continue;

      tiles.add(KmzTile(
        imagePath: imagePath,
        north: tileNorth,
        south: tileSouth,
        east: tileEast,
        west: tileWest,
        rotation: tileRotation!,
        level: KmzTile.parseLevelFromFilename(imageFileName),
      ));

      // Accumulate overall bounds
      north = north == null ? tileNorth : math.max(north, tileNorth);
      south = south == null ? tileSouth : math.min(south, tileSouth);
      east = east == null ? tileEast : math.max(east, tileEast);
      west = west == null ? tileWest : math.min(west, tileWest);
    }

    print('[KMZ] importKmz complete: ${tiles.length} tiles extracted to $dirPath');

    if (tiles.isEmpty) {
      // Clean up empty directory
      await Directory(dirPath).delete(recursive: true);
      throw FormatException(
          lookupAppLocalizations(AppLanguage.localeFor()).kmzNoUsableTiles);
    }

    return KmzImportResult(
      mapId: mapId,
      name: mapName,
      dirPath: dirPath,
      tiles: tiles,
      boundsNorth: north!,
      boundsSouth: south!,
      boundsEast: east!,
      boundsWest: west!,
    );
  }

  /// Loads tile metadata for a previously imported map from its directory.
  ///
  /// Re-parses the saved doc.kml to reconstruct [KmzTile] list.
  /// Returns null if the directory or kml is missing.
  Future<List<KmzTile>?> loadTiles(String dirPath) async {
    final kmlFile = File(p.join(dirPath, 'doc.kml'));
    if (!kmlFile.existsSync()) return null;

    final kmlContent = await kmlFile.readAsString();
    final document = XmlDocument.parse(kmlContent);
    final overlays = document.findAllElements('GroundOverlay').toList();

    final tiles = <KmzTile>[];
    for (final overlay in overlays) {
      final hrefEl = overlay
          .findElements('Icon')
          .expand((e) => e.findElements('href'))
          .firstOrNull;
      if (hrefEl == null) continue;
      final href = hrefEl.innerText.trim();
      if (href.isEmpty) continue;

      final imagePath = p.join(dirPath, p.basename(href));
      if (!File(imagePath).existsSync()) continue;

      final llBox = overlay.findElements('LatLonBox').firstOrNull;
      if (llBox == null) continue;

      final tileNorth = _parseDouble(llBox, 'north');
      final tileSouth = _parseDouble(llBox, 'south');
      final tileEast = _parseDouble(llBox, 'east');
      final tileWest = _parseDouble(llBox, 'west');
      final tileRotation = _parseDouble(llBox, 'rotation', fallback: 0.0);

      if (tileNorth == null ||
          tileSouth == null ||
          tileEast == null ||
          tileWest == null) continue;

      tiles.add(KmzTile(
        imagePath: imagePath,
        north: tileNorth,
        south: tileSouth,
        east: tileEast,
        west: tileWest,
        rotation: tileRotation!,
        level: KmzTile.parseLevelFromFilename(p.basename(href)),
      ));
    }
    print('[KMZ] loadTiles: ${tiles.length} tiles loaded from $dirPath');
    return tiles.isEmpty ? null : tiles;
  }

  /// Saves a minimal doc.kml into [dirPath] so tiles can be reconstructed
  /// later without keeping the original KMZ.
  Future<void> saveManifest(String dirPath, List<KmzTile> tiles) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('<Document>');
    for (final tile in tiles) {
      final imageName = p.basename(tile.imagePath);
      buffer.writeln('  <GroundOverlay>');
      buffer.writeln('    <Icon><href>$imageName</href></Icon>');
      buffer.writeln('    <LatLonBox>');
      buffer.writeln('      <north>${tile.north}</north>');
      buffer.writeln('      <south>${tile.south}</south>');
      buffer.writeln('      <east>${tile.east}</east>');
      buffer.writeln('      <west>${tile.west}</west>');
      buffer.writeln('      <rotation>${tile.rotation}</rotation>');
      buffer.writeln('    </LatLonBox>');
      buffer.writeln('  </GroundOverlay>');
    }
    buffer.writeln('</Document>');
    buffer.writeln('</kml>');
    await File(p.join(dirPath, 'doc.kml')).writeAsString(buffer.toString());
  }

  double? _parseDouble(XmlElement parent, String tag, {double? fallback}) {
    final el = parent.findElements(tag).firstOrNull;
    if (el == null) return fallback;
    return double.tryParse(el.innerText.trim()) ?? fallback;
  }

  String _generateId() {
    // Simple UUID v4-like ID without requiring the uuid package here
    final rand = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${bytes.sublist(0, 4).map(hex).join()}'
        '-${bytes.sublist(4, 6).map(hex).join()}'
        '-${bytes.sublist(6, 8).map(hex).join()}'
        '-${bytes.sublist(8, 10).map(hex).join()}'
        '-${bytes.sublist(10).map(hex).join()}';
  }
}
