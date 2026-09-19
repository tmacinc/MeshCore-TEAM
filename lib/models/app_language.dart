// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

/// One language the app ships translations for.
///
/// [endonym] is the language's name *in that language* (Deutsch, not German).
/// The first-launch picker is shown before any language has been chosen, so it
/// cannot rely on localized strings — endonyms are readable to the speaker of
/// each language regardless of which locale is currently active.
class AppLanguage {
  /// ISO 639-1 code. Matches the `app_<code>.arb` suffix and the generated
  /// `AppLocalizations` locale.
  final String code;

  /// Language name written in that language.
  final String endonym;

  const AppLanguage({required this.code, required this.endonym});

  Locale get locale => Locale(code);

  /// Sentinel [AppSettings.localeCode] value meaning "follow the device".
  ///
  /// A sentinel rather than null because `AppSettings.copyWith` uses `??`
  /// merging, which cannot write a null back over a non-null value — the same
  /// reason [AppThemeMode.system] exists.
  static const String systemDefault = 'system';

  /// Language used when the device locale is not one we translate.
  ///
  /// Flutter's default resolution falls back to the *first* entry of
  /// `supportedLocales`, which gen-l10n emits alphabetically — that made
  /// German the fallback for the entire non-German, non-English world. See
  /// `_resolveLocale` in main.dart, which overrides that behaviour.
  static const String fallbackCode = 'en';

  /// Every language with a translation, in picker display order.
  ///
  /// KEEP IN SYNC:
  ///   - lib/l10n/app_<code>.arb            (the translations themselves)
  ///   - ios/Runner/Info.plist              (CFBundleLocalizations — without
  ///     an entry there iOS never reports that locale to the app)
  static const List<AppLanguage> all = <AppLanguage>[
    AppLanguage(code: 'en', endonym: 'English'),
    AppLanguage(code: 'de', endonym: 'Deutsch'),
    AppLanguage(code: 'es', endonym: 'Español'),
    AppLanguage(code: 'fr', endonym: 'Français'),
    AppLanguage(code: 'it', endonym: 'Italiano'),
    AppLanguage(code: 'nl', endonym: 'Nederlands'),
    AppLanguage(code: 'pt', endonym: 'Português'),
  ];

  static const Set<String> codes = <String>{
    'en',
    'de',
    'es',
    'fr',
    'it',
    'nl',
    'pt',
  };

  /// True when [code] is [systemDefault] or a language we translate.
  static bool isValidSetting(String? code) =>
      code == systemDefault || (code != null && codes.contains(code));

  /// The catalog entry for [code], or null for [systemDefault] / unknown.
  static AppLanguage? byCode(String? code) {
    for (final language in all) {
      if (language.code == code) return language;
    }
    return null;
  }

  /// Resolve [preferred] against the languages we translate, falling back to
  /// [fallbackCode] rather than to whichever locale happens to sort first.
  ///
  /// Used as `MaterialApp.localeResolutionCallback`. Flutter's default returns
  /// `supportedLocales.first` when nothing matches, and gen-l10n emits that
  /// list alphabetically — so with [de, en] every device set to a language we
  /// do not ship (Italian, Polish, Japanese, …) silently came up in German.
  ///
  /// Matching is on language code only, so de_AT and fr_CA resolve to de and
  /// fr instead of falling through to English.
  static Locale resolve(Locale? preferred, Iterable<Locale> supported) {
    if (preferred != null) {
      for (final locale in supported) {
        if (locale.languageCode == preferred.languageCode) return locale;
      }
    }
    return const Locale(fallbackCode);
  }

  /// The locale that code outside the widget tree should localize into.
  ///
  /// Widgets read their locale from `AppLocalizations.of(context)`. Services
  /// that build user-visible text with no context — notifications above all —
  /// have to arrive at the same answer on their own: the explicit choice when
  /// the user made one, otherwise the device locale run through [resolve], so
  /// an untranslated device language lands on English rather than German.
  ///
  /// The language setting the app is currently running under.
  ///
  /// [SettingsService] keeps this in step with the stored preference. It exists
  /// for code that must localize without a [BuildContext] and without a
  /// reference to the settings — import services, tile caches, background
  /// tasks. Anything holding a `SettingsService` should read that instead;
  /// anything inside the widget tree should use `AppLocalizations.of(context)`.
  static String activeLocaleCode = systemDefault;

  /// Pair with `lookupAppLocalizations` to get the strings themselves.
  ///
  /// [localeCode] defaults to [activeLocaleCode] when omitted.
  static Locale localeFor([String? localeCode]) {
    localeCode ??= activeLocaleCode;
    if (localeCode != systemDefault) {
      final match = byCode(localeCode);
      if (match != null) return match.locale;
    }
    return resolve(
      PlatformDispatcher.instance.locale,
      all.map((language) => language.locale),
    );
  }
}
