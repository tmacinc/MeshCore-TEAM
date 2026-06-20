// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import 'package:meshcore_team/widgets/night_clock.dart';
import 'package:meshcore_team/widgets/themed_dropdown.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Settings'),
        actions: [
          if (settings.settings.appTheme == AppThemeMode.nighttime)
            const NightClock(),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Location',
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
                  title: 'Location Source',
                  subtitle: _locationSourceLabel(settings.settings.locationSource),
                  leading: Icons.location_on,
                  onTap: () => _showLocationSourceDialog(settings),
                ),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  title: 'Location Tracking',
                  subtitle: settings.settings.telemetryEnabled
                      ? (settings.settings.telemetryChannelName != null
                          ? 'Enabled on: ${settings.settings.telemetryChannelName}'
                          : 'Enabled (no channel)')
                      : 'Disabled',
                  leading: settings.settings.telemetryEnabled
                      ? Icons.check_circle
                      : Icons.location_off,
                  onTap: () => _showTelemetryDialog(settings),
                ),
                if (Platform.isIOS) ...[
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    title: 'Always On Location',
                    subtitle: settings.settings.backgroundLocationEnabled
                        ? 'Enabled — location updates continue in background'
                        : 'Disabled',
                    leading: settings.settings.backgroundLocationEnabled
                        ? Icons.my_location
                        : Icons.location_disabled,
                    onTap: () => _showBackgroundLocationDialog(settings),
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
              'Appearance',
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
                  title: 'Theme',
                  subtitle: _themeLabel(settings.settings.appTheme),
                  leading: _themeIcon(settings.settings.appTheme),
                  onTap: () => _showThemeDialog(settings),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
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

  String? _findChannelNameByHashHex(List<ChannelData> channels, String hashHexLower) {
    for (final channel in channels) {
      if (channel.hash.toRadixString(16).toLowerCase() == hashHexLower) {
        return channel.name;
      }
    }
    return null;
  }

  Future<void> _showLocationSourceDialog(SettingsService settingsService) async {
    String selected = settingsService.settings.locationSource;
    final connectionVM = context.read<ConnectionViewModel>();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Location Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Phone GPS'),
                value: LocationSource.phone,
                groupValue: selected,
                onChanged: (v) { if (v != null) setState(() => selected = v); },
              ),
              RadioListTile<String>(
                title: const Text('Companion Radio GPS'),
                value: LocationSource.companion,
                groupValue: selected,
                onChanged: (v) { if (v != null) setState(() => selected = v); },
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
                if (!context.mounted) return;
                if (connectionVM.isConnected) {
                  final autonomousEnabled = connectionVM.currentAutonomousEnabled ?? false;
                  final needsGps = selected == LocationSource.companion || autonomousEnabled;
                  final ok = await connectionVM.setGpsEnabled(needsGps);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Could not configure companion GPS — no GPS hardware?'),
                      duration: Duration(seconds: 3),
                    ));
                  }
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTelemetryDialog(SettingsService settingsService) async {
    final channelRepository = context.read<ChannelRepository>();
    final connectionVM = context.read<ConnectionViewModel>();

    final allChannels = await channelRepository.getAllChannels().first;
    if (!mounted) return;
    final privateChannels = allChannels.where((c) => !c.isPublic).toList();

    bool enabled = settingsService.settings.telemetryEnabled;
    String? selectedChannelHash = settingsService.settings.telemetryChannelHash;
    int intervalSeconds =
        ((settingsService.settings.telemetryIntervalSeconds / 10).round() * 10).clamp(30, 180);
    int minDistanceMeters =
        ((settingsService.settings.telemetryMinDistanceMeters / 10).round() * 10).clamp(50, 500);
    bool isSaving = false;

    final validHashes = privateChannels.map((c) => c.hash.toRadixString(16).toLowerCase()).toSet();
    if (selectedChannelHash != null && !validHashes.contains(selectedChannelHash)) {
      selectedChannelHash = null;
    }
    if (selectedChannelHash == null && privateChannels.isNotEmpty) {
      selectedChannelHash = privateChannels.first.hash.toRadixString(16).toLowerCase();
    }
    if (selectedChannelHash != null &&
        !privateChannels.any((c) =>
            c.hash.toRadixString(16).toLowerCase() == selectedChannelHash!.toLowerCase())) {
      selectedChannelHash = null;
    }

    String? channelNameForHash(String? hashHex) {
      if (hashHex == null) return null;
      return _findChannelNameByHashHex(privateChannels, hashHex.toLowerCase());
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                            if (enabled && selectedChannelHash == null && privateChannels.isNotEmpty) {
                              selectedChannelHash =
                                  privateChannels.first.hash.toRadixString(16).toLowerCase();
                            }
                          });
                        },
                ),
                const SizedBox(height: 8),
                if (privateChannels.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Connect to a companion to select a channel.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  )
                else
                  ThemedDropdown<String>(
                    value: selectedChannelHash,
                    decoration: const InputDecoration(labelText: 'Channel'),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('None')),
                      for (final c in privateChannels)
                        DropdownMenuItem<String>(
                          value: c.hash.toRadixString(16).toLowerCase(),
                          child: Text(c.name),
                        ),
                    ],
                    onChanged: isSaving ? null : (v) => setState(() => selectedChannelHash = v),
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
                      : (v) => setState(() => intervalSeconds = (v / 10).round() * 10),
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
                      : (v) => setState(() => minDistanceMeters = (v / 10).round() * 10),
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
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (enabled && selectedChannelHash == null) return;
                      setState(() => isSaving = true);

                      await settingsService.setTelemetryEnabled(enabled);
                      await settingsService.setTelemetryChannelHash(selectedChannelHash);
                      await settingsService.setTelemetryChannelName(
                          channelNameForHash(selectedChannelHash));
                      await settingsService.setTelemetryIntervalSeconds(intervalSeconds);
                      await settingsService.setTelemetryMinDistanceMeters(minDistanceMeters);

                      final caps = connectionVM.deviceCapabilities;
                      final supportsAutonomous =
                          caps != null && caps.supportsAutonomous && caps.isCustomFirmware;
                      if (supportsAutonomous && connectionVM.currentAutonomousEnabled == true) {
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
                        channelForAuto ??= privateChannels.isNotEmpty ? privateChannels.first : null;
                        final channelHashByte = channelForAuto != null
                            ? sha256.convert(channelForAuto.sharedKey).bytes[0]
                            : 0;
                        await connectionVM.setAutonomousSettings(
                          enabled: true,
                          channelHash: channelHashByte,
                          intervalSec: intervalSeconds.clamp(10, 3600),
                          minDistanceMeters: minDistanceMeters.clamp(0, 5000),
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
        ),
      ),
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

  String _themeLabel(String theme) {
    switch (theme) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.nighttime:
        return 'Red Light Discipline';
      default:
        return 'System default';
    }
  }

  IconData _themeIcon(String theme) {
    switch (theme) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.nighttime:
        return Icons.nightlight_round;
      default:
        return Icons.brightness_auto;
    }
  }

  Future<void> _showThemeDialog(SettingsService settings) async {
    final current = settings.settings.appTheme;
    await showDialog<void>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          _themeOption(context, settings, AppThemeMode.system, 'System default',
              Icons.brightness_auto, current),
          _themeOption(context, settings, AppThemeMode.light, 'Light',
              Icons.light_mode, current),
          _themeOption(context, settings, AppThemeMode.dark, 'Dark',
              Icons.dark_mode, current),
          _themeOption(context, settings, AppThemeMode.nighttime,
              'Red Light Discipline', Icons.nightlight_round, current),
        ],
      ),
    );
  }

  Widget _themeOption(
    BuildContext context,
    SettingsService settings,
    String value,
    String label,
    IconData icon,
    String current,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        settings.setAppTheme(value);
        Navigator.of(context).pop();
      },
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (current == value) const Icon(Icons.check, size: 18),
        ],
      ),
    );
  }

  Future<void> _showBackgroundLocationDialog(
      SettingsService settingsService) async {
    if (settingsService.settings.backgroundLocationEnabled) {
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
}
