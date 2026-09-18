// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/models/capability_message.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import '../l10n/app_localizations.dart';

/// Asks for a team name once: at first launch, and once for anyone upgrading.
///
/// The field starts empty, with the radio name (when there is one) as
/// placeholder text. It is deliberately not pre-filled: saving a copy of the
/// radio name would leave the team seeing the old name after the radio is
/// renamed, which is exactly what someone anonymizing their radio doesn't
/// want. Skipping, or saving it empty, means "use my radio name".
Future<void> showTeamNamePromptIfNeeded(BuildContext context) async {
  final settings = context.read<SettingsService>();
  if (settings.settings.teamAliasPrompted) return;

  final radioName = context.read<ConnectionViewModel>().deviceName.trim();
  if (!context.mounted) return;

  final controller = TextEditingController();
  final alias = await showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext)!;
      return AlertDialog(
        scrollable: true,
        title: Text(l10n.teamNamePrompt),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: CapabilityMessage.maxAliasBytes,
              decoration: InputDecoration(
                labelText: l10n.teamName,
                hintText: radioName.isEmpty ? null : radioName,
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.teamNameSaveExplanation),
            const SizedBox(height: 8),
            Text(l10n.teamNameSkipExplanation),
            const SizedBox(height: 12),
            Text(
              l10n.teamNameChangeLater,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(dialogContext).colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: Text(l10n.skip),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      );
    },
  );

  // Typing the radio name means the same as skipping, and keeps working when
  // the radio is renamed.
  final chosen = (alias == null || alias == radioName) ? null : alias;
  await settings.setTeamAlias(chosen);
  await settings.setTeamAliasPrompted(true);
}
