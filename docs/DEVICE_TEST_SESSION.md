# FoldPulse — Device Test Session (Phase 5, Part B)

**For:** the Founder, with a Mac and an iPhone Duo · **Version:** 1.0 · 9 November 2026

These tests need real hardware; no computer in the cloud can run them. They're split into short sessions. **Do them in order, and stop anywhere.** Whatever isn't done is listed honestly as "not verified" in the Phase 5 report, and anything that blocks release says so.

When a step says **"Send:"**, reply to Claude with a short answer or a screenshot. To take a screenshot on iPhone, press the side button and volume-up together.

---

## Session 1 — Install FoldPulse on your iPhone Duo (≈ 15 min) · closes P4-1

1. On the iPhone: **Settings → General → About → iOS Version**.
   **Send:** the number (for example 27.2.1).
2. Plug the iPhone into the Mac. Open **Terminal** and paste:
   ```
   curl -fsSL https://raw.githubusercontent.com/odthientho/FoldPulse/main/scripts/setup_mac.sh | bash
   ```
3. In Xcode:
   - Click **FoldPulse** (top of the left sidebar) → **Signing & Capabilities** → **Team** = your Apple ID. Do the same for **FoldPulseWidgets**.
   - Choose your iPhone Duo at the top, then press **▶**.
4. **If Xcode shows a red error, Send:** a screenshot of it. It may be about the App Group or a "personal team"; that's risk R-29, and Claude will tell you the next step.
5. When FoldPulse opens, go through the three welcome pages, then fold and unfold the phone 5 times with the app open.
   **Send:** a screenshot of **Today**. It should show **5** under "Folds counted since install".

## Session 2 — Quick checks (≈ 10 min) · closes P4-2 / I-24 and widget checks

1. **Half-fold** the phone like a small laptop with FoldPulse open on the big screen.
   **Send:** a screenshot. Is any text or button hidden in the fold?
2. Long-press the Home Screen → **Edit → Add Widget** → **FoldPulse** → add the small widget.
   **Send:** a screenshot.
3. Lock Screen: long-press it → **Customize → Lock Screen** → add both FoldPulse widgets.
   **Send:** a screenshot of the Lock Screen.
4. Put the phone on a charger, locked, on its side.
   **Send:** does StandBy appear? Try it closed and open.

## Session 3 — Background counting (≈ 10 min) · closes R-28 (S-2)

Only if your iPhone is on **iOS 27.2 or later** (Session 1, step 1).

1. In FoldPulse: **Settings → Shortcuts automation → Open Shortcuts**, and follow the 4 steps on that screen.
   - **If you get stuck on any Shortcuts screen, Send:** a screenshot, and Claude will say exactly what to tap.
2. Back in FoldPulse, tap **Start self-test**. Close the phone, wait 5 seconds, then open it and return to FoldPulse.
   **Send:** a screenshot of the result (Working ✓ or the reason it failed).
3. **Send:** were you ever asked to confirm the automation? (yes / no)

## Session 4 — Accuracy (≈ 30 min, can be split) · S-1 and S-3

Use a clicker, or a tally-counter app on another device. Click once **each time you close** the phone.

1. **With FoldPulse open:** in FoldPulse, note the Folds number. Close and open the phone **100 times**, clicking each close. Note the number again.
   **Send:** your click total, and FoldPulse's increase.
2. **With the phone locked** (needs Session 3): lock it, then close and open **100 times** without unlocking. Unlock and open FoldPulse.
   **Send:** your click total, and FoldPulse's increase.
3. **Rotation:** with FoldPulse open, rotate the phone in every direction 20 times, open and half-folded, **without closing it**.
   **Send:** did the number change? (It shouldn't.)

## Session 5 — One day of normal use · privacy, battery, persistence

1. Turn on **App Privacy Report**: Settings → Privacy & Security → App Privacy Report → On.
2. Use your phone normally for a day, with the automation on, and restart the phone once.
3. **Send:**
   - **App Privacy Report → FoldPulse**: a screenshot. It should list **no network activity or domains**.
   - **Settings → Battery**: FoldPulse's percentage over the last 24 hours.
   - **Today** in FoldPulse after the restart: are the numbers still there?

---

| Session | Closes | Release-blocking if not done? |
|---|---|---|
| 1 | P4-1: the app runs and counts on iPhone Duo | **Yes**: automatic counting would be unverified |
| 2 | P4-2 / I-24, widget display, StandBy | Yes for P4-2 (inner-screen layout); StandBy is informational |
| 3 | R-28: background counting | **Yes for any background-counting claim** in the App Store text |
| 4 | Accuracy targets (≥ 99 % open, ≥ 95 % locked) | **Yes** for accuracy claims |
| 5 | Privacy at runtime, battery, persistence after restart | Yes for privacy (PT-03); battery is informational |
