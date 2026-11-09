# FoldPulse — Development Log (Phase 4: MVP)

**Owner:** Agent 1 (PM), with entries from the responsible engineers · **Started:** 9 November 2026
Each entry follows the brief: plan → responsible agent → implementation → build → tests → review → fixes → docs → result.
Build results come from CI (GitHub Actions); run numbers link to https://github.com/odthientho/FoldPulse/actions.

---

## Working method

- Features were built in **three batches**, each verified by CI before the next was trusted:
  - **A** — counting engine (pure Swift);
  - **B** — recording;
  - **C** — screens.
  Batches B and C were pushed together but committed separately (`21efabf`, `6b0dddb`).
- **Hinge code** (`HingeTrackingModifier`) is compiled only with the iOS 27.1 SDK, behind `HINGE_API` (DECISIONS T-10). Its logic lives in `HingeTracker` and `HingeEdgeDetector`, which CI does test. The SwiftUI hookup uses the exact API form that compiled and ran in FoldProbe on the Founder's iPhone Duo.
- **Independent reviews** ran on the complete Phase 4 code (see "Reviews and fixes").

## Batch A — counting engine (commit `870359d`, CI run #7: green on Linux and macOS)

| Feature | Plan | Responsible | Implementation | Tests |
|---|---|---|---|---|
| F1 rules: hinge edges | Turn raw hinge readings into folds/unfolds per feasibility §6 | Agent 7 (rules), Agent 6 (code) | `HingeEdgeDetector`: 250 ms debounce, first-entered timestamp, baseline-on-activation, flush, nil resets baseline | 7 tests: baseline, debounce, bounce, many angle callbacks, late tick, flush, resume-without-false-event |
| De-duplication and gaps | One physical fold → one event, regardless of source or order; gaps when alternation breaks | Agent 7, Agent 6 | `Reconciler.plan`: ±10 s either order, precedence hinge > shortcut > manual, one-to-one per source, same-source 1 s, gap interval bucketed on the later day, idempotent | 11 tests: both orders, window edge, opposite event in between, manual-after-automatic, one-to-one, idempotence, delete restores duplicate, gap removed when filled, gap day |
| F7 Insights data | D/W/M/Y with honest averages | Agent 7 | `Statistics.summary` | 4 tests: hourly, week (full-day average, busiest day), month/year with previous period, empty |
| F10 Export | Safe CSV + full-fidelity JSON | Agent 8 (rules), Agent 6 | `Exporter`: formula-injection escaping, tombstones omitted from CSV, ISO-8601 milliseconds | 3 tests: injection cases, ordering/tombstones, JSON round trip |

## Batch B — recording (commit `21efabf`)

| Feature | Plan | Responsible | Implementation | Tests |
|---|---|---|---|---|
| Shared services | One writer for the UI and background intents | Agent 3, Agent 6 | `AppServices` (store, snapshot, settings), `AppSettings` (App Group defaults) | Covered by recording tests |
| Recording + reconciliation | Every write reconciles a 7-day window | Agent 6 | `EventStore.record/edit/delete/reconcile` | `RecordingTests`: hinge+shortcut count once; missed unfold → gap, not counted; Undo; edit moves the day; milestone once |
| F1 Automatic counting | Count while on screen | Agent 6 | `HingeTracker` (ordered delivery, debounce timer, flush) + `HingeTrackingModifier` (HINGE_API) | `HingeTrackerTests` (3) |
| F2 Background counting | Shortcuts automation → App Intent in background | Agent 6, Agent 10 | `RecordFoldIntent` / `RecordUnfoldIntent` (`supportedModes = .background`), App Shortcuts | Compile-verified in CI; behaviour on device = Phase 5 (S-2/S-3) |
| F4 Manual + Undo | Record by hand, undo for 5 s (persistent with VoiceOver/Switch Control) | Agent 5 | `RecordSheet` | UI test (batch C) |
| F8 Milestones | Celebrate once, ever; optional local notification | Agent 4, Agent 6 | `AppSettings.claimMilestones`, `MilestoneSheet`, `MilestoneNotifier` | `AppSettingsTests`, `RecordingTests` |

## Batch C — screens (commit `6b0dddb`)

| Feature | Implementation | Tests |
|---|---|---|
| F6 History | Source filter (segmented Picker), range Menu, day sections, swipe delete (confirm for automatic), detail, edit sheet | Store queries tested; UI test checks the recorded fold appears |
| F7 Insights | D/W/M/Y chart, previous period, busiest day, full-day averages, coverage | Core summary tests |
| F15 Coverage | Detail per source, gaps, background status | Core coverage tests |
| F3 Setup + self-test | Plain steps, iOS 27.2 check, Open Shortcuts, self-test (both automations after start, within 10 min), troubleshooting | Logic in `AppModel.checkSelfTest` (on device: Phase 5) |
| F12/F13 Settings | Theme, milestone notifications (permission on enable), export CSV/JSON with privacy note, two-step reset (type RESET), privacy statement | Export covered by core tests |
| Onboarding / manual-only | 3 pages on first launch; "Waiting for the hinge" notice until a reading is seen | Skipped in UI tests (`-ui-testing`) |
| UI test | Record → Record Fold → Today shows "1 fold since install" → History lists it | `LaunchTests` (2) |

## CI history (Phase 4)

| Run | Commit | Result | Notes |
|---|---|---|---|
| #7 | `870359d` (batch A) | **Green** | Core tests pass on Linux and macOS |
| #8 | `6b0dddb` (batches B + C) | Failed | One compile error in a test: `XCTUnwrap(await …)` isn't allowed (async call in a non-async autoclosure). All app sources compiled |
| #9 | `1436d83` | **Green** | Batches B + C build and pass all tests (pre-review) |
| #11, #12 | `53f8922`, `e2abeac` | Cancelled | Superseded while still queued (GitHub keeps one waiting run per branch); their code is included in #13 |
| #13 | `7249679` | Failed (UI) | All 86 unit/core tests and both functional UI tests pass. The new `ScreenshotTests` found a **real UI bug**: the milestone sheet presented over the Settings tab and covered the tab bar |
| #14 | `80e99c3` | **Green** | Milestone sheet only while Today is visible. **57 core + 29 app + 3 UI = 89 tests, 0 failures** |

## Screenshots and the last UI fix

Run #16 (`c8d0aa8`, green) published real screenshots of the running app to the `ci/screenshots` branch (see the Phase 4 report, Chapter 2). They showed truncated text in the Record sheet at its medium height. The sheet now scrolls and its text wraps; this is verified by the run after `c8d0aa8`.

## Reviews and fixes

Two independent reviews ran on the complete Phase 4 code (see PHASE4_REVIEWS.md):
- **Engineer + Data Analyst:** 4 High, 3 Medium, 3 Low.
- **Privacy + Compliance + QA + Independent:** no Critical, conditional approval.

The fixes are in commit `53f8922`, with regression tests:
- **Rule change (Data Analyst):** de-duplication now uses hinge events as the backbone, and lower-precedence events pair one-to-one with the nearest kept event within ±10 s.
- **Hinge baseline:** reset on activation, and "unknown" never changes it.
- **Reconciliation:** slice protection.
- **Background-task protection** for saves.
- **Store-unavailable errors** for Shortcuts.
- **Privacy:** export/temp-file hygiene and notes cleared on delete.
- **Accessibility:** Undo persistence, Dynamic Type, Reduce Motion.
- **Missing Today states.**
- **Self-test:** fail state.

## Open items carried to Phase 5

- **P4-1:** compile and run the hinge hookup with Xcode 27.1 on an iPhone Duo.
- **P4-2:** inner-display `ArrangementView` split and the half-folded tab bar (I-24).
- **P4-3:** App Store wording, "Requires iPhone Duo for automatic counting" (Phase 6).
- **P4-4:** v1.1 backlog (DST-normalised heat strip, custom History range).
