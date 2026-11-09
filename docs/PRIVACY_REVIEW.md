# FoldPulse — Privacy & Security Review (Phase 1)

**Owner:** Agent 8 — Privacy and Security Engineer · **Reviewed by:** Agent 10 (Compliance), Agent 12 (Independent Reviewer)
**Version:** 1.1 · 9 November 2026 · **Scope:** Phase 1 design-level review, plus the Phase 3 code review (§5)

## 1. Verdict

The proposed design **can honestly qualify for the App Store "Data Not Collected" label**. Apple defines *collect* as transmitting data off the device in a way that the developer or third parties can access. A file the user chooses to export through the share sheet is not collection. Seven requirements below must hold in the implementation.

## 2. Data inventory

| Data | Where | Sensitivity | Leaves device? |
|---|---|---|---|
| Fold/unfold events (timestamp, time zone, type, source, note) | SwiftData store in the App Group container | **Medium.** Timestamps reveal sleep and daily routine | Only through a user-initiated export, or as part of the user's own iCloud/Finder device backup |
| Widget snapshot (today, total, next milestone, as-of) | App Group JSON | Low | Same as above |
| Settings | `UserDefaults` (App Group suite) | Low | Same |
| Notes (free text) | SwiftData | Potentially high (the user types it) | Same |

No identifiers, location, contacts, health data, advertising ID or device fingerprinting.

## 3. Requirements

| # | Requirement | Verification (Phase 5) |
|---|---|---|
| P-1 | **No networking code.** No `URLSession`/`Network.framework`/WebKit fetches, no third-party SDKs, no analytics, ads, crash-reporting SDKs, CloudKit or remote database. (iOS has no "network entitlement" to remove, so this rule is enforced in the code itself) | CI check fails on networking symbols; proxy capture of a release build shows zero requests |
| P-2 | **Privacy manifest** (`PrivacyInfo.xcprivacy`) in both the app and the widget extension. `NSPrivacyTracking = false`, no tracking domains, collected data types = none. Required-reason APIs as used, likely `UserDefaults` (`1C8F.1` for App Group access, `CA92.1` app-only), file timestamps (`C617.1`), and system boot time (`35F9.1`) if monotonic clocks are used for debounce | Xcode privacy report |
| P-3 | **File protection** `CompleteUntilFirstUserAuthentication` for the store, snapshot and queue (needed for locked-device writes); never weaker | Spike locked-write test |
| P-4 | **Export safety:** CSV cells starting with `=`, `+`, `-` or `@` are escaped (formula injection). Before sharing, a notice says the file reveals daily routine. Exports go to a temporary file deleted after sharing | Unit tests |
| P-5 | **Import safety:** ≤ 20 MB, strict schema decode, field bounds (dates 2026–2100, notes ≤ 500 chars), transactional merge, preview before commit, nothing executed or rendered as HTML | Fuzz tests with corrupt and oversized files |
| P-6 | **Lock Screen widgets** use `.privacySensitive()` for counts | UI review |
| P-7 | **Disclosure:** the in-app privacy statement and the App Store policy say "Data stays on your iPhone. It is included in your own device backups (iCloud/Finder) if you use them. FoldPulse never sends it anywhere." A **privacy policy URL** is required (guideline 5.1.1(i)) | Phase 6 checklist |

## 4. Other notes

- **Notifications:** local `UNUserNotificationCenter` only. No push entitlement and no APNs.
- **App Intents:** `authenticationPolicy` stays at the default `.alwaysAllowed` so that folds can be recorded while the phone is locked. The intents only *append* an event. They expose no data on the Lock Screen and accept no parameters except an optional note.
- **Unverified callers:** any user shortcut can call "Record Fold". This is a data-quality issue, not a privacy one; see risk R-25.
- **Reset:** deletes the store, snapshot, queue and settings, then reloads widgets.
- **Monetisation:** any future model must use StoreKit only. Ad or analytics SDKs are ruled out.

## 5. Phase 3 code review (Agent 8, independent)

| Requirement | Status in code | Evidence |
|---|---|---|
| P-1 No networking | **Met** | No networking symbols in shipping Swift code; CI privacy-guard step fails the build if any appear; CloudKit explicitly `.none` |
| P-2 Privacy manifest | **Met** | App: no tracking, no collected data, UserDefaults reason `1C8F.1` (App Group suite, the only use). Widget: no required-reason APIs. Corrected after review: the first draft declared an unused reason |
| P-3 File protection | **Met (verify on device)** | Store directory created with `completeUntilFirstUserAuthentication`; snapshot written with the same protection |
| No stranded data | **Met** | Release builds never fall back from the App Group to a private location |
| Debug-only tools | **Met** | Sample data, delete-all and the `-ui-testing` in-memory switch are compiled only in debug builds |
| P-4/P-5 Export/import safety, P-6 widget privacy | P-6 met (`.privacySensitive()`); P-4/P-5 arrive with Phase 4 export |

## Sources

- App privacy details: https://developer.apple.com/app-store/app-privacy-details/
- Privacy manifest required-reason APIs: https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons
- App Store Review Guidelines 5.1.1: https://developer.apple.com/app-store/review/guidelines/
- AppIntent.authenticationPolicy: https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy
