// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import '../l10n/app_localizations.dart';

/// True when the phone owns this channel but the connected radio doesn't
/// hold it — after a radio switch, or when its slots were full.
///
/// Such channels are parked on negative sentinel slots. Slot 0 is real: it
/// is the public channel, which is always on the radio.
bool channelNeedsRadio(ChannelData channel) =>
    !channel.firmwareConfirmed || channel.channelIndex < 0;

/// Asks whether to put a channel the phone owns onto the connected radio.
///
/// The radio does the encryption, so a channel it doesn't hold can be read
/// here but not used on the mesh. Returns true once the channel is on the
/// radio.
Future<bool> promptAddChannelToRadio(
  BuildContext context,
  ChannelData channel,
) async {
  final l10n = AppLocalizations.of(context)!;
  final repo = context.read<ChannelRepository>();
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.addChannelToRadio),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(channel.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(l10n.addChannelToRadioExplanation),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.add),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  final error = await repo.addChannelToRadio(channel);
  if (error == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.addedChannelToRadio(channel.name))),
    );
    return true;
  }

  messenger.showSnackBar(SnackBar(
    content: Text(switch (error) {
      AddChannelToRadioError.noSlots => l10n.addChannelToRadioNoSlots,
      AddChannelToRadioError.notConnected => l10n.notConnected,
      AddChannelToRadioError.failed => l10n.failedToAddChannel,
    }),
  ));
  return false;
}
