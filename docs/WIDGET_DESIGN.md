# FoldPulse — Widget Design

**Owner:** Agent 4 (UI/UX) · **Reviewed by:** Agent 10 (Compliance), Agent 11 (Performance)
**Version:** 1.0 · 9 November 2026 · Mockups: `w-home.png`, `w-standby.png`, `w-lock.png`

---

## 1. Lean v1 widget set (decision D-6)

| Widget | Family | Content | Mockup |
|---|---|---|---|
| **Today** (Home Screen) | `systemSmall` | "Today" · today's folds (hero) · "folds" · "1,284 since install" (never "total") · freshness · pulse mark | `w-home` (light & dark) |
| **StandBy** | `systemSmall` presented by the system in StandBy | Same widget. The system scales it and applies the night-mode red tint | `w-standby` |
| **Today ring** (Lock Screen) | `accessoryCircular` | Today's folds inside a gauge of today ÷ 7-day daily average (capped at 100%) | `w-lock` |
| **Today + total** (Lock Screen) | `accessoryRectangular` | "FoldPulse" · "64 folds today" · "1,284 since install" | `w-lock` |

Deferred to v1.1: `systemMedium`, `systemLarge`, `accessoryInline`, and the interactive "+ Fold" button. The button is also inactive while the phone is locked (an Apple restriction) and runs in the widget process (risk R-18).

## 2. Data and freshness

- The widget reads **`WidgetSnapshot.json`** from the App Group (file protection **`completeUntilFirstUserAuthentication`**, so it stays readable on the Lock Screen and writable by background intents while locked): `todayFolds`, `todayUnfolds`, `totalSinceInstall`, `dailyAverage7d`, `nextMilestone`, `localDate`, `generatedAt`. It never opens the database.
- **Freshness label:** "as of 14:02" whenever `now − generatedAt > 15 min`. Otherwise no label (Small) or "Updated just now" (in the app only).
- **Midnight rule:** the timeline contains a second entry at the next local midnight. From that moment "Today" shows **"—"** until the app refreshes the snapshot (it can't know about folds recorded after midnight until then), and the total keeps its "as of" label. No reload is needed (Apple: predictable timeline events).
- **Reload policy (Agent 11):** reload immediately when the app is in the foreground (unbudgeted). From background intents, reload at most once every 5 minutes (coalesced). The budget is roughly 40–70 reloads a day.
- **Empty state:** "0 · Start folding" before any data. Tapping the widget opens Today.

## 3. Rendering modes

| Mode | Treatment |
|---|---|
| Full colour (Home) | `containerBackground` = `surface` token; numerals `text`; pulse mark `accent` |
| Accented / tinted Home Screen | Numerals and pulse marked `.widgetAccentable()`; background removed by the system |
| Vibrant (Lock Screen, StandBy night) | Monochrome; hierarchy via opacity (primary 100%, secondary 70%) |
| Clear / Liquid Glass Home Screen styles | No custom background images; rely on system materials |

Checked with `@Environment(\.widgetRenderingMode)`.

## 4. Privacy

- Lock Screen counts **and the gauge value** use `.privacySensitive()`. The system draws the redaction, so the "••" in `w-lock` (bottom row) is an approximation, to be checked on a device.
- Widgets show counts only, never timestamps of individual folds.

## 5. Accessibility

- VoiceOver label: "FoldPulse. 64 folds today. 1,284 since install. Updated 14:02."
- Numerals use Dynamic Type within widget limits. In the circular family the number shrinks to fit (`minimumScaleFactor(0.6)`) rather than truncating.
- The gauge also announces its value: "64 of your daily average of 72".

## 6. StandBy notes

StandBy shows Home Screen small widgets when an iPhone is charging, locked and on its side. **On iPhone Duo, which pose (closed or open) enters StandBy is unverified** (spike observation O-4 was skipped). FoldPulse adds nothing StandBy-specific beyond a widget that reads well at a distance: one hero number, two short labels. **It does not claim to replace or customise StandBy.**
