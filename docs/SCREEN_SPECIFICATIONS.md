# FoldPulse — Screen Specifications

**Owner:** Agent 4 — UI/UX Design Director · **Reviewed by:** Agent 5 (UI Developer), Agent 7 (Data Analyst), Agent 10 (Compliance)
**Version:** 1.1 (revised after agent reviews) · 9 November 2026 · Mockups: `design/mockups/png/` (sample data only: one consistent dataset, install Oct 24, today Mon Nov 9 14:04)

---

## 0. Navigation structure

FoldPulse uses a system **`TabView`** with four tabs and `.tabViewStyle(.sidebarAdaptable)`:

| Tab | Purpose | Outer display (compact) | Inner display (regular) |
|---|---|---|---|
| **Today** | At-a-glance dashboard + record | 1 column; the system shows bars vertically on the side | `ArrangementView` split: stats · recent + record |
| **History** | Every event, filter, edit, delete | List → detail push | List + detail side by side |
| **Insights** | Trends and averages | 1 column | 2 columns (period · month) |
| **Settings** | Counting, appearance, data, about | List | List + detail |

Modal surfaces are **sheets**: Record, Edit event, Export, Milestone, Onboarding (full-screen cover on first launch).

General rules:
- The system draws all bars (**Liquid Glass**). No custom tab bars.
- When **partially folded**, content and controls avoid the fold (active `.divisions` reserved region, handled by `ArrangementView`). When fully open there is no division.
- Toolbar items always have **an icon and a title**: on the outer display Apple presents bars vertically, and title-only items aren't shown there. Prominent items use `topBarPinnedTrailing`.
- Every screen supports light and dark mode, Dynamic Type to AX5, and VoiceOver (see DESIGN_SYSTEM §9).
- No screen shows prices, upgrades or ads (D-5, paid up front).

---

## 1. Onboarding (3 pages) — `o-onboard-1…3`

| | |
|---|---|
| Entry | First launch only (`hasCompletedOnboarding == false`) |
| Page 1 | "Every Fold. Every Beat." + animated pulse line + one-sentence value |
| Page 2 | **How counting works**: Automatic (while open) · Shortcut (optional, background) · Manual. "Every number shows where it came from." |
| Page 3 | **Private by design**: data stays on this iPhone, no account/cloud/tracking; export any time |
| CTA | "Continue" → "Start counting" opens **Today**. Background setup is **not** forced (decision C-2r: it's optional) |
| Notes | No permission prompts during onboarding. Notification permission is asked only when the user enables milestone notifications |
| Acceptance | US-01, US-02 AC6 (honest description), PRD §7 privacy |

## 2. Today (dashboard) — `o-today-light/dark`, `i-today`

| Element | Content | Behaviour |
|---|---|---|
| Title | "Today" (large title) | |
| `HeroCounter` | **Folds since install**, e.g. 1,284. When background counting is not set up: **"Folds counted since install"**, so a partial count isn't read as complete | `.numericText()` roll on change; pulse beats once per fold |
| `MilestoneBar` | Progress to the next milestone + "3,716 to the 5,000 milestone" | Uses the milestone list 100 / 500 / 1k / 5k / 10k / 25k / 50k / 100k |
| Tiles | **Today** (folds + unfolds) · **Daily average** (last 7 complete days) | Today resets at local midnight |
| `CoverageTile` | "Counted for you · 94% of recorded folds" + stacked bar by source + gap count | Tap → Coverage detail. No "Good" verdict: missed folds can't be in the denominator, so the number describes recorded folds only |
| Week chart | Last 7 days, today highlighted | VoiceOver: Audio Graph |
| Last event | "Last: Fold · 2 min ago · [Automatic]" | Relative time updates every minute |
| Inner display extras | Recent events list, next-milestone card with pace estimate, **Record Fold** button | |
| Outer display | Record via the toolbar **"+ Record"** item (icon + title, `topBarPinnedTrailing`) → Record sheet | |
| Hinge observation | While this screen (or any FoldPulse screen) is visible, automatic counting is active | Implementation: one device-level observer (feasibility §5) |

**States**

| State | Display |
|---|---|
| First run / no data (`o-today-empty`) | Hero "0"; "Ready when you are" card; optional **Count in the background** card; Record Fold button |
| **Background counting not set up** (`o-today-foreground`, the likely default) | Hero label "Folds counted since install"; the coverage tile is replaced by the card **"Counting only while FoldPulse is open"** explaining what's missed + "Set up background counting" |
| Gaps exist | Coverage tile footnote "2 gaps this week" → History filtered to gaps |
| Data loading (cold start) | Cached snapshot shown immediately, then refreshed (no spinner) |

## 3. Record sheet — `o-track`

| | |
|---|---|
| Entry | "+ Record" toolbar item (outer), Record Fold button (inner) |
| Presentation | Sheet with `.presentationDetents([.medium, .large])`, a **Close** button (`cancellationAction`) and title "Record" |
| Live status | "Hinge right now: Fully open / Partially open / Closed" (from `onHingeChange`) |
| Actions | **Record Fold** (primary, 56 pt), **Record Unfold** (secondary) |
| Feedback | Toast "Fold recorded · Manual" with **Undo**, kept until the sheet closes or the next record (DESIGN_SYSTEM §8) + `.increase` haptic + VoiceOver announcement |
| Guidance | "Use manual recording only for folds FoldPulse missed. Automatic counts already include folds made while the app is open." This prevents double counting when the phone is folded with the sheet open, which is also handled by de-duplication |
| Acceptance | US-03 AC1–AC2 |

## 4. History — `o-history`, `i-history`

| Element | Behaviour |
|---|---|
| Source filter | Segmented `Picker`: All · Auto · Shortcut · Manual (+ Gaps when any exist) |
| Date range | Toolbar `Menu` "Nov 1 – Nov 9" → presets + custom `DatePicker` |
| Sections | Grouped by local day: "Today", "Yesterday · 77 folds", then dates |
| `EventRow` | Time · Fold/Unfold · source badge (icon-only on the outer display) · ✎ if it has a note or was edited |
| Gap row | Dashed badge, "Unfold (gap)", no time ("—"). It always sits **between two events of the opposite type** (e.g. between two folds); explanation in the footer |
| Swipe | `List` + `.swipeActions` → **Delete** (destructive); confirmation for automatic and shortcut events |
| Tap | Detail (inner: right column; outer: push). Shows source, time zone, de-duplication info ("Matched with automatic fold 13:12"), note, Edit, Delete |
| Performance | Lazy list; tested to 50,000 events (US-06) |

## 5. Edit event sheet — `o-edit`

Fields: Type (Fold/Unfold), Time (date picker, keeps the original time zone), Source (read-only + "edited"), Note (≤ 500 characters). Buttons: Cancel / Save / Delete event. After saving, reconciliation re-runs (feasibility §6). Acceptance: US-04.

## 6. Insights — `o-insights`, `i-insights`

| Element | Behaviour |
|---|---|
| Period | Segmented control **D / W / M / Y** |
| Headline | Total folds in the period ("incl. today so far" when it contains today) + the previous period's total |
| Chart | Bars per hour (D), day (W, M) or month (Y); average rule line |
| Tiles | Busiest day · Average per day (full days only). Inner display adds: Since install · Unfolds + gaps |
| Coverage | "Counted for you" repeated, with the note "Averages use full days only, since <first day>" |
| Deferred to v1.1 (D-6) | Time-of-day heat strip, session durations |
| Acceptance | US-07 AC1–AC2 |

## 7. Coverage detail — `o-coverage`

Hero % for this week ("of N recorded folds"); a row per source (count and %); gaps (not counted); a background-counting status card ("Working · last run 13:47 · self-test passed <date>", or "Not set up" → Setup, or "No automation run in 24 h" → troubleshooting). Includes a plain-language definition: *the share of recorded folds captured without tapping; folds missed entirely can't be included; gaps show where something was missed.* Acceptance: US-12.

## 8. Background counting setup — `o-setup`

| | |
|---|---|
| Entry | Today card, Coverage detail, Settings → Background counting |
| Content | Why (one sentence, "Optional") · four **plain numbered** steps (no checkmarks: FoldPulse cannot see what the user does in Shortcuts) · **Open Shortcuts** · **Self-test** (the only status shown) · "To stop, delete the two automations in Shortcuts" |
| Labels to verify | The trigger name ("Opened or Closed"), the "Run Immediately" option and the setup time come from press reports. **Verify them on a device in Phase 5 (S-2)** before shipping the copy |
| Self-test | The user closes and opens the phone. FoldPulse checks for a `shortcut` fold **and** a `shortcut` unfold within 60 s → "Working ✓"; otherwise it names the failing step |
| Recovery | "**Can't find the trigger?** It needs iOS 27.2 or later (Settings → General → About). FoldPulse still counts automatically while it's open." (Learned in the Phase 1b spike) |
| Version gate | If the device runs iOS < 27.2, the screen shows the update notice instead of the steps |
| Honesty | Never says background counting is on until the self-test passes |
| Acceptance | US-02 AC1–AC6 |

## 9. Settings — `o-settings`

| Group | Rows |
|---|---|
| Counting | Background counting (status: "Not set up" / "Self-test passed" / "Not seen recently" → Setup) · Milestone notifications (off). *"Count gaps in totals" removed: deferred to v1.1 (D-6); gaps are always excluded (D-2)* |
| Appearance | Theme: System / Light / Dark |
| Your data | Export data · **Reset all data** (destructive, two-step confirmation, type "RESET"). *Import deferred to v1.1 (D-6)* |
| About | Privacy ("Data stays on this iPhone" → privacy statement) · Version · Acknowledgements |

## 10. Export sheet — `o-export`

Format CSV / JSON · range (all time / custom) · privacy card ("never uploads… fold times can reveal daily routines") · **Export** → system share sheet. CSV cells are escaped against formula injection (PRIVACY_REVIEW P-4). *Import is v1.1 (D-6); its flow is kept in USER_FLOWS F4 for later.*

## 11. Milestone celebration — `o-milestone`

Shown **once** per milestone, the next time the app is opened after crossing it: pulse line draws in, the milestone number in the gradient, date reached, next milestone, one button "Nice". It is never re-shown, even if deletions drop the total (feasibility §6). No confetti, streaks or badges.

## 12. Manual-only mode — `o-manual-only`

On devices where no hinge reading has ever been received after 10 s on screen (and the model has no hinge), FoldPulse explains: "This iPhone has no hinge. Automatic counting needs iPhone Duo. You can still record folds manually." Widgets and analytics work the same. Coverage is hidden. (D-4; App Review 2.4.1.)

## 13. Error and edge states (all screens)

| Situation | Behaviour |
|---|---|
| Storage write fails | Non-blocking banner "Couldn't save the last fold. Retrying." The event is kept in the pending queue |
| Clock or time-zone change | Days re-bucket per the stored `localDate` rules; no user-facing message |
| Import file invalid | Sheet with a specific reason; nothing is written |
| Data reset | Returns to the first-run Today state; widgets reload |
