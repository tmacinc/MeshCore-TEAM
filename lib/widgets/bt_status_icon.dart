// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/theme/night_theme.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';

class BtStatusIcon extends StatelessWidget {
  const BtStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<ConnectionViewModel>().isConnected;
    final isNighttime = context.watch<SettingsService>().settings.appTheme ==
        AppThemeMode.nighttime;

    final color = isNighttime
        ? (isConnected ? NightColors.statusConnected : NightColors.primary)
        : (isConnected ? Colors.blue : Colors.red);

    return Opacity(
      opacity: 0.7,
      child: Tooltip(
        message: isConnected ? 'Connected' : 'Not connected',
        child: Icon(
          isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
          color: color,
        ),
      ),
    );
  }
}
