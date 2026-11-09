# FoldPulse — Phase 4 Agent Reviews

**Version:** 1.0 · 9 November 2026

---

## How the reviews were run

Two independent reviewer subagents read all the Phase 4 code, tests and specifications. They could not edit files or compile; CI compiled separately. Each finding came with a hand-traced failure scenario.

| Reviewer | Roles | Verdict |
|---|---|---|
| A | Agent 6 — Senior iOS Software Engineer; Agent 7 — Data Analyst | 7 counting/engineering issues (4 High) |
| B | Agent 8 — Privacy; Agent 10 — Compliance & Accessibility; Agent 9 — QA; Agent 12 — Independent | No Critical; **conditional approval** |

Every High and Medium finding was fixed in commit `53f8922`, with regression tests, unless listed under "Not fixed in Phase 4".

## Engineer (Agent 6)

| # | Finding | Sev. | Resolution |
|---|---|---|---|
| E1 | The hinge baseline survived a trip to the background. Opening FoldPulse hours later on the outer display created a **phantom fold** | High | Baseline reset when the scene becomes active or background; test `testReturningToTheAppNeverCreatesAPhantomFold` |
| E2 | An "unknown" status reset the baseline, so a fold could be lost | High | Unknown updates the label only; test `testUnknownNeverChangesTheBaseline` |
| E3 | Every window fed one shared detector (iPhone Duo supports several) | Medium | Only the foreground-active scene counts |
| E4 | A fold flushed as the phone closes could be lost when the app is suspended | Medium | Each save runs inside a background task |
| E5 | A Shortcut "succeeded" while the store was unavailable, so the fold was lost and the self-test could pass falsely | Medium | `record` throws `StoreUnavailableError`; tested |
| E6 | Swipe-deleting a gap brought it back | Low | Gaps can't be swipe-deleted |

## Data Analyst (Agent 7)

| # | Finding | Sev. | Resolution |
|---|---|---|---|
| D1 | The 7-day reconcile window cut through duplicate pairs and gaps: duplicates resurfaced and long gaps were deleted about a week later | High | Slice protection (`protectBefore`); test `testWindowProtectionKeepsPairsAndGapsThatStartBeforeTheSlice` |
| D2 | Lagging Shortcuts after a quick close-and-reopen double counted (2 folds instead of 1) | Medium | **Rule change:** hinge events are the backbone; Shortcut, then manual, events pair one-to-one with the nearest higher-precedence kept event within ±10 s, even across an opposite event. Shortcut events never pair with each other. Tests for both cases |
| D3 | A double tap next to a hinge event counted twice | Medium | Same-source repeats grouped first; tested |
| D4 | Replacement chains stretched the 10 s window | Low | Removed by the new pairing (no chains) |
| D5 | The Day chart puts both copies of the repeated DST hour in one bar | Low | **Accepted** for the single-day chart; the time-of-day heat strip (v1.1) will normalise |

## Privacy & Security (Agent 8)

| Finding | Sev. | Resolution |
|---|---|---|
| Export files stayed in tmp; the file was written as soon as the sheet opened | Medium | Written only on request; removed on close, launch and reset; tested |
| Deleted events kept their note and were exported | Medium | Deleting clears the note; export omits deleted events; tested |
| Lock Screen gauge not fully private | Low | `.privacySensitive()` on the whole gauge |
| Reset left delivered notifications; the CI privacy guard missed some networking APIs | Low | Both fixed |
| P-1 (no networking), P-2 (manifests), local-only notifications, CSV injection | — | Confirmed met |

## Compliance & Accessibility (Agent 10)

| Finding | Sev. | Resolution |
|---|---|---|
| Undo disappeared after 5 s for Voice Control and Full Keyboard Access users (can't be detected) | Medium | Undo now stays for everyone until the sheet closes or the next record |
| Dynamic Type truncation (fixed widths and sizes) | Medium | `@ScaledMetric` and text styles throughout |
| The app is paid, but only manual counting works on non-Duo iPhones | Medium (App Review) | **Phase 6:** the App Store text must state "Requires iPhone Duo for automatic counting" (guidelines 2.3, 2.4.1) |
| Reduce Motion ignored in two places; haptic also fired when the toast hid; missing success haptic; chart bars spoken as ISO dates | Low | All fixed |

## QA (Agent 9)

| Finding | Sev. | Resolution |
|---|---|---|
| **The hinge mapping code is never compiled in CI** (needs the iOS 27.1 SDK) | High | The mapping is now a pure `HingeReading` path tested in CI. The remaining 15-line SwiftUI hookup **must be compiled on the Founder's Mac (Xcode 27.1) before Phase 5**: open item **P4-1** |
| Background-save risk; intent fallback | Medium | Fixed (E4, E5) |
| History silently capped at 2,000 | Medium | Limit raised to 10,000, with an on-screen notice when reached. The 50,000-event scroll test is a Phase 5 performance test |
| Untested self-test, export, reset, intents | Medium | Self-test, export and reset now tested. The intent bodies call the tested `AppServices.record`; their run in Shortcuts is the Phase 5 device test S-2/S-3 |

## Independent Final Reviewer (Agent 12)

| Finding | Sev. | Resolution |
|---|---|---|
| Today lacked the "Folds counted since install" label, the "Counting only while FoldPulse is open" card and the "Last:" row | Medium | Implemented |
| Self-test had no fail state; window was 600 s, not 60 s | Medium | 60 s window; the failure names the missing automation; tested |
| "Working" showed even after days without a run | Medium | "No automation run in 24 h" |
| **Inner-display `ArrangementView` split and fold avoidance not implemented** | Medium | **Not fixed in Phase 4**: needs the iOS 27.1 SDK and the iPhone Duo simulator, which only the Founder's Mac has. Combined with I-24 as open item **P4-2** for the Phase 5 device session. Until then the inner display uses standard full-width layouts, which the system already adapts to the fold |
| Widget "—" vs spec "0" at midnight | Low | Spec corrected to "—" (honest until refreshed) |
| Widget empty state; update notice should replace the steps; hide coverage/setup on manual-only devices; README | Low | All fixed |
| Custom History date range; Gaps filter always shown | Low | v1.1 backlog |
| Scope | — | No scope creep; debug tools excluded from release builds |

## Not fixed in Phase 4 (open items)

| ID | Item | Plan |
|---|---|---|
| P4-1 | Compile and run the hinge hookup with Xcode 27.1 on an iPhone Duo | Founder's Mac, start of Phase 5 (one-line setup script) |
| P4-2 | Inner-display `ArrangementView` split; inner tab bar when half-folded (I-24) | Phase 5, on the iPhone Duo simulator / device |
| P4-3 | App Store text: "Requires iPhone Duo for automatic counting" | Phase 6 |
| P4-4 | DST-normalised hourly heat strip, custom History range | v1.1 |
