#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-OCRMenuBarApp}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-${APP_NAME}}"
BUNDLE_NAME="${APP_NAME}.app"
APP_BUNDLE_ID="${APP_BUNDLE_ID:-com.local.${APP_NAME}}"
APP_VERSION="${APP_VERSION:-1.0.0}"
APP_BUILD="${APP_BUILD:-1}"

SIGN_MODE="${SIGN_MODE:-adhoc}"              # adhoc | developerid
NOTARIZE="${NOTARIZE:-0}"                    # 0 | 1
DEVELOPER_ID_APP="${DEVELOPER_ID_APP:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
SKIP_BUILD="${SKIP_BUILD:-0}"                # 0 | 1

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_BIN="${ROOT_DIR}/.build/release/${EXECUTABLE_NAME}"
DIST_DIR="${ROOT_DIR}/dist"
APP_DIR="${DIST_DIR}/${BUNDLE_NAME}"
APP_ZIP="${DIST_DIR}/${APP_NAME}.zip"
DMG_ROOT="${DIST_DIR}/dmg-root"
DMG_PATH="${DIST_DIR}/${APP_NAME}.dmg"
NOTARY_APP_LOG="${DIST_DIR}/notary-app.json"
NOTARY_DMG_LOG="${DIST_DIR}/notary-dmg.json"

usage() {
  cat <<USAGE
Usage:
  ./scripts/build_dmg.sh

Environment variables:
  SIGN_MODE=adhoc|developerid      (default: adhoc)
  NOTARIZE=0|1                     (default: 0)
  DEVELOPER_ID_APP="Developer ID Application: ..."  (required for developerid)
  NOTARY_PROFILE="keychain-profile-name"            (required when NOTARIZE=1)
  APP_BUNDLE_ID="com.yourcompany.OCRMenuBarApp"     (recommended for release)
  APP_VERSION="1.0.0"
  APP_BUILD="1"
  SKIP_BUILD=0|1

Examples:
  SIGN_MODE=adhoc ./scripts/build_dmg.sh

  SIGN_MODE=developerid \
  DEVELOPER_ID_APP="Developer ID Application: Your Name (TEAMID)" \
  ./scripts/build_dmg.sh

  SIGN_MODE=developerid NOTARIZE=1 \
  DEVELOPER_ID_APP="Developer ID Application: Your Name (TEAMID)" \
  NOTARY_PROFILE="AC_NOTARY" \
  APP_BUNDLE_ID="com.yourcompany.ocrmenubarapp" \
  ./scripts/build_dmg.sh
USAGE
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd swift
require_cmd codesign
require_cmd hdiutil
require_cmd ditto
require_cmd xcrun

if [[ "${SIGN_MODE}" != "adhoc" && "${SIGN_MODE}" != "developerid" ]]; then
  echo "SIGN_MODE must be 'adhoc' or 'developerid'" >&2
  exit 1
fi

if [[ "${NOTARIZE}" == "1" && "${SIGN_MODE}" != "developerid" ]]; then
  echo "NOTARIZE=1 requires SIGN_MODE=developerid" >&2
  exit 1
fi

if [[ "${SIGN_MODE}" == "developerid" && -z "${DEVELOPER_ID_APP}" ]]; then
  echo "DEVELOPER_ID_APP is required when SIGN_MODE=developerid" >&2
  exit 1
fi

if [[ "${NOTARIZE}" == "1" && -z "${NOTARY_PROFILE}" ]]; then
  echo "NOTARY_PROFILE is required when NOTARIZE=1" >&2
  exit 1
fi

if [[ "${SIGN_MODE}" == "developerid" && "${APP_BUNDLE_ID}" == com.local.* ]]; then
  echo "Warning: APP_BUNDLE_ID='${APP_BUNDLE_ID}' looks local-only. Use your real reverse-DNS bundle id for distribution." >&2
fi

mkdir -p "${DIST_DIR}"

if [[ "${SKIP_BUILD}" != "1" ]]; then
  echo "Building release binary..."
  swift build -c release
fi

if [[ ! -x "${BUILD_BIN}" ]]; then
  echo "Missing release binary at ${BUILD_BIN}" >&2
  exit 1
fi

rm -rf "${APP_DIR}" "${DMG_ROOT}" "${DMG_PATH}" "${APP_ZIP}" "${NOTARY_APP_LOG}" "${NOTARY_DMG_LOG}"

mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${BUILD_BIN}" "${APP_DIR}/Contents/MacOS/${EXECUTABLE_NAME}"
chmod +x "${APP_DIR}/Contents/MacOS/${EXECUTABLE_NAME}"

cat > "${APP_DIR}/Contents/Info.plist" <<PLIST
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
  echo "Signing app bundle with Developer ID..."
  codesign --force --deep --timestamp --options runtime --sign "${DEVELOPER_ID_APP}" "${APP_DIR}"
else
  echo "Ad-hoc signing app bundle..."
  codesign --force --deep --sign - "${APP_DIR}"
fi

codesign --verify --deep --strict --verbose=2 "${APP_DIR}"

if [[ "${NOTARIZE}" == "1" ]]; then
  echo "Submitting app for notarization..."
  ditto -c -k --keepParent --sequesterRsrc "${APP_DIR}" "${APP_ZIP}"
  xcrun notarytool submit "${APP_ZIP}" --keychain-profile "${NOTARY_PROFILE}" --wait --output-format json > "${NOTARY_APP_LOG}"

  echo "Stapling app ticket..."
  xcrun stapler staple -v "${APP_DIR}"
  xcrun stapler validate -v "${APP_DIR}"
fi

mkdir -p "${DMG_ROOT}"
cp -R "${APP_DIR}" "${DMG_ROOT}/"
ln -s /Applications "${DMG_ROOT}/Applications"

echo "Creating dmg..."
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${DMG_ROOT}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

if [[ "${SIGN_MODE}" == "developerid" ]]; then
  echo "Signing dmg with Developer ID..."
  codesign --force --timestamp --sign "${DEVELOPER_ID_APP}" "${DMG_PATH}"
else
  echo "Ad-hoc signing dmg..."
  codesign --force --sign - "${DMG_PATH}"
fi

codesign --verify --verbose=2 "${DMG_PATH}"

if [[ "${NOTARIZE}" == "1" ]]; then
  echo "Submitting dmg for notarization..."
  xcrun notarytool submit "${DMG_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait --output-format json > "${NOTARY_DMG_LOG}"

  echo "Stapling dmg ticket..."
  xcrun stapler staple -v "${DMG_PATH}"
  xcrun stapler validate -v "${DMG_PATH}"
fi

echo "App bundle: ${APP_DIR}"
echo "DMG file:   ${DMG_PATH}"
if [[ "${NOTARIZE}" == "1" ]]; then
  echo "Notary app log: ${NOTARY_APP_LOG}"
  echo "Notary dmg log: ${NOTARY_DMG_LOG}"
fi
