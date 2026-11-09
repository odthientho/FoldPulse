# FoldPulse — User Flows

**Owner:** Agent 4 — UI/UX Design Director · **Reviewed by:** Agent 2 (Founder Rep), Agent 9 (QA)
**Version:** 1.0 · 9 November 2026 · Diagrams: `design/flows/*.svg`

---

## F0. Navigation map (`flow-nav.svg`)

Four tabs: **Today**, **History**, **Insights**, **Settings**. Sheets: Record, Edit, Export, Milestone (Import arrives in v1.1). Full-screen cover: Onboarding (first launch only). Pushed screens: Coverage detail, Background counting setup, Event detail (outer display).

## F1. First launch (`flow-setup.svg`, top row)

1. App opens → **Onboarding 1** (value) → **2** (how counting works: Automatic / Shortcut / Manual) → **3** (privacy) → **Start counting**.
2. **Today (empty state)**. Automatic counting is already active while the app is open. No permission prompts.
3. The user can fold right away and watch the count start ("Ready when you are").

*Design intent:* the user sees value within 30 seconds, without any setup. Background counting is offered but never forced.

## F2. Optional background counting (`flow-setup.svg`)

1. Entry: the Today card "Count in the background", Coverage detail, or Settings.
2. **Version check:** on iOS < 27.2, show the update notice and keep foreground mode (the Phase 1b finding).
3. **Setup screen:** four plain numbered steps (FoldPulse can't observe Shortcuts, so no checkmarks) → **Open Shortcuts**.
4. In Shortcuts, the user creates **Closed → Record Fold** and **Opened → Record Unfold**, choosing **Run Immediately**.
5. Back in FoldPulse, the **self-test**: close the phone, then open it. FoldPulse looks for a shortcut fold and unfold within 60 s.
6. **Pass:** "Working ✓", and coverage starts tracking. **Fail:** the screen names the likely cause (trigger not found → iOS version; confirmation prompt → choose Run Immediately; no run → check the action is FoldPulse's) and offers to retry.

## F3. Record and correct (`flow-record.svg`)

1. **Automatic** (app open): fold → event → hero rolls, pulse beats, no haptic.
2. **Shortcut** (app closed, if set up): the automation records in the background; widgets refresh within the budget.
3. **Manual:** Record sheet → Record Fold → toast with **Undo** (5 s).
4. All sources pass through **de-duplication (±10 s) and gap reconciliation** (feasibility §6).
5. **Correct:** History → tap → Edit (type, time, note; the event is marked "edited"), or swipe → Delete (confirmation for automatic and shortcut events).
6. Totals, coverage and widgets update, and the milestone check runs (each milestone fires once).

## F4. Export and import

1. Settings → **Export data** → choose CSV/JSON and range → privacy note → share sheet → a temporary file is deleted afterwards.
2. *(v1.1, deferred by D-6)* Settings → **Import data** → file picker → validation (size, schema, bounds) → preview ("312 new, 14 already present, 0 invalid") → **Merge**. Nothing is written if validation fails.

## F5. Reset

Settings → **Reset all data** → explanation ("This deletes all 2,565 events on this iPhone. Export first?") with an **Export first** shortcut → type **RESET** → done → first-run Today state. Widgets reload.

## F6. Milestone

When the total crosses a milestone, the next time Today is visible a sheet appears **once**: pulse animation, number, date reached, next milestone. Optional local notification if enabled (off by default; permission asked only when the user turns it on).

## F7. Non-hinge device

No hinge reading within 10 s on a model without a hinge → the manual-only explanation → manual mode. Coverage and background setup are hidden.

## Flow-level acceptance checks (for QA, Phase 5)

| Flow | Check |
|---|---|
| F1 | A new user can see their first automatic fold counted in under 30 s from launch |
| F2 | The app never shows "Working" without a passed self-test; on iOS 27.1 it shows the update notice |
| F3 | Folding with the Record sheet open, then tapping Record Fold within 10 s, leaves exactly **one** fold |
| F4 | Export produces a CSV that opens safely in a spreadsheet (no formula execution). Import checks move to v1.1 |
| F5 | After reset, widgets show 0 within one reload |
| F6 | Deleting events below a milestone never re-shows its celebration |
