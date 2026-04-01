# Release Notes — v1.0.3-beta2

## Team Config Export / Import
- New **Create Team Config**, **Import Team Config**, and **Share Config Offline** options in the Connection screen menu (visible when connected).
- Export channels, waypoints, radio settings, and offline map tiles as a portable `.teamcfg.zip` file.
- Named configs — give each export a descriptive name (stored in the manifest).
- Per-item selection — choose exactly which channels, waypoints, and map areas to include.
- Radio settings export includes frequency, bandwidth, spreading factor, and coding rate (TX power excluded — each radio keeps its own value).
- Import requires an active companion connection — channels are registered with the firmware, radio settings applied, waypoints merged (dedup by meshId + name/location), and map tiles added to cache.
- Two import methods: **From File** (local file picker) or **From QR Code** (scan and download from a nearby device).
- Preview dialog shows full config contents before importing.
- Offline map tiles are packaged inside the ZIP and restored into the tile cache on import.
- File saved via system file picker; compatible with Android and iOS.

## Offline Config Sharing
- New **Share Config Offline** option — serve a `.teamcfg.zip` over a local Wi-Fi hotspot without internet.
- Guided setup: platform-specific hotspot instructions (Android/iOS), file picker, config confirmation, then one-tap serving.
- Displays a QR code for receivers to scan from the **Import Team Config → From QR Code** flow.
- Manual URL fallback shown below the QR code.
- Download counter tracks how many devices have fetched the config.
- Server shuts down cleanly when the user taps **Finished**.
- Download progress bar with MB counter when importing via QR code.

## Wipe Local Data
- New **Wipe Local Data** option in the Connection screen menu.
- Choose which data to clear: private channels, waypoints & routes, offline maps.
- Channels are cleared from the companion radio firmware before being removed from the local database.
- Double confirmation — a second "Are you sure?" dialog before any data is deleted.
- Items with no data are shown as disabled.

## Fixes
- Fixed out-of-memory crash when exporting or importing large configs with many map tiles. File data is no longer passed through the Flutter method channel — all transfers use temp files and direct file I/O.

---

# Release Notes — v1.0.3

## Route Colors
- Routes can now be assigned a color from a 10-color preset palette when saving.
- Route colors are shared over the mesh network and displayed on the map.
- Color is preserved when editing routes and when receiving multi-part routes.

## Contact Path History
- Contact movement trails can be displayed on the map.
- Paths render as dotted lines (black with white outline) with dots at each GPS fix.
- Global "Show Contact Paths" toggle in the map settings menu to show/hide all paths.
- Per-contact "Show Path" / "Hide Path" button in the contact details dialog.
- Global and per-contact toggles stay in sync — toggling all on/off updates individual states, and individually hiding the last contact turns off the global toggle.
- 25-meter stationary gate prevents point clustering when a contact is not moving.
- Position history is thinned to 50 real GPS points per contact (no averaging).

## GPX Export
- GPX export now uses a file picker dialog on both Android and iOS instead of saving to a hardcoded Downloads directory.

## Bug Fixes
- Fixed keyboard overflow when saving a route with a long name or description.
- Fixed received multi-part routes losing their color.
- Fixed literal `\n` showing in the manage waypoints subtitle instead of a newline.
- Removed "Route" from the waypoint type dropdown in the create waypoint dialog.

---

# Release Notes — v1.0.2

## iOS Support
- Full iOS platform support added.
- iOS BLE lifecycle improvements: deferred reconnect, sequential permissions, and stale connection cleanup.
- Removed unnecessary background location dialog on Android.

## Telemetry
- Moved telemetry handling into Dart on Android so both location streams use the same logic.
- Fixed Dart sending V2 telemetry, V2 null byte protection, and adverts being zero hop.

## Map & Location
- Fixed slow location updates on the map by adding periodic GPS polling as a safety net.
- Restored compass heading via the compassx plugin (replaces flutter_compass).
- Fixed compass heading not updating — first heading event was silently dropped due to a delta-wrapping bug.

## Forwarding
- Forwarding policy engine now requires more than 2 group members on the tracking channel before activating.

## Bug Fixes
- Fixed crash when opening location settings with no private channel.
- Fixed bug when adding a channel via deep link.
