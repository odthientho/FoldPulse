#!/bin/bash
# FoldPulse developer setup (macOS): fetches the repo, generates the Xcode
# project from project.yml and opens it.
# Usage (Terminal):
#   curl -fsSL https://raw.githubusercontent.com/odthientho/FoldPulse/main/scripts/setup_mac.sh | bash
set -euo pipefail
DIR="$HOME/FoldPulse"
TOOLS="$HOME/.foldpulse-tools"
say() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31mERROR: %s\033[0m\n' "$1"; exit 1; }

say "Checking Xcode"
command -v xcodebuild >/dev/null 2>&1 || fail "Install Xcode 27.1+ from the Mac App Store, open it once, then run this again."
xcodebuild -version | head -1

say "Updating $DIR"
if [ -d "$DIR/.git" ]; then git -C "$DIR" pull --ff-only; else git clone https://github.com/odthientho/FoldPulse.git "$DIR"; fi

say "Getting XcodeGen"
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

say "Generating FoldPulse.xcodeproj"
cd "$DIR" && "$XCODEGEN" generate
open "$DIR/FoldPulse.xcodeproj"
cat <<'MSG'

Done. In Xcode:
  1. Select the FoldPulse target -> Signing & Capabilities -> Team: your Apple ID.
     Do the same for the FoldPulseWidgets target.
  2. Choose your iPhone Duo at the top, then press Play (Cmd+R).
  3. In the app: Settings -> "Insert sample week" shows the design with sample data.
If Xcode shows an error, send a screenshot or the text to Claude.
MSG
