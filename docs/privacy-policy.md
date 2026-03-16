# Privacy Policy — MeshCore-TEAM

Last updated: 2026-02-20

MeshCore-TEAM ("the app") is a field communications app that connects to a companion MeshCore radio over Bluetooth.

## Data We Process

The app may process the following data on your device:

- Bluetooth device identifiers (to discover and connect to your companion radio)
- Location data (to show your position on map and share telemetry when enabled)
- Camera access (only for scanning QR codes, e.g., channel import)
- Messages/channels/contacts used for mesh communication
- App settings and local cache (including offline map data)

## How Data Is Used

We use data to provide core app features:

- Connect to companion radio hardware
- Send and receive mesh messages
- Display and optionally share location telemetry
- Scan QR codes for channel sharing/import
- Store local app state and offline maps

## Data Sharing

- The app does not sell personal data.
- Data sent over the mesh network is shared only according to your app actions and selected channels.
- Local data remains on your device unless you explicitly share/export it.

## Data Storage

- Data is stored locally on your device.
- You can remove app data by uninstalling the app or clearing app storage in Android settings.

## Permissions

- **Bluetooth (`BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`)**: required to discover and connect to companion radio hardware.
- **Location (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`)**: required for map/telemetry features and BLE scanning behavior on some Android versions.
- **Background Location (`ACCESS_BACKGROUND_LOCATION`)**: used only when enabled to support telemetry/location features while the app is in background.
- **Foreground Service (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `FOREGROUND_SERVICE_CONNECTED_DEVICE`)**: used to maintain reliable background BLE connectivity and related location/device operations.
- **Wake Lock (`WAKE_LOCK`)**: helps keep critical background mesh operations running reliably.
- **Notifications (`POST_NOTIFICATIONS`)**: used for message alerts and foreground-service status.
- **Camera (`CAMERA`)**: used only for QR code scanning (for example, channel import/share).
- **Battery Optimization Exemption (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`)**: requested so users can allow stable long-running background connectivity.
- **Network (`INTERNET`)**: used for online map tiles and optional network-based app functionality.
- **Storage (`READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE` on older Android versions)**: used for user-driven import/export flows such as GPX files.

## Children

This app is not directed to children under 13.

## Security

We take reasonable steps to protect local app data, but no method of storage or transmission is 100% secure.

## Changes to This Policy

We may update this policy from time to time. Updates will be posted at this URL with a revised date.

## Contact

For privacy questions, contact: meshcore.team.beta@gmail.com
