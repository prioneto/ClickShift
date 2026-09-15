# ClickShift v1.2.0

ClickShift 1.2 makes the connection model clear and removes the need to choose a recognized training app during setup.

## What’s new

- Automatically detects MyWhoosh, TrainingPeaks Virtual, or ROUVY when the app opens.
- Keeps a **Custom app** option for any other macOS training app that accepts keyboard shifting shortcuts.
- Excludes Zwift as a target because Zwift supports the Zwift Click natively.
- Reworked onboarding and Settings explanations around a simple three-part flow:
  1. The training app connects directly to and controls the trainer.
  2. ClickShift connects only to the right-hand Zwift Click v2.
  3. ClickShift turns button presses into keyboard shortcuts for the focused training app.
- Makes it explicit that ClickShift never pairs with the trainer, proxies trainer data, or controls resistance.
- Preserves automatic controller reconnection, app-only keyboard safety, configurable mappings, gear steps, and privacy-safe diagnostics.

## Default MyWhoosh controls

- Right Click `+` → `K` → shift up
- Right Click `B` → `I` → shift down

Button and key assignments can be changed under **Settings → Controls**.

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac
- Right-hand Zwift Click v2
- A training app that accepts keyboard shortcuts for shifting

## Installation

1. Download `ClickShift-v1.2.0-macOS-universal.zip`.
2. Unzip it and move `ClickShift.app` to `/Applications`.
3. Open ClickShift and complete the Setup Assistant.
4. Allow Bluetooth access for the Click and Accessibility access for keyboard shortcuts.
5. Connect your trainer directly inside your training app as usual.

The app is ad-hoc signed but not Apple-notarized. If macOS blocks the first launch, open **System Settings → Privacy & Security**, choose **Open Anyway**, and confirm.

## Verification

SHA-256:

`2a92fef20b933627091fdcfe76e848286d9b5cbdf3f8c2242115d4f3bc73be81`

ClickShift is unofficial and is not affiliated with Zwift, MyWhoosh, or the other supported training applications.
