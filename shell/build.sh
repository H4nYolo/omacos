#!/usr/bin/env bash
# Build omacos-shell and wrap it into ~/.local/share/omacos/omacos-shell.app
# (LSUIElement: no Dock icon; a bundle id so AeroSpace and macOS can tell it apart).
# Needs only the Command Line Tools. Called by install.sh; run it by hand after changing shell/.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
swift build -c release 2>&1 | grep -E 'error|Build complete' || true
BIN="$(swift build -c release --show-bin-path)/omacos-shell"
[[ -x "$BIN" ]] || { echo "build failed" >&2; exit 1; }

APP="$HOME/.local/share/omacos/omacos-shell.app"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/omacos-shell"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.omacos.shell</string>
  <key>CFBundleName</key><string>omacos-shell</string>
  <key>CFBundleExecutable</key><string>omacos-shell</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "built $APP"
