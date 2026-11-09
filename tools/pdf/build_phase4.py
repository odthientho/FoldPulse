#!/usr/bin/env python3
"""Build docs/phase-04-development.pdf (Phase 4 — MVP Development).

Inputs: docs/PHASE4_SUMMARY.md, DEVELOPMENT_LOG.md, PHASE4_REVIEWS.md,
PHASE4_NEXT.md, ARCHITECTURE.md (Phase 4 section), real app screenshots in
docs/screenshots/phase4/ (exported by CI). Usage: python3 tools/pdf/build_phase4.py
"""
import html
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import build_phase1 as base  # noqa: E402
import build_phase2 as p2  # noqa: E402
import build_phase3 as p3  # noqa: E402
from pypdf import PdfReader, PdfWriter  # noqa: E402

ROOT, DOCS, BUILD = base.ROOT, base.DOCS, base.BUILD
SHOTS = DOCS / "screenshots" / "phase4"
OUT = DOCS / "phase-04-development.pdf"
VERSION, DATE = "1.0", "9 November 2026"


def screenshots():
    files = sorted(SHOTS.glob("*.png"))
    if not files:
        return base.md("_Screenshots were not available for this build._")
    captions = {"01-today": "Today (sample week)", "02-record-sheet": "Record sheet with Undo", "03-history": "History",
                "04-insights": "Insights · week", "05-settings": "Settings", "06-milestone": "Milestone celebration (once)"}
    cells = "".join(
        f'<div class="gcell"><img src="file://{f}"><div class="gcap">{html.escape(captions.get(f.stem, f.stem))}</div></div>'
        for f in files)
    return (base.md("Real screenshots from the **running app**, captured by the UI test `ScreenshotTests` in CI. "
                    "Simulator iPhone 17 Pro, iOS 26.5 SDK, debug build with the sample week. They are not mockups. "
                    "The \"Waiting for the hinge\" card is expected: the simulator has no hinge. "
                    "These screenshots revealed one layout bug, truncated text in the Record sheet at its medium height. "
                    "It was fixed right after capture: the sheet now scrolls and the text wraps.")
            + f'<div class="gallery c3">{cells}</div>')


def chapters():
    return [
        ("Executive summary & recommendation",
         '<div class="decision"><div class="label">Phase 4 recommendation</div><div class="verdict">APPROVE</div>'
         '<p>The MVP is implemented and CI is green. Two open items need your Mac and iPhone Duo at the start of Phase 5.</p></div>'
         + base.md((DOCS / "PHASE4_SUMMARY.md").read_text())),
        ("The app, running", screenshots()),
        ("Development log", base.doc_body("DEVELOPMENT_LOG.md")),
        ("Agent reviews & resolutions", base.doc_body("PHASE4_REVIEWS.md")),
        ("Architecture (updated)", base.doc_body("ARCHITECTURE.md")),
        ("Decisions requested & next steps", base.md((DOCS / "PHASE4_NEXT.md").read_text())),
    ]


def cover_html():
    return p2.cover_html().replace("Phase 2 · Brand, UI/UX &amp; Design", "Phase 4 · MVP Development") \
        .replace("Design Report &amp; Specifications", "Development Report") \
        .replace("<b>APPROVE</b> (open items R-28, I-24 recorded)", "<b>APPROVE</b> (open items P4-1, P4-2)") \
        .replace("All numbers in mockups are sample data.", "Screenshots show sample data; build results are from CI.")


def body_html(page_map):
    chs = chapters()
    toc = "".join(
        f'<li><span class="n">{i}</span><span class="t">{html.escape(t)}</span><span class="dots"></span><span class="p">{page_map.get(i, "")}</span></li>'
        for i, (t, _) in enumerate(chs, 1))
    parts = [f'<section class="toc"><h1 class="toch">Contents</h1><ol>{toc}</ol></section>']
    for i, (t, c) in enumerate(chs, 1):
        parts.append(f'<section class="chapter"><h1 class="chap"><span class="num">{i}</span> {html.escape(t)}<span class="marker">§§CH{i}§§</span></h1>{c}</section>')
    css = base.CSS + p3.EXTRA_CSS + ".gallery.c3 .gcell img { max-height: 120mm; width: auto; max-width: 100%; }"
    return base.nowrap_ids(f'<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head><body>{"".join(parts)}</body></html>')


def main():
    n = len(chapters())
    cp, bp = BUILD / "p4-cover.html", BUILD / "p4-body.html"
    cp.write_text(cover_html())
    base.render(cp, BUILD / "p4-cover.pdf", None)
    pages = {}
    for _ in range(2):
        bp.write_text(body_html(pages))
        base.render(bp, BUILD / "p4-body.pdf", {"title": "FoldPulse · Phase 4 Development Report", "version": f"v{VERSION} · {DATE}"})
        pages = base.find_pages(BUILD / "p4-body.pdf", n)
    assert len(pages) == n, f"chapter markers missing: {pages}"
    w = PdfWriter()
    for f in (BUILD / "p4-cover.pdf", BUILD / "p4-body.pdf"):
        for p in PdfReader(str(f)).pages:
            w.add_page(p)
    w.add_metadata({"/Title": "FoldPulse — Phase 4 Development Report", "/Author": "FoldPulse product team",
                    "/Subject": "MVP development", "/Keywords": "FoldPulse, iPhone Duo, MVP"})
    with open(OUT, "wb") as fh:
        w.write(fh)
    print(f"wrote {OUT} ({len(PdfReader(str(OUT)).pages)} pages); chapter pages: {pages}")


if __name__ == "__main__":
    main()
