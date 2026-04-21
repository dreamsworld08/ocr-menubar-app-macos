#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-OCRMenuBarApp}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-${APP_NAME}}"
APP_BUNDLE_ID="${APP_BUNDLE_ID:-com.local.${APP_NAME}}"
APP_VERSION="${APP_VERSION:-1.0.0}"
APP_BUILD="${APP_BUILD:-1}"

SIGN_MODE="${SIGN_MODE:-adhoc}"
DEVELOPER_ID_APP="${DEVELOPER_ID_APP:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
BUILD_BIN="${ROOT_DIR}/.build/release/${EXECUTABLE_NAME}"
APP_PATH="${DIST_DIR}/${APP_NAME}.app"
DMG_STAGE="${DIST_DIR}/dmg-root"
DMG_PATH="${DIST_DIR}/${APP_NAME}.dmg"

if [[ "${SIGN_MODE}" != "adhoc" && "${SIGN_MODE}" != "developerid" ]]; then
  echo "SIGN_MODE must be 'adhoc' or 'developerid'"
  exit 1
fi

if [[ "${SIGN_MODE}" == "developerid" && -z "${DEVELOPER_ID_APP}" ]]; then
  echo "DEVELOPER_ID_APP is required when SIGN_MODE=developerid"
  exit 1
fi

mkdir -p "${DIST_DIR}"

swift build -c release

if [[ ! -x "${BUILD_BIN}" ]]; then
  echo "Release binary not found: ${BUILD_BIN}"
  exit 1
fi

rm -rf "${APP_PATH}" "${DMG_STAGE}" "${DMG_PATH}"

mkdir -p "${APP_PATH}/Contents/MacOS"
mkdir -p "${APP_PATH}/Contents/Resources"

cp "${BUILD_BIN}" "${APP_PATH}/Contents/MacOS/${EXECUTABLE_NAME}"
chmod +x "${APP_PATH}/Contents/MacOS/${EXECUTABLE_NAME}"

cat > "${APP_PATH}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${EXECUTABLE_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${APP_BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${APP_BUILD}</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSScreenCaptureDescription</key>
  <string>OCR needs screen capture access for selected text regions.</string>
</dict>
</plist>
PLIST

if [[ "${SIGN_MODE}" == "developerid" ]]; then
  codesign --force --deep --timestamp --options runtime --sign "${DEVELOPER_ID_APP}" "${APP_PATH}"
else
  codesign --force --deep --sign - "${APP_PATH}"
fi

codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

mkdir -p "${DMG_STAGE}"
cp -R "${APP_PATH}" "${DMG_STAGE}/"
ln -s /Applications "${DMG_STAGE}/Applications"

hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${DMG_STAGE}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

if [[ "${SIGN_MODE}" == "developerid" ]]; then
  codesign --force --timestamp --sign "${DEVELOPER_ID_APP}" "${DMG_PATH}"
else
  codesign --force --sign - "${DMG_PATH}"
fi

codesign --verify --verbose=2 "${DMG_PATH}"

echo "App bundle created: ${APP_PATH}"
echo "DMG created: ${DMG_PATH}"
