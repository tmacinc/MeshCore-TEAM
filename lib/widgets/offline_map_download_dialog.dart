// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/services/map_tile_cache_service.dart';

class OfflineMapDownloadDialog extends StatefulWidget {
  final LatLngBounds bounds;
  final String providerId;
  final String providerLabel;
  final String urlTemplate;
  final List<String> subdomains;

  const OfflineMapDownloadDialog({
    super.key,
    required this.bounds,
    required this.providerId,
    required this.providerLabel,
    required this.urlTemplate,
    required this.subdomains,
  });

  @override
  State<OfflineMapDownloadDialog> createState() =>
      _OfflineMapDownloadDialogState();
}

class _OfflineMapDownloadDialogState extends State<OfflineMapDownloadDialog> {
  static const int _minAllowedZoom = 8;
  static const int _maxAllowedZoom = 18;
  static const int _defaultMinZoom = 12;
  static const int _defaultMaxZoom = 16;

  final TextEditingController _nameController = TextEditingController();

  int _minZoom = _defaultMinZoom;
  int _maxZoom = _defaultMaxZoom;

  bool _isDownloading = false;
  bool _cancelRequested = false;

  int? _estimatedTiles;
  int? _estimatedBytes;

  MapTileCacheProgress? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recomputeEstimate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _recomputeEstimate() {
    final tileCache = context.read<MapTileCacheService>();
    final total =
        tileCache.estimateTileCount(widget.bounds, _minZoom, _maxZoom);

    // Match TEAM Android estimate: ~20KB per tile.
    const bytesPerTile = 20 * 1024;

    setState(() {
      _estimatedTiles = total;
      _estimatedBytes = total * bytesPerTile;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024.0;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024.0;
    return '${gb.toStringAsFixed(2)} GB';
  }

  Future<void> _startDownload() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _error = 'Please enter a name';
      });
      return;
    }

    final tileCache = context.read<MapTileCacheService>();
    final db = context.read<AppDatabase>();

    setState(() {
      _isDownloading = true;
      _cancelRequested = false;
      _progress = null;
      _error = null;
    });

    try {
      final result = await tileCache.downloadRegion(
        bounds: widget.bounds,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        urlTemplate: widget.urlTemplate,
        subdomains: widget.subdomains,
        concurrentDownloads: 2,
        isCancelled: () => _cancelRequested,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progress = p;
          });
        },
      );

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final id = const Uuid().v4();

      await db.offlineMapAreasDao.insertArea(
        OfflineMapAreasCompanion.insert(
          id: id,
          name: name,
          providerId: widget.providerId,
          north: widget.bounds.north,
          south: widget.bounds.south,
          east: widget.bounds.east,
          west: widget.bounds.west,
          minZoom: _minZoom,
          maxZoom: _maxZoom,
          tileCount: result.total,
          downloadedAt: nowMs,
          sizeBytes: result.sizeBytes,
        ),
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Downloaded ${result.downloaded}/${result.total} tiles (${_formatBytes(result.sizeBytes)})',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final cancelled = _cancelRequested;
      setState(() {
        _isDownloading = false;
        _progress = null;
        _error = cancelled ? 'Download cancelled' : 'Download failed: $e';
      });

      if (cancelled) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimatedTiles = _estimatedTiles;
    final estimatedBytes = _estimatedBytes;

    final progress = _progress;
    final progressValue = (progress == null || progress.total == 0)
        ? null
        : (progress.completed / progress.total).clamp(0.0, 1.0);

    return AlertDialog(
      scrollable: true,
      title: const Text('Download Map Area'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Provider: ${widget.providerLabel}'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                enabled: !_isDownloading,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Home, Trailhead, City Center',
                ),
                onChanged: (_) {
                  if (_error != null) {
                    setState(() {
                      _error = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Zoom range: $_minZoom–$_maxZoom'),
              ),
              RangeSlider(
                values: RangeValues(_minZoom.toDouble(), _maxZoom.toDouble()),
                min: _minAllowedZoom.toDouble(),
                max: _maxAllowedZoom.toDouble(),
                divisions: _maxAllowedZoom - _minAllowedZoom,
                labels: RangeLabels('$_minZoom', '$_maxZoom'),
                onChanged: _isDownloading
                    ? null
                    : (values) {
                        final nextMin = values.start.round();
                        final nextMax = values.end.round();
                        setState(() {
                          _minZoom = nextMin;
                          _maxZoom = nextMax;
                        });
                        _recomputeEstimate();
                      },
              ),
              if (estimatedTiles != null && estimatedBytes != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Estimated: $estimatedTiles tiles (~${_formatBytes(estimatedBytes)})',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (_isDownloading) ...[
                LinearProgressIndicator(value: progressValue),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    progress == null
                        ? 'Starting…'
                        : 'Progress: ${progress.completed}/${progress.total} (failed: ${progress.failed})',
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_isDownloading) {
              setState(() {
                _cancelRequested = true;
              });
              return;
            }
            Navigator.of(context).pop();
          },
          child: Text(_isDownloading ? 'Cancel' : 'Close'),
        ),
        FilledButton(
          onPressed: _isDownloading ? null : _startDownload,
          child: const Text('Download'),
        ),
      ],
    );
  }
}
