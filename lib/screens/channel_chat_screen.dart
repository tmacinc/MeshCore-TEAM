// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:io' show Platform;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:async';

import '../database/database.dart';
import '../l10n/app_localizations.dart';
import '../repositories/channel_repository.dart';
import '../repositories/message_repository.dart';
import '../services/message_notification_service.dart';
import '../widgets/chat_message_text.dart';
import '../widgets/status_bar_actions.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../theme/night_theme.dart';
import '../utils/message_time_format.dart';

/// Channel chat screen for group conversations
class ChannelChatScreen extends StatefulWidget {
  final ChannelData channel;

  const ChannelChatScreen({
    super.key,
    required this.channel,
  });

  @override
  State<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends State<ChannelChatScreen> {
  late final MessageRepository _messageRepository;
  late final ChannelRepository _channelRepository;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  int? _firstUnreadTimestamp;
  List<String> _mentionSuggestions = [];
  StreamSubscription<List<MessageData>>? _messagesSub;
  late final Stream<List<MessageData>> _messagesStream;
  List<MessageData> _allMessages = const [];
  List<MessageData> _messages = const [];
  bool _messagesLoaded = false;
  bool _isAtBottom = true;

  int get _newMessageCount => _allMessages.length - _messages.length;

  @override
  void initState() {
    super.initState();
    _messageRepository = Provider.of<MessageRepository>(context, listen: false);
    _channelRepository = Provider.of<ChannelRepository>(context, listen: false);
    if (!Platform.isAndroid && !Platform.isIOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _inputFocusNode.requestFocus();
      });
    }
    _scrollController.addListener(_onScroll);
    _messagesStream =
        _messageRepository.watchMessagesByChannel(widget.channel.hash);
    _messagesSub = _messagesStream.listen((messages) {
      if (!mounted) return;
      setState(() {
        _allMessages = messages;
        _messagesLoaded = true;
        if (_isAtBottom || messages.length <= _messages.length) {
          _messages = messages;
        }
      });
      if (_isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    // Track active channel for notification suppression
    MessageNotificationService.isMessagesScreenVisible = true;
    MessageNotificationService.activeChannelHash = widget.channel.hash;

    // Get first unread timestamp for divider
    _loadFirstUnreadTimestamp();
  }

  Future<void> _loadFirstUnreadTimestamp() async {
    final timestamp = await _messageRepository.messagesDao
        .getFirstUnreadTimestampByChannel(widget.channel.hash);
    if (!mounted) return;
    setState(() {
      _firstUnreadTimestamp = timestamp;
    });
    // Mark as read now, while this screen is still visible, so the channel
    // list is already sorted correctly by the time the user navigates back.
    await _messageRepository.messagesDao
        .markChannelMessagesAsRead(widget.channel.hash);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _messagesSub?.cancel();

    // Clear active channel tracking
    MessageNotificationService.isMessagesScreenVisible = false;
    MessageNotificationService.activeChannelHash = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isNighttime = context.watch<SettingsService>().settings.appTheme ==
        AppThemeMode.nighttime;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.channel.name),
            Text(
              widget.channel.isPublic ? l10n.publicChannel : l10n.privateChannel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          if (!widget.channel.isPublic)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: l10n.shareChannelLower,
              onPressed: () => _showShareChannelDialog(context),
            ),
          IconButton(
            icon: Icon(
              widget.channel.isPublic ? Icons.public : Icons.lock,
              color: isNighttime
                  ? NightColors.onSurfaceVariant
                  : (widget.channel.isPublic ? Colors.green : Colors.orange),
            ),
            onPressed: () {
              final l = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${l.channelIndex(widget.channel.channelIndex.toString())}\n'
                    '${l.channelHash(widget.channel.hash.toRadixString(16).padLeft(2, '0'))}',
                  ),
                ),
              );
            },
          ),
          const SizedBox(
            height: 24,
            child: VerticalDivider(width: 16, thickness: 1),
          ),
          const StatusBarActions(),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Stack(
              children: [
                if (!_messagesLoaded)
                  const Center(child: CircularProgressIndicator())
                else if (_messages.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          color: theme.colorScheme.outline,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noMessagesInChannel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.beFirstToStartConversation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message =
                          _messages[_messages.length - 1 - index];
                      final showUnreadDivider =
                          _firstUnreadTimestamp != null &&
                              message.timestamp == _firstUnreadTimestamp;

                      return Column(
                        children: [
                          if (showUnreadDivider) _buildUnreadDivider(theme),
                          _buildMessageBubble(message, theme),
                        ],
                      );
                    },
                  ),
                if (_newMessageCount > 0)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _scrollToBottom,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 4,
                                color: Colors.black26,
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_newMessageCount new ${_newMessageCount == 1 ? 'message' : 'messages'}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // @mention suggestions
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            alignment: Alignment.bottomCenter,
            child: _buildMentionSuggestions(),
          ),

          // Message input
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        TextField(
                          controller: _messageController,
                          focusNode: _inputFocusNode,
                          decoration: InputDecoration(
                            hintText:
                                l10n.typeAMessageToChannel(widget.channel.name),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            counterText: '',
                          ),
                          maxLines: null,
                          maxLength: 130,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          onChanged: (text) {
                            // Mark as read when user starts typing
                            if (text.isNotEmpty &&
                                _firstUnreadTimestamp != null) {
                              _messageRepository.messagesDao
                                  .markChannelMessagesAsRead(
                                      widget.channel.hash);
                              setState(() {
                                _firstUnreadTimestamp = null;
                              });
                            }
                            _updateMentionSuggestions(text);
                          },
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _messageController,
                            builder: (context, value, _) {
                              final count = value.text.length;
                              if (count == 0) return const SizedBox.shrink();
                              return Text(
                                '$count/130',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.6),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    mini: true,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showShareChannelDialog(BuildContext context) async {
    final link = _channelRepository.exportChannelKey(widget.channel);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l.shareChannel),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: QrImageView(
                      data: link,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Anyone with this link can join this private channel. Treat it like a password.',
                ),
                const SizedBox(height: 12),
                SelectableText(link),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.linkCopied)),
                  );
                }
              },
              child: Text(l.copy),
            ),
            TextButton(
              onPressed: () => Share.share(link),
              child: Text(l.share),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.done),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnreadDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.colorScheme.error,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Unread Messages',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: theme.colorScheme.error,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageData message, ThemeData theme) {
    final isFromMe = message.isSentByMe ?? false;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
    final senderName = isFromMe
        ? 'You'
        : (message.senderName ?? _getSenderName(message.senderId));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromMe) const SizedBox(width: 0), // Align left for received
          Flexible(
            child: GestureDetector(
              onLongPress: (Platform.isAndroid || Platform.isIOS)
                  ? () => _showMessageActions(message, senderName, isFromMe)
                  : null,
              onSecondaryTapDown: (!Platform.isAndroid && !Platform.isIOS)
                  ? (d) => _showMessageActions(message, senderName, isFromMe)
                  : null,
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: EdgeInsets.only(
                left: isFromMe ? 48 : 0,
                right: isFromMe ? 0 : 48,
              ),
              decoration: BoxDecoration(
                color: isFromMe
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isFromMe ? const Radius.circular(4) : null,
                  bottomLeft: !isFromMe ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isFromMe) ...[
                    Text(
                      senderName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  ChatMessageText(
                    text: message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isFromMe
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatMessageTime(timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: (isFromMe
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant)
                              .withOpacity(0.7),
                        ),
                      ),
                      if (isFromMe && message.deliveryStatus != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getStatusIcon(message.deliveryStatus!),
                          size: 14,
                          color: (isFromMe
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant)
                              .withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  void _seedReply(String senderName) {
    final prefix = '@[$senderName] ';
    final current = _messageController.text;
    if (current.startsWith(prefix)) return;
    final newText = current.isEmpty ? prefix : '$prefix$current';
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    _inputFocusNode.requestFocus();
  }

  void _showMessageActions(MessageData message, String senderName, bool isFromMe) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(AppLocalizations.of(context)!.copyMessageText),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.copied),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            if (!isFromMe)
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(AppLocalizations.of(context)!.reply),
                onTap: () {
                  Navigator.pop(ctx);
                  _seedReply(senderName);
                },
              ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'SENDING':
        return Icons.schedule;
      case 'SENT':
        return Icons.done;
      case 'DELIVERED':
        return Icons.done_all;
      default:
        return Icons.error_outline;
    }
  }

  String _getSenderName(List<int> senderId) {
    if (senderId.isEmpty) return 'Unknown';
    final hex = _bytesToHex(senderId);
    return hex.substring(0, 8); // Show first 8 chars of public key
  }

  Widget _buildMentionSuggestions() {
    if (_mentionSuggestions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      color: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: _mentionSuggestions.length,
          itemBuilder: (context, index) {
            final name = _mentionSuggestions[index];
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person, size: 18),
              ),
              title: Text(name),
              dense: true,
              onTap: () => _applyMention(name),
            );
          },
        ),
      ),
    );
  }

  List<String> get _channelSenderNames {
    return _messages
        .where((m) => !(m.isSentByMe ?? false))
        .map((m) => m.senderName ?? _getSenderName(m.senderId))
        .where((name) => name.isNotEmpty && name != 'Unknown')
        .toSet()
        .toList();
  }

  void _updateMentionSuggestions(String text) {
    final cursor = _messageController.selection.baseOffset;
    if (cursor <= 0) {
      if (_mentionSuggestions.isNotEmpty)
        setState(() => _mentionSuggestions = []);
      return;
    }
    final before = text.substring(0, cursor.clamp(0, text.length));
    final atIndex = before.lastIndexOf('@');
    if (atIndex == -1) {
      if (_mentionSuggestions.isNotEmpty)
        setState(() => _mentionSuggestions = []);
      return;
    }
    final query = before.substring(atIndex + 1);
    if (query.contains(' ')) {
      if (_mentionSuggestions.isNotEmpty)
        setState(() => _mentionSuggestions = []);
      return;
    }
    final queryLower = query.toLowerCase();
    final names = _channelSenderNames;
    final filtered = query.isEmpty
        ? names
        : names.where((n) => n.toLowerCase().contains(queryLower)).toList();
    setState(() => _mentionSuggestions = filtered);
  }

  void _applyMention(String contactName) {
    final text = _messageController.text;
    final cursor = _messageController.selection.baseOffset;
    if (cursor <= 0) return;
    final before = text.substring(0, cursor.clamp(0, text.length));
    final atIndex = before.lastIndexOf('@');
    if (atIndex == -1) return;
    final after = cursor < text.length ? text.substring(cursor) : '';
    final newText = '${text.substring(0, atIndex)}@[$contactName] $after';
    final newCursor = atIndex + contactName.length + 4; // @[name][space]
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    setState(() => _mentionSuggestions = []);
    if (!Platform.isAndroid && !Platform.isIOS) _inputFocusNode.requestFocus();
  }

  void _onScroll() {
    final atBottom = _scrollController.offset <= 50;
    if (atBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = atBottom;
        if (atBottom) _messages = _allMessages;
      });
    }
  }

  void _scrollToBottom() {
    setState(() {
      _messages = _allMessages;
      _isAtBottom = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    if (content.length > 130) return;

    // Clear input immediately
    _messageController.clear();
    setState(() { _mentionSuggestions = []; _messages = _allMessages; });
    if (!Platform.isAndroid && !Platform.isIOS) _inputFocusNode.requestFocus();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Send message
    try {
      final messageId = await _messageRepository.sendChannelMessage(
        channelIndex: widget.channel.channelIndex,
        channelHash: widget.channel.hash,
        content: content,
      );

      if (messageId != null) {
        debugPrint('✅ Channel message sent with ID: $messageId');
      } else {
        // Show error snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToSendMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending channel message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.genericError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
