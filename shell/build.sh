#!/usr/bin/env bash
# Build omacos-shell and omacos-notes and wrap them into ~/.local/share/omacos/<name>.app
# (LSUIElement: no Dock icon; a bundle id so AeroSpace and macOS can tell them apart).
# Needs only the Command Line Tools. Called by install.sh; run it by hand after changing shell/.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# bundle <product> <bundle id> <minimum macOS>
bundle() {
  local name="$1" id="$2" min="$3"
  swift build -c release --scratch-path .build/app --product "$name" 2>&1 | grep -E 'error|Build complete' || true
  local bin
  bin="$(swift build -c release --scratch-path .build/app --show-bin-path)/$name"
  [[ -x "$bin" ]] || { echo "build of $name failed" >&2; exit 1; }

  local app="$HOME/.local/share/omacos/$name.app"
  mkdir -p "$app/Contents/MacOS"
  cp "$bin" "$app/Contents/MacOS/$name"
  cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>$id</string>
  <key>CFBundleName</key><string>$name</string>
  <key>CFBundleExecutable</key><string>$name</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSMinimumSystemVersion</key><string>$min</string>
</dict></plist>
PLIST
  codesign --force --sign - "$app" >/dev/null 2>&1 || true
  echo "built $app"
}

bundle omacos-shell com.omacos.shell 14.0
bundle omacos-notes com.omacos.notes 14.0
