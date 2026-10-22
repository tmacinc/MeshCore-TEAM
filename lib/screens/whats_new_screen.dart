// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';

/// Pages shown once per release, on a fresh install and after an update,
/// before the app opens. The first page names the version and the headline
/// change; 1.2 then explains how teams work now that people are known by
/// their phone rather than their radio.
///
/// For a release with new pages, change [release] and the pages: everyone
/// who has seen the previous set sees the new one once.
class WhatsNewScreen extends StatefulWidget {
  static const String release = '1.2';

  final VoidCallback onDone;

  const WhatsNewScreen({super.key, required this.onDone});

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  final _controller = PageController();
  int _page = 0;
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_WhatsNewPage> _pages(AppLocalizations l10n) => [
        _WhatsNewPage(
          null,
          l10n.whatsNewIntroTitle,
          l10n.whatsNewIntroBody,
        ),
        _WhatsNewPage(
          Icons.badge,
          l10n.whatsNewNameTitle,
          l10n.whatsNewNameBody,
        ),
        _WhatsNewPage(
          Icons.swap_horiz,
          l10n.whatsNewRadioTitle,
          l10n.whatsNewRadioBody,
        ),
        _WhatsNewPage(
          Icons.phone_android,
          l10n.whatsNewChannelsTitle,
          l10n.whatsNewChannelsBody,
        ),
        _WhatsNewPage(
          Icons.hourglass_bottom,
          l10n.whatsNewExpectTitle,
          l10n.whatsNewExpectBody,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final pages = _pages(l10n);
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                children: [for (final page in pages) _buildPage(page)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: isLast
                        ? null
                        : TextButton(
                            onPressed: widget.onDone,
                            child: Text(l10n.skip),
                          ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < pages.length; i++)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _page
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: FilledButton(
                      onPressed: isLast
                          ? widget.onDone
                          : () => _controller.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                      child: Text(
                        isLast ? l10n.done : l10n.whatsNewNext,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// App icon, name and version, at the top of the start page.
  List<Widget> _buildReleaseHeader(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return [
      // Clipped: the launcher PNG has square black corners.
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          height: 96,
          Platform.isIOS
              ? 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'
              : 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.groups, size: 72, color: theme.colorScheme.primary),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'MeshCore TEAM',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        _version == null ? '' : l10n.whatsNewVersion(_version!),
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    ];
  }

  Widget _buildPage(_WhatsNewPage page) {
    final theme = Theme.of(context);
    // Scrolls on short screens and with large text.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              if (page.icon != null)
                Icon(page.icon, size: 72, color: theme.colorScheme.primary)
              else
                ..._buildReleaseHeader(theme),
              const SizedBox(height: 24),
              Text(
                page.title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                page.body,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsNewPage {
  /// Null for the start page, which shows the app and version instead.
  final IconData? icon;
  final String title;
  final String body;

  const _WhatsNewPage(this.icon, this.title, this.body);
}
