import AppKit
import SwiftUI

@main
struct ClickShiftApp: App {
    @StateObject private var controller = ClickController()
    @StateObject private var loginController = LaunchAtLoginController()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel(
                controller: controller,
                loginController: loginController
            )
        } label: {
            if let icon = AppAssets.image(
                named: "MenuBarIcon",
                template: true,
                size: NSSize(width: 18, height: 18)
            ) {
                Image(nsImage: icon)
            } else {
                Image(systemName: controller.state.isConnected ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle")
            }
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarPanel: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var loginController: LaunchAtLoginController

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            statusCard
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
                Text("Virtual shifting for MyWhoosh")
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

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: statusSymbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(statusColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    Text(controller.state.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                if controller.myWhooshRunning && !controller.state.isConnected {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            HStack(spacing: 6) {
                StatusPill(
                    title: "MyWhoosh",
                    symbol: controller.myWhooshRunning ? "play.fill" : "pause.fill",
                    isActive: controller.myWhooshRunning
                )
                StatusPill(
                    title: "Click v2",
                    symbol: controller.state.isConnected ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash",
                    isActive: controller.state.isConnected
                )
            }
        }
        .padding(12)
        .clickShiftStatusSurface()
    }

    private var shiftSummary: some View {
        VStack(spacing: 9) {
            HStack {
                ShiftMapping(key: "+", direction: "Up", shortcut: "K", symbol: "arrow.up")
                Divider().frame(height: 30)
                ShiftMapping(key: "B", direction: "Down", shortcut: "I", symbol: "arrow.down")
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

    private var statusTitle: String {
        if controller.state.isConnected { return "Ready to shift" }
        if !controller.myWhooshRunning { return "Standing by" }
        return "Getting ready"
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
    @ObservedObject var loginController: LaunchAtLoginController

    var body: some View {
        Button {
            DispatchQueue.main.async {
                SettingsWindowController.shared.show(
                    controller: controller,
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

private struct StatusPill: View {
    let title: String
    let symbol: String
    let isActive: Bool

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.caption2.weight(.medium))
            .foregroundStyle(isActive ? Color.primary : Color.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.background.opacity(0.7), in: Capsule())
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

private extension View {
    @ViewBuilder
    func clickShiftStatusSurface() -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
