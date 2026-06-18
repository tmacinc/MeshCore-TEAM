// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:flutter/material.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/theme/night_theme.dart';
import 'package:provider/provider.dart';

/// Wraps [DropdownButtonFormField] to apply the correct icon color in
/// nighttime mode, since Flutter's DropdownButton ignores iconTheme and
/// always uses white70 in dark brightness.
class ThemedDropdown<T> extends StatelessWidget {
  final T? value;
  final InputDecoration? decoration;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;

  const ThemedDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.decoration,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isNighttime =
        context.watch<SettingsService>().settings.appTheme ==
            AppThemeMode.nighttime;
    final iconColor =
        isNighttime ? NightColors.onSurfaceVariant : null;
    final iconDisabledColor =
        isNighttime ? NightColors.dimmer : null;

    return DropdownButtonFormField<T>(
      value: value,
      decoration: decoration,
      items: items,
      onChanged: onChanged,
      isExpanded: isExpanded,
      iconEnabledColor: iconColor,
      iconDisabledColor: iconDisabledColor,
    );
  }
}
