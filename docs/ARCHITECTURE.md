# FoldPulse — Architecture

**Owner:** Agent 3 — Senior iOS Technical Architect · **Reviewed by:** Agent 6 (Software Engineer), Agent 11 (Performance), Agent 8 (Privacy), Agent 12 (Independent)
**Version:** 1.1 (revised after agent reviews) · 9 November 2026 · **Phase:** 3 (foundation)

---

## 1. Principles

1. **The event log is the source of truth.** Every number is computed from it, and nothing derived is stored as authoritative (T-1).
2. **Pure domain logic lives in its own package** (`FoldPulseCore`). It has no UIKit, SwiftUI or SwiftData, so it is deterministic and testable on Linux and macOS.
3. **One database writer.** All persistence goes through the `EventStore` actor (T-2).
4. **Local only.** There is no networking code; CloudKit is explicitly off (T-3).
5. **Widgets never open the database.** They read a small JSON snapshot (WIDGET_DESIGN §2).
6. **System components first.** `TabView`, `List`, `Chart` and `Gauge` let the system handle iPhone Duo layouts, Liquid Glass and accessibility.
7. **Swift 6 with complete strict concurrency** in every target.

## 2. Module structure

```
FoldPulse (repo)
├── project.yml                  XcodeGen spec → FoldPulse.xcodeproj (generated, not committed)
├── Packages/FoldPulseCore/      Swift package — domain logic (pure Swift)
│   ├── Sources/FoldPulseCore/   FoldEvent, EventKinds, LocalDay, Statistics, Milestones, WidgetSnapshot
│   └── Tests/                   XCTest — runs on Linux and macOS
├── Shared/                      compiled into BOTH app and widget
│   ├── Storage/                 AppGroup (paths), SnapshotFile (read/write + file protection)
│   └── DesignSystem/            Tokens (colours, spacing, radii), PulseLine
├── FoldPulse/                   app target
│   ├── App/                     FoldPulseApp (entry), RootView (tabs), AppModel (state)
│   ├── Core/Persistence/        SchemaV1 (@Model), mapping, PersistenceController, EventStore (@ModelActor)
│   ├── Core/Services/           SnapshotService (widget snapshot + reload policy)
│   ├── DesignSystem/            Typography, components (HeroCounter, StatTile, SourceBadge, …)
│   ├── Features/                Today · History · Insights · Settings
│   └── Resources/               Assets (icon, accent), PrivacyInfo.xcprivacy, entitlements
├── FoldPulseWidgets/            widget extension (TodayWidget: small, circular, rectangular)
├── FoldPulseTests/              app unit tests (in-memory SwiftData)
├── FoldPulseUITests/            UI smoke tests
├── scripts/setup_mac.sh         one-line developer setup
└── .github/workflows/ci.yml     CI: Linux core tests + macOS build & tests
```

Dependency rule: **Features → AppModel → EventStore / SnapshotService → FoldPulseCore**. Shared depends only on FoldPulseCore and Apple frameworks. The widget depends on Shared + FoldPulseCore, never on app code.

## 3. Targets and capabilities

| Target | Type | Bundle ID | Capabilities |
|---|---|---|---|
| FoldPulse | iOS app (iPhone) | `io.github.odthientho.foldpulse` | App Group `group.io.github.odthientho.foldpulse` |
| FoldPulseWidgets | WidgetKit extension | `…foldpulse.widgets` | Same App Group |
| FoldPulseTests | Unit tests | `…foldpulse.tests` | — |
| FoldPulseUITests | UI tests | `…foldpulse.uitests` | — |

Deployment target **iOS 27.1** (D-3). Mac ("Designed for iPhone") and visionOS availability are **off** (R-06). Category: Utilities (R-27).

## 4. Data flow

```
[Phase 4] Hinge observer (onHingeChange, foreground) ─┐
[Phase 4] App Intents (Shortcuts automation, bg)  ────┤
[Phase 4] Record sheet (manual)                   ────┼─► [Phase 4] EventPipeline (FoldPulseCore:
[Phase 4] Widget "+" (v1.1) → queue file          ────┘     debounce · baseline · dedupe · reconcile)
                                                                 │
                                                                 ▼
                                              EventStore (@ModelActor, single writer)
                                                                 │  SwiftData (SQLite) in App Group
                                                                 ▼
                                              AppModel.reload()  (MainActor, @Observable)
                                                ├─► Features (Today, History, …) compute stats via FoldPulseCore
                                                └─► SnapshotService → WidgetSnapshot.json → WidgetKit reload (throttled)
                                                                                     │
                                                       TodayWidget ◄──────────────────┘ (timeline: now + next midnight)
```

The diagram for the PDF is Figure 2 of the Phase 3 report.

## 5. Concurrency model

| Component | Isolation | Notes |
|---|---|---|
| SwiftUI views, `AppModel`, `SnapshotService` | `@MainActor` | `AppModel` is `@Observable` and injected with `.environment` |
| `EventStore` | `@ModelActor` (its own serial executor), **created on a detached task** so its context isn't bound to the main thread | Exchanges only `Sendable` values (`FoldEvent`, `LoadedState`); computes `DashboardStats` itself, so statistics never run on the main thread |
| `FoldPulseCore` | Non-isolated, pure value types | All types `Sendable` |
| Widget provider | WidgetKit-managed | Reads a file; no shared mutable state |

## 6. Persistence

See **DATABASE_DESIGN.md**. In summary:
- SwiftData `SchemaV1.StoredEvent` with a `SchemaMigrationPlan` from day one.
- The store file lives in the App Group container.
- Rows are tombstoned instead of deleted.
- File protection is `completeUntilFirstUserAuthentication`, **set explicitly** on the store directory, so background writes work while the phone is locked.
- Release builds never fall back to a private location if the App Group is missing; they show a clear error instead.

## 7. Widget pipeline

- `SnapshotService.publish` writes the precomputed `WidgetSnapshot` atomically and calls `WidgetCenter.reloadTimelines(ofKind:)`. That reload is immediate when the app is active. From the background it is coalesced to at most one per 5 minutes; the last-reload time is kept in the **App Group defaults**, so the throttle holds across short-lived intent processes.
- The `TodayWidget` timeline has up to three entries: now; the moment the data turns **stale** (shows "as of HH:mm"); and the **next local midnight** ("today" shows "—" until refreshed). The widget also re-reads the snapshot **every 30 minutes**, so a reload the app throttled is never lost.

## 8. Testing strategy

| Layer | Framework | Where it runs | Phase 3 coverage |
|---|---|---|---|
| Domain (`FoldPulseCore`) | XCTest via `swift test` | **CI Linux + CI macOS** | LocalDay (DST, travel, leap year, ranges), totals (gaps, tombstones, duplicates), averages (full days, zero days, window cap), coverage, busiest day, milestones (fire once), snapshot (encoding, schema guard, midnight, staleness) |
| Persistence & services | XCTest, in-memory SwiftData | CI macOS (simulator) | Field-preserving round trip, ordering, update, tombstone, not-found, delete-all, snapshot write and reload throttling |
| UI | XCUITest | CI macOS (simulator) | Launch into Today (empty state), all four tabs reachable |
| On device | Manual | Founder's Mac + iPhone Duo | Sample week via the debug-only Settings action |

## 9. Build and run

- **Mac:** `curl -fsSL https://raw.githubusercontent.com/odthientho/FoldPulse/main/scripts/setup_mac.sh | bash`, then choose a Team for both targets and press Run.
- **CI:** every push to `main` runs `.github/workflows/ci.yml`.
  - On Linux: core tests in the `swift:6.1` container.
  - On macOS: the newest Xcode; core tests, then XcodeGen, then `xcodebuild test` on a simulator.
  - If the runner's iOS SDK is older than 27.1, CI lowers the deployment target in `project.yml` **for CI only** and says so in the job summary. GitHub's runners currently have the **iOS 26.5 SDK**. Phase 3 code uses no iOS 27-only API, so build and tests are meaningful there. From Phase 4, hinge code needs the 27.1 SDK; it will be compiled conditionally or verified on the Founder's Mac.
  - A **privacy guard** fails the build if networking symbols appear in shipping Swift code (PRIVACY_REVIEW P-1).

## 10. Phase 4 extension points

| Feature | Where it goes |
|---|---|
| Event pipeline (debounce, baseline, symmetric dedupe ±10 s, gap reconciliation) | `FoldPulseCore/Pipeline` — pure, unit-tested on Linux |
| Hinge observer | `FoldPulse/Core/Services/HingeObserver` (one per process, foreground scene only) |
| App Intents (Record Fold/Unfold, `.background`) | App target, writing through `EventStore` |
| Manual record / Undo, History edit/delete, Insights, Coverage, Setup + self-test, Export, Reset, Milestones, Onboarding | `Features/*` |

## 11. Known limitations and open items

| ID | Item | Plan |
|---|---|---|
| I-24 | Inner-display tab bar position when partially folded | Check in Xcode 27.1 Device Hub on the Founder's Mac (CI runners may not have the iPhone Duo simulator) |
| R-29 | **App Groups may need a paid Apple Developer Program membership** for device installs (free personal teams have restricted capabilities) | If signing fails on the Founder's Mac, either join the Program ($99/year, also required for App Store release) or temporarily remove the App Group (widgets then show the empty state) |
| R-01 | No iPhone Duo in CI | On-device checks stay with the Founder |
