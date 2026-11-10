# FoldPulse — Bug Log (Phase 5)

**Owner:** Agent 9 (QA) · Severity per TEST_PLAN §1 · Release-blocking = any open Critical or High.

| ID | Severity | Found by | Summary | Status |
|---|---|---|---|---|
| B-01 | Medium | UI test FT-02 (run #19) | After saving an edit, the event detail didn't show "Edited" until it was reopened (the store marked it; the screen's copy didn't). | **Fixed** in `736d5e0`; verified in run #21 |
| B-02 | High (performance) | PF-01/02/03 (run #19) | With 110,000 events, Today took 4.0 s, recording 5.0 s and Insights 4.3 s, because every load read the whole log. | **Fixed** in `56dcd6e` + `736d5e0` (day-count cache); now 0.30 s / 0.99 s / 0.15 s on CI |
| B-03 | Low (test) | run #19 | The "edited" UI check looked for a label that SwiftUI combines with its title. | **Fixed**: row has an accessibility identifier |

Findings from the Phase 5 independent reviews are added below with their resolution.

## Phase 5 independent reviews (10 November 2026)

Two reviews ran on the Phase 5 code: **QA + Performance** (Agents 9, 11) and **Privacy + Independent** (Agents 8, 12). Both gave **conditional approval**. Neither found a Critical issue. The new day-count cache was checked and has no correctness defect.

| ID | Sev. | Finding | Resolution |
|---|---|---|---|
| R5-1 | High | PF-03 median hid the first Insights open (full per-day count build) | **Fixed**: `first_ms` on a fresh store, asserted < 3 s |
| R5-2 | High | PF-02 (300 ms) and PF-04 (launch < 1 s) targets are not met on the CI simulator; CI limits are looser | **Accepted with condition:** CI limits are regression guards for a slower shared simulator. The plan targets stay, and they are **release-blocking until measured on an iPhone Duo** (Part B, Sessions 1 and 4.3) |
| R5-3 | Medium | Performance seed unrealistic (in-memory, no duplicates/gaps) | **Fixed**: file-backed store; ~5 % Shortcut duplicates and gaps |
| R5-4 | Medium | PF-07 memory not measured | **Fixed**: `PERF PF-07` footprint line at 50k/110k |
| R5-5 | Medium | A failed edit, delete or reset showed no error (the reload cleared it); a reset could look successful | **Fixed**: the error is kept; Reset says "Nothing was deleted" and stays open |
| R5-6 | Medium | Thin cache tests | **Fixed**: added travel (UTC+14 / UTC−12), public `update`/`softDelete`, clock moving back and forward |
| R5-7 | Low | `add(contentsOf:)` could leave part of a rejected batch | **Fixed**: all ids checked before any insert |
| R5-8 | Low | Reset cleared the kept counts after saving | **Fixed**: cleared first |
| R5-9 | Low | 9-day window could miss a day after extreme travel | **Fixed**: 10 days |
| P5-1 | High | Device tests and PT-03 would run a Debug build (silent App Group fallback, sample-data hint) | **Fixed**: Run scheme uses **Release**; sample-data hint removed; widget-matches-Today step proves the App Group |
| P5-2 | High | PT-02 audited only the Debug simulator binary | **Fixed**: CI now builds the **Release arm64 device** app and audits both. Note: on CI's 26.x SDK the hinge code is compiled out (T-10); the Founder's Xcode 27.1 build includes it |
| P5-3 | Medium | Audit gaps (WebKit/Safari, AsyncImage, frameworks folder, silent misses) | **Fixed**: framework **allowlist**, every Mach-O in the bundle scanned, required binaries and privacy manifests, `pipefail` |
| P5-4 | Medium | A store-open failure (e.g. a Shortcut before first unlock after a restart) sticks until iOS ends the process | **Open: verify on device** (Session 3 step 4). If it fails, fix with a lazy retry before release |
| P5-5 | Medium | Lock Screen/StandBy: "as of" time and VoiceOver labels not redacted; no device step | **Fixed** in code; device steps added (Session 2 steps 4–5) |
| P5-6 | Medium | Locked accuracy only tested with a near-empty history | **Fixed in plan**: Session 4.3 repeats with a 110,000-event history |
| P5-7 | Low | Deleted events keep their time in the store; not disclosed | **Disclosed** in the in-app privacy statement; purging deferred to v1.1 (accepted) |
| P5-8 | Low | `UserDefaults.standard` fallback not declared | **Fixed**: `CA92.1` declared; CI checks both manifests ship |
| P5-9 | Low | XcodeGen downloaded unpinned on the Founder's Mac | **Fixed**: pinned 2.42.0 with SHA-256 check |

**Still release-blocking (Part B, or outside this phase):** every Part B item in TEST_RESULTS §2, plus R5-2 (device timings), P5-4 (before first unlock) and the privacy-policy URL (R-24, Phase 6).
