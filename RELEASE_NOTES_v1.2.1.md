# ClickShift v1.2.1

ClickShift 1.2.1 returns app selection to the user and keeps the interface focused on setup and shifting.

## What changed

- Restored manual training-app selection in onboarding and **Settings → General**.
- Removed automatic training-app detection and automatic target switching.
- Removed the large “How ClickShift works” explanation panels from onboarding and Settings.
- Kept profiles for MyWhoosh, TrainingPeaks Virtual, ROUVY, and any custom macOS app that accepts keyboard shifting shortcuts.
- Expanded the README’s **How it works** section so the connection model remains fully documented without taking over the app interface.
- Clarified that the training app connects directly to and controls the trainer, while ClickShift connects only to the right-hand Zwift Click v2 and sends keyboard shortcuts.
- Kept Zwift out of the target list because Zwift supports the Click natively.

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

1. Download `ClickShift-v1.2.1-macOS-universal.zip`.
2. Unzip it and move `ClickShift.app` to `/Applications`.
3. Open ClickShift and choose your training app in the Setup Assistant.
4. Allow Bluetooth access for the Click and Accessibility access for keyboard shortcuts.
5. Connect your trainer directly inside your training app as usual.

The app is ad-hoc signed but not Apple-notarized. If macOS blocks the first launch, open **System Settings → Privacy & Security**, choose **Open Anyway**, and confirm.

## Verification

SHA-256:

`d994291aa4ec190a5d70f7c1b284880fa9ea299b2f4ed92f5c20b45675b62cf2`

ClickShift is unofficial and is not affiliated with Zwift, MyWhoosh, or the other supported training applications.
