#!/usr/bin/env python3
"""Build docs/phase-01-feasibility.pdf from the Phase 1 Markdown documents.

Pipeline: Markdown (pandoc → HTML) + report chapters + SVG figures → HTML →
Chromium (Playwright, render.js) → PDF. The cover is rendered separately
(no header/footer) and merged with pypdf. Two passes fill in TOC page numbers.

Usage: python3 tools/pdf/build_phase1.py
"""
import html
import json
import pathlib
import re
import subprocess

from pypdf import PdfReader, PdfWriter

ROOT = pathlib.Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
HERE = pathlib.Path(__file__).resolve().parent
ASSETS = HERE / "assets"
BUILD = HERE / "build"
BUILD.mkdir(exist_ok=True)
OUT = DOCS / "phase-01-feasibility.pdf"

VERSION = "1.0"
DATE = "9 November 2026"


def md(text: str) -> str:
    return subprocess.run(
        ["pandoc", "-f", "gfm", "-t", "html5", "--no-highlight"],
        input=text, capture_output=True, text=True, check=True,
    ).stdout


def doc_body(name: str) -> str:
    """Markdown body of a docs/ file without its title block."""
    text = (DOCS / name).read_text()
    # drop the document's own title/metadata block: leading H1, bold metadata
    # lines (e.g. **Owner:** …), blank lines and horizontal rules
    lines = text.splitlines()
    i = 0
    while i < len(lines) and (not lines[i].strip() or lines[i].startswith("# ")
                              or lines[i].strip() == "---"
                              or re.match(r"^\*\*[^*]+[:.]\*\*", lines[i])
                              or lines[i].strip() == "**Every Fold. Every Beat.**"):
        i += 1
    body = "\n".join(lines[i:])
    # demote: ## → h2 stays; the chapter supplies the h1
    return md(body)


def nowrap_ids(h: str) -> str:
    """Keep short IDs such as R-01, D-6, I-17 on one line inside table cells."""
    return re.sub(r'<td>([A-Z]{1,2}-\d{1,2}[a-z]?)</td>', r'<td><span class="idc">\1</span></td>', h)


def svg(name: str, caption: str) -> str:
    data = (ASSETS / name).read_text()
    return f'<figure>{data}<figcaption>{html.escape(caption)}</figcaption></figure>'


# ---------------------------------------------------------------- chapters
EXEC = """
<div class="decision"><div class="label">Phase 1 recommendation</div>
<div class="verdict">CONDITIONAL GO</div>
<p>FoldPulse is technically feasible with public Apple APIs, as an honest <b>hybrid tracker</b>. Two conditions must be met before significant design and build investment.</p></div>
"""

EXEC_MD = """
## What we set out to learn

Can a third-party iOS app count how often an iPhone Duo is folded and unfolded, accurately, privately, and without unsupported APIs? And is the product worth building?

## What we found

1. **iPhone Duo exposes a public hinge API (iOS 27.1).** `onHingeChange(isEnabled:_:)` in SwiftUI and `UIHingeInteraction` in UIKit report a hinge *status* (closed / partially open / fully open) and an *angle*. Apple documents both. **They only work while FoldPulse's UI is on screen.** There is no background mode.
2. **Background counting is possible only with the user's help.** iOS 27.2 added a Shortcuts automation trigger, "When my iPhone is opened or closed". FoldPulse can provide "Record Fold / Record Unfold" actions that run in the background. The user has to create the automation once. It is not yet verified whether it runs without a confirmation prompt and fires reliably while the phone is locked. **That is the biggest technical unknown.**
3. **Manual recording** and a widget button complete the picture. Core Motion and private APIs were examined and rejected.
4. **Widgets are well supported:** Home Screen, Lock Screen and StandBy (via the small widget). They refresh on a budget of roughly 40–70 updates a day, so they must show an "as of" time and never pretend to be live.
5. **The market already has fold counters.** *Duo Fold Counter* (about #10 in US Utilities), *FoldMeter* and *Foldometer* use the same mechanism. That proves the approach passes App Review. It also means FoldPulse must win on trust and polish. The team proposes a **tracking-coverage indicator** as the headline differentiator, with a **lean v1**.
6. **Local-only privacy is achievable**, and the "Data Not Collected" App Store label is justified, provided the seven privacy requirements in Chapter 7 are met.

## What FoldPulse can honestly claim

> "FoldPulse counts your folds automatically while it's open, and in the background once you add the FoldPulse automation in Shortcuts. Every count shows where it came from."

FoldPulse must **not** claim to "automatically count every fold", and it must not estimate hinge wear.

## Conditions of the GO

| # | Condition | Owner |
|---|---|---|
| C-1 | **Development access:** a Mac with Xcode 27.1+ and a physical iPhone Duo, or an equivalent macOS CI runner plus a device. The current cloud workspace runs Linux and cannot build or run iOS apps | Founder |
| C-2 | **Device validation spike (Phase 1b, 1–2 days), run before Phase 2 design.** It must show that (a) FoldPulse receives the `closed` update when the phone is folded with the app open, and (b) the Shortcuts automation runs without a prompt and captures ≥ 95% of folds while locked, measured against an independent tally over ≥ 300 cycles | Architect + Founder |
| C-3 | **Founder decisions** D-1 (compete despite existing apps), D-5 (business model) and D-6 (lean v1) | Founder |

**If C-2(b) fails**, the team recommends **pausing** and re-evaluating: a foreground-only fold counter is unlikely to beat the existing competitors. **If C-2(a) fails**, automatic counting is limited to unfolds, and the scope is re-planned with the Founder.
"""

TEAM_MD = """
## Environment inspected

| Item | Finding |
|---|---|
| Workspace | Linux cloud container; git repository `Church-Deacon-Election` (empty) on branch `claude/foldpulse-ios-development-gwxmj9` |
| iOS toolchain | **Not available** (no Xcode, Simulator or `swift` for iOS). Code cannot be compiled here |
| Research access | Apple developer documentation fetched directly (developer.apple.com JSON). Other sites accessed through web search summaries only (network policy) |
| Document tooling | Pandoc + headless Chromium (Playwright) for PDF; pdftoppm/pypdf for inspection |
| Agent capability | Claude Code subagents available |

## How the 12-agent team was run

Claude Code subagents were used for the **independent reviews**. Each reviewer ran as a separate agent, with its own context, its own research tools and no ability to edit the documents, so no agent approved its own work. Authoring roles were performed in the main session and are identified by role in every document.

| Agent | Role | Phase 1 contribution | Mode |
|---|---|---|---|
| 1 | Chief Product Manager | Research questions, PRD, MVP scope, roadmap, issue log, consolidation | Main session |
| 2 | Founder Representative | Challenged scope, value, competition and retention | **Independent subagent** |
| 3 | Senior iOS Technical Architect | Hinge/Shortcuts/WidgetKit research, feasibility matrix, architecture direction | Main session |
| 4 | UI/UX Design Director | Initial visual direction, icon concepts, dashboard and widget sketches (Chapter 6) | Main session |
| 5 | Senior iOS UI Developer | No Phase 1 task (no code in Phase 1); reviewed the layout feasibility of the concepts | Main session |
| 6 | Senior iOS Software Engineer | Event pipeline concept (debounce, reconcile, single writer) | Main session |
| 7 | Data Analyst | Rewrote the metric and event rules | **Independent subagent** |
| 8 | Privacy & Security Engineer | Privacy review (Chapter 7) | **Independent subagent** |
| 9 | QA & Automation Engineer | Spike ground-truth protocol (≥ 300 cycles, independent tally) | Main session |
| 10 | Apple Platform Compliance Specialist | Independently re-verified APIs; App Review risks | **Independent subagent** |
| 11 | Performance & Battery Engineer | Battery and widget-budget review (Chapter 8) | Main session |
| 12 | Independent Final Reviewer | Challenged all conclusions; GO/NO-GO assessment | **Independent subagent** |

## Initial research questions (Agent 1)

1. Does iPhone Duo expose hinge or fold state to third-party apps through public API? Since which iOS version?
2. Can fold events be observed in the foreground, in the background, and when the app is not running?
3. Which supported mechanisms (App Intents, Shortcuts, widgets, Controls) can extend tracking outside the app?
4. What can widgets show on the Home Screen, Lock Screen and in StandBy, and how fresh can they be?
5. Which metrics can be computed reliably given partial observation?
6. What does the local-only privacy promise require in practice (App Store label, privacy manifest, backups)?
7. Who else is solving this, and why would someone choose FoldPulse?
"""

VISUAL_MD = """
This chapter is the **UI/UX Design Director's initial direction**, offered so that the Founder can react early. It is a **temporary concept**: the brand, icon and screens are finalised in Phase 2. All numbers shown are illustrative, not user data.

**Positioning:** a premium, Apple-native instrument, closer to the Activity and Weather apps than to a game. The design is quiet and precise, with one accent colour. The interface's one moment of personality is the "pulse" line that traces each fold.
"""

VISUAL_MD2 = """
**Layout across displays.** The outer (5.4") display shows a single-column dashboard, with the system presenting bars vertically at the side. The inner (7.6") display uses a two-column split built from system containers, and keeps content out of the fold region (reserved regions API). Both displays are designed from the start; neither is a scaled copy of the other.

**Accessibility commitments for Phase 2:** Dynamic Type to AX5; VoiceOver labels and Audio Graphs for charts; contrast ≥ 4.5:1 in both themes; Reduce Motion replaces the pulse animation with a fade; colour is never the only carrier of meaning (source badges use both icon and text).
"""

PERF_MD = """
**Owner:** Agent 11 — Performance and Battery Engineer

| Area | Assessment | Design rule |
|---|---|---|
| Hinge observation | Event-driven system callbacks, no polling. Negligible cost while the app is on screen | Observer active only in the foreground; angle ignored except for optional effects |
| Background intents | Each automation run launches FoldPulse briefly in the background. About 100–300 runs a day for heavy users | Intent work kept minimal: append one event, update the snapshot, coalesce widget reloads. Target < 50 ms CPU per run |
| Widget refresh | Budget of about 40–70 reloads a day (Apple). Reloads from the foreground app and from widget intents are free | Reload immediately when in the foreground. In the background, at most one reload per 5 minutes; widgets show "as of" |
| Storage | 100,000 events ≈ a few MB | Raw event log + cached daily aggregates, invalidated on edit |
| Startup | Dashboard from the cached snapshot first, then recompute | Cold start < 1 s; first paint < 400 ms |
| Prohibited | Continuous Core Motion, location, background audio, silent push, timers | Never used |

**Open item:** the real battery cost of hundreds of daily automation launches is unmeasured. It is spike step 6 (24-hour test).
"""

REVIEWS_MD = """
Each reviewer below ran as an independent subagent. Its findings and the response to them are summarised here; the full trail is in the issue log (Chapter 9).

## Apple Platform Compliance Specialist (Agent 10)

| Finding | Severity | Response |
|---|---|---|
| Confirmed the hinge APIs, `supportedModes(.background)` (iOS 26+) and the WidgetKit budget wording against Apple's docs | — | Agreed |
| **SwiftUI `onHingeChange(isEnabled:_:)` is documented**; the first research pass missed it (wrong URL). `DeviceHinge.Status` is a struct and depends on angle *and orientation* | High | Verified independently by the Architect; feasibility report corrected; R-15 closed, R-22 added; rotation test added to the spike |
| Widget button intents run in the **widget extension process** and are **inactive while locked** | High | Verified in Apple docs; pending-events queue design; button is unlocked-only |
| No hinge key in `UIRequiredDeviceCapabilities`; iPhone apps must run on iPad (2.4.1) | Medium | Manual-only mode with a notice; iPad testing; opt out of Mac |
| Saturated category (4.3(b)); privacy policy URL required (5.1.1(i)) | Medium | R-23, R-24; App Review notes with demo video |

## Privacy & Security Engineer (Agent 8)

| Finding | Severity | Response |
|---|---|---|
| "Data Not Collected" label is valid; local notifications only is correct | — | Agreed |
| Privacy manifest (`PrivacyInfo.xcprivacy`) missing from the plan, for app and widget | High | Requirement P-2 |
| Locked-device writes fail under `Complete` file protection | High | `CompleteUntilFirstUserAuthentication` (P-3); spike test |
| App Group data is included in iCloud/Finder backups, so "no cloud" wording overstated | Medium | Disclosure P-7; R-11 downgraded |
| CSV formula injection; exports reveal daily routine | Medium | P-4 |
| `.privacySensitive()` on Lock Screen; shortcut events are unverified | Low | P-6; R-25 |

## Founder Representative (Agent 2)

| Finding | Severity | Response |
|---|---|---|
| Market risk understated: Duo Fold Counter is about #10 in US Utilities and already does background counting and a "hinge life" estimate | High | PRD §4 rewritten; R-21 |
| MVP too big for a late entrant | High | Lean v1 proposed; **Founder decision D-6** |
| Add a tracking-coverage indicator as the trust differentiator | High | Added as F15 / US-12 (Must) |
| Success can't be measured with local-only metrics | Medium | Use App Store Connect analytics (opt-in, Apple-aggregated; no SDK) |
| Users want a "hinge life" number | Medium | Provide factual context ("folds since install"); still no wear estimate. **Disagreement noted:** the Founder Rep considers this a retention risk; the PM and Compliance consider a wear estimate misleading |
| **Recommendation:** Conditional GO on a slimmed v1; stop if the automation needs confirmation or misses folds while locked | — | Adopted as the decision rule |

## Data Analyst (Agent 7)

| Finding | Severity | Response |
|---|---|---|
| Inferred-event rule was self-contradictory and had no time for day bucketing | Critical | Rewritten: alternation-based, uncertainty interval, bucketed on the later bound |
| First reading after resume would create a false unfold and double count | Critical | Baseline-on-activation rule |
| 3-second time-based dedupe was order-dependent | High | Symmetric one-to-one pairing, ±10 s, nothing opposite in between |
| Debounce timing and lost pending state on backgrounding | High | Timestamp = first entered; flush on scene-phase change |
| Import resurrects deleted events | High | Tombstones + `updatedAt`; re-run reconciliation |
| Averages, DST, sessions, milestones, widget at midnight | Medium/Low | All adopted (feasibility §6) |

## Independent Final Reviewer (Agent 12)

| Finding | Severity | Response |
|---|---|---|
| Verified `UIHingeInteraction`, `UIHinge.Status`, `supportedModes`, the widget budget. UIKit `Update` has no previous value | — | Agreed; noted in the report |
| **The core assumption, that a foreground fold is observable, is tested too late** | High | Spike moved to **Phase 1b, before design** (condition C-2) |
| Phase 1 was marked "Complete" before review; the PDF was referenced before it existed | High | Statuses corrected; this PDF produced and checked |
| `nil` hinge has two meanings | Medium | Hinged-device decision persisted from the first non-nil reading |
| Locked writes; second writer from the widget; one-directional dedupe; scene duplication | Medium | All addressed in the design |
| Accuracy targets statistically weak | Medium | ≥ 300 cycles with independent tally, 95% CI |
| "Lifetime"/"trustworthy" overclaims | Medium | "Since install" wording |
| No "network entitlement" exists; privacy manifest missing | Low | Corrected |
| "Mitigated" statuses overstate progress | Low | Relabelled "Designed – unverified" |
| Docs live in an unrelated repository | Low | Raised with the Founder (I-17) |
| **Recommendation: CONDITIONAL GO** (R-01, D-1, spike before Phase 2) | — | Adopted as the consolidated recommendation |

## Disagreements recorded

1. **Hinge-life number** — Founder Rep for a factual substitute; PM and Compliance against any wear estimate. Resolution proposed: factual counts only. **Founder may decide.**
2. **Lean v1 cuts** — Founder Rep would also cut JSON import; PM would keep it until the device-backup restore behaviour is verified.
3. **Spike timing** — Independent Reviewer requires it before Phase 2; PM notes Phase 2 brand work (not screens) could run in parallel. Consolidated recommendation: **spike first**.
"""

DECISIONS_MD = """
Please reply with your decisions. Defaults shown are the team's recommendations.

| # | Decision needed | Team recommendation |
|---|---|---|
| **A** | **Approve Phase 1** (this report and the docs) | Approve |
| D-1 | Build FoldPulse despite existing fold-counter apps? | Yes — compete on trust (coverage), widgets and polish |
| D-2 | Count `inferred` (gap) events in headline totals? | No by default |
| D-3 | Minimum iOS 27.1, iPhone Duo-focused | Yes |
| D-4 | Non-Duo devices: manual-only mode with a notice | Yes |
| D-5 | Business model: free / paid up front / one-time unlock / tip jar | Decide before Phase 2 (no ads, no analytics SDKs) |
| D-6 | Adopt the lean v1 (MVP_SCOPE §4.1) | Yes |
| C-1 | Provide a Mac with Xcode 27.1+ and an iPhone Duo (or macOS CI + device) | Required before the spike |
| C-2 | Run the Phase 1b device spike before Phase 2 | Yes |
| I-17 | Move FoldPulse into its own repository | Yes, before Phase 3 |

## Next phase

If approved, the next step is the **Phase 1b validation spike** (with your device). After it, **Phase 2 — Brand, UI/UX & Design** produces the design system, the final icon, screen specifications, user flows, widget designs, mockups and `phase-02-design.pdf`. No application code is written until Phase 3 is approved.
"""

SOURCES_MD = """
Apple primary sources were retrieved directly from developer.apple.com on 9 November 2026. Press and App Store sources were consulted through search-engine results, because those sites are blocked by this environment's network policy, and are rated Medium confidence.

**Apple — primary**

- UIHingeInteraction — https://developer.apple.com/documentation/uikit/uihingeinteraction
- UIHinge / UIHinge.Status / angle — https://developer.apple.com/documentation/uikit/uihinge
- SwiftUI onHingeChange(isEnabled:_:) — https://developer.apple.com/documentation/swiftui/view/onhingechange(isenabled:_:)
- SwiftUI DeviceHinge — https://developer.apple.com/documentation/swiftui/devicehinge
- Preparing your app for iPhone Duo — https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo
- Tech Talk 111464 (iPhone Duo) — https://developer.apple.com/videos/play/tech-talks/111464/
- Developer Forums 847888 — https://developer.apple.com/forums/thread/847888
- Keeping a widget up to date — https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date
- WidgetFamily — https://developer.apple.com/documentation/widgetkit/widgetfamily
- Adding interactivity to widgets — https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities
- AppIntent.supportedModes — https://developer.apple.com/documentation/appintents/appintent/supportedmodes
- AppIntent.authenticationPolicy — https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy
- UIRequiredDeviceCapabilities — https://developer.apple.com/documentation/bundleresources/information-property-list/uirequireddevicecapabilities
- Privacy manifest required-reason APIs — https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons
- App privacy details — https://developer.apple.com/app-store/app-privacy-details/
- App Store Review Guidelines — https://developer.apple.com/app-store/review/guidelines/
- Core Motion CMMotionManager — https://developer.apple.com/documentation/coremotion/cmmotionmanager
- Apple Newsroom, iPhone Duo developer apps (Oct 2026) — https://www.apple.com/newsroom/2026/10/developers-bring-incredible-new-app-experiences-to-iphone-duo/

**Press and market — secondary**

- MacRumors iPhone Duo roundup — https://www.macrumors.com/roundup/iphone-duo/
- MacRumors, Opened-or-Closed automation (25 Oct 2026) — https://www.macrumors.com/2026/10/25/iphone-duo-automation-opened-or-closed/
- MacRumors, iOS 27.2 features — https://www.macrumors.com/2026/10/26/ios-27-2-features/
- 9to5Mac, iOS 27.2 Shortcuts features — https://9to5mac.com/2026/10/29/ios-27-2-gives-shortcuts-app-these-new-and-improved-features/
- 9to5Mac, non-optimised apps on iPhone Duo — https://9to5mac.com/2026/09/09/heres-how-iphone-duo-treats-apps-not-optimized-for-the-foldable-display/
- Digital Trends, iPhone Duo — https://www.digitaltrends.com/phones/iphone-fold-everything-we-know-about-apples-ultra-foldable/
- App Store, Duo Fold Counter — https://apps.apple.com/us/app/duo-fold-counter/id6827677447
- Similarweb, Duo Fold Counter ranking — https://www.similarweb.com/app/apple/6827677447/
- Foldometer — https://apps.apple.com/app/id6819503409
- foldcounter.com — https://foldcounter.com/
"""


def chapters():
    return [
        ("Executive summary & recommendation", EXEC + md(EXEC_MD)),
        ("Team, environment & method", md(TEAM_MD)),
        ("Technical feasibility", svg("fig1-capabilities.svg", "Figure 1 — Observation mechanisms by app state")
            + doc_body("TECHNICAL_FEASIBILITY.md").replace(
                "<p>Architecture diagram: see Phase 1 PDF, Figure 2.</p>",
                svg("fig2-architecture.svg", "Figure 2 — Proposed local-only architecture"))
.replace('<h2 id="7-persistence-and-architecture-direction">',
                svg("fig3-events.svg", "Figure 3 — Hinge status transitions and counting rules")
                + '<h2 id="7-persistence-and-architecture-direction">')),
        ("Product requirements", doc_body("PRD.md")),
        ("MVP scope", doc_body("MVP_SCOPE.md")),
        ("Initial visual direction (temporary concept)", md(VISUAL_MD)
            + svg("fig4-visual-direction.svg", "Figure 4 — Colour, type and icon concepts")
            + svg("fig5-concepts.svg", "Figure 5 — Dashboard and widget concept sketches")
            + md(VISUAL_MD2)),
        ("Privacy & security review", doc_body("PRIVACY_REVIEW.md").split('<h2 id="sources">')[0]),
        ("Performance & battery review", md(PERF_MD)),
        ("Agent reviews, issues & risks", md(REVIEWS_MD) + "<h2>Risk register &amp; issue log</h2>" + doc_body("RISK_REGISTER.md")),
        ("Roadmap", doc_body("ROADMAP.md")),
        ("Decisions requested & next steps", md(DECISIONS_MD)),
        ("References", md(SOURCES_MD)),
    ]


CSS = (HERE / "style.css").read_text()


def cover_html():
    logo = (ASSETS / "fig4-visual-direction.svg").read_text()
    m = re.search(r'<g transform="translate\(470,240\)">(.*?)</g>', logo, re.S)
    icon = ('<svg viewBox="0 0 110 110" width="120" height="120"><defs>'
            '<linearGradient id="g1" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#14284A"/><stop offset="1" stop-color="#070F1F"/></linearGradient>'
            '</defs>' + re.sub(r'<text.*?</text>', '', m.group(1), flags=re.S) + '</svg>')
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>{CSS}</style></head>
<body class="cover"><div class="cover-inner">
<div class="cover-icon">{icon}</div>
<div class="brand">FoldPulse</div>
<div class="tagline">Every Fold. Every Beat.</div>
<div class="phase">Phase 1 · Product Research &amp; Feasibility</div>
<h1 class="cover-title">Feasibility Report &amp; Recommendation</h1>
<table class="meta">
<tr><td>Version</td><td>{VERSION}</td></tr>
<tr><td>Date</td><td>{DATE}</td></tr>
<tr><td>Prepared for</td><td>Founder &amp; Product Owner</td></tr>
<tr><td>Prepared by</td><td>FoldPulse product team (12 agent roles)</td></tr>
<tr><td>Status</td><td>Submitted for Founder approval</td></tr>
<tr><td>Recommendation</td><td><b>CONDITIONAL GO</b></td></tr>
</table>
<div class="cover-note">Confidential — prepared for the FoldPulse Founder. Icon shown is a temporary concept.</div>
</div></body></html>"""


def body_html(page_map):
    chs = chapters()
    toc = []
    for i, (title, _) in enumerate(chs, 1):
        pg = page_map.get(i, "")
        toc.append(f'<li><span class="n">{i}</span><span class="t">{html.escape(title)}</span><span class="dots"></span><span class="p">{pg}</span></li>')
    parts = [f'<section class="toc"><h1 class="toch">Contents</h1><ol>{"".join(toc)}</ol></section>']
    for i, (title, content) in enumerate(chs, 1):
        parts.append(f'<section class="chapter"><h1 class="chap"><span class="num">{i}</span> {html.escape(title)}<span class="marker">§§CH{i}§§</span></h1>{content}</section>')
    return nowrap_ids(f'<!doctype html><html><head><meta charset="utf-8"><style>{CSS}</style></head><body>{"".join(parts)}</body></html>')


def render(html_path, pdf_path, header):
    subprocess.run(["node", str(HERE / "render.js"), str(html_path), str(pdf_path), json.dumps(header)], check=True)


def find_pages(pdf_path, n):
    reader = PdfReader(str(pdf_path))
    found = {}
    for idx, page in enumerate(reader.pages):
        text = page.extract_text() or ""
        for i in range(1, n + 1):
            if i not in found and f"§§CH{i}§§" in text:
                found[i] = idx + 1  # body page number as printed in the footer (cover unnumbered)
    return found


def main():
    n = len(chapters())
    cover_p, body_p = BUILD / "cover.html", BUILD / "body.html"
    cover_p.write_text(cover_html())
    render(cover_p, BUILD / "cover.pdf", None)
    pages = {}
    for _ in range(2):
        body_p.write_text(body_html(pages))
        render(body_p, BUILD / "body.pdf", {"title": "FoldPulse · Phase 1 Feasibility Report", "version": f"v{VERSION} · {DATE}"})
        pages = find_pages(BUILD / "body.pdf", n)
    assert len(pages) == n, f"chapter markers missing: {pages}"
    w = PdfWriter()
    for f in (BUILD / "cover.pdf", BUILD / "body.pdf"):
        for p in PdfReader(str(f)).pages:
            w.add_page(p)
    w.add_metadata({"/Title": "FoldPulse — Phase 1 Feasibility Report", "/Author": "FoldPulse product team",
                    "/Subject": "Product research and feasibility", "/Keywords": "FoldPulse, iPhone Duo, feasibility"})
    with open(OUT, "wb") as fh:
        w.write(fh)
    print(f"wrote {OUT} ({len(PdfReader(str(OUT)).pages)} pages); chapter pages: {pages}")


if __name__ == "__main__":
    main()
