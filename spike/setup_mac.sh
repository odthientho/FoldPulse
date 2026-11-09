#!/bin/bash
# FoldProbe setup for the FoldPulse Phase 1b device spike (macOS).
# Downloads the FoldPulse repo, generates the FoldProbe Xcode project and opens it.
# Usage (Terminal):
#   curl -fsSL https://raw.githubusercontent.com/odthientho/FoldPulse/main/spike/setup_mac.sh | bash
set -euo pipefail

DIR="$HOME/FoldPulse"
TOOLS="$HOME/.foldprobe-tools"

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31mERROR: %s\033[0m\n' "$1"; exit 1; }

say "Checking Xcode"
command -v xcodebuild >/dev/null 2>&1 || fail "Xcode is not installed. Install Xcode 27.1+ from the Mac App Store, open it once, then run this again."
xcodebuild -version | head -1

say "Getting the FoldPulse repository into $DIR"
if [ -d "$DIR/.git" ]; then
  git -C "$DIR" pull --ff-only
else
  git clone https://github.com/odthientho/FoldPulse.git "$DIR"
fi

say "Getting XcodeGen (generates the Xcode project)"
if command -v xcodegen >/dev/null 2>&1; then
  XCODEGEN="$(command -v xcodegen)"
else
  mkdir -p "$TOOLS"
  curl -fsSL -o "$TOOLS/xcodegen.zip" https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip
  unzip -oq "$TOOLS/xcodegen.zip" -d "$TOOLS"
  XCODEGEN="$(find "$TOOLS" -type f -path '*/bin/xcodegen' | head -1)"
  [ -n "$XCODEGEN" ] || fail "Could not find xcodegen after download."
  chmod +x "$XCODEGEN"
fi

say "Generating FoldProbe.xcodeproj"
cd "$DIR/spike"
"$XCODEGEN" generate

say "Opening the project in Xcode"
open "$DIR/spike/FoldProbe.xcodeproj"

cat <<'MSG'

Done. In Xcode:
  1. Click "FoldProbe" (blue icon, top of the left sidebar) -> "Signing & Capabilities".
     Team: choose your Apple ID (Add an Account... if none is listed).
  2. At the top of the window, pick your iPhone Duo as the run destination.
  3. Press the Play button (or Cmd+R).
If Xcode shows a red error, take a screenshot or copy the text and send it to Claude.
MSG
