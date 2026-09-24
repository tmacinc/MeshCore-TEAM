# Screenshots

This folder is referenced by the main [README](../../README.md) so screenshots render on GitHub.

## Naming scheme

Use this stable naming scheme so README links don’t change:

- `01-connection.png` — Connection
- `02-identity.png` — Identity
- `03-connection2.png` — Scanning
- `04-connection3.png` — Connected radio
- `05-radiosettings.png` — Radio settings
- `06-teamconfigmenu.png` — Team Config menu
- `07-teamconfigexport.png` — Team Config export
- `08-settings.png` — Settings: general
- `09-settings.png` — Settings: location tracking
- `10-settings.png` — Settings: data
- `11-settingsRedLightTheme.png` — Red Light theme
- `12-map.png` — Map
- `13-mapSat.png` — Satellite map
- `14-mapSettingsmenu.png` — Map settings menu
- `15-addwaypoint.png` — Add waypoint
- `16-addRoute.png` — Add route

## Capture guidelines

- Prefer **real devices** over emulators for BLE-related screens.
- Use light mode (default) and keep sensitive info out of the shot.
- Crop to just the app UI (avoid notification shade / system UI overlays).

### Android (ADB)

From a connected device:

- Save to local file:
  - `adb exec-out screencap -p > 01-connection.png`

If you’re on PowerShell and `>` produces a corrupt PNG, use:

- `adb exec-out screencap -p | Set-Content -Encoding Byte -Path 01-permissions.png`
- `adb exec-out screencap -p | Set-Content -Encoding Byte -Path 01-connection.png`

### iOS

Use Xcode simulator/device screenshot tools, then export as PNG with the filenames above.
