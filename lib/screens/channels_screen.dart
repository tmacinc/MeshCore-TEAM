// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/unread_models.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import 'package:meshcore_team/screens/qr_scan_screen.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'channel_chat_screen.dart';

/// Channels Screen
/// Displays list of synced channels from companion device
class ChannelsScreen extends StatelessWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final channelRepository = context.watch<ChannelRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add channel',
            onPressed: () => _showAddMenu(context, channelRepository),
          ),
        ],
      ),
      body: StreamBuilder<List<ChannelWithUnread>>(
        stream: channelRepository.watchChannelsWithUnread(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final channelsWithUnread = snapshot.data ?? [];

          if (channelsWithUnread.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No channels',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Connect to a device and sync to see channels',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: channelsWithUnread.length,
            itemBuilder: (context, index) {
              final channelWithUnread = channelsWithUnread[index];
              return ChannelListTile(
                channel: channelWithUnread.channel,
                unreadCount: channelWithUnread.unreadCount,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddMenu(
      BuildContext context, ChannelRepository channelRepository) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Create Private Channel'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showCreateChannelDialog(context, channelRepository);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Add via Link / QR Code'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showImportChannelDialog(context, channelRepository);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateChannelDialog(
      BuildContext context, ChannelRepository channelRepository) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        bool isCreating = false;
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> create() async {
              if (isCreating) return;
              setState(() {
                isCreating = true;
              });
              final name = controller.text;
              try {
                final created =
                    await channelRepository.createPrivateChannel(name);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created: ${created.name}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
                if (dialogContext.mounted) {
                  setState(() {
                    isCreating = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('Create Private Channel'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !isCreating,
                    decoration: const InputDecoration(
                      labelText: 'Channel name',
                    ),
                    onSubmitted: (_) => create(),
                  ),
                  if (isCreating) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isCreating
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isCreating ? null : create,
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
    // Controllers are method-local and will be GC'd; explicit disposal
    // races with the dialog exit animation and causes _dependents.isEmpty
    // assertions, so we intentionally skip it.
  }

  Future<void> _showImportChannelDialog(
      BuildContext context, ChannelRepository channelRepository) async {
    final nameOrUrlController = TextEditingController();
    final keyOrUrlController = TextEditingController();

    Future<void> runImport(BuildContext dialogContext) async {
      final imported = await channelRepository.importChannel(
        nameOrUrlController.text,
        keyOrUrlController.text,
      );

      if (imported == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid channel link / key')),
          );
        }
        return;
      }

      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added: ${imported.name}')),
        );
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Add Channel'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameOrUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Name or Link',
                        hintText: 'meshcore://channel/add?...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: keyOrUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Secret or Link',
                        hintText: '32 hex chars or base64',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          final status = await Permission.camera.request();
                          if (!status.isGranted) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Camera permission required')),
                              );
                            }
                            return;
                          }

                          final scanned = await Navigator.of(context).push(
                            MaterialPageRoute<String>(
                              builder: (_) => const QrScanScreen(
                                title: 'Scan Channel QR',
                              ),
                            ),
                          );
                          if (scanned == null || scanned.isEmpty) return;

                          // TEAM behavior: if QR is a meshcore URL, import immediately.
                          if (scanned.startsWith('meshcore://channel/add?')) {
                            nameOrUrlController.text = scanned;
                            keyOrUrlController.text = '';
                            setState(() {});
                            await runImport(dialogContext);
                            return;
                          }

                          nameOrUrlController.text = scanned;
                          setState(() {});
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    try {
                      await runImport(dialogContext);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
    // Controllers are method-local and will be GC'd; explicit disposal
    // races with the dialog exit animation and causes _dependents.isEmpty
    // assertions, so we intentionally skip it.
  }
}

class ChannelListTile extends StatelessWidget {
  final ChannelData channel;
  final int unreadCount;

  const ChannelListTile({
    super.key,
    required this.channel,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final isPublic = channel.isPublic;
    final createdText = _formatCreatedAt(channel.createdAt);

    // Determine if this channel is the active telemetry channel.
    final settings = context.watch<SettingsService>().settings;
    final telemetryHashHex = settings.telemetryChannelHash;
    int? telemetryHashInt;
    if (telemetryHashHex != null && telemetryHashHex.isNotEmpty) {
      final cleaned =
          telemetryHashHex.trim().toLowerCase().replaceFirst('0x', '');
      telemetryHashInt = int.tryParse(cleaned, radix: 16);
    }
    final isTelemetryChannel =
        settings.telemetryEnabled && channel.hash == telemetryHashInt;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: isPublic ? Colors.green : Colors.blue,
              child: Icon(
                isPublic ? Icons.public : Icons.lock,
                color: Colors.white,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          channel.name.isNotEmpty ? channel.name : 'Unnamed Channel',
          style: TextStyle(
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hash: ${channel.hash.toRadixString(16)}'),
            Text('Index: ${channel.channelIndex}'),
            Text('Created: $createdText'),
            Text('Type: ${isPublic ? 'Public' : 'Private'}'),
            if (channel.muteNotifications) const Text('🔕 Notifications muted'),
            if (isTelemetryChannel)
              const Text('📍 Location sharing on')
            else if (!settings.telemetryEnabled &&
                channel.hash == telemetryHashInt)
              const Text('📍 Location sharing off'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPublic ? Icons.public : Icons.group,
                  color: isPublic ? Colors.green : Colors.blue,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ch${channel.channelIndex}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (!isPublic) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Channel actions',
                onSelected: (value) async {
                  if (value != 'delete') return;

                  final repo = context.read<ChannelRepository>();

                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) {
                      bool isDeleting = false;
                      return StatefulBuilder(
                        builder: (dialogContext, setState) {
                          Future<void> doDelete() async {
                            if (isDeleting) return;
                            setState(() => isDeleting = true);
                            try {
                              await repo.deletePrivateChannel(channel);
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Deleted: ${channel.name}')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                              if (dialogContext.mounted) {
                                setState(() => isDeleting = false);
                              }
                            }
                          }

                          return AlertDialog(
                            title: const Text('Delete Channel?'),
                            content: Text(
                              'Delete "${channel.name}" from the companion and this phone?\n\nThis cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: isDeleting
                                    ? null
                                    : () => Navigator.of(dialogContext).pop(),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: isDeleting ? null : doDelete,
                                child: isDeleting
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChannelChatScreen(channel: channel),
            ),
          );
        },
      ),
    );
  }

  String _formatCreatedAt(int timestamp) {
    final created = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(created);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }
}
