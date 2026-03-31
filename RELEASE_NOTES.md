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
