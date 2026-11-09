# FoldPulse — Test Plan (Phase 5)

**Owner:** Agent 9 — QA & Automation Engineer · **Reviewers:** Agents 8 (Privacy), 11 (Performance), 12 (Independent)
**Version:** 1.0 · 9 November 2026

---

## 1. Scope and approach

| Part | Where | Who | Evidence |
|---|---|---|---|
| **A — automated** | CI: Linux (core) + macOS simulator (app, UI, performance) | Agents 9, 11, 8 | CI run links, test counts, timings |
| **B — device** | Founder's Mac (Xcode 27.1) + iPhone Duo (iOS 27.2+) | Founder, guided by `DEVICE_TEST_SESSION.md` | Checklist answers, FoldProbe/FoldPulse logs, screenshots |

Severity for bugs (BUGS.md): **Critical** (data loss, wrong totals, privacy breach, crash), **High** (feature broken), **Medium** (degraded or confusing), **Low** (cosmetic). **Release-blocking** = any open Critical or High, or any unverified claim the App Store listing would make.

## 2. Functional tests

| ID | Test | Part | Method |
|---|---|---|---|
| FT-01 | Record fold / unfold manually; Undo | A | UI test `testRecordingAFoldManuallyUpdatesTodayAndHistory`, `RecordingTests` |
| FT-02 | Edit an event (type, time, note) → marked edited, moves day | A | `RecordingTests.testEditingTime…`, new UI test FT-02 |
| FT-03 | Delete an event (confirmation for automatic events); gaps can't be deleted | A | New UI test, `ReviewFixPhase4Tests` |
| FT-04 | Since-install total, today, 7-day average, coverage | A | Core `StatisticsTests`, `DashboardStats` tests |
| FT-05 | Insights D/W/M/Y values | A | Core `PeriodStatsTests`, new UI test (all periods render) |
| FT-06 | Milestones once, ever; shown only on Today | A | `AppSettingsTests`, `RecordingTests`, `ScreenshotTests` |
| FT-07 | History filters (source, range) | A | New UI test |
| FT-08 | Automatic counting (hinge) | **B** | Device: 300 cycles vs clicker (S-1) |
| FT-09 | Background counting via the Shortcuts automation | **B** | Device: S-2/S-3 (no prompt; ≥ 95 % while locked) |
| FT-10 | Self-test passes/fails correctly | A + B | `ReviewFixPhase4Tests` + device |

## 3. Data tests

| ID | Test | Part | Method |
|---|---|---|---|
| DT-01 | Persistence across app relaunch | A | New UI test with a persistent test store (relaunch, count unchanged) |
| DT-02 | Persistence across device restart | **B** | Device |
| DT-03 | Time-zone change / travel keeps capture day | A | Core `StatisticsTests.testEventKeepsCaptureDayAfterTravel`, `LocalDayTests` |
| DT-04 | DST (23/25-hour days, repeated hour) | A | Core `LocalDayTests`, `ReviewFixTests` |
| DT-05 | Duplicates (hinge/shortcut/manual, lagging, double tap) | A | Core `ReconcilerTests` (14), `RecordingTests` |
| DT-06 | Export CSV/JSON (injection-safe, no deleted events, removed afterwards) | A | `ExporterTests`, `ReviewFixPhase4Tests` |
| DT-07 | Import / corrupted import | — | **Not applicable in v1** (import deferred, D-6); corrupt **snapshot** handling tested (`WidgetSnapshotTests`) |
| DT-08 | Unknown/future rows are skipped, never guessed | A | `EventStoreTests.testRowsWithUnknownValues…` |

## 4. Widget tests

| ID | Test | Part | Method |
|---|---|---|---|
| WT-01 | Snapshot values, midnight rule, staleness, schema guard | A | `WidgetSnapshotTests`, `SnapshotServiceTests` |
| WT-02 | Reload throttling across processes | A | `SnapshotServiceTests` |
| WT-03 | Home small, Lock Screen circular/rectangular render with real data | **B** | Device screenshots |
| WT-04 | StandBy presentation (which pose) | **B** | Device (O-4) |
| WT-05 | Lock Screen redaction when locked | **B** | Device |

## 5. Privacy tests

| ID | Test | Part | Method |
|---|---|---|---|
| PT-01 | No networking symbols in shipping source | A | CI privacy guard |
| PT-02 | **No networking APIs linked in the built binary** | A | New CI step: inspect the app binary's imported symbols (`nm`) |
| PT-03 | No network activity at runtime | **B** | iOS **App Privacy Report** (Settings → Privacy & Security → App Privacy Report) after a day of use: FoldPulse must show **no network domains** |
| PT-04 | Privacy manifest matches API use | A | Review (Agent 8) |
| PT-05 | Export/temp-file hygiene, notes cleared on delete | A | `ReviewFixPhase4Tests` |

## 6. Performance tests

| ID | Test | Part | Target | Method |
|---|---|---|---|---|
| PF-01 | Load + statistics at 50,000 and 110,000 events | A | < 1 s at 110k (simulator) | New `PerformanceTests` (XCTest `measure`) |
| PF-02 | Record one event (insert + reconcile + snapshot) with 110,000 events stored | A | < 300 ms | New `PerformanceTests` |
| PF-03 | Insights summary at 110,000 events | A | < 1 s | New `PerformanceTests` |
| PF-04 | Cold launch time | A | < 1 s first frame (simulator indicative) | New UI test with `XCTApplicationLaunchMetric` |
| PF-05 | History scroll with 50,000 events | A | No hang; query capped at 10,000 with notice | Covered by PF-01 (query) + review; device check in B |
| PF-06 | Battery: 24 h with the automation on | **B** | FoldPulse ≤ 1 % in Settings → Battery | Device (S-7) |
| PF-07 | Memory during load at 110k | A | Reported | `XCTMemoryMetric` in PF-01 |

## 7. Exit criteria for Phase 5

1. All Part A tests green in CI.
2. No open Critical or High bugs.
3. Part B completed, or every unrun Part B item listed as **release-blocking** with its reason.
4. Independent QA, Privacy and Performance reviews submitted, with findings resolved or explicitly accepted by the Founder.
