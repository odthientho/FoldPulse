## What was built

The FoldPulse MVP (lean v1, decision D-6) is implemented in Swift 6 with complete strict concurrency:

| Feature | Status |
|---|---|
| F1 Automatic counting while the app is open (hinge) | Implemented. Logic tested in CI; the 15-line iOS 27.1 hookup builds on your Mac (P4-1) |
| F2 Background counting via the Shortcuts automation (App Intents, background) | Implemented; compile-verified. Behaviour on device = Phase 5 test S-2/S-3 |
| F3 Guided setup + self-test (60 s window, names the failing step) | Implemented and tested |
| F4 Manual recording with Undo | Implemented; UI-tested end to end |
| F5 Today dashboard (honest "counted" label, "counting only while open" card, Last row) | Implemented |
| F6 History (filters, day sections, detail, edit, delete) | Implemented |
| F7 Insights (day/week/month/year, previous period, busiest day, full-day averages) | Implemented and tested |
| F8 Milestones (once, ever; optional local notifications) | Implemented and tested |
| F9 Widgets (Home small/StandBy, Lock Screen circular and rectangular) | From Phase 3, polished (privacy, empty state) |
| F10 Export CSV/JSON (injection-safe, written on request, removed afterwards) | Implemented and tested |
| F12 Reset (type RESET) | Implemented and tested |
| F13 Settings (theme, notifications, privacy) | Implemented |
| F14 Gap detection (shown, not counted) | Implemented and tested |
| F15 Coverage ("Counted for you · % of recorded folds") | Implemented and tested |
| Onboarding, manual-only mode | Implemented |

## How it was verified

- **89 automated tests, 0 failures** (CI run #14, commit `80e99c3`):
  - **57 core tests** on Linux and macOS;
  - **29 app tests** with SwiftData;
  - **3 UI tests** on the iPhone 17 Pro simulator, including recording a fold end to end and capturing the screenshots in Chapter 2.
- A **privacy guard** in CI fails the build if networking code appears.
- **Two independent reviews** found 4 High and 13 Medium issues, all traced by hand, including:
  - a phantom fold on returning to the app;
  - a lost fold after an "unknown" reading;
  - de-duplication and gap errors caused by the 7-day window;
  - double counting from lagging Shortcuts;
  - export files left behind;
  - Undo timing out for Voice Control users.

  **All High and Medium findings are fixed with regression tests**, except the two items that need your Mac (P4-1, P4-2).
- CI also caught real problems: one Swift 6 compile error in a test, and a UI bug where the milestone celebration covered another tab.

## Recommendation

**Approve Phase 4.** Open items, recorded and not hidden:
1. **P4-1:** the hinge hookup must be compiled with Xcode 27.1 and run on your iPhone Duo. That's the first Phase 5 step.
2. **P4-2:** the inner-display `ArrangementView` split and the half-folded tab bar (I-24) need the iPhone Duo simulator or device.
3. **R-28:** background counting through Shortcuts is still unverified on a device (Phase 5 gate).
4. **R-29:** the Apple Developer Program is likely needed for the App Group on your device.
