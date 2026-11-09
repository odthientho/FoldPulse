# FoldPulse — Phase 3 Agent Reviews

**Version:** 1.0 · 9 November 2026

---

## How the reviews were run

Two independent reviewer subagents read the complete Phase 3 code and documentation. They could not edit anything. Neither could compile, so CI checked compilation separately.

| Reviewer | Roles |
|---|---|
| A | Agent 6 — Senior iOS Software Engineer; Agent 11 — Performance & Battery Engineer |
| B | Agent 8 — Privacy & Security; Agent 9 — QA & Automation; Agent 12 — Independent Final Reviewer |

Both returned **approve with changes**. Every High and Medium finding was fixed in commit `4185837` before this report. Low findings were fixed or are scheduled as listed.

## Engineer (Agent 6)

| Finding | Sev. | Resolution |
|---|---|---|
| Throttled background widget reloads were dropped and never retried; the throttle lived only in memory, so it reset in every short-lived intent process | High | Last-reload time stored in App Group defaults (tested across two instances); the widget re-reads the snapshot every 30 min |
| "as of HH:mm" never appeared: no timeline entry at the stale point | Medium | Entry added at `generatedAt + 15 min` |
| Editing `timestamp` left `localDay` on the old day | Medium | `timestamp`/`localDay` are `private(set)`; `setTimestamp` recomputes in the capture zone (tested) |
| `add` with an existing id silently overwrote the row (`.unique` upsert) | Medium | `EventStore.add` rejects duplicates (tested) |
| UI tests overwrote the real widget snapshot and reloaded widgets | Medium | UI-test mode uses a temp file and no reload |
| Release builds silently fell back from the App Group | Low | Debug-only fallback; release shows a clear error |
| `LocalDay(string:)` accepted 2026-02-31 | Low | Validated with leap-year arithmetic (tested) |
| History showed merged duplicates | Low | `recentEvents` contains live events only (tested) |

## Performance & Battery (Agent 11)

| Finding | Sev. | Resolution |
|---|---|---|
| Statistics recomputed on the main thread inside the view body (about 7 full passes per render), contradicting the docs | High | `DashboardStats` computed once per reload inside the `EventStore` actor; views only read it |
| Per-row `Calendar` and `TimeZone` work while loading; tombstones filtered in memory | High | Stored `localDay` reused, time-zone cache, `#Predicate { deletedAt == nil }` |
| Double reload at launch (and on every foreground) | Medium | `.task` at launch; reload on return from background only; midnight rollover via `NSCalendarDayChanged` |
| `@ModelActor` created on the main thread may run its context there | Medium | Created on a detached task |
| Sample-data insert saved once per event | Low | Batch `add(contentsOf:)` with one save |
| Widget memory | — | Fine: reads a small JSON file only |

## Privacy & Security (Agent 8)

| Finding | Sev. | Resolution |
|---|---|---|
| App Group fallback could strand data | Medium | Fixed (see Engineer) |
| Store file protection assumed, not set | Medium | Store directory created with `completeUntilFirstUserAuthentication` |
| Privacy manifest declared an unused reason (CA92.1) | Low | App: `1C8F.1` (actual App Group defaults use); widget: none |
| `-ui-testing` honoured in release | Low | Debug-only |
| Promised "CI check for networking symbols" didn't exist | Low | CI privacy-guard step added |

## QA & Automation (Agent 9)

| Finding | Sev. | Resolution |
|---|---|---|
| Missing tests: unknown enum rows, unknown time zone, skipped midnight, inferred first event, `includeInferred` pass-through | Medium | All added |
| Migration fixture test | Medium | **Deferred to the first schema change (V2)**: there is no older schema to migrate from yet. Recorded in DATABASE_DESIGN §6 |
| Empty simulator UDID gave an unclear error | Low | Explicit failure |
| SDK-fallback run passed with only a warning | Low | Job summary now states "compile check on iOS 26.5 SDK" |
| CI does fail on test failures | — | Confirmed |
| FoldPulseCore not in Xcode coverage; XcodeGen not pinned | Low | Core coverage comes from `swift test`. Pinning is scheduled for Phase 4 |

## Independent Final Reviewer (Agent 12)

| Finding | Sev. | Resolution |
|---|---|---|
| Docs overclaimed: ids "enforced by the store", reset "removes files", protection, PRIVACY_REVIEW not updated | Medium | DATABASE_DESIGN, ARCHITECTURE and PRIVACY_REVIEW corrected (v1.1) |
| "Verified build" claimed before CI passed | Low | The build-verification chapter uses actual CI results and links |
| Coverage of the Phase 3 brief | — | All items present: architecture, project, folders, 4 targets, widget extension, data model, persistence, design system, components, tests |

## Disagreements

None between the reviewers in this phase. One limitation is noted: CI compiles against the **iOS 26.5 SDK**, because GitHub's runners don't yet have Xcode 27.1. The 27.1 build is verified on the Founder's Mac.
