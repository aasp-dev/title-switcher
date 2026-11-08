#!/usr/bin/env bash
# Builds build/TitleSwitcher.app. Ad-hoc signed by default, so macOS asks for Accessibility again after
# each rebuild; set SIGN_IDENTITY to a stable certificate to avoid that.
# VERSION sets CFBundleShortVersionString (default 0.1.0).
set -euo pipefail
cd "$(dirname "$0")/.."
build_flags=(-c release --arch arm64 --arch x86_64)  # universal binary
swift build "${build_flags[@]}"
app=build/TitleSwitcher.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$(swift build "${build_flags[@]}" --show-bin-path)/TitleSwitcher" "$app/Contents/MacOS/"
cp Resources/AppIcon.icns "$app/Contents/Resources/"
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>dev.local.TitleSwitcher</string>
  <key>CFBundleName</key><string>TitleSwitcher</string>
  <key>CFBundleExecutable</key><string>TitleSwitcher</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION:-0.1.0}</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign "${SIGN_IDENTITY:--}" "$app"
echo "Built $app"
