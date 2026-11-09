#!/usr/bin/env python3
"""Build docs/phase-03-architecture.pdf (Phase 3 — Architecture & Foundation).

Chapters come from docs/ARCHITECTURE.md, DATABASE_DESIGN.md, DECISIONS.md,
BUILD_VERIFICATION.md (real CI results) and PHASE3_REVIEWS.md, plus the
diagrams in design/architecture/. Usage: python3 tools/pdf/build_phase3.py
"""
import html
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import build_phase1 as base  # noqa: E402
import build_phase2 as p2  # noqa: E402
from pypdf import PdfReader, PdfWriter  # noqa: E402

ROOT = base.ROOT
DOCS, BUILD = base.DOCS, base.BUILD
ARCH = ROOT / "design" / "architecture"
OUT = DOCS / "phase-03-architecture.pdf"
VERSION, DATE = "1.0", "9 November 2026"


def fig(name, caption):
    return p2.img(ARCH / f"{name}.svg", caption)


def code_listing(path, start_marker=None, max_lines=60):
    lines = (ROOT / path).read_text().splitlines()
    if start_marker:
        idx = next((i for i, l in enumerate(lines) if start_marker in l), 0)
        lines = lines[idx:]
    body = html.escape("\n".join(lines[:max_lines]))
    return f'<p class="lst">{html.escape(path)}</p><pre class="code">{body}</pre>'


def tree():
    import subprocess
    out = subprocess.run(["git", "-C", str(ROOT), "ls-files"], capture_output=True, text=True).stdout.splitlines()
    keep = [f for f in out if f.split("/")[0] in ("FoldPulse", "FoldPulseWidgets", "FoldPulseTests", "FoldPulseUITests", "Shared", "Packages", "scripts", ".github")
            and not f.endswith(".png") and "Contents.json" not in f] + ["project.yml"]
    return '<pre class="code small">' + html.escape("\n".join(sorted(keep))) + "</pre>"


def chapters():
    return [
        ("Executive summary & recommendation",
         '<div class="decision"><div class="label">Phase 3 recommendation</div><div class="verdict">APPROVE</div>'
         '<p>The foundation builds and all 43 automated tests pass in CI. The High and Medium review findings are fixed.</p></div>'
         + base.md((DOCS / "PHASE3_SUMMARY.md").read_text())),
        ("Architecture", fig("arch-modules", "Figure 1 — Module structure and dependencies")
         + fig("arch-dataflow", "Figure 2 — Data flow") + base.doc_body("ARCHITECTURE.md")),
        ("Database design", fig("arch-schema", "Figure 3 — Persistence schema") + base.doc_body("DATABASE_DESIGN.md")),
        ("Project foundation: files & key code",
         base.md("Every file below is in the repository (`odthientho/FoldPulse`, branch `main`). The Xcode project is generated from `project.yml` by XcodeGen.")
         + tree()
         + code_listing("FoldPulse/Core/Persistence/EventStore.swift", "@ModelActor", 70)
         + code_listing("Packages/FoldPulseCore/Sources/FoldPulseCore/Statistics.swift", "public static func dailyAverage", 12)),
        ("Build & test verification", fig("arch-ci", "Figure 4 — Continuous integration") + base.doc_body("BUILD_VERIFICATION.md")),
        ("Agent reviews & resolutions", base.doc_body("PHASE3_REVIEWS.md")),
        ("Technical decisions", base.doc_body("DECISIONS.md")),
        ("Decisions requested & next steps", base.md((DOCS / "PHASE3_NEXT.md").read_text())),
    ]


EXTRA_CSS = p2.EXTRA_CSS + """
pre.code { font-family: 'DejaVu Sans Mono', monospace; font-size: 7.1pt; line-height: 1.35; background: #F4F6FA;
  border: 0.5pt solid #C9D3E3; border-radius: 2mm; padding: 3mm; white-space: pre-wrap; word-break: break-word; }
pre.code.small { font-size: 6.8pt; column-count: 2; column-gap: 6mm; }
p.lst { font-size: 8pt; color: #5B6472; margin: 4mm 0 1mm; font-weight: 600; }
"""


def cover_html():
    return p2.cover_html().replace("Phase 2 · Brand, UI/UX &amp; Design", "Phase 3 · Architecture &amp; Project Foundation") \
        .replace("Design Report &amp; Specifications", "Architecture Report &amp; Build Verification") \
        .replace("<b>APPROVE</b> (open items R-28, I-24 recorded)", "<b>APPROVE</b> (see open items)") \
        .replace("All numbers in mockups are sample data.", "Build results are from the project's CI.")


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
    cp, bp = BUILD / "p3-cover.html", BUILD / "p3-body.html"
    cp.write_text(cover_html())
    base.render(cp, BUILD / "p3-cover.pdf", None)
    pages = {}
    for _ in range(2):
        bp.write_text(body_html(pages))
        base.render(bp, BUILD / "p3-body.pdf", {"title": "FoldPulse · Phase 3 Architecture Report", "version": f"v{VERSION} · {DATE}"})
        pages = base.find_pages(BUILD / "p3-body.pdf", n)
    assert len(pages) == n, f"chapter markers missing: {pages}"
    w = PdfWriter()
    for f in (BUILD / "p3-cover.pdf", BUILD / "p3-body.pdf"):
        for p in PdfReader(str(f)).pages:
            w.add_page(p)
    w.add_metadata({"/Title": "FoldPulse — Phase 3 Architecture Report", "/Author": "FoldPulse product team",
                    "/Subject": "Architecture and project foundation", "/Keywords": "FoldPulse, iPhone Duo, architecture"})
    with open(OUT, "wb") as fh:
        w.write(fh)
    print(f"wrote {OUT} ({len(PdfReader(str(OUT)).pages)} pages); chapter pages: {pages}")


if __name__ == "__main__":
    main()
