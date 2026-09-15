<p align="center">
  <img src="Resources/AppIcon.png" width="128" alt="ClickShift icon">
</p>

# ClickShift

ClickShift is a small, free macOS menu-bar utility that lets a **right-hand Zwift Click v2** control virtual shifting in MyWhoosh.

- `+` sends `K` — shift up
- `B` sends `I` — shift down
- Starts connecting automatically when MyWhoosh opens
- Disconnects when MyWhoosh quits so the controller can sleep
- Reconnects automatically if the controller drops or wakes again
- Runs quietly as a menu-bar app with a compact native macOS panel
- Opens controls, permissions, and startup options in a real tabbed Settings window
- No accounts, analytics, advertising, or network service

ClickShift is unofficial and is not affiliated with Zwift or MyWhoosh.

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac
- Zwift Click v2 right controller
- MyWhoosh for macOS with Virtual Shifting enabled

The downloadable app is universal and contains native `arm64` and `x86_64` executables.

## Download and install

1. Download `ClickShift-v1.1.0-macOS-universal.zip` from the [latest GitHub release](https://github.com/prioneto/ClickShift/releases/latest).
2. Unzip it and move `ClickShift.app` to `/Applications`.
3. Open ClickShift once. It appears as a small shift icon in the menu bar.
4. Approve Bluetooth access when macOS asks.
5. Open the ClickShift menu, choose **Settings**, then open the **Permissions** tab and select **Enable Accessibility**. Enable ClickShift under **System Settings → Privacy & Security → Accessibility**.
6. In the **General** tab, keep **Open ClickShift when you log in** enabled. ClickShift must be running quietly in the background to notice MyWhoosh launching.

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
2. Open MyWhoosh.
3. Enable Virtual Shifting in MyWhoosh.
4. Press a button on the **right-hand** Click to wake it.
5. Wait for ClickShift's status to change to **Connected**.
6. Use `+` to shift up and `B` to shift down.

ClickShift identifies the right controller from its Zwift manufacturer data. It deliberately ignores the left controller, avoiding the left side's periodic unlock/restart behavior while still providing both shift directions.

## Automatic behavior

ClickShift registers itself as a macOS login item on first launch. It listens for the installed MyWhoosh app (`com.whoosh.whooshgame`):

- **MyWhoosh closed:** ClickShift waits without initializing or scanning Bluetooth.
- **MyWhoosh opened:** ClickShift starts searching for the right Click.
- **Click disconnected:** ClickShift resumes searching after two seconds.
- **MyWhoosh quit:** ClickShift disconnects and stops Bluetooth activity.

The menu-bar panel shows connection state and the current button mapping. Choose **Settings** to open a normal macOS application window with three tabs:

- **General:** launch-at-login and connection controls
- **Controls:** button mappings and shift tests
- **Permissions:** Accessibility, Bluetooth help, privacy, and version information

## Battery use

Battery impact on the Mac should be negligible:

- While MyWhoosh is closed, ClickShift only receives macOS app launch/quit notifications.
- While MyWhoosh is open, Bluetooth scanning runs only until the right Click connects.
- Once connected, ClickShift sends one three-byte keepalive every five seconds and otherwise waits for button notifications.

The keepalive keeps the Click awake during a MyWhoosh session, which necessarily uses more of the Click's coin-cell battery than leaving it asleep. ClickShift disconnects as soon as MyWhoosh quits.

## Privacy

ClickShift operates locally and does not contain telemetry, analytics, advertising, user accounts, or network communication. It does not read MyWhoosh account or ride data.

The app stores only small local preferences, such as the remembered CoreBluetooth identifier for the right controller and the launch-at-login setup state. macOS manages the Bluetooth, Accessibility, and login-item permissions.

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
- MyWhoosh's current macOS shortcuts must remain `I` for shift down and `K` for shift up.

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
- MyWhoosh must use its `I`/`K` keyboard shortcuts.
- The public build is ad-hoc signed and not Apple-notarized.
- Hardware behavior may change with future Click firmware.

## License and credits

ClickShift is released under the MIT License. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for attribution and protocol-research credits.
