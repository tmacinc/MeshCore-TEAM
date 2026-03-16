// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/models/sync_status.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import 'package:meshcore_team/services/message_notification_service.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import 'package:meshcore_team/repositories/contact_repository.dart';
import 'connection_screen.dart';
import 'contacts_screen.dart';
import 'channels_screen.dart';
import 'map_screen.dart';

/// Main Navigation Screen with Bottom Navigation Bar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  bool _identityDialogShowing = false;

  static const MethodChannel _appLifecycleChannel =
      MethodChannel('com.meshcore.team/app_lifecycle');

  final List<Widget> _screens = [
    const ConnectionScreen(),
    const ContactsScreen(),
    const ChannelsScreen(),
    const MapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MessageNotificationService.isAppInForeground = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        MessageNotificationService.isAppInForeground = true;
        debugPrint('📱 App resumed - notifications will be suppressed');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        MessageNotificationService.isAppInForeground = false;
        debugPrint('📱 App paused/inactive - notifications will be shown');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionVM = context.watch<ConnectionViewModel>();
    final channelRepository = context.watch<ChannelRepository>();
    final contactRepository = context.watch<ContactRepository>();
    final isConnected = connectionVM.isConnected;
    final navLocked = connectionVM.identityConfirmationRequired;
    final shouldShowIdentityDialog =
        navLocked && connectionVM.syncStatus.phase == SyncPhase.complete;

    if (navLocked && _currentIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = 0;
        });
      });
    }

    if (shouldShowIdentityDialog && !_identityDialogShowing) {
      _identityDialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _showIdentityDialog(context, connectionVM);
        if (!mounted) return;
        _identityDialogShowing = false;
      });
    }

    return WillPopScope(
      onWillPop: () async {
        // At the root of the app, Android Back would normally finish the Activity,
        // which detaches the Flutter engine and can disconnect BLE.
        // Match TEAM behavior: keep the app/service alive and move to background.
        try {
          await _appLifecycleChannel.invokeMethod('moveToBackground');
        } catch (e) {
          debugPrint('⚠️ moveToBackground failed: $e');
        }
        return false;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: StreamBuilder<_UnreadCounts>(
          stream: _getUnreadCounts(channelRepository, contactRepository),
          builder: (context, snapshot) {
            final counts = snapshot.data ?? const _UnreadCounts(0, 0);
            final contactsUnread = counts.contacts;
            final channelsUnread = counts.channels;

            final nav = BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: navLocked
                  ? null
                  : (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.bluetooth,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                  activeIcon: Icon(
                    Icons.bluetooth,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                  label: 'Connection',
                ),
                BottomNavigationBarItem(
                  icon: _buildBadgedIcon(
                    Icons.people,
                    contactsUnread,
                  ),
                  label: 'Contacts',
                ),
                BottomNavigationBarItem(
                  icon: _buildBadgedIcon(
                    Icons.chat_bubble,
                    channelsUnread,
                  ),
                  label: 'Channels',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'Map',
                ),
              ],
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
            );

            if (!navLocked) return nav;

            return Opacity(
              opacity: 0.4,
              child: IgnorePointer(
                ignoring: true,
                child: nav,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showIdentityDialog(
    BuildContext context,
    ConnectionViewModel connectionVM,
  ) async {
    final controller = TextEditingController(text: connectionVM.deviceName);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String? errorText;
        bool isSaving = false;

        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Set Identity'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This name is how you will be identified on the mesh network.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLength: 31,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        errorText: errorText,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final proposed = controller.text;
                            final trimmed = proposed.trim();
                            if (trimmed.isEmpty) {
                              setState(() {
                                errorText = 'Name cannot be empty';
                              });
                              return;
                            }

                            setState(() {
                              errorText = null;
                              isSaving = true;
                            });

                            final ok = await connectionVM
                                .confirmIdentityName(proposed);
                            if (!context.mounted) return;

                            if (ok) {
                              Navigator.of(context).pop();
                            } else {
                              setState(() {
                                errorText =
                                    'Failed to apply name. Please try again.';
                                isSaving = false;
                              });
                            }
                          },
                    child: Text(isSaving ? 'Saving...' : 'Save'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Build icon with unread badge
  Widget _buildBadgedIcon(IconData icon, int unreadCount) {
    if (unreadCount == 0) {
      return Icon(icon);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              unreadCount > 9 ? '9+' : unreadCount.toString(),
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
    );
  }

  /// Get combined unread counts for contacts and channels
  /// Matches Android MessageViewModel reactive unread tracking
  /// Uses companion-filtered channels and contacts streams
  /// Auto-switches when companion changes (handled by repositories)
  Stream<_UnreadCounts> _getUnreadCounts(
    ChannelRepository channelRepository,
    ContactRepository contactRepository,
  ) async* {
    // Manually combine both streams using a controller
    final controller = StreamController<_UnreadCounts>();

    var latestChannelsUnread = 0;
    var latestContactsUnread = 0;

    // Listen to channels with unread
    final channelsSub =
        channelRepository.watchChannelsWithUnread().listen((channels) {
      latestChannelsUnread = channels.fold<int>(
        0,
        (sum, channel) => sum + channel.unreadCount,
      );
      if (!controller.isClosed) {
        controller
            .add(_UnreadCounts(latestContactsUnread, latestChannelsUnread));
      }
    });

    // Listen to contacts with unread
    final contactsSub =
        contactRepository.watchContactsWithUnread().listen((contacts) {
      latestContactsUnread = contacts.fold<int>(
        0,
        (sum, contact) => sum + contact.unreadCount,
      );
      if (!controller.isClosed) {
        controller
            .add(_UnreadCounts(latestContactsUnread, latestChannelsUnread));
      }
    });

    // Emit initial value
    controller.add(const _UnreadCounts(0, 0));

    try {
      await for (final counts in controller.stream) {
        yield counts;
      }
    } finally {
      await channelsSub.cancel();
      await contactsSub.cancel();
      await controller.close();
    }
  }
}

/// Simple data class for unread counts
class _UnreadCounts {
  final int contacts;
  final int channels;

  const _UnreadCounts(this.contacts, this.channels);
}
