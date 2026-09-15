import AppKit
import SwiftUI

@main
struct ClickShiftApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var controller: ClickController
    @StateObject private var loginController: LaunchAtLoginController

    init() {
        let settings = AppSettings()
        let controller = ClickController(settings: settings)
        let loginController = LaunchAtLoginController()
        _settings = StateObject(wrappedValue: settings)
        _controller = StateObject(wrappedValue: controller)
        _loginController = StateObject(wrappedValue: loginController)

        if !settings.didCompleteSetup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                SetupWindowController.shared.show(
                    controller: controller,
                    settings: settings,
                    loginController: loginController
                )
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel(
                controller: controller,
                settings: settings,
                loginController: loginController
            )
        } label: {
            if let icon = AppAssets.tintedImage(
                named: "MenuBarIcon",
                color: menuBarNSColor,
                size: NSSize(width: 18, height: 18)
            ) {
                Image(nsImage: icon)
                    .renderingMode(.original)
            } else {
                Image(systemName: controller.state.isConnected ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle")
                    .foregroundStyle(menuBarColor)
            }
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    SettingsWindowController.shared.show(
                        controller: controller,
                        settings: settings,
                        loginController: loginController
                    )
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }

    private var menuBarColor: Color {
        if !controller.accessibilityGranted && controller.myWhooshRunning { return .red }
        switch controller.state {
        case .connected: return .green
        case .scanning, .connecting, .reconnecting, .foundLeft, .waitingForWake: return .orange
        case .bluetoothOff, .failed: return .red
        case .waitingForMyWhoosh, .stopped: return .secondary
        }
    }

    private var menuBarNSColor: NSColor {
        if !controller.accessibilityGranted && controller.myWhooshRunning { return .systemRed }
        switch controller.state {
        case .connected: return .systemGreen
        case .scanning, .connecting, .reconnecting, .foundLeft, .waitingForWake: return .systemOrange
        case .bluetoothOff, .failed: return .systemRed
        case .waitingForMyWhoosh, .stopped: return .secondaryLabelColor
        }
    }
}

private struct MenuBarPanel: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings
    @ObservedObject var loginController: LaunchAtLoginController

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            connectionSummary
            Divider()
            shiftSummary
            footer
        }
        .padding(16)
        .frame(width: 324)
        .onAppear {
            controller.refreshPermissions()
            loginController.refresh()
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            AppIconView(size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("ClickShift")
                    .font(.headline)
                Text("Virtual shifting for \(settings.targetName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .accessibilityLabel(controller.state.label)
        }
    }

    private var connectionSummary: some View {
        HStack(spacing: 10) {
            Image(systemName: statusSymbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(statusColor)
                .frame(width: 30, height: 30)
                .background(statusColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(connectionTitle)
                    .font(.subheadline.weight(.semibold))
                Text(connectionDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if controller.myWhooshRunning && !controller.state.isConnected {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var shiftSummary: some View {
        VStack(spacing: 9) {
            HStack {
                ShiftMapping(key: settings.upButton.displayName, direction: "Up", shortcut: settings.upKey, symbol: "arrow.up")
                Divider().frame(height: 30)
                ShiftMapping(key: settings.downButton.displayName, direction: "Down", shortcut: settings.downKey, symbol: "arrow.down")
            }

            if controller.lastAction != "No shifts yet" {
                Text(controller.lastAction)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Divider()

            HStack(spacing: 8) {
                if controller.state == .stopped {
                    Button("Start") { controller.start() }
                } else {
                    Button("Reconnect") { controller.reconnectNow() }
                        .disabled(!controller.myWhooshRunning)
                }

                Spacer()

                OpenSettingsButton(
                    controller: controller,
                    settings: settings,
                    loginController: loginController
                )

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .controlSize(.small)
        }
    }

    private var connectionTitle: String {
        if !controller.accessibilityGranted && controller.myWhooshRunning { return "Accessibility needed" }
        if controller.state.isConnected { return "Click v2 connected" }
        if !controller.myWhooshRunning { return "Waiting for \(settings.targetName)" }
        if controller.state == .stopped { return "ClickShift paused" }
        return controller.state.label
    }

    private var connectionDetail: String {
        if !controller.accessibilityGranted && controller.myWhooshRunning { return "Open Settings → Permissions to allow shifting" }
        if controller.state.isConnected { return "\(settings.targetName) is open · Ready to shift" }
        if !controller.myWhooshRunning { return "Connects automatically when it opens" }
        if controller.state == .stopped { return "Start it when you’re ready" }
        return "Wake the right controller if needed"
    }

    private var statusSymbol: String {
        switch controller.state {
        case .connected: return "checkmark.circle.fill"
        case .bluetoothOff, .failed: return "exclamationmark.triangle.fill"
        case .waitingForMyWhoosh, .stopped: return "moon.zzz.fill"
        default: return "dot.radiowaves.left.and.right"
        }
    }

    private var statusColor: Color {
        switch controller.state {
        case .connected: return .green
        case .bluetoothOff, .failed: return .red
        case .waitingForMyWhoosh, .stopped: return .secondary
        default: return .orange
        }
    }
}

private struct OpenSettingsButton: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings
    @ObservedObject var loginController: LaunchAtLoginController

    var body: some View {
        Button {
            DispatchQueue.main.async {
                SettingsWindowController.shared.show(
                    controller: controller,
                    settings: settings,
                    loginController: loginController
                )
            }
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
    }
}

private struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let icon = AppAssets.image(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.tint)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct ShiftMapping: View {
    let key: String
    let direction: String
    let shortcut: String
    let symbol: String

    var body: some View {
        HStack(spacing: 8) {
            Text(key)
                .font(.system(.body, design: .rounded, weight: .bold))
                .frame(width: 26, height: 26)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Label(direction, systemImage: symbol)
                    .font(.caption.weight(.semibold))
                Text("Sends \(shortcut)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}
