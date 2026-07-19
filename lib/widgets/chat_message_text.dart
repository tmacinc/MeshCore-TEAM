// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../repositories/channel_repository.dart';

/// Renders a chat message with tappable [#hashtag] links, tappable URLs, and
/// styled [@mention]s.
///
/// Tapping a #hashtag presents a confirmation dialog that joins the channel
/// whose PSK is derived from the name alone — no QR exchange needed.
///
/// Tapping a URL opens it in the device's default browser.
///
/// @mentions are highlighted in the secondary colour but are not currently
/// interactive (the exact mention format may vary by firmware version).
class ChatMessageText extends StatefulWidget {
  final String text;

  /// Base text style applied to plain runs. Colour overrides are applied per
  /// token type (#hashtag → primary, @mention → secondary).
  final TextStyle? style;

  const ChatMessageText({super.key, required this.text, this.style});

  @override
  State<ChatMessageText> createState() => _ChatMessageTextState();
}

class _ChatMessageTextState extends State<ChatMessageText> {
  /// Matches #hashtag (alphanumeric, underscore, hyphen), @mention
  /// (non-whitespace), and http(s)/www URLs.
  static final _tokenPattern = RegExp(
    r'(#[a-zA-Z0-9_-]+|@\[[^\]]+\]|https?://\S+|www\.\S+)',
  );

  /// Trailing characters trimmed off a matched URL so sentence punctuation
  /// immediately after a link (e.g. "see https://example.com.") isn't
  /// swallowed into the tappable span.
  static const _urlTrailingPunctuation = '.,;:!?\'")]}';

  static bool _isUrl(String token) =>
      token.startsWith('http://') ||
      token.startsWith('https://') ||
      token.startsWith('www.');

  /// End offset of [match] with any trailing punctuation trimmed off, for
  /// URL tokens only (other token types are returned unchanged).
  int _effectiveEnd(RegExpMatch match) {
    if (!_isUrl(match.group(0)!)) return match.end;
    var end = match.end;
    while (end > match.start &&
        _urlTrailingPunctuation.contains(widget.text[end - 1])) {
      end--;
    }
    return end;
  }

  // Recognizers and matches are built once and reused across rebuilds.
  // Rebuilt only in didUpdateWidget when widget.text changes, which never
  // happens for received messages.
  final List<TapGestureRecognizer> _recognizers = [];
  late List<RegExpMatch> _matches;

  @override
  void initState() {
    super.initState();
    _matches = _tokenPattern.allMatches(widget.text).toList();
    _buildRecognizers();
  }

  @override
  void didUpdateWidget(ChatMessageText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _clearRecognizers();
      _matches = _tokenPattern.allMatches(widget.text).toList();
      _buildRecognizers();
    }
  }

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  void _clearRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _buildRecognizers() {
    for (final match in _matches) {
      final token = match.group(0)!;
      if (token.startsWith('#')) {
        _recognizers.add(TapGestureRecognizer()
          ..onTap = () => _onHashtagTapped(context, token));
      } else if (_isUrl(token)) {
        final url = widget.text.substring(match.start, _effectiveEnd(match));
        _recognizers.add(
            TapGestureRecognizer()..onTap = () => _onUrlTapped(context, url));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = widget.style;
    final spans = <InlineSpan>[];

    int lastEnd = 0;
    int recIdx = 0;
    for (final match in _matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: widget.text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      final token = match.group(0)!;
      if (token.startsWith('#')) {
        spans.add(TextSpan(
          text: token,
          style: baseStyle?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            decorationColor: theme.colorScheme.primary,
          ),
          recognizer: _recognizers[recIdx++],
        ));
      } else if (_isUrl(token)) {
        final urlEnd = _effectiveEnd(match);
        spans.add(TextSpan(
          text: widget.text.substring(match.start, urlEnd),
          style: baseStyle?.copyWith(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: theme.colorScheme.primary,
          ),
          recognizer: _recognizers[recIdx++],
        ));
        if (urlEnd < match.end) {
          spans.add(TextSpan(
            text: widget.text.substring(urlEnd, match.end),
            style: baseStyle,
          ));
        }
      } else {
        // @mention — visual highlight only (format TBD by firmware)
        spans.add(TextSpan(
          text: token,
          style: baseStyle?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _onUrlTapped(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    final l10n = AppLocalizations.of(context)!;
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenLink)),
        );
      }
    }
  }

  Future<void> _onHashtagTapped(BuildContext context, String tag) async {
    final channelRepository = context.read<ChannelRepository>();
    final l10n = AppLocalizations.of(context)!;
    bool isJoining = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> join() async {
              if (isJoining) return;
              setState(() => isJoining = true);
              try {
                final joined =
                    await channelRepository.createHashtagChannel(tag);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.channelJoined(joined.name))),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  setState(() => isJoining = false);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            }

            return AlertDialog(
              title: Text(l10n.joinChannelConfirmation(tag)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Anyone who joins "$tag" derives the same key from the '
                    'name — no QR code needed.',
                  ),
                  if (isJoining) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isJoining
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: isJoining ? null : join,
                  child: Text(l10n.join),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
