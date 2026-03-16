// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database.dart';
import '../repositories/channel_repository.dart';
import '../repositories/message_repository.dart';
import '../services/message_notification_service.dart';

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
  int _previousMessageCount = 0;
  int? _firstUnreadTimestamp;

  @override
  void initState() {
    super.initState();
    _messageRepository = Provider.of<MessageRepository>(context, listen: false);
    _channelRepository = Provider.of<ChannelRepository>(context, listen: false);

    // Track active channel for notification suppression
    MessageNotificationService.isMessagesScreenVisible = true;
    MessageNotificationService.activeChannelHash = widget.channel.hash;

    // Get first unread timestamp for divider
    _loadFirstUnreadTimestamp();
  }

  Future<void> _loadFirstUnreadTimestamp() async {
    final timestamp = await _messageRepository.messagesDao
        .getFirstUnreadTimestampByChannel(widget.channel.hash);
    setState(() {
      _firstUnreadTimestamp = timestamp;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    // Mark all messages as read when navigating away
    _messageRepository.messagesDao
        .markChannelMessagesAsRead(widget.channel.hash);

    // Clear active channel tracking
    MessageNotificationService.isMessagesScreenVisible = false;
    MessageNotificationService.activeChannelHash = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.channel.name),
            Text(
              widget.channel.isPublic ? 'Public Channel' : 'Private Channel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surfaceVariant,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        elevation: 0,
        actions: [
          if (!widget.channel.isPublic)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share channel',
              onPressed: () => _showShareChannelDialog(context),
            ),
          IconButton(
            icon: Icon(
              widget.channel.isPublic ? Icons.public : Icons.lock,
              color: widget.channel.isPublic ? Colors.green : Colors.orange,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Channel Index: ${widget.channel.channelIndex}\n'
                    'Hash: ${widget.channel.hash.toRadixString(16).padLeft(2, '0')}',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<MessageData>>(
              stream: _messageRepository
                  .watchMessagesByChannel(widget.channel.hash),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                // Auto-scroll to bottom when new messages arrive
                if (messages.length > _previousMessageCount) {
                  _previousMessageCount = messages.length;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }

                if (messages.isEmpty) {
                  return Center(
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
                          'No messages in this channel',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to start the conversation',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final showUnreadDivider = _firstUnreadTimestamp != null &&
                        message.timestamp == _firstUnreadTimestamp;

                    return Column(
                      children: [
                        if (showUnreadDivider) _buildUnreadDivider(theme),
                        _buildMessageBubble(message, theme),
                      ],
                    );
                  },
                );
              },
            ),
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
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message to ${widget.channel.name}...',
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
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      onChanged: (text) {
                        // Mark as read when user starts typing
                        if (text.isNotEmpty && _firstUnreadTimestamp != null) {
                          _messageRepository.messagesDao
                              .markChannelMessagesAsRead(widget.channel.hash);
                          setState(() {
                            _firstUnreadTimestamp = null; // Hide divider
                          });
                        }
                      },
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
        return AlertDialog(
          title: const Text('Share Channel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: QrImageView(
                    data: link,
                    size: 220,
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
                    const SnackBar(content: Text('Link copied')),
                  );
                }
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Share.share(link),
              child: const Text('Share'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done'),
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
                  Text(
                    message.content,
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
                        '${timestamp.hour.toString().padLeft(2, '0')}:'
                        '${timestamp.minute.toString().padLeft(2, '0')}',
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
        ],
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

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Clear input immediately
    _messageController.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
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
            const SnackBar(
              content: Text('Failed to send message'),
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
            content: Text('Error: $e'),
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
