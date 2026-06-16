# TODO

## Bugs

- [ ] **Dual sync race on rapid reconnect**: `_performInitialSync` sets `_syncStatus` to non-idle only after a 500ms `await`, so a second `connected` event within that window bypasses the in-progress guard and launches a concurrent sync. Fix: set `_syncStatus` to a non-idle phase synchronously at the top of `_performInitialSync` before the first `await`. (`lib/viewmodels/connection_viewmodel.dart`)
