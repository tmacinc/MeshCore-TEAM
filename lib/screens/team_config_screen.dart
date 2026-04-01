// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:meshcore_team/ble/ble_connection_manager.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/map_tile_providers.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import 'package:meshcore_team/services/map_tile_cache_service.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/services/team_config_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';

enum TeamConfigMode { export, import }

class TeamConfigScreen extends StatefulWidget {
  final TeamConfigMode mode;

  const TeamConfigScreen({super.key, required this.mode});

  @override
  State<TeamConfigScreen> createState() => _TeamConfigScreenState();
}

class _TeamConfigScreenState extends State<TeamConfigScreen> {
  final TeamConfigService _configService = TeamConfigService();

  // Export state
  List<ChannelData> _allChannels = [];
  List<WaypointData> _allWaypoints = [];
  List<OfflineMapAreaData> _allMapAreas = [];

  final Set<int> _selectedChannelHashes = {};
  final Set<String> _selectedWaypointIds = {};
  final Set<String> _selectedMapAreaIds = {};
  bool _includeRadioSettings = true;
  final TextEditingController _configNameController = TextEditingController();

  bool _isBusy = false;
  String _busyMessage = '';
  double _busyProgress = 0;

  @override
  void initState() {
    super.initState();
    if (widget.mode == TeamConfigMode.export) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _configNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = context.read<AppDatabase>();
    final settings = context.read<SettingsService>();
    final companionKey = settings.settings.currentCompanionPublicKey;

    final channels = companionKey != null && companionKey.isNotEmpty
        ? await db.channelsDao.getChannelsByCompanion(companionKey)
        : <ChannelData>[];
    final waypoints = await db.waypointsDao.getAllWaypoints();
    final mapAreas = await db.offlineMapAreasDao.getAllAreas();

    if (!mounted) return;
    setState(() {
      _allChannels = channels;
      _allWaypoints = waypoints;
      _allMapAreas = mapAreas;

      // Select all private channels by default.
      _selectedChannelHashes.addAll(
        channels.where((c) => !c.isPublic).map((c) => c.hash),
      );
      // Select all waypoints by default.
      _selectedWaypointIds.addAll(waypoints.map((w) => w.id));
      // Select all map areas by default.
      _selectedMapAreaIds.addAll(mapAreas.map((a) => a.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final bleManager = context.watch<BleConnectionManager>();
    final connectionVM = context.watch<ConnectionViewModel>();
    final isConnected = bleManager.isConnected;
    final isExport = widget.mode == TeamConfigMode.export;

    return Scaffold(
      appBar: AppBar(
        title: Text(isExport ? 'Create Team Config' : 'Import Team Config'),
      ),
      body: _isBusy
          ? _buildBusyView()
          : isExport
              ? _buildExportView(connectionVM)
              : _buildImportView(isConnected, connectionVM),
    );
  }

  Widget _buildBusyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              _busyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_busyProgress > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _busyProgress),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportView(ConnectionViewModel connectionVM) {
    final privateChannels = _allChannels.where((c) => !c.isPublic).toList();
    final estimatedTileSize = _allMapAreas
        .where((a) => _selectedMapAreaIds.contains(a.id))
        .fold<int>(0, (sum, a) => sum + a.sizeBytes);
    final caps = connectionVM.deviceCapabilities;

    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset + 24),
      children: [
        // Config Name
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _configNameController,
            decoration: const InputDecoration(
              labelText: 'Config Name',
              hintText: 'e.g. Team Alpha, SAR Unit 5',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ),

        // Radio Settings
        if (caps != null)
          Card(
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              title: const Text('Radio Settings',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${caps.frequencyMHz.toStringAsFixed(3)} MHz · '
                'BW ${caps.bandwidthKHz.toStringAsFixed(1)} kHz · '
                'SF${caps.spreadingFactor} · CR 4/${caps.codingRate}',
              ),
              value: _includeRadioSettings,
              onChanged: (val) => setState(() => _includeRadioSettings = val),
            ),
          ),
        if (caps != null) const SizedBox(height: 8),

        // Channels
        _buildSectionCard(
          title: 'Channels',
          subtitle:
              '${_selectedChannelHashes.length} of ${privateChannels.length} selected',
          children: privateChannels.map((channel) {
            return CheckboxListTile(
              title: Text(channel.name),
              value: _selectedChannelHashes.contains(channel.hash),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedChannelHashes.add(channel.hash);
                  } else {
                    _selectedChannelHashes.remove(channel.hash);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Waypoints & Routes
        if (_allWaypoints.isNotEmpty)
          _buildSectionCard(
            title: 'Waypoints & Routes',
            subtitle:
                '${_selectedWaypointIds.length} of ${_allWaypoints.length} selected',
            children: [
              CheckboxListTile(
                title: const Text('Select All'),
                value: _selectedWaypointIds.length == _allWaypoints.length
                    ? true
                    : _selectedWaypointIds.isEmpty
                        ? false
                        : null,
                tristate: true,
                onChanged: (val) {
                  setState(() {
                    if (_selectedWaypointIds.length == _allWaypoints.length) {
                      // All are selected → deselect all.
                      _selectedWaypointIds.clear();
                    } else {
                      // Some or none selected → select all.
                      _selectedWaypointIds
                          .addAll(_allWaypoints.map((w) => w.id));
                    }
                  });
                },
              ),
              const Divider(height: 1),
              ..._allWaypoints.map((wp) {
                final isRoute = wp.waypointType == 'ROUTE';
                return CheckboxListTile(
                  secondary: Icon(
                    isRoute ? Icons.route : Icons.location_on,
                    color: isRoute ? Colors.blue : Colors.red,
                    size: 20,
                  ),
                  title: Text(wp.name),
                  subtitle: Text(isRoute ? 'Route' : wp.waypointType),
                  value: _selectedWaypointIds.contains(wp.id),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedWaypointIds.add(wp.id);
                      } else {
                        _selectedWaypointIds.remove(wp.id);
                      }
                    });
                  },
                );
              }),
            ],
          ),
        const SizedBox(height: 8),

        // Map Areas
        if (_allMapAreas.isNotEmpty) ...[
          _buildSectionCard(
            title: 'Offline Map Areas',
            subtitle:
                '${_selectedMapAreaIds.length} of ${_allMapAreas.length} selected',
            children: _allMapAreas.map((area) {
              final provider = tileProviderForId(area.providerId);
              final sizeMB =
                  (area.sizeBytes / (1024 * 1024)).toStringAsFixed(1);
              return CheckboxListTile(
                title: Text(area.name),
                subtitle: Text(
                    '${provider.label} · $sizeMB MB · ${area.tileCount} tiles'),
                value: _selectedMapAreaIds.contains(area.id),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedMapAreaIds.add(area.id);
                    } else {
                      _selectedMapAreaIds.remove(area.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Estimated size
        if (estimatedTileSize > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Estimated tile size: ~${(estimatedTileSize / (1024 * 1024)).toStringAsFixed(1)} MB',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),

        const SizedBox(height: 16),

        // Export button
        FilledButton.icon(
          onPressed: _selectedChannelHashes.isEmpty &&
                  _selectedWaypointIds.isEmpty &&
                  _selectedMapAreaIds.isEmpty
              ? null
              : _exportConfig,
          icon: const Icon(Icons.file_download),
          label: const Text('Export Config'),
        ),
      ],
    );
  }

  Widget _buildImportView(bool isConnected, ConnectionViewModel connectionVM) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isConnected) ...[
            Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          'Connect to a companion device before importing. '
                          'Channels must be registered with firmware.'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Select a .teamcfg.zip file to import channels, waypoints, '
            'and offline map tiles.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isConnected ? _importConfig : null,
            icon: const Icon(Icons.file_upload),
            label: const Text('Select .teamcfg.zip file'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        initiallyExpanded: true,
        children: children,
      ),
    );
  }

  Future<void> _exportConfig() async {
    setState(() {
      _isBusy = true;
      _busyMessage = 'Preparing export…';
      _busyProgress = 0;
    });

    try {
      final tileCache = context.read<MapTileCacheService>();
      final tempDir = await getTemporaryDirectory();

      final selectedChannels = _allChannels
          .where((c) => _selectedChannelHashes.contains(c.hash))
          .toList();
      final selectedWaypoints = _allWaypoints
          .where((w) => _selectedWaypointIds.contains(w.id))
          .toList();
      final selectedMapAreas = _allMapAreas
          .where((a) => _selectedMapAreaIds.contains(a.id))
          .toList();

      // Build radio settings from connected device capabilities.
      TeamConfigRadioSettings? radioSettings;
      if (_includeRadioSettings) {
        final connectionVM = context.read<ConnectionViewModel>();
        final caps = connectionVM.deviceCapabilities;
        if (caps != null) {
          radioSettings = TeamConfigRadioSettings(
            frequencyMHz: caps.frequencyMHz,
            bandwidthKHz: caps.bandwidthKHz,
            spreadingFactor: caps.spreadingFactor,
            codingRate: caps.codingRate,
          );
        }
      }

      final zipFile = await _configService.exportConfig(
        channels: selectedChannels,
        waypoints: selectedWaypoints,
        mapAreas: selectedMapAreas,
        tileCache: tileCache,
        name: _configNameController.text.trim(),
        description: '',
        tempDir: tempDir,
        radioSettings: radioSettings,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _busyMessage = progress.phase;
            _busyProgress =
                progress.total > 0 ? progress.current / progress.total : 0;
          });
        },
      );

      if (!mounted) return;

      // Let user choose save location.
      final configName = _configNameController.text.trim();
      final safeName = configName.isNotEmpty
          ? configName
              .replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '')
              .replaceAll(' ', '_')
          : 'team_config';
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Team Config',
        fileName: '$safeName.teamcfg.zip',
        type: FileType.any,
        bytes: await zipFile.readAsBytes(),
      );

      if (outputPath == null || !mounted) return;

      // On some platforms saveFile() writes the bytes for us, on others
      // it only returns the path.
      final outFile = File(outputPath);
      if (!await outFile.exists() || await outFile.length() == 0) {
        await outFile.writeAsBytes(await zipFile.readAsBytes(), flush: true);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Config saved to $outputPath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importConfig() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      if (picked.bytes == null) return;

      // Write to temp file for the archive library.
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/import_${picked.name}');
      await tempFile.writeAsBytes(picked.bytes!, flush: true);

      // Read preview.
      final preview = await _configService.readPreview(tempFile);

      if (!mounted) return;

      // Show preview dialog.
      final confirmed = await _showImportPreviewDialog(preview);
      if (confirmed != true || !mounted) return;

      setState(() {
        _isBusy = true;
        _busyMessage = 'Importing…';
        _busyProgress = 0;
      });

      final db = context.read<AppDatabase>();
      final tileCache = context.read<MapTileCacheService>();
      final channelRepo = context.read<ChannelRepository>();
      final connectionVM = context.read<ConnectionViewModel>();

      final importResult = await _configService.importConfig(
        zipFile: tempFile,
        db: db,
        tileCache: tileCache,
        channelRepo: channelRepo,
        applyRadioSettings: (settings) => connectionVM.applyRadioSettings(
          frequencyMHz: settings.frequencyMHz,
          bandwidthKHz: settings.bandwidthKHz,
          spreadingFactor: settings.spreadingFactor,
          codingRate: settings.codingRate,
          txPowerDbm: connectionVM.deviceCapabilities?.txPower ?? 20,
        ),
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _busyMessage = progress.phase;
            _busyProgress =
                progress.total > 0 ? progress.current / progress.total : 0;
          });
        },
      );

      // Clean up temp file.
      try {
        await tempFile.delete();
      } catch (_) {}

      if (!mounted) return;

      // Refresh data.
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(importResult.toString())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<bool?> _showImportPreviewDialog(TeamConfigPreview preview) {
    final tileSizeMB =
        (preview.tileSizeBytes / (1024 * 1024)).toStringAsFixed(1);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Team Config'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (preview.name != null && preview.name!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    preview.name!,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              if (preview.description != null &&
                  preview.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    preview.description!,
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                ),
              if (preview.radioSettings != null) ...[
                Text(
                  'Radio Settings',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Text(
                    '${preview.radioSettings!.frequencyMHz.toStringAsFixed(3)} MHz · '
                    'BW ${preview.radioSettings!.bandwidthKHz.toStringAsFixed(1)} kHz · '
                    'SF${preview.radioSettings!.spreadingFactor} · '
                    'CR 4/${preview.radioSettings!.codingRate}',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (preview.channels.isNotEmpty) ...[
                Text(
                  'Channels (${preview.channels.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...preview.channels.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 12, top: 2),
                      child: Text('• ${c.name}'),
                    )),
                const SizedBox(height: 8),
              ],
              if (preview.waypoints.isNotEmpty) ...[
                Text(
                  'Waypoints & Routes (${preview.waypoints.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...preview.waypoints.map((w) => Padding(
                      padding: const EdgeInsets.only(left: 12, top: 2),
                      child: Text('• ${w.name} (${w.waypointType})'),
                    )),
                const SizedBox(height: 8),
              ],
              if (preview.tileCount > 0) ...[
                Text(
                  'Map Tiles: ${preview.tileCount} (~$tileSizeMB MB)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...preview.tileAreas.map((a) {
                  final provider = tileProviderForId(a.providerId);
                  return Padding(
                    padding: const EdgeInsets.only(left: 12, top: 2),
                    child: Text('• ${a.name} (${provider.label})'),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
