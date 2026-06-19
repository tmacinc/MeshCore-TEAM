// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/settings_service.dart';
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
          if (Platform.isIOS) ...[
            const Divider(height: 1),
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
                    title: 'Always On Location',
                    subtitle: settings.settings.backgroundLocationEnabled
                        ? 'Enabled — location updates continue in background'
                        : 'Disabled',
                    leading: settings.settings.backgroundLocationEnabled
                        ? Icons.my_location
                        : Icons.location_disabled,
                    onTap: () => _showBackgroundLocationDialog(settings),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ],
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
