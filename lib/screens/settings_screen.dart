// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import 'package:meshcore_team/widgets/night_clock.dart';

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
        actions: const [],
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
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text('Location Source',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      RadioListTile<String>(
                        title: const Text('Phone GPS'),
                        value: LocationSource.phone,
                        groupValue: settings.settings.locationSource,
                        onChanged: (v) => _setLocationSource(settings, v!),
                      ),
                      RadioListTile<String>(
                        title: const Text('Companion GPS'),
                        subtitle: const Text('Phone fallback'),
                        value: LocationSource.companion,
                        groupValue: settings.settings.locationSource,
                        onChanged: (v) => _setLocationSource(settings, v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildLocationTrackingCard(settings),
                if (Platform.isIOS) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      onTap: () => _showBackgroundLocationDialog(settings),
                      leading: Icon(settings.settings.backgroundLocationEnabled
                          ? Icons.my_location
                          : Icons.location_disabled),
                      title: const Text('Always On Location',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(settings.settings.backgroundLocationEnabled
                          ? 'Enabled — location updates continue in background'
                          : 'Disabled'),
                      trailing: const Icon(Icons.chevron_right),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Theme'),
                      value: settings.settings.appTheme,
                      items: const [
                        DropdownMenuItem(
                          value: AppThemeMode.system,
                          child: Row(children: [
                            Icon(Icons.brightness_auto, size: 18),
                            SizedBox(width: 8),
                            Text('System default'),
                          ]),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.light,
                          child: Row(children: [
                            Icon(Icons.light_mode, size: 18),
                            SizedBox(width: 8),
                            Text('Light'),
                          ]),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.dark,
                          child: Row(children: [
                            Icon(Icons.dark_mode, size: 18),
                            SizedBox(width: 8),
                            Text('Dark'),
                          ]),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.nighttime,
                          child: Row(children: [
                            Icon(Icons.nightlight_round, size: 18),
                            SizedBox(width: 8),
                            Text('Red Light Discipline'),
                          ]),
                        ),
                      ],
                      onChanged: (v) => settings.setAppTheme(v!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setLocationSource(SettingsService settingsService, String source) async {
    await settingsService.setLocationSource(source);
    final connectionVM = context.read<ConnectionViewModel>();
    if (!connectionVM.isConnected) return;
    final autonomousEnabled = connectionVM.currentAutonomousEnabled ?? false;
    final needsGps = source == LocationSource.companion || autonomousEnabled;
    final ok = await connectionVM.setGpsEnabled(needsGps);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not configure companion GPS — no GPS hardware?'),
        duration: Duration(seconds: 3),
      ));
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

  Widget _buildLocationTrackingCard(SettingsService settings) {
    final isConnected = context.select<ConnectionViewModel, bool>((vm) => vm.isConnected);
    final s = settings.settings;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Location Tracking',
                style: TextStyle(fontWeight: FontWeight.w500)),
            value: s.telemetryEnabled,
            onChanged: (v) => settings.setTelemetryEnabled(v),
          ),
          // Channel selection
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: isConnected
                ? StreamBuilder<List<ChannelData>>(
                    stream: context.read<ChannelRepository>().getAllChannels(),
                    builder: (context, snapshot) {
                      final privateChannels = (snapshot.data ?? [])
                          .where((c) => !c.isPublic)
                          .toList();

                      String? currentHash = s.telemetryChannelHash;
                      final validHashes = privateChannels
                          .map((c) => c.hash.toRadixString(16).toLowerCase())
                          .toSet();
                      if (currentHash != null && !validHashes.contains(currentHash)) {
                        currentHash = null;
                      }

                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Channel'),
                        value: currentHash,
                        items: [
                          const DropdownMenuItem<String>(
                              value: null, child: Text('None')),
                          for (final c in privateChannels)
                            DropdownMenuItem<String>(
                              value: c.hash.toRadixString(16).toLowerCase(),
                              child: Text(c.name),
                            ),
                        ],
                        onChanged: (v) async {
                          await settings.setTelemetryChannelHash(v);
                          final name = v == null
                              ? null
                              : _findChannelNameByHashHex(
                                  privateChannels, v.toLowerCase());
                          await settings.setTelemetryChannelName(name);
                        },
                      );
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.telemetryChannelName != null
                            ? 'Will share on: ${s.telemetryChannelName}'
                            : 'No channel selected',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect to a device to select a channel.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
          ),
          _TelemetrySliders(settings: settings),
          const SizedBox(height: 8),
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

class _TelemetrySliders extends StatefulWidget {
  final SettingsService settings;
  const _TelemetrySliders({required this.settings});

  @override
  State<_TelemetrySliders> createState() => _TelemetrySlidersState();
}

class _TelemetrySlidersState extends State<_TelemetrySliders> {
  late double _interval;
  late double _distance;

  @override
  void initState() {
    super.initState();
    _interval = widget.settings.settings.telemetryIntervalSeconds.toDouble().clamp(30, 180);
    _distance = widget.settings.settings.telemetryMinDistanceMeters.toDouble().clamp(50, 500);
  }

  @override
  void didUpdateWidget(_TelemetrySliders old) {
    super.didUpdateWidget(old);
    _interval = widget.settings.settings.telemetryIntervalSeconds.toDouble().clamp(30, 180);
    _distance = widget.settings.settings.telemetryMinDistanceMeters.toDouble().clamp(50, 500);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text('Interval: ${_interval.round()}s'),
        ),
        Slider(
          value: _interval,
          min: 30,
          max: 180,
          divisions: 15,
          onChanged: (v) => setState(() => _interval = (v / 10).round() * 10.0),
          onChangeEnd: (v) => widget.settings
              .setTelemetryIntervalSeconds(((v / 10).round() * 10).clamp(30, 180)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text('Min distance: ${_distance.round()}m'),
        ),
        Slider(
          value: _distance,
          min: 50,
          max: 500,
          divisions: 45,
          onChanged: (v) => setState(() => _distance = (v / 10).round() * 10.0),
          onChangeEnd: (v) => widget.settings
              .setTelemetryMinDistanceMeters(((v / 10).round() * 10).clamp(50, 500)),
        ),
      ],
    );
  }
}
