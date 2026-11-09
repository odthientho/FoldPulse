#!/usr/bin/env python3
"""Phase 3 architecture diagrams (SVG)."""
import html, pathlib
OUT = pathlib.Path(__file__).resolve().parent
NAVY, BLUE, CYAN, GRAY, LINE, SOFT = "#0B1B33", "#2F7BFF", "#5CC8FF", "#55606E", "#C9D3E3", "#F7F8FA"

def box(x, y, w, h, title, sub="", fill="#FFFFFF", fg=NAVY, stroke=LINE, rx=10):
    t = [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="1.4"/>',
         f'<text x="{x + w/2}" y="{y + (h/2 if not sub else h/2 - 5)}" text-anchor="middle" font-size="12.5" font-weight="700" fill="{fg}">{html.escape(title)}</text>']
    for i, line in enumerate(sub.split("\n") if sub else []):
        t.append(f'<text x="{x + w/2}" y="{y + h/2 + 11 + i*13}" text-anchor="middle" font-size="10.5" fill="{fg if fill not in ("#FFFFFF", SOFT) else GRAY}">{html.escape(line)}</text>')
    return "".join(t)

def arrow(x1, y1, x2, y2, dash=False, label=""):
    d = ' stroke-dasharray="5 4"' if dash else ""
    s = f'<path d="M{x1},{y1} L{x2},{y2}" stroke="{GRAY}" stroke-width="1.5" fill="none" marker-end="url(#a)"{d}/>'
    if label:
        s += f'<text x="{(x1+x2)/2 + 5}" y="{(y1+y2)/2 - 4}" font-size="10" fill="{GRAY}" stroke="{SOFT}" stroke-width="4" paint-order="stroke">{html.escape(label)}</text>'
    return s

def svg(name, w, h, title, body, note=""):
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" font-family="Inter, sans-serif">',
             f'<defs><marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="{GRAY}"/></marker></defs>',
             f'<rect width="{w}" height="{h}" rx="14" fill="{SOFT}"/>',
             f'<text x="24" y="34" font-size="17" font-weight="700" fill="{NAVY}">{html.escape(title)}</text>', body]
    if note:
        parts.append(f'<text x="24" y="{h-14}" font-size="11" fill="{GRAY}">{html.escape(note)}</text>')
    parts.append("</svg>")
    (OUT / f"{name}.svg").write_text("".join(parts))

# 1. Module layers
b = []
b.append(f'<rect x="20" y="52" width="600" height="300" rx="12" fill="none" stroke="{BLUE}" stroke-dasharray="4 4"/><text x="34" y="70" font-size="11" font-weight="700" fill="{BLUE}">FoldPulse app target</text>')
b.append(box(40, 82, 560, 44, "Features", "Today · History · Insights · Settings  (SwiftUI)"))
b.append(box(40, 142, 270, 44, "DesignSystem", "Typography + components"))
b.append(box(330, 142, 270, 44, "AppModel  (@MainActor, @Observable)", "state + orchestration", fill="#EAF1FF", stroke="#8DB6FF"))
b.append(box(40, 202, 270, 54, "EventStore  (@ModelActor)", "single writer · SwiftData SchemaV1", fill=NAVY, fg="#FFFFFF", stroke=NAVY))
b.append(box(330, 202, 270, 54, "SnapshotService  (@MainActor)", "WidgetSnapshot.json + reload policy"))
b.append(box(40, 272, 560, 60, "Phase 4: HingeObserver · App Intents · Event pipeline · Export", "slots reserved, not yet implemented", fill="#FFFFFF", stroke=GRAY))
b.append(f'<rect x="640" y="52" width="300" height="160" rx="12" fill="none" stroke="{BLUE}" stroke-dasharray="4 4"/><text x="654" y="70" font-size="11" font-weight="700" fill="{BLUE}">FoldPulseWidgets extension</text>')
b.append(box(660, 82, 260, 54, "TodayWidget", "small · circular · rectangular"))
b.append(box(660, 146, 260, 50, "SnapshotProvider", "timeline: now + next midnight"))
b.append(box(640, 232, 300, 54, "Shared (both targets)", "AppGroup · SnapshotFile · Tokens · PulseLine", fill="#EAF1FF", stroke="#8DB6FF"))
b.append(box(20, 372, 920, 62, "FoldPulseCore  (Swift package · pure Swift · tested on Linux + macOS)",
             "FoldEvent · EventType · DetectionSource · LocalDay · Statistics · Milestones · WidgetSnapshot", fill=BLUE, fg="#FFFFFF", stroke=BLUE))
b.append(arrow(320, 352, 320, 370)); b.append(arrow(790, 286, 790, 370)); b.append(arrow(790, 212, 790, 230))
b.append(arrow(600, 229, 638, 255, label="writes JSON"))
svg("arch-modules", 960, 470, "Module structure and dependencies", "".join(b), "Arrows point to dependencies. The widget never links app code or opens the database.")

# 2. Data flow
b = []
srcs = [("Hinge observer", "foreground · Phase 4"), ("App Intents", "Shortcuts · background · Phase 4"), ("Record sheet", "manual · Phase 4")]
for i, (t, s) in enumerate(srcs):
    b.append(box(24, 66 + i*70, 190, 52, t, s, stroke=GRAY))
    b.append(arrow(214, 92 + i*70, 262, 160))
b.append(box(264, 130, 190, 60, "Event pipeline", "debounce · dedupe · gaps\n(FoldPulseCore, Phase 4)", fill="#EAF1FF", stroke="#8DB6FF"))
b.append(arrow(454, 160, 500, 160))
b.append(box(502, 130, 190, 60, "EventStore", "@ModelActor · SwiftData", fill=NAVY, fg="#FFFFFF", stroke=NAVY))
b.append(box(502, 240, 190, 56, "FoldPulse.store", "App Group · protected", stroke=GRAY))
b.append(arrow(597, 190, 597, 238))
b.append(arrow(692, 160, 738, 160))
b.append(box(740, 130, 196, 60, "AppModel.reload()", "@MainActor", fill="#EAF1FF", stroke="#8DB6FF"))
b.append(arrow(838, 190, 838, 238))
b.append(box(740, 240, 196, 50, "Features", "stats via FoldPulseCore"))
b.append(arrow(740, 175, 700, 330, label=""))
b.append(box(502, 316, 196, 50, "SnapshotService", "write JSON · throttle reload"))
b.append(arrow(502, 341, 456, 341))
b.append(box(264, 316, 190, 50, "WidgetSnapshot.json", "App Group"))
b.append(arrow(264, 341, 216, 341))
b.append(box(24, 316, 190, 50, "TodayWidget", "WidgetKit timeline"))
svg("arch-dataflow", 960, 400, "Data flow (Phase 3 implemented: store → model → features & widget)", "".join(b),
    "Grey boxes on the left are Phase 4 sources; everything from EventStore onward exists and is tested.")

# 3. Schema
rows = [("id", "UUID", "unique"), ("typeRaw", "String", "fold | unfold"), ("sourceRaw", "String", "hinge | shortcut | manual | inferred"),
        ("timestamp", "Date", "indexed · UTC"), ("timeZoneID", "String", "IANA zone at capture"), ("localDay", "String", "indexed · YYYY-MM-DD"),
        ("note", "String?", "≤ 500 chars"), ("createdAt", "Date", ""), ("updatedAt", "Date", "newer wins on import"), ("isEdited", "Bool", ""),
        ("deletedAt", "Date?", "tombstone"), ("duplicateOf", "UUID?", "merged by dedupe"), ("inferredIntervalStart/End", "Date?", "gap window")]
b = [f'<rect x="24" y="56" width="560" height="{34 + 24*len(rows)}" rx="10" fill="#FFFFFF" stroke="{LINE}"/>',
     f'<rect x="24" y="56" width="560" height="30" rx="10" fill="{NAVY}"/><text x="40" y="76" font-size="13" font-weight="700" fill="#FFFFFF">StoredEvent  (SchemaV1 1.0.0)</text>']
for i, (f, t, n) in enumerate(rows):
    y = 104 + i*24
    b.append(f'<text x="40" y="{y}" font-size="11.5" font-weight="600" fill="{NAVY}" font-family="DejaVu Sans Mono, monospace">{f}</text>'
             f'<text x="250" y="{y}" font-size="11.5" fill="{BLUE}" font-family="DejaVu Sans Mono, monospace">{t}</text>'
             f'<text x="340" y="{y}" font-size="11" fill="{GRAY}">{html.escape(n)}</text>')
b.append(box(620, 56, 316, 90, "WidgetSnapshot.json  (v1)", "schemaVersion · generatedAt · localDay\ntodayFolds · todayUnfolds · totalSinceInstall\ndailyAverage7d · nextMilestone"))
b.append(box(620, 166, 316, 70, "Computed, never stored", "totals · series · averages · coverage\nbusiest day · milestones"))
b.append(box(620, 256, 316, 70, "Migration plan", "VersionedSchema + SchemaMigrationPlan\nV1 now; V2+ add stages with fixture tests"))
svg("arch-schema", 960, 440, "Persistence schema", "".join(b))

# 4. CI pipeline
b = []
b.append(box(24, 70, 150, 50, "git push main", "", fill=NAVY, fg="#FFFFFF", stroke=NAVY))
b.append(arrow(174, 95, 214, 70)); b.append(arrow(174, 95, 214, 170))
b.append(box(216, 50, 300, 50, "Linux · swift:6.1 container", "swift test FoldPulseCore"))
b.append(box(216, 140, 150, 60, "macOS runner", "newest Xcode"))
steps = [("Core tests", "swift test"), ("XcodeGen", "generate project"), ("xcodebuild test", "unit + UI tests\non a simulator")]
for i, (t, s) in enumerate(steps):
    x = 400 + i*180
    b.append(box(x, 140, 160, 60, t, s, fill="#EAF1FF", stroke="#8DB6FF"))
    b.append(arrow(x - 34 if i == 0 else x - 20, 170, x - 2, 170))
b.append(box(520, 230, 420, 46, "If SDK < 27.1: compile check, lowered target (warned)", "", fill="#FFF6E5", stroke="#A15C00"))
svg("arch-ci", 960, 300, "Continuous integration", "".join(b), "Every push builds and tests independently of this workspace (which cannot run Xcode).")
print("diagrams written")
