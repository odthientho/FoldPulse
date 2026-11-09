# FoldPulse — Product Requirements Document

**Every Fold. Every Beat.**

**Owner:** Agent 1 — Chief Product Manager
**Reviewers:** Agent 2 (Founder Representative), Agent 7 (Data Analyst), Agent 12 (Independent Reviewer)
**Version:** 1.0 (Phase 1 draft) · 9 November 2026
**Decision authority:** Founder / Product Owner

---

## 1. Problem statement

iPhone Duo is Apple's first foldable iPhone. Owners worry about, and are curious about, the hinge: *How often do I actually fold it? Am I wearing it out? Do I use the big screen or mostly the cover screen?* iOS has no built-in fold counter. Screen Time reports app usage, not hardware usage.

FoldPulse turns folding activity into a trustworthy, beautiful, private record.

## 2. Target users

| Persona | Need | Priority |
|---|---|---|
| **The Curious Early Adopter** — bought iPhone Duo at launch, loves stats (Activity rings, Screen Time) | "Show me my numbers — lifetime, today, trends." | Primary |
| **The Hinge Worrier** — paid $1,999+, worries about durability, resale and warranty | "Give me a credible count since install, with its coverage, that I can export." | Primary |
| **The Habit Tracker** — wants to use the phone less or use the inner screen deliberately | "How often do I open it, and when?" | Secondary |
| **The Tech Reviewer / Creator** — makes durability content | "Export a dataset; show a widget on camera." | Secondary |

**Out of scope as users:** owners of non-foldable iPhones (FoldPulse offers them nothing meaningful).

## 3. Product goals and success measures

| Goal | Measure (FoldPulse contains no telemetry. Adoption and retention come from Apple's App Store Connect analytics, which are aggregated by Apple and cover only users who opted in to share with developers. No SDK is involved) |
|---|---|
| Accurate counts | Foreground automatic detection ≥ 99% and background assisted ≥ 95%, measured against an independent tally over ≥ 300 cycles (spike protocol) |
| Delight at a glance | Home/Lock Screen widget readable in < 1 s; dashboard first paint < 400 ms |
| Privacy | Zero network requests in a release build (verified by proxy capture in Phase 5) |
| Low effort | Background counting set up in ≤ 60 seconds via a guided flow |
| Battery | No measurable battery drain attributable to FoldPulse over 24 h (< 1% in Battery settings) |

## 4. Competitive landscape (new finding — requires Founder attention)

The research found that **folding counters already exist** on the App Store for iPhone Duo:

- **Duo Fold Counter** — counts folds in real time while open; uses the iOS 27.2 "Opened or Closed" automation with "Count Fold / Count Unfold" Shortcuts actions; records missed changes as "inferred".
- **Fold Counter (foldcounter.com)** — positions itself as "hinge diagnostics".
- **FoldMeter – Fold Counter** and **Foldometer** — further App Store entrants.
- Open-source hobby projects (e.g. *iphone-duo-fold-counter* on GitHub).

Duo Fold Counter ranked about #10 in US Utilities (Similarweb, 2 Nov 2026) and already estimates "hinge life used". FoldPulse would arrive about 2–3 months later. **Polish alone is not a moat.** The team's view is that FoldPulse needs one trust feature the competitors lack (the coverage indicator below) and a lean, fast v1.

**What this means:** the core mechanism is proven and approvable. The market is not empty, though. FoldPulse must win on **experience, trust and polish** rather than on novelty:

1. **Tracking coverage indicator (headline differentiator)** — "Automatic capture covered 97% of your folds this week", plus a per-source breakdown (Automatic / Shortcut / Manual / Inferred). Users see how much to trust the number.
1a. **Factual context instead of fake "hinge health"** — e.g. "12,458 folds since install". FoldPulse cites a manufacturer rating only if Apple publishes one, and never estimates wear.
2. **Best-in-class widgets** — Home, Lock Screen and StandBy, with an honest "as of" freshness label.
3. **Analytics depth** — time-of-day patterns, open-session length, trends, milestones.
4. **Guided one-minute Shortcuts setup** with a self-test ("Fold your phone now — we'll confirm it worked").
5. **Strict privacy** — no network code at all, and a data export the user owns.

## 5. Scope summary

See `MVP_SCOPE.md` for the full in/out list. MVP pillars:

1. Hybrid tracking (Automatic in foreground, Assisted via Shortcuts, Manual).
2. Dashboard.
3. History with edit/delete and filters.
4. Analytics (day/week/month/year, averages, peaks, time of day).
5. Milestones (quiet celebration).
6. Widgets (Home small/medium/large, Lock Screen circular/rectangular/inline, StandBy via small).
7. Local data management (JSON/CSV export, JSON import, reset).

## 6. User stories and acceptance criteria

IDs map to MVP features. "AC" = acceptance criteria. All metrics follow `TECHNICAL_FEASIBILITY.md` §6.

### Tracking

**US-01 — Automatic counting while open.** *As an owner, when FoldPulse is on screen and I fold or unfold my phone, I want it counted automatically.*
- AC1: A committed transition to `.closed` creates one `fold` event with source `hinge`.
- AC2: A committed transition out of `.closed` creates one `unfold` event with source `hinge`.
- AC3: `partiallyOpen ↔ fullyOpen` creates no fold/unfold event.
- AC4: `.unknown` never creates an event.
- AC5: Bouncing at the closing point (status flicker < debounce window) creates no extra events.
- AC6: The dashboard counter updates within 1 s of the event.

**US-02 — Background counting via Shortcuts.** *As an owner, I want folds counted even when FoldPulse isn't open.*
- AC1: FoldPulse provides "Record Fold" and "Record Unfold" Shortcuts actions that run without opening the app.
- AC2: A guided setup screen explains the steps, with illustrations, and deep-links to Shortcuts where possible.
- AC3: A self-test confirms that the automation fired ("We saw your fold at 14:02 ✓").
- AC4: Background events carry source `shortcut`.
- AC5: If a `hinge` event and a `shortcut` event of the same type occur within 3 s, exactly one event is kept.
- AC6: The app clearly states that this mode depends on iOS 27.2+ and on the user's automation.

**US-03 — Manual recording.** *As any user, I want to record a fold or unfold by hand.*
- AC1: Record Fold / Record Unfold buttons are on the Track screen; each creates an event with source `manual`.
- AC2: A 5-second Undo is offered after each manual entry.

**US-04 — Correct mistakes.** *As a user, I want to delete or edit an incorrect event.*
- AC1: Swipe-to-delete in History with confirmation; totals update immediately.
- AC2: Edit time, type and note. Editing a `hinge`/`shortcut` event marks it `edited` (the original source is preserved).

### Dashboard

**US-05 — At-a-glance numbers.** Folds since install (hero; the label says "since install", not the device lifetime), today's folds, today's unfolds, 7-day daily average, last event (relative time + source), mini 7-day chart, progress to the next milestone.
- AC: All values are computed from the event log; with zero data, an empty state invites setup (no fake sample numbers, ever).

### History

**US-06 — Browse history.** Chronological list grouped by day: time, type, source badge, note. Filter by date range and source.
- AC: Scrolls smoothly at 50,000 events (lazy loading).

### Analytics

**US-07 — Trends.** Day/Week/Month/Year charts of folds; daily/weekly/monthly averages; highest-activity day; time-of-day heat strip.
- AC1: Aggregates use the event's recorded local time zone (see the Data Analyst's rules).
- AC2: Averages state their denominator ("per tracked day since 2 Nov").
- AC3: Open-session (unfold→fold) duration stats are shown only when ≥ 80% of the period's events are non-inferred, otherwise hidden with an explanation.

### Milestones

**US-08 — Celebrate.** Milestones at 100, 500, 1k, 5k, 10k, 25k, 50k, 100k folds.
- AC: A one-time, dismissible celebration in the app; an optional local notification (off by default); no streaks, badges or gamified pressure.

### Widgets

**US-09 — Widgets.** Home small/medium/large, Lock Screen circular/rectangular/inline; small works in StandBy.
- AC1: Every widget shows data as of its last snapshot and displays the "as of" time when the data is older than 15 minutes.
- AC2: Optional interactive "+ Fold" button on the Home Screen widget (source `manual`). Works only while unlocked (an Apple restriction); not available on Lock Screen widgets.
- AC3: Lock Screen widgets hide their counts when the device is locked and the user has chosen to hide sensitive data (`.privacySensitive()`).

### Data

**US-10 — Own my data.** Export JSON (full fidelity) and CSV (formula-injection safe; a notice says exports reveal daily routine); import JSON (validate, preview, then merge without duplicates by event ID); reset everything with two-step confirmation.
- AC: An import of a corrupt or malicious file fails safely with a clear message and no partial writes.

### Settings

**US-12 — Tracking coverage.** *As a Hinge Worrier, I want to know how complete my count is.*
- AC1: The dashboard shows weekly coverage = automatically captured folds ÷ all folds, plus the number of detected gaps (inferred).
- AC2: Tapping it explains how to raise coverage (set up or repair the automation).
- AC3: The Shortcuts self-test result and the date of the last automation-fired event are visible.

**US-11 — Settings.** Theme (System/Light/Dark), count inferred events (on/off), milestone notifications, Shortcuts setup and self-test, data management, privacy statement, About.

## 7. Non-functional requirements

- **Privacy:** no network calls, accounts, analytics, ads or cloud sync (see `PRIVACY_REVIEW.md`).
- **Accessibility:** Dynamic Type up to AX5, VoiceOver labels on all counters and charts (Audio Graphs for charts), Reduce Motion respected, contrast ≥ 4.5:1.
- **Localization-ready:** strings in a String Catalog; English at launch.
- **Performance:** cold start < 1 s; an event commit runs off the main thread; the widget snapshot write is < 10 ms.
- **Battery:** no continuous sensors, no location, no background audio tricks, no polling.

## 8. Explicit non-goals (MVP)

iCloud sync; Apple Watch app; social sharing/leaderboards; hinge "health" scores or warranty claims (FoldPulse cannot measure wear and must not imply it can); Android; monetization.

## 9. Product decisions (resolved 2026-11-09 — see DECISIONS.md)

All recommendations below were accepted. **D-5 was decided as _paid up front_.**

| # | Decision | PM recommendation |
|---|---|---|
| D-1 | Proceed despite existing competitors? | Yes — compete on quality, transparency and widgets |
| D-2 | Count `inferred` events in headline totals? | No by default; user toggle |
| D-3 | Minimum OS iOS 27.1, iPhone Duo-focused? | Yes |
| D-4 | Show a "Requires iPhone Duo" notice on other iPhones vs. a manual-only mode | Manual-only mode with a clear notice (reduces App Review risk) |
| D-5 | Business model (free / paid up front / one-time unlock / tip jar) | **Decide before Phase 2**: it shapes design (paywall surfaces). Must stay privacy-preserving (StoreKit only, no ad or analytics SDKs) |
| D-6 | Adopt the **lean v1** proposed by the Founder Representative (see MVP_SCOPE §4)? | Yes — ship faster against established competitors |
