// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart' show LatLng;
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/database/daos/imported_overlay_maps_dao.dart';
import 'package:meshcore_team/services/kmz_import_service.dart';
import 'package:meshcore_team/services/mbtiles_import_service.dart';
import 'package:meshcore_team/services/mbtiles_registry.dart';

class ImportedMapsScreen extends StatefulWidget {
  const ImportedMapsScreen({super.key});

  @override
  State<ImportedMapsScreen> createState() => _ImportedMapsScreenState();
}

class _ImportedMapsScreenState extends State<ImportedMapsScreen> {
  bool _isBusy = false;
  int _importDone = 0;
  int _importTotal = 0;

  /// Heading shown in the busy overlay.
  String _importLabel = 'Importing map…';

  /// Whether progress counts bytes (MBTiles copy) or tiles (KMZ extract).
  bool _importIsBytes = false;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024.0;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024.0;
    return '${gb.toStringAsFixed(2)} GB';
  }

  /// Groups thousands so a six-figure tile count stays readable.
  String _formatTileCount(int count) {
    final digits = count.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String _formatDate(int msSinceEpoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $hh:$mm';
  }

  String _boundsLabel(ImportedOverlayMapData m) {
    final n = m.boundsNorth.toStringAsFixed(4);
    final s = m.boundsSouth.toStringAsFixed(4);
    final e = m.boundsEast.toStringAsFixed(4);
    final w = m.boundsWest.toStringAsFixed(4);
    return 'N$n S$s E$e W$w';
  }

  /// Calculates the total size of files inside an extracted overlay directory.
  Future<int> _dirSizeBytes(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Asks which format to import, then runs the matching importer.
  Future<void> _startImport() async {
    final choice = await showModalBottomSheet<OverlayLayerType>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text('Garmin KMZ'),
              subtitle: const Text(
                  'Raster map tiles from a Garmin Custom Map archive'),
              onTap: () => Navigator.of(context).pop(OverlayLayerType.kmz),
            ),
            ListTile(
              leading: const Icon(Icons.grid_on),
              title: const Text('MBTiles'),
              subtitle: const Text(
                  'Offline tile pyramid from QGIS, GDAL, or Mobile Atlas Creator'),
              onTap: () => Navigator.of(context).pop(OverlayLayerType.mbtiles),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    if (choice == OverlayLayerType.mbtiles) {
      await _importMbtiles();
    } else {
      await _importKmz();
    }
  }

  Future<void> _importKmz() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['kmz'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    setState(() {
      _isBusy = true;
      _importDone = 0;
      _importTotal = 0;
      _importLabel = 'Importing map…';
      _importIsBytes = false;
    });
    try {
      final kmzService = KmzImportService();
      final importResult = await kmzService.importKmz(
        File(path),
        onProgress: (done, total) {
          if (mounted) setState(() { _importDone = done; _importTotal = total; });
        },
      );

      // Save the doc.kml manifest for later tile reloading
      await kmzService.saveManifest(importResult.dirPath, importResult.tiles);

      // Calculate total on-disk size
      final sizeBytes = await _dirSizeBytes(importResult.dirPath);

      if (!mounted) return;
      final db = context.read<AppDatabase>();
      await db.importedOverlayMapsDao.insertMap(
        ImportedOverlayMapsCompanion.insert(
          id: const Uuid().v4(),
          name: importResult.name,
          dirPath: importResult.dirPath,
          tileCount: importResult.tiles.length,
          importedAt: DateTime.now().millisecondsSinceEpoch,
          boundsNorth: importResult.boundsNorth,
          boundsSouth: importResult.boundsSouth,
          boundsEast: importResult.boundsEast,
          boundsWest: importResult.boundsWest,
          layerType: Value(OverlayLayerType.kmz.dbValue),
          sizeBytes: Value(sizeBytes),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported "${importResult.name}" — ${importResult.tiles.length} tile${importResult.tiles.length == 1 ? '' : 's'} (${_formatBytes(sizeBytes)})',
          ),
        ),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.importFailedError(e.message))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.importFailedError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importMbtiles() async {
    // Deliberately FileType.any rather than allowedExtensions: ['mbtiles'].
    // Android resolves custom extensions through MIME types, and .mbtiles has
    // no registered type, so the picker would grey the file out.
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    if (!path.toLowerCase().endsWith('.mbtiles')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a .mbtiles file.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isBusy = true;
      _importDone = 0;
      _importTotal = 0;
      _importLabel = 'Copying map…';
      _importIsBytes = true;
    });

    try {
      final service = context.read<MbtilesImportService>();
      final importResult = await service.importMbtiles(
        File(path),
        onProgress: (done, total) {
          if (mounted) {
            setState(() {
              _importDone = done;
              _importTotal = total;
            });
          }
        },
      );

      if (!mounted) return;
      final db = context.read<AppDatabase>();
      await db.importedOverlayMapsDao.insertMap(
        ImportedOverlayMapsCompanion.insert(
          id: importResult.mapId,
          name: importResult.name,
          dirPath: importResult.dirPath,
          tileCount: importResult.tileCount,
          importedAt: DateTime.now().millisecondsSinceEpoch,
          boundsNorth: importResult.boundsNorth,
          boundsSouth: importResult.boundsSouth,
          boundsEast: importResult.boundsEast,
          boundsWest: importResult.boundsWest,
          layerType: Value(OverlayLayerType.mbtiles.dbValue),
          minZoom: Value(importResult.minZoom),
          maxZoom: Value(importResult.maxZoom),
          sizeBytes: Value(importResult.sizeBytes),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported "${importResult.name}" — ${importResult.tileCount} tiles, '
            'z${importResult.minZoom}–${importResult.maxZoom} '
            '(${_formatBytes(importResult.sizeBytes)})',
          ),
        ),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.importFailedError(e.message))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.importFailedError(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _importIsBytes = false;
        });
      }
    }
  }

  Future<void> _deleteMap(ImportedOverlayMapData m) async {
    final ok = await _confirm(
      'Delete map?',
      'This will remove "${m.name}" and its image files from the device.',
    );
    if (!ok || !mounted) return;

    setState(() => _isBusy = true);
    try {
      // Release the SQLite handle first: on Windows an open handle blocks the
      // directory delete outright, and elsewhere it would leak until exit.
      if (m.type.isTiled) {
        context.read<MbtilesRegistry>().close(m.id);
      }
      final dir = Directory(m.dirPath);
      if (dir.existsSync()) await dir.delete(recursive: true);
      if (!mounted) return;
      final db = context.read<AppDatabase>();
      await db.importedOverlayMapsDao.deleteMapById(m.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deleteFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _toggleVisibility(ImportedOverlayMapData m) async {
    final db = context.read<AppDatabase>();
    await db.importedOverlayMapsDao.updateVisibility(m.id, !m.isVisible);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final db = context.read<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importedMaps),
        actions: [
          IconButton(
            tooltip: l10n.importMapFile,
            onPressed: _isBusy ? null : _startImport,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<ImportedOverlayMapData>>(
        stream: db.importedOverlayMapsDao.watchAllMaps(),
        builder: (context, snapshot) {
          final maps = snapshot.data ?? const <ImportedOverlayMapData>[];

          if (maps.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No imported maps',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Import a Garmin-style KMZ file or an MBTiles archive '
                      'to display a custom offline map on top of the base map.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isBusy ? null : _startImport,
                      icon: const Icon(Icons.file_open),
                      label: Text(l10n.importMap),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: maps.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final m = maps[index];
              final isTiled = m.type.isTiled;

              // Tiled maps report their zoom range and on-disk size, which is
              // what actually tells you whether the map covers your area.
              final detail = isTiled
                  ? '${_formatTileCount(m.tileCount)} tiles • '
                      'z${m.minZoom ?? 0}–${m.maxZoom ?? 0}'
                      '${m.sizeBytes > 0 ? ' • ${_formatBytes(m.sizeBytes)}' : ''}'
                  : '${m.tileCount} tile${m.tileCount == 1 ? '' : 's'}';

              final subtitle = '$detail\n'
                  '${_boundsLabel(m)} • Imported ${_formatDate(m.importedAt)}';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      isTiled ? Icons.grid_on : Icons.layers,
                      color: m.isVisible
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    title: Text(m.name),
                    subtitle: Text(subtitle),
                    isThreeLine: true,
                    // Jump the map to this layer's extent. Without this there
                    // is no way to find a layer whose coverage you don't
                    // already know, and it silently looks broken instead.
                    onTap: _isBusy
                        ? null
                        : () => Navigator.of(context).pop(
                              LatLngBounds(
                                LatLng(m.boundsSouth, m.boundsWest),
                                LatLng(m.boundsNorth, m.boundsEast),
                              ),
                            ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: m.isVisible ? 'Hide on map' : 'Show on map',
                          child: IconButton(
                            onPressed:
                                _isBusy ? null : () => _toggleVisibility(m),
                            icon: Icon(
                              m.isVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        Tooltip(
                          message: l10n.delete,
                          child: IconButton(
                            onPressed: _isBusy ? null : () => _deleteMap(m),
                            icon: const Icon(Icons.delete),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (m.isVisible)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.opacity, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Slider(
                              // Must be clamped to the slider's own range, not
                              // just to 0..1, or Slider asserts on a stored
                              // value below the minimum.
                              value: m.opacity.clamp(0.2, 1.0),
                              min: 0.2,
                              max: 1.0,
                              divisions: 8,
                              label: '${(m.opacity * 100).round()}%',
                              onChanged: _isBusy
                                  ? null
                                  : (value) => db.importedOverlayMapsDao
                                      .updateOpacity(m.id, value),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
          if (_isBusy)
            const ModalBarrier(color: Color(0x88000000), dismissible: false),
          if (_isBusy)
            Center(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _importLabel,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _importTotal > 0
                            ? _importDone / _importTotal
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _importTotal <= 0
                            ? 'Reading archive…'
                            : _importIsBytes
                                ? '${_formatBytes(_importDone)} of ${_formatBytes(_importTotal)}…'
                                : 'Extracting tile $_importDone of $_importTotal…',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}
