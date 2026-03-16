# Screenshots

This folder is referenced by the main [README](../../README.md) so screenshots render on GitHub.

## Naming scheme

Use this stable naming scheme so README links don’t change:

- `01-connection.png` — Connection
- `02-identity.png` — Identity prompt
- `03-connection2.png` — Connection (sync)
- `04-radiosettings.png` — Radio settings
- `05-trackingsettings.png` — Location tracking
- `06-contacts.png` — Contacts
- `07-directmesage.png` — Direct message
- `08-channels.png` — Channels
- `09-privatechannel.png` — Private channel
- `10-sharechannel.png` — Share channel
- `11-createAddchannel.png` — Create/Add channel
- `12-map.png` — Map

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
