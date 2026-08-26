// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/database/database.dart';
import '../l10n/app_localizations.dart';
import 'package:meshcore_team/models/unread_models.dart';
import 'package:meshcore_team/repositories/contact_repository.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/theme/night_theme.dart';
import 'package:meshcore_team/widgets/status_bar_actions.dart';
import 'package:meshcore_team/widgets/night_clock.dart';
import 'package:meshcore_team/widgets/sort_menu_button.dart';
import 'direct_message_screen.dart';

enum _ContactFilter { endNodes, repeaters, hasLocation, noLocation, favorites }

enum _SortOrder { lastSeen, name, favoritesFirst }

class _ContactFilterOption {
  final _ContactFilter value;
  final IconData icon;
  final String label;

  const _ContactFilterOption(this.value, this.icon, this.label);
}

/// Contacts Screen
/// Displays list of synced contacts from companion device
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  Set<_ContactFilter> _filter = {};
  _SortOrder _sort = _SortOrder.lastSeen;
  bool _searching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContactWithUnread> _applyFilterAndSort(List<ContactWithUnread> all) {
    // Type chips (End Nodes, Repeaters) are OR'd; Favorites is AND'd on top.
    final hasType = _filter.contains(_ContactFilter.endNodes) ||
        _filter.contains(_ContactFilter.repeaters);

    final typeFiltered = hasType
        ? all.where((c) {
            if (_filter.contains(_ContactFilter.repeaters) && c.contact.isRepeater) return true;
            if (_filter.contains(_ContactFilter.endNodes) && !c.contact.isRepeater && !c.contact.isRoomServer) return true;
            return false;
          }).toList()
        : all;

    final hasLoc = _filter.contains(_ContactFilter.hasLocation);
    final noLoc = _filter.contains(_ContactFilter.noLocation);
    final locFiltered = (hasLoc || noLoc) && !(hasLoc && noLoc)
        ? typeFiltered.where((c) {
            final loc = c.contact.latitude != null;
            return hasLoc ? loc : !loc;
          }).toList()
        : typeFiltered;

    final filtered = _filter.contains(_ContactFilter.favorites)
        ? locFiltered.where((c) => c.contact.isFavorite).toList()
        : locFiltered;

    final q = _searchQuery.trim().toLowerCase();
    final searched = q.isEmpty
        ? filtered
        : filtered.where((c) {
            final name = (c.contact.name ?? '').toLowerCase();
            final hash = c.contact.hash.toRadixString(16).toLowerCase();
            return name.contains(q) || hash.contains(q);
          }).toList();

    if (_sort == _SortOrder.lastSeen) return searched;

    final sorted = [...searched];
    if (_sort == _SortOrder.name) {
      sorted.sort((a, b) {
        final aName = (a.contact.name ?? '').toLowerCase();
        final bName = (b.contact.name ?? '').toLowerCase();
        return aName.compareTo(bName);
      });
    } else if (_sort == _SortOrder.favoritesFirst) {
      sorted.sort((a, b) {
        if (a.contact.isFavorite == b.contact.isFavorite) return 0;
        return a.contact.isFavorite ? -1 : 1;
      });
    }
    return sorted;
  }

  List<SortMenuOption<_SortOrder>> _sortOptions(AppLocalizations l10n) => [
    SortMenuOption(value: _SortOrder.lastSeen, icon: Icons.access_time, label: l10n.sortByLastSeen),
    SortMenuOption(value: _SortOrder.name, icon: Icons.sort_by_alpha, label: l10n.sortByName),
    SortMenuOption(value: _SortOrder.favoritesFirst, icon: Icons.star, label: l10n.sortByFavorites),
  ];

  List<_ContactFilterOption> _filterOptions(AppLocalizations l10n) => [
    _ContactFilterOption(_ContactFilter.endNodes, Icons.person, l10n.filterEndNodes),
    _ContactFilterOption(_ContactFilter.repeaters, Icons.device_hub, l10n.filterRepeaters),
    _ContactFilterOption(_ContactFilter.hasLocation, Icons.location_on, l10n.filterHasLocation),
    _ContactFilterOption(_ContactFilter.noLocation, Icons.location_off, l10n.filterNoLocation),
    _ContactFilterOption(_ContactFilter.favorites, Icons.star, l10n.sortByFavorites),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contactRepository = context.watch<ContactRepository>();
    final isNighttime = context.watch<SettingsService>().settings.appTheme ==
        AppThemeMode.nighttime;

    return StreamBuilder<List<ContactWithUnread>>(
      stream: contactRepository.watchContactsWithUnread(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final contacts = _applyFilterAndSort(all);

        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: isNighttime ? const NightClock() : null,
            actions: [
              _buildFilterButton(l10n),
              SortMenuButton<_SortOrder>(
                value: _sort,
                options: _sortOptions(l10n),
                onChanged: (value) => setState(() => _sort = value),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: l10n.search,
                onPressed: _searching ? null : () => setState(() => _searching = true),
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
              _buildSearchRow(l10n),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
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

                    if (all.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noContacts,
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.connectToDeviceToSeeContacts,
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (contacts.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.noContactsMatchFilter,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contactWithUnread = contacts[index];
                        return ContactListTile(
                          contact: contactWithUnread.contact,
                          unreadCount: contactWithUnread.unreadCount,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchRow(AppLocalizations l10n) {
    if (!_searching) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.search,
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              _searching = false;
              _searchQuery = '';
              _searchController.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final anyActive = _filter.isNotEmpty;

    return MenuAnchor(
      builder: (context, controller, child) => IconButton(
        icon: Icon(
          Icons.tune,
          color: anyActive ? colorScheme.primary : null,
        ),
        tooltip: l10n.filterContacts,
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in _filterOptions(l10n))
                CheckboxListTile(
                  value: _filter.contains(option.value),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: Icon(option.icon),
                  title: Text(option.label),
                  onChanged: (checked) => setState(() {
                    _filter = checked == true
                        ? (Set.of(_filter)..add(option.value))
                        : (Set.of(_filter)..remove(option.value));
                  }),
                ),
              if (anyActive)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.filter_alt_off),
                  title: Text(l10n.clearFilters),
                  onTap: () => setState(() => _filter = {}),
                ),
            ],
          ),
        ),
      ],
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
    final l10n = AppLocalizations.of(context)!;
    final contactRepository = context.read<ContactRepository>();
    final hasLocation = contact.latitude != null && contact.longitude != null;
    final lastSeenText = _formatLastSeen(contact.lastSeen);
    final isNighttime = context.watch<SettingsService>().settings.appTheme ==
        AppThemeMode.nighttime;

    final minutesSinceLastSeen =
        (DateTime.now().millisecondsSinceEpoch - contact.lastSeen).toDouble();
    final connectivityColor =
        _getConnectivityColor(minutesSinceLastSeen.toInt(), isNighttime);

    return GestureDetector(
      onLongPress: () => _showContactOptions(context),
      onSecondaryTap: () => _showContactOptions(context),
      child: Card(
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
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isNighttime
                      ? NightColors.onSurfaceVariant
                      : Colors.blueGrey,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  contact.isRepeater ? Icons.device_hub : contact.isRoomServer ? Icons.meeting_room : Icons.person,
                  size: 13,
                  color: isNighttime ? NightColors.surface : Colors.white,
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
                contact.name ?? l10n.unknown,
                style: TextStyle(
                  fontWeight:
                      unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (contact.isRepeater)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  l10n.repeaterLabel,
                  style: const TextStyle(
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
            Text(l10n.channelHash(contact.hash.toRadixString(16))),
            Text(l10n.lastSeen(lastSeenText)),
            if (hasLocation)
              Text(l10n.locationCoordinates(
                  contact.latitude!.toStringAsFixed(4),
                  contact.longitude!.toStringAsFixed(4))),
            if (contact.companionBatteryMilliVolts != null)
              Text(l10n.batteryVoltage(
                  (contact.companionBatteryMilliVolts! / 1000)
                      .toStringAsFixed(2))),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => contactRepository.setFavorite(
                  contact.publicKey, !contact.isFavorite),
              child: Icon(
                contact.isFavorite ? Icons.star : Icons.star_border,
                color: contact.isFavorite
                    ? (isNighttime ? NightColors.primary : Colors.amber)
                    : (isNighttime ? NightColors.dimmer : Colors.grey),
                size: 22,
              ),
            ),
            const SizedBox(width: 4),
            hasLocation
                ? Icon(Icons.location_on,
                    color: isNighttime ? NightColors.primary : Colors.blue)
                : Icon(Icons.location_off,
                    color: isNighttime ? NightColors.dimmer : Colors.grey),
          ],
        ),
        onTap: () {
          if (contact.isRepeater || contact.isRoomServer) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.directMessagesDisabledForRepeaters),
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
    ),
    );
  }

  void _showContactOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<ContactRepository>();
    final name = contact.name ?? l10n.unknown;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy contact info'),
              onTap: () {
                Navigator.of(ctx).pop();
                final hash = contact.hash.toRadixString(16);
                final lines = <String>[
                  'Name: $name',
                  'Hash: $hash',
                  if (contact.latitude != null && contact.longitude != null)
                    'Location: ${contact.latitude!.toStringAsFixed(6)}, ${contact.longitude!.toStringAsFixed(6)}',
                  if (contact.companionBatteryMilliVolts != null)
                    'Battery: ${(contact.companionBatteryMilliVolts! / 1000).toStringAsFixed(2)}V',
                  'Type: ${contact.isRepeater ? 'Repeater' : contact.isRoomServer ? 'Room Server' : 'End Node'}',
                ];
                Clipboard.setData(ClipboardData(text: lines.join('\n')));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact info copied')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                l10n.deleteContact,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.of(ctx).pop();
                await repo.deleteContact(contact);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.contactDeletedName(name))),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(int timestamp) {
    final now = DateTime.now();
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = lastSeen.isAfter(now) ? Duration.zero : now.difference(lastSeen);

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
