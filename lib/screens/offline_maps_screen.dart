// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/map_tile_providers.dart';
import 'package:meshcore_team/services/map_tile_cache_service.dart';

class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  bool _isBusy = false;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024.0;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024.0;
    return '${gb.toStringAsFixed(2)} GB';
  }

  String _formatDate(int msSinceEpoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  LatLngBounds _boundsForArea(OfflineMapAreaData area) {
    return LatLngBounds(
      LatLng(area.north, area.west),
      LatLng(area.south, area.east),
    );
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _deleteArea(OfflineMapAreaData area) async {
    final ok = await _confirm(
      'Delete offline map?',
      'This will remove downloaded tiles for "${area.name}".',
    );
    if (!ok) return;

    final db = context.read<AppDatabase>();
    final tileCache = context.read<MapTileCacheService>();
    final provider = tileProviderForId(area.providerId);

    setState(() {
      _isBusy = true;
    });

    try {
      await tileCache.deleteRegion(
        bounds: _boundsForArea(area),
        minZoom: area.minZoom,
        maxZoom: area.maxZoom,
        urlTemplate: provider.urlTemplate,
        subdomains: provider.subdomains,
      );
      await db.offlineMapAreasDao.deleteAreaById(area.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _clearAll(List<OfflineMapAreaData> areas) async {
    if (areas.isEmpty) return;

    final ok = await _confirm(
      'Clear all offline maps?',
      'This will remove all downloaded offline map areas and their tiles.',
    );
    if (!ok) return;

    final db = context.read<AppDatabase>();
    final tileCache = context.read<MapTileCacheService>();

    setState(() {
      _isBusy = true;
    });

    try {
      for (final area in areas) {
        final provider = tileProviderForId(area.providerId);
        await tileCache.deleteRegion(
          bounds: _boundsForArea(area),
          minZoom: area.minZoom,
          maxZoom: area.maxZoom,
          urlTemplate: provider.urlTemplate,
          subdomains: provider.subdomains,
        );
      }
      await db.offlineMapAreasDao.deleteAllAreas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clear all failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Maps'),
      ),
      body: StreamBuilder<List<OfflineMapAreaData>>(
        stream: db.offlineMapAreasDao.watchAllAreas(),
        builder: (context, snapshot) {
          final areas = snapshot.data ?? const <OfflineMapAreaData>[];

          return Column(
            children: [
              StreamBuilder<int>(
                stream: db.offlineMapAreasDao.watchTotalStorageBytes(),
                builder: (context, totalSnapshot) {
                  final totalBytes = totalSnapshot.data ?? 0;
                  return ListTile(
                    title: const Text('Storage'),
                    subtitle: Text(_formatBytes(totalBytes)),
                    trailing: IconButton(
                      tooltip: 'Clear all',
                      onPressed: _isBusy ? null : () => _clearAll(areas),
                      icon: const Icon(Icons.delete_sweep),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: areas.isEmpty
                    ? const Center(
                        child: Text('No offline maps downloaded'),
                      )
                    : ListView.separated(
                        itemCount: areas.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final area = areas[index];
                          final provider = tileProviderForId(area.providerId);
                          final subtitle =
                              '${provider.label} • zoom ${area.minZoom}–${area.maxZoom} • ${area.tileCount} tiles • ${_formatBytes(area.sizeBytes)}\nDownloaded ${_formatDate(area.downloadedAt)}';

                          return ListTile(
                            title: Text(area.name),
                            subtitle: Text(subtitle),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: 'Delete',
                              onPressed:
                                  _isBusy ? null : () => _deleteArea(area),
                              icon: const Icon(Icons.delete),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar:
          _isBusy ? const LinearProgressIndicator(minHeight: 2) : null,
    );
  }
}
