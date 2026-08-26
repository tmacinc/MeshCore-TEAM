// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/screens/settings_screen.dart';
import 'package:meshcore_team/services/forwarding_policy_service.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/theme/night_theme.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import '../l10n/app_localizations.dart';

/// Location sharing and forwarding status icons shown on all main screens.
class NetworkStatusIcons extends StatelessWidget {
  const NetworkStatusIcons({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsService = context.watch<SettingsService>();
    final settings = settingsService.settings;
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
        ? l10n.sharingLocation
        : telemetryConfigured
            ? l10n.locationSharingEnabledNotConnected
            : l10n.locationSharingOff;

    final forwardingTooltip = forwardingActive && campModeEnabled
        ? l10n.campModeForwardingActive(activeHops!)
        : forwardingActive
            ? l10n.policyEngineForwardingActive(activeHops!)
            : campModeEnabled
                ? l10n.forwardingModeCamp
                : l10n.defaultRouting;

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
        PopupMenuButton<void>(
          tooltip: telemetryTooltip,
          padding: EdgeInsets.zero,
          icon: Icon(
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
          itemBuilder: (context) {
            bool trackingEnabled = settings.telemetryEnabled;
            return [
              PopupMenuItem<void>(
                enabled: false,
                padding: EdgeInsets.zero,
                child: StatefulBuilder(
                  builder: (context, setLocalState) => SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(l10n.locationTracking),
                    value: trackingEnabled,
                    onChanged: (value) {
                      setLocalState(() => trackingEnabled = value);
                      settingsService.setTelemetryEnabled(value);
                    },
                  ),
                ),
              ),
              PopupMenuItem<void>(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text(l10n.appSettings),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ];
          },
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
