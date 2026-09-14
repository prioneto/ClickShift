# ClickShift v1.0.0

The first public release of ClickShift: a small, free macOS menu-bar bridge between the right-hand Zwift Click v2 and MyWhoosh virtual shifting.

## Features

- `+` shifts up in MyWhoosh
- `B` shifts down in MyWhoosh
- Automatically activates when MyWhoosh opens
- Automatic Bluetooth reconnection
- Disconnects when MyWhoosh quits so the Click can sleep
- Optional launch at login
- Test-shift buttons and connection status in the menu bar
- Universal macOS build for Apple Silicon and Intel
- No telemetry, accounts, advertising, or network communication

## Requirements

- macOS 13 Ventura or later
- Zwift Click v2 right controller
- MyWhoosh with Virtual Shifting enabled

## Installation

1. Download `ClickShift-v1.0.0-macOS-universal.zip` below.
2. Unzip it and move `ClickShift.app` to `/Applications`.
3. Open ClickShift and approve Bluetooth access.
4. Use **Enable Accessibility** in its menu and enable it in **System Settings → Privacy & Security → Accessibility**.
5. Open MyWhoosh and wake the right Click.

## macOS security notice

This free build is ad-hoc signed but not Apple-notarized. On first launch, macOS may require you to try opening the app and then choose **Open Anyway** under **System Settings → Privacy & Security**. Only do this for a build downloaded from this repository. The complete source and build script are available for inspection. See [Apple's security guidance](https://support.apple.com/102445) for details.

## Known limitations

- Only the right-hand Click v2 is used; `B` is reassigned to downshift.
- MyWhoosh must retain its `I`/`K` shifting shortcuts.
- A future Click firmware update could require a protocol update.

## Download verification

SHA-256 for `ClickShift-v1.0.0-macOS-universal.zip`:

```text
fca7ea6566fba94201fa5dac05203229af72c2ee2676d48b44c15afc17407d31
```
