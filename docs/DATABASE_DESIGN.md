# FoldPulse — Database Design

**Owner:** Agent 3 (Architect) with Agent 7 (Data Analyst) · **Reviewed by:** Agent 8 (Privacy), Agent 11 (Performance)
**Version:** 1.1 (corrected after Phase 3 reviews) · 9 November 2026

---

## 1. Technology decision (final)

**SwiftData**, stored in the App Group container (DECISIONS T-2, confirmed T-6).

| Criterion | SwiftData | Core Data |
|---|---|---|
| Minimum iOS (27.1) | Fully available, mature since iOS 18 (`#Index`, `#Unique`, history) | Available |
| Migrations | `VersionedSchema` + `SchemaMigrationPlan` | Model versions + mapping models |
| Swift 6 concurrency | `@ModelActor` gives an isolated writer | Manual context/queue discipline |
| Widget compatibility | Not needed: widgets read a JSON snapshot | Same |
| Complexity | Low | Higher |

Core Data stays the fallback if SwiftData blocks something in Phase 4. `EventStore` hides the choice from the rest of the app.

## 2. Entity: `StoredEvent` (SchemaV1, version 1.0.0)

| Field | Type | Rules |
|---|---|---|
| `id` | UUID | **Unique.** `EventStore.add` **rejects** an existing id (`StoreError.duplicateID`) because SwiftData's `.unique` would silently overwrite the row. Never changes; the import merge key |
| `typeRaw` | String | `fold` / `unfold` (`EventType`) |
| `sourceRaw` | String | `hinge` / `shortcut` / `manual` / `inferred` (`DetectionSource`) |
| `timestamp` | Date | UTC instant of the event. **Indexed** |
| `timeZoneID` | String | IANA zone at capture, e.g. `Europe/London`. Kept when the time is edited |
| `localDay` | String | `YYYY-MM-DD` in the capture zone. **Indexed**; the key for daily buckets. Recomputed (in the capture zone) when the time is edited (`FoldEvent.setTimestamp`) |
| `note` | String? | ≤ 500 characters (enforced in Phase 4 UI) |
| `createdAt` | Date | First insert |
| `updatedAt` | Date | Bumped on every change; newer wins on import |
| `isEdited` | Bool | The user changed an automatically recorded event |
| `deletedAt` | Date? | **Tombstone.** Rows are never physically deleted except by Reset |
| `duplicateOf` | UUID? | Set when merged into another event by de-duplication (Phase 4) |
| `inferredIntervalStart/End` | Date? | For gaps: the window in which the missed event happened |

Rows whose `typeRaw` or `sourceRaw` the app doesn't recognise (written by a newer version) are **skipped, not guessed** (`StoredEvent.domainEvent`).

## 3. Derived data: computed, not stored

| Metric | Computed by | Notes |
|---|---|---|
| Totals, today, per-day series | `Statistics.total` / `.series` | Excludes tombstones, duplicates and (by default) gaps |
| Daily average | `Statistics.dailyAverage` | Last 7 **full** days before today, zero days included, never before the first tracked day |
| Coverage | `Statistics.coverage` | Share of **recorded** folds captured without tapping, plus gap count |
| Milestones | `Milestones` | Celebrated once; celebrated set persisted in Phase 4 (`UserDefaults`) |
| Widget snapshot | `WidgetSnapshot.make` | Written to JSON after each change |

**Performance:** a heavy user (~150 folds a day ≈ 300 events) creates ~110,000 rows a year, about 20–30 MB. Statistics are computed **once per reload inside the `EventStore` actor** (`loadState` → `DashboardStats`), off the main thread; views only read the result. Loading reuses the stored `localDay` and caches time zones, so there is no per-row calendar work. Tombstones are filtered in the fetch predicate. If Phase 5 profiling shows a need, per-day aggregate queries on the `localDay` index replace loading every row.

## 4. Files and protection

| File | Location | Protection | Writer | Readers |
|---|---|---|---|---|
| `FoldPulse.store` (+ `-wal`, `-shm`) | App Group container, `Store/` directory | `completeUntilFirstUserAuthentication`, **set explicitly on the directory** (new files inherit it). Verified on device in Phase 5 | App (`EventStore`) | App |
| `WidgetSnapshot.json` | App Group container | `completeUntilFirstUserAuthentication` (set explicitly on write) | App (`SnapshotService`) | Widget |
| `pending-events` queue (v1.1, widget button) | App Group | Same | Widget | App |

**No silent fallback:** release builds refuse to start (clear message) if the App Group is unavailable, rather than writing data to a private location that would be stranded later. Debug/CI builds fall back to Application Support.

**Backups:** App Group data is included in the user's own iCloud or Finder device backups (PRIVACY_REVIEW P-7). Deleting the app deletes the data.

## 5. Snapshot JSON (schema version 1)

```json
{
  "dailyAverage7d": 72,
  "generatedAt": 1794233040,
  "localDay": "2026-11-09",
  "nextMilestone": 5000,
  "schemaVersion": 1,
  "todayFolds": 64,
  "todayUnfolds": 62,
  "totalSinceInstall": 1284
}
```

Readers reject a newer `schemaVersion` and fall back to the empty state instead of misreading it.

## 6. Migration strategy

1. Never edit `SchemaV1` after release. Add `SchemaV2` and a `MigrationStage` (lightweight where possible, custom with tests otherwise).
2. Every migration gets a unit test that opens a V(n−1) store fixture and checks that every row survives.
3. Snapshot JSON changes bump `schemaVersion`. Widgets ship in the same bundle, so they update together.

## 7. Integrity rules

- IDs are unique: enforced by `EventStore.add`, which rejects duplicates (tested).
- Fold and unfold alternation is **checked, not enforced**: violations become `inferred` gaps (Phase 4 reconciliation). Recorded data is never rewritten.
- Edits keep the original `timeZoneID` and set `isEdited`.
- Reset (Phase 4, Settings) will remove all rows, the snapshot and settings, then reload widgets. In Phase 3, `deleteAll` exists and is exposed only in debug builds.
