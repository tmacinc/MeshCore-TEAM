// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/models/sync_status.dart';
import 'package:meshcore_team/theme/night_theme.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';
import 'package:meshcore_team/services/message_notification_service.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/models/unread_models.dart';
import 'package:meshcore_team/models/channel_notification_mode.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import 'package:meshcore_team/repositories/contact_repository.dart';
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
  int _channelsUnread = 0;
  int _contactsUnread = 0;
  StreamSubscription<List<ChannelWithUnread>>? _channelsSub;
  StreamSubscription<List<ContactWithUnread>>? _contactsSub;

  bool _identityDialogShowing = false;


  static const MethodChannel _appLifecycleChannel =
      MethodChannel('com.meshcore.team/app_lifecycle');

  final List<Widget> _screens = [
    const ContactsScreen(),
    const ChannelsScreen(),
    const MapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MessageNotificationService.isAppInForeground = true;

    final channelRepo =
        Provider.of<ChannelRepository>(context, listen: false);
    final contactRepo =
        Provider.of<ContactRepository>(context, listen: false);

    _channelsSub = channelRepo.watchChannelsWithUnread().listen((channels) {
      if (!mounted) return;
      setState(() {
        _channelsUnread = channels
            .where((c) =>
                ChannelNotificationMode.fromString(c.channel.notificationMode) !=
                ChannelNotificationMode.muted)
            .fold(0, (sum, c) => sum + c.unreadCount);
      });
    }, onError: (Object e) {
      debugPrint('[MainNav] ⚠️ channels unread stream error: $e');
    });

    _contactsSub = contactRepo.watchContactsWithUnread().listen((contacts) {
      if (!mounted) return;
      setState(() {
        _contactsUnread =
            contacts.fold(0, (sum, c) => sum + c.unreadCount);
      });
    }, onError: (Object e) {
      debugPrint('[MainNav] ⚠️ contacts unread stream error: $e');
    });
  }

  @override
  void dispose() {
    _channelsSub?.cancel();
    _contactsSub?.cancel();
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
    final l10n = AppLocalizations.of(context)!;
    final navLocked = context.select<ConnectionViewModel, bool>(
        (vm) => vm.identityConfirmationRequired);
    final syncPhase = context.select<ConnectionViewModel, SyncPhase>(
        (vm) => vm.syncStatus.phase);
    final isNighttime = context.watch<SettingsService>().settings.appTheme ==
        AppThemeMode.nighttime;
    if (_currentIndex >= _screens.length) _currentIndex = 0;
    final shouldShowIdentityDialog =
        navLocked && syncPhase == SyncPhase.complete;

    if (shouldShowIdentityDialog && !_identityDialogShowing) {
      _identityDialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final connectionVM = context.read<ConnectionViewModel>();
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
        bottomNavigationBar: Builder(builder: (context) {
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
                icon: _buildBadgedIcon(
                  Icons.people,
                  _contactsUnread,
                  isNighttime,
                ),
                label: l10n.contacts,
              ),
              BottomNavigationBarItem(
                icon: _buildBadgedIcon(
                  Icons.chat_bubble,
                  _channelsUnread,
                  isNighttime,
                ),
                label: l10n.channels,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: l10n.map,
              ),
            ],
          );

          if (!navLocked) return nav;

          return Opacity(
            opacity: 0.4,
            child: IgnorePointer(
              ignoring: true,
              child: nav,
            ),
          );
        }),
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
        final l10n = AppLocalizations.of(context)!;
        String? errorText;
        bool isSaving = false;

        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(l10n.setIdentity),
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
                        labelText: l10n.name,
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
                    child: Text(isSaving ? 'Saving...' : l10n.save),
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
  Widget _buildBadgedIcon(IconData icon, int unreadCount, bool isNighttime) {
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
            decoration: BoxDecoration(
              color: isNighttime ? NightColors.primary : Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              unreadCount > 9 ? '9+' : unreadCount.toString(),
              style: TextStyle(
                color: isNighttime ? NightColors.onSurface : Colors.white,
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

}

