# FoldPulse — Roadmap

**Owner:** Agent 1 — Chief Product Manager · **Version:** 1.0 · 9 November 2026

Every phase ends with a PDF report and an explicit Founder approval gate.

| Phase | Objective | Key outputs | Prerequisites | Status |
|---|---|---|---|---|
| **1 — Research & Feasibility** | Verify what's possible; define the MVP | Feasibility report, PRD, MVP scope, risks, roadmap, `phase-01-feasibility.pdf` | — | **Approved 2026-11-09** |
| **1b — Device validation spike** (recommended) | Prove on a real iPhone Duo: foreground fold observed; Shortcuts automation runs while locked without prompt | Spike report appended to the feasibility report | Founder's Mac with Xcode 27.1 + iPhone Duo (R-01) | **Closed early** (Founder decision C-2r; see SPIKE_RESULTS.md) |
| 2 — Brand, UI/UX & Design | Visual identity, icon, screens, widgets, accessibility | Design system, screen specs, flows, widget design, mockups, `phase-02-design.pdf` | Phase 1 approval; C-2r | **Approved 2026-11-09** |
| 3 — Architecture & Foundation | Xcode project, data layer, design system in code, tests | Architecture, decisions, DB design, buildable project, `phase-03-architecture.pdf` | Phase 2 approval; **Mac + Xcode 27.1 + iPhone Duo access (R-01)** | **Deliverables ready — pending Founder review** (CI green, run #5) |
| 4 — MVP Development | Implement F1–F14 incrementally | Source, dev log, test results, `phase-04-development.pdf` | Phase 3 approval | Not started |
| 5 — QA & Validation | Functional, data, widget, privacy, performance testing; **re-run spike criteria S-1…S-7 on device** | Test plan/results, bugs, reviews, `phase-05-testing.pdf` | Phase 4 approval | Not started |
| 6 — Release Preparation | App Store assets, privacy disclosure, final build | Store copy, checklist, disclosure, `phase-06-release.pdf` | Phase 5 approval | Not started |

## Post-MVP candidates (not committed)

| Version | Candidates |
|---|---|
| v1.1 | Control Center control ("Record Fold"), localization, posture-time analytics (partially-open "tent" time) if foreground data proves useful |
| v1.2 | Optional user-initiated encrypted backup file; yearly "Fold Wrapped" summary (on device) |
| Later (requires Founder privacy review) | Optional iCloud sync; Apple Watch glance |
