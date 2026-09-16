<p align="center">
  <img src="Resources/AppIcon.png" width="128" alt="ClickShift icon">
</p>

# ClickShift

ClickShift is a small, free macOS menu-bar utility that lets a **right-hand Zwift Click v2** control virtual shifting in keyboard-controlled training apps that do not support the Click natively.

- `+` sends `K` — shift up
- `B` sends `I` — shift down
- Watches the training app profile you choose during setup
- Disconnects when the ride app quits so the controller can sleep
- Reconnects automatically if the controller drops or the Mac wakes from sleep
- Sends shift keys only when the selected riding app is focused by default
- Supports configurable buttons, keys, app profiles, and 1–3 shifts per press
- Includes a guided first-run setup and privacy-safe diagnostics export
- Runs quietly as a menu-bar app with a compact native macOS panel
- Opens controls, permissions, startup options, and app details in a modern layered Settings window
- No accounts, analytics, advertising, or network service

ClickShift is unofficial and is not affiliated with Zwift or MyWhoosh.

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac
- Zwift Click v2 right controller
- A macOS training app that accepts keyboard shortcuts for shifting; enable the app’s virtual-shifting feature when required

The downloadable app is universal and contains native `arm64` and `x86_64` executables.

## Download and install

1. Download `ClickShift-v1.2.2-macOS-universal.zip` from the [latest GitHub release](https://github.com/prioneto/ClickShift/releases/latest).
2. Unzip it and move `ClickShift.app` to `/Applications`.
3. Open ClickShift once. The Setup Assistant asks you to choose a training app, then guides you through Bluetooth, Accessibility, and finding the right Click.
4. Keep **Launch at login** enabled on the final setup page. ClickShift must be running quietly in the background to notice your riding app launching.

### macOS security notice

The downloadable build is ad-hoc signed but is not notarized with a paid Apple Developer certificate. macOS may block the first launch because it cannot verify the developer.

If that happens:

1. Try to open ClickShift once and dismiss the warning.
2. Open **System Settings → Privacy & Security**.
3. Scroll to **Security** and choose **Open Anyway** for ClickShift.
4. Confirm **Open**.

Only bypass this warning for a build you obtained from this repository. You can also build the app from source instead. See [Apple's guidance for opening an app from an unidentified developer](https://support.apple.com/102445) for more information.

## Using ClickShift

1. Quit Zwift, Zwift Companion, BikeControl, and other apps that might connect to the Click.
2. Open your training app and connect the trainer directly inside that app as usual.
3. Enable virtual shifting in the training app if it requires it. In MyWhoosh, enable **Virtual Shifting**.
4. Press a button on the **right-hand** Click to wake it.
5. Wait for ClickShift's status to change to **Connected**.
6. Use `+` to shift up and `B` to shift down.

Safety mode is enabled by default: ClickShift sends keys only while the selected riding app is the focused application. A blocked press cannot type `I`, `K`, or a custom mapping into another app.

ClickShift identifies the right controller from its Zwift manufacturer data. It deliberately ignores the left controller, avoiding the left side's periodic unlock/restart behavior while still providing both shift directions.

## How it works

ClickShift is a controller-to-keyboard bridge, not a trainer bridge:

1. Your training app connects directly to the trainer and remains responsible for power, cadence, resistance, ERG mode, and the ride.
2. ClickShift separately connects only to the right-hand Zwift Click v2.
3. A Click button press becomes the configured keyboard shortcut, such as `K` or `I` in MyWhoosh.
4. Safety mode sends that shortcut only when your selected training app is focused.

ClickShift never pairs with the trainer, proxies trainer data, or changes trainer resistance itself. Zwift is intentionally excluded because it already supports the Click natively. Choose MyWhoosh, TrainingPeaks Virtual, ROUVY, or enter any other keyboard-controlled training app as a **Custom app**.

## Connection behavior

ClickShift registers itself as a macOS login item on first launch and watches only for the training app you selected:

- **Training app closed:** ClickShift waits without initializing or scanning Bluetooth.
- **Selected training app opened:** ClickShift starts searching for the right Click.
- **Click disconnected:** ClickShift attempts a remembered-device reconnect after about half a second.
- **Mac wakes from sleep:** ClickShift refreshes the riding-app and permission state, restarts Bluetooth, and reconnects automatically.
- **Training app quit:** ClickShift disconnects and stops Bluetooth activity.

The menu-bar panel shows connection state and the current button mapping. Choose **Settings** to open a normal macOS application window with four sidebar pages:

- **General:** app profile, safety mode, notifications, launch-at-login, and connection controls
- **Controls:** Click button mappings, custom keys, gear step, and shift tests
- **Permissions:** Accessibility and Bluetooth access
- **About:** version, privacy, source information, and diagnostics export

### App profiles and mappings

Choose MyWhoosh, TrainingPeaks Virtual, ROUVY, or a custom application name during setup or under **Settings → General**. The selected profile determines which running and focused application ClickShift considers safe; keyboard shortcuts differ between apps, so verify and set the two keys under **Settings → Controls**. Selecting MyWhoosh restores its documented `K`-up and `I`-down defaults.

Zwift is intentionally not a target: it supports the Zwift Click natively, so an extra keyboard bridge is unnecessary.

The right Click’s `+`, `B`, directional, `A`, `Y`, `Z`, and minus buttons can be assigned to either direction. Supported keyboard outputs include letters, numbers, common punctuation, arrows, Page Up, Page Down, Return, and Space.

### Gear step

**Shifts per press** sends the configured key 1, 2, or 3 times. MyWhoosh 5.7 and later also has its own Gear Step Size control; leave either ClickShift or MyWhoosh at `1` to avoid multiplying both settings.

### Menu-bar icon colors

- **Gray:** waiting for the riding app or stopped
- **Orange:** searching, connecting, or waiting for the right Click to wake
- **Green:** controller connected
- **Red:** Bluetooth, connection, or Accessibility problem

## Battery use

Battery impact on the Mac should be negligible:

- While the training app is closed, ClickShift only receives macOS app launch/quit notifications.
- While the training app is open, Bluetooth scanning runs only until the right Click connects.
- Once connected, ClickShift sends one three-byte keepalive every five seconds and otherwise waits for button notifications.

The keepalive keeps the Click awake during a training session, which necessarily uses more of the Click's coin-cell battery than leaving it asleep. ClickShift disconnects as soon as the training app quits.

## Privacy

ClickShift operates locally and does not contain telemetry, analytics, advertising, user accounts, or network communication. It does not read training-app accounts or ride data.

The app stores only small local preferences, such as mappings, profile choice, the remembered CoreBluetooth identifier for the right controller, and launch-at-login state. macOS manages Bluetooth, Accessibility, notification, and login-item permissions.

**Export Diagnostics** creates a plain-text report containing app/macOS version, connection state, permission status, mappings, and recent local status events. It excludes controller identifiers, accounts, ride data, and MyWhoosh data. Nothing is uploaded automatically.

## Troubleshooting

### The right Click is not found

- Press a right-side button to wake it; the controller advertises only briefly after waking.
- Close Zwift, Zwift Companion, BikeControl, and any other controller utility.
- Confirm Bluetooth permission for ClickShift under **System Settings → Privacy & Security → Bluetooth**.
- Replace the CR2032 battery if the controller indicates a low battery.

### ClickShift finds only the left controller

Wake the right controller. ClickShift intentionally ignores the left side.

### Connected, but MyWhoosh does not shift

- Enable Virtual Shifting in MyWhoosh.
- Confirm ClickShift is enabled under **Privacy & Security → Accessibility**.
- Keep MyWhoosh active and use **Test Shift Down** and **Test Shift Up** in **Settings → Controls**.
- Confirm the keys under **Settings → Controls** match the riding app’s shortcuts.
- If the menu says a press was blocked, bring the selected riding app to the front or review safety mode under **Settings → General**.

### It does not start with MyWhoosh

ClickShift itself must already be running. Enable **Open ClickShift when you log in** under **Settings → General**, then check **System Settings → General → Login Items & Extensions** if macOS has disabled it.

### A Click firmware update breaks input

The Click protocol is unofficial and reverse-engineered, so future firmware may change it. [Open a GitHub issue](https://github.com/prioneto/ClickShift/issues) with your Click firmware version and what ClickShift reports.

## Build from source

Requirements: Xcode or Xcode Command Line Tools with Swift 5.10 or later.

```sh
git clone https://github.com/prioneto/ClickShift.git
cd ClickShift
swift test
./scripts/build-app.sh
```

The build script produces `dist/ClickShift.app`, containing both Apple Silicon and Intel architectures. To copy and open it from the command line:

```sh
./scripts/install.sh
```

## Uninstall

1. Turn off **Open ClickShift when you log in** under **ClickShift Settings → General**.
2. Choose **Quit ClickShift**.
3. Move `/Applications/ClickShift.app` to the Trash.
4. Optionally remove ClickShift from the Bluetooth and Accessibility lists in System Settings.

## Limitations

- Right-hand Zwift Click v2 only.
- Third-party profiles require keyboard shortcuts that the target app accepts.
- The public build is ad-hoc signed and not Apple-notarized.
- Hardware behavior may change with future Click firmware.

## License and credits

ClickShift is released under the MIT License. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for attribution and protocol-research credits.
