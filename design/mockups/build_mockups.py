#!/usr/bin/env python3
"""Generate FoldPulse Phase 2 screen mockups (HTML) and render them to PNG.

Every frame in mockups.html has an id. render.js screenshots each frame to
design/mockups/png/<id>.png. All numbers are SAMPLE DATA for illustration.

Usage: python3 design/mockups/build_mockups.py
"""
import pathlib
import subprocess

HERE = pathlib.Path(__file__).resolve().parent
PNG = HERE / "png"
PNG.mkdir(exist_ok=True)

# ------------------------------------------------------------------ glyphs
PULSE = '<svg class="pulse" viewBox="0 0 120 24"><path d="M0 12 H38 L46 3 L56 21 L64 8 L70 12 H120" /></svg>'
ICON = {
    "today": '<svg viewBox="0 0 24 24"><path d="M2 12h5l2-5 4 10 2-5h7"/></svg>',
    "history": '<svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="16" rx="3"/><path d="M7 9h10M7 13h10M7 17h6"/></svg>',
    "insights": '<svg viewBox="0 0 24 24"><path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/></svg>',
    "settings": '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="3.2"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1 7 17M17 7l2.1-2.1"/></svg>',
    "auto": '<svg viewBox="0 0 24 24"><path d="M2 12h5l2-5 4 10 2-5h7"/></svg>',
    "shortcut": '<svg viewBox="0 0 24 24"><path d="M12 3 21 8 12 13 3 8z"/><path d="M3 12l9 5 9-5M3 16l9 5 9-5"/></svg>',
    "manual": '<svg viewBox="0 0 24 24"><path d="M9 11V5a2 2 0 0 1 4 0v6M13 10a2 2 0 0 1 4 0v2M17 11a2 2 0 0 1 4 0v4a7 7 0 0 1-7 7h-1a7 7 0 0 1-6-3l-3-5a2 2 0 0 1 3-2l2 2"/></svg>',
    "gap": '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" stroke-dasharray="3 3"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .9-1 1.6M12 17h.01"/></svg>',
    "chev": '<svg viewBox="0 0 24 24"><path d="M9 6l6 6-6 6"/></svg>',
    "plus": '<svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>',
    "check": '<svg viewBox="0 0 24 24"><path d="M5 12l5 5 9-10"/></svg>',
    "lock": '<svg viewBox="0 0 24 24"><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>',
    "share": '<svg viewBox="0 0 24 24"><path d="M12 3v12M7 8l5-5 5 5M5 13v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6"/></svg>',
    "warn": '<svg viewBox="0 0 24 24"><path d="M12 3 2 20h20z"/><path d="M12 10v4M12 17h.01"/></svg>',
}
SRC = {"auto": ("Automatic", "auto"), "shortcut": ("Shortcut", "shortcut"), "manual": ("Manual", "manual"), "gap": ("Gap", "gap")}


def badge(src, compact=False):
    label, ic = SRC[src]
    return f'<span class="badge {src}">{ICON[ic]}{"" if compact else label}</span>'


def status_bar(time="14:04"):
    return f'<div class="status"><span>{time}</span><span class="sb-r">●●● ▮</span></div>'


def rail(active):
    items = []
    for key, label in [("today", "Today"), ("history", "History"), ("insights", "Insights"), ("settings", "Settings")]:
        items.append(f'<div class="rail-i {"on" if key == active else ""}">{ICON[key]}<span>{label}</span></div>')
    return f'<nav class="rail">{"".join(items)}</nav>'


def topbar(active):
    items = []
    for key, label in [("today", "Today"), ("history", "History"), ("insights", "Insights"), ("settings", "Settings")]:
        items.append(f'<div class="tb-i {"on" if key == active else ""}">{ICON[key]}<span>{label}</span></div>')
    return f'<nav class="topbar">{"".join(items)}</nav>'


def outer(fid, theme, active, body, title=None, caption="", sheet=None):
    plus = '<span class="tbplus">' + ICON["plus"] + 'Record</span>' if active == "today" and title == "Today" else ""
    head = f'<div class="navrow"><h1 class="navtitle">{title}</h1>{plus}</div>' if title else ""
    sh = f'<div class="dim"></div><div class="sheet">{sheet}</div>' if sheet else ""
    railhtml = rail(active) if active else ""
    cls = "with-rail" if active else ""
    return f'''<figure class="mock"><div id="{fid}" class="frame outer {theme}">{status_bar()}
<div class="screen {cls}">{railhtml}<main>{head}{body}</main></div>{sh}</div>
<figcaption>{caption}</figcaption></figure>'''


def inner(fid, theme, active, body, caption=""):
    return f'''<figure class="mock"><div id="{fid}" class="frame inner {theme}">{status_bar()}
{topbar(active)}<div class="screen two">{body}</div></div>
<figcaption>{caption}</figcaption></figure>'''


# ------------------------------------------------------------------ screens
def week_chart(values, today_idx=6, h=110, labels="TWTFSSM"):  # last 7 days ending Mon Nov 9
    mx = max(values) or 1
    bars = []
    for i, v in enumerate(values):
        bh = int(h * v / mx)
        bars.append(f'<div class="bar-c"><div class="bar {"today" if i == today_idx else ""}" style="height:{bh}px"></div><span>{labels[i]}</span></div>')
    return f'<div class="chart" style="height:{h + 18}px">{"".join(bars)}</div>'


COV_ON = '''<div class="tile cov"><div class="tl">Counted for you · this week</div><div class="tn pos">94% <small>of recorded folds</small></div>
<div class="covbar"><i style="width:61%" class="a"></i><i style="width:33%" class="s"></i><i style="width:6%" class="m"></i></div>
<div class="tc">Automatic 61% · Shortcut 33% · Manual 6% · 2 gaps</div></div>'''
COV_OFF = '''<div class="card setup warnb">''' + ICON["warn"] + '''<div><div class="st">Counting only while FoldPulse is open</div>
<div class="ss">Folds made with the app closed aren't counted yet. Add the optional Shortcuts automation to count them too.</div>
<div class="link">Set up background counting</div></div></div>'''


def today_body(empty=False, foreground_only=False):
    if empty:
        return f'''
<div class="hero"><div class="lbl">Folds since install</div><div class="num">0</div>{PULSE}</div>
<div class="card empty"><div class="em-t">Ready when you are</div>
<div class="em-s">Close and open your iPhone while FoldPulse is open, and watch the count start.</div></div>
<div class="card setup warnb">{ICON["warn"]}<div><div class="st">Count in the background</div>
<div class="ss">Optional. Add a Shortcuts automation so folds count even when FoldPulse is closed.</div>
<div class="link">Set up · 1 min</div></div></div>
<div class="rec"><div class="btn primary">Record Fold</div></div>'''
    label = "Folds counted since install" if foreground_only else "Folds since install"
    COV = COV_OFF if foreground_only else COV_ON
    return f'''
<div class="hero"><div class="lbl">{label}</div><div class="num">{"412" if foreground_only else "1,284"}</div>{PULSE}
<div class="mbar"><div style="width:{"82.4" if foreground_only else "25.7"}%"></div></div><div class="mcap">{"88 to the 500 milestone" if foreground_only else "3,716 to the 5,000 milestone"}</div></div>
<div class="tiles"><div class="tile"><div class="tl">Today</div><div class="tn">{"21" if foreground_only else "64"}</div><div class="tc">{"20 unfolds" if foreground_only else "62 unfolds"}</div></div>
<div class="tile"><div class="tl">Daily average</div><div class="tn">{"23" if foreground_only else "72"}</div><div class="tc">last 7 full days</div></div></div>
{COV}
<div class="card"><div class="ch-h">Last 7 days</div>{week_chart([19, 27, 22, 30, 24, 23, 21] if foreground_only else [58, 77, 69, 81, 74, 73, 64])}</div>
<div class="last">Last: <b>Fold</b> · 2 min ago · {badge("auto")}</div>'''


def history_body():
    rows = [
        ("Today", [("14:02", "Fold", "auto", ""), ("13:47", "Unfold", "shortcut", ""), ("13:12", "Fold", "shortcut", ""),
                   ("—", "Unfold (gap)", "gap", ""), ("12:40", "Fold", "auto", ""), ("12:31", "Unfold", "manual", "note")]),
        ("Yesterday · 77 folds", [("23:41", "Fold", "shortcut", ""), ("23:05", "Unfold", "auto", "")]),
    ]
    out = ['<div class="seg"><span class="on">All</span><span>Auto</span><span>Shortcut</span><span>Manual</span></div>',
           '<div class="search">Nov 1 – Nov 9 ▾</div>']
    for day, items in rows:
        out.append(f'<div class="sec">{day}</div><div class="list">')
        for i, (t, typ, src, note) in enumerate(items):
            swipe = ' swiped' if (day == "Today" and i == 2) else ''
            n = '<span class="noteic">✎</span>' if note else ''
            gapc = ' gaprow' if src == "gap" else ''
            out.append(f'<div class="row{swipe}{gapc}"><span class="rt">{t}</span><span class="ry">{typ}{n}</span>{badge(src, compact=True)}'
                       + ('<span class="del">Delete</span>' if swipe else '') + '</div>')
        out.append('</div>')
    out.append('<div class="foot">A gap marks a missed unfold between two folds (or a missed fold between two unfolds). Gaps are not counted in totals.</div>')
    return "".join(out)


def insights_body():
    return f'''
<div class="seg"><span>D</span><span class="on">W</span><span>M</span><span>Y</span></div>
<div class="ins-h"><div class="tl">Last 7 days · Nov 3–9 (incl. today so far)</div><div class="tn big">496 <small>folds</small></div><div class="tc">Previous 7 days: 541</div></div>
<div class="card">{week_chart([58, 77, 69, 81, 74, 73, 64], h=130)}<div class="avgline">Full-day average 72 (Nov 3–8) · today so far 64</div></div>
<div class="tiles"><div class="tile"><div class="tl">Busiest day</div><div class="tn">81</div><div class="tc">Fri, Nov 6</div></div>
<div class="tile"><div class="tl">Avg per day</div><div class="tn">71</div><div class="tc">Nov 1–8 · full days</div></div></div>
<div class="tile cov"><div class="tl">Counted for you · this week</div><div class="tn pos">94% <small>of recorded folds</small></div><div class="tc">Averages use full days only, since Oct 24</div></div>'''


def settings_body():
    groups = [
        ("Counting", [("Background counting", "Self-test passed", "pos"), ("Milestone notifications", "Off", "")]),
        ("Appearance", [("Theme", "System", "")]),
        ("Your data", [("Export data", "CSV · JSON", ""), ("Reset all data", "", "dest")]),
        ("About", [("Privacy", "Data stays on this iPhone", ""), ("FoldPulse 1.0", "", "")]),
    ]
    out = []
    for g, rows in groups:
        out.append(f'<div class="sec">{g}</div><div class="list">')
        for a, b, c in rows:
            out.append(f'<div class="row set"><span class="ry {"destt" if c == "dest" else ""}">{a}</span><span class="rv {c}">{b}</span>{ICON["chev"]}</div>')
        out.append('</div>')
    return "".join(out)


def track_sheet():
    return f'''<div class="grab"></div><div class="sh-bar"><span class="xbtn">✕</span><b>Record</b><span></span></div>
<div class="live"><div class="tl">Hinge right now</div><div class="lv">Fully open</div><div class="tc">Automatic counting is on while FoldPulse is open</div></div>
<div class="btn primary big">Record Fold</div><div class="btn secondary big">Record Unfold</div>
<div class="toast">{ICON["check"]} Fold recorded · Manual <span class="undo">Undo</span></div>
<div class="tc center">Use manual recording only for folds FoldPulse missed. Automatic counts already include folds made while the app is open.</div>'''


def edit_sheet():
    return f'''<div class="grab"></div><div class="sh-bar"><span class="link">Cancel</span><b>Edit event</b><span class="link b">Save</span></div>
<div class="list"><div class="row set"><span class="ry">Type</span><span class="seg2"><span class="on">Fold</span><span>Unfold</span></span></div>
<div class="row set"><span class="ry">Time</span><span class="rv">Today, 13:12</span></div>
<div class="row set"><span class="ry">Source</span>{badge("shortcut")}<span class="rv">· edited</span></div>
<div class="row set"><span class="ry">Note</span><span class="rv">Add a note</span></div></div>
<div class="tc">The original source is kept and the event is marked "edited", so totals stay transparent.</div>
<div class="btn destructive">Delete event</div>'''


def coverage_body():
    return f'''<div class="hero small"><div class="lbl">Counted for you · this week</div><div class="num pos">94%</div><div class="tc">of 496 recorded folds</div></div>
<div class="list"><div class="row set"><span class="ry">{badge("auto")}</span><span class="rv">303 folds · 61%</span></div>
<div class="row set"><span class="ry">{badge("shortcut")}</span><span class="rv">164 folds · 33%</span></div>
<div class="row set"><span class="ry">{badge("manual")}</span><span class="rv">29 folds · 6%</span></div>
<div class="row set"><span class="ry">{badge("gap")}</span><span class="rv">2 gaps · not counted</span></div></div>
<div class="card setup okb">{ICON["check"]}<div><div class="st">Background counting is working</div>
<div class="ss">Last automation run: today 13:47. Self-test passed on Oct 24.</div><div class="link">Run self-test again</div></div></div>
<div class="tc">"Counted for you" is the share of recorded folds that FoldPulse or your automation captured without you tapping. Folds that were missed entirely can't be included. Gaps show where we know something was missed.</div>'''


def setup_body():
    steps = ["Open Shortcuts → Automation → New Automation",
             "Choose the “Opened or Closed” trigger → Closed",
             "Choose Run Immediately, then add the action “Record Fold (FoldPulse)”",
             "Repeat with Opened → “Record Unfold (FoldPulse)”"]
    st = "".join(f'<div class="step"><span class="sn">{i + 1}</span><span>{t}</span></div>' for i, t in enumerate(steps))
    return f'''<div class="intro">Optional. Count folds even when FoldPulse is closed. To stop later, delete the two automations in Shortcuts.</div>
<div class="steps">{st}</div><div class="btn primary">Open Shortcuts</div>
<div class="card"><div class="st">Self-test · not run yet</div><div class="ss">Close your iPhone, wait a moment, then open it. FoldPulse checks that both automations ran. This is the only way it can know.</div><div class="btn secondary">Start self-test</div></div>
<div class="help"><b>Can't find the trigger?</b> It needs iOS 27.2 or later (Settings → General → About). FoldPulse still counts automatically while it's open.</div>'''


def export_sheet():
    return f'''<div class="grab"></div><div class="sh-t">Export data</div>
<div class="list"><div class="row set"><span class="ry">Format</span><span class="seg2"><span class="on">CSV</span><span>JSON</span></span></div>
<div class="row set"><span class="ry">Range</span><span class="rv">All time · 2,565 events</span></div></div>
<div class="card setup infob">{ICON["lock"]}<div><div class="st">Your file, your choice</div>
<div class="ss">FoldPulse never uploads anything. Fold times can reveal daily routines like sleep, so share the file only with people you trust.</div></div></div>
<div class="btn primary">{ICON["share"]} Export</div>'''


def milestone_sheet():
    return f'''<div class="grab"></div><div class="ms">{PULSE}<div class="msn">1,000</div><div class="mst">folds since install</div>
<div class="tc center">Reached on Nov 6 at 08:12. Next milestone: 5,000.</div></div><div class="btn primary">Nice</div>'''


def onboarding(step):
    pages = {
        1: ("Every Fold. Every Beat.", "FoldPulse counts how often you fold and unfold your iPhone Duo, and turns it into simple, beautiful stats.",
            f'<div class="ob-art">{PULSE}</div>', "Continue"),
        2: ("How counting works", "",
            f'''<div class="ob-list"><div>{badge("auto")}<span>Counted for you while FoldPulse is open.</span></div>
<div>{badge("shortcut")}<span>Optional: counted in the background by a Shortcuts automation you add.</span></div>
<div>{badge("manual")}<span>You can always record or fix a fold by hand.</span></div></div>
<div class="tc">Every number shows where it came from.</div>''', "Continue"),
        3: ("Private by design", "",
            f'''<div class="ob-list"><div>{ICON["lock"]}<span>Your data stays on this iPhone. No account, no cloud, no tracking.</span></div>
<div>{ICON["share"]}<span>Export your history any time, as CSV or JSON.</span></div></div>''', "Start counting"),
    }
    t, s, art, cta = pages[step]
    dots = "".join(f'<i class="{"on" if i == step else ""}"></i>' for i in (1, 2, 3))
    return f'''<div class="ob">{art if step == 1 else ""}<div class="ob-t">{t}</div><div class="ob-s">{s}</div>{art if step != 1 else ""}
<div class="ob-foot"><div class="dots">{dots}</div><div class="btn primary">{cta}</div></div></div>'''


def manual_only():
    return f'''<div class="ob"><div class="ob-art small">{ICON["manual"]}</div><div class="ob-t">This iPhone has no hinge</div>
<div class="ob-s">Automatic fold counting needs iPhone Duo. You can still record folds manually, for example to track another device.</div>
<div class="ob-foot"><div class="btn primary">Use manual mode</div></div></div>'''


def inner_today():
    return f'''<section class="colA">{today_body()}</section>
<section class="colB"><div class="sec">Recent</div><div class="list">
<div class="row"><span class="rt">14:02</span><span class="ry">Fold</span>{badge("auto", True)}</div>
<div class="row"><span class="rt">13:47</span><span class="ry">Unfold</span>{badge("shortcut", True)}</div>
<div class="row"><span class="rt">13:12</span><span class="ry">Fold</span>{badge("shortcut", True)}</div>
<div class="row gaprow"><span class="rt">—</span><span class="ry">Unfold (gap)</span>{badge("gap", True)}</div></div>
<div class="card"><div class="ch-h">Next milestone</div><div class="tn">5,000</div><div class="mbar"><div style="width:25.7%"></div></div><div class="tc">3,716 to go · at your pace, around Dec 31</div></div>
<div class="rec"><div class="btn primary">Record Fold</div></div></section>'''


def inner_history():
    return f'''<section class="colA">{history_body()}</section>
<section class="colB"><div class="sec">Event</div><div class="det"><div class="tn big">Fold</div><div class="tc">Today at 13:12 · Europe/London</div>
<div class="list"><div class="row set"><span class="ry">Source</span>{badge("shortcut")}</div>
<div class="row set"><span class="ry">Matched with</span><span class="rv">Automatic fold 13:12 (duplicate removed)</span></div>
<div class="row set"><span class="ry">Note</span><span class="rv">—</span></div></div>
<div class="btn secondary">Edit</div><div class="btn destructive">Delete event</div></div></section>'''


def inner_insights():
    return f'''<section class="colA">{insights_body()}</section>
<section class="colB"><div class="sec">Month · November</div><div class="card">{week_chart([71, 66, 58, 77, 69, 81, 74, 73, 64], today_idx=8, h=150, labels="123456789")}</div>
<div class="tiles"><div class="tile"><div class="tl">Since install</div><div class="tn">1,284</div><div class="tc">17 days</div></div>
<div class="tile"><div class="tl">Unfolds</div><div class="tn">1,281</div><div class="tc">2 gaps</div></div></div></section>'''


# ------------------------------------------------------------------ widgets & icon
def widgets():
    small = lambda theme, fid, extra="": f'''<div id="{fid}" class="wsmall {theme} {extra}"><div class="wl">Today</div><div class="wn">64</div><div class="wl2">folds</div>
<div class="wf">1,284 since install</div><div class="wf2">as of 14:02</div>{PULSE}</div>'''
    return f'''
<figure class="mock"><div id="w-home" class="wall">{small("light", "w-small-light")}{small("dark", "w-small-dark")}</div>
<figcaption>Home Screen small widget · light and dark</figcaption></figure>
<figure class="mock"><div id="w-standby" class="standby"><div class="sb-clock">21:47</div><div class="sb-w">
<div class="wl">Today</div><div class="wn">64</div><div class="wl2">folds · 1,284 since install</div></div>
<div class="sb-w night"><div class="wl">Today</div><div class="wn">64</div><div class="wl2">folds · 1,284 since install</div></div></div>
<figcaption>StandBy: small widget at system scale; right = night mode (system red tint)</figcaption></figure>
<figure class="mock"><div id="w-lock" class="lock"><div class="lk-time">14:04</div>
<div class="lk-row"><div class="circ"><svg viewBox="0 0 60 60"><circle cx="30" cy="30" r="24" class="tr"/><circle cx="30" cy="30" r="24" class="pr" stroke-dasharray="135 151"/></svg><span>64</span></div>
<div class="rect"><div class="r1">FoldPulse</div><div class="r2">64 folds today</div><div class="r3">1,284 since install</div></div></div>
<div class="lk-priv"><div class="circ"><svg viewBox="0 0 60 60"><circle cx="30" cy="30" r="24" class="tr"/></svg><span>••</span></div>
<div class="rect"><div class="r1">FoldPulse</div><div class="r2">•• folds today</div></div></div></div>
<figcaption>Lock Screen: circular gauge (today vs. daily average) and rectangular; bottom row = privacy-redacted while locked</figcaption></figure>'''


ICON_SVG = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
<defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#173058"/><stop offset="1" stop-color="#060D1C"/></linearGradient>
<linearGradient id="pl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4C8DFF"/><stop offset="1" stop-color="#2F6BE8"/></linearGradient>
<linearGradient id="pr" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7BD6FF"/><stop offset="1" stop-color="#3FB4F0"/></linearGradient></defs>
<rect width="1024" height="1024" fill="url(#bg)"/>
<path d="M500 250 H330 a70 70 0 0 0 -70 70 V704 a70 70 0 0 0 70 70 H500 Z" fill="url(#pl)"/>
<path d="M524 250 H694 a70 70 0 0 1 70 70 V704 a70 70 0 0 1 -70 70 H524 Z" fill="url(#pr)"/>
<path d="M130 540 H380 L440 420 L520 670 L585 480 L625 540 H894" fill="none" stroke="#FFFFFF" stroke-width="52" stroke-linecap="round" stroke-linejoin="round"/>
</svg>'''

ICON_DARK = (ICON_SVG.replace('stop-color="#173058"', 'stop-color="#000000"').replace('stop-color="#060D1C"', 'stop-color="#000000"')
             .replace('stop-color="#4C8DFF"', 'stop-color="#6FA2FF"').replace('stop-color="#7BD6FF"', 'stop-color="#9BE2FF"'))
ICON_TINT = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><rect width="1024" height="1024" fill="#1C1C1E"/>'
             '<path d="M500 250 H330 a70 70 0 0 0 -70 70 V704 a70 70 0 0 0 70 70 H500 Z" fill="#B8C4D6"/><path d="M524 250 H694 a70 70 0 0 1 70 70 V704 a70 70 0 0 1 -70 70 H524 Z" fill="#8E9AAE"/>'
             '<path d="M130 540 H380 L440 420 L520 670 L585 480 L625 540 H894" fill="none" stroke="#FFFFFF" stroke-width="52" stroke-linecap="round" stroke-linejoin="round"/></svg>')


def _img(svg):
    """Embed an SVG as an isolated <img> so gradient ids don't collide between variants."""
    import base64
    return '<img src="data:image/svg+xml;base64,' + base64.b64encode(svg.encode()).decode() + '" style="width:100%;height:100%;display:block">'


def icon_sheet():
    (HERE.parent / "icon").mkdir(exist_ok=True)
    (HERE.parent / "icon" / "FoldPulse-icon.svg").write_text(ICON_SVG)
    (HERE.parent / "icon" / "FoldPulse-icon-dark.svg").write_text(ICON_DARK)
    (HERE.parent / "icon" / "FoldPulse-icon-tinted.svg").write_text(ICON_TINT)
    sizes = "".join(f'<div class="isz"><div class="ic" style="width:{s}px;height:{s}px">{_img(ICON_SVG)}</div><span>{s} px</span></div>' for s in (180, 120, 87, 58, 40))
    return f'''<figure class="mock"><div id="icon-sheet" class="iconsheet">
<div class="ibig"><div class="ic" style="width:300px;height:300px">{_img(ICON_SVG)}</div><span>Default</span></div>
<div class="ibig"><div class="ic" style="width:300px;height:300px">{_img(ICON_DARK)}</div><span>Dark</span></div>
<div class="ibig"><div class="ic" style="width:300px;height:300px">{_img(ICON_TINT)}</div><span>Tinted</span></div>
<div class="irow">{sizes}</div>
<div class="ihome">{"".join(f'<div class="ap"><div class="ic">{_img(ICON_SVG) if i == 1 else ""}</div><span>{"FoldPulse" if i == 1 else ""}</span></div>' for i in range(4))}</div>
</div><figcaption>App icon: final candidate (Concept A refined), appearances and small-size test</figcaption></figure>'''


def page():
    css = (HERE / "mockups.css").read_text()
    frames = [
        outer("o-today-dark", "dark", "today", today_body(), "Today", "Today · outer display · dark"),
        outer("o-today-light", "light", "today", today_body(), "Today", "Today · outer display · light"),
        outer("o-today-empty", "light", "today", today_body(empty=True), "Today", "Today · first run (no data)"),
        outer("o-today-foreground", "light", "today", today_body(foreground_only=True), "Today", "Today · background counting not set up (likely default)"),
        outer("o-track", "dark", "today", today_body(), "Today", "Record sheet (manual) with Undo", sheet=track_sheet()),
        outer("o-history", "light", "history", history_body(), "History", "History · filters, swipe to delete, gap row"),
        outer("o-edit", "light", "history", history_body(), "History", "Edit event sheet", sheet=edit_sheet()),
        outer("o-insights", "dark", "insights", insights_body(), "Insights", "Insights · last 7 days"),
        outer("o-coverage", "light", "today", coverage_body(), "Coverage", "Coverage detail (from the Today tile)"),
        outer("o-setup", "light", "settings", setup_body(), "Background counting", "Guided Shortcuts setup + self-test"),
        outer("o-settings", "light", "settings", settings_body(), "Settings", "Settings"),
        outer("o-export", "light", "settings", settings_body(), "Settings", "Export sheet with privacy note", sheet=export_sheet()),
        outer("o-milestone", "dark", "today", today_body(), "Today", "Milestone celebration (once)", sheet=milestone_sheet()),
        outer("o-onboard-1", "dark", None, onboarding(1), None, "Onboarding 1 · welcome"),
        outer("o-onboard-2", "dark", None, onboarding(2), None, "Onboarding 2 · how counting works"),
        outer("o-onboard-3", "dark", None, onboarding(3), None, "Onboarding 3 · privacy"),
        outer("o-manual-only", "light", None, manual_only(), None, "Non-hinge iPhone · manual-only mode"),
        inner("i-today", "light", "today", inner_today(), "Today · inner display, fully open · ArrangementView split"),
        inner("i-history", "dark", "history", inner_history(), "History · inner display · list + detail"),
        inner("i-insights", "light", "insights", inner_insights(), "Insights · inner display"),
    ]
    return f'''<!doctype html><html><head><meta charset="utf-8"><title>FoldPulse mockups</title><style>{css}</style></head>
<body><header class="doc"><h1>FoldPulse — Phase 2 mockups</h1><p>Sample data for illustration only. Fonts: Inter stands in for SF Pro. Display proportions are assumptions to be checked in Xcode Device Hub.</p></header>
<div class="grid">{"".join(frames)}</div><div class="grid">{widgets()}</div><div class="grid">{icon_sheet()}</div></body></html>'''


def main():
    html_path = HERE / "mockups.html"
    html_path.write_text(page())
    subprocess.run(["node", str(HERE / "shoot.js"), str(html_path), str(PNG)], check=True)
    print("rendered:", sorted(p.name for p in PNG.glob("*.png")))


if __name__ == "__main__":
    main()
