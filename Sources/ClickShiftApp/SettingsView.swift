import AppKit
import ClickShiftCore
import SwiftUI
import UniformTypeIdentifiers

private enum SettingsPage: String, CaseIterable, Identifiable {
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
        case .general: return "gearshape.fill"
        case .controls: return "arrow.up.arrow.down"
        case .permissions: return "hand.raised.fill"
        case .about: return "info"
        }
    }

    var tint: Color {
        switch self {
        case .general: return Color(nsColor: .systemGray)
        case .controls: return Brand.blue
        case .permissions: return Color(nsColor: .systemIndigo)
        case .about: return Brand.navy
        }
    }
}

struct SettingsView: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings
    @ObservedObject var loginController: LaunchAtLoginController
    @State private var page: SettingsPage = .general

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(
                selection: $page,
                status: ConnectionStatus(controller: controller, settings: settings)
            )
            .frame(width: 210)

            Rectangle()
                .fill(Surface.separator)
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 0) {
                Text(page.title)
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 28)
                    .frame(height: 52)

                ScrollView {
                    pageContent
                        .padding(.horizontal, 28)
                        .padding(.top, 4)
                        .padding(.bottom, 28)
                        .frame(maxWidth: 640, alignment: .topLeading)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .scrollIndicators(.automatic)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .ignoresSafeArea()
        .frame(minWidth: 680, idealWidth: 740, minHeight: 460, idealHeight: 540)
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refresh()
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case .general:
            GeneralSettingsPage(controller: controller, settings: settings, loginController: loginController)
        case .controls:
            ControlsSettingsPage(controller: controller, settings: settings)
        case .permissions:
            PermissionsSettingsPage(controller: controller)
        case .about:
            AboutSettingsPage(controller: controller, settings: settings)
        }
    }

    private func refresh() {
        controller.refreshPermissions()
        loginController.refresh()
    }
}

// MARK: - Sidebar

private struct SettingsSidebar: View {
    @Binding var selection: SettingsPage
    let status: ConnectionStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                AppIconImage(size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("ClickShift")
                        .font(.system(size: 13, weight: .semibold))
                    Text(AppInfo.versionLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)
            .padding(.bottom, 16)

            VStack(spacing: 2) {
                ForEach(SettingsPage.allCases) { page in
                    SidebarItem(page: page, isSelected: selection == page) {
                        selection = page
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer(minLength: 16)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Circle()
                    .fill(status.tone.color)
                    .frame(width: 7, height: 7)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1 }
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.title)
                        .font(.system(size: 11, weight: .medium))
                    Text(status.detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
            .accessibilityElement(children: .combine)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(VisualEffectBackground(material: .sidebar))
    }
}

private struct SidebarItem: View {
    let page: SettingsPage
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                SymbolTile(symbol: page.symbol, color: page.tint, size: 22)
                Text(page.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7)
            .frame(height: 32)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(isSelected ? 0.1 : (isHovered ? 0.045 : 0)))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hiddenFocusRing()
        .onHover { isHovered = $0 }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Pages

private struct GeneralSettingsPage: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings
    @ObservedObject var loginController: LaunchAtLoginController

    var body: some View {
        let status = ConnectionStatus(controller: controller, settings: settings)

        VStack(alignment: .leading, spacing: 24) {
            SettingsGroup {
                HStack(spacing: 12) {
                    StatusGlyph(symbol: status.symbol, tone: status.tone, size: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.title)
                            .font(.system(size: 13, weight: .semibold))
                        Text(status.detail)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    if controller.state == .stopped {
                        Button("Start") { controller.start() }
                    } else {
                        Button("Reconnect") { controller.reconnectNow() }
                            .disabled(!controller.myWhooshRunning)
                        Button("Stop") { controller.stop() }
                    }
                }
                .padding(14)
            }

            SettingsGroup(
                "Training app",
                footer: "ClickShift waits for this app, then scans only for the right Click while it’s open. Your trainer stays connected directly to the app."
            ) {
                SettingsRow("App") {
                    Picker("App", selection: Binding(
                        get: { settings.profile },
                        set: { settings.selectProfile($0) }
                    )) {
                        ForEach(AppSettings.Profile.allCases) { profile in
                            Text(profile.title).tag(profile)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }

                if settings.profile == .custom {
                    SettingsDivider()
                    SettingsRow("Application name", detail: "Exactly as it appears in the Dock") {
                        TextField("App name", text: $settings.customAppName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                    }
                }

                SettingsDivider()

                SettingsRow("Only send keys to \(settings.targetName)", detail: "Blocks shifts while another app is in front") {
                    SettingsToggle("Only send keys to \(settings.targetName)", isOn: $settings.onlySendToTarget)
                }
            }

            SettingsGroup("Startup & alerts") {
                SettingsRow("Open at login", detail: "Stay ready to notice when your training app opens") {
                    SettingsToggle("Open at login", isOn: Binding(
                        get: { loginController.isEnabled },
                        set: { loginController.setEnabled($0) }
                    ))
                }

                if let error = loginController.errorMessage {
                    SettingsDivider()
                    NoticeRow(text: error, symbol: "exclamationmark.triangle.fill", color: .red)
                }

                SettingsDivider()

                SettingsRow("Notifications", detail: "Connection, disconnection, and permission alerts") {
                    SettingsToggle("Notifications", isOn: Binding(
                        get: { settings.notificationsEnabled },
                        set: { enabled in
                            settings.notificationsEnabled = enabled
                            if enabled { NotificationManager.shared.requestAuthorization() }
                        }
                    ))
                }
            }

            SettingsGroup("Setup") {
                SettingsRow("Setup Assistant", detail: "Choose an app, grant permissions, and pair your Click again") {
                    Button("Open…") {
                        SetupWindowController.shared.show(
                            controller: controller,
                            settings: settings,
                            loginController: loginController
                        )
                    }
                }
            }
        }
    }
}

private struct ControlsSettingsPage: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsGroup(
                "Button mapping",
                footer: "Use a letter, number, punctuation, Up, Down, Left, Right, Page Up, Page Down, Return, or Space. MyWhoosh uses K to shift up and I to shift down."
            ) {
                MappingRow(title: "Shift up", symbol: "arrow.up", button: $settings.upButton, key: $settings.upKey)
                SettingsDivider()
                MappingRow(title: "Shift down", symbol: "arrow.down", button: $settings.downButton, key: $settings.downKey)

                if settings.upButton == settings.downButton {
                    SettingsDivider()
                    NoticeRow(
                        text: "Choose two different Click buttons so one press can’t shift both ways.",
                        symbol: "exclamationmark.triangle.fill",
                        color: .orange
                    )
                }

                ForEach(unsupportedKeys, id: \.self) { key in
                    SettingsDivider()
                    NoticeRow(
                        text: key.isEmpty ? "Enter a key for each direction." : "“\(key)” isn’t a supported key.",
                        symbol: "exclamationmark.triangle.fill",
                        color: .orange
                    )
                }
            }

            SettingsGroup(
                "Gear step",
                footer: "If \(settings.targetName) has its own gear-step setting, keep one of them at 1 so jumps don’t multiply."
            ) {
                SettingsRow("Shifts per press", detail: "Repeats the key on every press") {
                    Picker("Shifts per press", selection: $settings.gearStep) {
                        ForEach(1...3, id: \.self) { step in
                            Text("\(step)").tag(step)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }

            SettingsGroup("Test") {
                SettingsRow("Try a shift", detail: testDetail) {
                    HStack(spacing: 8) {
                        Button {
                            controller.testShiftDown()
                        } label: {
                            Label("Down", systemImage: "arrow.down")
                        }
                        Button {
                            controller.testShiftUp()
                        } label: {
                            Label("Up", systemImage: "arrow.up")
                        }
                    }
                }
            }
        }
    }

    private var unsupportedKeys: [String] {
        var keys: [String] = []
        for key in [settings.upKey, settings.downKey] where !KeyboardShifter.isSupported(key: key) && !keys.contains(key) {
            keys.append(key)
        }
        return keys
    }

    private var testDetail: String {
        controller.lastAction == "No shifts yet"
            ? "Brings \(settings.targetName) to the front and sends one shift"
            : controller.lastAction
    }
}

private struct PermissionsSettingsPage: View {
    @ObservedObject var controller: ClickController

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsGroup(
                footer: "ClickShift never reads what you type. Accessibility is used only to send your shifting shortcuts."
            ) {
                PermissionRow(
                    title: "Accessibility",
                    detail: "Sends your configured shift keys",
                    symbol: "accessibility",
                    tint: .blue,
                    isGranted: controller.accessibilityGranted
                ) {
                    Button("Allow…") { controller.requestAccessibility() }
                        .buttonStyle(.borderedProminent)
                }

                SettingsDivider()

                PermissionRow(
                    title: "Bluetooth",
                    detail: "Connects only to the right Click, never your trainer",
                    symbol: "antenna.radiowaves.left.and.right",
                    tint: .blue,
                    isGranted: controller.bluetoothAuthorizationGranted
                ) {
                    Button("Open Settings…") { openPrivacySettings(anchor: "Privacy_Bluetooth") }
                }
            }

            Button("Open Privacy & Security…") { openPrivacySettings(anchor: "Privacy_Accessibility") }
        }
    }

    private func openPrivacySettings(anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct AboutSettingsPage: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                AppIconImage(size: 76)
                    .padding(.bottom, 4)
                Text("ClickShift")
                    .font(.system(size: 20, weight: .bold))
                Text(AppInfo.versionLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("Zwift Click shifting for training apps without native Click support.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)

            SettingsGroup {
                SettingsRow("Private by design", detail: "No accounts, analytics, ads, or network access") {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.green)
                        .accessibilityLabel("Private")
                }

                SettingsDivider()

                SettingsRow("Source code", detail: "Open source under the MIT License") {
                    Button {
                        if let url = URL(string: "https://github.com/prioneto/ClickShift") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Label("GitHub", systemImage: "arrow.up.forward")
                    }
                }

                SettingsDivider()

                SettingsRow("Diagnostics", detail: "Save a privacy-safe report for troubleshooting") {
                    Button("Export…") {
                        DiagnosticsExporter.export(controller: controller, settings: settings)
                    }
                }
            }

            Text("Unofficial · Not affiliated with Zwift or MyWhoosh")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Building blocks

private struct SettingsGroup<Content: View>: View {
    let title: String?
    let footer: String?
    let content: Content

    init(_ title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity)
            .background(Surface.groupFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Surface.groupBorder, lineWidth: 1)
            }

            if let footer {
                Text(footer)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
    }
}

private struct SettingsRow<Accessory: View>: View {
    let title: String
    let detail: String?
    let accessory: Accessory

    init(_ title: String, detail: String? = nil, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.detail = detail
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                if let detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            accessory
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
    }
}

private struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool

    init(_ title: String, isOn: Binding<Bool>) {
        self.title = title
        _isOn = isOn
    }

    var body: some View {
        Toggle(title, isOn: $isOn)
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Surface.separator)
            .frame(height: 1)
            .padding(.horizontal, 14)
    }
}

private struct NoticeRow: View {
    let text: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            Text(text)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(.system(size: 12))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct PermissionRow<Action: View>: View {
    let title: String
    let detail: String
    let symbol: String
    let tint: Color
    let isGranted: Bool
    let action: Action

    init(
        title: String,
        detail: String,
        symbol: String,
        tint: Color,
        isGranted: Bool,
        @ViewBuilder action: () -> Action
    ) {
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.tint = tint
        self.isGranted = isGranted
        self.action = action()
    }

    var body: some View {
        HStack(spacing: 12) {
            SymbolTile(symbol: symbol, color: tint, size: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if isGranted {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Allowed")
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 12))
            } else {
                action
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 52)
    }
}

private struct MappingRow: View {
    let title: String
    let symbol: String
    @Binding var button: ClickButton
    @Binding var key: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 13))

            Spacer(minLength: 12)

            Picker("Click button for \(title.lowercased())", selection: $button) {
                ForEach(ClickButton.allCases, id: \.self) { candidate in
                    Text(candidate.menuTitle).tag(candidate)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()

            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)

            TextField("Key", text: $key)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .frame(width: 88)
                .accessibilityLabel("Key for \(title.lowercased())")
                .onChange(of: key) { value in
                    let normalized = value.uppercased()
                    if normalized != value { key = normalized }
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
    }
}

private extension ClickButton {
    var menuTitle: String {
        switch self {
        case .plus: return "+ button"
        case .minus: return "− button"
        case .a, .b, .y, .z: return "\(displayName) button"
        case .up, .down, .left, .right: return "D-pad \(displayName.lowercased())"
        }
    }
}

private enum DiagnosticsExporter {
    @MainActor
    static func export(controller: ClickController, settings: AppSettings) {
        let panel = NSSavePanel()
        panel.title = "Export ClickShift Diagnostics"
        panel.nameFieldStringValue = "ClickShift-Diagnostics.txt"
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try controller.diagnosticsReport().write(to: url, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
}
