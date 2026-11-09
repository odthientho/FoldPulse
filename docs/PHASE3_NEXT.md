## Decisions requested

| # | Decision | Team recommendation |
|---|---|---|
| **A-3** | **Approve Phase 3** (architecture, project foundation, data layer, design system in code, tests and CI) | Approve |
| R-29 | Apple Developer Program membership ($99/year): needed for App Store release, and probably for App Groups on your device | Join before Phase 4 device testing, or at the latest before Phase 6 |
| R-28 | Run the 10-minute background-automation check on iOS 27.2 before pricing | Strongly recommended (carried over from Phase 2) |

## Optional now: try the foundation on your iPhone Duo

1. Run the one-line setup in Terminal:
   `curl -fsSL https://raw.githubusercontent.com/odthientho/FoldPulse/main/scripts/setup_mac.sh | bash`
2. In Xcode, choose your Team for **FoldPulse** and **FoldPulseWidgets**, select your iPhone Duo, and press ▶.
3. In the app: **Settings → Insert sample week**. Today, History and the widget then show the design with sample data.
4. **I-24:** also check the inner-display tab bar with the phone half folded.

## Phase 4 — MVP development (after approval)

Features are built one at a time, each with a plan, implementation, tests, CI and review:
1. **Event pipeline** in FoldPulseCore: debounce, baseline-on-activation, symmetric de-duplication (±10 s) and gap reconciliation, all unit-tested on Linux.
2. **Automatic counting:** one device-level `onHingeChange` observer.
3. **Manual recording** with Undo.
4. **App Intents** (Record Fold / Unfold, background) and the guided Shortcuts setup with self-test.
5. **History:** filters, edit, delete.
6. **Insights:** D/W/M/Y, averages, busiest day.
7. **Coverage** detail.
8. **Milestones**, celebrated once.
9. **Widgets** final polish.
10. **Settings:** export (CSV/JSON) and reset.
11. **Onboarding**, manual-only mode, accessibility pass.

Deliverables: `phase-04-development.pdf`, `DEVELOPMENT_LOG.md`, an updated ARCHITECTURE.md and test results.
