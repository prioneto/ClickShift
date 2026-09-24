import AppKit
import SwiftUI

struct MenuBarPanel: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings
    @ObservedObject var loginController: LaunchAtLoginController

    var body: some View {
        let status = ConnectionStatus(controller: controller, settings: settings)
        let connection = ConnectionStatus(controller: controller, settings: settings, includesPermissions: false)

        VStack(alignment: .leading, spacing: 0) {
            header(status)

            PanelSeparator()

            PanelSectionLabel(text: "Status")
            PanelDeviceRow(
                symbol: "gamecontroller.fill",
                title: "Zwift Click v2",
                subtitle: connection.title,
                tone: connection.tone,
                showsProgress: connection.tone == .working
            )
            PanelDeviceRow(
                symbol: "figure.indoor.cycle",
                title: settings.targetName,
                subtitle: controller.myWhooshRunning ? "Open" : "Not running",
                tone: controller.myWhooshRunning ? .ready : .idle
            )

            if connection.tone == .working || connection.tone == .problem {
                Text(connection.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                    .padding(.top, 2)
                    .padding(.bottom, 4)
            }

            if !controller.accessibilityGranted {
                accessibilityCallout
            }

            PanelSeparator()

            PanelSectionLabel(text: "Shifting")
            PanelMappingRow(
                title: "Shift up",
                symbol: "arrow.up",
                button: settings.upButton.displayName,
                key: settings.upKey
            )
            PanelMappingRow(
                title: "Shift down",
                symbol: "arrow.down",
                button: settings.downButton.displayName,
                key: settings.downKey
            )

            if controller.lastAction != "No shifts yet" {
                Label(controller.lastAction, systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .padding(.bottom, 2)
            }

            PanelSeparator()

            if controller.state == .stopped {
                Button("Start ClickShift") { controller.start() }
                    .buttonStyle(PanelRowButtonStyle(symbol: "play.fill"))
                    .hiddenFocusRing()
            } else {
                Button("Reconnect") { controller.reconnectNow() }
                    .buttonStyle(PanelRowButtonStyle(symbol: "arrow.clockwise"))
                    .disabled(!controller.myWhooshRunning)
                    .hiddenFocusRing()
            }

            Button("Settings…") { openSettings() }
                .buttonStyle(PanelRowButtonStyle(symbol: "gearshape", shortcut: "⌘,"))
                .keyboardShortcut(",", modifiers: .command)
                .hiddenFocusRing()

            PanelSeparator()

            Button("Quit ClickShift") { NSApplication.shared.terminate(nil) }
                .buttonStyle(PanelRowButtonStyle(symbol: "power", shortcut: "⌘Q"))
                .keyboardShortcut("q", modifiers: .command)
                .hiddenFocusRing()
        }
        .padding(6)
        .frame(width: 290)
        .onAppear {
            controller.refreshPermissions()
            loginController.refresh()
        }
    }

    private func header(_ status: ConnectionStatus) -> some View {
        HStack(spacing: 9) {
            AppIconImage(size: 24)
            Text("ClickShift")
                .font(.system(size: 13, weight: .semibold))
            Spacer(minLength: 8)
            StatusBadge(status: status)
        }
        .padding(.horizontal, 8)
        .padding(.top, 5)
        .padding(.bottom, 3)
    }

    private var accessibilityCallout: some View {
        HStack(alignment: .center, spacing: 9) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 1) {
                Text("Accessibility needed")
                    .font(.system(size: 12, weight: .semibold))
                Text("Required to send shift keys")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 6)

            Button("Allow…") { controller.requestAccessibility() }
                .controlSize(.small)
                .hiddenFocusRing()
        }
        .padding(9)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    private func openSettings() {
        DispatchQueue.main.async {
            SettingsWindowController.shared.show(
                controller: controller,
                settings: settings,
                loginController: loginController
            )
        }
    }
}

private struct PanelSectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.top, 3)
            .padding(.bottom, 4)
    }
}

private struct PanelSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
    }
}

private struct PanelDeviceRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    let tone: ConnectionStatus.Tone
    var showsProgress = false

    var body: some View {
        HStack(spacing: 10) {
            StatusGlyph(symbol: symbol, tone: tone, size: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if showsProgress {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct PanelMappingRow: View {
    let title: String
    let symbol: String
    let button: String
    let key: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 13))

            Spacer(minLength: 8)

            ClickButtonCap(text: button)
            Image(systemName: "arrow.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
            Keycap(text: key)
        }
        .padding(.horizontal, 8)
        .frame(height: 26)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(button) button sends \(key)")
    }
}

/// Menu-item style row: full-width, hover highlight, optional shortcut hint.
private struct PanelRowButtonStyle: ButtonStyle {
    let symbol: String
    var shortcut: String?

    func makeBody(configuration: Configuration) -> some View {
        PanelRow(configuration: configuration, symbol: symbol, shortcut: shortcut)
    }

    private struct PanelRow: View {
        let configuration: ButtonStyleConfiguration
        let symbol: String
        let shortcut: String?

        @Environment(\.isEnabled) private var isEnabled
        @State private var isHovered = false

        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                configuration.label
                    .font(.system(size: 13))

                Spacer(minLength: 8)

                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .opacity(isEnabled ? 1 : 0.4)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(highlightOpacity))
            }
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
        }

        private var highlightOpacity: Double {
            guard isEnabled else { return 0 }
            if configuration.isPressed { return 0.14 }
            return isHovered ? 0.08 : 0
        }
    }
}
