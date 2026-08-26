// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/main.dart' show isBetaBuild;
import 'package:meshcore_team/ble/ble_commands.dart';
import 'package:meshcore_team/ble/ble_connection_manager.dart';
import 'package:meshcore_team/ble/mesh_ble_device.dart';
import 'package:meshcore_team/models/sync_status.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/theme/night_theme.dart';
import 'package:meshcore_team/widgets/night_clock.dart';
import 'package:meshcore_team/widgets/themed_dropdown.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import 'package:meshcore_team/repositories/contact_repository.dart';
import 'package:meshcore_team/screens/forwarding_debug_screen.dart';
import 'package:meshcore_team/screens/debug_log_screen.dart';
import 'package:meshcore_team/screens/team_config_screen.dart';
import 'package:meshcore_team/screens/offline_share_screen.dart';
import 'package:meshcore_team/services/map_tile_cache_service.dart';
import 'package:meshcore_team/models/map_tile_providers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';


/// Connection Screen
/// Provides device scanning, connection, and sync progress UI
/// Matches Android MainActivity/DeviceListActivity functionality
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _isScanning = false;
  final List<MeshBleDevice> _discoveredDevices = [];
  BleConnectionManager? _bleManager;

  Timer? _hideSyncTimer;
  bool _hideSyncProgress = false;
  bool _lastSyncWasComplete = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bleManager == null) {
      _bleManager = context.read<BleConnectionManager>();
      if (_bleManager!.isConnected &&
          context.read<ConnectionViewModel>().syncStatus.isComplete) {
        // Already synced before this screen opened — skip the flash.
        _lastSyncWasComplete = true;
        _hideSyncProgress = true;
      } else if (_discoveredDevices.isEmpty && !_bleManager!.isConnected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startScan();
        });
      }
    }
  }

  void _updateSyncProgressVisibility({
    required bool isConnected,
    required bool isSyncComplete,
  }) {
    if (!isConnected) {
      _hideSyncTimer?.cancel();
      _hideSyncTimer = null;

      if (_hideSyncProgress || _lastSyncWasComplete) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _hideSyncProgress = false;
            _lastSyncWasComplete = false;
          });
        });
      }
      return;
    }

    if (!isSyncComplete) {
      _hideSyncTimer?.cancel();
      _hideSyncTimer = null;

      if (_hideSyncProgress || _lastSyncWasComplete) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _hideSyncProgress = false;
            _lastSyncWasComplete = false;
          });
        });
      }
      return;
    }

    // Sync just completed: keep visible briefly, then hide.
    if (!_lastSyncWasComplete) {
      _hideSyncTimer?.cancel();
      _hideSyncTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _hideSyncProgress = true;
        });
      });

      _lastSyncWasComplete = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bleManager = context.watch<BleConnectionManager>();
    final connectionVM = context.watch<ConnectionViewModel>();

    _updateSyncProgressVisibility(
      isConnected: bleManager.isConnected,
      isSyncComplete: connectionVM.syncStatus.isComplete,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(l10n.connection),
        actions: [
          if (kDebugMode || isBetaBuild)
            IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.article_outlined),
              tooltip: l10n.debugLogs,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DebugLogScreen(),
                ),
              ),
            ),
          if (bleManager.isConnected)
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.settings),
              tooltip: l10n.teamConfig,
              onSelected: (value) {
                if (value == 'share_offline') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OfflineShareScreen(),
                    ),
                  );
                  return;
                }
                if (value == 'wipe_data') {
                  _showWipeDataDialog();
                  return;
                }
                final mode = value == 'export'
                    ? TeamConfigMode.export
                    : TeamConfigMode.import;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TeamConfigScreen(mode: mode),
                  ),
                );
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: const Icon(Icons.file_download),
                    title: Text(l10n.createTeamConfig),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'import',
                  child: ListTile(
                    leading: const Icon(Icons.file_upload),
                    title: Text(l10n.importTeamConfig),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'share_offline',
                  child: ListTile(
                    leading: const Icon(Icons.wifi_tethering),
                    title: Text(l10n.shareConfigOffline),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'wipe_data',
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: Text(l10n.wipeLocalData,
                        style: const TextStyle(color: Colors.red)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          _buildConnectionStatusIndicator(bleManager),
        ],
      ),
      body: Column(
        children: [
          // Sync progress section (shown when connected)
          if (bleManager.isConnected && !_hideSyncProgress) ...[
            _buildSyncProgressSection(connectionVM),
            const Divider(),
          ],

          // Scanner section
          Expanded(
            child: bleManager.isConnected
                ? _buildConnectedView(bleManager, connectionVM)
                : _buildScannerView(bleManager),
          ),
        ],
      ),
      floatingActionButton: bleManager.isConnected
          ? null
          : FloatingActionButton(
              onPressed: _isScanning ? _stopScan : _startScan,
              child: Icon(_isScanning ? Icons.stop : Icons.search),
            ),
    );
  }

  Future<void> _showWipeDataDialog() async {
    final db = context.read<AppDatabase>();
    final channelRepo = context.read<ChannelRepository>();
    final settingsService = context.read<SettingsService>();
    final tileCache = context.read<MapTileCacheService>();
    final companionKey =
        settingsService.settings.currentCompanionPublicKey ?? '';

    // Load current data counts for display
    final channels = companionKey.isNotEmpty
        ? await db.channelsDao.getChannelsByCompanion(companionKey)
        : <ChannelData>[];
    final privateChannels =
        channels.where((c) => !c.isPublic && c.channelIndex != 0).toList();
    final waypoints = await db.waypointsDao.getAllWaypoints();
    final mapAreas = await db.offlineMapAreasDao.getAllAreas();

    if (!mounted) return;

    bool wipeChannels = false;
    bool wipeWaypoints = false;
    bool wipeMaps = false;
    bool isWiping = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final l10n = AppLocalizations.of(context)!;
            final nothingSelected =
                !wipeChannels && !wipeWaypoints && !wipeMaps;

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 28),
                  const SizedBox(width: 8),
                  Text(l10n.wipeLocalData),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.wipePermanentDeleteWarning,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: wipeChannels,
                    onChanged: isWiping
                        ? null
                        : (v) =>
                            setDialogState(() => wipeChannels = v ?? false),
                    title: Text(l10n.channelsWithPrivateCount(privateChannels.length)),
                    subtitle:
                        Text(l10n.clearsFromFirmwareAndLocalDatabase),
                    secondary: const Icon(Icons.radio),
                    dense: true,
                    enabled: privateChannels.isNotEmpty && !isWiping,
                  ),
                  CheckboxListTile(
                    value: wipeWaypoints,
                    onChanged: isWiping
                        ? null
                        : (v) =>
                            setDialogState(() => wipeWaypoints = v ?? false),
                    title: Text(l10n.waypointsAndRoutesWithCount(waypoints.length)),
                    secondary: const Icon(Icons.place),
                    dense: true,
                    enabled: waypoints.isNotEmpty && !isWiping,
                  ),
                  CheckboxListTile(
                    value: wipeMaps,
                    onChanged: isWiping
                        ? null
                        : (v) => setDialogState(() => wipeMaps = v ?? false),
                    title: Text(l10n.offlineMapsWithCount(mapAreas.length)),
                    subtitle:
                        Text(l10n.removesDownloadedTilesAndMetadata),
                    secondary: const Icon(Icons.map),
                    dense: true,
                    enabled: mapAreas.isNotEmpty && !isWiping,
                  ),
                  if (isWiping) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(l10n.wipingData),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isWiping ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton.icon(
                  onPressed: (nothingSelected || isWiping)
                      ? null
                      : () async {
                          // Second confirmation
                          final confirm = await showDialog<bool>(
                            context: dialogContext,
                            builder: (ctx) {
                              final innerL10n = AppLocalizations.of(ctx)!;
                              return AlertDialog(
                                title: Text(innerL10n.areYouSure),
                                content: Text(
                                  '${innerL10n.wipePermanentDeleteWarning} '
                                  '${wipeChannels ? 'Channels will be cleared from the connected companion firmware. ' : ''}'
                                  'This cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: Text(innerL10n.cancel),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: Text(innerL10n.wipe),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirm != true) return;

                          setDialogState(() => isWiping = true);

                          try {
                            if (wipeChannels) {
                              for (final ch in privateChannels) {
                                try {
                                  await channelRepo.deletePrivateChannel(ch);
                                } catch (e) {
                                  debugPrint(
                                      '[Wipe] Channel delete failed: $e');
                                }
                              }
                            }
                            if (wipeWaypoints) {
                              await db.waypointsDao.deleteAllWaypoints();
                            }
                            if (wipeMaps) {
                              for (final area in mapAreas) {
                                final provider =
                                    tileProviderForId(area.providerId);
                                await tileCache.deleteRegion(
                                  bounds: LatLngBounds(
                                    LatLng(area.south, area.west),
                                    LatLng(area.north, area.east),
                                  ),
                                  minZoom: area.minZoom,
                                  maxZoom: area.maxZoom,
                                  urlTemplate: provider.urlTemplate,
                                  subdomains: provider.subdomains,
                                );
                              }
                              await db.offlineMapAreasDao.deleteAllAreas();
                            }

                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                  content: Text(AppLocalizations.of(this.context)!.dataWipedSuccessfully)),
                            );
                          } catch (e) {
                            setDialogState(() => isWiping = false);
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(this.context)!.wipeFailed(e.toString()))),
                            );
                          }
                        },
                  icon: const Icon(Icons.delete_forever),
                  label: Text(l10n.wipeSelected),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Connection status indicator
  Widget _buildConnectionStatusIndicator(BleConnectionManager bleManager) {
    final l10n = AppLocalizations.of(context)!;
    final isNighttime = context.read<SettingsService>().settings.appTheme ==
        AppThemeMode.nighttime;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (bleManager.state) {
      case BleConnectionState.connected:
        statusColor = isNighttime ? NightColors.statusConnected : Colors.green;
        statusIcon = Icons.check_circle;
        statusText = l10n.connected;
        break;
      case BleConnectionState.connecting:
        statusColor = isNighttime ? NightColors.statusConnecting : Colors.orange;
        statusIcon = Icons.sync;
        statusText = l10n.connecting;
        break;
      case BleConnectionState.scanning:
        statusColor = isNighttime ? NightColors.statusScanning : Colors.blue;
        statusIcon = Icons.search;
        statusText = l10n.scanning;
        break;
      case BleConnectionState.error:
        statusColor = isNighttime ? NightColors.primary : Colors.red;
        statusIcon = Icons.error;
        statusText = l10n.error;
        break;
      default:
        statusColor = isNighttime ? NightColors.statusDisconnected : Colors.grey;
        statusIcon = Icons.bluetooth_disabled;
        statusText = l10n.notConnected;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Text(statusText, style: TextStyle(color: statusColor)),
        ],
      ),
    );
  }

  /// Sync progress section
  Widget _buildSyncProgressSection(ConnectionViewModel connectionVM) {
    final l10n = AppLocalizations.of(context)!;
    final syncStatus = connectionVM.syncStatus;
    final phaseText = _getSyncPhaseText(syncStatus.phase, l10n);
    final progress = syncStatus.progressPercentage;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!syncStatus.isComplete)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (syncStatus.isComplete)
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                phaseText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (!syncStatus.isComplete && syncStatus.totalItems > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 4),
            Text(
              '${syncStatus.currentItem} / ${syncStatus.totalItems}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get sync phase display text
  String _getSyncPhaseText(SyncPhase phase, AppLocalizations l10n) {
    switch (phase) {
      case SyncPhase.idle:
        return l10n.idle;
      case SyncPhase.connecting:
        return '${l10n.connecting}...';
      case SyncPhase.syncingContacts:
        return l10n.syncingContacts;
      case SyncPhase.syncingChannels:
        return l10n.syncingChannels;
      case SyncPhase.syncingMessages:
        return l10n.syncingMessages;
      case SyncPhase.complete:
        return l10n.syncComplete;
    }
  }

  /// Scanner view (when not connected)
  Widget _buildScannerView(BleConnectionManager bleManager) {
    final l10n = AppLocalizations.of(context)!;
    // Permission error: service caught a SecurityException or missing Bluetooth
    // permission. Show a recovery banner so the user can re-grant without
    // needing to find Settings manually.
    final isPermissionError = bleManager.state == BleConnectionState.error &&
        (bleManager.errorMessage?.toLowerCase().contains('permission') ??
            false);

    if (isPermissionError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                l10n.permissionRequired,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                bleManager.errorMessage ?? 'Bluetooth permission not granted.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: Text(l10n.openAppSettings),
                onPressed: () => openAppSettings(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enable "Nearby devices" permission, then return to the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Bluetooth adapter disabled: native emits "Bluetooth is disabled" (Android)
    // or "Bluetooth is not turned on" (iOS).
    final isBleDisabled = bleManager.state == BleConnectionState.error &&
        (() {
          final msg = bleManager.errorMessage?.toLowerCase() ?? '';
          return msg.contains('disabled') ||
              msg.contains('not turned on') ||
              msg.contains('scanner unavailable');
        }());

    if (isBleDisabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bluetooth_disabled,
                  size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Bluetooth is Disabled',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Turn on Bluetooth and tap Retry.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
                onPressed: _startScan,
              ),
            ],
          ),
        ),
      );
    }

    if (_isScanning && _discoveredDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.scanningForDevices),
          ],
        ),
      );
    }

    if (_discoveredDevices.isEmpty) {
      final emptyColor = Theme.of(context).colorScheme.outline;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_searching, size: 64, color: emptyColor),
            const SizedBox(height: 16),
            Text(l10n.noDevicesFound),
            const SizedBox(height: 8),
            Text(
              'Tap the scan button to search for MeshCore companion radios',
              textAlign: TextAlign.center,
              style: TextStyle(color: emptyColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _discoveredDevices.length,
      itemBuilder: (context, index) {
        final device = _discoveredDevices[index];
        return ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(device.name.isNotEmpty ? device.name : 'Mesh device'),
          subtitle: Text(device.address),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _connectToDevice(bleManager, device),
        );
      },
    );
  }

  /// Connected view
  Widget _buildConnectedView(
      BleConnectionManager bleManager, ConnectionViewModel connectionVM) {
    final l10n = AppLocalizations.of(context)!;
    final channelRepository = context.watch<ChannelRepository>();

    return StreamBuilder<List<ChannelData>>(
      stream: channelRepository.getAllChannels(),
      builder: (context, snapshot) {
        final allChannels = snapshot.data ?? const <ChannelData>[];
        final privateChannels = allChannels.where((c) => !c.isPublic).toList();

        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildConnectedDeviceTile(bleManager, connectionVM),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Companion Settings',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: [
                  _buildSettingsCard(
                    title: l10n.deviceName,
                    subtitle: connectionVM.deviceName.isNotEmpty
                        ? connectionVM.deviceName
                        : 'Not set',
                    leading: Icons.edit,
                    onTap: () => _showDeviceNameDialog(connectionVM),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    title: l10n.radioSettings,
                    subtitle: _radioSettingsSubtitle(connectionVM),
                    leading: Icons.settings,
                    onTap: connectionVM.deviceCapabilities == null
                        ? null
                        : () => _showRadioSettingsDialog(
                              connectionVM,
                              privateChannels,
                            ),
                  ),
                  if (kDebugMode || isBetaBuild) ...[
                    const SizedBox(height: 8),
                    _buildSettingsCard(
                      title: l10n.forwardingDebug,
                      subtitle: l10n.inspectForwardingMode,
                      leading: Icons.bug_report,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForwardingDebugScreen(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                l10n.data,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.delete_sweep, color: Colors.red),
                      title: Text(
                        l10n.deleteAllContacts,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, color: Colors.red),
                      ),
                      onTap: () => _showDeleteAllContactsDialog(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.layers_clear, color: Colors.red),
                      title: Text(
                        l10n.deleteAllChannels,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, color: Colors.red),
                      ),
                      onTap: () => _showDeleteAllChannelsDialog(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteAllContactsDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllContacts),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAllContactsConfirm),
            const SizedBox(height: 12),
            Text(
              l10n.deleteAllContactsFavoritesNote,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repo = context.read<ContactRepository>();
    final count = await repo.purgeContactsOlderThan(0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contactsDeleted(count))),
      );
    }
  }

  Future<void> _showDeleteAllChannelsDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllChannels),
        content: Text(l10n.deleteAllChannelsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repo = context.read<ChannelRepository>();
    final count = await repo.deleteAllPrivateChannels();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.channelsDeleted(count))),
      );
    }
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData leading,
    required VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(leading),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _radioSettingsSubtitle(ConnectionViewModel connectionVM) {
    final caps = connectionVM.deviceCapabilities;
    if (caps == null) return 'Loading…';
    return '${caps.frequencyMHz.toStringAsFixed(3)} MHz • '
        'BW:${caps.bandwidthKHz.toStringAsFixed(1)} kHz • '
        'SF${caps.spreadingFactor} • '
        'CR4/${caps.codingRate} • '
        '${caps.txPower} dBm';
  }

  int? _tryParseChannelHash(String? hashHex) {
    if (hashHex == null) return null;

    final cleaned = hashHex.trim().toLowerCase().replaceFirst('0x', '');
    if (cleaned.isEmpty) return null;

    final isHex = RegExp(r'^[0-9a-f]+$').hasMatch(cleaned);
    if (!isHex) return null;

    try {
      return int.parse(cleaned, radix: 16);
    } catch (_) {
      return null;
    }
  }

  Future<void> _showDeviceNameDialog(ConnectionViewModel connectionVM) async {
    final controller = TextEditingController(text: connectionVM.deviceName);
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(l10n.deviceName),
              content: TextField(
                controller: controller,
                enabled: !isSaving,
                decoration: InputDecoration(
                  hintText: l10n.enterDeviceName,
                ),
                maxLength: 31,
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() {
                            isSaving = true;
                          });

                          final ok = await connectionVM
                              .confirmIdentityName(controller.text);

                          if (!context.mounted) return;
                          if (ok) {
                            Navigator.of(context).pop();
                          } else {
                            setState(() {
                              isSaving = false;
                            });
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(this.context)!.failedToSetDeviceName),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRadioSettingsDialog(ConnectionViewModel connectionVM,
      List<ChannelData> privateChannels) async {
    final caps = connectionVM.deviceCapabilities;
    if (caps == null) return;
    final settingsService = context.read<SettingsService>();

    final supportsForwarding = caps.supportsForwarding && caps.isCustomFirmware;
    final supportsAutonomous = caps.supportsAutonomous && caps.isCustomFirmware;

    final maxPower = caps.maxTxPower;

    final presets = _radioPresets(maxPower);
    final campPresets = _campRadioPresets(maxPower);
    bool campModeEnabled = settingsService.settings.campModeEnabled;
    bool smartForwardingEnabled =
        settingsService.settings.smartForwardingEnabled;
    final previousCampModeEnabled = campModeEnabled;
    final previousSmartForwardingEnabled = smartForwardingEnabled;

    if (!supportsForwarding) {
      smartForwardingEnabled = false;
    }

    bool autonomousEnabled = false;
    if (supportsAutonomous) {
      final current = await connectionVM.getAutonomousSettings();
      autonomousEnabled = current?.enabled ?? false;
    }
    final initialAutonomousEnabled = autonomousEnabled;

    String selectedPreset =
        campModeEnabled ? campPresets.first.name : presets.first.name;

    final frequencyController =
        TextEditingController(text: caps.frequencyMHz.toString());
    double bandwidthKHz = caps.bandwidthKHz;
    int spreadingFactor = caps.spreadingFactor;
    int codingRate = caps.codingRate;
    int txPower = caps.txPower;
    final dialogScrollController = ScrollController();

    bool isApplying = false;
    String? applyErrorMessage;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !isApplying,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              List<_RadioPreset> activePresets() {
                return campModeEnabled ? campPresets : presets;
              }

              _RadioPreset? findPresetByName(String presetName) {
                for (final preset in activePresets()) {
                  if (preset.name == presetName) return preset;
                }
                return null;
              }

              void applyPresetIfNeeded(String presetName) {
                final preset = findPresetByName(presetName);
                if (preset == null || preset.settings == null) return;

                frequencyController.text =
                    preset.settings!.frequencyMHz.toString();
                bandwidthKHz = preset.settings!.bandwidthKHz;
                spreadingFactor = preset.settings!.spreadingFactor;
                codingRate = preset.settings!.codingRate;
                txPower = preset.settings!.txPowerDbm;
              }

              String normalizedSelectedPreset() {
                final active = activePresets();
                if (active.isEmpty) return selectedPreset;
                final exists = active.any((p) => p.name == selectedPreset);
                if (!exists) {
                  selectedPreset = active.first.name;
                  applyPresetIfNeeded(selectedPreset);
                }
                return selectedPreset;
              }

              void enforceCampPresetSelection() {
                if (campPresets.isEmpty) return;
                selectedPreset = campPresets.first.name;
                applyPresetIfNeeded(selectedPreset);
              }

              final l10n = AppLocalizations.of(context)!;
              return AlertDialog(
                title: Text(l10n.radioSettings),
                content: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.72,
                  ),
                  child: Scrollbar(
                    controller: dialogScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: dialogScrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (applyErrorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(Icons.error_outline,
                                        color: Colors.red, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      applyErrorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.campMode),
                            subtitle: const Text(
                                'Locks radio to camp-compatible presets and enables firmware repeat mode'),
                            value: campModeEnabled,
                            onChanged: isApplying
                                ? null
                                : (value) {
                                    setState(() {
                                      campModeEnabled = value;
                                      if (campModeEnabled) {
                                        enforceCampPresetSelection();
                                      } else {
                                        selectedPreset = 'Custom';
                                      }
                                    });
                                  },
                          ),
                          if (campModeEnabled && supportsForwarding)
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.smartForwarding),
                              subtitle: const Text(
                                'Use app-managed smart forwarding while camp mode is active',
                              ),
                              value: smartForwardingEnabled,
                              onChanged: isApplying
                                  ? null
                                  : (value) {
                                      setState(() {
                                        smartForwardingEnabled = value;
                                      });
                                    },
                            ),
                          if (supportsAutonomous) ...[
                            const SizedBox(height: 8),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.autonomousMode),
                              subtitle: const Text(
                                'Configures firmware autonomous tracking. Uses values from Location Tracking settings.',
                              ),
                              value: autonomousEnabled,
                              onChanged: isApplying
                                  ? null
                                  : (value) {
                                      setState(() {
                                        autonomousEnabled = value;
                                      });
                                    },
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'To change interval/distance/channel, use Companion Settings → Location Tracking. This toggle does not enable app tracking.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                            if (autonomousEnabled &&
                                !connectionVM.hasCompanionGpsFix)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 16, color: Colors.orange),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'No GPS fix yet. Telemetry will not be sent until the companion radio acquires a valid GPS position.',
                                        style: TextStyle(color: Colors.orange),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          if (campModeEnabled) const SizedBox(height: 8),
                          const SizedBox(height: 8),
                          ThemedDropdown<String>(
                            value: normalizedSelectedPreset(),
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.presetConfiguration,
                            ),
                            items: [
                              for (final preset in activePresets())
                                DropdownMenuItem<String>(
                                  value: preset.name,
                                  child: Text(
                                    preset.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: isApplying
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    setState(() {
                                      selectedPreset = v;
                                      applyPresetIfNeeded(v);
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: frequencyController,
                            enabled: !isApplying && !campModeEnabled,
                            decoration: InputDecoration(
                              labelText: l10n.frequencyMhz,
                              helperText: '300-2500 MHz',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) {
                              if (campModeEnabled) return;
                              if (selectedPreset != 'Custom') {
                                setState(() => selectedPreset = 'Custom');
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          ThemedDropdown<double>(
                            value: bandwidthKHz,
                            decoration:
                                InputDecoration(labelText: l10n.bandwidth),
                            items: _bandwidthOptionsKHz
                                .map(
                                  (bw) => DropdownMenuItem<double>(
                                    value: bw,
                                    child: Text('${bw.toStringAsFixed(1)} kHz'),
                                  ),
                                )
                                .toList(),
                            onChanged: (isApplying || campModeEnabled)
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    setState(() {
                                      bandwidthKHz = v;
                                      selectedPreset = 'Custom';
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          ThemedDropdown<int>(
                            value: spreadingFactor,
                            decoration: InputDecoration(
                                labelText: l10n.spreadingFactor),
                            items: List.generate(
                              8,
                              (i) => DropdownMenuItem<int>(
                                value: 5 + i,
                                child: Text('SF${5 + i}'),
                              ),
                            ),
                            onChanged: (isApplying || campModeEnabled)
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    setState(() {
                                      spreadingFactor = v;
                                      selectedPreset = 'Custom';
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          ThemedDropdown<int>(
                            value: codingRate,
                            decoration:
                                InputDecoration(labelText: l10n.codingRate),
                            items: List.generate(
                              4,
                              (i) => DropdownMenuItem<int>(
                                value: 5 + i,
                                child: Text('CR4/${5 + i}'),
                              ),
                            ),
                            onChanged: (isApplying || campModeEnabled)
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    setState(() {
                                      codingRate = v;
                                      selectedPreset = 'Custom';
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                                'TX Power: ${txPower} dBm (max $maxPower)'),
                          ),
                          Slider(
                            value: txPower.toDouble(),
                            min: 1,
                            max: maxPower.toDouble().clamp(1, 30),
                            divisions: (maxPower.clamp(1, 30) - 1).clamp(1, 29),
                            onChanged: isApplying
                                ? null
                                : (v) {
                                    setState(() {
                                      txPower = v.round();
                                      if (!campModeEnabled) {
                                        selectedPreset = 'Custom';
                                      }
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        isApplying ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: isApplying
                        ? null
                        : () async {
                            final freq = double.tryParse(
                                frequencyController.text.trim());
                            if (freq == null) {
                              setState(() =>
                                  applyErrorMessage = 'Invalid frequency');
                              return;
                            }

                            final selected = findPresetByName(selectedPreset);
                            if (campModeEnabled && selected?.settings == null) {
                              setState(() =>
                                  applyErrorMessage = 'Select a camp preset');
                              return;
                            }

                            final applyFreq = campModeEnabled
                                ? selected!.settings!.frequencyMHz
                                : freq;
                            final applyBw = campModeEnabled
                                ? selected!.settings!.bandwidthKHz
                                : bandwidthKHz;
                            final applySf = campModeEnabled
                                ? selected!.settings!.spreadingFactor
                                : spreadingFactor;
                            final applyCr = campModeEnabled
                                ? selected!.settings!.codingRate
                                : codingRate;
                            final applyTx = txPower;

                            final enableClientRepeat = supportsForwarding &&
                                campModeEnabled &&
                                !smartForwardingEnabled;
                            final previousEnableClientRepeat =
                                supportsForwarding &&
                                    previousCampModeEnabled &&
                                    !previousSmartForwardingEnabled;

                            final radioUnchanged =
                                (applyFreq - caps.frequencyMHz).abs() <
                                        0.0001 &&
                                    (applyBw - caps.bandwidthKHz).abs() <
                                        0.0001 &&
                                    applySf == caps.spreadingFactor &&
                                    applyCr == caps.codingRate &&
                                    applyTx == caps.txPower;
                            final shouldPushRadioToFirmware = !radioUnchanged ||
                                campModeEnabled != previousCampModeEnabled ||
                                enableClientRepeat !=
                                    previousEnableClientRepeat;
                            final shouldPushAutonomousToFirmware =
                                supportsAutonomous &&
                                    (autonomousEnabled !=
                                            initialAutonomousEnabled ||
                                        autonomousEnabled);

                            await settingsService.setSmartForwardingEnabled(
                                smartForwardingEnabled);
                            await settingsService
                                .setCampModeEnabled(campModeEnabled);

                            if (!shouldPushRadioToFirmware &&
                                !shouldPushAutonomousToFirmware) {
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              return;
                            }

                            setState(() {
                              isApplying = true;
                              applyErrorMessage = null;
                            });

                            bool ok = true;

                            if (shouldPushRadioToFirmware) {
                              ok = await connectionVM.applyRadioSettings(
                                frequencyMHz: applyFreq,
                                bandwidthKHz: applyBw,
                                spreadingFactor: applySf,
                                codingRate: applyCr,
                                txPowerDbm: applyTx,
                                enableClientRepeat: enableClientRepeat,
                              );
                            }

                            if (ok && shouldPushAutonomousToFirmware) {
                              final s = settingsService.settings;
                              final parsedChannelHash =
                                  _tryParseChannelHash(s.telemetryChannelHash);
                              final fallbackHash = privateChannels.isNotEmpty
                                  ? privateChannels.first.hash
                                  : 0;
                              final targetDbHash =
                                  parsedChannelHash ?? fallbackHash;

                              // Firmware identifies channels by sha256(psk)[0].
                              // The app's DB hash is a polynomial rolling hash —
                              // its low byte does NOT match the firmware hash byte.
                              // Look up the channel PSK and compute the correct byte.
                              ChannelData? channelForAuto;
                              for (final c in privateChannels) {
                                if (c.hash == targetDbHash) {
                                  channelForAuto = c;
                                  break;
                                }
                              }
                              channelForAuto ??= privateChannels.isNotEmpty
                                  ? privateChannels.first
                                  : null;
                              final channelHashByte = channelForAuto != null
                                  ? sha256
                                      .convert(channelForAuto.sharedKey)
                                      .bytes[0]
                                  : targetDbHash & 0xFF;

                              final autonomousOk =
                                  await connectionVM.setAutonomousSettings(
                                enabled: autonomousEnabled,
                                channelHash: channelHashByte,
                                intervalSec:
                                    s.telemetryIntervalSeconds.clamp(10, 3600),
                                minDistanceMeters:
                                    s.telemetryMinDistanceMeters.clamp(0, 5000),
                              );

                              if (!autonomousOk) {
                                ok = false;
                              }
                            }

                            if (!context.mounted) return;
                            if (ok) {
                              Navigator.of(context).pop();
                            } else {
                              final autonomousErrorCode =
                                  connectionVM.lastAutonomousSettingsErrorCode;

                              String errorMessage;
                              if (supportsAutonomous &&
                                  autonomousErrorCode == 6) {
                                errorMessage =
                                    'Firmware rejected autonomous enable (ERR 6). This device does not have a GPS unit.';
                              } else if (supportsAutonomous &&
                                  autonomousErrorCode == -2) {
                                errorMessage =
                                    'Failed to verify autonomous settings after write. Check connection and retry.';
                              } else if (supportsAutonomous &&
                                  autonomousErrorCode == -3) {
                                errorMessage =
                                    'Autonomous settings did not stick after write. Please retry.';
                              } else {
                                errorMessage = supportsAutonomous
                                    ? 'Failed to apply settings. If enabling autonomous, ensure companion GPS is enabled and has a valid fix.'
                                    : 'Failed to apply radio settings.';
                              }

                              setState(() {
                                isApplying = false;
                                applyErrorMessage = errorMessage;
                              });
                              if (dialogScrollController.hasClients) {
                                unawaited(dialogScrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                ));
                              }
                            }
                          },
                    child: isApplying
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.apply),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      dialogScrollController.dispose();
    }
  }

  static const List<double> _bandwidthOptionsKHz = [
    7.8,
    10.4,
    15.6,
    20.8,
    31.25,
    41.7,
    62.5,
    125.0,
    250.0,
    500.0,
  ];

  List<_RadioPreset> _radioPresets(int maxPower) {
    int cap(int p) => p > maxPower ? maxPower : p;

    _RadioPreset p(String name, _RadioSettingsPreset? s) =>
        _RadioPreset(name, s);

    return [
      p('Custom', null),
      p('US/Canada 915 MHz', _RadioSettingsPreset(915.0, 125.0, 7, 5, cap(20))),
      p('US/Canada (Recommended)',
          _RadioSettingsPreset(910.525, 62.5, 7, 5, cap(20))),
      p('US/Canada Long Range',
          _RadioSettingsPreset(915.0, 125.0, 12, 8, cap(maxPower))),
      p('US/Canada Fast Speed',
          _RadioSettingsPreset(915.0, 500.0, 7, 5, cap(20))),
      p('Australia', _RadioSettingsPreset(915.800, 250.0, 10, 5, cap(20))),
      p('Australia: Victoria',
          _RadioSettingsPreset(946.575, 62.5, 7, 8, cap(20))),
      p('EU 868 MHz', _RadioSettingsPreset(868.0, 125.0, 7, 5, cap(14))),
      p('EU/UK (Narrow)', _RadioSettingsPreset(869.618, 62.5, 8, 8, cap(14))),
      p('EU/UK (Long Range)',
          _RadioSettingsPreset(869.525, 250.0, 11, 5, cap(14))),
      p('EU/UK (Medium Range)',
          _RadioSettingsPreset(869.525, 250.0, 10, 5, cap(14))),
      p('Czech Republic', _RadioSettingsPreset(869.432, 62.5, 7, 5, cap(14))),
      p('Asia 433 MHz', _RadioSettingsPreset(433.0, 125.0, 7, 5, cap(20))),
      p('EU 433 MHz (Long Range)',
          _RadioSettingsPreset(433.650, 250.0, 11, 5, cap(20))),
      p('New Zealand', _RadioSettingsPreset(917.375, 250.0, 10, 5, cap(20))),
      p('New Zealand (Narrow)',
          _RadioSettingsPreset(922.0, 62.5, 8, 8, cap(20))),
      p('Portugal 433 MHz', _RadioSettingsPreset(433.375, 62.5, 9, 6, cap(10))),
      p('Portugal 868 MHz', _RadioSettingsPreset(869.618, 62.5, 7, 6, cap(27))),
      p('Switzerland', _RadioSettingsPreset(869.525, 250.0, 10, 5, cap(14))),
      p('Vietnam', _RadioSettingsPreset(433.0, 250.0, 10, 5, cap(20))),
    ];
  }

  List<_RadioPreset> _campRadioPresets(int maxPower) {
    int cap(int p) => p > maxPower ? maxPower : p;

    _RadioPreset p(String name, _RadioSettingsPreset s) =>
        _RadioPreset(name, s, isCampPreset: true);

    return [
      p('Camp US/Canada (918 MHz)',
          _RadioSettingsPreset(918.0, 62.5, 7, 8, cap(20))),
      p('Camp EU/UK (869 MHz)',
          _RadioSettingsPreset(869.0, 62.5, 7, 8, cap(14))),
      p('Camp 433 Region (433 MHz)',
          _RadioSettingsPreset(433.0, 62.5, 7, 8, cap(20))),
    ];
  }

  Widget _buildConnectedDeviceTile(
      BleConnectionManager bleManager, ConnectionViewModel connectionVM) {
    final l10n = AppLocalizations.of(context)!;
    final address = bleManager.deviceAddress ?? '';
    final caps = connectionVM.deviceCapabilities;
    final voltage = connectionVM.companionBatteryVoltage;
    final isAutonomous = connectionVM.currentAutonomousEnabled == true;

    final firmwareType = (caps?.isCustomFirmware == true) ? l10n.firmwareCustom : l10n.firmwareStock;
    final forwarding = (caps?.supportsForwarding == true) ? 'FWD ✓' : 'FWD ✗';
    final autonomous = (caps?.supportsAutonomous == true) ? 'AUTO ✓' : 'AUTO ✗';

    final subtitleParts = <String>[
      if (address.isNotEmpty) l10n.deviceId(address),
      l10n.firmwareInfo(firmwareType, forwarding, autonomous),
      if (voltage != null) l10n.batteryVoltage(voltage.toStringAsFixed(2)),
    ];

    return Card(
      color: isAutonomous ? Colors.orange.withAlpha(38) : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.bluetooth_connected, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connectionVM.deviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  for (final line in subtitleParts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (isAutonomous)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.gps_fixed,
                              size: 12, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            l10n.autonomousMode,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Tooltip(
                  message: 'Send Advert',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      debugPrint('📡 Send Advert button pressed');
                      try {
                        final command = BleCommands.buildSendSelfAdvert();
                        final success = await bleManager.sendFrame(command);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.advertSentSuccessfully),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          debugPrint('✅ Advert sent successfully');
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.failedToSendAdvert),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          debugPrint('❌ Failed to send advert');
                        }
                      } catch (e) {
                        debugPrint('❌ Send advert error: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.genericError(e.toString())),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        children: [
                          const Icon(Icons.wifi_tethering),
                          const SizedBox(height: 2),
                          Text(
                            l10n.advert,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: l10n.disconnectDevice,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      debugPrint('🔴 Disconnect button pressed');
                      try {
                        await connectionVM.manualDisconnect();
                        debugPrint('✅ Disconnect completed');
                      } catch (e) {
                        debugPrint('❌ Disconnect error: $e');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        children: [
                          const Icon(Icons.power_off),
                          const SizedBox(height: 2),
                          Text(
                            l10n.disconnect,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// Start scanning
  void _startScan() async {
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });

    final bleManager = _bleManager ?? context.read<BleConnectionManager>();

    await for (final device in bleManager.startScan()) {
      if (mounted) {
        setState(() {
          if (!_discoveredDevices.any(
              (d) => d.address.toUpperCase() == device.address.toUpperCase())) {
            _discoveredDevices.add(device);
          }
        });
      }
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  /// Stop scanning
  void _stopScan() async {
    final bleManager = _bleManager;
    if (bleManager == null) return;
    await bleManager.stopScan();

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  /// Connect to device
  void _connectToDevice(
      BleConnectionManager bleManager, MeshBleDevice device) async {
    setState(() {
      _isScanning = false;
    });

    final success = await bleManager.connect(device);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Connected to ${device.name.isNotEmpty ? device.name : device.address}'),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to connect to ${device.name.isNotEmpty ? device.name : device.address}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Avoid Provider lookups during dispose.
    _hideSyncTimer?.cancel();
    _bleManager?.stopScan();
    super.dispose();
  }
}

class _RadioPreset {
  final String name;
  final _RadioSettingsPreset? settings;
  final bool isCampPreset;

  const _RadioPreset(this.name, this.settings, {this.isCampPreset = false});
}

class _RadioSettingsPreset {
  final double frequencyMHz;
  final double bandwidthKHz;
  final int spreadingFactor;
  final int codingRate;
  final int txPowerDbm;

  const _RadioSettingsPreset(
    this.frequencyMHz,
    this.bandwidthKHz,
    this.spreadingFactor,
    this.codingRate,
    this.txPowerDbm,
  );
}
