// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final l10n = AppLocalizations.of(context)!;
    showAboutDialog(
      context: context,
      applicationName: 'MeshCore TEAM',
      applicationVersion: 'v${info.version}',
      children: [
        TextButton.icon(
          icon: const Icon(Icons.bug_report_outlined),
          label: Text(l10n.reportBug),
          onPressed: () => _reportBug(context, info),
        ),
      ],
    );
  }

  Future<void> _reportBug(BuildContext context, PackageInfo info) async {
    final platform =
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    final body = 'App version: ${info.version} (build ${info.buildNumber})\n'
        'Platform: $platform\n\n'
        'Describe the issue:\n';
    final uri = Uri.https('github.com', '/tmacinc/MeshCore-TEAM/issues/new', {
      'body': body,
    });

    final l10n = AppLocalizations.of(context)!;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenLink)),
        );
      }
    }
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
