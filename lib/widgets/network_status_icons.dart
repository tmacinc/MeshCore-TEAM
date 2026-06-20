// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/forwarding_policy_service.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/theme/night_theme.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';

/// Location sharing and forwarding status icons shown on all main screens.
class NetworkStatusIcons extends StatelessWidget {
  const NetworkStatusIcons({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>().settings;
    final isConnected = context.watch<ConnectionViewModel>().isConnected;
    final forwardingPolicy = context.watch<ForwardingPolicyService>();
    final isNighttime = settings.appTheme == AppThemeMode.nighttime;

    final telemetryConfigured = settings.telemetryEnabled &&
        (settings.telemetryChannelHash?.isNotEmpty ?? false);
    final telemetryActive = telemetryConfigured && isConnected;

    final campModeEnabled = settings.campModeEnabled;
    final activeHops = forwardingPolicy.lastAppliedMaxHops;
    final forwardingActive = activeHops != null && activeHops > 0;

    final telemetryTooltip = telemetryActive
        ? 'Sharing location'
        : telemetryConfigured
            ? 'Location sharing enabled (not connected)'
            : 'Location sharing off';

    final forwardingTooltip = forwardingActive && campModeEnabled
        ? 'Camp mode - forwarding active ($activeHops hop${activeHops == 1 ? '' : 's'})'
        : forwardingActive
            ? 'Policy engine: forwarding active ($activeHops hop${activeHops == 1 ? '' : 's'})'
            : campModeEnabled
                ? 'Forwarding mode: camp'
                : 'Default routing';

    final forwardingIconColor = isNighttime
        ? NightColors.onSurfaceVariant
        : Colors.lightGreenAccent;

    final label = campModeEnabled
        ? (forwardingActive ? 'C$activeHops' : 'C')
        : forwardingActive
            ? '$activeHops'
            : null;
    final showDouble = forwardingActive || campModeEnabled;

    return Opacity(
      opacity: 0.7,
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: telemetryTooltip,
          child: Icon(
            telemetryConfigured ? Icons.sensors : Icons.sensors_off,
            size: 22,
            color: isNighttime
                ? (telemetryActive ? NightColors.primary : NightColors.dimmer)
                : (telemetryActive
                    ? Colors.green
                    : telemetryConfigured
                        ? Colors.orange
                        : Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: forwardingTooltip,
          child: showDouble
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 18,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            child: Icon(Icons.check, size: 18, color: forwardingIconColor),
                          ),
                          Positioned(
                            left: 5,
                            child: Icon(Icons.check, size: 18, color: forwardingIconColor),
                          ),
                        ],
                      ),
                    ),
                    if (label != null) ...[
                      const SizedBox(width: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: forwardingIconColor,
                        ),
                      ),
                    ],
                  ],
                )
              : Icon(Icons.check, size: 20, color: forwardingIconColor),
        ),
        const SizedBox(width: 4),
      ],
      ),
    );
  }
}
