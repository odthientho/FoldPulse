#!/usr/bin/env python3
"""Build docs/phase-02-design.pdf (Phase 2 — Brand, UI/UX & Design).

Reuses the Phase 1 pipeline (pandoc → HTML → Chromium → PDF, two passes for
TOC page numbers). Run design/mockups/build_mockups.py and
design/flows/build_flows.py first so the images are current.

Usage: python3 tools/pdf/build_phase2.py
"""
import html
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import build_phase1 as base  # noqa: E402
from pypdf import PdfReader, PdfWriter  # noqa: E402

ROOT = base.ROOT
DOCS, BUILD = base.DOCS, base.BUILD
DESIGN = ROOT / "design"
PNG = DESIGN / "mockups" / "png"
OUT = DOCS / "phase-02-design.pdf"
VERSION, DATE = "1.0", "9 November 2026"


def img(path, caption, width="100%"):
    return (f'<figure><img src="file://{path}" style="width:{width};display:block;margin:0 auto">'
            f'<figcaption>{html.escape(caption)}</figcaption></figure>')


def gallery(items, cols=3):
    cells = "".join(
        f'<div class="gcell"><img src="file://{PNG / (fid + ".png")}"><div class="gcap">{html.escape(cap)}</div></div>'
        for fid, cap in items)
    return f'<div class="gallery c{cols}">{cells}</div>'


def doc(name):
    return base.doc_body(name)


EXEC_MD = """
## What this phase delivers

FoldPulse now has a complete, reviewed design, ready to be built:

- **Brand and final app icon:** an open foldable crossed by a pulse line, with default, dark and tinted variants, tested down to 40 px.
- **A design system:** colour tokens with **measured** contrast (all 36 text pairs pass WCAG AA), type, spacing, components, motion and accessibility rules.
- **24 high-fidelity mockups** in light and dark, for the outer (5.4") and inner (7.6") displays: onboarding, Today (including the honest "background counting not set up" state), Record, History, Edit, Insights, Coverage, background-counting setup, Settings, Export, Milestone and manual-only mode.
- **Widgets:** Home Screen small (also used in StandBy) and Lock Screen circular and rectangular, with freshness, midnight and privacy rules.
- **User flows** for first launch, optional background setup with self-test, recording and correcting, export and reset, milestones and non-hinge devices.

## Decisions this design follows

| Decision | Effect on the design |
|---|---|
| D-5 Paid up front | No paywalls, upgrade prompts, tip jars or ads anywhere |
| D-6 Lean v1 | Three widgets; no import, gap toggle, heat strip or session stats (tagged v1.1) |
| C-2r Device test skipped | Background counting is **optional and unverified**. The default "counting only while open" state is designed honestly, and setup reports status only through a self-test |
| D-2 Gaps excluded | Gaps are shown in History and Coverage, never added to totals |

## What changed after the agent reviews

The independent reviewers found real problems, and all of them were fixed before this report:
- **Setup screen:** it implied FoldPulse could see the user's Shortcuts steps. It now shows plain numbered steps, and only the self-test reports a status.
- **Coverage metric:** it overclaimed. It is now "Counted for you · % of recorded folds", with no "Good" verdict.
- **Sample data:** it was inconsistent (wrong weekdays, totals that didn't add up, a misplaced gap row). It was regenerated from one seed.
- **Icon:** it read as an open book at small sizes. It was redesigned.
- **Fold rule and controls:** the fold-region rule was corrected, and custom controls were replaced by system controls.

## Recommendation

**Approve Phase 2.** Two open items are recorded and not hidden:
1. **R-28 (High):** FoldPulse is a paid app whose background counting is unverified. The Founder Representative strongly recommends updating your iPhone Duo to **iOS 27.2** and running the 10-minute automation check (S-2/S-3) **before a price is set**.
2. **I-24:** UI Developer and Compliance disagree about the inner-display tab bar when the phone is partially folded. It will be checked in the Xcode simulator in Phase 3.
"""

METHOD_MD = """
## Inputs

Phase 1 report and documents; decisions A-1, C-1, C-2r, D-1…D-6, I-17 (`DECISIONS.md`); partial device results (`SPIKE_RESULTS.md`): FoldProbe built unchanged, hinge callbacks fire continuously, and an informal 5/5 fold count was correct.

## Who did what

| Agent | Role in Phase 2 | Mode |
|---|---|---|
| 4 — UI/UX Design Director | Brand, icon, design system, screens, flows, widgets | Main session (author) |
| 5 — Senior iOS UI Developer | Buildability with system SwiftUI components | **Independent subagent** |
| 10 — Compliance & Accessibility | HIG, iPhone Duo guidance, widgets, App Review, accessibility | **Independent subagent** (with Agent 5) |
| 2 — Founder Representative | Value, simplicity, paid-app expectations | **Independent subagent** |
| 12 — Independent Final Reviewer | Consistency, overclaims, PRD alignment | **Independent subagent** (with Agent 2) |
| 7 — Data Analyst | Sample-data consistency, coverage definition | Main session (applied fixes) |
| 1 — Chief Product Manager | Scope alignment (PRD, MVP), issue log | Main session |

## How the mockups were made

The mockups are HTML/CSS built from the design-system tokens and rendered by headless Chromium at 2× (`design/mockups/`). Inter stands in for SF Pro. **Display proportions are assumptions** (outer 376 × 820 pt, inner 760 × 860 pt) to be checked in Xcode 27.1's iPhone Duo simulator in Phase 3. Bars, sheets and Liquid Glass are approximations of system components, which draw themselves in the real app.

**Sample data** (illustrative, never shown to users): installed **Fri Oct 24**, today **Mon Nov 9, 14:04**, 1,284 folds since install, last 7 days 58 · 77 · 69 · 81 · 74 · 73 · 64 (today so far), full-day average 72, busiest day Fri Nov 6 (81), coverage this week 303 automatic + 164 shortcut + 29 manual = 496 folds, 2 gaps.
"""

ACCESS_MD = """
| Area | Commitment | How it's verified |
|---|---|---|
| Contrast | All 36 text/background pairs ≥ 4.5:1; raw accent used only for graphics and large text (≥ 3:1) | **Measured**: `design/contrast_check.py` (table below) |
| Dynamic Type | To AX5; tiles stack; hero uses `ViewThatFits` + a scaled-size ceiling | Phase 4 UI tests at AX5 on both displays |
| VoiceOver | Sentence labels; Audio Graphs for charts; icon-only badges labelled; pulse hidden | Phase 5 VoiceOver walkthrough |
| Timing | Undo persists while assistive tech is running; History offers Undo any time | Phase 5 |
| Motion | Reduce Motion → crossfades; no auto-playing loops | Phase 5 |
| Colour independence | Every source and status carries a symbol and a word | Design review (done) |
| Targets | ≥ 44 pt; Record buttons 56 pt | Phase 4 |
| Privacy on the Lock Screen | `.privacySensitive()` on counts and the gauge | Phase 5 on device |

## Measured contrast (WCAG 2.x)
"""

REVIEWS_MD = """
## UI Developer (Agent 5) and Compliance & Accessibility (Agent 10)

| Finding | Severity | Resolution |
|---|---|---|
| Setup screen ticked steps FoldPulse cannot observe; "switch it off any time" implied an in-app switch | High | Plain numbered steps; self-test is the only status; "delete the automations to stop" |
| Outer display shows bars vertically: toolbar "+" was missing; Record sheet had no Close | High | "+ Record" item (icon + title, pinned trailing); Close + detents |
| The fold is reserved only when partially open | Medium | `ArrangementView` split; rule corrected |
| Gap toggle and Import contradicted D-6 | Medium | Removed from v1 (tagged v1.1) |
| "Captured automatically" clashed with the "Automatic" source | Medium | Renamed "Counted for you" |
| Custom chips, toast and buttons | Medium | Segmented Picker, Menu + DatePicker, List swipeActions, glassProminent buttons |
| Widget file protection while locked | Medium | `completeUntilFirstUserAuthentication` stated |
| Icon: Dark ≈ Default; reads as a book at 40 px; pulse + "Pulse" may look like a health app | Medium | Redesigned glyph, true dark and tinted; Utilities category, no health keywords (R-27) |
| 5 s Undo is a timing barrier | Medium | Persistent Undo with assistive tech + announcement |
| "••" redaction is system-drawn | Medium | Gauge also private; mockup marked approximate |
| AX5 hero cannot wrap; "1,284 total" wording; untokened beige; unlabelled icon badges | Low | All fixed |

## Founder Representative (Agent 2)

| Finding | Severity | Resolution |
|---|---|---|
| **A paid app whose core value (background counting) is unproven** | Critical | Recorded as **R-28 (High, Founder decision)**: run S-2/S-3 on iOS 27.2 before setting a price. Design made honest for the default state |
| Mockups showed only the happy path | High | Added `o-today-foreground` with "Folds counted since install" and the counting-only-while-open card |
| Gap toggle and Import over-built vs lean v1 | Medium | Removed (v1.1) |
| No App Store screenshot concept for a paid app | Medium | Explicitly deferred to Phase 6 (I-25) |
| Three coverage levels, two tokens | Low | Levels mapped to positive / text2 / warning |

## Independent Final Reviewer (Agent 12)

| Finding | Severity | Resolution |
|---|---|---|
| Coverage overclaims (missed folds not in the denominator) | High | "% of recorded folds"; no verdict word; PRD wording fixed |
| Setup mockup claimed impossible knowledge; trigger labels unverified | High | Fixed; labels marked "verify in S-2" |
| Sample data inconsistent | Medium | One seed dataset; weekday error (Nov 9 is a Monday) fixed |
| PRD and MVP out of date (3 s dedupe, deferred widgets, monetization) | Medium | Aligned with D-5, D-6, C-2r |
| Insights mockup vs spec mismatch; 9:41 status bars | Medium/Low | Aligned; 14:04 throughout |
| **Recommendation: approve with changes** | — | Changes applied in this version |

## Disagreements recorded

1. **Inner tab bar over the fold when partially open (I-24).** UI Developer: acceptable, because the system draws and positions it. Compliance: validate in the partially open pose first. **Resolution:** check in Xcode Device Hub at the start of Phase 3.
2. **Pricing before verification (R-28).** Founder Rep: don't set a price until S-2/S-3 pass. Recorded as a Founder decision; the design team can't resolve it.
"""

NEXT_MD = """
## Decisions requested

| # | Decision | Team recommendation |
|---|---|---|
| **A-2** | **Approve Phase 2** (design system, icon, screens, flows, widgets) | Approve |
| R-28 | Before setting a price: update your iPhone Duo to iOS 27.2 and run the 10-minute automation check (SPIKE_PLAN Parts 2–3, runs C and D) | Strongly recommended, not blocking Phase 3 |
| I-24 | Confirm that the inner tab bar is checked in the simulator in Phase 3 | Yes |

## What Phase 3 will do (after approval)

**Architecture & project foundation:**
- Create the Xcode project (app, widget extension, App Group), using your Mac via the same one-line script approach.
- Implement the data model and SwiftData persistence with file protection.
- Implement the design tokens and core components in SwiftUI.
- Set up unit and UI tests.
- Verify the build.
- Write ARCHITECTURE.md, DATABASE_DESIGN.md, DECISIONS updates and `phase-03-architecture.pdf`.

Because this cloud workspace can't run Xcode, each build will be verified on your Mac (or a macOS CI runner if you'd like one set up).
"""

SOURCES_MD = """
- Apple — Preparing your app for iPhone Duo: https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo
- Apple — Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- Apple — Keeping a widget up to date: https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date
- Apple — WidgetFamily: https://developer.apple.com/documentation/widgetkit/widgetfamily
- Apple — Adding interactivity to widgets: https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities
- Apple — SwiftUI onHingeChange(isEnabled:_:): https://developer.apple.com/documentation/swiftui/view/onhingechange(isenabled:_:)
- Apple — App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- W3C — WCAG 2.2 (contrast 1.4.3, timing 2.2.1): https://www.w3.org/TR/WCAG22/
- Project files: `docs/DESIGN_SYSTEM.md`, `docs/SCREEN_SPECIFICATIONS.md`, `docs/USER_FLOWS.md`, `docs/WIDGET_DESIGN.md`, `design/` (mockups, flows, icon, contrast check)
"""

OUTER = [
    ("o-onboard-1", "Onboarding 1 · welcome"), ("o-onboard-2", "Onboarding 2 · how counting works"), ("o-onboard-3", "Onboarding 3 · privacy"),
    ("o-today-light", "Today · light"), ("o-today-dark", "Today · dark"), ("o-today-foreground", "Today · background counting not set up"),
    ("o-today-empty", "Today · first run"), ("o-track", "Record sheet + Undo"), ("o-history", "History · swipe to delete, gap row"),
    ("o-edit", "Edit event"), ("o-insights", "Insights · last 7 days"), ("o-coverage", "Coverage detail"),
    ("o-setup", "Background counting setup + self-test"), ("o-settings", "Settings (lean v1)"), ("o-export", "Export with privacy note"),
    ("o-milestone", "Milestone (once)"), ("o-manual-only", "Non-hinge iPhone · manual mode"),
]
INNER = [("i-today", "Inner · Today (ArrangementView split)"), ("i-history", "Inner · History list + detail"), ("i-insights", "Inner · Insights")]


def flows_chapter():
    import re
    body = doc("USER_FLOWS.md")
    figs = {"f2": img(DESIGN / "flows" / "flow-setup.svg", "Figure 3 — First launch and optional background counting"),
            "f3": img(DESIGN / "flows" / "flow-record.svg", "Figure 4 — Recording and correcting events")}
    for key, fig in figs.items():
        m = re.search(r'<h2 id="' + key + r'[^"]*">', body)
        assert m, f"heading {key} not found"
        body = body[:m.start()] + fig + body[m.start():]
    return img(DESIGN / "flows" / "flow-nav.svg", "Figure 2 — Navigation map") + body


def chapters():
    contrast = (DESIGN / "contrast_report.md").read_text()
    return [
        ("Executive summary & recommendation",
         '<div class="decision"><div class="label">Phase 2 recommendation</div><div class="verdict">APPROVE</div>'
         '<p>The design is complete and reviewed. Two open items are recorded (R-28, I-24); neither blocks Phase 3.</p></div>' + base.md(EXEC_MD)),
        ("Inputs, team & method", base.md(METHOD_MD)),
        ("Brand & app icon", img(PNG / "icon-sheet.png", "Figure 1 — Final icon: default, dark and tinted appearances; small-size test; Home Screen") +
         base.md("""
**Why this icon:** an open foldable (two panels, hinge seam) crossed by a single pulse line, the "beat" of each fold. It contains no text and no Apple device silhouette or trademark. It was redesigned after the review: the Phase 1 V-shaped panels read as an open book at 40 px. The final layered version (background · panels · pulse) is assembled in **Icon Composer** in Phase 3, so the system can apply Liquid Glass highlights and the dark and tinted appearances.

**Brand voice:** plain, factual, warm. Counts are always "since install". No wear or health language, no gamification. Tagline: **Every Fold. Every Beat.**
""")),
        ("Design system", doc("DESIGN_SYSTEM.md")),
        ("Navigation & user flows", flows_chapter()),
        ("Screen designs",
         base.md("Sample data only. Outer display (5.4\"), light and dark. The system presents bars vertically on the side of the outer display (Apple's iPhone Duo guidance); FoldPulse uses the standard `TabView` and toolbar items so this happens automatically.")
         + gallery(OUTER, 3) + '<h2>Inner display (7.6")</h2>' + gallery(INNER, 2)
         + '<h2>Screen specifications</h2>' + doc("SCREEN_SPECIFICATIONS.md")),
        ("Widgets",
         img(PNG / "w-home.png", "Figure 5 — Home Screen small widget, light and dark", "70%")
         + img(PNG / "w-standby.png", "Figure 6 — StandBy (system-scaled small widget; right: night mode)", "90%")
         + img(PNG / "w-lock.png", "Figure 7 — Lock Screen circular and rectangular; bottom row: privacy-redacted (approximate)", "55%")
         + doc("WIDGET_DESIGN.md")),
        ("Accessibility review", base.md(ACCESS_MD + "\n" + contrast)),
        ("Agent reviews, issues & disagreements", base.md(REVIEWS_MD)),
        ("Decisions requested & next steps", base.md(NEXT_MD)),
        ("References", base.md(SOURCES_MD)),
    ]


EXTRA_CSS = """
.gallery { display: grid; gap: 5mm 4mm; margin: 3mm 0 6mm; }
.gallery.c3 { grid-template-columns: repeat(3, 1fr); } .gallery.c2 { grid-template-columns: repeat(2, 1fr); }
.gcell { break-inside: avoid; text-align: center; } .gcell img { width: 100%; display: block; }
.gcap { font-size: 7.6pt; color: #5B6472; margin-top: 1.2mm; }
figure img { max-width: 100%; }
"""


def cover_html():
    css = base.CSS
    icon = DESIGN / "icon" / "FoldPulse-icon-1024.png"
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head>
<body class="cover"><div class="cover-inner">
<div class="cover-icon"><img src="file://{icon}" style="width:120px;height:120px;border-radius:26px;box-shadow:0 8px 30px rgba(0,0,0,.4)"></div>
<div class="brand">FoldPulse</div><div class="tagline">Every Fold. Every Beat.</div>
<div class="phase">Phase 2 · Brand, UI/UX &amp; Design</div>
<h1 class="cover-title">Design Report &amp; Specifications</h1>
<table class="meta">
<tr><td>Version</td><td>{VERSION}</td></tr><tr><td>Date</td><td>{DATE}</td></tr>
<tr><td>Prepared for</td><td>Founder &amp; Product Owner</td></tr>
<tr><td>Prepared by</td><td>FoldPulse product team (12 agent roles)</td></tr>
<tr><td>Status</td><td>Submitted for Founder approval</td></tr>
<tr><td>Recommendation</td><td><b>APPROVE</b> (open items R-28, I-24 recorded)</td></tr>
</table>
<div class="cover-note">Confidential — prepared for the FoldPulse Founder. All numbers in mockups are sample data.</div>
</div></body></html>"""


def body_html(page_map):
    chs = chapters()
    toc = "".join(
        f'<li><span class="n">{i}</span><span class="t">{html.escape(t)}</span><span class="dots"></span><span class="p">{page_map.get(i, "")}</span></li>'
        for i, (t, _) in enumerate(chs, 1))
    parts = [f'<section class="toc"><h1 class="toch">Contents</h1><ol>{toc}</ol></section>']
    for i, (t, c) in enumerate(chs, 1):
        parts.append(f'<section class="chapter"><h1 class="chap"><span class="num">{i}</span> {html.escape(t)}<span class="marker">§§CH{i}§§</span></h1>{c}</section>')
    return base.nowrap_ids(f'<!doctype html><html><head><meta charset="utf-8"><style>{base.CSS}{EXTRA_CSS}</style></head><body>{"".join(parts)}</body></html>')


def main():
    n = len(chapters())
    cp, bp = BUILD / "p2-cover.html", BUILD / "p2-body.html"
    cp.write_text(cover_html())
    base.render(cp, BUILD / "p2-cover.pdf", None)
    pages = {}
    for _ in range(2):
        bp.write_text(body_html(pages))
        base.render(bp, BUILD / "p2-body.pdf", {"title": "FoldPulse · Phase 2 Design Report", "version": f"v{VERSION} · {DATE}"})
        pages = base.find_pages(BUILD / "p2-body.pdf", n)
    assert len(pages) == n, f"chapter markers missing: {pages}"
    w = PdfWriter()
    for f in (BUILD / "p2-cover.pdf", BUILD / "p2-body.pdf"):
        for p in PdfReader(str(f)).pages:
            w.add_page(p)
    w.add_metadata({"/Title": "FoldPulse — Phase 2 Design Report", "/Author": "FoldPulse product team",
                    "/Subject": "Brand, UI/UX and design", "/Keywords": "FoldPulse, iPhone Duo, design"})
    with open(OUT, "wb") as fh:
        w.write(fh)
    print(f"wrote {OUT} ({len(PdfReader(str(OUT)).pages)} pages); chapter pages: {pages}")


if __name__ == "__main__":
    main()
