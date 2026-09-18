// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/channel.dart' show ChannelDataKind;
import 'package:meshcore_team/services/settings_service.dart';
import '../l10n/app_localizations.dart';

/// Makes sure tracking has a channel once it has been switched on.
///
/// Tracking with no channel shares nothing, so rather than leave it on
/// "None": the only eligible channel is used, several are offered to pick
/// from, and with none (or if the choice is cancelled) tracking is switched
/// back off.
///
/// Call it with a context that outlives any menu that triggered it.
Future<void> ensureTrackingChannel(BuildContext context) async {
  final settings = context.read<SettingsService>();
  final s = settings.settings;
  if (!s.telemetryEnabled) return;
  if (s.telemetryChannelHash?.isNotEmpty ?? false) return;

  final channels = (await context
          .read<AppDatabase>()
          .channelsDao
          .getVisibleChannels(s.currentCompanionPublicKey))
      .where((c) => c.canBeTrackingChannel)
      .toList();
  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  if (channels.isEmpty) {
    await settings.setTelemetryEnabled(false);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.trackingNeedsPrivateChannel)),
    );
    return;
  }

  final chosen = channels.length == 1
      ? channels.single
      : await showDialog<ChannelData>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: Text(l10n.trackingChannelPrompt),
            children: [
              for (final c in channels)
                SimpleDialogOption(
                  onPressed: () => Navigator.of(dialogContext).pop(c),
                  child: Text(c.name),
                ),
            ],
          ),
        );

  if (chosen == null) {
    await settings.setTelemetryEnabled(false);
    return;
  }
  await settings.setTelemetryChannelHash(
      chosen.hash.toRadixString(16).toLowerCase());
  await settings.setTelemetryChannelName(chosen.name);
}
