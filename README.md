# ClickShift

ClickShift is a small, free macOS menu-bar utility for using the **right Zwift Click v2** with MyWhoosh:

- `+` sends `K` (shift up in MyWhoosh)
- `B` sends `I` (shift down in MyWhoosh)
- reconnects automatically whenever the controller wakes or returns in range
- runs quietly at login, begins connecting when MyWhoosh opens, and disconnects when MyWhoosh quits
- uses the right controller only, so it does not need the left controller's periodic Zwift unlock

ClickShift is an unofficial personal utility and is not affiliated with Zwift or MyWhoosh.

## Build

Requirements: macOS 13 or later and Xcode Command Line Tools.

```sh
./scripts/build-app.sh
```

The packaged app is written to `../outputs/ClickShift.app` by default.

Run tests with:

```sh
swift test
```

## Install and use

1. Run `./scripts/install.sh`, or drag `ClickShift.app` to Applications yourself.
2. Approve Bluetooth access when macOS asks.
3. Use **Enable Accessibility** in the menu and enable ClickShift in System Settings. This permission lets it send the `I`/`K` keys to MyWhoosh.
4. Close Zwift and Zwift Companion so they do not take the Click connection.
5. Open MyWhoosh. ClickShift detects `com.whoosh.whooshgame` and starts searching automatically.
6. Press a button on the **right** Click to wake it. The bicycle icon becomes filled when connected.
7. Enable Virtual Shifting in MyWhoosh and start a ride.

ClickShift registers itself as a macOS login item the first time it runs. While MyWhoosh is closed it remains idle and does not scan for Bluetooth devices. When MyWhoosh opens, ClickShift starts scanning; if the controller sleeps or disconnects, press a right-side button to wake it and it will reconnect automatically.

## Why the right controller?

The Click v2 advertises its left and right pucks separately. ClickShift filters for the right-side manufacturer identifier and maps its `B` button to downshift, giving both shift directions on one puck without the left-side unlock/restart behavior.

## Troubleshooting

- **Only the left Click is found:** press a button on the right Click; it advertises for a short time after waking.
- **Connected but MyWhoosh does not shift:** confirm Accessibility is enabled for ClickShift, enable Virtual Shifting in MyWhoosh, and use the two Test buttons while MyWhoosh is active.
- **Controller is not found:** quit Zwift, Zwift Companion, BikeControl, or anything else that may already be connected to it.
- **A firmware update breaks input:** the Click protocol is unofficial and reverse-engineered. Open an issue with the raw firmware/version details before changing the decoder.

## Technical notes

The app uses CoreBluetooth and the Click v2's `0xFC82` service. It subscribes to the controller notification characteristics, performs the right-side `RideOn` handshake, sends a keepalive every five seconds, and decodes the active-low button mask. Keyboard events use macOS Quartz and therefore require Accessibility permission.
