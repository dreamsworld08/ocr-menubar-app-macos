#!/usr/bin/env bash
set -euo pipefail

IDENTITY_FILTER="${DEVELOPER_ID_APP:-Developer ID Application}"
NOTARY_PROFILE="${NOTARY_PROFILE:-AC_NOTARY}"

echo "Checking code-signing identities..."
if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  security find-identity -v -p codesigning | grep "Developer ID Application" || true
else
  echo "No Developer ID Application identity found in keychain."
fi

echo
echo "Checking notary profile: ${NOTARY_PROFILE}"
if xcrun notarytool history --keychain-profile "${NOTARY_PROFILE}" >/dev/null 2>&1; then
  echo "Notary profile '${NOTARY_PROFILE}' is valid."
else
  echo "Notary profile '${NOTARY_PROFILE}' is missing or invalid."
fi

echo
echo "If identity is missing, import your Developer ID cert (.p12) into login keychain."
echo "If profile is missing, run:"
echo "  xcrun notarytool store-credentials \"${NOTARY_PROFILE}\" --apple-id \"you@example.com\" --team-id \"YOURTEAMID\" --password \"app-specific-password\""
