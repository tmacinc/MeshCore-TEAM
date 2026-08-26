// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/screens/connection_screen.dart';
import 'package:meshcore_team/services/mesh_connection_service.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/theme/night_theme.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import '../l10n/app_localizations.dart';

class BtStatusIcon extends StatelessWidget {
  const BtStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final connectionVM = context.watch<ConnectionViewModel>();
    final meshService = context.watch<MeshConnectionService>();
    final isConnected = connectionVM.isConnected;
    // Service running but not connected → an auto-reconnect is in progress.
    final isReconnecting = !isConnected && meshService.isReconnecting;
    final isNighttime = context.watch<SettingsService>().settings.appTheme ==
        AppThemeMode.nighttime;

    final color = isNighttime
        ? (isConnected ? NightColors.statusConnected : NightColors.primary)
        : (isConnected ? Colors.blue : Colors.red);

    final icon = Icon(
      isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
      color: color,
    );

    // Reconnecting: offer a "Stop reconnecting" action so the user can kill a
    // stuck reconnect (e.g. companion battery died) without waiting.
    if (isReconnecting) {
      return Opacity(
        opacity: 0.7,
        child: PopupMenuButton<void>(
          tooltip: l10n.notConnected,
          icon: icon,
          itemBuilder: (context) => [
            PopupMenuItem<void>(
              onTap: () => connectionVM.manualDisconnect(),
              child: ListTile(
                leading: const Icon(Icons.stop_circle_outlined),
                title: Text(l10n.stopReconnecting),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem<void>(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConnectionScreen()),
              ),
              child: ListTile(
                leading: const Icon(Icons.settings_bluetooth),
                title: Text(l10n.connection),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );
    }

    // Disconnected (no active service): tap opens the connection page.
    if (!isConnected) {
      return Opacity(
        opacity: 0.7,
        child: IconButton(
          tooltip: l10n.notConnected,
          icon: icon,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ConnectionScreen()),
          ),
        ),
      );
    }

    // Connected: dropdown with a disconnect action.
    return Opacity(
      opacity: 0.7,
      child: PopupMenuButton<void>(
        tooltip: l10n.connected,
        icon: icon,
        itemBuilder: (context) => [
          PopupMenuItem<void>(
            onTap: () => connectionVM.manualDisconnect(),
            child: ListTile(
              leading: const Icon(Icons.bluetooth_disabled),
              title: Text(l10n.disconnect),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
