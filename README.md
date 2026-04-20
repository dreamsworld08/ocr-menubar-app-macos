# OCR Menu Bar App (macOS, Apple Silicon)

A lightweight native macOS menu bar app that lets you drag-select text on screen and copy OCR output.

## Features

- Menu bar icon trigger (`text.viewfinder` symbol).
- Click **Start OCR** to enter selection mode.
- Drag to highlight the region with text.
- OCR runs on-device with Apple Vision (`VNRecognizeTextRequest`, accurate mode).
- Recognized text is automatically copied to clipboard.
- Editable result panel opens with selected text so `Cmd+C` and `Cmd+V` workflow is natural.

## Build & Run

1. Open this folder in Xcode (Xcode can open Swift packages directly).
2. Choose the `OCRMenuBarApp` executable target.
3. Run.

Or via terminal:

```bash
swift build
swift run
```

## Build DMG

```bash
./scripts/build_dmg.sh
```

Output:

- `dist/OCRMenuBarApp.app`
- `dist/OCRMenuBarApp.dmg`

## External Distribution (No Gatekeeper Warning)

Use Developer ID signing + notarization:

1. Install your **Developer ID Application** certificate in Keychain.
2. Store notarization credentials once:

```bash
xcrun notarytool store-credentials "AC_NOTARY" \
  --apple-id "you@example.com" \
  --team-id "YOURTEAMID" \
  --password "app-specific-password"
```

3. Build signed + notarized artifacts:

```bash
SIGN_MODE=developerid NOTARIZE=1 \
DEVELOPER_ID_APP="Developer ID Application: Your Name (YOURTEAMID)" \
NOTARY_PROFILE="AC_NOTARY" \
APP_BUNDLE_ID="com.yourcompany.ocrmenubarapp" \
./scripts/build_dmg.sh
```

The script will:

- Sign app with hardened runtime
- Notarize and staple app
- Build + sign DMG
- Notarize and staple DMG

## First-run Permission

The app needs **Screen Recording** permission to capture the selected area:

- Open **System Settings > Privacy & Security > Screen Recording**
- Enable permission for your built app/Terminal host
- Re-run Start OCR

## Usage

1. Click menu bar OCR icon.
2. Click **Start OCR**.
3. Drag over text and release.
4. OCR text is copied to clipboard.
5. Paste anywhere with `Cmd+V`.

Press `Esc` while selecting to cancel.
