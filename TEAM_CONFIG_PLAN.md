# Team Config — Export, Import & Share

## Overview

A team leader builds a self-contained mission package (`.teamcfg.zip`) containing channels, waypoints, routes, and offline map tiles. This file is saved locally for reuse across missions and can be shared with team members via any available method.

Two distinct workflows:
1. **Build & Save** — Create the config file locally (export available anytime)
2. **Import** — Import requires an active companion connection (channels must be registered with firmware)
3. **Share** — Send a saved config to other devices (deferred to Phase 2+)

---

## File Format: `.teamcfg.zip`

A standard ZIP archive containing:

```
manifest.json              # Package metadata
config.json                # Channels, waypoints, routes
tiles/                     # Offline map tile images (optional)
  {providerId}/
    {z}/{x}/{y}.png
tile_areas.json            # Offline map area definitions (bounds, zoom, provider)
```

### manifest.json
```json
{
  "version": 1,
  "createdAt": "2026-03-31T12:00:00Z",
  "creatorName": "Team Leader",
  "description": "Operation Alpha base camp config",
  "includesChannels": true,
  "includesWaypoints": true,
  "includesTiles": true,
  "tileCount": 4200,
  "tileSizeBytes": 84000000
}
```

### config.json
```json
{
  "channels": [
    {
      "name": "TEAM 6",
      "sharedKeyHex": "aabbccddee00112233445566778899aa",
      "hash": 12345678,
      "isPublic": false,
      "shareLocation": true
    }
  ],
  "waypoints": [
    {
      "id": "uuid-here",
      "meshId": "mesh-id-or-null",
      "name": "Base Camp",
      "description": "{\"points\":[...],\"color\":4294198070}",
      "latitude": 37.7749,
      "longitude": -122.4194,
      "waypointType": "CAMP",
      "creatorNodeId": "!aabbccdd",
      "createdAt": 1711900000
    }
  ]
}
```
- Waypoints and routes use the same schema (routes are `waypointType: "ROUTE"` with route payload in `description`)
- `sharedKeyHex` is the 16-byte PSK as a 32-char hex string — same format used in `meshcore://` deep links
- `channelIndex` is NOT exported — the receiver assigns the next available slot on import
- `creatorNodeId` is exported; on import, it is preserved if present, otherwise set to the importer's companion node ID
- On import, waypoints default to `isReceived: false`, `isVisible: true`, `isNew: true`

### tile_areas.json
```json
{
  "areas": [
    {
      "name": "Base Camp Region",
      "providerId": "mapnik",
      "north": 37.80,
      "south": 37.75,
      "east": -122.38,
      "west": -122.45,
      "minZoom": 10,
      "maxZoom": 16,
      "tileCount": 4200,
      "sizeBytes": 84000000
    }
  ]
}
```

### tiles/ directory
Tiles stored as `tiles/{providerId}/{z}/{x}/{y}.png`. On export, tiles are read from `flutter_cache_manager` via `cacheManager.getFileFromCache(url)`. On import, tiles are written back into the cache via `cacheManager.putFile(url, bytes)`.

---

## Workflow 1: Build & Save Config

### New Dependencies
```yaml
dependencies:
  archive: ^4.0.0  # ZIP read/write
```

### UI: Team Config Screen

New screen: `lib/screens/team_config_screen.dart`

**Entry point:** Settings icon button (⚙️) in the Connection screen AppBar, positioned to the right of the connection status indicator. Only visible when a companion device is connected.

```
┌─────────────────────────────────────┐
│ MeshCore TEAM            [🔧] [🟢] │  ← settings button + status indicator
├─────────────────────────────────────┤
│ (connected device view)             │
└─────────────────────────────────────┘
```

Tapping the settings button opens the Team Config screen.

**Screen layout:**
```
┌─────────────────────────────────┐
│ ← Team Config                   │
├─────────────────────────────────┤
│                                 │
│ ── Export Config ────────────── │
│                                 │
│ ┌─ Select Channels ───────────┐ │
│ │ ☑ TEAM 6                    │ │
│ │ ☐ Public                    │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─ Waypoints & Routes ────────┐ │
│ │ ☑ Include all (12 items)    │ │
│ │   or ☐ Select individually  │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─ Offline Map Areas ─────────┐ │
│ │ ☑ Base Camp (84 MB, 4200)   │ │
│ │ ☑ Route Alpha (22 MB, 1100) │ │
│ │ ☐ Downtown (340 MB, 17000)  │ │
│ └─────────────────────────────┘ │
│                                 │
│ Estimated size: ~106 MB         │
│                                 │
│ [ Export Config ]               │
│                                 │
│ ── Import Config ────────────── │
│                                 │
│ [ Select .teamcfg.zip file ]    │
│                                 │
└─────────────────────────────────┘
```

**Import is gated on connection:** The "Select .teamcfg.zip file" button is only enabled when the companion device is connected. If disconnected mid-import, channel registration is queued and retried on next connection (same as existing `importChannel()` behavior).

### Export Implementation

**Service: `lib/services/team_config_service.dart`**

```
class TeamConfigService
  Future<File> exportConfig({
    required List<ChannelData> channels,
    required List<WaypointData> waypoints,
    required List<OfflineMapAreaData> mapAreas,
    required MapTileCacheService tileCache,
    required String description,
    void Function(TeamConfigProgress)? onProgress,
  })

  Future<TeamConfigContents> readConfigManifest(File zipFile)

  Future<void> importConfig({
    required File zipFile,
    required AppDatabase db,
    required MapTileCacheService tileCache,
    required ChannelRepository channelRepo,
    void Function(TeamConfigProgress)? onProgress,
  })
```

**Export steps:**
1. Build `manifest.json` and `config.json` in memory
2. For each selected offline map area:
   a. Read tile area metadata from `OfflineMapAreas` table
   b. Enumerate all tile coordinates using `_tileBoundsForBounds()` (same logic as download/delete)
   c. For each tile coordinate, build the URL key and call `cacheManager.getFileFromCache(url)`
   d. If the file exists in cache, read its bytes and add to ZIP as `tiles/{providerId}/{z}/{x}/{y}.png`
   e. Report progress (current tile / total tiles)
3. Write ZIP to a temp file
4. Open `FilePicker.platform.saveFile()` to let user choose save location and filename
5. Copy temp file to chosen location

**Key considerations:**
- Export runs in an isolate or uses `compute()` for the ZIP compression to avoid UI jank
- Progress callback reports: packing channels, packing waypoints, packing tiles (N/total), writing file
- Cancel support via a flag checked between tiles
- The `flutter_cache_manager` `BaseCacheManager` has `getFileFromCache(key)` which returns `FileInfo?` — the `key` is the tile URL

### Import Implementation

**Import steps:**
1. User picks `.teamcfg.zip` via `FilePicker.platform.pickFiles()`
2. Read and parse `manifest.json` → show preview dialog:
   - Channels: X channels (list names)
   - Waypoints/Routes: X items
   - Map tiles: X tiles (~Y MB)
3. User confirms import
4. **Channels:** For each channel in `config.json`:
   - Construct a `meshcore://` deep link URL from `sharedKeyHex`, `name`, and flags (same format as QR/share links)
   - Call `ChannelRepository.importChannel(url)` — this handles:
     - Hash computation
     - Duplicate detection (skip if hash already exists)
     - Next available `channelIndex` assignment
     - DB insert via `ChannelsDao.upsertChannel()`
     - Firmware registration via `_registerChannelWithFirmware()` if connected
   - **Import requires active companion connection** — channels are registered with firmware immediately
   - If a channel already exists (hash match), it is skipped
5. **Waypoints/Routes:** For each waypoint:
   - Check for duplicate by `meshId` (if present) or by matching name + lat/lon
   - Skip duplicates, insert new ones via `WaypointsDao.insertWaypoint()`
   - Generate new UUID for `id` to avoid collisions, preserve `meshId` for dedup
6. **Tiles:** For each file in `tiles/` directory of the ZIP:
   - Reconstruct the tile URL from the path + provider's `urlTemplate`
   - Write bytes into cache via `cacheManager.putFile(url, bytes, key: url)`
   - Insert/update `OfflineMapAreas` record from `tile_areas.json`
   - Report progress
7. Show success summary: "Imported 1 channel, 12 waypoints, 4200 tiles"

**Merge rules:**
| Data type | Duplicate detection | On duplicate |
|-----------|-------------------|--------------|
| Channel | Hash match | Skip (already exists) |
| Waypoint | meshId match, or name+lat+lon within 10m | Skip |
| Route | meshId match, or name+lat+lon within 10m | Skip |
| Map area | Same providerId + overlapping bounds + same zoom | Merge (add missing tiles) |
| Tile | Same URL key | Skip (already cached) |

---

## Workflow 2: Share Config (Deferred)

Sharing will be added in a later phase. The export produces a `.teamcfg.zip` file saved to local storage via `FilePicker.platform.saveFile()`. Users can share this file manually (email, messaging, USB, cloud drive, AirDrop, Quick Share, etc.).

When share is implemented, it will integrate into the Team Config screen with these options:

### Option A: OS Share Sheet

Share via `share_plus`:
```dart
await Share.shareXFiles(
  [XFile(configFile.path)],
  subject: 'Team Config — Operation Alpha',
);
```

### Option B: Local Wi-Fi Server (offline cross-platform)

**New dependencies:**
```yaml
dependencies:
  shelf: ^1.4.0
  shelf_io: ^1.1.0
```

**Sender flow:**
1. User taps "Share via Wi-Fi" on a saved config
2. App starts an HTTP server on a random available port:
   ```
   GET /manifest  → returns manifest.json (for preview)
   GET /config    → streams the .teamcfg.zip file
   ```
3. App determines local IP address (`NetworkInterface.list()`)
4. Displays a screen with:
   - Instructions: "Create a mobile hotspot or ensure devices are on the same Wi-Fi network"
   - QR code encoding: `teamcfg://192.168.x.x:port`
   - The IP:port in text (manual fallback)
   - "Stop Sharing" button
5. Server stays alive until user stops or app backgrounds

**Receiver flow:**
1. User taps "Import via Wi-Fi" (or scans QR from in-app scanner — `qr_scan_screen.dart` already exists)
2. App parses `teamcfg://` URL → extracts IP and port
3. Fetches `GET /manifest` → shows preview (same as file import)
4. User confirms → streams `GET /config` → saves to temp file → runs the same import logic as Workflow 1
5. Progress bar during download

**QR scanning:** The app already has `qr_scan_screen.dart`. Add a handler for the `teamcfg://` URL scheme alongside the existing `meshcore://` handler.

---

## File Registration (Optional Enhancement)

Register `.teamcfg.zip` as a file type the app can open:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <data android:mimeType="application/zip" />
  <data android:pathPattern=".*\\.teamcfg\\.zip" />
</intent-filter>
```

**iOS** (`ios/Runner/Info.plist`):
Add `CFBundleDocumentTypes` and `UTImportedTypeDeclarations` for the `.teamcfg.zip` extension.

When the app is opened via a file, route to the import preview screen automatically.

---

## Implementation Phases

### Phase 1: Export & Import (core)
**Files to create:**
- `lib/services/team_config_service.dart` — Export/import logic, ZIP packing/unpacking
- `lib/screens/team_config_screen.dart` — UI for building and importing configs

**Files to modify:**
- `pubspec.yaml` — Add `archive` dependency
- `lib/services/map_tile_cache_service.dart` — Add public tile helpers:
  - `Future<Uint8List?> getTileBytes(String url)` — Get cached tile bytes by URL key
  - `Future<void> putTileBytes(String url, Uint8List bytes)` — Write tile bytes into cache
  - `List<String> tileUrlsForRegion(bounds, minZoom, maxZoom, urlTemplate, subdomains)` — Enumerate tile URLs for a region (expose existing `_tileBoundsForBounds` + `_buildTileUrl` logic)
  - Both wrap `cacheManager.getFileFromCache(key)` and `cacheManager.putFile(key, bytes)`
- `lib/screens/connection_screen.dart` — Add settings icon button (⚙️) in AppBar `actions`, before the connection status indicator, visible only when `bleManager.isConnected`. Navigates to `TeamConfigScreen`.
- `lib/database/daos/offline_map_areas_dao.dart` — Add `findByProviderAndBounds()` query for duplicate/merge detection on import

**Channel import strategy:**
- For each channel in `config.json`, construct a `meshcore://` deep link URL from `sharedKeyHex` + `name` + flags
- Call `ChannelRepository.importChannel(url)` which handles hash, dedup, index assignment, DB insert, and firmware registration
- No need to expose private `_calculateHash()` or `_bytesToHex()` methods

### Phase 2: Share via OS Share Sheet
**Files to modify:**
- `lib/screens/team_config_screen.dart` — Add "Share" button using `share_plus` on exported file

### Phase 3: Share via Local Wi-Fi Server
**Files to create:**
- `lib/services/team_config_server.dart` — HTTP server using `shelf` + `shelf_io`

**Files to modify:**
- `pubspec.yaml` — Add `shelf`, `shelf_io`
- `lib/screens/team_config_screen.dart` — Add "Share via Wi-Fi" UI with QR display
- `lib/screens/qr_scan_screen.dart` — Handle `teamcfg://` URL scheme

### Phase 4: File Association (optional)
**Files to modify:**
- `android/app/src/main/AndroidManifest.xml` — Register file type
- `ios/Runner/Info.plist` — Register file type
- `lib/main.dart` — Handle incoming file intents

---

## Relevant Existing Code

| Purpose | File | Key functions/patterns |
|---------|------|----------------------|
| Channel export as URL | `lib/repositories/channel_repository.dart` | `exportChannelKey()`, `_bytesToHex()` |
| Channel import from URL | `lib/repositories/channel_repository.dart` | `importChannel()`, hash computation |
| Waypoint DAO | `lib/database/daos/waypoints_dao.dart` | `insertWaypoint()`, `getWaypointByMeshId()` |
| Channel DAO | `lib/database/daos/channels_dao.dart` | `upsertChannel()`, `getChannelByHash()` |
| Offline map areas DAO | `lib/database/daos/offline_map_areas_dao.dart` | `insertArea()`, `getAllAreas()` |
| Tile cache service | `lib/services/map_tile_cache_service.dart` | `downloadRegion()`, `_buildTileUrl()`, `_tileBoundsForBounds()` |
| Tile URL generation | `lib/services/map_tile_cache_service.dart` | `_buildTileUrl(urlTemplate, subdomains, x, y, zoom)` |
| Tile providers | `lib/models/map_tile_providers.dart` | `tileProviderForId()`, `kMapTileProviderOptions` |
| GPX file export pattern | `lib/screens/manage_waypoints_screen.dart` | `FilePicker.platform.saveFile()`, `Share.shareXFiles()` |
| GPX file import pattern | `lib/screens/manage_waypoints_screen.dart` | `FilePicker.platform.pickFiles()` |
| QR scanning | `lib/screens/qr_scan_screen.dart` | Existing scanner UI |
| Deep link handling | `lib/main.dart` | `meshcore://` URL handler |
