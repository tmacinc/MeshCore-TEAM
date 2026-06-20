// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/unread_models.dart';
import 'package:meshcore_team/repositories/contact_repository.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/theme/night_theme.dart';
import 'package:meshcore_team/widgets/app_menu_button.dart';
import 'package:meshcore_team/widgets/bt_status_icon.dart';
import 'package:meshcore_team/widgets/network_status_icons.dart';
import 'package:meshcore_team/widgets/night_clock.dart';
import 'direct_message_screen.dart';

/// Contacts Screen
/// Displays list of synced contacts from companion device
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contactRepository = context.watch<ContactRepository>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: NightTitle(title: 'Contacts'),
        actions: [
          const NetworkStatusIcons(),
          const BtStatusIcon(),
          const AppMenuButton(),
        ],
      ),
      // Repository handles companion filtering automatically
      body: StreamBuilder<List<ContactWithUnread>>(
        stream: contactRepository.watchContactsWithUnread(),
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

          final contactsWithUnread = snapshot.data ?? [];

          if (contactsWithUnread.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No contacts',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Connect to a device and sync to see contacts',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: contactsWithUnread.length,
            itemBuilder: (context, index) {
              final contactWithUnread = contactsWithUnread[index];
              return ContactListTile(
                contact: contactWithUnread.contact,
                unreadCount: contactWithUnread.unreadCount,
              );
            },
          );
        },
      ),
    );
  }
}

class ContactListTile extends StatelessWidget {
  final ContactData contact;
  final int unreadCount;

  const ContactListTile({
    super.key,
    required this.contact,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = contact.latitude != null && contact.longitude != null;
    final lastSeenText = _formatLastSeen(contact.lastSeen);
    final isNighttime = context.watch<SettingsService>().settings.appTheme ==
        AppThemeMode.nighttime;

    final minutesSinceLastSeen =
        (DateTime.now().millisecondsSinceEpoch - contact.lastSeen).toDouble();
    final connectivityColor =
        _getConnectivityColor(minutesSinceLastSeen.toInt(), isNighttime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: connectivityColor,
              child: Text(
                contact.name?.isNotEmpty == true
                    ? contact.name!.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  color: isNighttime ? NightColors.onSurface : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.name ?? 'Unknown',
                style: TextStyle(
                  fontWeight:
                      unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (contact.isRepeater)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  'REPEATER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hash: ${contact.hash.toRadixString(16)}'),
            if (contact.isRepeater)
              const Text(
                'Repeater',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            Text('Last seen: $lastSeenText'),
            if (hasLocation)
              Text(
                  'Location: ${contact.latitude!.toStringAsFixed(4)}, ${contact.longitude!.toStringAsFixed(4)}'),
            if (contact.companionBatteryMilliVolts != null)
              Text(
                  'Battery: ${(contact.companionBatteryMilliVolts! / 1000).toStringAsFixed(2)}V'),
          ],
        ),
        trailing: hasLocation
            ? Icon(Icons.location_on,
                color: isNighttime ? NightColors.primary : Colors.blue)
            : Icon(Icons.location_off,
                color: isNighttime ? NightColors.dimmer : Colors.grey),
        onTap: () {
          if (contact.isRepeater) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Direct messages are disabled for repeaters'),
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DirectMessageScreen(contact: contact),
            ),
          );
        },
      ),
    );
  }

  String _formatLastSeen(int timestamp) {
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Color _getConnectivityColor(int millisSinceLastSeen, bool isNighttime) {
    final minutesSince = millisSinceLastSeen / 60000.0;

    if (isNighttime) {
      if (minutesSince < 1) return NightColors.connectJustSeen;
      if (minutesSince < 5) return NightColors.connectRecent;
      if (minutesSince < 10) return NightColors.connectStale;
      if (minutesSince < 30) return NightColors.connectOffline;
      return NightColors.connectOutOfRange;
    }

    if (minutesSince < 1) return Colors.green;
    if (minutesSince < 5) return Colors.yellow;
    if (minutesSince < 10) return Colors.orange;
    if (minutesSince < 30) return Colors.red;
    return Colors.grey;
  }
}
