// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:meshcore_team/screens/connection_screen.dart';
import 'package:meshcore_team/screens/settings_screen.dart';
import '../l10n/app_localizations.dart';

/// Shared hamburger menu button used in the AppBar of Contacts, Channels,
/// and Map screens. Add menu items here to have them appear on all three.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  Future<void> _showAbout(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'MeshCore TEAM',
      applicationVersion: 'v${info.version}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu),
      onSelected: (value) {
        if (value == 'connection') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ConnectionScreen()),
          );
        } else if (value == 'app_settings') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        } else if (value == 'about') {
          _showAbout(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'connection',
          child: ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(l10n.connection),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'app_settings',
          child: ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.appSettings),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'about',
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.about),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
