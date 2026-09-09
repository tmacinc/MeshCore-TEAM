// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'package:path_provider/path_provider.dart';

import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/l10n/app_localizations.dart';
import 'package:meshcore_team/models/app_language.dart';
import 'package:meshcore_team/models/map_tile_providers.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import 'package:meshcore_team/services/map_tile_cache_service.dart';

/// Largest imported overlay map that may be packed into a team config.
///
/// The export builds the whole ZIP in memory before encoding it, so a
/// multi-hundred-megabyte MBTiles archive would exhaust the heap. Maps above
/// this are skipped and reported back to the caller.
const int kMaxShareableOverlayBytes = 150 * 1024 * 1024;

/// Progress reported during export or import.
class TeamConfigProgress {
  final String phase;
  final int current;
  final int total;

  const TeamConfigProgress({
    required this.phase,
    required this.current,
    required this.total,
  });
}

/// Preview of a team config ZIP before full import.
class TeamConfigPreview {
  final int version;
  final String? name;
  final String? creatorName;
  final String? description;
  final List<TeamConfigChannelEntry> channels;
  final List<TeamConfigWaypointEntry> waypoints;
  final List<TeamConfigTileAreaEntry> tileAreas;
  final TeamConfigRadioSettings? radioSettings;
  final int tileCount;
  final int tileSizeBytes;
  final List<TeamConfigOverlayMapEntry> overlayMaps;
  final int overlayMapSizeBytes;

  const TeamConfigPreview({
    required this.version,
    this.name,
    this.creatorName,
    this.description,
    required this.channels,
    required this.waypoints,
    required this.tileAreas,
    this.radioSettings,
    required this.tileCount,
    required this.tileSizeBytes,
    this.overlayMaps = const [],
    this.overlayMapSizeBytes = 0,
  });
}

class TeamConfigChannelEntry {
  final String name;
  final String sharedKeyHex;
  final bool isPublic;
  final bool shareLocation;

  const TeamConfigChannelEntry({
    required this.name,
    required this.sharedKeyHex,
    required this.isPublic,
    required this.shareLocation,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sharedKeyHex': sharedKeyHex,
        'isPublic': isPublic,
        'shareLocation': shareLocation,
      };

  factory TeamConfigChannelEntry.fromJson(Map<String, dynamic> json) =>
      TeamConfigChannelEntry(
        name: json['name'] as String,
        sharedKeyHex: json['sharedKeyHex'] as String,
        isPublic: json['isPublic'] as bool? ?? false,
        shareLocation: json['shareLocation'] as bool? ?? false,
      );
}

class TeamConfigWaypointEntry {
  final String id;
  final String? meshId;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String waypointType;
  final String creatorNodeId;
  final int createdAt;

  const TeamConfigWaypointEntry({
    required this.id,
    this.meshId,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.waypointType,
    required this.creatorNodeId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        if (meshId != null) 'meshId': meshId,
        'name': name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'waypointType': waypointType,
        'creatorNodeId': creatorNodeId,
        'createdAt': createdAt,
      };

  factory TeamConfigWaypointEntry.fromJson(Map<String, dynamic> json) =>
      TeamConfigWaypointEntry(
        id: json['id'] as String,
        meshId: json['meshId'] as String?,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        waypointType: json['waypointType'] as String,
        creatorNodeId: json['creatorNodeId'] as String? ?? '',
        createdAt: json['createdAt'] as int,
      );
}

class TeamConfigRadioSettings {
  final double frequencyMHz;
  final double bandwidthKHz;
  final int spreadingFactor;
  final int codingRate;

  const TeamConfigRadioSettings({
    required this.frequencyMHz,
    required this.bandwidthKHz,
    required this.spreadingFactor,
    required this.codingRate,
  });

  Map<String, dynamic> toJson() => {
        'frequencyMHz': frequencyMHz,
        'bandwidthKHz': bandwidthKHz,
        'spreadingFactor': spreadingFactor,
        'codingRate': codingRate,
      };

  factory TeamConfigRadioSettings.fromJson(Map<String, dynamic> json) =>
      TeamConfigRadioSettings(
        frequencyMHz: (json['frequencyMHz'] as num).toDouble(),
        bandwidthKHz: (json['bandwidthKHz'] as num).toDouble(),
        spreadingFactor: json['spreadingFactor'] as int,
        codingRate: json['codingRate'] as int,
      );
}

class TeamConfigTileAreaEntry {
  final String name;
  final String providerId;
  final double north;
  final double south;
  final double east;
  final double west;
  final int minZoom;
  final int maxZoom;
  final int tileCount;
  final int sizeBytes;

  const TeamConfigTileAreaEntry({
    required this.name,
    required this.providerId,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    required this.minZoom,
    required this.maxZoom,
    required this.tileCount,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'providerId': providerId,
        'north': north,
        'south': south,
        'east': east,
        'west': west,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'tileCount': tileCount,
        'sizeBytes': sizeBytes,
      };

  factory TeamConfigTileAreaEntry.fromJson(Map<String, dynamic> json) =>
      TeamConfigTileAreaEntry(
        name: json['name'] as String,
        providerId: json['providerId'] as String,
        north: (json['north'] as num).toDouble(),
        south: (json['south'] as num).toDouble(),
        east: (json['east'] as num).toDouble(),
        west: (json['west'] as num).toDouble(),
        minZoom: json['minZoom'] as int,
        maxZoom: json['maxZoom'] as int,
        tileCount: json['tileCount'] as int? ?? 0,
        sizeBytes: json['sizeBytes'] as int? ?? 0,
      );
}

class TeamConfigOverlayMapEntry {
  final String id;
  final String name;
  final int tileCount;
  final int sizeBytes;
  final double north;
  final double south;
  final double east;
  final double west;

  /// 'kmz' | 'mbtiles' | 'geopdf'. Absent in configs written before MBTiles
  /// support existed, which is why [fromJson] defaults it to 'kmz'.
  final String layerType;

  /// Native zoom range for tiled layers; null for KMZ.
  final int? minZoom;
  final int? maxZoom;

  const TeamConfigOverlayMapEntry({
    required this.id,
    required this.name,
    required this.tileCount,
    required this.sizeBytes,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    this.layerType = 'kmz',
    this.minZoom,
    this.maxZoom,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tileCount': tileCount,
        'sizeBytes': sizeBytes,
        'north': north,
        'south': south,
        'east': east,
        'west': west,
        'layerType': layerType,
        if (minZoom != null) 'minZoom': minZoom,
        if (maxZoom != null) 'maxZoom': maxZoom,
      };

  factory TeamConfigOverlayMapEntry.fromJson(Map<String, dynamic> json) =>
      TeamConfigOverlayMapEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        tileCount: json['tileCount'] as int? ?? 0,
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        north: (json['north'] as num).toDouble(),
        south: (json['south'] as num).toDouble(),
        east: (json['east'] as num).toDouble(),
        west: (json['west'] as num).toDouble(),
        layerType: json['layerType'] as String? ?? 'kmz',
        minZoom: json['minZoom'] as int?,
        maxZoom: json['maxZoom'] as int?,
      );
}

/// Result of an import operation.
class TeamConfigImportResult {
  final int channelsImported;
  final int channelsSkipped;
  final int waypointsImported;
  final int waypointsSkipped;
  final int tilesImported;
  final int tilesSkipped;
  final int tileAreasImported;
  final bool radioSettingsApplied;
  final int overlayMapsImported;
  final int overlayMapsSkipped;

  const TeamConfigImportResult({
    this.channelsImported = 0,
    this.channelsSkipped = 0,
    this.waypointsImported = 0,
    this.waypointsSkipped = 0,
    this.tilesImported = 0,
    this.tilesSkipped = 0,
    this.tileAreasImported = 0,
    this.radioSettingsApplied = false,
    this.overlayMapsImported = 0,
    this.overlayMapsSkipped = 0,
  });

  /// Human-readable summary in the user's language.
  ///
  /// [toString] stays English for logs and crash reports; this is what the
  /// snackbar after an import shows.
  String describe(AppLocalizations l10n) {
    final parts = <String>[];
    if (channelsImported > 0) parts.add(l10n.countChannels(channelsImported));
    if (waypointsImported > 0) {
      parts.add(l10n.countWaypoints(waypointsImported));
    }
    if (tilesImported > 0) parts.add(l10n.countTiles(tilesImported));
    if (overlayMapsImported > 0) {
      parts.add(l10n.countOverlayMaps(overlayMapsImported));
    }
    if (radioSettingsApplied) parts.add(l10n.radioSettingsItem);
    final imported = parts.isEmpty
        ? l10n.nothingNew
        : l10n.importedItems(parts.join(', '));

    final skipped = <String>[];
    if (channelsSkipped > 0) skipped.add(l10n.countChannels(channelsSkipped));
    if (waypointsSkipped > 0) {
      skipped.add(l10n.countWaypoints(waypointsSkipped));
    }
    if (tilesSkipped > 0) skipped.add(l10n.countTiles(tilesSkipped));
    if (overlayMapsSkipped > 0) {
      skipped.add(l10n.countOverlayMaps(overlayMapsSkipped));
    }

    return skipped.isEmpty
        ? imported
        : l10n.importedWithSkipped(imported, skipped.join(', '));
  }

  @override
  String toString() {
    final parts = <String>[];
    if (channelsImported > 0) parts.add('$channelsImported channels');
    if (waypointsImported > 0) parts.add('$waypointsImported waypoints');
    if (tilesImported > 0) parts.add('$tilesImported tiles');
    if (overlayMapsImported > 0) parts.add('$overlayMapsImported overlay maps');
    if (radioSettingsApplied) parts.add('radio settings');
    final imported =
        parts.isEmpty ? 'Nothing new' : 'Imported ${parts.join(', ')}';
    final skipped = <String>[];
    if (channelsSkipped > 0) skipped.add('$channelsSkipped channels');
    if (waypointsSkipped > 0) skipped.add('$waypointsSkipped waypoints');
    if (tilesSkipped > 0) skipped.add('$tilesSkipped tiles');
    if (overlayMapsSkipped > 0) skipped.add('$overlayMapsSkipped overlay maps');
    return skipped.isEmpty
        ? imported
        : '$imported (skipped ${skipped.join(', ')})';
  }
}

/// Strings for the user's language, for progress labels built outside the
/// widget tree.
///
/// This service holds no [SettingsService], so it reads the language from
/// [AppLanguage.activeLocaleCode], which settings keeps up to date.
AppLocalizations get _phaseL10n =>
    lookupAppLocalizations(AppLanguage.localeFor());

class TeamConfigService {
  static const int _formatVersion = 1;

  /// Build a `.teamcfg.zip` and return the compressed bytes.
  ///
  /// ZIP encoding runs in a background isolate to avoid blocking the UI thread
  /// (the `archive` package encoder is synchronous and can take seconds for
  /// large tile sets).
  Future<Uint8List> exportConfig({
    required List<ChannelData> channels,
    required List<WaypointData> waypoints,
    required List<OfflineMapAreaData> mapAreas,
    required MapTileCacheService tileCache,
    List<ImportedOverlayMapData> overlayMaps = const [],
    String name = '',
    String description = '',
    TeamConfigRadioSettings? radioSettings,
    void Function(TeamConfigProgress)? onProgress,
    bool Function()? isCancelled,
    /// Called with the names of any overlay maps left out because they exceed
    /// [kMaxShareableOverlayBytes]. The export still succeeds without them.
    void Function(List<String> names)? onOverlayMapsTooLarge,
  }) async {
    final archive = Archive();

    // --- Build config.json ---
    onProgress?.call(const TeamConfigProgress(
      phase: 'Packing channels & waypoints',
      current: 0,
      total: 0,
    ));

    final channelEntries = channels.map((c) {
      final hexKey = _bytesToHex(Uint8List.fromList(c.sharedKey));
      return TeamConfigChannelEntry(
        name: c.name,
        sharedKeyHex: hexKey,
        isPublic: c.isPublic,
        shareLocation: c.shareLocation,
      );
    }).toList();

    final waypointEntries = waypoints
        .map((w) => TeamConfigWaypointEntry(
              id: w.id,
              meshId: w.meshId,
              name: w.name,
              description: w.description,
              latitude: w.latitude,
              longitude: w.longitude,
              waypointType: w.waypointType,
              creatorNodeId: w.creatorNodeId,
              createdAt: w.createdAt,
            ))
        .toList();

    final configJson = jsonEncode({
      'channels': channelEntries.map((e) => e.toJson()).toList(),
      'waypoints': waypointEntries.map((e) => e.toJson()).toList(),
      if (radioSettings != null) 'radioSettings': radioSettings.toJson(),
    });
    archive.addFile(ArchiveFile(
      'config.json',
      utf8.encode(configJson).length,
      utf8.encode(configJson),
    ));

    // --- Pack tile areas + tile files ---
    final tileAreaEntries = <TeamConfigTileAreaEntry>[];
    int totalTileCount = 0;
    int totalTileSizeBytes = 0;
    int tilesProcessed = 0;

    // Count total tiles for progress reporting.
    int totalTilesToPack = 0;
    for (final area in mapAreas) {
      totalTilesToPack += area.tileCount;
    }

    for (final area in mapAreas) {
      if (isCancelled?.call() == true) break;

      final provider = tileProviderForId(area.providerId);
      final bounds = LatLngBounds(
        LatLng(area.south, area.west),
        LatLng(area.north, area.east),
      );
      final tiles = tileCache.tileCoordinatesForRegion(
        bounds: bounds,
        minZoom: area.minZoom,
        maxZoom: area.maxZoom,
        urlTemplate: provider.urlTemplate,
        subdomains: provider.subdomains,
      );

      int areaTileCount = 0;
      int areaSizeBytes = 0;

      for (final tile in tiles) {
        if (isCancelled?.call() == true) break;

        final tileBytes = await tileCache.getTileBytes(tile.url);
        if (tileBytes != null) {
          // Use the known coordinates directly — no URL parsing needed.
          final tilePath =
              'tiles/${area.providerId}/${tile.z}/${tile.x}/${tile.y}.png';
          archive.addFile(ArchiveFile(tilePath, tileBytes.length, tileBytes));
          areaTileCount++;
          areaSizeBytes += tileBytes.length;
        }

        tilesProcessed++;
        if (tilesProcessed % 50 == 0 || tilesProcessed == totalTilesToPack) {
          onProgress?.call(TeamConfigProgress(
            phase: _phaseL10n.packingTiles,
            current: tilesProcessed,
            total: totalTilesToPack,
          ));
        }
      }

      totalTileCount += areaTileCount;
      totalTileSizeBytes += areaSizeBytes;

      tileAreaEntries.add(TeamConfigTileAreaEntry(
        name: area.name,
        providerId: area.providerId,
        north: area.north,
        south: area.south,
        east: area.east,
        west: area.west,
        minZoom: area.minZoom,
        maxZoom: area.maxZoom,
        tileCount: areaTileCount,
        sizeBytes: areaSizeBytes,
      ));
    }

    // --- tile_areas.json ---
    if (tileAreaEntries.isNotEmpty) {
      final tileAreasJson = jsonEncode({
        'areas': tileAreaEntries.map((e) => e.toJson()).toList(),
      });
      archive.addFile(ArchiveFile(
        'tile_areas.json',
        utf8.encode(tileAreasJson).length,
        utf8.encode(tileAreasJson),
      ));
    }

    // --- Pack overlay map tile files ---
    final overlayMapEntries = <TeamConfigOverlayMapEntry>[];
    final overlayMapsTooLarge = <String>[];
    int overlayMapSizeBytes = 0;

    for (int mi = 0; mi < overlayMaps.length; mi++) {
      if (isCancelled?.call() == true) break;
      final map = overlayMaps[mi];

      onProgress?.call(TeamConfigProgress(
        phase: 'Packing overlay map ${mi + 1} of ${overlayMaps.length}',
        current: mi + 1,
        total: overlayMaps.length,
      ));

      final dir = Directory(map.dirPath);
      if (!dir.existsSync()) continue;

      // The archive is assembled in memory before being encoded, so a large
      // MBTiles map would exhaust the heap. Skip those rather than crash the
      // whole export; the manage screen flags which maps are too big to share.
      final files = dir.listSync().whereType<File>().toList();
      int dirBytes = 0;
      for (final file in files) {
        dirBytes += await file.length();
      }
      if (dirBytes > kMaxShareableOverlayBytes) {
        overlayMapsTooLarge.add(map.name);
        continue;
      }

      int mapSizeBytes = 0;
      for (final file in files) {
        if (isCancelled?.call() == true) break;
        final bytes = await file.readAsBytes();
        final entryPath = 'kmz_overlays/${map.id}/${file.uri.pathSegments.last}';
        archive.addFile(ArchiveFile(entryPath, bytes.length, bytes));
        mapSizeBytes += bytes.length;
      }

      overlayMapSizeBytes += mapSizeBytes;
      overlayMapEntries.add(TeamConfigOverlayMapEntry(
        id: map.id,
        name: map.name,
        tileCount: map.tileCount,
        sizeBytes: mapSizeBytes,
        north: map.boundsNorth,
        south: map.boundsSouth,
        east: map.boundsEast,
        west: map.boundsWest,
        layerType: map.layerType,
        minZoom: map.minZoom,
        maxZoom: map.maxZoom,
      ));
    }

    // --- kmz_overlays.json ---
    if (overlayMapEntries.isNotEmpty) {
      final overlayJson = jsonEncode({
        'maps': overlayMapEntries.map((e) => e.toJson()).toList(),
      });
      archive.addFile(ArchiveFile(
        'kmz_overlays.json',
        utf8.encode(overlayJson).length,
        utf8.encode(overlayJson),
      ));
    }

    // --- manifest.json ---
    final manifest = {
      'version': _formatVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'name': name,
      'description': description,
      'includesChannels': channelEntries.isNotEmpty,
      'includesWaypoints': waypointEntries.isNotEmpty,
      'includesRadioSettings': radioSettings != null,
      'includesTiles': totalTileCount > 0,
      'channelCount': channelEntries.length,
      'waypointCount': waypointEntries.length,
      'tileCount': totalTileCount,
      'tileSizeBytes': totalTileSizeBytes,
      'includesOverlayMaps': overlayMapEntries.isNotEmpty,
      'overlayMapCount': overlayMapEntries.length,
      'overlayMapSizeBytes': overlayMapSizeBytes,
      if (overlayMapsTooLarge.isNotEmpty)
        'overlayMapsOmittedTooLarge': overlayMapsTooLarge,
    };
    if (overlayMapsTooLarge.isNotEmpty) {
      onOverlayMapsTooLarge?.call(List.unmodifiable(overlayMapsTooLarge));
    }
    final manifestJson = jsonEncode(manifest);
    archive.addFile(ArchiveFile(
      'manifest.json',
      utf8.encode(manifestJson).length,
      utf8.encode(manifestJson),
    ));

    // --- Write ZIP ---
    onProgress?.call(const TeamConfigProgress(
      phase: 'Compressing ZIP (this may take a moment)…',
      current: 0,
      total: 0,
    ));

    // Run the synchronous ZIP encoder in a background isolate so we don't
    // block the UI thread (ANR risk on large tile sets).
    final zipBytes = await Isolate.run(() {
      return Uint8List.fromList(ZipEncoder().encode(archive));
    });

    return zipBytes;
  }

  /// Read a `.teamcfg.zip` and return a preview without importing.
  Future<TeamConfigPreview> readPreview(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const FormatException('Invalid team config: missing manifest.json');
    }
    final manifest = jsonDecode(utf8.decode(manifestFile.content as List<int>))
        as Map<String, dynamic>;

    final version = manifest['version'] as int? ?? 1;
    if (version > _formatVersion) {
      throw FormatException(
          'Unsupported team config version $version (max supported: $_formatVersion)');
    }

    List<TeamConfigChannelEntry> channels = [];
    List<TeamConfigWaypointEntry> waypoints = [];
    TeamConfigRadioSettings? radioSettings;
    final configFile = archive.findFile('config.json');
    if (configFile != null) {
      final config = jsonDecode(utf8.decode(configFile.content as List<int>))
          as Map<String, dynamic>;
      channels = (config['channels'] as List<dynamic>?)
              ?.map((e) =>
                  TeamConfigChannelEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      waypoints = (config['waypoints'] as List<dynamic>?)
              ?.map((e) =>
                  TeamConfigWaypointEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      if (config['radioSettings'] != null) {
        radioSettings = TeamConfigRadioSettings.fromJson(
            config['radioSettings'] as Map<String, dynamic>);
      }
    }

    List<TeamConfigTileAreaEntry> tileAreas = [];
    final tileAreasFile = archive.findFile('tile_areas.json');
    if (tileAreasFile != null) {
      final parsed = jsonDecode(utf8.decode(tileAreasFile.content as List<int>))
          as Map<String, dynamic>;
      tileAreas = (parsed['areas'] as List<dynamic>?)
              ?.map((e) =>
                  TeamConfigTileAreaEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    }

    List<TeamConfigOverlayMapEntry> overlayMaps = [];
    final overlayFile = archive.findFile('kmz_overlays.json');
    if (overlayFile != null) {
      final parsed = jsonDecode(utf8.decode(overlayFile.content as List<int>))
          as Map<String, dynamic>;
      overlayMaps = (parsed['maps'] as List<dynamic>?)
              ?.map((e) => TeamConfigOverlayMapEntry.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [];
    }

    return TeamConfigPreview(
      version: version,
      name: manifest['name'] as String?,
      creatorName: manifest['creatorName'] as String?,
      description: manifest['description'] as String?,
      channels: channels,
      waypoints: waypoints,
      tileAreas: tileAreas,
      radioSettings: radioSettings,
      tileCount: manifest['tileCount'] as int? ?? 0,
      tileSizeBytes: manifest['tileSizeBytes'] as int? ?? 0,
      overlayMaps: overlayMaps,
      overlayMapSizeBytes: manifest['overlayMapSizeBytes'] as int? ?? 0,
    );
  }

  /// Import a `.teamcfg.zip` into the app.
  ///
  /// Channels are imported via [channelRepo.importChannel()] which requires
  /// an active companion connection to register with firmware.
  Future<TeamConfigImportResult> importConfig({
    required File zipFile,
    required AppDatabase db,
    required MapTileCacheService tileCache,
    required ChannelRepository channelRepo,
    Future<bool> Function(TeamConfigRadioSettings)? applyRadioSettings,
    void Function(TeamConfigProgress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Validate manifest
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const FormatException('Invalid team config: missing manifest.json');
    }
    final manifest = jsonDecode(utf8.decode(manifestFile.content as List<int>))
        as Map<String, dynamic>;
    final version = manifest['version'] as int? ?? 1;
    if (version > _formatVersion) {
      throw FormatException(
          'Unsupported team config version $version (max supported: $_formatVersion)');
    }

    // Parse config.json
    List<TeamConfigChannelEntry> channelEntries = [];
    List<TeamConfigWaypointEntry> waypointEntries = [];
    TeamConfigRadioSettings? radioSettings;
    final configFile = archive.findFile('config.json');
    if (configFile != null) {
      final config = jsonDecode(utf8.decode(configFile.content as List<int>))
          as Map<String, dynamic>;
      channelEntries = (config['channels'] as List<dynamic>?)
              ?.map((e) =>
                  TeamConfigChannelEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      waypointEntries = (config['waypoints'] as List<dynamic>?)
              ?.map((e) =>
                  TeamConfigWaypointEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      if (config['radioSettings'] != null) {
        radioSettings = TeamConfigRadioSettings.fromJson(
            config['radioSettings'] as Map<String, dynamic>);
      }
    }

    // Parse tile_areas.json
    List<TeamConfigTileAreaEntry> tileAreaEntries = [];
    final tileAreasFile = archive.findFile('tile_areas.json');
    if (tileAreasFile != null) {
      final parsed = jsonDecode(utf8.decode(tileAreasFile.content as List<int>))
          as Map<String, dynamic>;
      tileAreaEntries = (parsed['areas'] as List<dynamic>?)
              ?.map((e) =>
                  TeamConfigTileAreaEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    }

    int channelsImported = 0;
    int channelsSkipped = 0;
    int waypointsImported = 0;
    int waypointsSkipped = 0;
    int tilesImported = 0;
    int tilesSkipped = 0;
    int tileAreasImported = 0;
    bool radioSettingsApplied = false;

    // --- Apply radio settings first (before channels, since firmware restarts) ---
    if (radioSettings != null && applyRadioSettings != null) {
      onProgress?.call(TeamConfigProgress(
        phase: _phaseL10n.applyingRadioSettings,
        current: 0,
        total: 1,
      ));
      radioSettingsApplied = await applyRadioSettings(radioSettings);
      onProgress?.call(TeamConfigProgress(
        phase: _phaseL10n.applyingRadioSettings,
        current: 1,
        total: 1,
      ));
    }

    // --- Import channels via existing importChannel() ---
    onProgress?.call(TeamConfigProgress(
      phase: _phaseL10n.importingChannels,
      current: 0,
      total: channelEntries.length,
    ));

    for (int i = 0; i < channelEntries.length; i++) {
      if (isCancelled?.call() == true) break;
      final entry = channelEntries[i];

      // Skip public channel — it's always present.
      if (entry.isPublic) {
        channelsSkipped++;
        continue;
      }

      // Construct a meshcore:// URL and import through the existing path.
      final url =
          'meshcore://channel/add?name=${Uri.encodeQueryComponent(entry.name)}&secret=${entry.sharedKeyHex}';
      final result = await channelRepo.importChannel(url, '');
      if (result != null) {
        channelsImported++;
      } else {
        // importChannel returns null for duplicates or errors.
        channelsSkipped++;
      }

      onProgress?.call(TeamConfigProgress(
        phase: _phaseL10n.importingChannels,
        current: i + 1,
        total: channelEntries.length,
      ));
    }

    // --- Import waypoints ---
    onProgress?.call(TeamConfigProgress(
      phase: _phaseL10n.importingWaypoints,
      current: 0,
      total: waypointEntries.length,
    ));

    const uuid = Uuid();
    for (int i = 0; i < waypointEntries.length; i++) {
      if (isCancelled?.call() == true) break;
      final entry = waypointEntries[i];

      // Dedup by meshId if present.
      bool isDuplicate = false;
      if (entry.meshId != null && entry.meshId!.isNotEmpty) {
        final existing =
            await db.waypointsDao.getWaypointByMeshId(entry.meshId!);
        if (existing != null) isDuplicate = true;
      }

      // Dedup by name + location within ~10m.
      if (!isDuplicate) {
        final allWaypoints = await db.waypointsDao.getAllWaypoints();
        for (final existing in allWaypoints) {
          if (existing.name.trim().toLowerCase() ==
              entry.name.trim().toLowerCase()) {
            final dist = _distanceMeters(
              existing.latitude,
              existing.longitude,
              entry.latitude,
              entry.longitude,
            );
            if (dist < 10.0) {
              isDuplicate = true;
              break;
            }
          }
        }
      }

      if (isDuplicate) {
        waypointsSkipped++;
      } else {
        await db.waypointsDao.insertWaypoint(WaypointsCompanion.insert(
          id: uuid.v4(),
          meshId: drift.Value(entry.meshId),
          name: entry.name,
          description: drift.Value(entry.description),
          latitude: entry.latitude,
          longitude: entry.longitude,
          waypointType: entry.waypointType,
          creatorNodeId: entry.creatorNodeId,
          createdAt: entry.createdAt,
          isReceived: const drift.Value(false),
          isVisible: const drift.Value(true),
          isNew: const drift.Value(true),
        ));
        waypointsImported++;
      }

      onProgress?.call(TeamConfigProgress(
        phase: _phaseL10n.importingWaypoints,
        current: i + 1,
        total: waypointEntries.length,
      ));
    }

    // --- Import tiles ---
    final tileFiles =
        archive.files.where((f) => f.name.startsWith('tiles/')).toList();
    final totalTiles = tileFiles.length;

    onProgress?.call(TeamConfigProgress(
      phase: _phaseL10n.importingTiles,
      current: 0,
      total: totalTiles,
    ));

    for (int i = 0; i < tileFiles.length; i++) {
      if (isCancelled?.call() == true) break;
      final file = tileFiles[i];
      if (file.isFile) {
        // Strip the leading 'tiles/' prefix.
        final relativePath = file.name.substring('tiles/'.length);
        final parsed = MapTileCacheService.parseTilePath(relativePath);
        if (parsed != null) {
          final provider = tileProviderForId(parsed.providerId);
          final url = tileCache.buildTileUrl(
            urlTemplate: provider.urlTemplate,
            subdomains: provider.subdomains,
            x: parsed.x,
            y: parsed.y,
            zoom: parsed.z,
          );

          // Check if already cached.
          final existing = await tileCache.getTileBytes(url);
          if (existing != null) {
            tilesSkipped++;
          } else {
            await tileCache.putTileBytes(
                url, Uint8List.fromList(file.content as List<int>));
            tilesImported++;
          }
        }
      }

      if (i % 50 == 0 || i == totalTiles - 1) {
        onProgress?.call(TeamConfigProgress(
          phase: _phaseL10n.importingTiles,
          current: i + 1,
          total: totalTiles,
        ));
      }
    }

    // --- Import tile area metadata ---
    for (final areaEntry in tileAreaEntries) {
      if (isCancelled?.call() == true) break;

      // Check for overlapping area with same provider.
      final overlapping =
          await db.offlineMapAreasDao.findByProviderAndOverlappingBounds(
        providerId: areaEntry.providerId,
        north: areaEntry.north,
        south: areaEntry.south,
        east: areaEntry.east,
        west: areaEntry.west,
      );

      if (overlapping.isEmpty) {
        await db.offlineMapAreasDao.insertArea(OfflineMapAreasCompanion.insert(
          id: uuid.v4(),
          name: areaEntry.name,
          providerId: areaEntry.providerId,
          north: areaEntry.north,
          south: areaEntry.south,
          east: areaEntry.east,
          west: areaEntry.west,
          minZoom: areaEntry.minZoom,
          maxZoom: areaEntry.maxZoom,
          tileCount: areaEntry.tileCount,
          downloadedAt: DateTime.now().millisecondsSinceEpoch,
          sizeBytes: areaEntry.sizeBytes,
        ));
        tileAreasImported++;
      }
    }

    // --- Import overlay maps ---
    int overlayMapsImported = 0;
    int overlayMapsSkipped = 0;

    List<TeamConfigOverlayMapEntry> overlayMapEntries = [];
    final overlayMetaFile = archive.findFile('kmz_overlays.json');
    if (overlayMetaFile != null) {
      final parsed =
          jsonDecode(utf8.decode(overlayMetaFile.content as List<int>))
              as Map<String, dynamic>;
      overlayMapEntries = (parsed['maps'] as List<dynamic>?)
              ?.map((e) => TeamConfigOverlayMapEntry.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [];
    }

    if (overlayMapEntries.isNotEmpty) {
      final docsDir = await getApplicationDocumentsDirectory();
      final existingOverlays = await db.importedOverlayMapsDao.getAllMaps();

      onProgress?.call(TeamConfigProgress(
        phase: _phaseL10n.importingOverlayMaps,
        current: 0,
        total: overlayMapEntries.length,
      ));

      for (int i = 0; i < overlayMapEntries.length; i++) {
        if (isCancelled?.call() == true) break;
        final entry = overlayMapEntries[i];

        // Dedup: skip if same name (case-insensitive) or exact same bounds.
        final isDuplicate = existingOverlays.any((existing) =>
            existing.name.trim().toLowerCase() ==
                entry.name.trim().toLowerCase() ||
            (existing.boundsNorth == entry.north &&
                existing.boundsSouth == entry.south &&
                existing.boundsEast == entry.east &&
                existing.boundsWest == entry.west));

        if (isDuplicate) {
          overlayMapsSkipped++;
        } else {
          // Extract tile files for this overlay map.
          final dirPath =
              '${docsDir.path}/imported_maps/${entry.id}';
          await Directory(dirPath).create(recursive: true);

          final prefix = 'kmz_overlays/${entry.id}/';
          for (final zipEntry in archive.files) {
            if (!zipEntry.isFile || !zipEntry.name.startsWith(prefix)) {
              continue;
            }
            final filename = zipEntry.name.substring(prefix.length);
            if (filename.isEmpty || filename.contains('/')) continue;
            final outFile = File('$dirPath/$filename');
            await outFile.writeAsBytes(zipEntry.content as List<int>);
          }

          await db.importedOverlayMapsDao.insertMap(ImportedOverlayMapsCompanion.insert(
            id: entry.id,
            name: entry.name,
            dirPath: dirPath,
            tileCount: entry.tileCount,
            importedAt: DateTime.now().millisecondsSinceEpoch,
            boundsNorth: entry.north,
            boundsSouth: entry.south,
            boundsEast: entry.east,
            boundsWest: entry.west,
            layerType: drift.Value(entry.layerType),
            minZoom: drift.Value(entry.minZoom),
            maxZoom: drift.Value(entry.maxZoom),
            sizeBytes: drift.Value(entry.sizeBytes),
          ));
          overlayMapsImported++;
        }

        onProgress?.call(TeamConfigProgress(
          phase: _phaseL10n.importingOverlayMaps,
          current: i + 1,
          total: overlayMapEntries.length,
        ));
      }
    }

    return TeamConfigImportResult(
      channelsImported: channelsImported,
      channelsSkipped: channelsSkipped,
      waypointsImported: waypointsImported,
      waypointsSkipped: waypointsSkipped,
      tilesImported: tilesImported,
      tilesSkipped: tilesSkipped,
      tileAreasImported: tileAreasImported,
      radioSettingsApplied: radioSettingsApplied,
      overlayMapsImported: overlayMapsImported,
      overlayMapsSkipped: overlayMapsSkipped,
    );
  }

  String _bytesToHex(Uint8List bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  /// Haversine distance in meters.
  static double _distanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
