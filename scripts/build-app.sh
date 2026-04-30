#!/usr/bin/env bash
# Wrap the SPM release binary in a Sharpie.app bundle so macOS treats it as
# a proper menu-bar app (LSUIElement=true) and Vikky can launch it from the
# Applications folder. v1.0 will sign and notarize this; for v0.1 it's just
# unsigned and you'll need to right-click → Open the first time.

set -euo pipefail

APP_NAME="Sharpie"
BUNDLE_ID="ai.sharpie.app"
VERSION="0.1.0"
BUILD_NUMBER="1"
MIN_MACOS="14.0"

cd "$(dirname "$0")/.."

echo "→ swift build -c release"
swift build -c release

SRC_BIN=".build/release/${APP_NAME}"
APP_DIR="build/${APP_NAME}.app"

if [ ! -f "${SRC_BIN}" ]; then
  echo "expected ${SRC_BIN} after release build, not found" >&2
  exit 1
fi

echo "→ assembling ${APP_DIR}"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${SRC_BIN}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# SPM emits resource bundles next to the executable. Copy any .bundle
# directories along with the binary so Bundle.module still resolves.
shopt -s nullglob
for b in .build/release/*.bundle; do
  cp -R "${b}" "${APP_DIR}/Contents/MacOS/"
done
shopt -u nullglob

cat > "${APP_DIR}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key><string>Sharpie</string>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key><string>${APP_NAME}</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>${MIN_MACOS}</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>MIT licensed. See LICENSE.</string>
</dict>
</plist>
EOF

echo "→ done: ${APP_DIR}"
echo "   open it with:  open ${APP_DIR}"
