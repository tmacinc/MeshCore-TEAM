---
name: drift-migration-raw-sql
description: Drift gotcha — typed queries inside onUpgrade read the current schema and crash on older databases; use raw SQL in migration steps
metadata:
  type: project
---

A typed drift query (`select(contacts)`, `update(messages)`, a DAO call) maps
rows to today's data class, so it expects every column in today's
`tables.dart`. Inside `onUpgrade`, an earlier step runs before later steps have
added their columns, so the query reads NULL for a NOT NULL column and throws
`Null check operator used on a null value` from `database.g.dart`.

This froze the 1.1.7 → 1.2.0-beta4 upgrade on the splash screen: the v12 step
looked up `contacts` while `hide_on_map` (added in v15) didn't exist yet. Every
launch re-ran the step and crashed again, until the app was reinstalled.

- Use `customStatement` / `customSelect` with explicit columns in migration
  steps. DDL through `Migrator` (`createTable`, `addColumn`) is fine.
- `onUpgrade` runs in one transaction (`_upgrade`), so a failing step leaves
  the database at its old version instead of half-migrated.
- Test migrations from a database built with the old release's exact DDL
  (see `test/upgrade_clean_start_test.dart`), not from today's tables with
  columns dropped. A database built from today's tables already has the new
  columns, which hides this bug.
