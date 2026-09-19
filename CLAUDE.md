# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project overview

**MeshCore TEAM** is a cross-platform Flutter app (package name `meshcore_team`), mainly for Android and iOS. It talks to a MeshCore companion radio over BLE (Nordic UART Service). It offers contacts, channels and DMs, a map with offline tiles, KMZ and MBTiles overlays, waypoints and routes, location telemetry, Team Config export/import, and smart forwarding.

- Stock MeshCore firmware covers basic features. [Custom firmware](https://github.com/tmacinc/MeshCore) unlocks smart forwarding, autonomous mode and extra radio settings. The app detects custom firmware from the `RESP_SELF_INFO` capability bitmask, and custom-only UI must stay hidden on stock firmware.
- Licensed **CC BY-NC-SA 4.0** (non-commercial). Source files start with the copyright/license header. Copy it from an existing file when creating new ones.
- `README.md` is the feature/user-facing reference (forwarding, autonomous mode, channel links, etc.). Keep it in sync when behavior changes.

The apps main goal is to provide offline capable tracking for a group of users, prioritizing ease of setup and confidentiality on the mesh.

## Commands

```bash
flutter pub get
flutter run                                   # debug
flutter run --release --dart-define=BETA=true # release perf + in-app debug log / forwarding debug screens
flutter analyze                               # lints: package:flutter_lints/flutter.yaml
flutter test                                  # tests live in test/
flutter test test/mbtiles_source_test.dart    # single file

# Code generation (drift) — run after editing lib/database/tables.dart or any DAO
dart run build_runner build --delete-conflicting-outputs

# Localization — regenerated from lib/l10n/*.arb (flutter: generate: true)
flutter gen-l10n
```

- **Release builds:** `./Build.sh` is an interactive bash script. It prompts for targets (APK/AAB/IPA), signing, and dev vs. production version. It passes `--build-name` and `--build-number=<epoch>`, writes `.build_version`, and puts output in `compiled/`. Don't run it non-interactively.
- iOS requires `cd ios && pod install` on macOS.
- The dev machine is Windows, so iOS builds happen elsewhere. 

## Architecture (`lib/`)

Dependency wiring happens in `main.dart` through `provider` (`MultiProvider`, around line 467). Most long-lived services are created in `_runAppStartup()` and exposed with `.value`.

| Layer | Path | Notes |
|---|---|---|
| BLE | `ble/` | `ble_service`, `ble_connection_manager`, `reconnection_manager`, protocol encode/decode (`ble_protocol`, `ble_commands`, `ble_responses`, `ble_constants`) |
| Persistence | `database/` | Drift. `tables.dart` holds the schema, `daos/` the DAOs. `*.g.dart` files are **generated**, so never hand-edit them |
| Repositories | `repositories/` | Contact / channel / message logic on top of DAOs + BLE (`message_repository.dart` is large) |
| Services | `services/` | Mesh connection lifecycle, telemetry, forwarding policy, capability publish/track, notifications, map tile cache, KMZ/MBTiles import, Team Config (ZIP + local `shelf` server), settings |
| Forwarding | `services/forwarding/` | `ForwardingStrategy` interface; `forwarding_v1_strategy` is current; `topology_forwarding_strategy` |
| State | `viewmodels/`, `ChangeNotifier` services | `ConnectionViewModel`, `SettingsService`, etc. |
| UI | `screens/`, `widgets/`, `theme/` | `main_navigation_screen` is the tab shell; `night_theme` is "Red Light Discipline" |
| Models | `models/` | Includes in-band mesh message formats (telemetry, capability, topology, waypoint, route) |
| l10n | `l10n/` | `app_en.arb` is the template. Other locales: de, es, fr, it, nl, pt |

In-band protocols travel as channel text with prefixes such as `#TEL` (telemetry) and `#CAP:` (capability advertisement). Changing their format breaks older peers, so keep them backward compatible.

## Conventions and rules

- **UI imports:** use `package:material_ui/material_ui.dart` / `package:cupertino_ui/cupertino_ui.dart`, not `package:flutter/material.dart` (migrated in #80).
- **No hardcoded user-facing strings.** Add keys to `app_en.arb` **and every other locale's `.arb`**, regenerate, and use `AppLocalizations.of(context)`. Recent commits fixed missed translations, so check all 7 locales.
- **Database changes:** bump `schemaVersion` in `database/database.dart` (currently 9), add a `from <= N && to >= N+1` step in `onUpgrade`, then regenerate with build_runner.
- **Location streams:** every `Geolocator.getPositionStream` caller must use `buildAppLocationSettings()` from `utils/location_settings.dart`. iOS shares a single native session, so a bare `LocationSettings` breaks background tracking. See `memory/geolocator-shared-stream-background.md`.
- **Logging:** release builds suppress `print` / `debugPrint`. Debug logging goes through `debug_log_service` (enabled in debug and `BETA` builds). Gate debug-only UI behind `kDebugMode || isBetaBuild`.
- Platform-specific behavior (Android foreground service, battery optimization, iOS BLE lifecycle and deferred reconnect) is deliberate. Don't simplify it away without checking both platforms.
- `memory/` holds project knowledge notes (gotchas). Add new ones there in the same frontmatter format.


## Git workflow

- `dev` is the default/integration branch that is available to beta testers; `main` holds releases. Remotes: `origin` (tmacinc)
- Version lives in `pubspec.yaml` (`version: x.y.z+build`). Bump the build number for store submissions.
- Update `RELEASE_NOTES.md` for user-visible changes.

