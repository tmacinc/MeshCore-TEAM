# MeshCore TEAM

Cross-platform MeshCore TEAM companion app for Android/iOS, built with Flutter.

This app talks to a **MeshCore companion radio** over **Bluetooth Low Energy (BLE)**, syncs contacts/channels/messages, and provides chat + map tooling (offline maps, waypoints, location sharing).

The app works with stock MeshCore firmware for basic messaging, contacts, channels, and maps. [Custom MeshCore firmware](https://github.com/tmacinc/MeshCore) is required for full functionality, including:

- **Smart forwarding** — app-managed multi-hop routing (forwarding policy engine)
- **Autonomous mode** — firmware-side GPS tracking without a phone connection
- **Full radio settings UI** — smart forwarding toggle, autonomous mode toggle

## Screenshots

| Connection | Identity | Connection (sync) | Radio settings | Location tracking |
|---|---|---|---|---|
| ![Connection](docs/screenshots/01-connection.png) | ![Identity](docs/screenshots/02-identity.png) | ![Connection (sync)](docs/screenshots/03-connection2.png) | ![Radio settings](docs/screenshots/04-radiosettings.png) | ![Location tracking](docs/screenshots/05-trackingsettings.png) |

| Contacts | Direct message | Channels | Private channel | Share channel |
|---|---|---|---|---|
| ![Contacts](docs/screenshots/06-contacts.png) | ![Direct message](docs/screenshots/07-directmesage.png) | ![Channels](docs/screenshots/08-channels.png) | ![Private channel](docs/screenshots/09-privatechannel.png) | ![Share channel](docs/screenshots/10-sharechannel.png) |

| Create/Add channel | Map |  |  |  |
|---|---|---|---|---|
| ![Create/Add channel](docs/screenshots/11-createAddchannel.png) | ![Map](docs/screenshots/12-map.png) |  |  |  |

## What's in the app today

Core user-facing features that are already implemented:

- BLE scan/connect/disconnect with sync progress (contacts/channels/messages)
- Identity/name prompt (set how you appear on the mesh)
- Contacts list with unread badges + direct messages (repeaters are read-only)
- Channels list with unread badges
	- Create private channels
	- Import via link/QR
	- Share private channels via link/QR
- Map screen
	- Phone location + optional "track-up" mode
	- Contact markers (when location tracking is enabled)
	- Waypoints (create/edit/manage)
	- Offline map download + management
- Location settings
	- Location source: phone GPS vs companion radio GPS
	- Location tracking ("telemetry") to a selected private channel
- Companion radio settings (when supported by firmware)
	- Frequency/BW/SF/CR/TX power presets + custom values
	- Camp mode with dedicated camp presets and firmware repeat
- **Smart forwarding** (V1) — app-managed multi-hop routing via the forwarding policy engine
- **Autonomous mode** — firmware-side GPS tracking that operates without a phone connection
- Capability advertisement between peers (`#CAP:` on the telemetry channel)
- Foreground service for background BLE stability (Android)

## Custom firmware

TEAM is designed to work with the [custom MeshCore firmware](https://github.com/tmacinc/MeshCore). While the app can connect to stock MeshCore radios for basic messaging, running custom firmware unlocks the full feature set:

| Feature | Stock firmware | Custom firmware |
|---|---|---|
| Smart forwarding (policy engine) | Not available | Full V1 engine with automatic `maxHops` management |
| Autonomous mode | Not available | Firmware-side GPS tracking without phone |
| Radio settings UI | Basic frequency/power | Smart Forwarding toggle, Autonomous Mode toggle |

The app detects custom firmware automatically via the `RESP_SELF_INFO` capability bitmask on connect. When stock firmware is detected, custom-only UI elements (forwarding toggles, autonomous mode) are hidden and the forwarding policy engine stays inactive. The connected device tile on the Connection screen shows the firmware type and supported capabilities (`FW: Custom • FWD ✓ • AUTO ✓`).

For flashing instructions, supported boards, and build guides, see the [MeshCore firmware repo](https://github.com/tmacinc/MeshCore).

## How forwarding works

Forwarding lets companion radios relay messages on behalf of nodes that can't reach each other directly. The app implements a **forwarding policy engine** that monitors the mesh in real time and automatically adjusts the companion radio's `maxHops` setting.

### Forwarding V1 (current)

The V1 strategy is driven by incoming telemetry (`#TEL`) events on the tracking channel:

1. **Activation** — forwarding activates when any tracked peer either reports `needsForwarding=true` in its last telemetry, or hasn't been heard for longer than 5 minutes (stale).
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

1. Go to **Connection → Companion Settings → Location Tracking** and configure your tracking channel, interval, and minimum distance.
2. Open **Radio Settings** and toggle **Autonomous Mode** on.
3. The app writes your tracking parameters to the firmware. You'll see an orange "Autonomous mode active" indicator on the connected device tile.

Requirements:

- Custom firmware that reports `supportsAutonomous`
- A companion radio with a GPS module — the firmware will reject the enable command (ERR 6) if no GPS hardware is present
- A valid GPS fix before telemetry will begin transmitting

Autonomous mode and app-side location tracking are independent — you can run both, or use autonomous mode alone for "deploy and walk away" scenarios.

## Quickstart (dev)

### Prerequisites

- Flutter SDK with Dart `>= 3.6` (see `pubspec.yaml`)
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

## User guide

### 1) First launch: permissions

On first launch the app will show a permissions explainer screen. Tap the button to request permissions:

- **Bluetooth** (Scan + Connect on Android 12+): to discover and connect to the companion radio
- **Location**: required for BLE scanning on Android, and for the map / GPS features
- **Notifications**: message alerts when the app is in the background

On Android, you'll also be prompted about **battery optimization**. Disabling optimization for the app lets the foreground service keep the BLE connection alive when the screen is off.

### 2) Connect to a companion radio

1. Open the **Connection** tab (bottom nav, first icon).
2. Tap **Scan** — discovered MeshCore devices will appear in a list.
3. Tap a device to connect. The app will run an initial sync sequence:
   - **Device query** — reads firmware version and capability flags
   - **App start** — reads the radio's identity and radio parameters
   - **Contact sync** — pulls the contact list from the radio
   - **Channel sync** — pulls configured channels (up to 8 on custom firmware)
   - **Message sync** — pulls any queued messages
4. If this is a new companion (or the name has changed), you'll be prompted to confirm or set your **Identity** — the name others see on the mesh. Navigation is locked to the Connection tab until you confirm.

On subsequent connects to the same companion, the app runs an **incremental sync** (contacts + messages only, skipping channels) for a faster reconnect.

### 3) Contacts and direct messages

- Open **Contacts** (second tab) to see synced devices.
- Tap a contact to open a **Direct Message** conversation.
- If a contact is a **repeater**, direct messaging is disabled (you can still see it in the list).
- Unread badges show on the Contacts tab icon when new messages arrive.

### 4) Channels (group chat)

- Open **Channels** (third tab) to see all synced channels.
- Tap **+** to:
	- **Create Private Channel**
	- **Add via Link / QR Code**

Private channels can be shared from inside the channel chat via link or QR code.

Channel share links use this format:

`meshcore://channel/add?name=<name>&secret=<hex32>`

Treat the link like a password: anyone who has it can join the channel.

### 5) Map, offline maps, and waypoints

- Open **Map** (fourth tab) to see your position.
- Use the map menus to:
	- change the map provider (layers icon)
	- download offline tiles (**Download Map Area**)
	- manage stored areas (**Manage Offline Maps**)
	- manage waypoints (**Manage Waypoints**)

To create a waypoint, tap the **add waypoint** button and confirm the position.

Contact markers appear on the map when they have sent location telemetry on the tracking channel within the last 12 hours.

### 6) Radio settings

From the Connection tab, tap **Radio Settings** to configure:

- **Camp Mode** — locks the radio to camp-compatible presets and enables firmware repeat mode. When camp mode is on, manual frequency/BW/SF/CR controls are disabled.
- **Smart Forwarding** (camp mode + custom firmware) — enables the app-managed forwarding policy engine while camp mode is active.
- **Autonomous Mode** (custom firmware + GPS) — configures the firmware to track and broadcast location independently. See [How autonomous mode works](#how-autonomous-mode-works).
- **Preset / Custom** radio parameters — frequency, bandwidth, spreading factor, coding rate, TX power.

### 7) Location tracking ("telemetry")

Location tracking controls whether the app sends periodic location updates to the mesh.

1. Go to **Connection → Companion Settings → Location Tracking**.
2. Enable tracking.
3. Select a **private channel** for telemetry.
4. Choose interval and minimum-distance thresholds.
5. Choose the location source: **phone GPS** or **companion radio GPS**.

When tracking is enabled, the app broadcasts your position on the selected channel. Other TEAM users on the same channel will see your marker on their map.

When tracking is disabled, contact markers are hidden from the map.

## iOS support

TEAM is built with Flutter and targets both Android and iOS. The current state of iOS support:

- **What works**: all core UI — connection, contacts, channels, map, messaging, radio settings — runs on iOS. BLE scan/connect and the full sync flow work on real iOS devices (BLE is not available in the iOS simulator).
- **Background limitations**: Android uses a native foreground service to keep the BLE connection alive indefinitely. iOS does not allow true foreground services. The app declares `bluetooth-central`, `location`, and `processing` background modes, but iOS may suspend or terminate the BLE connection when the app is backgrounded. Reconnection on resume is handled, but gaps are expected.
- **Permissions**: iOS uses a two-step location permission flow (When In Use → Always). The current implementation requests When In Use; upgrading to Always for background tracking is still in progress.
- **Notifications**: local notification support is wired but needs further validation on iOS.

See `ios/TODO.md` for the detailed iOS parity checklist.

## Roadmap

Planned features and improvements (see also the [issues tracker](../../issues)):

- **Forwarding V2** — topology-aware routing using the mesh graph model (`#T:` topology events). V2 will build a real-time network graph and use it to compute targeted forward lists (`SET_FORWARD_LIST`) instead of relying solely on `maxHops`. The topology strategy skeleton is in place and currently falls back to V1; the graph model and prefix-based routing logic are next.
- **iOS background reliability** — improve BLE connection persistence using Core Bluetooth state restoration and background location updates; implement the Always-location upgrade flow for background tracking; validate `flutter_foreground_task` behavior on iOS.
- Topology map visualization — display the mesh network graph on the map screen
- Enhanced offline map management
- Multi-companion device switching

## Troubleshooting

- **No BLE devices found**: ensure Bluetooth + Location permissions are granted; on Android 12+ also ensure Bluetooth Scan/Connect permissions are allowed.
- **Disconnects when screen turns off (Android)**: accept the battery optimization exemption prompt; keep the app allowed to run in the background.
- **Map shows no contacts**: enable Location Tracking (telemetry) on the Connection screen. Contacts must have sent telemetry within the last 12 hours to appear.
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
