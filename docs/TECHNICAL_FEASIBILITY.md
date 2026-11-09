# FoldPulse — Technical Feasibility Report

**Phase:** 1 — Product Research and Feasibility
**Owner:** Agent 3 — Senior iOS Technical Architect
**Independent verification:** Agent 10 — Apple Platform Compliance Specialist
**Version:** 1.0 · 9 November 2026
**Status:** Submitted for Founder review

---

## 1. Summary

**Short answer: yes, FoldPulse can count folds on iPhone Duo using public Apple APIs. It can count every fold automatically only while the app is on screen. Counting while the app is closed depends on a user-configured Shortcuts automation.**

The research found three public, documented mechanisms. Together they make a credible product:

1. **Hinge API (iOS 27.1 SDK)** — `UIHingeInteraction` (UIKit) and `onHingeChange` (SwiftUI) report a discrete hinge **status** (`closed`, `partiallyOpen`, `fullyOpen`, `unknown`) and a continuous **angle** in radians. These APIs are tied to a *view hierarchy*. They deliver updates only while FoldPulse's UI is live. They do **not** deliver events while the app is in the background or terminated.
2. **Shortcuts "Opened or Closed" automation trigger (iOS 27.2 system feature)** — Shortcuts can run a personal automation when iPhone Duo is opened, closed, or either. FoldPulse can expose App Intents ("Record Fold", "Record Unfold") that the automation calls. App Intents can run **in the background** (`supportedModes = [.background]`) without bringing the app forward. This is the only public route found to background counting. It requires a one-time setup by the user.
3. **Manual recording** — always available as a fallback and as a correction tool.

There is **no public API that lets a third-party app subscribe to hinge events in the background** without the user's Shortcuts automation. Nothing suggests one is coming. Core Motion, `UIDevice` and `BackgroundTasks` expose no hinge state.

**Architect recommendation:** CONDITIONAL GO. Build a *hybrid tracker*: automatic counting in the foreground, assisted counting in the background via Shortcuts, and manual recording. Label every event with its source.

> **Honesty constraint:** FoldPulse must not claim to "automatically count every fold." The accurate claim is: *"Counts folds automatically while open, and in the background once you add the FoldPulse automation in Shortcuts."*

---

## 2. Target device — iPhone Duo

| Item | Finding | Source | Confidence |
|---|---|---|---|
| Device exists and is on sale | Announced 9 Sep 2026; on sale 23 Oct 2026 | MacRumors roundup; Apple Newsroom (Oct 2026) | High |
| Displays | 5.4" outer (cover) display, 7.6" inner display | MacRumors; Digital Trends | Medium (press, not Apple spec sheet) |
| Shipping OS | iOS 27.1. iOS 27.2 released 26 Oct 2026 | MacRumors iOS 27.2 coverage | High |
| Content moves between displays when opening/closing | "As iPhone Duo is opened, closed, partially folded, and rotated, content transitions between displays" | Apple — *Preparing your app for iPhone Duo* | High (Apple primary) |
| Simulator support | Xcode 27.1 Device Hub can open, close, fold and rotate a simulated iPhone Duo | 9to5Mac / Apple developer coverage | Medium |

**Implication:** a foreground FoldPulse app keeps running as the device folds; its scene moves to the outer display. It can therefore observe the fold transition itself, not just the next unfold. This needs confirmation on a physical device (see §9, Validation spike).

---

## 3. API investigation

### 3.1 Hinge APIs — `UIHinge`, `UIHingeInteraction`, `onHingeChange`

**Apple documentation (verified directly from developer.apple.com, 9 Nov 2026):**

- `UIHingeInteraction` — "An interaction for observing the hinge state associated with the view's hierarchy." Available **iOS 27.1+**. Created with `init(updateHandler:)`; has `isEnabled`.
- "The interaction's handler is called when the hinge state changes, or when the interaction moves between hierarchies. When the interaction moves out of a hierarchy that provides hinge updates, the update's `hinge` is nil."
- `UIHinge` — "An object encapsulating the state of a single hinge." Properties: `angle` ("The current angle of the hinge, in radians") and `status`.
- `UIHinge.Status` — `closed` ("The hinge is closed"), `partiallyOpen`, `fullyOpen` ("open as far as the device allows"), `unknown`.
- UIKit's `Update` carries only `hinge`: no previous value and no timestamp. FoldPulse keeps its own last state and timestamps.
- On `angle`: "The rate and granularity of angle updates are system policy and can change based on system state, so don't depend on a particular update frequency or precision. If you only need to know whether the hinge is closed, partially open, or fully open, prefer `status` over the angle."

**Apple Tech Talk 111464 (iPhone Duo):** "SwiftUI provides a new onHingeChange modifier, and UIKit provides UIHingeInteraction. Both give you access to the high-level hinge status… Beyond the discrete status, it provides continuous updates of the hinge angle." The handler receives `(previous, current)` contexts, and "A null value indicates the app is running on a device without a hinge." Apple: "Hinge data is observed live, and is ideal for driving interactions or effects. For layout, use the arrangement and region APIs."

**Architect's analysis:**

- The API is attached to a **view in a live hierarchy**, not to the device or the process. No delegate, notification or background mode is documented. **Background delivery: not supported** (high confidence, by design).
- `status` is the right signal for counting: a fold is a transition into `.closed`, and an unfold is a transition out of `.closed`. The angle is useful only for optional visual effects, and it is not reliable enough for metrics (Apple explicitly declines to guarantee rate or precision; press reports roughly ±5° accuracy).
- The handler fires on *hierarchy moves* too. Moving between displays can therefore produce updates that are not physical hinge changes. Counting must be **edge-based** (state changed vs. last committed state) and **debounced**.
- `.unknown` must never be counted as a fold or unfold.

**SwiftUI (verified in Apple docs after the Compliance review):** `onHingeChange(isEnabled:_:)` — "Adds an action to perform when the hinge context of the view hierarchy changes." The closure receives `(DeviceHingeContext, DeviceHingeContext)` (old, new). `DeviceHingeContext.hinge` is an optional `DeviceHinge` with `angle` and `status`. `DeviceHinge.Status` is a **struct** with `closed`, `partiallyOpen` and `fullyOpen`. It has no `unknown`, so code must handle unrecognised values defensively.

**Important nuance:** Apple says the status is "determined by the system based on the current angle **and device orientation**". Rotating the phone could therefore change the status (most likely between `partiallyOpen` and `fullyOpen`) without any fold. FoldPulse counts only edges into and out of `closed`, which limits the exposure. The spike adds rotation-only tests to confirm that rotation never produces a `closed` edge.

### 3.2 Shortcuts "Opened or Closed" automation + App Intents

- iOS 27.2 adds a Shortcuts personal-automation trigger, "**When my iPhone is opened or closed**" (Display section; options: Opened / Closed / Either). It is exclusive to iPhone Duo. (9to5Mac, 29 Oct 2026; MacRumors, 25–26 Oct 2026.)
- Third-party apps cannot create automations themselves. The **user** creates the automation and picks an action. FoldPulse can provide **App Intents** (`RecordFoldIntent`, `RecordUnfoldIntent`) that appear as Shortcuts actions. It can also provide an **App Shortcut** that guides setup.
- App Intents can run without UI: Apple's `supportedModes` documentation says "Specify `background` to run the action entirely in the background."
- **Market evidence:** an existing App Store app, *Duo Fold Counter*, describes exactly this mechanism ("Count Fold"/"Count Unfold" actions on the Opened or Closed trigger, "even when the app isn't running"). That indicates the approach works and passes App Review. It is also a **competitive signal** (see PRD §4).

**Open questions (require device validation):**

| Question | Why it matters |
|---|---|
| Can the automation run immediately with no confirmation banner/tap? | If it asks every time, background counting is impractical |
| Latency and reliability under Low Power Mode, Focus, locked device | Missed folds = wrong totals |
| Does it fire when the device is folded while locked or on the Lock Screen? | Many folds happen while locked |
| Does it fire alongside the foreground hinge observer (double count)? | Requires de-duplication (see §6) |
| Is a timestamp passed, or must we use "now" at intent execution? | Accuracy of the event time |

### 3.3 Other frameworks examined

| Framework | Hinge/fold data? | Conclusion |
|---|---|---|
| Core Motion (`CMMotionManager`, device motion) | No hinge or posture API documented. Accelerometer/gyroscope only describe the whole device | Not usable. Inferring folds from motion would be unreliable and battery-heavy. Rejected |
| `UIDevice` | Orientation, battery, model — no hinge state documented | Not usable |
| `BackgroundTasks` (`BGAppRefreshTask`, `BGProcessingTask`) | Opportunistic, system-scheduled; no event triggers | Cannot capture events. May be used only for maintenance |
| SwiftUI reserved regions / `ArrangementView` | Geometry of the fold region for layout | For layout only; not an event source |
| SceneKit / ARKit | No hinge data | Not relevant |
| Private APIs / SpringBoard / IOKit | Possibly | **Forbidden** — App Store rejection, policy violation |

### 3.4 Widgets (WidgetKit)

Verified from Apple's *Keeping a widget up to date*:

- Widgets are rendered by the system in a separate process. "Your widget extension is not continually active, even if the widget is onscreen."
- Budget: "For a widget the user frequently views, a daily budget typically includes from 40 to 70 refreshes… roughly… every 15 to 60 minutes."
- Reloads **don't count against the budget** when "the widget's containing app is in the foreground" or "the widget performs an app intent."
- "In StandBy, the system refreshes your widget's display at a system-defined rate that doesn't count against its budget."
- Timeline entries should be "at least about 5 minutes apart."

Families available on iOS: `systemSmall`, `systemMedium`, `systemLarge` (Home Screen); `accessoryCircular`, `accessoryRectangular`, `accessoryInline` (Lock Screen). `systemSmall` widgets appear in StandBy.

**Implications:**

- Each app-recorded event calls `WidgetCenter.reloadTimelines(ofKind:)`. That reload is free when the app is in the foreground and budgeted when it runs from a background intent. With heavy use (Duo owners may fold 50–150+ times a day), **background-intent reloads can exhaust the budget**. Widgets must therefore show an "as of" time and must never imply live data.
- The widget extension reads a small precomputed **snapshot** from the App Group container. It does not run analytics queries (widget memory limits are tight).

### 3.5 Lock Screen and StandBy

- Lock Screen accessory widgets: supported (circular gauge toward the next milestone, rectangular "Today · Lifetime", inline "38 folds today").
- StandBy shows Home Screen `systemSmall` widgets when an iPhone is charging, locked and on its side. **Unverified:** whether, and in which pose (closed or open), iPhone Duo enters StandBy. That is a device-validation item. FoldPulse supplies widgets that work well in StandBy. It does **not** and cannot replace the StandBy interface.

---

## 4. Feasibility matrix

| Capability | Public API available? | Foreground | Background | Confidence | Evidence |
|---|---|---|---|---|---|
| Detect fold | **Yes** — hinge status transition to `.closed` (iOS 27.1) | **Yes** (automatic) | **Only via user-created Shortcuts automation** (iOS 27.2) | High (fg) / Medium (bg) | Apple UIHinge docs; Tech Talk 111464; 9to5Mac/MacRumors on the 27.2 trigger; Duo Fold Counter listing |
| Detect unfold | **Yes** — transition out of `.closed` | **Yes** (automatic) | **Only via Shortcuts automation** | High / Medium | Same |
| Read hinge angle | **Yes** — `UIHinge.angle` (radians) | Yes; rate/precision not guaranteed | **No** | High | Apple `angle` docs |
| Detect partially-open (tent/laptop) pose | Yes — `.partiallyOpen` | Yes | No | High | Apple `UIHinge.Status` |
| Update widgets | Yes — WidgetKit + App Group | Yes, unbudgeted while app foreground | Yes, budgeted (≈40–70/day) | High | Apple WidgetKit docs |
| Lock Screen widget | Yes — accessory families | n/a (system-rendered) | Shows last snapshot | High | Apple `WidgetFamily` |
| StandBy widget | Yes — `systemSmall` in StandBy | n/a | System-defined refresh rate | Medium (Duo-specific StandBy behaviour unverified) | Apple WidgetKit docs |
| Shortcuts / App Intents logging | Yes — App Intents with `.background` mode | Yes | Yes | Medium–High | Apple `supportedModes` docs |
| Interactive widget "+1" button | Yes — `Button(intent:)` in widget (iOS 17+). Runs **in the widget extension process** by default. **Inactive on a locked device** | n/a | Yes (unlocked only) | High | Apple *Adding interactivity to widgets* |
| Infer folds via Core Motion | No hinge API | — | — | High (rejected) | Apple Core Motion docs |

---

## 5. Recommended tracking model

**Sources** (stored on every event, always shown in the UI):

| Source | How | When | Trust |
|---|---|---|---|
| `hinge` (Automatic) | `onHingeChange` status edges | App on screen | Highest |
| `shortcut` (Assisted) | App Intent called by the Opened or Closed automation | App in background or not running | High (once validated) |
| `manual` | User taps Record Fold / Record Unfold, or a widget/Control button | Any time | User-asserted |
| `inferred` | Gap reconciliation. Fold and unfold must alternate, so **two consecutive events of the same type** (e.g. fold, fold) prove that one opposite event was missed. An `inferred` event of the missing type is created with an **uncertainty interval** `[previous event, next event]` rather than a precise time | On reconciliation (app activation, after import/edit) | Low. Shown in History with an explanation. Excluded from time-of-day, session and duration statistics. Excluded from headline totals by default (user toggle; Founder decision D-2) |

**Device-level observer.** Exactly **one** hinge observer runs per process, attached to the active scene's root view. If the app shows windows on both displays, only the scene that is foreground-active may commit events. This prevents per-scene double counting.

**`nil` hinge has two meanings.** Apple: `hinge` is nil "when the interaction leaves a hierarchy that provides hinge updates", and Tech Talk 111464 says it is nil "on a device without a hinge". FoldPulse treats `nil` as **"no reading right now"**, never as "not an iPhone Duo". Whether the device is hinged is decided once, from the first non-nil reading ever received (persisted). Until then the app shows a neutral "Waiting for hinge…" state, not the manual-only mode.

---

## 6. Event correctness rules (revised after Data Analyst & Independent Reviewer review)

**Definitions**

- **Fold** = committed transition of hinge status from `.partiallyOpen`/`.fullyOpen` to `.closed`.
- **Unfold** = committed transition from `.closed` to `.partiallyOpen` or `.fullyOpen`.
- `.partiallyOpen ↔ .fullyOpen` transitions are **not** folds. They are not stored in the MVP.
- `.unknown` and `nil` never create events and never change the committed baseline.

**Timing**

- **Debounce:** a candidate status is committed once it has been stable for ≥ 250 ms (tuned in the spike). The event's `timestamp` is the moment the status was **first entered**, not the commit moment.
- **Flush on lifecycle change:** if the scene phase changes (for example, closing the phone sends the app to the background) while a candidate is pending, the candidate is committed immediately if it is not `.unknown`. This prevents a lost fold at the moment of closing.

**Baseline on activation (prevents false events)**

- The **first** reading after launch, after scene activation, or after a `nil` period only **sets the baseline**. It never creates a `hinge` event by itself.
- If that baseline contradicts the last stored event (e.g. last stored = fold, baseline = open), FoldPulse first tries to match a `shortcut` unfold that arrived in the meantime. If there is none, reconciliation records an `inferred` unfold covering the gap.

**De-duplication (symmetric pairing)**

- Two events are duplicates when they have the **same type**, there is **no opposite-type event between them**, and |Δt| ≤ **10 s**, in **either order** (a Shortcut may run before or after the debounced hinge commit, and it may lag while locked).
- Precedence when merging: `hinge` > `shortcut` > `manual` (including the widget button) > `inferred`. The kept event takes the timestamp of the highest-precedence source. The dropped event is retained as a hidden `duplicateOf` record for diagnostics and a "coverage" metric.
- Pairing is one-to-one: each event can absorb at most one duplicate per other source.

**Derived metrics**

- **Headline "Folds"** = fold events from `hinge` + `shortcut` + `manual` (+ `inferred` only if the user enables it). Shown as **"since install / since tracking began"**, never as the device's true lifetime.
- **Cycle / open session** = an unfold followed by the next fold, both non-inferred. A session is assigned to the local day it **started**. Sessions > 12 h are treated as missing data and excluded from duration statistics.
- **Coverage** (trust metric) = share of automatically captured folds this week (`hinge` + `shortcut`) out of all folds. Also the share of `shortcut` events whose automation self-test passed.
- **Averages** use **complete local days** from the first tracked day to **yesterday**, including zero days. The current partial day is excluded.

**Time and time zones**

- Store: `timestamp` (UTC instant), `timeZoneID` at capture and `localDate` (YYYY-MM-DD at capture). Daily buckets use the stored `localDate`; History sorts by UTC.
- Travel can make a local date appear twice or a day last 23 or 25 hours. Daily totals simply sum events by `localDate`. The time-of-day chart normalises each hour by the number of times that hour occurred, which handles the DST fall-back hour that happens twice.
- Weeks start on the user's locale `firstWeekday`.
- Editing an event's time keeps its original `timeZoneID`.

**Edits, deletes and import**

- Every event has `updatedAt`. Deletes leave a **tombstone** (`deletedAt`), so an import can't bring deleted events back.
- Import merges by `id`: the newer `updatedAt` wins, and tombstones win over older live copies.
- After any edit, delete or import, the reconciliation pass (alternation → dedupe → inferred → cycles) runs again for the affected range.
- **Milestones** store `reachedAt` the first time they are crossed and never fire again, even if later deletions drop the total below the threshold.

---

## 7. Persistence and architecture direction

| Decision | Recommendation | Rationale |
|---|---|---|
| Minimum OS | **iOS 27.1** (hinge APIs); the Shortcuts assisted mode requires the device to run 27.2+ | iPhone Duo ships with 27.1; there is no reason to support older OSs |
| Device family | iPhone. Full features on iPhone Duo; other iPhones and iPads get a **manual-only mode with a clear notice**. `UIRequiredDeviceCapabilities` has **no hinge key**, so distribution cannot be limited to Duo. Guideline 2.4.1 expects iPhone apps to run on iPad, so test there too. **Opt out** of Apple-silicon Mac availability | App Review (2.4.1, 4.2, 4.3(b)) |
| App Intents auth | `authenticationPolicy` left at the default `.alwaysAllowed`; never `requiresAuthentication` | Folds happen while locked |
| Persistence | **SwiftData** with the store in the **App Group** container | Mature by iOS 27, native, simple migrations via `VersionedSchema`; Core Data stays the fallback if spike issues appear |
| Stored data | Raw `FoldEvent` log is the **source of truth**; daily aggregates are computed and cached, never authoritative | Avoids drift; recomputation is cheap (100k events ≈ a few MB) |
| Widget data | App writes a compact `WidgetSnapshot` (JSON, < 4 KB) to the App Group after each commit | Widgets stay fast and within memory limits |
| Charts | Swift Charts | Native |
| Background intents | App Intents defined in the **app target** (the process launched in background), writing through the same persistence actor | Avoids two processes writing to SwiftData at once |
| Networking | **No networking code.** iOS has no network entitlement to turn off, so the promise is enforced by having no `URLSession`/networking imports, no third-party SDKs, a lint/CI check that fails on networking symbols, and proxy capture in Phase 5 | Privacy promise |
| File protection | SwiftData store and snapshot use **`NSFileProtectionCompleteUntilFirstUserAuthentication`** | Background intents must be able to write while the device is **locked**. `Complete` protection would make locked-device writes fail |
| Widget button writes | Apple confirms that the widget's "+ Fold" intent executes in the **widget extension process** by default. It must not open SwiftData itself; it appends to a small lock-free **pending-events queue file** in the App Group, which the app's single writer drains | Keeps one database writer (R-08) |
| Privacy manifest | Ship `PrivacyInfo.xcprivacy` declaring required-reason APIs (`UserDefaults`, file timestamp) and *no* tracking domains; App Store label "Data Not Collected" | Required for App Store submission |

Architecture diagram: see Phase 1 PDF, Figure 2.

---

## 8. Constraints of the current development environment

- This project's cloud workspace runs **Linux**. **Xcode, the iOS Simulator and iOS builds are not available here.** Swift source, documentation and tests can be written, but the app cannot be **compiled, run or tested** in this environment.
- Phases 3–5 therefore need **one** of: (a) the Founder's Mac with Xcode 27.1+ and an iPhone Duo; (b) a macOS CI runner (e.g. GitHub Actions macOS) with Xcode 27.1 available; or (c) a Remote Control session to the Founder's Mac.
- No physical iPhone Duo is available to the team. **Every "device validation" item below is unverified until run on hardware.**

This is recorded as risk **R-01 (Critical)**.

---

## 9. Validation spike (proposed as **Phase 1b, before Phase 2 design**, ~1–2 days on a real device)

A throwaway diagnostic app (not shipped) that:

0. **Most important: confirm that FoldPulse stays foreground-active through a fold and receives the `.closed` update** (or learn what happens instead: scene moves to the outer display / app backgrounds / device locks). If the `.closed` update is not received, automatic *fold* counting in the foreground fails and only unfolds are automatic.
1. Logs every `onHingeChange` callback (status, angle, timestamp, which display, scene phase) while the device is folded/unfolded at different speeds.
2. Measures the false-transition rate under different debounce windows.
3. Adds a background App Intent and a user-created Opened/Closed automation, then checks: does it run immediately (no prompt)? Does it fire while locked? Under Low Power Mode? What is the latency?
4. Folds the device with the app in the foreground **and** the automation enabled → verifies de-duplication.
5. Checks StandBy entry on Duo (closed/open, charging, landscape) and widget presentation.
6. Measures battery impact over 24 h of the automation running.
7. **Rotation-only test:** rotate the device in each pose without folding, and confirm that no `closed` edge appears (status depends on orientation).
8. **Locked write test:** fold 50× while the phone is locked and confirm that background intents can write (file protection).

**Ground-truth protocol:** a tester performs **≥ 300 fold/unfold cycles** per condition (app foreground; app background, unlocked; locked; Low Power Mode). They keep an independent tally (a counter clicker), and the session is screen-recorded or video-recorded from a second device. Results are reported with a 95% confidence interval.

**Exit criteria:** foreground: ≤ 3 errors per 300 cycles (≥ 99%); background automation runs **without a confirmation prompt** and captures ≥ 95% of folds while locked; no duplicate after de-duplication.

**Decision rule:** if the background automation requires confirmation or misses > 5% of folds while locked, **stop and re-assess with the Founder** (a foreground-only product is unlikely to beat existing competitors). If the foreground `.closed` update is not delivered, automatic counting is limited to unfolds and the product is re-scoped.

---

## 10. Sources

- Apple — UIHingeInteraction: https://developer.apple.com/documentation/uikit/uihingeinteraction
- Apple — UIHinge: https://developer.apple.com/documentation/uikit/uihinge
- Apple — UIHinge.Status: https://developer.apple.com/documentation/uikit/uihinge/status-swift.enum
- Apple — UIHinge.angle: https://developer.apple.com/documentation/uikit/uihinge/angle
- Apple — Preparing your app for iPhone Duo: https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo
- Apple Tech Talk 111464 (iPhone Duo hinge, scenes, accessories): https://developer.apple.com/videos/play/tech-talks/111464/
- Apple Developer Forums 847888 (fold posture / reserved regions): https://developer.apple.com/forums/thread/847888
- Apple — Keeping a widget up to date: https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date
- Apple — WidgetFamily: https://developer.apple.com/documentation/widgetkit/widgetfamily
- Apple — AppIntent.supportedModes: https://developer.apple.com/documentation/appintents/appintent/supportedmodes
- Apple — SwiftUI onHingeChange(isEnabled:_:): https://developer.apple.com/documentation/swiftui/view/onhingechange(isenabled:_:)
- Apple — SwiftUI DeviceHinge / DeviceHinge.Status: https://developer.apple.com/documentation/swiftui/devicehinge
- Apple — Adding interactivity to widgets and Live Activities: https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities
- Apple — AppIntent.authenticationPolicy: https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy
- Apple — UIRequiredDeviceCapabilities: https://developer.apple.com/documentation/bundleresources/information-property-list/uirequireddevicecapabilities
- Apple — App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple — Core Motion CMMotionManager: https://developer.apple.com/documentation/coremotion/cmmotionmanager
- Apple Newsroom — Developers bring new app experiences to iPhone Duo (Oct 2026): https://www.apple.com/newsroom/2026/10/developers-bring-incredible-new-app-experiences-to-iphone-duo/
- MacRumors — iPhone Duo roundup: https://www.macrumors.com/roundup/iphone-duo/
- MacRumors — iPhone Duo automation when opened or closed (25 Oct 2026): https://www.macrumors.com/2026/10/25/iphone-duo-automation-opened-or-closed/
- MacRumors — iOS 27.2 features: https://www.macrumors.com/2026/10/26/ios-27-2-features/
- 9to5Mac — iOS 27.2 Shortcuts features (29 Oct 2026): https://9to5mac.com/2026/10/29/ios-27-2-gives-shortcuts-app-these-new-and-improved-features/
- 9to5Mac — iPhone Duo and non-optimized apps: https://9to5mac.com/2026/09/09/heres-how-iphone-duo-treats-apps-not-optimized-for-the-foldable-display/
- App Store — Duo Fold Counter (competitor): https://apps.apple.com/us/app/duo-fold-counter/id6827677447
- foldcounter.com — Fold Counter (competitor): https://foldcounter.com/

**Research method note:** Apple developer documentation was retrieved directly from developer.apple.com. Press sites (MacRumors, 9to5Mac, App Store pages) could not be fetched from this environment's network and were consulted through search-engine summaries. Those findings are marked Medium confidence where Apple has not confirmed them.
