// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_team/l10n/app_localizations.dart';
import 'package:meshcore_team/models/app_language.dart';

void main() {
  // The real list MaterialApp passes to the callback: gen-l10n emits it
  // alphabetically, which is what made 'de' the accidental global fallback.
  const supported = AppLocalizations.supportedLocales;

  group('AppLanguage.resolve', () {
    test('an unsupported device locale falls back to English, not German', () {
      // Regression: an Italian user reported the app coming up in German.
      // Flutter's default resolution returns supportedLocales.first, and
      // 'de' sorts first — so every untranslated locale landed on German.
      for (final code in ['pl', 'ja', 'sv', 'cs', 'zz']) {
        expect(AppLanguage.resolve(Locale(code), supported), const Locale('en'),
            reason: '$code should fall back to English');
      }
    });

    test('a null device locale falls back to English', () {
      expect(AppLanguage.resolve(null, supported), const Locale('en'));
    });

    test('each shipped language resolves to itself', () {
      for (final language in AppLanguage.all) {
        expect(
          AppLanguage.resolve(language.locale, supported),
          Locale(language.code),
        );
      }
    });

    test('a regional variant resolves on language code alone', () {
      // de_AT / fr_CA / es_MX must not fall through to English.
      expect(AppLanguage.resolve(const Locale('de', 'AT'), supported),
          const Locale('de'));
      expect(AppLanguage.resolve(const Locale('fr', 'CA'), supported),
          const Locale('fr'));
      expect(AppLanguage.resolve(const Locale('es', 'MX'), supported),
          const Locale('es'));
      expect(AppLanguage.resolve(const Locale('it', 'CH'), supported),
          const Locale('it'));
      // We ship European Portuguese under the generic 'pt' code, so Brazilian
      // devices resolve to it rather than falling through to English.
      expect(AppLanguage.resolve(const Locale('pt', 'BR'), supported),
          const Locale('pt'));
    });
  });

  group('AppLanguage catalog', () {
    test('every catalog entry has a generated translation', () {
      // Catches an entry added to `all` without a matching app_<code>.arb.
      final supportedCodes = supported.map((l) => l.languageCode).toSet();
      for (final language in AppLanguage.all) {
        expect(supportedCodes, contains(language.code));
      }
    });

    test('every generated translation is offered in the picker', () {
      // Catches an app_<code>.arb added without an entry in `all`, which
      // would leave the language unreachable from the UI.
      for (final locale in supported) {
        expect(AppLanguage.byCode(locale.languageCode), isNotNull,
            reason: '${locale.languageCode} has translations but no '
                'AppLanguage entry');
      }
    });

    test('codes and all stay in sync', () {
      expect(AppLanguage.codes, AppLanguage.all.map((l) => l.code).toSet());
    });

    test('the fallback language is one we actually ship', () {
      expect(AppLanguage.byCode(AppLanguage.fallbackCode), isNotNull);
    });

    test('isValidSetting accepts the sentinel and shipped codes only', () {
      expect(AppLanguage.isValidSetting(AppLanguage.systemDefault), isTrue);
      expect(AppLanguage.isValidSetting('it'), isTrue);
      expect(AppLanguage.isValidSetting('pl'), isFalse);
      expect(AppLanguage.isValidSetting(null), isFalse);
      expect(AppLanguage.isValidSetting(''), isFalse);
    });
  });
}
