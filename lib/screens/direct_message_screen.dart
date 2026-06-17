// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

import '../database/database.dart';
import '../repositories/contact_repository.dart';
import '../repositories/message_repository.dart';
import '../services/message_notification_service.dart';
import '../widgets/chat_message_text.dart';

/// Direct message chat screen for one-on-one conversations
class DirectMessageScreen extends StatefulWidget {
  final ContactData contact;

  const DirectMessageScreen({
    super.key,
    required this.contact,
  });

  @override
  State<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  late final MessageRepository _messageRepository;
  late final ContactRepository _contactRepository;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _previousMessageCount = 0;
  int? _firstUnreadTimestamp;
  List<ContactData> _allContacts = [];
  List<ContactData> _mentionSuggestions = [];
  StreamSubscription<List<ContactData>>? _contactsSub;

  @override
  void initState() {
    super.initState();
    _messageRepository = Provider.of<MessageRepository>(context, listen: false);
    _contactRepository = Provider.of<ContactRepository>(context, listen: false);
    _contactsSub = _contactRepository.getAllContacts().listen((contacts) {
      if (mounted) setState(() => _allContacts = contacts);
    });

    // Track active chat for notification suppression
    MessageNotificationService.isMessagesScreenVisible = true;
    MessageNotificationService.activeContactHash = widget.contact.hash;

    // Get first unread timestamp for divider
    _loadFirstUnreadTimestamp();
  }

  Future<void> _loadFirstUnreadTimestamp() async {
    final timestamp = await _messageRepository.messagesDao
        .getFirstUnreadTimestampByContact(widget.contact.hash);
    setState(() {
      _firstUnreadTimestamp = timestamp;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _contactsSub?.cancel();

    // Mark all messages as read when navigating away
    _messageRepository.messagesDao
        .markContactMessagesAsRead(widget.contact.hash);

    // Clear active chat tracking
    MessageNotificationService.isMessagesScreenVisible = false;
    MessageNotificationService.activeContactHash = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipientKey = _bytesToHex(widget.contact.publicKey);
    final isRepeater = widget.contact.isRepeater;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contact.name ?? 'Unknown Contact'),
            Text(
              'Direct Message',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (isRepeater)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: theme.colorScheme.surfaceVariant,
              child: Text(
                'This contact is a repeater. Direct messages are disabled.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Messages list
          Expanded(
            child: StreamBuilder<List<MessageData>>(
              stream:
                  _messageRepository.watchPrivateMessages(widget.contact.hash),
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
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                  _previousMessageCount = messages.length;
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: theme.colorScheme.outline,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
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
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
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
                          enabled: !isRepeater,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
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
                            if (text.isNotEmpty && _firstUnreadTimestamp != null) {
                              _messageRepository.messagesDao
                                  .markContactMessagesAsRead(widget.contact.hash);
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
                    onPressed: isRepeater ? null : _sendMessage,
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

  Widget _buildMessageBubble(MessageData message, ThemeData theme) {
    final isFromMe = message.isSentByMe ?? false;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(message.timestamp);

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
            final contact = _mentionSuggestions[index];
            final name = contact.name ?? 'Unknown';
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
    if (query.isEmpty || query.contains(' ')) {
      if (_mentionSuggestions.isNotEmpty)
        setState(() => _mentionSuggestions = []);
      return;
    }
    final queryLower = query.toLowerCase();
    final filtered = _allContacts
        .where((c) => (c.name ?? '').toLowerCase().contains(queryLower))
        .toList();
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
  }

  Future<void> _sendMessage() async {
    if (widget.contact.isRepeater) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Direct messages are disabled for repeaters'),
          ),
        );
      }
      return;
    }

    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    if (content.length > 130) return;

    // Clear input immediately
    _messageController.clear();
    setState(() => _mentionSuggestions = []);

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
      final recipientKey = _bytesToHex(widget.contact.publicKey);
      final messageId = await _messageRepository.sendDirectMessage(
        recipientPublicKey: recipientKey,
        recipientHash: widget.contact.hash,
        content: content,
      );

      if (messageId != null) {
        debugPrint('✅ Message sent with ID: $messageId');
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
      debugPrint('❌ Error sending message: $e');
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
