## Decisions requested

| # | Decision | Team recommendation |
|---|---|---|
| **A-4** | **Approve Phase 4** (MVP implemented; CI green; reviews' High and Medium items fixed) | Approve |
| P4-1 | At the start of Phase 5: build on your Mac with Xcode 27.1 and run on your iPhone Duo (one-line setup script), so the hinge code is compiled and exercised for real | Required |
| R-29 | Apple Developer Program ($99/year): likely needed for the App Group (widgets) on your device, and required for release | Join before Phase 5 device testing |
| R-28 | Background counting on iOS 27.2 (spike S-2/S-3) is still unverified | Phase 5 gate |

## Phase 5 — Quality assurance & validation (after approval)

1. **On your iPhone Duo (with you):**
   - P4-1 build;
   - the spike protocol S-1…S-7, re-run with the real app: accuracy over at least 300 cycles, the automation while locked, rotation, battery;
   - widgets on the Lock Screen and in StandBy;
   - P4-2 inner layout and I-24.
2. **Functional, data, widget, privacy and performance testing:**
   - time-zone and DST runs;
   - persistence across restarts;
   - a 50,000-event History scroll;
   - export with corrupt-data checks;
   - proxy capture showing zero network requests.
3. **Deliverables:** TEST_PLAN.md, TEST_RESULTS.md, BUGS.md, the privacy and performance reviews, the release-blocking list, and `phase-05-testing.pdf`.
