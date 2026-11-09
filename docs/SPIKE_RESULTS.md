# FoldPulse — Phase 1b Device Spike: Results (partial)

**Version:** 1.0 · 9 November 2026 · **Status:** Closed early by Founder decision (C-2r)

## What was verified on a real iPhone Duo

| Item | Result | Evidence |
|---|---|---|
| FoldProbe builds and runs with the documented iOS 27.1 hinge API (`onHingeChange`, `DeviceHinge`) | **Pass**: built and ran with no code changes | Founder report, 9 Nov 2026 |
| Hinge callbacks fire while the app is on screen | **Pass**: fires continuously (many per fold), as Apple documents | Founder report |
| Fold/unfold edge counting in the foreground (closed ↔ open) | **Pass (informal)**: 5 folds → Folds 5, Unfolds 5 | Founder quick check |

## What was not verified

| Criterion | Status | Note |
|---|---|---|
| S-1 Foreground accuracy (300 cycles vs clicker) | Not run | The informal 5/5 is encouraging but not statistically meaningful |
| S-2 Automation runs without confirmation | **Not run** | The Founder could not find the "Opened or Closed" trigger in Shortcuts. The cause is unknown: the device may be on iOS 27.1 (the trigger needs 27.2), or the trigger may have a different label |
| S-3 Background coverage while locked | **Not run** | Depends on S-2 |
| S-4 Locked writes | Not run | |
| S-5 De-duplication | Not run | |
| S-6 Rotation | Not run | |
| S-7 Battery | Not run | |

## Decision and consequences

The Founder decided to **skip the remaining tests and continue to Phase 2** (decision C-2r).

Consequences adopted by the team:

1. **Background counting stays unverified (risk R-02, High).** The design treats it as an **optional add-on** that the app can live without. Every screen must work in "foreground + manual" mode, and the coverage indicator explains the gap honestly.
2. **Claims stay conservative** until the automation is verified: "Counts folds automatically while FoldPulse is open. Add the Shortcuts automation to count in the background."
3. **The guided setup includes a recovery path:** "Can't find the trigger? Check that you're on iOS 27.2 or later."
4. **The remaining tests (S-1…S-7) become a gate for Phase 5** (QA), using the same `spike/` kit. They must pass before any App Store claim about background counting.
