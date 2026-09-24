# MeshCore TEAM

Cross-platform MeshCore TEAM companion app for Android/iOS, built with Flutter.

This app talks to a **MeshCore companion radio** over **Bluetooth Low Energy (BLE)**, syncs contacts/channels/messages, and provides chat + map tooling (offline maps, waypoints, location sharing).

The app works with stock MeshCore firmware for basic messaging, contacts, channels, and maps. [Custom MeshCore firmware](https://github.com/tmacinc/MeshCore) is required for full functionality, including:

- **Smart forwarding** — app-managed multi-hop routing (forwarding policy engine)
- **Autonomous mode** — firmware-side GPS tracking without a phone connection
- **Full radio settings UI** — smart forwarding toggle, autonomous mode toggle

📖 **[User guide](https://tmacinc.github.io/MeshCore-TEAM/)** · 🔒 **[Privacy policy](https://tmacinc.github.io/MeshCore-TEAM/privacy/)**

## Support

If you need help or have questions:

- 📧 Email: tmacinc090@gmail.com  
- 🐞 Report an issue: https://github.com/tmacinc/MeshCore-TEAM/issues  

Please include device type and app version when reporting issues.

## Screenshots

| Connection | Identity | Your name | Scanning | Connected radio |
|---|---|---|---|---|
| ![Connection](docs/screenshots/01-connection.png) | ![Identity](docs/screenshots/02-identity.png) | ![Your name](docs/screenshots/02-setAlias.png) | ![Scanning](docs/screenshots/03-connection2.png) | ![Connected radio](docs/screenshots/04-connection3.png) |

| Radio settings | Team Config menu | Team Config export | Settings: general |
|---|---|---|---|
| ![Radio settings](docs/screenshots/05-radiosettings.png) | ![Team Config menu](docs/screenshots/06-teamconfigmenu.png) | ![Team Config export](docs/screenshots/07-teamconfigexport.png) | ![Settings: general](docs/screenshots/08-settings.png) |

| Settings: location tracking | Settings: data | Red Light theme | Map |
|---|---|---|---|
| ![Settings: location tracking](docs/screenshots/09-settings.png) | ![Settings: data](docs/screenshots/10-settings.png) | ![Red Light theme](docs/screenshots/11-settingsRedLightTheme.png) | ![Map](docs/screenshots/12-map.png) |

| Satellite map | Map settings menu | Add waypoint | Add route |
|---|---|---|---|
| ![Satellite map](docs/screenshots/13-mapSat.png) | ![Map settings menu](docs/screenshots/14-mapSettingsmenu.png) | ![Add waypoint](docs/screenshots/15-addwaypoint.png) | ![Add route](docs/screenshots/16-addRoute.png) |

## What's in the app today

Core user-facing features that are already implemented:

- BLE scan/connect/disconnect with sync progress (contacts/channels/messages)
- Identity/name prompt (set how you appear on the mesh)
- Localization — English, German, Spanish, French, Italian, Dutch and Portuguese; follows the device language or can be chosen in settings
- Appearance themes — system/light/dark, plus a **night mode** ("Red Light Discipline") that dims the entire UI to red and red-filters map tiles to preserve dark-adapted vision in the field
- Contacts list with unread badges + direct messages (repeaters are read-only)
	- Search by name or public-key hash
	- Filter, sort, and favorite contacts
	- Delete contacts, with optional auto-purge of stale contacts after a set number of days
	- Battery level per contact (companion and phone), carried in telemetry so you can see who's running low
- Channels list with unread badges
	- Create private channels
	- Import via link/QR
	- Share private channels via link/QR
	- Per-channel notification modes (normal/muted/favorite), persisted across syncs
	- Hashtag channel creation directly from the chat input
	- `@mention` autocomplete suggestions from known contacts
- Messaging
	- Long-press / right-click a message to copy text or reply
	- Reply seeds an `@[name]` mention; `@` autocomplete from channel history
	- New-message indicator that holds scroll position and badges unread messages
	- Relative-date message timestamps
- Status icons and app menu on every screen, with network-bar shortcuts to toggle tracking and disconnect/reconnect
- Map screen
	- Phone location + optional "track-up" mode
	- Toggle name labels for tracked users and waypoints/routes to declutter the map
	- Contact markers (when location tracking is enabled)
		- Contact path history (dotted trail showing recent GPS fixes per contact)
		- Waypoints (create/edit/manage)
		- Routes (create multi-point paths, edit, color-code, share via mesh)
		- Offline map download + management
		- KMZ overlay map import — render Garmin-style custom maps as georeferenced raster overlays
- Location settings
	- Location source: phone GPS vs companion radio GPS
	- Location tracking ("telemetry") to a selected private channel
- Companion radio settings (when supported by firmware)
	- Frequency/BW/SF/CR/TX power presets + custom values
	- Camp mode with dedicated camp presets and firmware repeat
- **Smart forwarding** (V1) — app-managed multi-hop routing via the forwarding policy engine
- **Autonomous mode** — firmware-side GPS tracking that operates without a phone connection
- Capability advertisement between peers (`#CAP:` on the telemetry channel)
- Team Config export/import
		- Export channels, waypoints, radio settings, offline map tiles, and KMZ overlay maps as a portable `.teamcfg.zip` file
		- Import config on a connected companion — channels are registered with the radio, radio settings applied, waypoints and map tiles merged, overlay maps extracted
		- Named configs with per-item selection (choose which channels, waypoints, map areas, and overlay maps to include)
	- Offline sharing — serve configs over a local hotspot with QR code download (no internet required)
- Wipe Local Data — selectively clear channels (from firmware too), waypoints/routes, and offline maps with double confirmation
- Foreground service for background BLE stability (Android)
- Keep-screen-on / show-over-lock-screen option (Android) so the map and chat stay glanceable without unlocking
- iOS BLE lifecycle handling with deferred reconnect and stale connection cleanup

## Custom firmware

TEAM is designed to work with the [custom MeshCore firmware](https://github.com/tmacinc/MeshCore). While the app can connect to stock MeshCore radios for basic messaging, running custom firmware unlocks the full feature set:

| Feature | Stock firmware | Custom firmware |
|---|---|---|
| Smart forwarding (policy engine) | Not available | Full V1 engine with automatic `maxHops` management |
| Autonomous mode | Not available | Firmware-side GPS tracking without phone |
| Radio settings UI | Basic frequency/power | Smart Forwarding toggle, Autonomous Mode toggle |

The app detects custom firmware automatically via the `RESP_SELF_INFO` capability bitmask on connect. When stock firmware is detected, custom-only UI elements (forwarding toggles, autonomous mode) are hidden and the forwarding policy engine stays inactive. The connected device tile on the Connection screen shows the firmware type and supported capabilities (`FW: Custom • FWD ✓ • AUTO ✓`).

That bitmask only tells you about *your own* radio. To learn what *other* members are running, each node broadcasts a `#CAP:` capability advertisement on the telemetry channel announcing its own flags (custom firmware, forwarding, autonomous). Nodes publish shortly after they discover a new contact, or a minute or so after their capabilities change (a firmware reconnect or a relevant settings change) — there's no periodic keepalive, so a peer whose `#CAP:` is missing or older than 12 hours is assumed to be on stock firmware. This is what lets cooperative features like smart forwarding know which neighbors can actually participate.

For flashing instructions, supported boards, and build guides, see the [MeshCore firmware repo](https://github.com/tmacinc/MeshCore).

## How forwarding works

Forwarding lets companion radios relay messages on behalf of nodes that can't reach each other directly. The app implements a **forwarding policy engine** that monitors the mesh in real time and automatically adjusts the companion radio's `maxHops` setting.

### Forwarding V1 (current)

The V1 strategy is driven by incoming telemetry (`#TEL`) events on the tracking channel:

1. **Activation** — forwarding activates for groups larger than 2 members, when any tracked peer either reports `needsForwarding=true` in its last telemetry, or hasn't been heard for longer than 5 minutes (stale).
2. **Hop calculation** — `maxHops` is set to `max(observed path length across triggering peers) + 1`, clamped to a ceiling of 4.
3. **Hold-down** — once every tracked peer is directly reachable again (observed path length = 0), a 5-minute hold-down starts. If no peer re-triggers during the hold, `maxHops` drops back to 0 (forwarding off).
4. **Peer signalling** — each node broadcasts its own `needsForwarding` and `maxPathObserved` values in outgoing telemetry so neighboring nodes can react cooperatively.

V1 does **not** use a forward list — the firmware handles routing internally based solely on `maxHops`.

### Enabling forwarding

Forwarding is available when the companion radio runs **custom firmware** that reports forwarding support. The engine activates automatically when:

- The radio is connected and reports `supportsForwarding`
- Location tracking (telemetry) is enabled
- In **non-camp mode**: the engine is always active
- In **camp mode**: enable the **Smart Forwarding** toggle in Radio Settings

A forwarding debug screen (accessible from the Connection tab) shows the current engine state, applied `maxHops`, strategy mode, and per-node details.

## How autonomous mode works

Autonomous mode offloads location tracking to the **companion radio's own GPS**, so the radio can continue broadcasting telemetry even when the phone is disconnected or out of range.

When enabled, the firmware independently:

- Acquires a GPS fix using the companion radio's GPS module
- Periodically transmits location updates on the configured tracking channel
- Respects the interval / minimum-distance thresholds configured in the app

### Enabling autonomous mode

1. Go to **App Settings → Location → Location Tracking** and configure your tracking channel, interval, and minimum distance.
2. Open **Connection → Companion Settings → Radio Settings** and toggle **Autonomous Mode** on.
3. The app writes your tracking parameters to the firmware. You'll see an orange "Autonomous mode active" indicator on the connected device tile.

Requirements:

- Custom firmware that reports `supportsAutonomous`
- A companion radio with a GPS module — the firmware will reject the enable command (ERR 6) if no GPS hardware is present
- A valid GPS fix before telemetry will begin transmitting

Autonomous mode and app-side location tracking are independent — you can run both, or use autonomous mode alone for "deploy and walk away" scenarios.

## Quickstart (dev)

### Prerequisites

- Flutter SDK with Dart `>= ^3.12.0` (see `pubspec.yaml`)
- Android Studio (Android SDK + emulator) and/or Xcode (iOS, macOS only)
- A MeshCore companion radio running [custom firmware](https://github.com/tmacinc/MeshCore) (recommended for end-to-end testing)

### Run

```bash
flutter pub get
flutter run
```

On iOS (macOS), run CocoaPods once:

```bash
cd ios
pod install
cd ..
```

### Build

```bash
# Android
flutter build apk --release

# iOS (macOS)
flutter build ios --release
```

### Beta builds (with debug tooling)

A `BETA` compile-time flag enables the in-app debug log viewer and forwarding debug screen in release builds. This is useful for TestFlight / Play Store beta tracks where you want to collect logs from testers without shipping a debug build.

```bash
# iOS beta IPA (debug UI included, release performance)
flutter build ipa --release --dart-define=BETA=true

# Android beta APK
flutter build apk --release --dart-define=BETA=true

# Run on device to test locally
flutter run --release --dart-define=BETA=true
```

Regular release builds (without `--dart-define=BETA=true`) exclude all debug UI via compile-time tree-shaking.

## User guide

The full user guide — first launch, connecting a radio, setting up team tracking, channels, the map, Team Config, radio and app settings, and troubleshooting — lives at **https://tmacinc.github.io/MeshCore-TEAM/** (source: [docs/index.md](docs/index.md)).

## iOS support

TEAM is built with Flutter and fully supports both Android and iOS.

### What works

All core features run on iOS — connection, contacts, channels, map, messaging, radio settings, and the full BLE sync flow. BLE scan/connect works on real iOS devices (BLE is not available in the iOS simulator).

### BLE lifecycle

iOS-specific BLE lifecycle handling has been implemented:

- **Deferred reconnect** — when the app returns to the foreground, it automatically reconnects to the last connected companion radio.
- **Stale connection cleanup** — on disconnect, lingering CoreBluetooth connections are force-cleaned to prevent ghost connections.
- **Adapter readiness** — scanning waits for the Bluetooth adapter to report ready (CoreBluetooth can briefly report "unknown" on first launch).
- **Reconnection manager** — exponential backoff (2 s → 30 s max) handles transient disconnects.

### Permissions

Permissions are requested sequentially to avoid stacking iOS system dialogs:

1. Location (When In Use)
2. Notifications
3. Bluetooth (requested last to avoid the local-network prompt appearing before the user has context)

### Background operation

iOS background operation was **overhauled in v1.1.5** and location + telemetry now run reliably while backgrounded. The app declares `bluetooth-central`, `location`, and `processing` background modes, and holds a shared background location session that keeps the app — and its BLE link to the companion radio — alive when the screen is off or the app is in the background.

- **Location + telemetry in the background** — every location consumer (the map and the telemetry sender) subscribes through a **single shared session** (`buildAppLocationSettings()` in [lib/utils/location_settings.dart](lib/utils/location_settings.dart)) with `allowsBackgroundLocationUpdates` enabled, so GPS updates and telemetry broadcasts continue when backgrounded. iOS shows its blue location indicator while this is active.
- **Why a shared session** — geolocator reuses one native `CLLocationManager` for all callers, and the *first* subscriber's settings win. If any caller subscribed first with foreground-only settings, the app lost its background execution assertion and iOS suspended it (and telemetry) a few seconds after backgrounding. Routing every caller through the shared background settings fixes this.
- Because the background-location assertion keeps the process running, the BLE connection stays up alongside it, so tracking and incoming messages continue rather than dropping shortly after backgrounding.

iOS still has no true always-on foreground service like Android, so under sustained memory pressure the system can reclaim the app; reconnection on resume is handled automatically.

### Known limitations

- **Background execution ceiling** — location, telemetry, and BLE keep running via the background-location assertion, but iOS can still suspend the app under heavy memory pressure. It reconnects and resumes on the next foreground or location event.
- **Always-location (indicator-free) background** — background tracking currently relies on the blue location indicator being shown. An "Always" authorization upgrade that removes the persistent indicator is planned.

See [ios/TODO.md](ios/TODO.md) for the detailed iOS parity checklist.

## Roadmap

Planned features and improvements (see also the [issues tracker](../../issues)):

- **Forwarding V2** — topology-aware routing using the mesh graph model (`#T:` topology events). V2 will build a real-time network graph and use it to compute targeted forward lists (`SET_FORWARD_LIST`) instead of relying solely on `maxHops`. The topology strategy skeleton is in place and currently falls back to V1; the graph model and prefix-based routing logic are next.
- **iOS background reliability** — Core Bluetooth state restoration is now enabled (shipped in v1.1.5); continued work on background BLE persistence and the Always-location upgrade flow for background tracking.
- Topology map visualization — display the mesh network graph on the map screen
- Multi-companion device switching

*Previously shipped:*
- ~~**Group member location history**~~ — shipped in v1.0.3
- ~~**Team Config export/import**~~ — shipped in v1.0.3-beta2; overlay maps added in v1.1.4
- ~~**Hashtag channel creation + @mentions**~~ — shipped in v1.1.4
- ~~**KMZ overlay map import**~~ — shipped in v1.1.4
- ~~**Localization (English + German)**~~ — shipped in v1.1.5
- ~~**Contact search, filtering, favorites, and auto-purge**~~ — shipped in v1.1.5
- ~~**Per-channel notification modes**~~ — shipped in v1.1.5
- ~~**Message copy/reply + new-message indicator**~~ — shipped in v1.1.5

### Possible future features

- **User alias** — allow members to use an alias on the mesh, maintaining privacy outside of their private group.
- **Multiple group handling with tagging** — manage membership in multiple groups with tagging/filtering to keep conversations organized.

## Troubleshooting

- **No BLE devices found**: ensure Bluetooth + Location permissions are granted; on Android 12+ also ensure Bluetooth Scan/Connect permissions are allowed.
- **Disconnects when screen turns off (Android)**: accept the battery optimization exemption prompt; keep the app allowed to run in the background.
- **Map shows no contacts**: enable Location Tracking (telemetry) in **App Settings → Location**. Contacts must have sent telemetry within the last 12 hours to appear.
- **Can't DM a device**: repeaters are intentionally blocked from direct messages.
- **Autonomous mode won't enable**: the companion radio must have a GPS module. If the firmware returns ERR 6, the hardware doesn't support GPS.
- **Forwarding not activating**: ensure you're on custom firmware, telemetry is enabled, and (if in camp mode) Smart Forwarding is toggled on.

## License

### Non-Commercial Use Only

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.

- See `LICENSE` for full terms.
- Third-party attributions: `NOTICES.md`.

### Commercial licensing

For commercial use, contact: tmacinc090@gmail.com

## Disclaimer

This is a hobby/research project provided "as is", without warranty. Use at your own risk.
