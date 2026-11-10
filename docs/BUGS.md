# FoldPulse — Bug Log (Phase 5)

**Owner:** Agent 9 (QA) · Severity per TEST_PLAN §1 · Release-blocking = any open Critical or High.

| ID | Severity | Found by | Summary | Status |
|---|---|---|---|---|
| B-01 | Medium | UI test FT-02 (run #19) | After saving an edit, the event detail didn't show "Edited" until it was reopened (the store marked it; the screen's copy didn't). | **Fixed** in `736d5e0`; verified in run #21 |
| B-02 | High (performance) | PF-01/02/03 (run #19) | With 110,000 events, Today took 4.0 s, recording 5.0 s and Insights 4.3 s, because every load read the whole log. | **Fixed** in `56dcd6e` + `736d5e0` (day-count cache); now 0.30 s / 0.99 s / 0.15 s on CI |
| B-03 | Low (test) | run #19 | The "edited" UI check looked for a label that SwiftUI combines with its title. | **Fixed**: row has an accessibility identifier |

Findings from the Phase 5 independent reviews are added below with their resolution.
