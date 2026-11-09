# FoldPulse — Design System

**Owner:** Agent 4 — UI/UX Design Director · **Implementation review:** Agent 5 — Senior iOS UI Developer
**Version:** 1.1 (revised after agent reviews) · 9 November 2026 · **Status:** Phase 2, submitted for Founder approval

---

## 1. Brand

| Element | Decision |
|---|---|
| Name | **FoldPulse** (one word, capital F and P) |
| Tagline | **Every Fold. Every Beat.** |
| Personality | A precise, calm instrument. Native, premium, quiet. Closer to Weather or Fitness than to a game |
| Voice | Plain, factual, warm. Numbers first. Never alarmist about the hinge, never gamified |
| Signature motif | The **pulse line**: a short ECG-like stroke that "beats" once when a fold is recorded |
| Business model impact | Paid up front (D-5): **no paywalls, upsells, tip prompts or ads** anywhere in the UI |

### 1.1 Copy rules

- Counts are always **"since install"** or **"since tracking began"**. Never "lifetime of your phone".
- No wear or health language ("hinge health", "wear", "lifespan", "damage"). FoldPulse counts; it does not diagnose.
- Every number can say **where it came from** (Automatic / Shortcut / Manual / Gap).
- Background counting is described as **optional**: "Count in the background with a Shortcuts automation".
- Stale data says so: "as of 14:02".
- Numbers use locale grouping (1,284 / 1.284) and monospaced digits.

## 2. App icon (final recommendation)

The final icon refines **Concept A, "Fold + Pulse"**: an **open foldable seen from the front**, with a left panel in Pulse Blue and a right panel in Signal Cyan, separated by a hinge seam, crossed by one white pulse line, on a deep-navy squircle. *Revision:* the Phase 1 V-shaped panels read as an open book at 40 px (Compliance review), so the panels are now upright and rounded like a phone. Files: `design/icon/` (SVG + 1024 px PNG for each appearance).

| Variant | Use |
|---|---|
| Default (navy background) | Home Screen, App Store |
| Dark | iOS dark icon appearance: black background, brighter panels |
| Tinted | iOS tinted appearance: monochrome glyph (panels + pulse) on the system tint |
| Layer structure (Liquid Glass) | Built in **Icon Composer** with three layers: background, panels, pulse. The system adds specular highlights and depth |

**Category and keywords:** Utilities. No health or medical keywords anywhere in the listing, because the pulse motif plus the name could otherwise be read as a health app (App Review 1.4.1 / 5.1.3 risk, R-27).

Small-size rule: at 29 pt the pulse line must stay ≥ 2 px thick and the panels must stay distinguishable. This was tested at 1024, 180, 120, 87, 58 and 40 px (Figure 2 of the Phase 2 report). The icon contains no text and no Apple device silhouette or trademarked shapes.

## 3. Colour

All colours are defined as **semantic tokens** in the asset catalog, with Light and Dark variants. Contrast was **measured** with `design/contrast_check.py` (WCAG 2.x). **All 36 text/background pairs pass AA**; the full table is in `design/contrast_report.md`.

| Token | Light | Dark | Use | Lowest measured contrast vs `bg`/`surface` (light / dark) |
|---|---|---|---|---|
| `bg` | #F2F4F8 | #070F1F | Screen background | — |
| `surface` | #FFFFFF | #12233F | Cards, tiles | — |
| `text` | #0B1B33 | #FFFFFF | Primary text, hero numbers | 15.65:1 / 15.70:1 |
| `text2` | #55606E | #9FB1CF | Secondary labels | 5.81:1 / 7.22:1 |
| `accent` | #2F7BFF | #4C8DFF | Pulse Blue: charts, large numerals, icons, buttons (fills) | 3.53:1 / 4.90:1 (graphics & large text only; needs 3:1) |
| `accentText` | #1D5FD8 | #6FA2FF | Accent-coloured **small** text and links | 5.18:1 / 6.19:1 |
| `src.automatic` | = accent | = accent | Automatic (hinge) events | — |
| `src.shortcut` | #0B6F85 | #5CC8FF | Shortcut-automation events | 5.26:1 / 8.34:1 |
| `src.manual` | #55606E | #B4C0D3 | Manual events | 5.81:1 / 8.54:1 |
| `src.gap` | outline only, `text2` | outline only | Inferred gaps (dashed) | — |
| `positive` | #1E7F4F | #5BD08E | Coverage good (≥ 90%) | 4.54:1 / 8.12:1 |
| `warning` | #A15C00 | #FFB547 | Coverage low, setup needed | 4.71:1 / 8.93:1 |
| `destructive` | #C2362B | #FF6B5E | Delete, reset | 4.95:1 / 5.62:1 |

**Rule:** colour is never the only carrier of meaning. Source badges pair colour with an SF Symbol and a text label, and coverage pairs colour with a percentage and a word ("Good", "Low").

**Gradient:** Pulse Blue → Signal Cyan (#5CC8FF), used only for the hero progress bar and the icon.

## 4. Typography

The app uses **SF Pro** (the system font). All styles use **Dynamic Type** text styles, so they scale up to AX5. Mockups use Inter as a stand-in because SF Pro cannot be used outside Apple platforms.

| Role | SwiftUI | Notes |
|---|---|---|
| Hero numeral | `.system(size: 64, weight: .bold, design: .rounded)` scaled by `@ScaledMetric(relativeTo: .largeTitle)`, `.monospacedDigit()` | Total since install; `.contentTransition(.numericText())` |
| Tile numeral | `.system(.title, design: .rounded).weight(.bold).monospacedDigit()` | Today, averages |
| Screen title | `.largeTitle` (system navigation title) | |
| Section header | `.headline` | |
| Body | `.body` | |
| Label / meta | `.subheadline`, `.footnote` in `text2` | |
| Badge | `.caption.weight(.semibold)` | |

At accessibility sizes (≥ AX1), tiles stack vertically. The hero numeral uses `ViewThatFits` with a ceiling on the scaled size and `minimumScaleFactor(0.5)` as a last resort: a 6-digit number cannot wrap on the 5.4" display. Text in rows is never truncated; rows grow in height instead.

## 5. Layout, spacing and shape

- **Grid:** 4-pt base. Spacing scale: 4 · 8 · 12 · 16 · 20 · 24 · 32.
- **Margins:** system readable margins (`.scenePadding()`); cards use 16 pt inner padding.
- **Corners:** cards 20 pt, tiles 16 pt, badges 8 pt, all `RoundedRectangle(style: .continuous)`.
- **Depth:** no drop shadows. Hierarchy comes from surface colour, system **materials** and **Liquid Glass** on system bars.
- **Displays:** layouts are built from **size classes and container size**, never device checks (Apple: *Preparing your app for iPhone Duo*).
  - **Outer display** (compact width): one column. The system may present the tab bar **vertically along the side**, so FoldPulse uses `TabView` and never draws custom bars.
  - **Inner display** (regular width): two panes built with **`ArrangementView` (split style)**, with primary content and a secondary pane. When **fully open**, the screen has no fold division, so content may span it; the split is a layout choice, not a hinge workaround.
  - **Partially folded ("tent" / "laptop")**: the fold becomes an active reserved region (`.divisions`). `ArrangementView` moves the panes onto either side, and controls avoid the fold. *Corrected after the UI Developer review: the fold is reserved only when partially open.*

## 6. Components

| Component | Description | States |
|---|---|---|
| `HeroCounter` | "Folds since install" label + hero numeral + pulse line | normal, counting animation, empty ("0" + setup prompt) |
| `StatTile` | Small card: label, numeral, optional caption | normal, no-data ("—") |
| `CoverageTile` | **"Counted for you"**: % **of recorded folds** captured without tapping + stacked bar by source; tap → coverage detail. *Renamed after review:* "captured automatically" clashed with the "Automatic" source name and overclaimed (missed folds can't be in the denominator) | high (≥ 90%, `positive`) · medium (70–89%, `text2`) · low (< 70%, `warning`) · not set up (`warning` card) |
| `MilestoneBar` | Gradient progress bar toward the next milestone, with "N to go" | normal, reached |
| `SourceBadge` | Symbol + label: Automatic · Shortcut · Manual · Gap | 4 variants; also icon-only for compact rows |
| `EventRow` | Time, type (Fold/Unfold), source badge, note indicator | normal, edited, gap (dashed) |
| `WeekChart` | Swift Charts bar chart, 7 days; today highlighted | data, partial, empty |
| `RecordButton` | System `Button` with `.buttonStyle(.glassProminent)` (fallback `.borderedProminent`) and `.controlSize(.extraLarge)`; not hand-drawn | enabled, just-recorded (Undo) |
| `FreshnessLabel` | "Updated just now" / "as of 14:02" | live, stale |
| `SetupCard` | Inline call to action for background counting | not set up, verified, failed self-test |
| `EmptyState` | `ContentUnavailableView` with action | — |
| Filters | Source filter = segmented `Picker`; date range = toolbar `Menu` + `DatePicker`. No custom chips | — |
| Lists | `List` + `.swipeActions` (VoiceOver actions come for free) | — |

## 7. Iconography

The app uses **SF Symbols** only, so they inherit weight and Dynamic Type. Proposed symbols (names to be confirmed in the SF Symbols app for iOS 27):

| Concept | Symbol |
|---|---|
| Today tab | `waveform.path.ecg` |
| History tab | `list.bullet.rectangle` |
| Insights tab | `chart.bar.xaxis` |
| Settings tab | `gearshape` |
| Automatic | `sensor.fill` |
| Shortcut | `square.2.layers.3d` |
| Manual | `hand.tap` |
| Gap | `questionmark.circle.dashed` (fallback `questionmark.circle`) |
| Fold / Unfold | `arrow.down.right.and.arrow.up.left` / `arrow.up.left.and.arrow.down.right` |

## 8. Motion and haptics

| Moment | Motion | Haptic | Reduce Motion |
|---|---|---|---|
| Automatic fold recorded (app open) | Hero numeral `.numericText()` roll + one pulse-line beat (600 ms) | **None**: avoids noise across ~100 folds a day | Crossfade only |
| Manual record | Same + button ripple; Undo toast. **Undo stays until dismissed when VoiceOver, Switch Control or Voice Control is running** (no timing barrier, WCAG 2.2.1), and an announcement is posted. Undo is also always possible from History | `.sensoryFeedback(.increase)` | Crossfade, haptic kept |
| Milestone reached | Sheet with the pulse line drawing itself (1.2 s), once | `.success` | Static illustration |
| Delete event | System list animation | `.impact(weight: .light)` | System default |

## 9. Accessibility checklist (applies to every screen)

- Dynamic Type through AX5 without truncation. Layouts reflow at AX sizes.
- VoiceOver: counters read as full sentences ("1,284 folds since install"). Charts expose **Audio Graphs** via `AXChartDescriptor`. Source badges read their label, including icon-only badges on the outer display (`accessibilityLabel`). The pulse animation is hidden from accessibility.
- Minimum hit target 44 × 44 pt. The Record buttons are 56 pt tall.
- Contrast AA, measured (§3). Supports Increase Contrast (higher-contrast token variants) and Smart Invert (images excluded).
- Reduce Motion and Reduce Transparency respected.
- No information conveyed by colour alone, sound alone or haptics alone.
- Every control is reachable with Full Keyboard Access and Voice Control, with visible labels.
