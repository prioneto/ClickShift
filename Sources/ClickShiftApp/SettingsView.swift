import AppKit
import SwiftUI

private enum SettingsDestination: String, CaseIterable, Identifiable {
    case general
    case controls
    case permissions
    case about

    var id: Self { self }

    var title: String {
        switch self {
        case .general: return "General"
        case .controls: return "Controls"
        case .permissions: return "Permissions"
        case .about: return "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .controls: return "arrow.up.arrow.down"
        case .permissions: return "hand.raised"
        case .about: return "info.circle"
        }
    }

    var subtitle: String {
        switch self {
        case .general: return "Startup and connection behavior"
        case .controls: return "Click mappings and shift tests"
        case .permissions: return "Access required for shifting"
        case .about: return "Version, privacy, and source"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var loginController: LaunchAtLoginController
    @State private var selection: SettingsDestination? = .general

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    Section {
                        ForEach(SettingsDestination.allCases) { destination in
                            Label(destination.title, systemImage: destination.symbol)
                                .font(.system(size: 13, weight: .medium))
                                .padding(.vertical, 2)
                                .listRowInsets(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
                                .tag(destination)
                        }
                    }
                }
                .listStyle(.sidebar)
                .padding(.top, 8)

                Divider()
                sidebarFooter
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 215)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    pageHeader
                    selectedPage
                }
                .padding(.horizontal, 30)
                .padding(.top, 26)
                .padding(.bottom, 34)
                .frame(maxWidth: 680, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 760, idealWidth: 790, minHeight: 520, idealHeight: 560)
        .onAppear {
            controller.refreshPermissions()
            loginController.refresh()
        }
    }

    private var sidebarFooter: some View {
        HStack(spacing: 9) {
            SettingsAppIcon(size: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text("ClickShift")
                    .font(.caption.weight(.semibold))
                Text(versionLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 13)
        .padding(.bottom, 15)
    }

    private var pageHeader: some View {
        let destination = selection ?? .general
        return VStack(alignment: .leading, spacing: 5) {
            Text(destination.title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text(destination.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var selectedPage: some View {
        switch selection ?? .general {
        case .general:
            GeneralSettingsPage(
                controller: controller,
                loginController: loginController
            )
        case .controls:
            ControlsSettingsPage(controller: controller)
        case .permissions:
            PermissionsSettingsPage(controller: controller)
        case .about:
            AboutSettingsPage(versionLabel: versionLabel)
        }
    }

    private var versionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "Version \(version ?? "Development")"
    }
}

private struct GeneralSettingsPage: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var loginController: LaunchAtLoginController

    var body: some View {
        VStack(spacing: 18) {
            SettingsCard(title: "SYSTEM") {
                SettingsRow(
                    title: "Launch at login",
                    detail: "Stay ready to detect MyWhoosh",
                    symbol: "power"
                ) {
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { loginController.isEnabled },
                            set: { loginController.setEnabled($0) }
                        )
                    )
                    .labelsHidden()
                }
            }

            if let error = loginController.errorMessage {
                InlineNotice(text: error, color: .red, symbol: "exclamationmark.triangle.fill")
            }

            SettingsCard(title: "CONNECTION") {
                SettingsRow(
                    title: "MyWhoosh",
                    detail: controller.myWhooshRunning ? "Detected on this Mac" : "ClickShift is waiting quietly",
                    symbol: "play.rectangle"
                ) {
                    StatusValue(
                        text: controller.myWhooshRunning ? "Open" : "Closed",
                        color: controller.myWhooshRunning ? .green : .secondary
                    )
                }

                CardDivider()

                SettingsRow(
                    title: "Right Click v2",
                    detail: controller.state.label,
                    symbol: "dot.radiowaves.left.and.right"
                ) {
                    StatusValue(
                        text: controller.state.isConnected ? "Connected" : "Waiting",
                        color: controller.state.isConnected ? .green : .secondary
                    )
                }

                CardDivider()

                HStack(spacing: 8) {
                    if controller.state == .stopped {
                        Button("Start ClickShift") { controller.start() }
                    } else {
                        Button("Reconnect") { controller.reconnectNow() }
                            .disabled(!controller.myWhooshRunning)
                        Button("Stop") { controller.stop() }
                    }
                    Spacer()
                }
                .padding(14)
            }

            InlineNotice(
                text: "Bluetooth scanning starts only while MyWhoosh is open and stops as soon as it closes.",
                color: .secondary,
                symbol: "leaf"
            )
        }
    }
}

private struct ControlsSettingsPage: View {
    @ObservedObject var controller: ClickController

    var body: some View {
        VStack(spacing: 18) {
            SettingsCard(title: "BUTTON MAPPING") {
                MappingSettingsRow(button: "+", action: "Shift up", output: "K", symbol: "arrow.up")
                CardDivider()
                MappingSettingsRow(button: "B", action: "Shift down", output: "I", symbol: "arrow.down")
            }

            InlineNotice(
                text: "MyWhoosh must keep its default shortcuts: K for up and I for down.",
                color: .secondary,
                symbol: "keyboard"
            )

            SettingsCard(title: "TEST SHIFTING") {
                HStack(spacing: 10) {
                    Button {
                        controller.testShiftDown()
                    } label: {
                        Label("Shift Down", systemImage: "arrow.down")
                    }

                    Button {
                        controller.testShiftUp()
                    } label: {
                        Label("Shift Up", systemImage: "arrow.up")
                    }

                    Spacer()
                    Text(controller.lastAction)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
            }
        }
    }
}

private struct PermissionsSettingsPage: View {
    @ObservedObject var controller: ClickController

    var body: some View {
        VStack(spacing: 18) {
            SettingsCard(title: "ACCESSIBILITY") {
                SettingsRow(
                    title: "Keyboard control",
                    detail: "Sends only the I and K shortcuts",
                    symbol: "keyboard.badge.ellipsis"
                ) {
                    StatusValue(
                        text: controller.accessibilityGranted ? "Allowed" : "Required",
                        color: controller.accessibilityGranted ? .green : .orange
                    )
                }

                CardDivider()

                HStack(spacing: 8) {
                    Button(controller.accessibilityGranted ? "Open System Settings" : "Enable Accessibility") {
                        if controller.accessibilityGranted {
                            openSystemSettings(anchor: "Privacy_Accessibility")
                        } else {
                            controller.requestAccessibility()
                        }
                    }
                    Button("Refresh") { controller.refreshPermissions() }
                    Spacer()
                }
                .padding(14)
            }

            SettingsCard(title: "BLUETOOTH") {
                SettingsRow(
                    title: "Zwift Click access",
                    detail: "Used only while MyWhoosh is open",
                    symbol: "wave.3.right"
                ) {
                    Button("Open Settings") {
                        openSystemSettings(anchor: "Privacy_Bluetooth")
                    }
                }
            }

            InlineNotice(
                text: "ClickShift doesn’t read what you type. Accessibility is used only to send virtual-shifting shortcuts.",
                color: .secondary,
                symbol: "lock.shield"
            )
        }
    }

    private func openSystemSettings(anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct AboutSettingsPage: View {
    let versionLabel: String

    var body: some View {
        VStack(spacing: 18) {
            SettingsCard(title: "CLICKSHIFT") {
                HStack(spacing: 16) {
                    SettingsAppIcon(size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ClickShift")
                            .font(.title3.weight(.semibold))
                        Text(versionLabel)
                            .foregroundStyle(.secondary)
                        Text("Virtual shifting for MyWhoosh with the right Zwift Click v2.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
            }

            SettingsCard(title: "PRIVACY") {
                SettingsRow(
                    title: "Local by design",
                    detail: "No accounts, analytics, ads, or network service",
                    symbol: "hand.raised.fill"
                ) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            HStack {
                Link("View source on GitHub", destination: URL(string: "https://github.com/prioneto/ClickShift")!)
                Spacer()
                Text("Unofficial · Not affiliated with Zwift or MyWhoosh")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.5)
            }
        }
    }
}

private struct SettingsRow<Trailing: View>: View {
    let title: String
    let detail: String
    let symbol: String
    let trailing: Trailing

    init(
        title: String,
        detail: String,
        symbol: String,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)
            trailing
        }
        .padding(14)
    }
}

private struct MappingSettingsRow: View {
    let button: String
    let action: String
    let output: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Text(button)
                .font(.system(.body, design: .rounded, weight: .bold))
                .frame(width: 34, height: 34)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            Label(action, systemImage: symbol)
                .font(.subheadline.weight(.medium))
            Spacer()
            Text("Sends \(output)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
    }
}

private struct StatusValue: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.1), in: Capsule())
    }
}

private struct InlineNotice: View {
    let text: String
    let color: Color
    let symbol: String

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

private struct CardDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 56)
    }
}

private struct SettingsAppIcon: View {
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
