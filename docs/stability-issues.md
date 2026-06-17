# Stability Issues

Findings from static analysis of the codebase. Issues are grouped by severity.
Each entry includes a trigger scenario for manual or automated verification.

---

## Critical

### ~~1. Double-complete crash on Completer (connection_viewmodel.dart:404)~~

~~A timeout Timer completes a Completer at line 404, but there is no guard against the
BLE response arriving concurrently and completing the same Completer a second time.
Completing an already-completed Completer throws a StateError and crashes.~~

~~**Trigger:** Connect to a device that responds very quickly (sub-100ms). The timeout
and the response fire close together. Reproduce reliably by throttling BLE in a test
harness or with a mock that responds after a short sleep.~~

**False positive.** Code review of the actual implementation shows both paths are
already guarded. The stream listener checks `completer.isCompleted` on entry (line 387)
and the timer checks it before calling `complete()` (line 405). No bug exists here.

---

### ~~2. Double-complete crash on contact sync timeout (contact_repository.dart:261)~~

~~Same pattern as above: a periodic timer fires after the contact sync Completer is
already completed by a BLE response, causing a StateError crash.~~

~~**Trigger:** Connect to a companion that is slow to respond but does respond before
the 100ms window closes. Toggle BLE on/off rapidly while syncing contacts.~~

**False positive.** Every `completer.complete()` call in the timer is guarded with
`!completer.isCompleted` (lines 273, 290, 308). No bug exists here.

---

### ~~3. Hang on channel fetch with unresponsive firmware (channel_repository.dart:840)~~

~~The pipelined channel fetch awaits `completion.future` at line 881. The max-wait timer
cancels but the future can remain pending if the stream subscription is not also closed,
leaving the sync coroutine stuck indefinitely.~~

~~**Trigger:** Start channel sync, then power off the companion mid-fetch. The app should
time out and recover; if it hangs, this is the cause.~~

**False positive.** `completeIfPending` guards with `!completion.isCompleted`, the
`maxWaitTimer` fires it on timeout, and the `finally` block cancels both subscriptions
regardless of how the future resolves. No hang is possible here.

---

## High

### ~~4. Unhandled exception in battery poll timer (connection_viewmodel.dart:941)~~

~~`_pollBattery()` has no try-catch. If `sendFrame` throws during a disconnect, the
unhandled exception in the timer callback crashes the app.~~

~~**Trigger:** Initiate a battery poll (wait ~30 s after connecting), then immediately
disconnect the BLE device. Observe crash or logcat exception.~~

**False positive.** `_pollBattery()` has a try/catch at line 959 that catches and logs
any exception from `sendFrame`. No unhandled exception is possible here.

---

### ~~5. Unhandled exception in deep link listener (deep_link_listener.dart:31,38,45)~~

~~Three `unawaited()` calls in `initState` and the stream listener have no error handling.
A malformed or unexpected URI silently crashes the handler.~~

~~**Trigger:** Send a malformed `meshcore://` deep link to the running app (e.g. via
`adb shell am start -a android.intent.action.VIEW -d "meshcore://%invalid"`).~~

**False positive.** `_init()` wraps the initial link fetch in a try/catch and
`_handleUri()` has its own try/catch that surfaces errors via a SnackBar. Both paths
are covered.

---

### 6. UI jank from N sequential DB queries per stream emission (contacts_dao.dart:345)

`watchContactsWithUnreadByCompanion()` calls `getUnreadCountByContact()` and
`getMessageCountByContact()` sequentially for every contact on every stream emission.
With 50+ contacts this is 100+ synchronous-style DB round trips per update.

**Trigger:** Import or sync 50+ contacts, then send a message. Observe frame drops on
the contacts list screen using Flutter DevTools timeline.

**Fixed.** Added `getUnreadCountsForContacts()`, `getMessageCountsForContacts()`,
`getUnreadCountsForContactsByCompanion()`, and `getMessageCountsForContactsByCompanion()`
to `MessagesDao` — each issues a single `GROUP BY` query returning counts for all
contacts at once. Both `watchAllContactsWithUnread()` and
`watchContactsWithUnreadByCompanion()` in `ContactsDao` now call these instead of
looping, reducing N*2 round-trips per emission to 2 regardless of contact count.

---

### ~~7. Null dereference in BLE write catch block (ble_connection_manager.dart:474)~~

~~Line 477 accesses `_fbpRxChar!` inside a catch block without a null check. If the
device disconnects just as a write fails, the field may have been nulled during cleanup.~~

~~**Trigger:** Send a large message, then yank BLE power mid-write. Check logcat for a
null-check exception on top of the original write error.~~

**False positive.** Line 530 explicitly checks `if (_fbpRxChar == null)` and throws
before the `!` dereference on line 533. The catch block never touches `_fbpRxChar`.

---

### ~~8. GPS state inconsistency on disconnect during autonomous setup (connection_viewmodel.dart:220)~~

~~`setGpsEnabled(needsGps)` is awaited at line 246 while enabling autonomous mode. If
the device disconnects during that await, GPS is saved as enabled locally but the
device is offline and never configured.~~

~~**Trigger:** Enable autonomous mode, immediately toggle airplane mode. Re-enable radios
and reconnect; verify the device's GPS state matches the local setting.~~

**False positive.** The entire method is wrapped in a try/catch. A disconnect mid-await
throws, is caught, and returns `false`. Line 246 only runs if `verified` is true, so
GPS state is never saved locally on a failed or interrupted call.

---

### ~~9. Silent native method channel crash (telemetry_send_service.dart:179)~~

~~`invokeMethod` is wrapped in `.catchError()` but the error handler is itself
`unawaited()`. If the handler throws, the exception is completely swallowed.~~

~~**Trigger:** Revoke location permission while the app is running. The native call will
fail; confirm whether the UI reflects the failure or silently stops updating.~~

**False positive.** The `.catchError()` handler only logs the error via `debugPrint`
and cannot itself throw, so the unawaited pattern is safe here.

---

### 10. Stream error stops unread badge updates permanently (main_navigation_screen.dart:320,333)

`.listen()` calls at lines 320 and 333 have no `onError` handler. A single database
error kills the subscription; unread counts then freeze until app restart.

**Trigger:** Simulate a DB error (e.g. corrupt a test database, or provoke a drift
exception) and confirm badge counts stop updating.

**Fixed.** Added `onError` handlers to both `.listen()` calls that log the error and
keep the subscription alive.

---

## Medium

### ~~11. Subscription leak in overlay map loading (map_screen.dart:1226)~~

~~`_loadMissingOverlayTiles` calls `.listen()` on the overlay maps stream but never
stores or cancels the subscription. Each call to this method adds another live
listener.~~

~~**Trigger:** Open the map screen, add and remove overlay layers repeatedly (10+ times).
Monitor memory in DevTools; heap should grow steadily.~~

**False positive.** The subscription is stored in `_overlayMapsSub` (line 1225) and
cancelled in `dispose()` (line 1251).

---

### ~~12. KmzImportService instances never disposed (map_screen.dart:235)~~

~~A new `KmzImportService()` is created per overlay in a loop with no disposal. Multiple
instances accumulate in memory.~~

~~**Trigger:** Load 5+ KMZ overlay maps in one session. Check DevTools memory snapshot
for multiple `KmzImportService` instances.~~

**False positive.** A single `KmzImportService` instance is created once before the
loop (line 238) and reused for all overlays. The class has no `dispose` method and
holds no resources requiring cleanup.

---

### ~~13. Race condition on rapid location source toggle (telemetry_send_service.dart:318)~~

~~Rapid calls to `_applyConfigAndMaybeStartAsync()` can create overlapping
`Geolocator.getPositionStream()` subscriptions before old ones are cancelled.~~

~~**Trigger:** In settings, rapidly toggle the location source between "phone" and
"companion" 10+ times. Observe whether location updates double-fire or drain battery
faster than expected.~~

**False positive.** `_stopInternal()` cancels and nulls `_positionSub` before
`_startInternal()` creates a new one on source change (lines 221-222). No overlap
is possible.

---

### ~~14. Subscription accumulation in channel wait (channel_repository.dart:762)~~

~~`_waitForChannelOrError` creates a timeout Timer but on timeout does not cancel
`channelSub` and `errorSub`. These subscriptions live until GC.~~

~~**Trigger:** Trigger multiple rapid channel refreshes (e.g. spam the refresh button)
while the companion is slow to respond so timeouts fire. Monitor subscription count
in DevTools.~~

**False positive.** The timeout timer cancels both subscriptions unconditionally at
lines 794-795 regardless of whether the completer was already completed.

---

### ~~15. Frame subscription active after failed sync (connection_viewmodel.dart:621)~~

~~`_setupFrameSubscription()` is called at line 492 before the sync sequence. If the
sync throws, the subscription stays active and routes subsequent frames incorrectly.~~

~~**Trigger:** Connect to a device that fails the query handshake. Then connect to a
second device and observe whether messages from the second device are correctly
attributed.~~

**False positive.** `_setupFrameSubscription()` cancels any existing subscription at
line 628 before creating a new one, so re-entry is safe.

---

### ~~16. Race on autonomous settings (connection_viewmodel.dart:220)~~

~~Multiple interleaved async awaits in `_applyAutonomousSettings` can leave state
partially applied if any step is interrupted by a disconnect.~~

~~**Trigger:** Toggle autonomous mode on/off rapidly while connected. After stabilizing,
read back all autonomous settings and confirm they match the last intended state.~~

**False positive.** Same method as item 8 — the outer try/catch returns `false` on
any exception, preventing partial state from being saved.

---

### ~~17. Forwarding policy service has no dispose() (forwarding_policy_service.dart)~~

~~`_contactsSub`, `_telemetrySub`, `_topologySub`, `_displayStatesSub`,
`_companionKeySub`, and `_periodicTimer` are never cancelled; the class has no
`dispose()` method.~~

~~**Trigger:** Enable forwarding, navigate away, return repeatedly. Long-session memory
usage will grow due to accumulated subscriptions.~~

**False positive.** `dispose()` exists at line 438 and cancels all subscriptions and
the timer.

---

### ~~18. Unread count stream in inconsistent state on DB error (main_navigation_screen.dart:310)~~

~~`_getUnreadCounts()` builds a StreamController with two inner subscriptions. If either
throws an error the controller is left open with one dead and one live subscription,
emitting stale data indefinitely.~~

~~**Trigger:** Same as item 10 above; a DB error mid-stream leaves the controller in a
mixed state.~~

**Resolved by fix for item 10.** The `onError` handlers added to both subscriptions
keep them alive on error, so the controller never enters a mixed state.

---

### 19. Fire-and-forget contact sync with no error visibility (message_repository.dart:222,260)

Two `unawaited()` blocks handle contact sync and advert responses without try-catch.
Failures are invisible to the user and to logging.

**Trigger:** Simulate a repository error during advert handling (mock or fault injection).
Confirm the error is logged somewhere, or confirm it is silently swallowed.

**Fixed.** Wrapped both `unawaited` bodies in try/catch blocks that log the error via
`debugPrint`.

---

### 20. Blocking sequential DB queries in all-contacts stream (contacts_dao.dart:425)

`watchAllContactsWithUnread()` has the same N-query-per-emission pattern as item 6,
affecting the all-contacts view.

**Trigger:** Same as item 6 but using the global contacts list rather than a
companion-filtered one.

**Resolved by fix for item 6.** Both `watchAllContactsWithUnread()` and
`watchContactsWithUnreadByCompanion()` were updated together.

---

## Open TODOs

### 21. Channel sync progress freezes at end (channel_repository.dart:698)

After fetching all channels from firmware, the repository deletes then re-inserts them
one by one with sequential `await` calls (lines 698-710) before emitting `isComplete`,
causing the UI to appear frozen at the end of channel sync.

**Fixed.** Added `replaceAllChannels()` to `ChannelsDao` which wraps the full
delete-and-insert in a single Drift transaction. The repository now calls this instead
of the per-row loop, reducing N+1 DB round-trips to one atomic operation.

---

### 22. Dual sync race on rapid reconnect (connection_viewmodel.dart)

`_performInitialSync` sets `_syncStatus` to non-idle only after a 500ms `await`, so a
second `connected` event within that window bypasses the in-progress guard and launches
a concurrent sync.

**Fix:** Set `_syncStatus` to a non-idle phase synchronously at the top of
`_performInitialSync` before the first `await`.
