# MeshCore TEAM

Cross-platform MeshCore TEAM companion app for Android/iOS, built with Flutter.

This app talks to a **MeshCore companion radio** over **Bluetooth Low Energy (BLE)**, syncs contacts/channels/messages, and provides chat + map tooling (offline maps, waypoints, location sharing).

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

## What’s in the app today

Core user-facing features that are already implemented in this folder:

- BLE scan/connect/disconnect with sync progress (contacts/channels/messages)
- Identity/name prompt (set how you appear on the mesh)
- Contacts list with unread badges + direct messages (repeaters are read-only)
- Channels list with unread badges
	- Create private channels
	- Import via link/QR
	- Share private channels via link/QR
- Map screen
	- Phone location + optional “track-up” mode
	- Contact markers (when location tracking is enabled)
	- Waypoints (create/edit/manage)
	- Offline map download + management
- Location settings
	- Location source: phone GPS vs companion radio GPS
	- Location tracking (“telemetry”) to a selected private channel
- Companion radio settings (when supported by firmware)
	- Frequency/BW/SF/CR/TX power presets + custom values

Project roadmap / broader plans: see the [issues tracker](../../issues) and `TODO.md`.

## Quickstart (dev)

### Prerequisites

- Flutter SDK with Dart `>= 3.6` (see `pubspec.yaml`)
- Android Studio (Android SDK + emulator) and/or Xcode (iOS, macOS only)
- A MeshCore companion radio running compatible firmware (recommended for end-to-end testing)

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

## Simple user guide

### 1) First launch: permissions

On first launch the app will request:

- **Bluetooth**: to connect to the companion radio
- **Location**: required for BLE scanning on Android, and for the map
- **Notifications**: message alerts

On Android, you’ll also be prompted about **battery optimization**. Disabling optimization for the app improves background BLE stability.

### 2) Connect to a companion radio

1. Open the **Connection** tab.
2. Tap **Scan** and select your MeshCore device.
3. After connect, the app will **sync** contacts/channels/messages.
4. If prompted, set your **Identity** (the name others see on the mesh).

### 3) Contacts and direct messages

- Open **Contacts** to see synced devices.
- Tap a contact to open a **Direct Message**.
- If a contact is a **repeater**, direct messaging is disabled (you can still see it in the list).

### 4) Channels (group chat)

- Open **Channels** to see all synced channels.
- Tap **+** to:
	- **Create Private Channel**
	- **Add via Link / QR Code**

Private channels can be shared from inside the channel chat.

Channel share links use this format:

`meshcore://channel/add?name=<name>&secret=<hex32>`

Treat the link like a password: anyone who has it can join the channel.

### 5) Map, offline maps, and waypoints

- Open **Map** to see your position.
- Use the map menus to:
	- change the map provider (layers icon)
	- download offline tiles (**Download Map Area**)
	- manage stored areas (**Manage Offline Maps**)
	- manage waypoints (**Manage Waypoints**)

To create a waypoint, tap the **add waypoint** button and confirm the position.

### 6) Location tracking (“telemetry”)

Location tracking controls whether the app sends periodic location updates to the mesh.

1. Go to **Connection → Companion Settings → Location Tracking**.
2. Enable tracking.
3. Select a **private channel**.
4. Choose interval and minimum-distance thresholds.

Note: when tracking is disabled, contacts are hidden from the map.

## Troubleshooting

- **No BLE devices found**: ensure Bluetooth + Location permissions are granted; on Android 12+ also ensure Bluetooth Scan/Connect permissions are allowed.
- **Disconnects when screen turns off (Android)**: accept the battery optimization exemption prompt; keep the app allowed to run in the background.
- **Map shows no contacts**: enable Location Tracking (telemetry) on the Connection screen.
- **Can’t DM a device**: repeaters are intentionally blocked from direct messages.

## License

### Non-Commercial Use Only

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.

- See `LICENSE` for full terms.
- Third-party attributions: `NOTICES.md`.

### Commercial licensing

For commercial use, contact: tmacinc090@gmail.com

## Disclaimer

This is a hobby/research project provided “as is”, without warranty. Use at your own risk.
