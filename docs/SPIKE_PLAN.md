# FoldPulse — Phase 1b Device Validation Spike: Test Protocol

**Owners:** Agent 3 (Architect) and Agent 9 (QA) · **Run by:** Founder, on a physical iPhone Duo
**Version:** 1.0 · 9 November 2026 · **Approved by:** Founder (decision C-2)

## Why we're doing this

Phase 1 found that FoldPulse's promise rests on two behaviours that **only a real iPhone Duo can confirm**:

1. **Foreground:** when FoldPulse is open and you fold the phone, does the app actually receive the "closed" hinge update?
2. **Background:** does the iOS 27.2 Shortcuts automation "When my iPhone is opened/closed" run FoldPulse's action **without asking you each time**, and does it still fire **while the phone is locked**?

If (2) fails, the team recommends pausing the project (see the Phase 1 report, condition C-2). This test takes about **2–3 hours of hands-on time**, plus 24 hours of normal use for the battery check.

## What you need

- A Mac with **Xcode 27.1 or later**, and your **iPhone Duo on iOS 27.2 or later** (Settings → General → About).
- A USB-C cable. A free Apple ID is enough to run the app on your own phone.
- A **hand tally counter (clicker)**, or a tally-counter app on **another** device. This is the "ground truth": you click once **every time you close** the phone.
- Optional: a second phone to video-record the long runs (helps resolve disagreements).

## Part 1 — Install FoldProbe (≈ 15 min)

**Easiest (no Claude needed on the Mac):** plug in the iPhone, open Terminal and paste:

```
curl -fsSL https://raw.githubusercontent.com/odthientho/FoldPulse/main/spike/setup_mac.sh | bash
```

The script downloads the project, generates `FoldProbe.xcodeproj` and opens Xcode. Then, in Xcode: **FoldProbe target → Signing & Capabilities → Team** = your Apple ID; choose your iPhone at the top; press **▶ Run**. You still need step 5 below (Developer Mode). If you have Claude Code on the Mac, `spike/MAC_SESSION_PROMPT.md` lets it do everything instead. The manual steps below are the fallback.

FoldProbe is a throwaway diagnostic app. It is **not** FoldPulse and will never ship. It writes a log file on your phone and never uses the network.

1. On the Mac, open Xcode → **File → New → Project… → iOS → App**. Product Name: `FoldProbe`. Interface: **SwiftUI**. Language: **Swift**. Storage: **None**. Uncheck tests.
2. In the project navigator, **delete** the generated `ContentView.swift` and `FoldProbeApp.swift` (choose "Move to Trash").
3. Drag the four files from the repository's `spike/FoldProbe/` folder into the project (tick "Copy items if needed" and the FoldProbe target):
   `FoldProbeApp.swift`, `ContentView.swift`, `ProbeLog.swift`, `ProbeIntents.swift`.
4. Select the FoldProbe target → **General** → *Minimum Deployments*: **iOS 27.1**. Under **Signing & Capabilities**, choose your Team (your Apple ID).
5. On the iPhone: **Settings → Privacy & Security → Developer Mode → On** (it restarts).
6. Connect the iPhone, select it as the run destination, and press **Run (⌘R)**. The first time, trust the developer on the phone: Settings → General → VPN & Device Management.
7. FoldProbe opens and shows "Live hinge". Fold and unfold once: **Status** should change and **Callbacks** should increase.
   - **If Xcode shows a build error**, copy the error text and send it to Claude. The code was written without access to Xcode, so a small fix may be needed.

## Part 2 — Create the two automations (≈ 5 min)

1. Open **Shortcuts → Automation → + → New Automation**.
2. Find **Opened or Closed** (in the Display section). Choose **Closed**.
3. If you see **Run Immediately** (or a similar option), **select it** and switch **off** "Notify When Run". Write down which options you were offered (Observation O-1).
4. Tap Next → **New Blank Automation → Add Action** → search **"Probe"** → choose **Probe: Phone Closed** (FoldProbe). Done.
5. Repeat for **Opened** → **Probe: Phone Opened**.

## Part 3 — The test runs

**Before each run:** open FoldProbe → **Test run → Condition** → pick the run → tap **Mark START of run**. Reset your clicker to 0.
**After each run:** return to FoldProbe → **Mark END of run**. Write the clicker total in the results sheet.
**One cycle** = close the phone fully, then open it. Click the counter **each time you close**. Vary your speed naturally. Keep ~1 second between actions unless the run says otherwise.

| Run | Condition (pick in app) | Setup | Cycles | What it proves |
|---|---|---|---|---|
| A | `A-foreground-300` | Automations **off** (toggle both off in Shortcuts). FoldProbe on screen | **300** | Foreground fold detection accuracy; best debounce window |
| B | `B-foreground-automation-50` | Automations **on**. FoldProbe on screen | 50 | De-duplication: hinge and automation together; latency |
| C | `C-background-unlocked-100` | Automations on. After START, go to the Home Screen; keep the phone unlocked (Face ID) | 100 | Background counting while unlocked |
| D | `D-locked-300` | Automations on. After START, **lock** the phone (side button). Fold/unfold **without unlocking** | **300** | **The critical test:** counting while locked |
| E | `E-locked-lowpower-100` | Turn on **Low Power Mode**, then as in D | 100 | Reliability under power saving |
| F | `F-rotation-only` | Automations on. FoldProbe on screen. **Don't fold**: rotate the phone through all orientations, ~20 turns while fully open, then ~20 while half-open ("tent") | 0 | Rotation must never look like a fold |
| G | `G-slow-and-bounce-50` | FoldProbe on screen. Close **slowly**; sometimes stop just before closing, or let it bounce | 50 | Edge cases at the closing point |

Tip: runs A and D are long (≈ 10–15 min each). Take breaks *between* runs, not during them.

## Part 4 — Observations to note (write them down as you go)

| # | Question | Your answer |
|---|---|---|
| O-1 | When creating the automation, which options were offered (Run Immediately / Ask Before Running / Notify When Run)? | |
| O-2 | During runs C–E, did iOS ever **ask you to confirm**, or show a banner or notification? | |
| O-3 | When you fold with FoldProbe open, does the app keep running on the outer display, or does the phone lock or go to the Home Screen? | |
| O-4 | **StandBy:** put the phone on a charger, locked, on its side. Does StandBy appear when the phone is **closed**? When **open**? | |
| O-5 | Anything surprising (lag, missed folds you noticed, crashes)? | |

## Part 5 — Battery (24 hours, passive)

Leave both automations **on** and use your phone normally for a day. Then open **Settings → Battery** and note FoldProbe's percentage (O-6), and roughly how often you folded that day.

## Part 6 — Send the results back

1. In FoldProbe → **Share log file** → save to Files, or AirDrop it to your Mac.
2. Send Claude the `foldprobe-log.jsonl` file plus your clicker totals and observations O-1…O-6. For example:
   `A=300 B=50 C=100 D=300 E=100 F=0 G=50`
3. Claude runs `spike/analyze.py` on the log and writes the spike report (`phase-01b-spike.pdf`) with a clear **pass/fail** for each criterion.

When finished, delete the automations and FoldProbe.

## Pass / fail criteria (set in Phase 1)

| ID | Criterion | Pass if |
|---|---|---|
| S-1 | Foreground fold detection (run A) | ≤ 3 errors in 300 folds at the chosen debounce window |
| S-2 | Automation needs no confirmation (O-1, O-2) | No prompt or confirmation on any run |
| S-3 | Background coverage while locked (run D) | Automation logs ≥ 95% of clicker folds (≥ 285 of 300) |
| S-4 | Locked writes (run D) | All automation events written while locked (no write errors) |
| S-5 | De-duplication (run B) | Every automation event pairs with one hinge event within 10 s |
| S-6 | Rotation (run F) | Zero fold or unfold events |
| S-7 | Battery (Part 5) | FoldProbe ≤ 1% of daily battery |

**Decision rule.** If **S-2 or S-3 fails**, the team recommends pausing and re-assessing with you before Phase 2. If **S-1 fails**, automatic foreground counting is limited to unfolds and the scope is re-planned. Other failures are design inputs, not blockers.
