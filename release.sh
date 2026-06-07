#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MacSide"
PROJECT_NAME="MacSide"
VERSION="1.1"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
TMP_DMG="${SCRIPT_DIR}/tmp_rw.dmg"

XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

echo "▶ Building ${APP_NAME} ${VERSION} (Release)..."

"$XCODEBUILD" \
  -project "${SCRIPT_DIR}/${PROJECT_NAME}.xcodeproj" \
  -scheme "${APP_NAME}" \
  -configuration Release \
  clean build

# Find the .app Xcode just built in DerivedData
APP_PATH=$(
  "$XCODEBUILD" \
    -project "${SCRIPT_DIR}/${PROJECT_NAME}.xcodeproj" \
    -scheme "${APP_NAME}" \
    -configuration Release \
    -showBuildSettings 2>/dev/null \
  | awk '/BUILT_PRODUCTS_DIR/{print $3}' \
  | head -1
)
APP_PATH="${APP_PATH}/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
  echo "✗ Could not locate built .app"
  exit 1
fi

echo "✓ Built: ${APP_PATH}"

# Stage app + Applications symlink
STAGING=$(mktemp -d)
cp -r "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

rm -f "$TMP_DMG" "${SCRIPT_DIR}/${DMG_NAME}"

echo "▶ Creating installer DMG..."

# Create a writable DMG from the staging folder
hdiutil create \
  -srcfolder "$STAGING" \
  -volname "$APP_NAME" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,b=16" \
  -format UDRW \
  -size 150m \
  "$TMP_DMG"

# Mount it (no auto-open)
MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$TMP_DMG" \
  | grep '/Volumes/' | sed 's|.*\(/Volumes/[^\t]*\)|\1|' | sed 's/[[:space:]]*$//')

echo "▶ Configuring Finder window..."

# Use Finder via AppleScript to set the window layout
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 760, 420}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set position of item "${APP_NAME}.app" of container window to {150, 140}
        set position of item "Applications" of container window to {410, 140}
        close
        open
        update without registering applications
        delay 3
        close
    end tell
end tell
EOF

# Give Finder a moment to fully release the volume
sleep 3

# Unmount (force if Finder is still holding a reference)
hdiutil detach "$MOUNT_DIR" || hdiutil detach "$MOUNT_DIR" -force

# Convert to compressed read-only
echo "▶ Compressing..."
hdiutil convert "$TMP_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "${SCRIPT_DIR}/${DMG_NAME}"

# Cleanup
rm -f "$TMP_DMG"
rm -rf "$STAGING"

echo ""
echo "✓ Done: ${SCRIPT_DIR}/${DMG_NAME}"
echo ""
echo "─────────────────────────────────────────────────────────"
echo "  Gatekeeper note (no Apple Developer account)"
echo "─────────────────────────────────────────────────────────"
echo "  First-time users must right-click the app → Open → Open"
echo "  OR: System Settings → Privacy & Security → Open Anyway"
echo "  This is a one-time step per machine."
echo "─────────────────────────────────────────────────────────"
