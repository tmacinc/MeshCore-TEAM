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
