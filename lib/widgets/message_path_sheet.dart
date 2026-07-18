// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/message_time_format.dart';

/// Bottom sheet showing a simple sender → receiver timeline for a message,
/// with the hop count (direct or N relays) between them.
///
/// This is a summary view only — the underlying BLE protocol doesn't
/// currently expose which specific repeaters relayed a message, just a hop
/// count, so unlike richer reference clients this can't name individual
/// hops or show per-hop signal stats yet.
class MessagePathSheet extends StatelessWidget {
  final String senderName;

  /// 0 = direct, >0 = number of relay hops.
  final int hopCount;
  final DateTime timestamp;

  const MessagePathSheet({
    super.key,
    required this.senderName,
    required this.hopCount,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDirect = hopCount == 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.messagePath, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              formatMessageTime(timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _TimelineNode(label: senderName, color: theme.colorScheme.primary),
            _TimelineConnector(
              label: isDirect ? l10n.hopDirect : l10n.hopsCount(hopCount),
              color: theme.colorScheme.outline,
            ),
            _TimelineNode(label: 'You', color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final String label;
  final Color color;

  const _TimelineNode({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  final String label;
  final Color color;

  const _TimelineConnector({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 3.5),
            child: Container(width: 1, height: 28, color: color),
          ),
          const SizedBox(width: 20.5),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
