# ClickShift v1.1.0

This release gives ClickShift a cleaner, more native macOS interface while keeping its shifting behavior unchanged.

## What changed

- Redesigned the menu-bar panel around connection status and the two shift mappings.
- Added native Liquid Glass styling on macOS 26 and later, with a compatible material fallback for macOS 13–15.
- Moved startup, connection, test, permission, privacy, and version details into a real macOS Settings window.
- Added General, Controls, and Permissions tabs so the main panel stays compact.
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

`aed1b8e89a06a1775fbe516f52f748a5244285933f41988b33766267b10177c4`
