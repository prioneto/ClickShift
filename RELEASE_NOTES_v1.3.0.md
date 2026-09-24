# ClickShift v1.3.0

ClickShift 1.3.0 redesigns the menu-bar dropdown and the Settings window so they look and feel like a native Mac app in both light and dark mode.

## What’s new

### Menu-bar dropdown

- A header with a live status badge: **Connected**, **Searching**, **Waiting**, **Paused**, or **Action needed**.
- Status rows for the right-hand Zwift Click v2 and your training app, with a spinner and wake-up hint while ClickShift searches.
- Button mappings shown as key caps, such as `+ → K` and `B → I`, along with your last shift.
- Menu-style **Reconnect**, **Settings…** (⌘,), and **Quit ClickShift** (⌘Q) rows.
- An **Allow…** button right in the dropdown when Accessibility access is missing.

### Settings

- A native sidebar window that follows your Mac’s light or dark appearance.
- Standard macOS switches, pop-up menus, and a 1 / 2 / 3 gear-step control, grouped into clear sections.
- **General** opens with a connection status card with **Reconnect**, **Stop**, or **Start**.
- **Permissions** shows Accessibility and Bluetooth status at a glance and refreshes automatically when you return from System Settings.
- A new **About** page with version, privacy, source code, and diagnostics export.

The menu-bar icon, dropdown, and Settings now share one status model, so they always agree.

## Default MyWhoosh controls

- Right Click `+` → `K` → shift up
- Right Click `B` → `I` → shift down

Button assignments, keyboard shortcuts, and shifts per press can be changed under **Settings → Controls**.

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac
- Right-hand Zwift Click v2
- A training app that accepts keyboard shortcuts for shifting

## Installation

1. Download `ClickShift-v1.3.0-macOS-universal.zip`.
2. If you are updating, quit ClickShift from its menu-bar dropdown first.
3. Unzip the download and move `ClickShift.app` to `/Applications`, replacing the old copy.
4. Open ClickShift. New users choose a training app and grant Bluetooth and Accessibility in the Setup Assistant.

The app is ad-hoc signed but not Apple-notarized. If macOS blocks the first launch, open **System Settings → Privacy & Security**, choose **Open Anyway**, and confirm.

After an update, macOS may ask for Accessibility again. If the dropdown shows **Action needed**, click **Allow…**. If that does not help, remove ClickShift from **System Settings → Privacy & Security → Accessibility** and add it again.

## Verification

SHA-256:

`bdbdba2ae8ea2e4412533188c3057119385b3c1e85259e6bbab403c8c4cf1585`

ClickShift is unofficial and is not affiliated with Zwift, MyWhoosh, or the other supported training applications.
