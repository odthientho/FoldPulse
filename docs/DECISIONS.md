# FoldPulse — Decision Log

Product and technical decisions, newest first. Only the Founder makes product decisions. Changes to an approved decision require a new entry.

| ID | Date | Decision | Decided by | Context / consequence |
|---|---|---|---|---|
| A-1 | 2026-11-09 | **Phase 1 approved** (feasibility report + documents) | Founder | Recommendation CONDITIONAL GO accepted |
| C-2 | 2026-11-09 | **Run the device validation spike (Phase 1b) before Phase 2** | Founder | Phase 2 starts after spike results are reviewed. Kit: `docs/SPIKE_PLAN.md`, `spike/` |
| C-1 | 2026-11-09 | Founder provides a **Mac with Xcode 27.1+ and an iPhone Duo** | Founder | Resolves R-01 for the spike. CI for later phases is still to be decided in Phase 3 |
| D-5 | 2026-11-09 | **Business model: paid up front** (one-time download price, no in-app purchases) | Founder | Design needs no paywall, tip or upgrade surfaces. StoreKit is not needed. Pricing is set in Phase 6. New risk R-26 (paid vs. free competitors) |
| D-1 | 2026-11-09 | **Build FoldPulse despite existing fold counters**; compete on trust (coverage indicator), widgets and polish | Founder (accepted team default) | R-05/R-21 remain as tracked risks |
| D-2 | 2026-11-09 | **Inferred (gap) events excluded** from headline totals by default | Founder (default) | Shown in History with explanation |
| D-3 | 2026-11-09 | **Minimum iOS 27.1**, iPhone Duo-focused | Founder (default) | Background assisted mode needs iOS 27.2+ on the device |
| D-4 | 2026-11-09 | **Manual-only mode with a notice** on non-hinge iPhones and iPads | Founder (default) | Addresses App Review 2.4.1 |
| D-6 | 2026-11-09 | **Lean v1** (MVP_SCOPE §4.1) | Founder (default) | Medium/Large/inline widgets, heat strip, session stats, inferred toggle and JSON import (pending backup check) move to v1.1 |
| I-17 | 2026-11-09 | **Move FoldPulse to its own GitHub repository** | Founder (default) | Done: `odthientho/FoldPulse` (`main`). Repo is currently **public**; the Founder decides on visibility |
| T-1 | 2026-11-09 | Event log is the source of truth; aggregates are computed/cached | Architect (Phase 1) | See TECHNICAL_FEASIBILITY §6–§7 |
| T-2 | 2026-11-09 | SwiftData in the App Group, single writer in the app process; widget writes via a queue file | Architect (Phase 1) | Confirmed or replaced in Phase 3 |
| T-3 | 2026-11-09 | No networking code, no third-party SDKs | Privacy (Phase 1) | PRIVACY_REVIEW P-1 |
