// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

class MapTileCacheProgress {
  final int completed;
  final int total;
  final int failed;

  const MapTileCacheProgress({
    required this.completed,
    required this.total,
    required this.failed,
  });
}

class MapTileCacheResult {
  final int total;
  final int downloaded;
  final int failed;
  final int sizeBytes;

  const MapTileCacheResult({
    required this.total,
    required this.downloaded,
    required this.failed,
    required this.sizeBytes,
  });
}

class MapTileCacheService {
  static const String cacheKey = 'map_tile_cache';
  static const int maxCacheObjects = 200000;

  final BaseCacheManager cacheManager;
  late final TileProvider tileProvider;

  MapTileCacheService({BaseCacheManager? cacheManager})
      : cacheManager = cacheManager ??
            CacheManager(
              Config(
                cacheKey,
                stalePeriod: const Duration(days: 365),
                maxNrOfCacheObjects: maxCacheObjects,
              ),
            ) {
    tileProvider = _CachedNetworkTileProvider(cacheManager: this.cacheManager);
  }

  /// Downloads all tiles within the given bounds and zoom range.
  ///
  /// - [urlTemplate] must match the FlutterMap `TileLayer.urlTemplate`.
  /// - [subdomains] should match `TileLayer.subdomains` (may be empty).
  Future<MapTileCacheResult> downloadRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    required List<String> subdomains,
    int concurrentDownloads = 2,
    void Function(MapTileCacheProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final safeMin = math.min(minZoom, maxZoom);
    final safeMax = math.max(minZoom, maxZoom);

    final total = estimateTileCount(bounds, safeMin, safeMax);
    int completed = 0;
    int failed = 0;
    int sizeBytes = 0;

    final safeConcurrency = math.max(1, concurrentDownloads);
    final pending = <Future<void>>[];

    Future<void> queueDownload(String url) async {
      if (isCancelled?.call() == true) {
        throw _DownloadCancelled();
      }

      final future =
          cacheManager.downloadFile(url, key: url).then((info) async {
        completed += 1;
        final file = info.file;
        final len = await file.length();
        sizeBytes += len;
      }).catchError((_) {
        completed += 1;
        failed += 1;
      }).whenComplete(() {
        onProgress?.call(
          MapTileCacheProgress(
            completed: completed,
            total: total,
            failed: failed,
          ),
        );
      });

      pending.add(future);
      if (pending.length >= safeConcurrency) {
        await Future.wait(pending);
        pending.clear();
      }
    }

    for (int zoom = safeMin; zoom <= safeMax; zoom++) {
      final tileBounds = _tileBoundsForBounds(bounds, zoom);
      for (int x = tileBounds.minX; x <= tileBounds.maxX; x++) {
        for (int y = tileBounds.minY; y <= tileBounds.maxY; y++) {
          final url = _buildTileUrl(
            urlTemplate: urlTemplate,
            subdomains: subdomains,
            x: x,
            y: y,
            zoom: zoom,
          );
          await queueDownload(url);
        }
      }
    }

    if (pending.isNotEmpty) {
      await Future.wait(pending);
      pending.clear();
    }

    return MapTileCacheResult(
      total: total,
      downloaded: completed - failed,
      failed: failed,
      sizeBytes: sizeBytes,
    );
  }

  int estimateTileCount(LatLngBounds bounds, int minZoom, int maxZoom) {
    final safeMin = math.min(minZoom, maxZoom);
    final safeMax = math.max(minZoom, maxZoom);
    int total = 0;

    for (int zoom = safeMin; zoom <= safeMax; zoom++) {
      final tileBounds = _tileBoundsForBounds(bounds, zoom);
      total += tileBounds.count;
    }
    return total;
  }

  /// Enumerate all tile URLs for a region (for export/import).
  List<String> tileUrlsForRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    required List<String> subdomains,
  }) {
    final safeMin = math.min(minZoom, maxZoom);
    final safeMax = math.max(minZoom, maxZoom);
    final urls = <String>[];

    for (int zoom = safeMin; zoom <= safeMax; zoom++) {
      final tileBounds = _tileBoundsForBounds(bounds, zoom);
      for (int x = tileBounds.minX; x <= tileBounds.maxX; x++) {
        for (int y = tileBounds.minY; y <= tileBounds.maxY; y++) {
          urls.add(_buildTileUrl(
            urlTemplate: urlTemplate,
            subdomains: subdomains,
            x: x,
            y: y,
            zoom: zoom,
          ));
        }
      }
    }
    return urls;
  }

  /// Get cached tile bytes by URL key. Returns null if not cached.
  Future<Uint8List?> getTileBytes(String url) async {
    final info = await cacheManager.getFileFromCache(url);
    if (info == null) return null;
    return info.file.readAsBytes();
  }

  /// Write tile bytes into the cache under the given URL key.
  Future<void> putTileBytes(String url, Uint8List bytes) async {
    await cacheManager.putFile(url, bytes, key: url);
  }

  /// Build a tile URL from template + coordinates (public accessor for export).
  String buildTileUrl({
    required String urlTemplate,
    required List<String> subdomains,
    required int x,
    required int y,
    required int zoom,
  }) {
    return _buildTileUrl(
      urlTemplate: urlTemplate,
      subdomains: subdomains,
      x: x,
      y: y,
      zoom: zoom,
    );
  }

  /// Parse a tile path like `{providerId}/{z}/{x}/{y}.png` into components.
  /// Returns null if the path doesn't match the expected format.
  static ({String providerId, int z, int x, int y})? parseTilePath(
      String path) {
    final parts = path.split('/');
    if (parts.length < 4) return null;
    final y = int.tryParse(parts.last.replaceAll(RegExp(r'\.\w+$'), ''));
    final x = int.tryParse(parts[parts.length - 2]);
    final z = int.tryParse(parts[parts.length - 3]);
    final providerId = parts.sublist(0, parts.length - 3).join('/');
    if (y == null || x == null || z == null || providerId.isEmpty) return null;
    return (providerId: providerId, z: z, x: x, y: y);
  }

  Future<void> deleteRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    required List<String> subdomains,
    bool Function()? isCancelled,
  }) async {
    final safeMin = math.min(minZoom, maxZoom);
    final safeMax = math.max(minZoom, maxZoom);

    for (int zoom = safeMin; zoom <= safeMax; zoom++) {
      final tileBounds = _tileBoundsForBounds(bounds, zoom);
      for (int x = tileBounds.minX; x <= tileBounds.maxX; x++) {
        for (int y = tileBounds.minY; y <= tileBounds.maxY; y++) {
          if (isCancelled?.call() == true) {
            throw _DownloadCancelled();
          }

          final url = _buildTileUrl(
            urlTemplate: urlTemplate,
            subdomains: subdomains,
            x: x,
            y: y,
            zoom: zoom,
          );
          await cacheManager.removeFile(url);
        }
      }
    }
  }

  _TileBounds _tileBoundsForBounds(LatLngBounds bounds, int zoom) {
    final north = _clampLatitude(bounds.north);
    final south = _clampLatitude(bounds.south);
    final maxIndex = (1 << zoom) - 1;

    final minX = _lonToTileX(bounds.west, zoom, maxIndex);
    final maxX = _lonToTileX(bounds.east, zoom, maxIndex);
    final minY = _latToTileY(north, zoom, maxIndex);
    final maxY = _latToTileY(south, zoom, maxIndex);

    return _TileBounds(
      minX: math.min(minX, maxX),
      maxX: math.max(minX, maxX),
      minY: math.min(minY, maxY),
      maxY: math.max(minY, maxY),
    );
  }

  int _lonToTileX(double lon, int zoom, int maxIndex) {
    final n = 1 << zoom;
    final value = ((lon + 180.0) / 360.0 * n).floor();
    return value.clamp(0, maxIndex);
  }

  int _latToTileY(double lat, int zoom, int maxIndex) {
    final n = 1 << zoom;
    final rad = lat * math.pi / 180.0;
    final value =
        ((1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * n)
            .floor();
    return value.clamp(0, maxIndex);
  }

  double _clampLatitude(double lat) {
    const maxLat = 85.05112878;
    return lat.clamp(-maxLat, maxLat);
  }

  String _buildTileUrl({
    required String urlTemplate,
    required List<String> subdomains,
    required int x,
    required int y,
    required int zoom,
  }) {
    final hasSubdomain = urlTemplate.contains('{s}');
    final s = (hasSubdomain && subdomains.isNotEmpty)
        ? subdomains[(x + y) % subdomains.length]
        : '';

    return urlTemplate
        .replaceAll('{z}', zoom.toString())
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString())
        .replaceAll('{s}', s);
  }
}

class _CachedNetworkTileProvider extends TileProvider {
  final BaseCacheManager cacheManager;

  _CachedNetworkTileProvider({required this.cacheManager, super.headers});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return CachedNetworkImageProvider(
      url,
      cacheManager: cacheManager,
      headers: headers,
    );
  }
}

class _TileBounds {
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;

  const _TileBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;
  int get count => width * height;
}

class _DownloadCancelled implements Exception {
  @override
  String toString() => 'Download cancelled';
}
