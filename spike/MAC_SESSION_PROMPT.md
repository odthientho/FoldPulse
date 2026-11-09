# Message to paste into Claude Code on the Founder's Mac

Open Terminal on the Mac and run `mkdir -p ~/FoldPulse && cd ~/FoldPulse && claude`
(or use the Claude desktop app → Code with folder `~/FoldPulse`). Then paste everything below the line.

---

You are helping with the FoldPulse Phase 1b device spike. Goal: build the throwaway diagnostic app **FoldProbe** and install it on my iPhone Duo, which is plugged into this Mac. Ask me before anything that needs my password, and tell me when I need to tap something on the phone.

1. Clone `https://github.com/odthientho/FoldPulse` into the current folder (or `git pull` if it is already there).
2. Check the prerequisites and report: `xcodebuild -version` must be Xcode 27.1 or later. `xcrun devicectl list devices` must show my iPhone Duo as connected, on iOS 27.2 or later. If Developer Mode is off, or the device isn't trusted, tell me exactly what to tap.
3. Install XcodeGen if it is missing (`brew install xcodegen`; install Homebrew only if I agree). Then `cd spike && xcodegen` to create `FoldProbe.xcodeproj` from `spike/project.yml`.
4. Find my Apple development team ID (from the Xcode account or the signing identities). If there is none, ask me to sign in under Xcode → Settings → Accounts.
5. Build for the device with automatic signing, for example:
   `xcodebuild -project FoldProbe.xcodeproj -scheme FoldProbe -configuration Debug -destination 'id=<DEVICE_ID>' -allowProvisioningUpdates DEVELOPMENT_TEAM=<TEAM_ID> -derivedDataPath build build`
   If the bundle ID is taken, change the suffix of `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` and regenerate.
6. **If the Swift code fails to compile**, fix it with minimal changes. The code was written without access to Xcode against Apple's documented iOS 27.1 APIs (`onHingeChange(isEnabled:_:)`, `DeviceHinge`, `AppIntent.supportedModes`). Keep the behaviour: raw hinge logging, scene logging, the two background intents, a local JSON-lines log, no networking. Commit the fixes to a branch named `spike/foldprobe-fixes` and push it.
7. Install and launch: `xcrun devicectl device install app --device <DEVICE_ID> build/Build/Products/Debug-iphoneos/FoldProbe.app`, then `xcrun devicectl device process launch --device <DEVICE_ID> com.foldpulse.spike.foldprobe.odthientho` (use the actual bundle ID). If iOS says the developer is untrusted, tell me to open Settings → General → VPN & Device Management.
8. Ask me to fold and unfold the phone once, and confirm that FoldProbe's "Callbacks" number goes up.
9. Finish with a short summary: the Xcode and iOS versions, any code fixes you made, and whether the hinge callbacks worked. I will then follow `docs/SPIKE_PLAN.md` Part 2 onwards.
