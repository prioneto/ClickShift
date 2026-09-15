# ClickShift v1.1.0

This release gives ClickShift a cleaner, more native macOS interface while keeping its shifting behavior unchanged.

## What changed

- Redesigned the menu-bar panel around a compact inline connection status and the two shift mappings.
- Uses native controls and materials that follow the current macOS appearance.
- Moved startup, connection, test, permission, privacy, and version details into a real macOS Settings window.
- Added a clean sidebar with General, Controls, Permissions, and About pages.
- Opens Settings through a dedicated application window controller for reliable menu-bar operation.
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
3. Open ClickShift once and allow Bluetooth access.
4. Open the menu-bar panel, choose **Settings**, and enable Accessibility from the **Permissions** tab.

This build is ad-hoc signed and not notarized. If macOS blocks the first launch, open **System Settings → Privacy & Security**, choose **Open Anyway**, and confirm.

## SHA-256

`65fc67193b2b1d08fe50559a0cb3460fb47edd6c39f28ed4220701d61cfe2746`
