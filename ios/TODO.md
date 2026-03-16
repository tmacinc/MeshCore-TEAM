# iOS parity TODO (vs Android)

This checklist tracks what the iOS build is missing/needs relative to the Android implementation.

> Note: iOS has hard OS limits on background BLE and long-running work. Some Android behaviors (native foreground service that runs indefinitely) cannot be replicated 1:1.

## Build & project setup

- [x] Add `Podfile` for Flutter plugins (required for `pod install`).
  - File: `ios/Podfile`
- [ ] Verify CocoaPods + workspace wiring on macOS.
  - Steps: `flutter pub get` → `cd ios && pod install`
  - Expectation: `Runner.xcworkspace` includes a `Pods` project after install.
- [ ] Confirm iOS deployment target consistency.
  - `Runner.xcodeproj` currently sets `IPHONEOS_DEPLOYMENT_TARGET = 13.0`.
  - Keep `Podfile` platform aligned (currently `platform :ios, '13.0'`).

## Permissions / privacy prompts

- [ ] Ensure iOS requests the correct location permission level when background tracking is enabled.
  - Today the app requests `Permission.location` (permission_handler), which typically maps to **When In Use**.
  - If true background tracking is required, implement an explicit flow to request **Always** (and handle the two-step iOS upgrade UX).
  - Files to review:
    - `lib/screens/permissions_screen.dart`
    - `ios/Runner/Info.plist` (already contains Always/WhenInUse strings)

- [ ] Validate Bluetooth permission UX on iOS.
  - `ios/Runner/Info.plist` includes Bluetooth usage strings.
  - Confirm the BLE scan/connect path works on a real device (iOS simulators don’t support BLE).

## Background operation parity (biggest gap)

Android uses a native foreground BLE service. iOS cannot run a true foreground service.

- [ ] Decide the iOS background strategy (documented + implemented).
  - Options usually include:
    - Background BLE central mode + state restoration (best-effort)
    - Background location updates (if always-location is granted)
    - User-visible expectation: connection may drop when app is backgrounded.

- [ ] Validate/adjust background modes & capabilities.
  - `ios/Runner/Info.plist` already declares:
    - `UIBackgroundModes`: `bluetooth-central`, `location`, `processing`
  - Still required: enable the corresponding Background Modes capability in Xcode Signing & Capabilities.

- [ ] Review `flutter_foreground_task` usage on iOS.
  - The app currently initializes and starts `flutter_foreground_task` for non-Android platforms.
  - Confirm this actually does what we expect on iOS (many "foreground task" behaviors are Android-centric).
  - File: `lib/services/mesh_connection_service.dart`

- [ ] iOS reconnection reliability work.
  - Ensure `ReconnectionManager` runs appropriately when returning to foreground.
  - Consider adding: app lifecycle hooks to trigger reconnect attempts when the app resumes.
  - Files:
    - `lib/ble/reconnection_manager.dart`
    - `lib/screens/main_navigation_screen.dart` (lifecycle observer)

## Notifications

- [ ] Confirm local notifications permissions/behavior on iOS.
  - iOS requires explicit user permission; ensure the permission request timing is correct.
  - Validate notification tap routing on iOS (deep navigation from payload).
  - Files:
    - `lib/main.dart` (FlutterLocalNotifications init + tap handler)
    - `lib/services/message_notification_service.dart`

- [ ] Verify iOS foreground-notification suppression behavior.
  - The code tracks `MessageNotificationService.isAppInForeground`.
  - Confirm it updates correctly with iOS scene lifecycle (multi-scene / backgrounding).

## Deep links (meshcore://)

- [ ] Validate deep link handling end-to-end on iOS.
  - `Info.plist` includes the `meshcore` URL scheme.
  - Confirm incoming `meshcore://channel/add?...` links open the app and route to import.
  - Files:
    - `ios/Runner/Info.plist` (URL scheme)
    - `lib/widgets/deep_link_listener.dart`

## BLE feature parity

- [ ] Confirm scanning works on iOS with current permission flow.
  - BLE scan on iOS behaves differently vs Android (timing, background, device name visibility).

- [ ] Confirm the Android-specific native service APIs are not required on iOS.
  - Android calls:
    - `_bleManager.startNativeService()` / `.stopNativeService()`
  - Ensure iOS never hits these paths.

## QA checklist (iOS)

- [ ] Fresh install flow: Permissions → Scan → Connect → Sync.
- [ ] App backgrounded for 1–5 minutes: connection state on resume.
- [ ] Track-up + compass + course behavior.
- [ ] QR scan (camera) and share sheet.
- [ ] Offline maps download + cache reuse.

## Docs

- [ ] Add an iOS section to the main README explaining expected limitations.
  - Keep it honest: iOS background BLE is best-effort.
