# FoldPulse — Every Fold. Every Beat.

A privacy-first iPhone Duo app that counts, records and analyses folds and unfolds. All data stays on the device.

**Current status:** Phases 1–2 approved. Phase 3 (Architecture & Foundation) is ready for Founder review: a buildable Xcode project (generated from `project.yml`), with 43 automated tests passing in CI.

**Build it on a Mac:** `curl -fsSL https://raw.githubusercontent.com/odthientho/FoldPulse/main/scripts/setup_mac.sh | bash`

| Path | Contents |
|---|---|
| `docs/phase-01-feasibility.pdf` | Phase 1 report: findings, agent reviews, recommendation (CONDITIONAL GO) |
| `docs/TECHNICAL_FEASIBILITY.md` | Hinge API / Shortcuts / WidgetKit research and feasibility matrix |
| `docs/PRD.md`, `docs/MVP_SCOPE.md` | Product requirements, user stories, MVP scope |
| `docs/RISK_REGISTER.md` | Risks and the agent-review issue log |
| `docs/PRIVACY_REVIEW.md` | Local-only privacy and security review |
| `docs/ROADMAP.md` | Six-phase roadmap with approval gates |
| `docs/phase-02-design.pdf` | Phase 2 design report: icon, design system, 24 mockups, flows, widgets, reviews |
| `docs/DESIGN_SYSTEM.md`, `SCREEN_SPECIFICATIONS.md`, `USER_FLOWS.md`, `WIDGET_DESIGN.md` | Phase 2 design documents |
| `design/` | Mockups (HTML → PNG), flows (SVG), app icon (SVG/PNG), contrast check |
| `docs/phase-03-architecture.pdf` | Phase 3 report: architecture, database, code, CI results, reviews |
| `docs/ARCHITECTURE.md`, `DATABASE_DESIGN.md`, `BUILD_VERIFICATION.md` | Phase 3 documents |
| `FoldPulse/`, `FoldPulseWidgets/`, `Shared/`, `Packages/FoldPulseCore/` | App, widget extension, shared code, domain package |
| `FoldPulseTests/`, `FoldPulseUITests/`, `.github/workflows/ci.yml` | Tests and CI |
| `tools/pdf/` | Reproducible PDF build (`python3 tools/pdf/build_phase1.py`, `build_phase2.py`; needs pandoc, Node Playwright + Chromium, pypdf) |
