# OCR Menu Bar App (macOS, Apple Silicon)

A lightweight native menu bar app to select text from any on-screen region using Apple Vision OCR.

## Workflow

1. Click the menu bar icon.
2. Click **Start OCR**.
3. Cursor changes to I-beam selection mode.
4. Drag to highlight the text region.
5. On release, OCR runs and text is copied to clipboard.
6. Paste anywhere with `Cmd+V`.

An editable OCR result window also opens with text selected, so `Cmd+C` and `Cmd+V` work naturally.

## Build and Run

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

## Install on macOS

1. Open `dist/OCRMenuBarApp.dmg`.
2. Drag `OCRMenuBarApp.app` to `Applications`.
3. Launch from `Applications`.

If blocked first time, right-click app -> **Open**.

## Required Permission

Enable **Screen Recording** for OCR capture:

- System Settings -> Privacy & Security -> Screen Recording
- Turn on for `OCRMenuBarApp` (or Terminal while testing)

## Optional: Developer ID Signing

```bash
SIGN_MODE=developerid \
DEVELOPER_ID_APP="Developer ID Application: Your Name (TEAMID)" \
./scripts/build_dmg.sh
```
