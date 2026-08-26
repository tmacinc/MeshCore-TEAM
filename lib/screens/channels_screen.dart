// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/channel_notification_mode.dart';
import 'package:meshcore_team/models/unread_models.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import 'package:meshcore_team/screens/qr_scan_screen.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/theme/night_theme.dart';
import 'package:meshcore_team/widgets/status_bar_actions.dart';
import 'package:meshcore_team/widgets/night_clock.dart';
import 'package:meshcore_team/widgets/sort_menu_button.dart';
import 'channel_chat_screen.dart';

enum _ChannelSort { messageCount, alpha, channelNumber, favoritesFirst }

/// Channels Screen
/// Displays list of synced channels from companion device
class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  _ChannelSort _sort = _ChannelSort.messageCount;
  // Positions (hash -> index) from the last message-count sort pass.
  // Used as tiebreaker so equal-count channels don't jump back to channel-index order.
  Map<int, int> _messageCountPositions = {};

  List<SortMenuOption<_ChannelSort>> _sortOptions(AppLocalizations l10n) => [
        SortMenuOption(value: _ChannelSort.messageCount, icon: Icons.mark_unread_chat_alt, label: l10n.sortByMessageCount),
        SortMenuOption(value: _ChannelSort.alpha, icon: Icons.sort_by_alpha, label: l10n.sortByName),
        SortMenuOption(value: _ChannelSort.channelNumber, icon: Icons.tag, label: l10n.sortByChannelNumber),
        SortMenuOption(value: _ChannelSort.favoritesFirst, icon: Icons.star, label: l10n.sortByFavorites),
      ];

  List<ChannelWithUnread> _applySort(List<ChannelWithUnread> channels) {
    // Muted channels always go to the bottom, sorted by channel index.
    final muted = channels
        .where((c) =>
            ChannelNotificationMode.fromString(c.channel.notificationMode) ==
            ChannelNotificationMode.muted)
        .toList()
      ..sort(
          (a, b) => a.channel.channelIndex.compareTo(b.channel.channelIndex));

    final rest = channels
        .where((c) =>
            ChannelNotificationMode.fromString(c.channel.notificationMode) !=
            ChannelNotificationMode.muted)
        .toList();

    switch (_sort) {
      case _ChannelSort.messageCount:
        final prevPositions = _messageCountPositions;
        rest.sort((a, b) {
          if (a.unreadCount != b.unreadCount) {
            return b.unreadCount.compareTo(a.unreadCount);
          }
          final ai = prevPositions[a.channel.hash];
          final bi = prevPositions[b.channel.hash];
          if (ai != null && bi != null) return ai.compareTo(bi);
          if (ai != null) return -1;
          if (bi != null) return 1;
          return a.channel.channelIndex.compareTo(b.channel.channelIndex);
        });
        _messageCountPositions = {
          for (final entry in rest.asMap().entries)
            entry.value.channel.hash: entry.key,
        };
      case _ChannelSort.alpha:
        String key(String name) =>
            name.toLowerCase().replaceFirst(RegExp(r'^#+'), '').trimLeft();
        rest.sort((a, b) => key(a.channel.name).compareTo(key(b.channel.name)));
      case _ChannelSort.channelNumber:
        rest.sort(
            (a, b) => a.channel.channelIndex.compareTo(b.channel.channelIndex));
      case _ChannelSort.favoritesFirst:
        rest.sort((a, b) {
          if (a.channel.isFavorite != b.channel.isFavorite) {
            return a.channel.isFavorite ? -1 : 1;
          }
          return a.channel.channelIndex.compareTo(b.channel.channelIndex);
        });
    }

    return [...rest, ...muted];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final channelRepository = context.watch<ChannelRepository>();
    final isNighttime = context.watch<SettingsService>().settings.appTheme ==
        AppThemeMode.nighttime;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: isNighttime ? const NightClock() : null,
        actions: [
          SortMenuButton<_ChannelSort>(
            value: _sort,
            options: _sortOptions(l10n),
            onChanged: (value) => setState(() => _sort = value),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addChannelLower,
            onPressed: () => _showAddMenu(context, channelRepository),
          ),
          const SizedBox(
            height: 24,
            child: VerticalDivider(width: 16, thickness: 1),
          ),
          const StatusBarActions(),
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
                  Text(l10n.genericError(snapshot.error.toString())),
                ],
              ),
            );
          }

          final channelsWithUnread = _applySort(snapshot.data ?? []);

          if (channelsWithUnread.isEmpty) {
            final emptyColor = Theme.of(context).colorScheme.outline;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: emptyColor),
                  const SizedBox(height: 16),
                  Text(
                    'No channels',
                    style: TextStyle(fontSize: 18, color: emptyColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect to a device and sync to see channels',
                    style: TextStyle(color: emptyColor),
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
        final sheetL10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(sheetL10n.createPrivateChannel),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showCreateChannelDialog(context, channelRepository);
                },
              ),
              ListTile(
                leading: const Icon(Icons.tag),
                title: Text(sheetL10n.joinHashtagChannel),
                subtitle: Text(sheetL10n.deriveKeyFromName),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showJoinHashtagChannelDialog(context, channelRepository);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: Text(sheetL10n.addViaLinkQr),
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
                    SnackBar(content: Text(AppLocalizations.of(context)!.channelCreated(created.name))),
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
              title: Text(AppLocalizations.of(dialogContext)!.createPrivateChannel),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !isCreating,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(dialogContext)!.channelName,
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
                  child: Text(AppLocalizations.of(dialogContext)!.cancel),
                ),
                FilledButton(
                  onPressed: isCreating ? null : create,
                  child: Text(AppLocalizations.of(dialogContext)!.create),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showJoinHashtagChannelDialog(
      BuildContext context, ChannelRepository channelRepository) async {
    final controller = TextEditingController(text: '#');
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        bool isJoining = false;
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> join() async {
              if (isJoining) return;
              setState(() {
                isJoining = true;
              });
              try {
                final joined =
                    await channelRepository.createHashtagChannel(controller.text);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.channelJoined(joined.name))),
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
                    isJoining = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: Text(AppLocalizations.of(dialogContext)!.joinHashtagChannel),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !isJoining,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(dialogContext)!.channelName,
                      hintText: AppLocalizations.of(dialogContext)!.publicChannelName,
                      helperText:
                          'Anyone who types the same name joins the same channel',
                    ),
                    onSubmitted: (_) => join(),
                  ),
                  if (isJoining) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isJoining ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalizations.of(dialogContext)!.cancel),
                ),
                FilledButton(
                  onPressed: isJoining ? null : join,
                  child: Text(AppLocalizations.of(dialogContext)!.join),
                ),
              ],
            );
          },
        );
      },
    );
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
            SnackBar(content: Text(AppLocalizations.of(context)!.invalidChannelLinkKey)),
          );
        }
        return;
      }

      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.channelAdded(imported.name))),
        );
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(dialogContext)!.addChannel),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameOrUrlController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(dialogContext)!.nameOrLink,
                        hintText: AppLocalizations.of(dialogContext)!.meshcoreChannelAddPlaceholder,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: keyOrUrlController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(dialogContext)!.secretOrLink,
                        hintText: AppLocalizations.of(dialogContext)!.hexCharsOrBase64,
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
                                SnackBar(
                                    content: Text(AppLocalizations.of(context)!.cameraPermissionRequired)),
                              );
                            }
                            return;
                          }

                          final scanned = await Navigator.of(context).push(
                            MaterialPageRoute<String>(
                              builder: (_) => QrScanScreen(
                                title: AppLocalizations.of(context)!.scanChannelQr,
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
                        label: Text(AppLocalizations.of(dialogContext)!.scanQrCode),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalizations.of(dialogContext)!.cancel),
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
                  child: Text(AppLocalizations.of(dialogContext)!.add),
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

  void _showChannelOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<ChannelRepository>();
    final mode = ChannelNotificationMode.fromString(channel.notificationMode);
    final isPublic = channel.isPublic;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.channelNotifications,
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
              ),
              _NotificationModeOption(
                label: l10n.notificationModeNormal,
                description: l10n.notificationModeNormalDesc,
                icon: Icons.notifications,
                selected: mode == ChannelNotificationMode.normal,
                onTap: () {
                  Navigator.of(ctx).pop();
                  repo.setNotificationMode(channel.hash, 'normal');
                },
              ),
              _NotificationModeOption(
                label: l10n.notificationModeSilent,
                description: l10n.notificationModeSilentDesc,
                icon: Icons.notifications_off,
                selected: mode == ChannelNotificationMode.silent,
                onTap: () {
                  Navigator.of(ctx).pop();
                  repo.setNotificationMode(channel.hash, 'silent');
                },
              ),
              _NotificationModeOption(
                label: l10n.notificationModeMuted,
                description: l10n.notificationModeMutedDesc,
                icon: Icons.volume_off,
                selected: mode == ChannelNotificationMode.muted,
                onTap: () {
                  Navigator.of(ctx).pop();
                  repo.setNotificationMode(channel.hash, 'muted');
                },
              ),
              if (!isPublic) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    l10n.deleteChannel,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showDeleteDialog(context, repo);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteDialog(
      BuildContext context, ChannelRepository repo) async {
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
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .channelDeleted(channel.name))),
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
              title: Text(AppLocalizations.of(dialogContext)!.deleteChannel),
              content: Text(
                'Delete "${channel.name}" from the companion and this phone?\n\nThis cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed:
                      isDeleting ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalizations.of(dialogContext)!.cancel),
                ),
                FilledButton(
                  onPressed: isDeleting ? null : doDelete,
                  child: isDeleting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(dialogContext)!.delete),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPublic = channel.isPublic;
    final isNighttime = context.watch<SettingsService>().settings.appTheme ==
        AppThemeMode.nighttime;
    final mode = ChannelNotificationMode.fromString(channel.notificationMode);
    final isMuted = mode == ChannelNotificationMode.muted;
    final isSilent = mode == ChannelNotificationMode.silent;
    final showBadge = unreadCount > 0 && !isMuted;

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
      child: GestureDetector(
        onLongPress: () => _showChannelOptions(context),
        onSecondaryTap: () => _showChannelOptions(context),
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: isNighttime
                    ? (isPublic
                        ? NightColors.connectStale
                        : NightColors.surfaceHigh)
                    : (isPublic ? Colors.green : Colors.blue),
                child: Icon(
                  isPublic ? Icons.public : Icons.lock,
                  color: isNighttime ? NightColors.onSurface : Colors.white,
                ),
              ),
              if (showBadge)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isNighttime ? NightColors.primary : Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color:
                            isNighttime ? NightColors.onSurface : Colors.white,
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
              fontWeight:
                  showBadge ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.channelHash(channel.hash.toRadixString(16))),
              Text(l10n.channelIndex(channel.channelIndex.toString())),
              Text(isPublic ? l10n.channelTypePublic : l10n.channelTypePrivate),
              if (isMuted) Text(l10n.notificationsMuted),
              if (isSilent) Text(l10n.notificationsSilent),
              if (isTelemetryChannel)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on,
                        size: 14,
                        color: isNighttime ? NightColors.primary : Colors.blue),
                    const SizedBox(width: 2),
                    Text(l10n.locationSharingOn),
                  ],
                )
              else if (!settings.telemetryEnabled &&
                  channel.hash == telemetryHashInt)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off,
                        size: 14,
                        color: isNighttime ? NightColors.dimmer : Colors.grey),
                    const SizedBox(width: 2),
                    Text(l10n.locationSharingOff),
                  ],
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => context
                    .read<ChannelRepository>()
                    .setFavorite(channel.hash, !channel.isFavorite),
                child: Icon(
                  channel.isFavorite ? Icons.star : Icons.star_border,
                  color: channel.isFavorite
                      ? (isNighttime ? NightColors.primary : Colors.amber)
                      : (isNighttime ? NightColors.dimmer : Colors.grey),
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPublic ? Icons.public : Icons.group,
                    color: isNighttime
                        ? (isPublic
                            ? NightColors.connectStale
                            : NightColors.onSurfaceVariant)
                        : (isPublic ? Colors.green : Colors.blue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ch${channel.channelIndex}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
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
      ),
    );
  }
}

class _NotificationModeOption extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NotificationModeOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? colorScheme.primary : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? colorScheme.primary : null,
        ),
      ),
      subtitle: Text(description),
      trailing: selected ? Icon(Icons.check, color: colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}
