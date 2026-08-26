// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/services/map_tile_cache_service.dart';
import '../l10n/app_localizations.dart';

class OfflineMapDownloadDialog extends StatefulWidget {
  final LatLngBounds bounds;
  final String providerId;
  final String providerLabel;
  final String urlTemplate;
  final List<String> subdomains;

  /// Deepest zoom this provider serves. Downloading past it would cache 404
  /// bodies or blank placeholders as though they were map tiles.
  final int maxNativeZoom;

  const OfflineMapDownloadDialog({
    super.key,
    required this.bounds,
    required this.providerId,
    required this.providerLabel,
    required this.urlTemplate,
    required this.subdomains,
    required this.maxNativeZoom,
  });

  @override
  State<OfflineMapDownloadDialog> createState() =>
      _OfflineMapDownloadDialogState();
}

class _OfflineMapDownloadDialogState extends State<OfflineMapDownloadDialog> {
  static const int _minAllowedZoom = 8;
  static const int _defaultMinZoom = 12;
  static const int _defaultMaxZoom = 16;

  /// Upper end of the slider. Bounded by what the provider actually serves,
  /// with a floor so the range never collapses to zero divisions.
  int get _maxAllowedZoom =>
      widget.maxNativeZoom > _minAllowedZoom + 1
          ? widget.maxNativeZoom
          : _minAllowedZoom + 1;

  final TextEditingController _nameController = TextEditingController();

  late int _minZoom;
  late int _maxZoom;

  bool _isDownloading = false;
  bool _cancelRequested = false;

  int? _estimatedTiles;
  int? _estimatedBytes;

  MapTileCacheProgress? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    // A provider that stops at z16 must not open with a z16-to-z18 default.
    _maxZoom = _defaultMaxZoom.clamp(_minAllowedZoom, _maxAllowedZoom);
    _minZoom = _defaultMinZoom.clamp(_minAllowedZoom, _maxZoom);
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
    final l10n = AppLocalizations.of(context)!;
    final estimatedTiles = _estimatedTiles;
    final estimatedBytes = _estimatedBytes;

    final progress = _progress;
    final progressValue = (progress == null || progress.total == 0)
        ? null
        : (progress.completed / progress.total).clamp(0.0, 1.0);

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.downloadMapArea),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.mapProviderLabel(widget.providerLabel)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                enabled: !_isDownloading,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  hintText: l10n.waypointNameHint,
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
                child: Text(l10n.zoomRange('$_minZoom', '$_maxZoom')),
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
          child: Text(_isDownloading ? l10n.cancel : l10n.close),
        ),
        FilledButton(
          onPressed: _isDownloading ? null : _startDownload,
          child: Text(l10n.download),
        ),
      ],
    );
  }
}
