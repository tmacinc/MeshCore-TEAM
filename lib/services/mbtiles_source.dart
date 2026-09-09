// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart' show GZipDecoder, ZLibDecoder;
import 'package:flutter/foundation.dart' show SynchronousFuture, immutable;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:meshcore_team/l10n/app_localizations.dart';
import 'package:meshcore_team/models/app_language.dart';

/// A read-only handle on an MBTiles file.
///
/// MBTiles (https://github.com/mapbox/mbtiles-spec) is a plain SQLite database
/// holding a Web Mercator tile pyramid:
///
///   metadata(name TEXT, value TEXT)
///   tiles(zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER,
///         tile_data BLOB)
///
/// Because it is already an XYZ pyramid it maps directly onto a flutter_map
/// [TileLayer] — unlike the KMZ overlay path, no bounding-box stretching or
/// manual level selection is needed.
///
/// Note that `tile_row` uses TMS numbering (origin bottom-left), which is
/// flipped relative to the XYZ scheme flutter_map uses. [tile] handles that.
class MbtilesSource {
  MbtilesSource._({
    required this.filePath,
    required Database db,
    required this.name,
    required this.format,
    required this.minZoom,
    required this.maxZoom,
    required this.bounds,
    required this.tileCount,
    required this.attribution,
    required this.tilePixelSize,
  }) : _db = db;

  final String filePath;
  final Database _db;

  /// Display name from `metadata.name`, falling back to the file name.
  final String name;

  /// Image format of the tile blobs: 'png', 'jpg', or 'webp'.
  final String format;

  final int minZoom;
  final int maxZoom;
  final LatLngBounds bounds;
  final int tileCount;

  /// `metadata.attribution`, if the file declares one. May be empty.
  final String attribution;

  /// Edge length in pixels of the archive's tiles, sniffed from a real blob.
  ///
  /// Almost always 256, but 512 is common in high-DPI archives. flutter_map
  /// needs to be told, or it lays 512px images out on a 256px grid.
  final int tilePixelSize;

  bool _closed = false;
  bool get isClosed => _closed;

  /// Opens [filePath] read-only and reads its metadata.
  ///
  /// Throws [FormatException] with a user-presentable message if the file is
  /// not a usable raster MBTiles archive. The database handle is always
  /// released before throwing.
  static MbtilesSource open(String filePath) {
    if (!File(filePath).existsSync()) {
      throw const FormatException('MBTiles file not found.');
    }

    late final Database db;
    try {
      db = sqlite3.open(filePath, mode: OpenMode.readOnly);
    } catch (e) {
      throw FormatException('Could not open MBTiles file: $e');
    }

    try {
      // A `tiles` relation is the one hard requirement. It is a table in
      // simple archives and a view over map/images in deduplicated ones;
      // either way this query works.
      try {
        db.select('SELECT 1 FROM tiles LIMIT 1');
      } catch (_) {
        throw const FormatException(
          'This SQLite file has no "tiles" table, so it is not an MBTiles map.',
        );
      }

      final meta = _readMetadata(db);

      final format = (meta['format'] ?? 'png').toLowerCase().trim();
      if (format == 'pbf' || format == 'mvt') {
        throw FormatException(
          lookupAppLocalizations(AppLanguage.localeFor())
          .mbtilesVectorNotSupported,
        );
      }

      final zooms = _resolveZoomRange(db, meta);
      final bounds = _resolveBounds(db, meta, zooms.$1);

      final countRow = db.select('SELECT COUNT(*) AS c FROM tiles').first;
      final tileCount = (countRow['c'] as int?) ?? 0;
      if (tileCount == 0) {
        throw const FormatException('This MBTiles file contains no tiles.');
      }

      final metaName = (meta['name'] ?? '').trim();

      // Sniff a real tile for its pixel size. Deliberately conservative: only
      // a recognised non-standard tile size overrides the 256 default, so a
      // stray or unreadable sample can never break an archive that works.
      var tilePixelSize = 256;
      final sizeSample = db.select(
        'SELECT tile_data FROM tiles ORDER BY zoom_level DESC LIMIT 1',
      );
      if (sizeSample.isNotEmpty) {
        final blob = sizeSample.first['tile_data'];
        if (blob is Uint8List) {
          final dims = imageSize(_maybeInflate(blob));
          if (dims != null && dims.$1 == dims.$2 && const [512, 1024].contains(dims.$1)) {
            tilePixelSize = dims.$1;
          }
        }
      }

      return MbtilesSource._(
        tilePixelSize: tilePixelSize,
        filePath: filePath,
        db: db,
        name: metaName.isNotEmpty
            ? metaName
            : filePath.split(Platform.pathSeparator).last,
        format: format,
        minZoom: zooms.$1,
        maxZoom: zooms.$2,
        bounds: bounds,
        tileCount: tileCount,
        attribution: (meta['attribution'] ?? '').trim(),
      );
    } catch (_) {
      db.dispose();
      rethrow;
    }
  }

  static Map<String, String> _readMetadata(Database db) {
    final meta = <String, String>{};
    try {
      for (final row in db.select('SELECT name, value FROM metadata')) {
        final key = row['name'];
        final value = row['value'];
        if (key is String && value != null) meta[key] = value.toString();
      }
    } catch (_) {
      // The metadata table is optional in practice; everything it would have
      // told us is derivable from the tiles table below.
    }
    return meta;
  }

  /// Returns (minZoom, maxZoom), preferring metadata and falling back to the
  /// actual contents of the tiles table.
  static (int, int) _resolveZoomRange(Database db, Map<String, String> meta) {
    final metaMin = int.tryParse(meta['minzoom'] ?? '');
    final metaMax = int.tryParse(meta['maxzoom'] ?? '');
    if (metaMin != null && metaMax != null && metaMin <= metaMax) {
      return (metaMin.clamp(0, 24), metaMax.clamp(0, 24));
    }

    final row = db
        .select('SELECT MIN(zoom_level) AS lo, MAX(zoom_level) AS hi FROM tiles')
        .first;
    final lo = (row['lo'] as int?) ?? 0;
    final hi = (row['hi'] as int?) ?? lo;
    return (lo.clamp(0, 24), hi.clamp(0, 24));
  }

  /// Returns the geographic extent, preferring `metadata.bounds` and falling
  /// back to the envelope of the tiles present at [minZoom].
  ///
  /// The metadata form is "west,south,east,north" in WGS84 degrees.
  static LatLngBounds _resolveBounds(
    Database db,
    Map<String, String> meta,
    int minZoom,
  ) {
    final raw = meta['bounds'];
    if (raw != null) {
      final parts = raw.split(',').map((s) => double.tryParse(s.trim())).toList();
      if (parts.length == 4 && !parts.contains(null)) {
        final west = parts[0]!, south = parts[1]!;
        final east = parts[2]!, north = parts[3]!;
        if (north > south && east > west) {
          return LatLngBounds(LatLng(south, west), LatLng(north, east));
        }
      }
    }

    // Derive from the coarsest level, which has the fewest rows to scan.
    final row = db.select(
      'SELECT MIN(tile_column) AS minx, MAX(tile_column) AS maxx, '
      'MIN(tile_row) AS miny, MAX(tile_row) AS maxy '
      'FROM tiles WHERE zoom_level = ?',
      [minZoom],
    ).first;

    final minX = (row['minx'] as int?) ?? 0;
    final maxX = (row['maxx'] as int?) ?? 0;
    final minRow = (row['miny'] as int?) ?? 0;
    final maxRow = (row['maxy'] as int?) ?? 0;

    // tile_row is TMS (origin bottom-left), so the largest row index is the
    // northern edge. Convert to XYZ before going back to latitude.
    final northY = xyzToTmsRow(maxRow, minZoom);
    final southY = xyzToTmsRow(minRow, minZoom) + 1;

    return LatLngBounds(
      LatLng(tileYToLat(southY, minZoom), tileXToLon(minX, minZoom)),
      LatLng(tileYToLat(northY, minZoom), tileXToLon(maxX + 1, minZoom)),
    );
  }

  /// Converts flutter_map's XYZ row [y] to the TMS `tile_row` MBTiles stores.
  ///
  /// XYZ counts rows southward from the north edge; TMS counts them northward
  /// from the south edge. The mapping is its own inverse.
  static int xyzToTmsRow(int y, int z) => ((1 << z) - 1) - y;

  /// Inverse of `MapTileCacheService._lonToTileX`.
  static double tileXToLon(int x, int z) => x / (1 << z) * 360.0 - 180.0;

  /// Inverse of `MapTileCacheService._latToTileY`.
  static double tileYToLat(int y, int z) {
    final n = math.pi - 2.0 * math.pi * y / (1 << z);
    return 180.0 / math.pi *
        math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  /// Reads one tile, converting from flutter_map's XYZ [y] to MBTiles' TMS
  /// row. Returns null when the archive has no tile at that coordinate.
  Uint8List? tile(int z, int x, int y) {
    if (_closed) return null;
    if (z < minZoom || z > maxZoom) return null;

    final tmsRow = xyzToTmsRow(y, z);
    try {
      final result = _db.select(
        'SELECT tile_data FROM tiles '
        'WHERE zoom_level = ? AND tile_column = ? AND tile_row = ? LIMIT 1',
        [z, x, tmsRow],
      );
      if (result.isEmpty) return null;
      final data = result.first['tile_data'];
      if (data is! Uint8List) return null;
      return _maybeInflate(data);
    } catch (_) {
      return null;
    }
  }

  /// Transparently decompresses a tile blob when the archive stores it
  /// compressed.
  ///
  /// The MBTiles spec does not compress raster tiles, but writers that also
  /// emit vector archives frequently gzip every blob regardless. The bytes
  /// then reach the image decoder as a gzip stream, which fails to decode and
  /// leaves the layer blank even though every lookup succeeded.
  static Uint8List _maybeInflate(Uint8List data) {
    if (data.length < 2) return data;
    try {
      // gzip
      if (data[0] == 0x1f && data[1] == 0x8b) {
        return Uint8List.fromList(GZipDecoder().decodeBytes(data));
      }
      // raw zlib/deflate
      if (data[0] == 0x78 &&
          (data[1] == 0x01 || data[1] == 0x9c || data[1] == 0xda)) {
        return Uint8List.fromList(ZLibDecoder().decodeBytes(data));
      }
    } catch (_) {
      // Fall through and let the decoder report on the original bytes.
    }
    return data;
  }

  /// Reads the pixel dimensions of an encoded image, or null if unknown.
  ///
  /// Only PNG and JPEG are handled, which covers every raster MBTiles in
  /// practice. The width matters because flutter_map assumes 256px tiles: an
  /// archive of 512px tiles drawn at 256 produces a scrambled mosaic rather
  /// than an obviously broken layer.
  static (int, int)? imageSize(Uint8List b) {
    // PNG: 8-byte signature, then an IHDR chunk whose payload starts at 16.
    if (b.length >= 24 &&
        b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
      int be32(int o) =>
          (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
      return (be32(16), be32(20));
    }
    // JPEG: walk the segment markers to the first SOFn frame header.
    if (b.length >= 4 && b[0] == 0xFF && b[1] == 0xD8) {
      int i = 2;
      while (i + 9 < b.length) {
        if (b[i] != 0xFF) {
          i++;
          continue;
        }
        final marker = b[i + 1];
        // SOF0..SOF3, SOF5..SOF7, SOF9..SOF11, SOF13..SOF15
        final isSof = marker >= 0xC0 &&
            marker <= 0xCF &&
            marker != 0xC4 &&
            marker != 0xC8 &&
            marker != 0xCC;
        if (isSof) {
          final height = (b[i + 5] << 8) | b[i + 6];
          final width = (b[i + 7] << 8) | b[i + 8];
          return (width, height);
        }
        final segmentLength = (b[i + 2] << 8) | b[i + 3];
        if (segmentLength <= 0) break;
        i += 2 + segmentLength;
      }
    }
    return null;
  }

  /// Names the image format of [bytes] from its magic number, for diagnostics.
  static String sniffFormat(Uint8List bytes) {
    if (bytes.length < 4) return 'too short (${bytes.length}B)';
    bool starts(List<int> magic) {
      for (int i = 0; i < magic.length; i++) {
        if (bytes[i] != magic[i]) return false;
      }
      return true;
    }

    if (starts([0x89, 0x50, 0x4E, 0x47])) return 'PNG';
    if (starts([0xFF, 0xD8, 0xFF])) return 'JPEG';
    if (starts([0x47, 0x49, 0x46])) return 'GIF';
    if (starts([0x52, 0x49, 0x46, 0x46])) return 'WEBP/RIFF';
    if (starts([0x1F, 0x8B])) return 'GZIP (compressed)';
    if (starts([0x78])) return 'ZLIB (compressed)';
    final head = bytes
        .take(6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');
    return 'unknown [$head]';
  }

  /// Reports where the archive's tiles actually sit, interpreting `tile_row`
  /// both ways.
  ///
  /// The spec says `tile_row` is TMS (origin bottom-left), but some writers
  /// emit XYZ instead. Under the wrong interpretation every lookup misses and
  /// the layer renders nothing while the metadata still reads perfectly, so
  /// this compares both against the declared bounds.
  String describeCoverage() {
    // A mid-pyramid zoom: deep enough to be specific, shallow enough to scan.
    final probeZoom = minZoom + ((maxZoom - minZoom) ~/ 2);
    try {
      final row = _db.select(
        'SELECT MIN(tile_column) AS minx, MAX(tile_column) AS maxx, '
        'MIN(tile_row) AS minr, MAX(tile_row) AS maxr, COUNT(*) AS n '
        'FROM tiles WHERE zoom_level = ?',
        [probeZoom],
      ).first;

      final n = (row['n'] as int?) ?? 0;
      if (n == 0) return 'z$probeZoom: no tiles';

      final minX = row['minx'] as int;
      final maxX = row['maxx'] as int;
      final minR = row['minr'] as int;
      final maxR = row['maxr'] as int;

      final west = tileXToLon(minX, probeZoom);
      final east = tileXToLon(maxX + 1, probeZoom);

      // TMS: biggest row index is the northern edge.
      final tmsNorth = tileYToLat(xyzToTmsRow(maxR, probeZoom), probeZoom);
      final tmsSouth = tileYToLat(xyzToTmsRow(minR, probeZoom) + 1, probeZoom);
      // XYZ: smallest row index is the northern edge.
      final xyzNorth = tileYToLat(minR, probeZoom);
      final xyzSouth = tileYToLat(maxR + 1, probeZoom);

      // Sniff a real blob: metadata.format lies often enough that the magic
      // number is the only trustworthy answer.
      final sample = _db.select(
        'SELECT tile_data FROM tiles WHERE zoom_level = ? LIMIT 1',
        [probeZoom],
      );
      var blobInfo = 'no sample';
      if (sample.isNotEmpty) {
        final blob = sample.first['tile_data'];
        if (blob is Uint8List) {
          final inflated = _maybeInflate(blob);
          blobInfo = '${blob.length}B raw=${sniffFormat(blob)}';
          if (!identical(inflated, blob)) {
            blobInfo += ' -> inflated=${sniffFormat(inflated)}';
          }
        }
      }

      String f(double v) => v.toStringAsFixed(4);
      return 'blob=$blobInfo declaredFormat=$format | '
          'z$probeZoom n=$n cols=$minX..$maxX rows=$minR..$maxR | '
          'lon W${f(west)} E${f(east)} | '
          'if TMS: N${f(tmsNorth)} S${f(tmsSouth)} | '
          'if XYZ: N${f(xyzNorth)} S${f(xyzSouth)} | '
          'declared: N${f(bounds.north)} S${f(bounds.south)} '
          'E${f(bounds.east)} W${f(bounds.west)}';
    } catch (e) {
      return 'coverage probe failed: $e';
    }
  }

  /// Releases the SQLite handle.
  ///
  /// Must be called before deleting the file: on Windows an open handle blocks
  /// deletion outright, and on every platform it leaks until process exit.
  void close() {
    if (_closed) return;
    _closed = true;
    _db.dispose();
  }
}

/// A flutter_map [TileProvider] that serves tiles out of an [MbtilesSource].
///
/// Modelled on `MapTileCacheService`'s `_CachedNetworkTileProvider`.
class MbtilesTileProvider extends TileProvider {
  MbtilesTileProvider(this.source);

  final MbtilesSource source;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _MbtilesImage(source, coordinates.z, coordinates.x, coordinates.y);
}

/// Identity of a single tile for Flutter's [ImageCache].
///
/// Keying on the coordinates rather than the bytes matters: [MemoryImage]
/// compares its `Uint8List` by identity, and every read from SQLite returns a
/// fresh list, so it would never produce a cache hit when panning back over
/// ground already visited.
@immutable
class _MbtilesImageKey {
  const _MbtilesImageKey(this.path, this.z, this.x, this.y);

  final String path;
  final int z;
  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is _MbtilesImageKey &&
      other.path == path &&
      other.z == z &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(path, z, x, y);
}

class _MbtilesImage extends ImageProvider<_MbtilesImageKey> {
  const _MbtilesImage(this.source, this.z, this.x, this.y);

  final MbtilesSource source;
  final int z;
  final int x;
  final int y;

  /// 1x1 fully transparent PNG, substituted for coordinates the archive has no
  /// tile for so that gaps fall through to the base map instead of rendering
  /// flutter_map's error tile.
  static final Uint8List _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  );

  @override
  Future<_MbtilesImageKey> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(_MbtilesImageKey(source.filePath, z, x, y));

  @override
  ImageStreamCompleter loadImage(
    _MbtilesImageKey key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(key, decode),
      scale: 1.0,
      debugLabel: 'mbtiles:${key.path}/${key.z}/${key.x}/${key.y}',
    );
  }

  Future<ui.Codec> _loadCodec(
    _MbtilesImageKey key,
    ImageDecoderCallback decode,
  ) async {
    // sqlite3 reads are synchronous, but a single indexed row fetch of a few
    // kilobytes is sub-millisecond, so this stays off the critical path.
    final raw = source.tile(key.z, key.x, key.y);
    final bytes = raw ?? _transparentPng;
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return await decode(buffer);
    } catch (e) {
      // Tagged so it shows up alongside the other MBTiles diagnostics rather
      // than only as a generic image-service exception.
      // ignore: avoid_print
      print('[MBTiles] decode failed z${key.z}/${key.x}/${key.y}: '
          '${bytes.length}B ${MbtilesSource.sniffFormat(bytes)} — $e');
      final fallback = await ui.ImmutableBuffer.fromUint8List(_transparentPng);
      return decode(fallback);
    }
  }
}
