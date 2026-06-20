// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:meshcore_team/screens/connection_screen.dart';
import 'package:meshcore_team/screens/settings_screen.dart';

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
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'connection',
          child: ListTile(
            leading: Icon(Icons.bluetooth),
            title: Text('Connection'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'app_settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('App Settings'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'about',
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
