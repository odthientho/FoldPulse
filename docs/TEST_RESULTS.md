# FoldPulse — Test Results (Phase 5)

**Owner:** Agent 9 (QA), with Agents 8 (Privacy) and 11 (Performance) · **Version:** 1.0 · 10 November 2026
Results are from CI (GitHub Actions). The compact output of each run is published as `results.txt` on the `ci/screenshots` branch.

---

## 1. Part A: automated, CI run #21 (commit `736d5e0`), green

| Suite | Where | Tests | Result |
|---|---|---|---|
| FoldPulseCore | Linux (Swift 6.1) and macOS | 57 | All pass |
| App unit tests (FoldPulseTests) | iOS simulator | 34 | All pass |
| UI tests (FoldPulseUITests) | iOS simulator | 7 | All pass |
| **Total** | | **98** | **0 failures** |

### Functional, data and widget tests

| ID | Result | Evidence |
|---|---|---|
| FT-01 Record + Undo | ✅ Pass | `LaunchTests`, `RecordingTests` |
| FT-02 Edit (type/time/note, marked edited) | ✅ Pass after fix B-01 | `QAFunctionalTests.testEditFilterAndDeleteAnEvent` |
| FT-03 Delete with confirmation | ✅ Pass | same UI test, `ReviewFixPhase4Tests` |
| FT-04 Totals, averages, coverage | ✅ Pass | `StatisticsTests`, `DayTallyStoreTests` |
| FT-05 Insights D/W/M/Y | ✅ Pass | `PeriodStatsTests`, `QAFunctionalTests.testInsightsPeriodsRender` |
| FT-06 Milestones once | ✅ Pass | `AppSettingsTests`, `RecordingTests`, `ScreenshotTests` |
| FT-07 History filters | ✅ Pass | `QAFunctionalTests` (Shortcut filter hides a manual event) |
| FT-10 Self-test logic | ✅ Pass (logic) | `ReviewFixPhase4Tests`; on device: Part B |
| DT-01 Persists across relaunch | ✅ Pass | `QAFunctionalTests.testDataPersistsAcrossRelaunch` |
| DT-03 / DT-04 Travel, DST | ✅ Pass | `LocalDayTests`, `StatisticsTests`, `ReviewFixTests` |
| DT-05 Duplicates | ✅ Pass | `ReconcilerTests` (14), `RecordingTests` |
| DT-06 Export | ✅ Pass | `ExporterTests`, `ReviewFixPhase4Tests` |
| DT-08 Unknown rows skipped | ✅ Pass | `EventStoreTests` |
| WT-01 / WT-02 Snapshot, throttling | ✅ Pass | `WidgetSnapshotTests`, `SnapshotServiceTests` |
| **New:** day-count cache stays exact | ✅ Pass | `DayTallyStoreTests`: delete/edit 20–30 days back, duplicates, time moving on, reset; every step is compared with the full log |

### Privacy

| ID | Result | Evidence |
|---|---|---|
| PT-01 No networking symbols in source | ✅ Pass | CI privacy guard |
| PT-02 No networking APIs in the built binaries | ✅ Pass | CI `nm -u` / `otool -L` on the app and widget: "no networking APIs imported by FoldPulse or its widget" |
| PT-05 Export/temp-file hygiene | ✅ Pass | `ReviewFixPhase4Tests` |

### Performance (CI simulator; indicative, the device check is in Part B)

| ID | Measurement | Before fix (run #19) | **After (run #21)** | Target |
|---|---|---|---|---|
| PF-01 | Today load at 50k events, first / later | 1,830 ms | **210 / 206 ms** | < 1 s |
| PF-01 | Today load at 110k events, first / later | 3,999 ms | **297 / 251 ms** | < 1 s |
| PF-02 | Record one event at 110k (insert + de-duplicate + reload) | 4,973 ms | **994 ms** (de-duplicate 685, reload 315) | 300 ms on device; CI limit 1.5 s |
| PF-03 | Insights at 110k, day / week / month / year | 4,100–4,339 ms | **146 / 132 / 145 / 138 ms** | < 1 s |
| PF-04 | Cold launch (simulator) | 1.7 s (noisy) | **3.25 s** average (±10 %) | < 1 s on device: Part B |
| PF-05 | History at 50k (capped at 10,000) | 1,388 ms | **1,347 ms** | No hang |

**What changed:** the store used to read every event to compute totals and charts. It now keeps folds counted per day (built with one database count per day, updated before every write), and reads only the last 10 days in full. `DayTallyStoreTests` proves the kept counts always equal a full recount.

**Honest note:** the CI simulator is a shared, slower virtual Mac. PF-02 (300 ms) and PF-04 (launch < 1 s) can only be confirmed on an iPhone Duo (Part B, Session 1). The de-duplication step re-reads a 7-day window by design (DECISIONS T-2). If it turns out slow on device, it is the first thing to tighten.

## 2. Part B: on device (not yet run)

| Item | Status | Release-blocking if not done? |
|---|---|---|
| P4-1 App runs and counts on iPhone Duo (FT-08) | ⏳ Not verified | **Yes** |
| P4-2 / I-24 Half-fold layout | ⏳ Not verified | **Yes** |
| WT-03…05 Widgets, StandBy, Lock Screen redaction | ⏳ Not verified | Widgets yes; StandBy informational |
| R-28 / FT-09 Background counting (Shortcuts) | ⏳ Not verified | **Yes, for any background-counting claim** |
| S-1 / S-3 Accuracy (≥ 99 % open, ≥ 95 % locked) | ⏳ Not verified | **Yes, for accuracy claims** |
| DT-02 Persistence across restart | ⏳ Not verified | Yes |
| PT-03 No network activity (App Privacy Report) | ⏳ Not verified | **Yes** |
| PF-06 Battery ≤ 1 % / 24 h | ⏳ Not verified | Informational |

Steps for the Founder: `DEVICE_TEST_SESSION.md`.
