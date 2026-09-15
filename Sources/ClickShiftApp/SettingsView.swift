import AppKit
import ClickShiftCore
import SwiftUI
import UniformTypeIdentifiers

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

    var accent: Color {
        switch self {
        case .general: return Color(red: 0.35, green: 0.68, blue: 1.0)
        case .controls: return Color(red: 0.38, green: 0.86, blue: 0.78)
        case .permissions: return Color(red: 0.67, green: 0.53, blue: 1.0)
        case .about: return Color(red: 1.0, green: 0.63, blue: 0.39)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings
    @ObservedObject var loginController: LaunchAtLoginController
    @State private var selection: SettingsDestination? = .general

    var body: some View {
        ZStack {
            SettingsBackdrop()

            HStack(spacing: 0) {
                sidebar

                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 1)

                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        pageHeader
                        selectedPage
                            .buttonStyle(ModernButtonStyle())
                    }
                    .padding(.horizontal, 34)
                    .padding(.top, 46)
                    .padding(.bottom, 38)
                    .frame(maxWidth: 710, alignment: .topLeading)
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .preferredColorScheme(.dark)
        .frame(minWidth: 800, idealWidth: 840, minHeight: 550, idealHeight: 600)
        .onAppear {
            controller.refreshPermissions()
            loginController.refresh()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                SettingsAppIcon(size: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ClickShift")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("CONTROL CENTER")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 44)
            .padding(.bottom, 28)

            VStack(spacing: 8) {
                ForEach(SettingsDestination.allCases) { destination in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            selection = destination
                        }
                    } label: {
                        HStack(spacing: 11) {
                            Image(systemName: destination.symbol)
                                .font(.system(size: 13, weight: .semibold))
                                .frame(width: 30, height: 30)
                                .background(
                                    destination.accent.opacity(selection == destination ? 0.2 : 0.09),
                                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                                )

                            Text(destination.title)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))

                            Spacer()

                            if selection == destination {
                                Circle()
                                    .fill(destination.accent)
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .foregroundStyle(selection == destination ? Color.white : Color.white.opacity(0.62))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background {
                            if selection == destination {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(destination.accent.opacity(0.14))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .strokeBorder(destination.accent.opacity(0.22), lineWidth: 0.7)
                                }
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(connectionColor)
                        .frame(width: 7, height: 7)
                    Text(connectionLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.72))
                }

                Text(versionLabel)
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.32))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.7)
            }
            .padding(14)
        }
        .frame(width: 210)
        .background(Color.black.opacity(0.16))
    }

    private var pageHeader: some View {
        let destination = selection ?? .general
        return HStack(spacing: 15) {
            Image(systemName: destination.symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(destination.accent)
                .frame(width: 42, height: 42)
                .background(destination.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(destination.accent.opacity(0.18), lineWidth: 0.7)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(destination.title)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                Text(destination.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.48))
            }

            Spacer()
        }
    }

    private var connectionColor: Color {
        switch controller.state {
        case .connected: return .green
        case .scanning, .connecting, .reconnecting, .foundLeft, .waitingForWake: return .orange
        case .bluetoothOff, .failed: return .red
        case .waitingForMyWhoosh, .stopped: return Color.white.opacity(0.35)
        }
    }

    private var connectionLabel: String {
        if controller.state.isConnected { return "Click connected" }
        if controller.myWhooshRunning { return controller.state.label }
        return "Waiting for \(settings.targetName)"
    }

    @ViewBuilder
    private var selectedPage: some View {
        switch selection ?? .general {
        case .general:
            GeneralSettingsPage(
                controller: controller,
                settings: settings,
                loginController: loginController
            )
        case .controls:
            ControlsSettingsPage(controller: controller, settings: settings)
        case .permissions:
            PermissionsSettingsPage(controller: controller, settings: settings)
        case .about:
            AboutSettingsPage(controller: controller, settings: settings, versionLabel: versionLabel)
        }
    }

    private var versionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "Version \(version ?? "Development")"
    }
}

private struct GeneralSettingsPage: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings
    @ObservedObject var loginController: LaunchAtLoginController

    var body: some View {
        VStack(spacing: 18) {
            SettingsCard(title: "HOW IT WORKS") {
                SettingsInfoRow(
                    title: "Training app controls your trainer",
                    detail: "Pair power, cadence, and resistance directly inside the training app",
                    symbol: "figure.indoor.cycle",
                    color: ClickShiftTheme.teal
                )
                CardDivider()
                SettingsInfoRow(
                    title: "ClickShift connects only to the right Click",
                    detail: "It never pairs with, proxies, or changes resistance on your trainer",
                    symbol: "dot.radiowaves.left.and.right",
                    color: ClickShiftTheme.blue
                )
                CardDivider()
                SettingsInfoRow(
                    title: "Click buttons become keyboard shortcuts",
                    detail: "Safety mode sends them only while the selected training app is focused",
                    symbol: "keyboard",
                    color: Color(red: 0.67, green: 0.53, blue: 1.0)
                )
            }

            SettingsCard(title: "APP PROFILE") {
                SettingsToggleRow(
                    title: "Detect the running training app",
                    detail: "Automatically follows MyWhoosh, TrainingPeaks Virtual, or ROUVY",
                    symbol: "sparkle.magnifyingglass",
                    isOn: $settings.automaticallyDetectRideApp
                )

                CardDivider()

                SettingsRow(
                    title: "Target app",
                    detail: settings.automaticallyDetectRideApp ? "Current automatic selection" : "Manual selection for detection and safety",
                    symbol: "square.stack.3d.up"
                ) {
                    Menu {
                        ForEach(AppSettings.Profile.allCases) { profile in
                            Button {
                                settings.selectProfile(profile)
                            } label: {
                                if settings.profile == profile {
                                    Label(profile.title, systemImage: "checkmark")
                                } else {
                                    Text(profile.title)
                                }
                            }
                        }
                    } label: {
                        ModernMenuLabel(text: settings.profile.title, width: 146)
                    }
                    .menuStyle(.borderlessButton)
                }

                if settings.profile == .custom {
                    CardDivider()
                    SettingsRow(
                        title: "Application name",
                        detail: "Must match the name shown in the Dock",
                        symbol: "app"
                    ) {
                        TextField("App name", text: $settings.customAppName)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.09), lineWidth: 0.7)
                            }
                            .frame(width: 150)
                    }
                }
            }

            SettingsCard(title: "SYSTEM") {
                SettingsToggleRow(
                    title: "Launch at login",
                    detail: "Stay ready to detect your training app",
                    symbol: "power",
                    isOn: Binding(
                        get: { loginController.isEnabled },
                        set: { loginController.setEnabled($0) }
                    )
                )

                CardDivider()

                SettingsToggleRow(
                    title: "Only send keys to \(settings.targetName)",
                    detail: "Blocks shifts whenever another app is focused",
                    symbol: "lock.shield",
                    isOn: $settings.onlySendToTarget
                )

                CardDivider()

                SettingsToggleRow(
                    title: "Meaningful notifications",
                    detail: "Connection, disconnection, and permission alerts",
                    symbol: "bell",
                    isOn: Binding(
                        get: { settings.notificationsEnabled },
                        set: { enabled in
                            settings.notificationsEnabled = enabled
                            if enabled { NotificationManager.shared.requestAuthorization() }
                        }
                    )
                )
            }

            if let error = loginController.errorMessage {
                InlineNotice(text: error, color: .red, symbol: "exclamationmark.triangle.fill")
            }

            SettingsCard(title: "CONNECTION") {
                SettingsRow(
                    title: settings.targetName,
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

            HStack {
                Button("Run Setup Assistant") {
                    SetupWindowController.shared.show(
                        controller: controller,
                        settings: settings,
                        loginController: loginController
                    )
                }
                Spacer()
            }

            InlineNotice(
                text: "ClickShift scans only for the right Click while \(settings.targetName) is open. Your trainer remains connected directly to the training app.",
                color: .secondary,
                symbol: "leaf"
            )
        }
    }
}

private struct ControlsSettingsPage: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 18) {
            SettingsCard(title: "BUTTON MAPPING") {
                ConfigurableMappingRow(
                    action: "Shift up",
                    symbol: "arrow.up",
                    button: $settings.upButton,
                    key: $settings.upKey
                )
                CardDivider()
                ConfigurableMappingRow(
                    action: "Shift down",
                    symbol: "arrow.down",
                    button: $settings.downButton,
                    key: $settings.downKey
                )
            }

            InlineNotice(
                text: "Use a letter, number, arrow name, Page Up, or Page Down. MyWhoosh defaults to K for up and I for down.",
                color: .secondary,
                symbol: "keyboard"
            )

            if settings.upButton == settings.downButton {
                InlineNotice(
                    text: "Choose two different Click buttons so one press can’t trigger both directions.",
                    color: .orange,
                    symbol: "exclamationmark.triangle.fill"
                )
            }

            if !KeyboardShifter.isSupported(key: settings.upKey) || !KeyboardShifter.isSupported(key: settings.downKey) {
                InlineNotice(
                    text: "One of the entered keys isn’t supported yet.",
                    color: .orange,
                    symbol: "exclamationmark.triangle.fill"
                )
            }

            SettingsCard(title: "GEAR STEP") {
                SettingsRow(
                    title: "Shifts per press",
                    detail: "Send the configured key more than once",
                    symbol: "arrow.triangle.2.circlepath"
                ) {
                    GearStepPicker(selection: $settings.gearStep)
                }
            }

            InlineNotice(
                text: "If \(settings.targetName) also has a gear-step setting, leave one side at 1 to avoid multiplying the jump.",
                color: .secondary,
                symbol: "info.circle"
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
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 18) {
            SettingsCard(title: "ACCESSIBILITY") {
                SettingsRow(
                    title: "Keyboard control",
                    detail: "Sends your configured shifting shortcuts",
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
                    detail: "Connects only to the right Click; never to your trainer",
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
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings
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
                        Text("Click-to-keyboard shifting for training apps without native Click support.")
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
                Button("Export Diagnostics…") {
                    DiagnosticsExporter.export(controller: controller, settings: settings)
                }
                Spacer()
                Text("Unofficial · Zwift uses the Click natively")
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Capsule()
                    .fill(ClickShiftTheme.blue)
                    .frame(width: 13, height: 4)

                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(Color.white.opacity(0.45))
            }
            .padding(.leading, 3)

            VStack(spacing: 0) {
                content
            }
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.085), lineWidth: 0.8)
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
                .foregroundStyle(ClickShiftTheme.blue)
                .frame(width: 32, height: 32)
                .background(ClickShiftTheme.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.43))
            }

            Spacer(minLength: 12)
            trailing
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let detail: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.43))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let detail: String
    let symbol: String
    @Binding var isOn: Bool
    @State private var isHovered = false

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ClickShiftTheme.blue)
                    .frame(width: 32, height: 32)
                    .background(ClickShiftTheme.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.43))
                }

                Spacer(minLength: 12)

                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isOn ? ClickShiftTheme.blue.opacity(0.82) : Color.white.opacity(0.055))
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(isOn ? ClickShiftTheme.blue : Color.white.opacity(0.16), lineWidth: 1)

                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Color.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 24, height: 24)
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(isHovered ? 0.025 : 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.14), value: isHovered)
        .animation(.easeOut(duration: 0.16), value: isOn)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

private struct ConfigurableMappingRow: View {
    let action: String
    let symbol: String
    @Binding var button: ClickButton
    @Binding var key: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(ClickShiftTheme.teal)
                .frame(width: 32, height: 32)
                .background(ClickShiftTheme.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(action)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            Spacer()

            Menu {
                ForEach(ClickButton.allCases, id: \.self) { candidate in
                    Button {
                        button = candidate
                    } label: {
                        if button == candidate {
                            Label(candidate.displayName, systemImage: "checkmark")
                        } else {
                            Text(candidate.displayName)
                        }
                    }
                }
            } label: {
                ModernMenuLabel(text: button.displayName, width: 78)
            }
            .menuStyle(.borderlessButton)

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.24))

            TextField("Key", text: $key)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.09), lineWidth: 0.7)
                }
                .frame(width: 72)
                .onChange(of: key) { value in
                    let normalized = value.uppercased()
                    if normalized != value { key = normalized }
                }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
    }
}

private struct StatusValue: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .textCase(.uppercase)
            .tracking(0.5)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.11), in: Capsule())
            .overlay {
                Capsule().strokeBorder(color.opacity(0.16), lineWidth: 0.7)
            }
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

private struct CardDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, 56)
    }
}

private struct SettingsBackdrop: View {
    var body: some View {
        Color(red: 0.027, green: 0.034, blue: 0.048)
        .ignoresSafeArea()
    }
}

private enum ClickShiftTheme {
    static let blue = Color(red: 0.35, green: 0.68, blue: 1.0)
    static let teal = Color(red: 0.38, green: 0.86, blue: 0.78)
}

private struct ModernMenuLabel: View {
    let text: String
    let width: CGFloat

    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
            Spacer(minLength: 4)
        }
        .foregroundStyle(Color.white.opacity(0.86))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(width: width)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color.white.opacity(0.09), lineWidth: 0.7)
        }
    }
}

private struct GearStepPicker: View {
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { step in
                Button {
                    selection = step
                } label: {
                    Text("\(step)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(selection == step ? Color.white : Color.white.opacity(0.45))
                        .frame(width: 31, height: 25)
                        .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .background {
                            if selection == step {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(ClickShiftTheme.blue.opacity(0.68))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.7)
        }
    }
}

private struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.65 : 0.86))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Color.white.opacity(configuration.isPressed ? 0.045 : 0.075),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.7)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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
