# Release Notes — unreleased

## Your name on the team
- You can now set **your name**: an in-app name only members of your team channel can see, so your radio name can stay anonymous on the mesh. You're asked for one when the app first starts; skipping it keeps today's behaviour of showing your radio name.
- Team members appear under the name they chose on the map, in contacts, in chat and in notifications, with their radio name kept underneath. Replies and @mentions still use radio names, so your chosen name never reaches a public channel.
- Change it any time in **Settings → General**.

## Team channels
- A **team channel** belongs to your phone rather than one radio: it survives changing radio, along with its chat history, and is offered back to the new radio when you use it.
- A team channel the radio doesn't hold is greyed out and marked *Not on this radio*; you can still read it, and adding it back is one tap.
- New **Settings → General** section holding your name and a *Hide all but team channels and contacts* toggle.
- Team channel history is kept for 30 days; map trails for 24 hours, while each member's last known position is kept indefinitely.

## Contacts and discovery
- Your radio no longer stores every device it hears. Team members are added automatically, and everyone else appears under **Heard nearby** on the Contacts tab, where you can add or dismiss them.
- Team contacts are copied onto a newly paired radio, so changing radio doesn't cost you the group.
- Changing radio, or swapping radios with a teammate, no longer makes you appear twice: your team recognises your phone, not just your radio.
- Discovery now also asks a specific member to identify themselves, which fixes finding people who already have you, one-way links, and members who changed radio.
- Fixed: contact discovery silently failed on radios set not to add contacts automatically.

## Fixes
- Location tracking can no longer be set to a hashtag channel, whose key anyone can derive from its name; an existing one is cleared.
- Telemetry senders are matched to contacts by exact name only. The old fuzzy match could attach someone to an unrelated contact, overwriting its name and position and suppressing discovery.
- Changing radio no longer puts you on your own map. A radio with no phone attached stores the team traffic it hears, including yours, and hands it over when you connect to it; your own beacons were being taken for a teammate on the radio you had just left. Any such copy of you already in the group is removed.
- A teammate carrying a radio you once used, including after swapping radios with you, no longer splits into a second contact under the radio's name while their named one goes stale, and their beacons are no longer mistaken for your own. A teammate who turns up on a radio you already have a contact for is asked who they are, instead of staying unnamed until their hourly check-in.

# Release Notes — v1.1.5

## Localization
- Full internationalization support — in-app text is now translatable, and the app follows your device language automatically.
- German translation added.

## Contacts
- Search contacts by name or public-key hash.
- Filter and sort the contact list, and mark contacts as favorites to keep them at the top.
- Delete contacts, with an optional auto-purge that removes stale contacts after a configurable number of days.
- Device clock is synced to the companion radio on connect.

## Channels
- Per-channel notification modes — set each channel to normal, muted, or favorite.
- Notification mode and favorite status now persist across syncs.
- Fixed the muted-channel badge and made channel list sorting stable, with unread marked immediately.

## Messaging
- Long-press (or right-click on desktop) a message to copy its text or reply.
- Replying seeds an `@[name]` mention; `@` autocomplete suggests names from the channel history.
- New-message indicator — the chat holds its scroll position when messages arrive instead of jumping, and shows a badge for unread messages below the fold.
- Message timestamps now show relative dates.

## Status Bar & Navigation
- Status icons and the app menu are now available on every screen, including chat screens.
- Filter and sort controls moved into top-bar dropdown menus for a cleaner layout.
- New network-bar shortcuts: toggle location tracking, and disconnect/reconnect the companion radio, directly from the status bar.
- Mouse back button now navigates back (desktop).

## Android
- New "keep screen on / show over lock screen" option so the app stays visible on the lock screen when needed.

## iOS
- Background operation overhauled — location sharing and telemetry now keep running while the app is backgrounded or the screen is locked (tested working). Every location consumer shares one background location session so iOS no longer suspends tracking shortly after backgrounding.
- Improved BLE reliability, including CoreBluetooth state restoration.
- The Bluetooth / local-network permission prompt no longer appears before the permission explainer screen.

## Performance & Stability
- Large reduction in Android ANRs (app-not-responding) and notification spam during message sync.
- Faster reconnects using incremental contact sync on advert updates.
- Lower per-message rebuild cost and smoother chat scrolling; the database now opens on a background thread.

## Bug Fixes
- Fixed the share-channel QR dialog rendering (forced black-on-white, resolved layout assertion, removed duplicate repeater label).
- BLE scan filtering, added support for firmwares that aren't official Meshcore. WhisperOS etc. These will need testing

---

# Release Notes — v1.1.4

## KMZ Overlay Maps
- Import Garmin-style KMZ custom map files as raster overlays displayed directly on the map.
- KMZ tiles are extracted locally and rendered as georeferenced overlays with automatic zoom-level selection — higher-detail pyramid levels are shown when zoomed in, lower-detail levels when zoomed out, keeping tile count within budget.
- Manage imported maps from the map settings menu: toggle visibility, delete maps.
- Import progress is shown with a tile counter during extraction.

## Overlay Maps in Team Config
- KMZ overlay maps can now be included in a team config export.
- Per-map checkbox selection on the Create Team Config screen.
- On import, the full tile set is extracted and the map appears immediately in the recipient's Manage Imported Maps list.
- Duplicate detection: maps with the same name or identical bounds are skipped on import.

## Hashtag Channels
- Create channels using hashtag syntax directly from any chat screen.
- `@mention` suggestions appear when typing `@` — autocomplete from known contacts.
- Hashtag channel links are rendered as tappable chips in messages.

## Direct Message Routing
- Improved DM delivery with automatic retry logic for unacknowledged messages.
- Route discovery retries on failure before falling back to broadcast.

---

# Release Notes — v1.1.3

## Bug Fixes
- Fixed companion GPS enable/disable not taking effect until app restart.
- Fixed TX power being reset to default when entering camp mode.

---

# Release Notes — v1.1.2

## App Icons
- Updated app icon and launch images on Android and iOS.

## Bug Fixes
- Fixed BLE write response detection for ESP32-based devices on iOS — resolves connection issues where commands were silently dropped.

---

# Release Notes — v1.0.3-beta3

## Bug Fixes
- Fixed out-of-memory crash when exporting large team configs. File data is no longer passed through the Flutter method channel — exports now write to a temp file and use the system file picker directly.

---

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
- Fixed keyboard overflow when saving a route with a long name or description (carried forward from v1.0.3).

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
