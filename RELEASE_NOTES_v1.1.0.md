# ClickShift v1.1.0

This release gives ClickShift a cleaner, more native macOS interface and makes shifting safer, configurable, and easier to set up.

## What changed

- Redesigned the menu-bar panel around a compact inline connection status and the two shift mappings.
- Rebuilt Settings with a custom Alcove-inspired navigation rail, solid inset cards, restrained color accents, and compact controls.
- Moved startup, connection, test, permission, privacy, and version details into a real macOS Settings window.
- Added a clean sidebar with General, Controls, Permissions, and About pages.
- Opens Settings through a dedicated application window controller for reliable menu-bar operation.
- Adds a guided first-run setup for app selection, permissions, and controller discovery.
- Gives the Setup Assistant the same layered visual design, clearer progress, and polished status cards as Settings.
- Uses flat solid-color surfaces throughout and a rebuilt edge-to-edge app icon with no gradients, glow, or outer black ring.
- Adds a default-on safety mode that sends keys only to the focused riding app.
- Adds configurable Click buttons, keyboard outputs, and 1–3 shifts per press.
- Adds MyWhoosh, Zwift, IndieVelo, ROUVY, and custom target profiles.
- Reconnects through the remembered controller and shows wake guidance.
- Adds privacy-safe diagnostics, opt-in meaningful notifications, and connection-aware menu-bar icon colors.
- Updated setup and troubleshooting instructions for the new Settings layout.

## Still included

- Right-hand Zwift Click v2 support.
- `+` sends `K` for shift up; `B` sends `I` for shift down.
- Automatic MyWhoosh detection, connection, disconnection, and reconnect.
- Universal Apple Silicon and Intel build.
- No accounts, analytics, ads, or network service.

## Install

1. Download `ClickShift-v1.1.0-macOS-universal.zip` and unzip it.
2. Move `ClickShift.app` to `/Applications`.
3. Open ClickShift once and follow the Setup Assistant for Bluetooth, Accessibility, and controller discovery.
4. Keep **Open ClickShift when I log in** enabled so it can notice when your riding app opens.

This build is ad-hoc signed and not notarized. If macOS blocks the first launch, open **System Settings → Privacy & Security**, choose **Open Anyway**, and confirm.

## SHA-256

`9ff147ed82fe7c66460358ebca3fd0ddf50e6b7715b94b20666a35a55fe72936`
