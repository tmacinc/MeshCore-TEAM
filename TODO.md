# TODO

## Bugs

- [ ] **Channel sync progress freezes at end**: after fetching all channels from firmware, the repository deletes then re-inserts them one by one with sequential `await` calls (lines 698-710) before emitting `isComplete`, causing the UI to appear frozen. Fix: wrap the delete and insert loop in a single database transaction. (`lib/repositories/channel_repository.dart`)

- [ ] **Dual sync race on rapid reconnect**: `_performInitialSync` sets `_syncStatus` to non-idle only after a 500ms `await`, so a second `connected` event within that window bypasses the in-progress guard and launches a concurrent sync. Fix: set `_syncStatus` to a non-idle phase synchronously at the top of `_performInitialSync` before the first `await`. (`lib/viewmodels/connection_viewmodel.dart`)
