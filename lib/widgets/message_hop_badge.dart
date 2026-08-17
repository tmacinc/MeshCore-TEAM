// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/message_repository.dart';
import '../utils/radio_path_utils.dart';

/// Inline `(d)` / `(N)` / `(d/1)` hop badge for a message bubble.
///
/// Renders the Phase 1 single-value summary (from [fallbackHopCount],
/// firmware's own hopCount for this message) immediately, then swaps to the
/// real multi-path summary (e.g. "d/1" for a message heard both directly
/// and via a relay) once raw-frame correlation data loads, if any exists.
/// No loading flicker: the fallback is itself a valid, correct answer, just
/// potentially less complete.
class MessageHopBadge extends StatelessWidget {
  final String messageId;
  final int fallbackHopCount;
  final TextStyle? style;

  const MessageHopBadge({
    super.key,
    required this.messageId,
    required this.fallbackHopCount,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = '(${hopCountBadgeToken(fallbackHopCount)})';
    return FutureBuilder(
      future: context.read<MessageRepository>().getMessagePaths(messageId),
      builder: (context, snapshot) {
        final paths = snapshot.data;
        if (paths == null || paths.isEmpty) {
          return Text(fallback, style: style);
        }
        final hopCounts =
            paths.map((p) => decodePathByte(p.pathByte).hopCount).toList();
        return Text('(${formatHopCountsBadge(hopCounts)})', style: style);
      },
    );
  }
}
