// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/ble/ble_commands.dart';
import 'package:meshcore_team/ble/ble_connection_manager.dart';
import 'package:meshcore_team/ble/mesh_ble_device.dart';
import 'package:meshcore_team/models/sync_status.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import 'package:meshcore_team/screens/forwarding_debug_screen.dart';
import 'package:meshcore_team/screens/debug_log_screen.dart';
import 'package:meshcore_team/screens/team_config_screen.dart';
import 'package:permission_handler/permission_handler.dart';

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
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bleManager ??= context.read<BleConnectionManager>();
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
    final bleManager = context.watch<BleConnectionManager>();
    final connectionVM = context.watch<ConnectionViewModel>();

    _updateSyncProgressVisibility(
      isConnected: bleManager.isConnected,
      isSyncComplete: connectionVM.syncStatus.isComplete,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('MeshCore TEAM'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.article_outlined),
              tooltip: 'Debug Logs',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DebugLogScreen(),
                ),
              ),
            ),
          if (bleManager.isConnected)
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings),
              tooltip: 'Team Config',
              onSelected: (value) {
                final mode = value == 'export'
                    ? TeamConfigMode.export
                    : TeamConfigMode.import;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TeamConfigScreen(mode: mode),
                  ),
                );
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.file_download),
                    title: Text('Create Team Config'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'import',
                  child: ListTile(
                    leading: Icon(Icons.file_upload),
                    title: Text('Import Team Config'),
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

  /// Connection status indicator
  Widget _buildConnectionStatusIndicator(BleConnectionManager bleManager) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (bleManager.state) {
      case BleConnectionState.connected:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Connected';
        break;
      case BleConnectionState.connecting:
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        statusText = 'Connecting';
        break;
      case BleConnectionState.scanning:
        statusColor = Colors.blue;
        statusIcon = Icons.search;
        statusText = 'Scanning';
        break;
      case BleConnectionState.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Error';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.bluetooth_disabled;
        statusText = 'Disconnected';
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
    final syncStatus = connectionVM.syncStatus;
    final phaseText = _getSyncPhaseText(syncStatus.phase);
    final progress = syncStatus.progressPercentage;

    const primaryTextColor = Colors.black87;
    const secondaryTextColor = Colors.black54;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.blue.shade50,
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
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
              style: const TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get sync phase display text
  String _getSyncPhaseText(SyncPhase phase) {
    switch (phase) {
      case SyncPhase.idle:
        return 'Idle';
      case SyncPhase.syncingContacts:
        return 'Syncing Contacts...';
      case SyncPhase.syncingChannels:
        return 'Syncing Channels...';
      case SyncPhase.syncingMessages:
        return 'Syncing Messages...';
      case SyncPhase.complete:
        return 'Sync Complete';
    }
  }

  /// Scanner view (when not connected)
  Widget _buildScannerView(BleConnectionManager bleManager) {
    if (_isScanning && _discoveredDevices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning for MeshCore devices...'),
          ],
        ),
      );
    }

    if (_discoveredDevices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No devices found'),
            SizedBox(height: 8),
            Text(
              'Tap the scan button to search for MeshCore companion radios',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
    final settingsService = context.watch<SettingsService>();
    final channelRepository = context.watch<ChannelRepository>();

    return StreamBuilder<List<ChannelData>>(
      stream: channelRepository.getAllChannels(),
      builder: (context, snapshot) {
        final allChannels = snapshot.data ?? const <ChannelData>[];
        final privateChannels = allChannels.where((c) => !c.isPublic).toList();

        final telemetryChannelHash =
            settingsService.settings.telemetryChannelHash?.toLowerCase();
        final telemetryChannelName = telemetryChannelHash == null
            ? null
            : _findChannelNameByHashHex(privateChannels, telemetryChannelHash);

        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildConnectedDeviceTile(bleManager, connectionVM),
            ),
            const Divider(height: 1),
            if (Platform.isIOS) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'App Settings',
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
                      title: 'Always On Location',
                      subtitle: settingsService
                              .settings.backgroundLocationEnabled
                          ? 'Enabled — location updates continue in background'
                          : 'Disabled',
                      leading:
                          settingsService.settings.backgroundLocationEnabled
                              ? Icons.my_location
                              : Icons.location_disabled,
                      onTap: () =>
                          _showBackgroundLocationDialog(settingsService),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
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
                    title: 'Device Name',
                    subtitle: connectionVM.deviceName.isNotEmpty
                        ? connectionVM.deviceName
                        : 'Not set',
                    leading: Icons.edit,
                    onTap: () => _showDeviceNameDialog(connectionVM),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    title: 'Location Source',
                    subtitle: _locationSourceLabel(
                        settingsService.settings.locationSource),
                    leading: Icons.location_on,
                    onTap: () => _showLocationSourceDialog(settingsService),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    title: 'Location Tracking',
                    subtitle: settingsService.settings.telemetryEnabled
                        ? (telemetryChannelName != null
                            ? 'Enabled on: $telemetryChannelName'
                            : 'Enabled (no channel)')
                        : 'Disabled',
                    leading: settingsService.settings.telemetryEnabled
                        ? Icons.check_circle
                        : Icons.location_off,
                    onTap: () => _showTelemetryDialog(
                      settingsService: settingsService,
                      privateChannels: privateChannels,
                      connectionVM: connectionVM,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    title: 'Radio Settings',
                    subtitle: _radioSettingsSubtitle(connectionVM),
                    leading: Icons.settings,
                    onTap: connectionVM.deviceCapabilities == null
                        ? null
                        : () => _showRadioSettingsDialog(
                              connectionVM,
                              privateChannels,
                            ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 8),
                    _buildSettingsCard(
                      title: 'Forwarding Debug',
                      subtitle: 'Inspect active forwarding mode and topology',
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
            )
          ],
        );
      },
    );
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

  String _locationSourceLabel(String source) {
    switch (source) {
      case LocationSource.phone:
        return 'Phone GPS';
      case LocationSource.companion:
        return 'Companion Radio GPS';
      default:
        return 'Not set';
    }
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

  String? _findChannelNameByHashHex(
      List<ChannelData> channels, String hashHexLower) {
    for (final channel in channels) {
      final hex = channel.hash.toRadixString(16).toLowerCase();
      if (hex == hashHexLower) return channel.name;
    }
    return null;
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
            return AlertDialog(
              title: const Text('Device Name'),
              content: TextField(
                controller: controller,
                enabled: !isSaving,
                decoration: const InputDecoration(
                  hintText: 'Enter device name',
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
                  child: const Text('Cancel'),
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
                              const SnackBar(
                                content: Text('Failed to set device name'),
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
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showBackgroundLocationDialog(
      SettingsService settingsService) async {
    if (settingsService.settings.backgroundLocationEnabled) {
      // Already enabled — offer to disable
      await settingsService.setBackgroundLocationEnabled(false);
      return;
    }

    final shouldEnable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Location'),
        content: const Text(
          'MeshCore TEAM needs background location access to continue '
          'sharing your position with the mesh network when the app is '
          'minimized.\n\n'
          'This allows location tracking and BLE communication to '
          'continue working in the background.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (shouldEnable != true || !mounted) return;

    var status = await Permission.locationAlways.request();

    // iOS processes the "Always" upgrade asynchronously — the request()
    // may return before the change is applied. Poll briefly to catch it.
    if (!status.isGranted) {
      for (var i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        status = await Permission.locationAlways.status;
        if (status.isGranted) break;
      }
    }

    if (status.isGranted) {
      await settingsService.setBackgroundLocationEnabled(true);
    } else if (status.isPermanentlyDenied) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Background location was denied. Please enable "Always" '
            'location access in your device Settings for MeshCore TEAM.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showLocationSourceDialog(
      SettingsService settingsService) async {
    String selected = settingsService.settings.locationSource;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Location Source'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Phone GPS'),
                    value: LocationSource.phone,
                    groupValue: selected,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => selected = v);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Companion Radio GPS'),
                    value: LocationSource.companion,
                    groupValue: selected,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => selected = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await settingsService.setLocationSource(selected);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showTelemetryDialog({
    required SettingsService settingsService,
    required List<ChannelData> privateChannels,
    required ConnectionViewModel connectionVM,
  }) async {
    bool enabled = settingsService.settings.telemetryEnabled;
    String? selectedChannelHash = settingsService.settings.telemetryChannelHash;
    int intervalSeconds =
        ((settingsService.settings.telemetryIntervalSeconds / 10).round() * 10)
            .clamp(30, 180);
    int minDistanceMeters =
        ((settingsService.settings.telemetryMinDistanceMeters / 10).round() *
                10)
            .clamp(50, 500);
    bool isSaving = false;

    // Validate saved hash still exists in current channel list.
    final validHashes = privateChannels
        .map((c) => c.hash.toRadixString(16).toLowerCase())
        .toSet();
    if (selectedChannelHash != null &&
        !validHashes.contains(selectedChannelHash)) {
      selectedChannelHash = null;
    }

    // TEAM-like behavior: if no channel selected, pick the first available private channel.
    if (selectedChannelHash == null && privateChannels.isNotEmpty) {
      selectedChannelHash =
          privateChannels.first.hash.toRadixString(16).toLowerCase();
    }

    // Reset to null if the stored hash doesn't match any available private channel,
    // otherwise the DropdownButtonFormField will fail an assertion.
    if (selectedChannelHash != null &&
        !privateChannels.any((c) =>
            c.hash.toRadixString(16).toLowerCase() ==
            selectedChannelHash!.toLowerCase())) {
      selectedChannelHash = null;
    }

    String? channelNameForHash(String? hashHex) {
      if (hashHex == null) return null;
      return _findChannelNameByHashHex(privateChannels, hashHex.toLowerCase());
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Location Tracking'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable tracking'),
                      value: enabled,
                      onChanged: isSaving
                          ? null
                          : (v) {
                              setState(() {
                                enabled = v;
                                if (enabled &&
                                    selectedChannelHash == null &&
                                    privateChannels.isNotEmpty) {
                                  selectedChannelHash = privateChannels
                                      .first.hash
                                      .toRadixString(16)
                                      .toLowerCase();
                                }
                              });
                            },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedChannelHash,
                      decoration: const InputDecoration(
                        labelText: 'Channel',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None'),
                        ),
                        for (final c in privateChannels)
                          DropdownMenuItem<String>(
                            value: c.hash.toRadixString(16).toLowerCase(),
                            child: Text(c.name),
                          ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (v) {
                              setState(() => selectedChannelHash = v);
                            },
                    ),
                    const SizedBox(height: 12),
                    Text('Interval: ${intervalSeconds}s'),
                    Slider(
                      value: intervalSeconds.toDouble(),
                      min: 30,
                      max: 180,
                      divisions: 15,
                      onChanged: isSaving
                          ? null
                          : (v) {
                              setState(() =>
                                  intervalSeconds = (v / 10).round() * 10);
                            },
                    ),
                    const SizedBox(height: 8),
                    Text('Minimum distance: ${minDistanceMeters}m'),
                    Slider(
                      value: minDistanceMeters.toDouble(),
                      min: 50,
                      max: 500,
                      divisions: 45,
                      onChanged: isSaving
                          ? null
                          : (v) {
                              setState(() =>
                                  minDistanceMeters = (v / 10).round() * 10);
                            },
                    ),
                    if (enabled && selectedChannelHash == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Select a channel to enable tracking.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (enabled && selectedChannelHash != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Enabled on: ${channelNameForHash(selectedChannelHash) ?? selectedChannelHash}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (enabled && selectedChannelHash == null) {
                            return;
                          }

                          setState(() => isSaving = true);

                          await settingsService.setTelemetryEnabled(enabled);
                          await settingsService
                              .setTelemetryChannelHash(selectedChannelHash);
                          await settingsService.setTelemetryChannelName(
                            channelNameForHash(selectedChannelHash),
                          );
                          await settingsService
                              .setTelemetryIntervalSeconds(intervalSeconds);
                          await settingsService
                              .setTelemetryMinDistanceMeters(minDistanceMeters);

                          // If the companion is currently in autonomous mode,
                          // push the updated tracking settings to the firmware now
                          // so the user doesn't have to toggle autonomous off/on.
                          final caps = connectionVM.deviceCapabilities;
                          final supportsAutonomous = caps != null &&
                              caps.supportsAutonomous &&
                              caps.isCustomFirmware;
                          if (supportsAutonomous &&
                              connectionVM.currentAutonomousEnabled == true) {
                            ChannelData? channelForAuto;
                            if (selectedChannelHash != null) {
                              for (final c in privateChannels) {
                                if (c.hash.toRadixString(16).toLowerCase() ==
                                    selectedChannelHash!.toLowerCase()) {
                                  channelForAuto = c;
                                  break;
                                }
                              }
                            }
                            channelForAuto ??= privateChannels.isNotEmpty
                                ? privateChannels.first
                                : null;
                            final channelHashByte = channelForAuto != null
                                ? sha256
                                    .convert(channelForAuto.sharedKey)
                                    .bytes[0]
                                : 0;
                            await connectionVM.setAutonomousSettings(
                              enabled: true,
                              channelHash: channelHashByte,
                              intervalSec: intervalSeconds.clamp(10, 3600),
                              minDistanceMeters:
                                  minDistanceMeters.clamp(0, 5000),
                            );
                          }

                          if (context.mounted) Navigator.of(context).pop();
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
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

    String selectedPreset = presets.first.name; // Custom

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

              return AlertDialog(
                title: const Text('Radio Settings'),
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
                            title: const Text('Camp Mode'),
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
                              title: const Text('Smart Forwarding'),
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
                              title: const Text('Autonomous Mode'),
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
                          DropdownButtonFormField<String>(
                            value: normalizedSelectedPreset(),
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Preset Configuration',
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
                            decoration: const InputDecoration(
                              labelText: 'Frequency (MHz)',
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
                          DropdownButtonFormField<double>(
                            value: bandwidthKHz,
                            decoration:
                                const InputDecoration(labelText: 'Bandwidth'),
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
                          DropdownButtonFormField<int>(
                            value: spreadingFactor,
                            decoration: const InputDecoration(
                                labelText: 'Spreading Factor'),
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
                          DropdownButtonFormField<int>(
                            value: codingRate,
                            decoration:
                                const InputDecoration(labelText: 'Coding Rate'),
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
                            onChanged: (isApplying || campModeEnabled)
                                ? null
                                : (v) {
                                    setState(() {
                                      txPower = v.round();
                                      selectedPreset = 'Custom';
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
                    child: const Text('Cancel'),
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
                            final applyTx = campModeEnabled
                                ? selected!.settings!.txPowerDbm
                                : txPower;

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
                        : const Text('Apply'),
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
    final address = bleManager.deviceAddress ?? '';
    final caps = connectionVM.deviceCapabilities;
    final voltage = connectionVM.companionBatteryVoltage;
    final isAutonomous = connectionVM.currentAutonomousEnabled == true;

    final firmwareType = (caps?.isCustomFirmware == true) ? 'Custom' : 'Stock';
    final forwarding = (caps?.supportsForwarding == true) ? 'FWD ✓' : 'FWD ✗';
    final autonomous = (caps?.supportsAutonomous == true) ? 'AUTO ✓' : 'AUTO ✗';

    final subtitleParts = <String>[
      if (address.isNotEmpty) 'ID: $address',
      'FW: $firmwareType • $forwarding • $autonomous',
      if (voltage != null) 'Battery: ${voltage.toStringAsFixed(2)}V',
    ];

    return Card(
      color: isAutonomous ? Colors.orange.withAlpha(38) : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.bluetooth_connected, color: Colors.green),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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
                            'Autonomous mode active',
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
                            const SnackBar(
                              content: Text('Advert sent successfully'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          debugPrint('✅ Advert sent successfully');
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to send advert'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          debugPrint('❌ Failed to send advert');
                        }
                      } catch (e) {
                        debugPrint('❌ Send advert error: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        children: [
                          Icon(Icons.wifi_tethering),
                          SizedBox(height: 2),
                          Text(
                            'Advert',
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Disconnect device',
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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        children: [
                          Icon(Icons.power_off),
                          SizedBox(height: 2),
                          Text(
                            'Disconnect',
                            style: TextStyle(fontSize: 11),
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
