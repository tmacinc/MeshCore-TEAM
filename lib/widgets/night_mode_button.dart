// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:flutter/material.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/settings_service.dart';

class NightModeButton extends StatelessWidget {
  final SettingsService settings;

  const NightModeButton({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final isNighttime =
        settings.settings.appTheme == AppThemeMode.nighttime;
    return Opacity(
      opacity: isNighttime ? 1.0 : 0.4,
      child: IconButton(
        icon: const Icon(Icons.nightlight_round),
        tooltip: isNighttime ? 'Nighttime mode: on' : 'Nighttime mode: off',
        onPressed: () => settings.setAppTheme(
          isNighttime ? AppThemeMode.system : AppThemeMode.nighttime,
        ),
      ),
    );
  }
}
