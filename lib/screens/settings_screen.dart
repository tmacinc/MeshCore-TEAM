// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'dart:io' show Platform;

import 'package:material_ui/material_ui.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:meshcore_team/models/app_language.dart';
import 'package:meshcore_team/models/app_settings.dart';
import 'package:meshcore_team/models/capability_message.dart';
import 'package:meshcore_team/models/channel.dart' show ChannelDataKind;
import 'package:meshcore_team/widgets/add_channel_to_radio.dart';
import 'package:meshcore_team/repositories/channel_repository.dart';
import 'package:meshcore_team/services/settings_service.dart';
import 'package:meshcore_team/viewmodels/connection_viewmodel.dart';

const MethodChannel _appLifecycleChannel =
    MethodChannel('com.meshcore.team/app_lifecycle');

/// Stable ids for the collapsible sections of the settings screen.
///
/// Persisted in [AppSettings.collapsedSettingsSections], so these strings are
/// storage keys: renaming one silently resets that section to expanded. They
/// are deliberately independent of the localized section titles.
class SettingsSection {
  static const String appearance = 'appearance';
  static const String location = 'location';
  static const String data = 'data';
  static const String android = 'android';
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(l10n.settings),
        actions: const [],
      ),
      body: ListView(
        children: [
          _buildTeamNameCard(context, l10n, settings),
          const Divider(height: 1),
          _buildSection(
            context: context,
            settings: settings,
            id: SettingsSection.appearance,
            title: l10n.appearance,
            children: _appearanceChildren(l10n, settings),
          ),
          const Divider(height: 1),
          _buildSection(
            context: context,
            settings: settings,
            id: SettingsSection.location,
            title: l10n.location,
            children: _locationChildren(l10n, settings),
          ),
          const Divider(height: 1),
          _buildSection(
            context: context,
            settings: settings,
            id: SettingsSection.data,
            title: l10n.data,
            children: [_buildAutoPurgeCard(context, l10n, settings)],
          ),
          if (Platform.isAndroid) ...[
            const Divider(height: 1),
            _buildSection(
              context: context,
              settings: settings,
              id: SettingsSection.android,
              title: l10n.android,
              children: _androidChildren(l10n, settings),
            ),
          ],
        ],
      ),
    );
  }

  /// A collapsible settings section.
  ///
  /// [id] is a stable [SettingsSection] constant, not the localized [title] —
  /// the remembered collapse state has to survive a language change.
  Widget _buildSection({
    required BuildContext context,
    required SettingsService settings,
    required String id,
    required String title,
    required List<Widget> children,
  }) {
    final isCollapsed =
        settings.settings.collapsedSettingsSections.contains(id);

    return ExpansionTile(
      // Keyed so the tile keeps its open/closed state as the surrounding
      // ListView rebuilds (every settings change notifies this screen).
      key: PageStorageKey<String>(id),
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      // Read once on first build; afterwards ExpansionTile owns the live state
      // and onExpansionChanged writes it back.
      initiallyExpanded: !isCollapsed,
      onExpansionChanged: (expanded) =>
          settings.setSettingsSectionCollapsed(id, !expanded),
      // The screen separates sections with its own Dividers; suppress the
      // default M3 expanded/collapsed borders so the lines don't double up.
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  List<Widget> _appearanceChildren(
      AppLocalizations l10n, SettingsService settings) {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: l10n.theme),
            value: settings.settings.appTheme,
            items: [
              DropdownMenuItem(
                value: AppThemeMode.system,
                child: Row(children: [
                  const Icon(Icons.brightness_auto, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.themeSystemDefault),
                ]),
              ),
              DropdownMenuItem(
                value: AppThemeMode.light,
                child: Row(children: [
                  const Icon(Icons.light_mode, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.themeLight),
                ]),
              ),
              DropdownMenuItem(
                value: AppThemeMode.dark,
                child: Row(children: [
                  const Icon(Icons.dark_mode, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.themeDark),
                ]),
              ),
              DropdownMenuItem(
                value: AppThemeMode.nighttime,
                child: Row(children: [
                  const Icon(Icons.nightlight_round, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.redLightDiscipline),
                ]),
              ),
            ],
            onChanged: (v) => settings.setAppTheme(v!),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: l10n.language),
            value: settings.settings.localeCode,
            items: [
              DropdownMenuItem(
                value: AppLanguage.systemDefault,
                child: Row(children: [
                  const Icon(Icons.language, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.languageDeviceDefault),
                ]),
              ),
              // Endonyms, matching the first-launch picker: a language
              // name is most useful to the person who reads it.
              for (final language in AppLanguage.all)
                DropdownMenuItem(
                  value: language.code,
                  child: Row(children: [
                    const SizedBox(width: 26),
                    Text(language.endonym),
                  ]),
                ),
            ],
            onChanged: (v) => settings.setLocaleCode(v!),
          ),
        ),
      ),
    ];
  }

  List<Widget> _locationChildren(
      AppLocalizations l10n, SettingsService settings) {
    return [
      Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(l10n.locationSource,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            RadioListTile<String>(
              title: Text(l10n.phoneGps),
              value: LocationSource.phone,
              groupValue: settings.settings.locationSource,
              onChanged: (v) => _setLocationSource(settings, v!),
            ),
            RadioListTile<String>(
              title: Text(l10n.companionGps),
              subtitle: Text(l10n.phoneFallback),
              value: LocationSource.companion,
              groupValue: settings.settings.locationSource,
              onChanged: (v) => _setLocationSource(settings, v!),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      _buildLocationTrackingCard(settings),
      if (Platform.isIOS) ...[
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            onTap: () => _showBackgroundLocationDialog(settings),
            leading: Icon(settings.settings.backgroundLocationEnabled
                ? Icons.my_location
                : Icons.location_disabled),
            title: Text(l10n.alwaysOnLocation,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(settings.settings.backgroundLocationEnabled
                ? l10n.locationEnabledBackground
                : l10n.disabled),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    ];
  }

  List<Widget> _androidChildren(
      AppLocalizations l10n, SettingsService settings) {
    return [
      Card(
        child: ListTile(
          onTap: () => _toggleKeepScreenOnLock(settings),
          leading: Icon(settings.settings.keepScreenOnLock
              ? Icons.screen_lock_portrait
              : Icons.screen_lock_portrait_outlined),
          title: Text(l10n.keepScreenOn,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(settings.settings.keepScreenOnLock
              ? l10n.keepScreenOnEnabled
              : l10n.disabled),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    ];
  }

  static const _purgeDayOptions = [7, 14, 30, 60, 90, 180, 365, 0];

  /// The team name, kept next to nothing else: it is the one name the user
  /// picks for themselves, and it is separate from the radio name shown on
  /// the Connection screen.
  Widget _buildTeamNameCard(BuildContext context, AppLocalizations l10n,
      SettingsService settingsService) {
    final alias = settingsService.settings.teamAlias;
    final radioName = context.watch<ConnectionViewModel>().deviceName.trim();

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: ListTile(
        leading: const Icon(Icons.badge_outlined),
        title: Text(l10n.teamNameSettingsTitle),
        subtitle: Text(
          alias != null && alias.isNotEmpty
              ? alias
              : l10n.teamNameUsingRadioName(
                  radioName.isEmpty ? l10n.unknown : radioName),
        ),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => _showTeamNameDialog(context, settingsService, radioName),
      ),
    );
  }

  Future<void> _showTeamNameDialog(
    BuildContext context,
    SettingsService settingsService,
    String radioName,
  ) async {
    final controller =
        TextEditingController(text: settingsService.settings.teamAlias ?? '');

    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l10n.teamName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: CapabilityMessage.maxAliasBytes,
                decoration: InputDecoration(
                  labelText: l10n.teamName,
                  hintText: radioName.isEmpty ? null : radioName,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.teamNameSaveExplanation),
              const SizedBox(height: 8),
              Text(l10n.teamNameSkipExplanation),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    // Typing the radio name means the same as leaving it blank.
    await settingsService.setTeamAlias(result == radioName ? null : result);
  }

  Widget _buildAutoPurgeCard(BuildContext context, AppLocalizations l10n,
      SettingsService settingsService) {
    final days = settingsService.settings.contactAutoPurgeDays;
    final sliderIndex = () {
      final idx = _purgeDayOptions.indexOf(days);
      return idx < 0 ? _purgeDayOptions.length - 1 : idx;
    }();
    final label = days == 0
        ? l10n.autoPurgeContactsNever
        : l10n.autoPurgeContactsDays(days);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.autoPurgeContacts,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(label,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            Slider(
              value: sliderIndex.toDouble(),
              min: 0,
              max: (_purgeDayOptions.length - 1).toDouble(),
              divisions: _purgeDayOptions.length - 1,
              onChanged: (v) {
                final selected = _purgeDayOptions[v.round()];
                settingsService.setContactAutoPurgeDays(selected);
              },
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _toggleKeepScreenOnLock(SettingsService settingsService) async {
    final enabled = !settingsService.settings.keepScreenOnLock;
    await settingsService.setKeepScreenOnLock(enabled);
    try {
      await _appLifecycleChannel
          .invokeMethod('setShowOverLockScreen', {'enabled': enabled});
    } catch (e) {
      debugPrint('[KeepScreenOnLock] platform channel error: $e');
    }
  }

  Future<void> _setLocationSource(SettingsService settingsService, String source) async {
    await settingsService.setLocationSource(source);
    final connectionVM = context.read<ConnectionViewModel>();
    if (!connectionVM.isConnected) return;
    final autonomousEnabled = connectionVM.currentAutonomousEnabled ?? false;
    final needsGps = source == LocationSource.companion || autonomousEnabled;
    final ok = await connectionVM.setGpsEnabled(needsGps);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.couldNotConfigureCompanionGps),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  String? _findChannelNameByHashHex(List<ChannelData> channels, String hashHexLower) {
    for (final channel in channels) {
      if (channel.hash.toRadixString(16).toLowerCase() == hashHexLower) {
        return channel.name;
      }
    }
    return null;
  }

  Widget _buildLocationTrackingCard(SettingsService settings) {
    final l10n = AppLocalizations.of(context)!;
    final isConnected = context.select<ConnectionViewModel, bool>((vm) => vm.isConnected);
    final s = settings.settings;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(l10n.locationTracking,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            value: s.telemetryEnabled,
            onChanged: (v) => settings.setTelemetryEnabled(v),
          ),
          // Channel selection
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: isConnected
                ? StreamBuilder<List<ChannelData>>(
                    stream: context.read<ChannelRepository>().getAllChannels(),
                    builder: (context, snapshot) {
                      final privateChannels = (snapshot.data ?? [])
                          .where((c) => c.canBeTrackingChannel)
                          .toList();

                      String? currentHash = s.telemetryChannelHash;
                      final validHashes = privateChannels
                          .map((c) => c.hash.toRadixString(16).toLowerCase())
                          .toSet();
                      if (currentHash != null && !validHashes.contains(currentHash)) {
                        currentHash = null;
                      }

                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: l10n.channel),
                        value: currentHash,
                        items: [
                          DropdownMenuItem<String>(
                              value: null, child: Text(l10n.none)),
                          for (final c in privateChannels)
                            DropdownMenuItem<String>(
                              value: c.hash.toRadixString(16).toLowerCase(),
                              child: Text(c.name),
                            ),
                        ],
                        onChanged: (v) async {
                          await settings.setTelemetryChannelHash(v);
                          final name = v == null
                              ? null
                              : _findChannelNameByHashHex(
                                  privateChannels, v.toLowerCase());
                          await settings.setTelemetryChannelName(name);
                          if (v == null || !context.mounted) return;

                          // Tracking on a channel makes it a team channel, and
                          // tracking needs the radio to hold it.
                          final channel = privateChannels.firstWhere(
                              (c) => c.hash.toRadixString(16).toLowerCase() == v);
                          await context
                              .read<ChannelRepository>()
                              .setTeamChannel(channel, true);
                          if (!context.mounted) return;
                          if (channelNeedsRadio(channel)) {
                            await promptAddChannelToRadio(context, channel);
                          }
                        },
                      );
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.telemetryChannelName != null
                            ? l10n.willShareOnChannel(s.telemetryChannelName!)
                            : l10n.noChannelSelected,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.connectToDeviceToSelectChannel,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
          ),
          _TelemetrySliders(settings: settings),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _showBackgroundLocationDialog(
      SettingsService settingsService) async {
    if (settingsService.settings.backgroundLocationEnabled) {
      await settingsService.setBackgroundLocationEnabled(false);
      return;
    }

    final shouldEnable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.backgroundLocation),
        content: Text(
          AppLocalizations.of(context)!.backgroundLocationExplanation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.notNow),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.enable),
          ),
        ],
      ),
    );

    if (shouldEnable != true || !mounted) return;

    var status = await Permission.locationAlways.request();

    // iOS processes the "Always" upgrade asynchronously — the request()
    // may return before the change is applied. Poll briefly to catch it.
    if (!status.isGranted) {
      for (var i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        status = await Permission.locationAlways.status;
        if (status.isGranted) break;
      }
    }

    if (status.isGranted) {
      await settingsService.setBackgroundLocationEnabled(true);
    } else if (status.isPermanentlyDenied) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.permissionRequired),
          content: const Text(
            'Background location was denied. Please enable "Always" '
            'location access in your device Settings for MeshCore TEAM.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text(AppLocalizations.of(context)!.openSettings),
            ),
          ],
        ),
      );
    }
  }
}

class _TelemetrySliders extends StatefulWidget {
  final SettingsService settings;
  const _TelemetrySliders({required this.settings});

  @override
  State<_TelemetrySliders> createState() => _TelemetrySlidersState();
}

class _TelemetrySlidersState extends State<_TelemetrySliders> {
  late double _interval;
  late double _distance;

  @override
  void initState() {
    super.initState();
    _interval = widget.settings.settings.telemetryIntervalSeconds.toDouble().clamp(30, 180);
    _distance = widget.settings.settings.telemetryMinDistanceMeters.toDouble().clamp(50, 500);
  }

  @override
  void didUpdateWidget(_TelemetrySliders old) {
    super.didUpdateWidget(old);
    _interval = widget.settings.settings.telemetryIntervalSeconds.toDouble().clamp(30, 180);
    _distance = widget.settings.settings.telemetryMinDistanceMeters.toDouble().clamp(50, 500);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(l10n.intervalSeconds(_interval.round().toString())),
        ),
        Slider(
          value: _interval,
          min: 30,
          max: 180,
          divisions: 15,
          onChanged: (v) => setState(() => _interval = (v / 10).round() * 10.0),
          onChangeEnd: (v) => widget.settings
              .setTelemetryIntervalSeconds(((v / 10).round() * 10).clamp(30, 180)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(l10n.minDistanceMeters(_distance.round().toString())),
        ),
        Slider(
          value: _distance,
          min: 50,
          max: 500,
          divisions: 45,
          onChanged: (v) => setState(() => _distance = (v / 10).round() * 10.0),
          onChangeEnd: (v) => widget.settings
              .setTelemetryMinDistanceMeters(((v / 10).round() * 10).clamp(50, 500)),
        ),
      ],
    );
  }
}
