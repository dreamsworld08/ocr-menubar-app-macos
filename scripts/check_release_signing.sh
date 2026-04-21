#!/usr/bin/env bash
set -euo pipefail

NOTARY_PROFILE="${NOTARY_PROFILE:-AC_NOTARY}"

echo "Checking Developer ID identities..."
if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  security find-identity -v -p codesigning | grep "Developer ID Application"
else
  echo "No Developer ID Application identity found."
fi

echo
echo "Checking notary profile '${NOTARY_PROFILE}'..."
if xcrun notarytool history --keychain-profile "${NOTARY_PROFILE}" >/dev/null 2>&1; then
  echo "Notary profile is valid."
else
  echo "Notary profile missing/invalid. Create it with:"
  echo "xcrun notarytool store-credentials \"${NOTARY_PROFILE}\" --apple-id \"you@example.com\" --team-id \"YOURTEAMID\" --password \"app-specific-password\""
fi
