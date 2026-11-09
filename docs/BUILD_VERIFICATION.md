# FoldPulse — Phase 3 Build & Test Verification

**Owner:** Agent 9 — QA & Automation Engineer · **Version:** 1.0 · 9 November 2026
**Source:** GitHub Actions, repository `odthientho/FoldPulse`. All numbers below are copied from the CI logs.

---

## 1. Result

**Green.** The final verified build is commit `a154fc1` (run #5, https://github.com/odthientho/FoldPulse/actions/runs/42703454967), with the same results as run #4 (`825507e`) and **no build warnings** apart from the expected App Intents note. Every job and step passed:

| Job / step | Environment | Result |
|---|---|---|
| Core tests (Linux) | `swift:6.1-noble` container, x86_64 | **29 tests, 0 failures** |
| Core tests (macOS) | Xcode 26.6, arm64 | **29 tests, 0 failures** |
| Privacy guard (no networking symbols in shipping Swift code) | macOS | **Pass** |
| Generate Xcode project (XcodeGen 2.46.0) | macOS | **Pass** |
| Build app + widget extension, run unit tests | iPhone 17 Pro simulator, iOS 26.5 SDK | **13 tests, 0 failures** |
| UI test (launch → Today empty state → all four tabs) | Same simulator | **1 test, 0 failures** (20.9 s) |
| Overall | | `** TEST SUCCEEDED **` |

## 2. Test inventory

| Suite | Tests | What it proves |
|---|---|---|
| `LocalDayTests` | 7 | Parsing, travel across zones, DST (23-hour day, repeated fall-back hour), month/year/leap boundaries, ranges, coding |
| `StatisticsTests` | 8 | Totals exclude gaps, tombstones and duplicates; capture day survives travel; full-day averages with zero days and a 7-day cap; series; busiest day; coverage |
| `MilestonesTests` | 2 | Next milestone and progress; each milestone is celebrated once, even after deletions |
| `WidgetSnapshotTests` | 4 | Snapshot values, encoding round trip, rejects garbage or newer schema, midnight rule, staleness |
| `ReviewFixTests` | 8 | Regressions from the agent reviews: impossible dates, timestamp edits recompute the day, stored day reused, unknown-zone fallback, skipped midnight, inferred first day, `includeInferred` pass-through, dashboard week |
| `EventStoreTests` (app) | 10 | SwiftData round trip of every field, ordering, update, tombstone, not-found, duplicate id rejected, batch add, unknown rows skipped, duplicates hidden from recent events, delete-all |
| `SnapshotServiceTests` (app) | 3 | Snapshot written and readable; background reloads coalesced across processes; protected store directory created |
| `LaunchTests` (UI) | 1 | App launches into Today (empty state) with all tabs reachable |
| **Total** | **43** | |

## 3. Problems CI found, and fixes

| Run | Problem | Cause | Fix |
|---|---|---|---|
| #1 | Cancelled | A second push superseded it (concurrency setting) | Pushes now batched while a run is in flight |
| #2 | iOS job: "Unable to find a destination" | Runner has the **iOS 26.5 SDK**; the deployment-target override on the command line didn't apply when matching the destination | CI lowers the target in `project.yml` before generating (CI only) |
| #3 | 1 of 29 core tests failed | Test asserted the zone *name* "UTC"; Foundation reports "GMT" on both platforms | Test checks the zero offset; code uses one explicit `fallbackTimeZone` |
| #4 | Green; build warning: widget version 1.0 ≠ app 0.1.0 | XcodeGen default for the extension | Extension version follows the app's settings (commit `a154fc1`) |
| #5 | **Green, warning gone** | — | — |

No compile errors occurred in the app, widget or test code, under **Swift 6 with complete strict concurrency**.

## 4. What this verification does not cover

| Gap | Why | Covered by |
|---|---|---|
| iOS 27.1 SDK / iPhone Duo simulator | GitHub's runners have Xcode 26.6 (iOS 26.5 SDK) at most | Founder's Mac with Xcode 27.1 (one-line setup script), plus CI once runners update |
| Physical-device behaviour (file protection while locked, widgets on the Lock Screen and in StandBy, App Group signing) | Needs hardware | Phase 5 device tests (spike criteria S-1…S-7) |
| Hinge, Shortcuts and App Intents | Phase 4 features | Phase 4 |
| Remaining warning: "AppIntents metadata extraction skipped" | No App Intents exist yet | Disappears in Phase 4 |
