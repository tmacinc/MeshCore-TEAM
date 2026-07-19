// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../l10n/app_localizations.dart';
import '../repositories/contact_repository.dart';
import '../repositories/message_repository.dart';
import '../services/settings_service.dart';
import '../utils/message_time_format.dart';
import '../utils/radio_path_utils.dart';

/// Bottom sheet showing how a message was physically received: a simple
/// Sender -> You timeline when only the message-level hop-count summary is
/// available (Messages.hopCount/snr), or, when raw-frame correlation
/// matched real radio packets (see MessageRepository.getMessagePaths), a
/// full breakdown per distinct path -- including which repeater(s) relayed
/// it, real SNR/RSSI, and every path heard at once (e.g. direct AND via a
/// relay simultaneously).
class MessagePathSheet extends StatefulWidget {
  final String messageId;
  final String senderName;

  /// Fallback summary (0 = direct) used only when no correlated paths
  /// exist for this message.
  final int hopCount;
  final DateTime timestamp;

  const MessagePathSheet({
    super.key,
    required this.messageId,
    required this.senderName,
    required this.hopCount,
    required this.timestamp,
  });

  @override
  State<MessagePathSheet> createState() => _MessagePathSheetState();
}

class _ResolvedHop {
  final Uint8List prefix;
  final List<ContactData> matches;
  _ResolvedHop({required this.prefix, required this.matches});
}

class _ResolvedPath {
  final MessagePathData raw;
  final List<_ResolvedHop> hops;
  _ResolvedPath({required this.raw, required this.hops});
}

class _MessagePathSheetState extends State<MessagePathSheet> {
  List<_ResolvedPath>? _resolvedPaths;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final messageRepo = context.read<MessageRepository>();
    final contactRepo = context.read<ContactRepository>();
    final companionKey =
        context.read<SettingsService>().settings.currentCompanionPublicKey;

    final paths = await messageRepo.getMessagePaths(widget.messageId);
    final resolved = <_ResolvedPath>[];
    for (final path in paths) {
      final hopPrefixes = splitPathHops(path.pathByte, path.pathBytes);
      final hops = <_ResolvedHop>[];
      for (final prefix in hopPrefixes) {
        final matches = await contactRepo.getContactsByPublicKeyPrefix(
          prefix,
          prefixLength: prefix.length,
          companionKey: companionKey,
        );
        hops.add(_ResolvedHop(prefix: prefix, matches: matches));
      }
      resolved.add(_ResolvedPath(raw: path, hops: hops));
    }

    if (mounted) setState(() => _resolvedPaths = resolved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final resolved = _resolvedPaths;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: resolved == null
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(l10n.messagePath,
                          style: theme.textTheme.titleMedium),
                      if (resolved.length > 1) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${formatHopCountsBadge(resolved.map((p) => decodePathByte(p.raw.pathByte).hopCount).toList())})',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatMessageTime(widget.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (resolved.isEmpty)
                    _SinglePathTimeline(
                      senderName: widget.senderName,
                      hopCount: widget.hopCount,
                    )
                  else
                    for (var i = 0; i < resolved.length; i++) ...[
                      if (i > 0) const SizedBox(height: 20),
                      if (resolved.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            l10n.pathNumber(i + 1),
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                      _ResolvedPathTimeline(
                        senderName: widget.senderName,
                        path: resolved[i],
                      ),
                    ],
                ],
              ),
      ),
    );
  }
}

/// Fallback timeline for when no raw-frame correlation exists -- just the
/// message-level hop-count summary firmware already gives us.
class _SinglePathTimeline extends StatelessWidget {
  final String senderName;
  final int hopCount;

  const _SinglePathTimeline({required this.senderName, required this.hopCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDirect = hopCount == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineNode(label: senderName, color: theme.colorScheme.primary),
        _TimelineConnector(
          label: isDirect ? l10n.hopDirect : l10n.hopsCount(hopCount),
          color: theme.colorScheme.outline,
        ),
        _TimelineNode(label: 'You', color: theme.colorScheme.primary),
      ],
    );
  }
}

/// Full timeline for a correlated path: sender, each named/ambiguous/unknown
/// hop, then the receiver, with real SNR/RSSI on the connecting caption.
class _ResolvedPathTimeline extends StatelessWidget {
  final String senderName;
  final _ResolvedPath path;

  const _ResolvedPathTimeline({required this.senderName, required this.path});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final decoded = decodePathByte(path.raw.pathByte);
    final isDirect = decoded.hopCount == 0;

    final signalParts = <String>[];
    if (path.raw.snr != null) {
      signalParts.add(l10n.snrValue((path.raw.snr! / 4.0).toStringAsFixed(1)));
    }
    if (path.raw.rssi != null) {
      signalParts.add(l10n.rssiValue(path.raw.rssi!));
    }
    final signalLabel = signalParts.join(' · ');

    final children = <Widget>[
      _TimelineNode(label: senderName, color: theme.colorScheme.primary),
    ];

    if (isDirect) {
      // No intermediate node to attach the hex/signal caption to -- this is
      // the same "Direct" summary the reference layout shows at the top
      // level when there's nothing between sender and receiver.
      children.add(_TimelineConnector(
        label: signalLabel.isEmpty
            ? l10n.hopDirect
            : '${l10n.hopDirect} — $signalLabel',
        color: theme.colorScheme.outline,
      ));
    } else {
      for (var i = 0; i < path.hops.length; i++) {
        final hop = path.hops[i];
        final hex = _hopHex(hop);
        // Plain connecting segment -- the hex/hop-number identifies the
        // node it leads to, so it's a caption on that node, not a label on
        // the segment leading to it.
        children.add(
            _TimelineConnector(label: '', color: theme.colorScheme.outline));
        children.add(_TimelineNode(
          caption: l10n.hopLabel(i + 1, hex),
          label: _hopName(l10n, hop, hex),
          color: hop.matches.length == 1
              ? theme.colorScheme.secondary
              : theme.colorScheme.error,
        ));
      }
      // Final segment, into the receiver -- this is "the last hop, as heard
      // by you" regardless of how many relays preceded it, so the signal
      // reading belongs here.
      children.add(_TimelineConnector(
          label: signalLabel, color: theme.colorScheme.outline));
    }

    children.add(_TimelineNode(label: 'You', color: theme.colorScheme.primary));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Hex string of a hop's raw path-byte identifier, per the reference
  /// layout (e.g. "6C") -- shown on the connector regardless of whether the
  /// hop resolves to a known contact.
  String _hopHex(_ResolvedHop hop) {
    return hop.prefix
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  /// Resolved display name for a hop's node: the contact name if there's
  /// exactly one match, an ambiguous-candidates note if more than one
  /// shares this hex prefix, or the hex itself again if unknown.
  String _hopName(AppLocalizations l10n, _ResolvedHop hop, String hex) {
    if (hop.matches.isEmpty) return hex;
    if (hop.matches.length > 1) {
      return l10n
          .ambiguousHop(hop.matches.map((c) => c.name ?? '?').join(', '));
    }
    return hop.matches.first.name ?? hex;
  }
}

class _TimelineNode extends StatelessWidget {
  final String label;
  final Color color;

  /// Small label above [label] identifying the node's role and raw
  /// identifier (e.g. "Hop 1: 6C") -- matches the reference layout, where
  /// this caption belongs to the node it identifies, not the segment
  /// leading to it.
  final String? caption;

  const _TimelineNode({required this.label, required this.color, this.caption});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: CircleAvatar(radius: 4, backgroundColor: color),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (caption != null)
                Text(
                  caption!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
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
          if (label.isNotEmpty)
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
