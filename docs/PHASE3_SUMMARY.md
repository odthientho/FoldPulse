## What this phase delivers

FoldPulse now has a **real, buildable iOS project**, verified independently by continuous integration:

- **Architecture:** a pure-Swift domain package (`FoldPulseCore`), an app target, a widget extension and shared code, with documented layers, data flow and concurrency model (Swift 6, complete strict concurrency).
- **Data layer:** a versioned SwiftData schema with a migration plan from day one, a single-writer `EventStore` actor, tombstones instead of deletes, duplicate-id protection, and explicit file protection that works while the phone is locked.
- **Design system in code:** colour tokens with the measured contrast from Phase 2, typography, and seven components (hero counter, stat tile, source badge, milestone bar, "Counted for you" tile, 7-day chart, pulse line).
- **App shell:** four tabs; Today runs on real data; a basic History; Insights and Settings placeholders. A debug-only "Insert sample week" lets you review the design on your iPhone Duo.
- **Widgets:** Home small (StandBy), Lock Screen circular and rectangular. They read a small snapshot file, never the database, and follow the midnight, staleness and privacy rules.
- **Tests and CI:** 43 automated tests, all passing on Linux and macOS (simulator), plus a privacy guard that fails the build if networking code appears.

## How it was verified

| Check | Result |
|---|---|
| Core logic tests on Linux and macOS | 29 / 29 pass |
| App unit tests (SwiftData, snapshot service) | 13 / 13 pass |
| UI test (launch, all tabs) | 1 / 1 pass |
| Privacy guard (no networking code) | Pass |
| Build warnings | One real warning (widget version) found and fixed |

CI found three problems along the way. The cause and fix for each are in Chapter 5. None was a compile error in the app code.

## Independent reviews

Two reviewer agents (Engineer + Performance; Privacy + QA + Independent Reviewer) found **2 High and 11 Medium issues**. Examples: the widget could stay hours out of date; statistics were recomputed on the main thread; editing a time left the event on the wrong day; duplicate IDs silently overwrote rows; the docs overclaimed. **All High and Medium items were fixed before this report** (Chapter 6).

## Recommendation

**Approve Phase 3.** Open items, recorded and not hidden:
1. **CI uses the iOS 26.5 SDK** because GitHub's runners don't have Xcode 27.1 yet. The 27.1 build on your Mac is the remaining check, and it becomes mandatory in Phase 4, when hinge code needs the 27.1 SDK.
2. **R-29:** App Groups on a device may require the paid Apple Developer Program.
3. **R-28 / I-24** (carried from Phase 2): background automation not yet verified; inner tab bar when half-folded not yet checked.
