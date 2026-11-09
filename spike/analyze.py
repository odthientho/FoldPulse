#!/usr/bin/env python3
"""Analyse a FoldProbe log (foldprobe-log.jsonl) for the FoldPulse Phase 1b spike.

Usage:
    python3 spike/analyze.py foldprobe-log.jsonl \
        --tally A-foreground-300=300 D-locked-300=300 ... [--out report.md]

--tally gives the number of FOLDS (closings) the tester counted with a
clicker for each run. Runs are delimited by the app's "Mark START/END" notes.

The report contains, per run:
  * hinge-based fold/unfold counts for several debounce windows vs. the tally
  * Shortcuts automation counts, coverage vs. tally, locked-write evidence
  * pairing of automation events with hinge edges (latency, either order)
  * rotation-only false transitions
"""
import argparse
import json
import statistics
import sys
from collections import Counter

DEBOUNCE_MS = [0, 100, 250, 500, 1000]
PAIR_WINDOW_S = 10.0
OPEN = {"partiallyOpen", "fullyOpen"}


def load(path):
    recs = []
    with open(path, encoding="utf-8") as fh:
        for n, line in enumerate(fh, 1):
            line = line.strip()
            if not line:
                continue
            try:
                recs.append(json.loads(line))
            except json.JSONDecodeError:
                print(f"warning: line {n} is not valid JSON, skipped", file=sys.stderr)
    recs.sort(key=lambda r: r["t"])
    return recs


def split_runs(recs):
    """Return {condition: [records]} using 'start X' / 'end X' notes."""
    runs, current, start_t = {}, None, None
    for r in recs:
        if r["kind"] == "note":
            edge, _, cond = (r.get("detail") or "").partition(" ")
            if edge == "start":
                current, start_t = cond, r["t"]
                runs.setdefault(current, [])
            elif edge == "end" and current == cond:
                current = None
            continue
        if current is not None:
            runs[current].append(r)
    return runs


def hinge_segments(recs):
    """Collapse hinge callbacks into (t_entered, coarse) segments: closed/open."""
    segs = []
    for r in recs:
        if r["kind"] != "hinge":
            continue
        st = r.get("status")
        if st == "closed":
            coarse = "closed"
        elif st in OPEN:
            coarse = "open"
        else:
            continue  # nil / unknown / other: never counted, baseline unchanged
        if not segs or segs[-1][1] != coarse:
            segs.append((r["t"], coarse))
    return segs


def debounced_edges(segs, end_t, debounce_ms):
    """Drop segments shorter than the debounce window; first segment = baseline."""
    d = debounce_ms / 1000.0
    kept = []
    for i, (t, c) in enumerate(segs):
        nxt = segs[i + 1][0] if i + 1 < len(segs) else end_t
        if nxt - t >= d or i + 1 == len(segs):  # last segment is still current
            if not kept or kept[-1][1] != c:
                kept.append((t, c))
    edges = []
    for (t0, c0), (t1, c1) in zip(kept, kept[1:]):
        edges.append((t1, "fold" if c1 == "closed" else "unfold"))
    return edges


def pair(shortcuts, edges):
    """One-to-one pairing of shortcut events with same-type hinge edges (±window)."""
    used, deltas, unmatched = set(), [], 0
    for t, typ in shortcuts:
        best = None
        for i, (te, ty) in enumerate(edges):
            if i in used or ty != typ or abs(te - t) > PAIR_WINDOW_S:
                continue
            if best is None or abs(te - t) < abs(edges[best][0] - t):
                best = i
        if best is None:
            unmatched += 1
        else:
            used.add(best)
            deltas.append(t - edges[best][0])  # >0: shortcut after hinge edge
    return deltas, unmatched


def fmt_stats(xs):
    if not xs:
        return "—"
    xs = sorted(xs)
    p95 = xs[min(len(xs) - 1, int(round(0.95 * (len(xs) - 1))))]
    return f"median {statistics.median(xs):+.2f} s · p95 {p95:+.2f} s · min {xs[0]:+.2f} s · max {xs[-1]:+.2f} s"


def analyse(path, tallies):
    recs = load(path)
    runs = split_runs(recs)
    out = [f"# FoldProbe spike analysis\n\nLog: `{path}` · {len(recs)} records · {len(runs)} runs\n"]
    if not runs:
        out.append("No runs found. Use **Mark START/END of run** in FoldProbe around each test.\n")
    for cond, rr in runs.items():
        tally = tallies.get(cond)
        end_t = rr[-1]["t"] if rr else 0
        kinds = Counter(r["kind"] for r in rr)
        statuses = Counter(r.get("status") for r in rr if r["kind"] == "hinge")
        segs = hinge_segments(rr)
        out.append(f"## Run `{cond}`\n")
        dur = (rr[-1]["t"] - rr[0]["t"]) if len(rr) > 1 else 0
        out.append(f"- Duration {dur/60:.1f} min · records {dict(kinds)}")
        out.append(f"- Hinge callbacks by status: {dict(statuses)}")
        out.append(f"- Clicker tally (folds): **{tally if tally is not None else 'not given'}**\n")

        if not statuses:
            out.append("_No hinge callbacks in this run. This is expected when FoldProbe is not on screen "
                       "(background/locked runs): only the Shortcuts automation can count there._\n")
        out.append("| Debounce | Hinge folds | Hinge unfolds | Error vs tally |")
        out.append("|---|---|---|---|")
        for ms in DEBOUNCE_MS:
            e = debounced_edges(segs, end_t, ms)
            f = sum(1 for _, x in e if x == "fold")
            u = len(e) - f
            err = "—" if tally is None else (f"{f - tally:+d} ({(f - tally) / tally:+.1%})" if tally else f"{f - tally:+d}")
            out.append(f"| {ms} ms | {f} | {u} | {err} |")
        out.append("")

        sc = [(r["t"], "fold" if r.get("status") == "closed" else "unfold")
              for r in rr if r["kind"] == "shortcut"]
        sc_f = sum(1 for _, x in sc if x == "fold")
        locked = sum(1 for r in rr if r["kind"] == "shortcut" and "protectedData=false" in (r.get("detail") or ""))
        cov = f"{sc_f / tally:.1%}" if tally else "—"
        out.append(f"- Shortcut automation: **{sc_f} closed**, {len(sc) - sc_f} opened · coverage vs tally **{cov}** · "
                   f"written while the device was locked (protected data unavailable): {locked}")
        seq = [x for _, x in sc]
        repeats = sum(1 for a, b in zip(seq, seq[1:]) if a == b)
        out.append(f"- Automation alternation breaks (same type twice in a row ⇒ a missed run): {repeats}")

        edges = debounced_edges(segs, end_t, 250)
        if edges and sc:
            deltas, unmatched = pair(sc, edges)
            out.append(f"- Pairing with hinge edges (250 ms, ±{PAIR_WINDOW_S:.0f} s, either order): "
                       f"{len(deltas)} paired, {unmatched} shortcut events unpaired")
            out.append(f"- Shortcut minus hinge time: {fmt_stats(deltas)}")
            over3 = sum(1 for d in deltas if abs(d) > 3)
            out.append(f"- Pairs further apart than 3 s: {over3}")

        # rotation / posture churn: open↔open status changes without closing
        churn = 0
        prev = None
        for r in rr:
            if r["kind"] == "hinge" and r.get("status") in OPEN:
                if prev in OPEN and prev != r["status"]:
                    churn += 1
                prev = r["status"]
            elif r["kind"] == "hinge" and r.get("status") == "closed":
                prev = "closed"
        out.append(f"- partiallyOpen↔fullyOpen changes (not counted; rotation sensitivity): {churn}")
        out.append("")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("log")
    ap.add_argument("--tally", nargs="*", default=[], help="CONDITION=FOLDS pairs")
    ap.add_argument("--out")
    a = ap.parse_args()
    tallies = {}
    for item in a.tally:
        k, _, v = item.partition("=")
        tallies[k] = int(v)
    report = analyse(a.log, tallies)
    if a.out:
        open(a.out, "w", encoding="utf-8").write(report)
    print(report)


if __name__ == "__main__":
    main()
