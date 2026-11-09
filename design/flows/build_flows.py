#!/usr/bin/env python3
"""Generate FoldPulse user-flow diagrams (SVG) from simple node/edge lists."""
import html
import pathlib

OUT = pathlib.Path(__file__).resolve().parent
COL = {"screen": ("#FFFFFF", "#0B1B33", "#2F7BFF"), "action": ("#2F7BFF", "#FFFFFF", "#2F7BFF"),
       "system": ("#EAF1FF", "#0B1B33", "#8DB6FF"), "decision": ("#FFF6E5", "#0B1B33", "#A15C00"),
       "end": ("#0B1B33", "#FFFFFF", "#0B1B33"), "bad": ("#FDECEA", "#0B1B33", "#C2362B")}


def node(x, y, w, h, text, kind):
    fill, fg, stroke = COL[kind]
    lines = text.split("\n")
    rx = 22 if kind in ("action", "end") else 10
    out = [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="1.6"/>']
    y0 = y + h / 2 - (len(lines) - 1) * 8 + 4
    for i, ln in enumerate(lines):
        weight = 700 if i == 0 else 400
        size = 13 if i == 0 else 11
        out.append(f'<text x="{x + w / 2}" y="{y0 + i * 16}" text-anchor="middle" font-size="{size}" font-weight="{weight}" fill="{fg}">{html.escape(ln)}</text>')
    return "".join(out)


def build(name, title, w, h, nodes, edges, note=""):
    pos = {}
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" font-family="Inter, sans-serif">',
             '<defs><marker id="ar" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#55606E"/></marker></defs>',
             f'<rect width="{w}" height="{h}" rx="14" fill="#F7F8FA"/>',
             f'<text x="24" y="34" font-size="17" font-weight="700" fill="#0B1B33">{html.escape(title)}</text>']
    for nid, x, y, nw, nh, text, kind in nodes:
        pos[nid] = (x, y, nw, nh)
    for a, b, label, *opt in edges:
        ax, ay, aw, ah = pos[a]
        bx, by, bw, bh = pos[b]
        # pick anchor sides
        if opt and "h" in opt:   # side-to-side with an elbow at mid x
            x1, y1 = (ax + aw, ay + ah / 2) if bx > ax else (ax, ay + ah / 2)
            x2, y2 = (bx, by + bh / 2) if bx > ax else (bx + bw, by + bh / 2)
            mx = (x1 + x2) / 2
            d = f"M{x1},{y1} L{mx},{y1} L{mx},{y2} L{x2},{y2}"
        elif abs((ay + ah / 2) - (by + bh / 2)) < 30:   # same row → horizontal
            x1, y1 = (ax + aw, ay + ah / 2) if bx > ax else (ax, ay + ah / 2)
            x2, y2 = (bx, by + bh / 2) if bx > ax else (bx + bw, by + bh / 2)
            d = f"M{x1},{y1} L{x2},{y2}"
        else:
            x1, y1 = ax + aw / 2, (ay + ah if by > ay else ay)
            x2, y2 = bx + bw / 2, (by if by > ay else by + bh)
            my = (y1 + y2) / 2
            d = f"M{x1},{y1} L{x1},{my} L{x2},{my} L{x2},{y2}"
        dash = ' stroke-dasharray="5 4"' if opt and "dash" in opt else ""
        parts.append(f'<path d="{d}" fill="none" stroke="#55606E" stroke-width="1.5"{dash} marker-end="url(#ar)"/>')
        if label:
            lx, ly = (x1 + x2) / 2, (y1 + y2) / 2
            parts.append(f'<text x="{lx + 4}" y="{ly - 5}" font-size="10.5" fill="#55606E" stroke="#F7F8FA" stroke-width="4" paint-order="stroke">{html.escape(label)}</text>')
    for nid, x, y, nw, nh, text, kind in nodes:
        parts.append(node(x, y, nw, nh, text, kind))
    if note:
        parts.append(f'<text x="24" y="{h - 16}" font-size="11" fill="#55606E">{html.escape(note)}</text>')
    legend = [("screen", "Screen"), ("action", "User action"), ("system", "System / iOS"), ("decision", "Decision"), ("bad", "Problem path")]
    lx = w - 520
    for i, (k, lab) in enumerate(legend):
        f, _, s = COL[k]
        parts.append(f'<rect x="{lx + i * 104}" y="20" width="14" height="14" rx="3" fill="{f}" stroke="{s}"/><text x="{lx + i * 104 + 20}" y="31" font-size="11" fill="#55606E">{lab}</text>')
    parts.append("</svg>")
    (OUT / f"{name}.svg").write_text("".join(parts))


# Navigation map
build("flow-nav", "Navigation map", 980, 440, [
    ("ob", 30, 70, 150, 54, "Onboarding\n3 pages, first launch", "screen"),
    ("today", 230, 70, 150, 54, "Today\ndashboard", "screen"),
    ("hist", 430, 70, 150, 54, "History", "screen"),
    ("ins", 610, 70, 140, 54, "Insights", "screen"),
    ("set", 790, 70, 170, 54, "Settings", "screen"),
    ("ms", 30, 200, 120, 50, "Milestone sheet\n(once)", "screen"),
    ("rec", 165, 200, 130, 50, "Record sheet\n(+ / Record Fold)", "screen"),
    ("cov", 310, 200, 130, 50, "Coverage detail", "screen"),
    ("edit", 455, 200, 130, 50, "Event detail\n/ Edit sheet", "screen"),
    ("setup", 290, 320, 170, 50, "Background counting\nsetup + self-test", "screen"),
    ("exp", 610, 200, 100, 50, "Export", "screen"),
    ("imp", 725, 200, 100, 50, "Import\n(v1.1)", "system"),
    ("reset", 845, 200, 120, 50, "Reset (2-step)", "bad"),
], [
    ("ob", "today", ""), ("today", "ms", "", "dash"), ("today", "rec", ""), ("today", "cov", ""),
    ("cov", "setup", ""), ("hist", "edit", ""), ("set", "exp", ""), ("set", "imp", ""), ("set", "reset", ""),
], note="Tabs: Today · History · Insights · Settings (system TabView). Setup is also reachable from Settings. Dashed = shown automatically.")

# Onboarding + background setup
build("flow-setup", "First launch and optional background counting", 980, 520, [
    ("launch", 30, 70, 130, 50, "First launch", "end"),
    ("ob", 200, 70, 160, 50, "Onboarding 1–3\nhonest counting model", "screen"),
    ("today", 400, 70, 150, 50, "Today (empty)\ncounts while open", "screen"),
    ("card", 590, 70, 170, 50, "Taps 'Count in the\nbackground' (optional)", "action"),
    ("ver", 800, 70, 150, 50, "iOS ≥ 27.2?", "decision"),
    ("upd", 800, 180, 150, 54, "Update notice\nkeep foreground mode", "bad"),
    ("steps", 590, 180, 170, 54, "4 illustrated steps\nOpen Shortcuts", "screen"),
    ("sc", 580, 290, 200, 54, "User creates 2 automations\nin Shortcuts", "system"),
    ("test", 330, 290, 170, 54, "Self-test: close,\nthen open the phone", "action"),
    ("ok", 330, 400, 170, 50, "Both runs seen\nwithin 60 s?", "decision"),
    ("pass", 100, 400, 170, 50, "Working ✓\ncoverage tracked", "end"),
    ("fail", 590, 400, 200, 54, "Names failing step:\nnot found / prompt / no run", "bad"),
], [
    ("launch", "ob", ""), ("ob", "today", ""), ("today", "card", ""), ("card", "ver", ""), ("ver", "upd", "no"),
    ("ver", "steps", "yes"), ("steps", "sc", ""), ("sc", "test", "back"), ("test", "ok", ""),
    ("ok", "pass", "yes"), ("ok", "fail", "no"),
], note="Background counting is never reported as on until the self-test passes (decision C-2r; risk R-02).")

# Record & correct
build("flow-record", "Recording and correcting events", 980, 420, [
    ("fold", 30, 70, 170, 54, "User folds phone\n(app open)", "action"),
    ("auto", 240, 70, 170, 54, "Automatic event\nhero rolls, pulse beats", "system"),
    ("bgf", 30, 180, 170, 54, "User folds phone\n(app closed)", "action"),
    ("sc", 240, 180, 170, 54, "Shortcut event\n(if set up)", "system"),
    ("dd", 450, 125, 170, 54, "De-duplicate ±10 s\nreconcile gaps", "system"),
    ("man", 30, 300, 170, 54, "Record sheet\nRecord Fold", "action"),
    ("undo", 240, 300, 170, 54, "Toast with Undo (5 s)", "screen"),
    ("hist", 660, 125, 140, 54, "History", "screen"),
    ("edit", 840, 70, 120, 54, "Edit\n→ 'edited'", "action"),
    ("del", 840, 180, 120, 54, "Delete\n(confirm)", "bad"),
    ("upd", 660, 300, 300, 54, "Totals, coverage, widgets update\nmilestone checked (fires once)", "end"),
], [
    ("fold", "auto", ""), ("bgf", "sc", ""), ("auto", "dd", "", "h"), ("sc", "dd", "", "h"), ("man", "undo", ""),
    ("undo", "dd", "", "h"), ("dd", "hist", ""), ("hist", "edit", "", "h"), ("hist", "del", "", "h"), ("dd", "upd", ""),
], note="Manual events go through the same de-duplication, so a manual tap right after an automatic fold isn't double counted.")
print("flows written")
