# FoldPulse — Risk Register & Issue Log

**Maintained by:** Agent 1 (PM), with input from all agents · **Version:** 1.0 · 9 November 2026

Severity: Critical · High · Medium · Low. Likelihood: H / M / L.

## 1. Risk register

| ID | Risk | Sev. | Lik. | Owner | Mitigation | Status |
|---|---|---|---|---|---|---|
| R-01 | **No macOS/Xcode or physical iPhone Duo is available to the team.** The cloud workspace runs Linux and cannot build or run iOS apps | Critical | H | Architect | Founder provides a Mac with Xcode 27.1+ and an iPhone Duo (or a macOS CI runner / Remote Control to the Founder's Mac) before Phase 3. All device claims stay "unverified" until then | **Open — Founder action** |
| R-02 | The Shortcuts automation asks for confirmation each run, or doesn't fire while locked → background counting impractical | High | M | Architect / Compliance | Validation spike step 3. Fallback: foreground + manual; revise marketing | Open |
| R-03 | Hinge callbacks fire on display/hierarchy moves → double counts | High | M | Engineer / Data Analyst | Edge-based commit vs. last committed state; 250 ms debounce; dedupe window | Designed – unverified |
| R-04 | Foreground hinge event + Shortcut event for the same physical fold → double count | High | H | Data Analyst | 3 s cross-source dedupe; keep `hinge` | Designed – unverified |
| R-05 | Established competitors (Duo Fold Counter, Fold Counter) reduce the market opportunity | High | H | PM / Founder Rep | Differentiate on transparency, widgets, setup UX, privacy. **Founder decision D-1** | Open — Founder decision |
| R-06 | App Review: app is mainly useful on iPhone Duo, and distribution can't be restricted (no hinge key in `UIRequiredDeviceCapabilities`; iPhone apps must run on iPad, 2.4.1) | Medium | M | Compliance | Manual-only mode with a notice on non-hinge devices; test on iPad; opt out of Mac | Open |
| R-07 | Widget reload budget exhausted by frequent background intent reloads → stale widgets | Medium | H | Performance | "As of" label; coalesce reloads (≥ 5 min apart from background); unbudgeted refresh when the app is foreground | Designed – unverified |
| R-08 | SwiftData + App Group + background intent concurrency issues | Medium | M | Architect | Single `ModelActor` writer in the app process; intents in the app target; widget reads only a JSON snapshot. Fallback Core Data | Open — verify in Phase 3 |
| R-09 | Users read FoldPulse as a measure of hinge wear/warranty | Medium | M | PM / Compliance | Copy review; disclaimer; no "health" scores | Designed – unverified |
| R-10 | Time-zone / DST errors in daily aggregates | Medium | M | Data Analyst | Store UTC instant + capture time-zone ID; bucket by `Calendar` in the capture zone; DST tests | Designed – unverified |
| R-11 | Data loss on delete/reinstall. Note: App Group data **is** included in iCloud/Finder device backups, so a restore from backup recovers it. Deleting the app does not | Low | M | Engineer / Privacy | Prominent export; disclose backup behaviour | Designed – unverified |
| R-12 | Malicious/corrupt JSON import | Medium | L | Privacy | Size cap (≤ 20 MB), schema validation, transactional import, no code paths that evaluate content | Designed – unverified |
| R-13 | Press-reported facts (iOS 27.2 trigger, StandBy on Duo, ±5° angle accuracy) are wrong or change | Medium | M | Compliance | Verify on the device during the spike; Apple primary docs take precedence | Open |
| R-14 | iPhone Duo StandBy behaviour unknown (pose / whether supported) | Low | M | Compliance | Spike step 5; widgets work regardless | Open |
| R-15 | SwiftUI `onHingeChange` signature unconfirmed | Low | L | Architect | **Resolved:** documented as `onHingeChange(isEnabled:_:)` with `DeviceHingeContext` | Closed |
| R-22 | Hinge status depends on **device orientation** as well as angle, so rotation could create spurious status changes | Medium | M | Architect / Data Analyst | Count only `closed` edges; rotation-only spike test | Designed – unverified |
| R-23 | App Review 4.3(b) (saturated category) / 2.3.1(a) (undisclosed features) | Medium | M | Compliance | Explain the differentiators in the review notes, with a demo video of the Shortcuts setup | Open |
| R-24 | Privacy policy URL required (5.1.1(i)) even when no data is collected | Medium | H | Compliance | Host a simple static privacy policy (Phase 6) | Open |
| R-25 | Any shortcut can call Record Fold, so `shortcut` events are not proof of a physical fold | Low | M | Privacy / Data Analyst | Label them "Shortcut"; the self-test verifies the automation; coverage metric | Designed – unverified |
| R-17 | Fold while locked: background intent cannot write if the store uses `Complete` file protection | Medium | M | Privacy / Architect | `CompleteUntilFirstUserAuthentication`; test in spike | Designed – unverified |
| R-18 | Widget "+ Fold" intent runs in the extension process → second database writer | Medium | M | Architect | Pending-events queue file drained by the app | Designed – unverified |
| R-19 | **Foreground fold may not be observable** if closing the phone backgrounds or locks the app before the `.closed` update arrives | High | M | Architect | Spike step 0 runs **before Phase 2**; re-scope if it fails | Open |
| R-20 | Overstating the count as "lifetime" or "trustworthy". The count starts at install and can be edited | Medium | M | PM / Compliance | Copy uses "since install"; source breakdown and coverage metric | Designed – unverified |
| R-21 | Late entry. Competitors (Duo Fold Counter ~#10 US Utilities on 2 Nov 2026; FoldMeter; Foldometer) are 2–3 months ahead | High | H | Founder Rep | Slim v1, ship fast, lead with the coverage/trust feature | Open — Founder decision |
| R-16 | Scope creep (Watch, sync, social) | Low | M | PM | MVP_SCOPE out-of-scope list; change-control via Founder | Controlled |

## 2. Issue log (Phase 1 agent reviews)

| ID | Description | Sev. | Raised by | Responsible | Proposed resolution | Status | Final decision |
|---|---|---|---|---|---|---|---|
| I-01 | The original brief's assumption that FoldPulse can "automatically count every fold" is false for background use | Critical | Architect | PM | Hybrid model; honest claim wording | Resolved | Adopted in PRD/feasibility |
| I-02 | No ability to compile or device-test in the current environment | Critical | Architect | Founder | See R-01 | Open | **Awaiting Founder** |
| I-03 | Competitors already exist | High | Founder Rep | PM | Differentiation plan PRD §4 | Open | **Awaiting Founder (D-1)** |
| I-04 | Should inferred events count toward totals? | Medium | Data Analyst | PM | Excluded by default; toggle | Proposed | Awaiting Founder (D-2) |
| I-05 | Storing DailyStatistics vs. computing them | Medium | Data Analyst | Architect | Compute from the event log; optional cache invalidated on edit | Resolved | Event log is authoritative |
| I-06 | "Cycle" definition was ambiguous in the brief | Medium | Data Analyst | Data Analyst | Unfold→next fold, both non-inferred | Resolved | Adopted |
| I-07 | Milestone notifications require a permission prompt | Low | Founder Rep | UX | Opt-in only | Resolved | Adopted |
| I-08 | Widget count (6 variants) is heavy for v1 | Low | Founder Rep | PM | Tiered Must/Should | Resolved | Adopted |
| I-09 | Press sources could not be fetched directly (network policy); relied on search summaries | Medium | Independent Reviewer | Architect | Confidence downgraded to Medium; device verification | Resolved (documented) | Accepted |
| I-10 | Local notifications for milestones are local only — confirm that no APNs entitlement is needed | Low | Privacy | Privacy | Use `UNUserNotificationCenter` local only; no push entitlement | Resolved | Adopted |
| I-11 | SwiftUI hinge API was missed in the first research pass (wrong URL) | Medium | Compliance | Architect | Verified and documented | Resolved | Adopted |
| I-12 | Widget button intent runs in the extension process; inactive while locked | High | Compliance | Architect | Queue file; widget button is unlocked-only and Should, not Must | Resolved in design | Adopted |
| I-13 | Missing privacy manifest, privacy policy URL, iCloud Backup disclosure, CSV injection, export sensitivity | High | Privacy | Privacy | See PRIVACY_REVIEW.md | Resolved in design | Adopted |
| I-14 | Inferred-event rule contradicted itself; resume could create a fake unfold; dedupe was one-directional | Critical | Data Analyst / Independent Reviewer | Data Analyst | Rules rewritten (feasibility §5–§6) | Resolved | Adopted |
| I-15 | Phase 1 was marked "Complete" before the reviews happened | High | Independent Reviewer | PM | Status → "pending Founder review" | Resolved | Adopted |
| I-16 | Core assumption (foreground fold observable) is tested too late | High | Independent Reviewer | Architect | Spike moved to Phase 1b, before design | Proposed | Awaiting Founder |
| I-17 | Project docs live in a repository named "Church-Deacon-Election" | Low | Independent Reviewer | Founder | Move to a dedicated FoldPulse repository before Phase 3 | Open | Awaiting Founder |


