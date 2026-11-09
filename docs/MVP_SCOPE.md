# FoldPulse — MVP Scope

**Owner:** Agent 1 — Chief Product Manager · **Challenged by:** Agent 2 — Founder Representative
**Version:** 1.0 · 9 November 2026

## 1. MVP definition

> A privacy-first iPhone Duo app that **counts folds automatically while open, in the background through a guided Shortcuts automation, and manually**. It labels every event by source and presents the results on a dashboard, in history, in analytics, and in Home/Lock Screen/StandBy widgets.

## 2. In scope (MVP)

| # | Feature | Priority | Feasibility | Notes |
|---|---|---|---|---|
| F1 | Hinge tracking in the foreground (`onHingeChange`) | Must | Verified (API docs) / device spike pending | Edge-based, debounced |
| F2 | App Intents: Record Fold / Record Unfold (background) | Must | Verified (API docs) / device spike pending | Powers the Shortcuts automation |
| F3 | Guided Shortcuts setup + self-test | Must | Feasible | Biggest UX differentiator |
| F4 | Manual record + undo | Must | Feasible | |
| F5 | Dashboard | Must | Feasible | |
| F6 | History list, filters, edit/delete | Must | Feasible | |
| F7 | Analytics (D/W/M/Y, averages, peak day, time of day) | Must | Feasible | Swift Charts |
| F8 | Milestones (in-app celebration) | Should | Feasible | Notification is optional, off by default |
| F9 | Widgets: Home S/M/L, Lock Screen circular/rect/inline | Must (S, circular, rect) / Should (M, L, inline) | Feasible | StandBy through systemSmall |
| F10 | Export JSON + CSV | Must | Feasible | Share sheet |
| F11 | Import JSON | Should | Feasible | Validate → preview → merge |
| F12 | Reset all data | Must | Feasible | Two-step confirm |
| F13 | Settings (theme, inferred toggle, notifications) | Must | Feasible | |
| F14 | Inferred-gap detection | Should | Feasible | Default excluded from totals |
| F15 | **Tracking coverage indicator** | **Must** | Feasible | Added after Founder Rep review; key differentiator |

## 3. Out of scope (MVP)

| Item | Reason |
|---|---|
| Background hinge monitoring without Shortcuts | **Not possible** with public APIs |
| Hinge angle analytics (angle histograms) | Apple doesn't guarantee angle rate/precision; foreground only |
| "Hinge health" / wear prediction | Not measurable; misleading; potential legal/marketing risk |
| iCloud / CloudKit sync | Violates the local-only principle (could be reconsidered later only with Founder approval) |
| Apple Watch, iPad, Mac | No hinge on those platforms; scope |
| Live Activities | Little value; adds complexity |
| Control Center control (iOS 18+ Controls) | Nice-to-have post-MVP (v1.1) |
| In-app purchases / subscriptions / ads | Business model is **paid up front** (D-5); the price is set in Phase 6 |
| Localization beyond English | v1.1 |

## 4. Founder Representative challenge (Agent 2) — and resolution

| Challenge | PM response | Outcome |
|---|---|---|
| "Competitors already do this. Why build it?" | The mechanism is commoditised; experience isn't. Differentiation comes from transparency, widgets, analytics and setup UX | **Escalated to Founder (D-1)** |
| "Large widget + inline + medium = 6 widget variants. Too many for v1." | Small + Lock circular + Lock rectangular are Must; the others are Should and can slip | Accepted |
| "Import JSON adds risk for few users." | Kept as Should. Device backups already restore App Group data, so import mainly helps after deleting the app or when moving data manually | Accepted as Should |
| "Inferred events will confuse people." | Default hidden from totals; shown only in History with an explanation | Accepted |
| "Milestone notifications need permission prompts — friction." | Off by default; the permission is requested only when the user turns them on | Accepted |
| "Analytics could be the whole app — keep v1 tight." | Limit to the list in F7; no custom ranges beyond the date filter | Accepted |

### 4.1 Second-round challenge from the independent Founder Representative review

| Challenge | PM response | Outcome |
|---|---|---|
| "Market risk understated: Duo Fold Counter is about #10 in US Utilities and already does background counting." | Agreed. Competitive section rewritten; risk R-21 added | Accepted |
| "14 features and 6 widgets is too big for a me-too launch. Cut the Large/Medium/inline widgets, the time-of-day heat strip, session durations and JSON import." | Partly agreed. Proposed **lean v1** below. JSON import is kept until we verify that App Group data is restored from an iCloud/Finder device backup; if it is, import moves to v1.1 | **Founder decision D-6** |
| "Add a coverage indicator — the one trust feature competitors lack." | Agreed | Added as F15 (Must) |
| "If the automation needs confirmation or misses folds while locked, stop." | Agreed. This is now the spike decision rule | Adopted |

**Lean v1 (PM-recommended, pending D-6):** F1–F6, F7 limited to D/W/M/Y charts, averages and peak day; F8; F9 limited to Home small + Lock Screen circular + rectangular (StandBy via small); F10; F12; F13; F14 (gaps shown only); F15.
**Deferred to v1.1:** Medium/Large/inline widgets, time-of-day heat strip, session-duration statistics, inferred-count toggle, JSON import (subject to the backup check).

## 5. MVP exit criteria

1. All Must features pass their acceptance criteria (PRD §6) on a physical iPhone Duo.
2. No Critical/High open bugs.
3. Zero network requests from a release build.
4. Spike exit criteria met (TECHNICAL_FEASIBILITY §9), or marketing claims revised.
