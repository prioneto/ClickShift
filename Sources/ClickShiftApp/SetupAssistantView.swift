import AppKit
import SwiftUI

struct SetupAssistantView: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings
    @ObservedObject var loginController: LaunchAtLoginController
    let onFinish: () -> Void

    @State private var step = 0

    var body: some View {
        ZStack {
            SetupBackdrop()

            VStack(spacing: 0) {
                setupHeader

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: permissionStep
                    case 2: controllerStep
                    default: completedStep
                    }
                }
                .id(step)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 38)

                setupFooter
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { controller.refreshPermissions() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            controller.refreshPermissions()
        }
        .frame(width: 720, height: 550)
    }

    private var setupHeader: some View {
        HStack(spacing: 12) {
            SetupAppIcon(size: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text("ClickShift")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("QUICK SETUP")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(Color.white.opacity(0.36))
            }

            Spacer()

            HStack(spacing: 7) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? setupAccent : Color.white.opacity(0.1))
                        .frame(width: index == step ? 30 : 16, height: 5)
                }
            }

            Text("\(step + 1) / 4")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.38))
                .frame(width: 34, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.top, 38)
        .padding(.bottom, 18)
    }

    private var setupFooter: some View {
        HStack(spacing: 10) {
            if step > 0 && step < 3 {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { step -= 1 }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(SetupSecondaryButtonStyle())
            }

            Spacer()

            if step < 3 {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        step += 1
                        if step == 2 { controller.startSetupScan() }
                    }
                } label: {
                    HStack(spacing: 7) {
                        Text(step == 2 ? "Continue" : "Next")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(SetupPrimaryButtonStyle(color: setupAccent))
            } else {
                Button {
                    settings.didCompleteSetup = true
                    controller.finishSetup()
                    onFinish()
                } label: {
                    HStack(spacing: 7) {
                        Text("Start using ClickShift")
                        Image(systemName: "checkmark")
                    }
                }
                .buttonStyle(SetupPrimaryButtonStyle(color: setupAccent))
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    private var welcomeStep: some View {
        SetupStage(
            eyebrow: "WELCOME",
            title: "Your app keeps control",
            detail: "Connect your trainer directly to your training app as usual. ClickShift connects only to the right Click and turns its buttons into keyboard shortcuts.",
            symbol: "arrow.up.arrow.down.circle.fill",
            color: SetupTheme.blue
        ) {
            SetupPanel(title: "HOW CLICKSHIFT WORKS") {
                SetupHowItWorksRow(
                    symbol: "figure.indoor.cycle",
                    title: "Training app controls the trainer",
                    detail: "Power and resistance stay connected there.",
                    color: SetupTheme.teal
                )
                SetupDivider()
                SetupHowItWorksRow(
                    symbol: "dot.radiowaves.left.and.right",
                    title: "ClickShift connects only to the Click",
                    detail: "It never pairs with or controls your trainer.",
                    color: SetupTheme.blue
                )
                SetupDivider()
                SetupHowItWorksRow(
                    symbol: "keyboard",
                    title: "Buttons become shortcuts",
                    detail: "They are sent only to the focused training app.",
                    color: SetupTheme.purple
                )

                SetupStatusLine(
                    text: controller.myWhooshRunning ? "Found \(settings.targetName)" : "Waiting for a supported ride app",
                    symbol: controller.myWhooshRunning ? "checkmark.circle.fill" : "sparkle.magnifyingglass",
                    color: controller.myWhooshRunning ? .green : SetupTheme.blue
                )

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
                    HStack(spacing: 10) {
                        Image(systemName: "figure.indoor.cycle")
                            .foregroundStyle(SetupTheme.blue)
                        Text("Choose manually: \(settings.profile.title)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                    .foregroundStyle(Color.white.opacity(0.88))
                    .padding(.horizontal, 13)
                    .frame(height: 42)
                    .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.09), lineWidth: 0.7)
                    }
                }
                .menuStyle(.borderlessButton)

                if settings.profile == .custom {
                    TextField("Application name", text: $settings.customAppName)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 13)
                        .frame(height: 42)
                        .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.09), lineWidth: 0.7)
                        }
                }

            }
        }
    }

    private var permissionStep: some View {
        SetupStage(
            eyebrow: "PERMISSIONS",
            title: "Two small permissions",
            detail: "Bluetooth finds your Click. Accessibility sends only the shifting shortcuts you configure.",
            symbol: "hand.raised.fill",
            color: SetupTheme.purple
        ) {
            SetupPanel(title: "ACCESS") {
                SetupPermissionRow(
                    title: "Bluetooth",
                    detail: "Find the right Click v2 — not your trainer",
                    symbol: "wave.3.right",
                    allowed: controller.bluetoothAuthorizationGranted,
                    color: SetupTheme.blue
                ) {
                    controller.startSetupScan()
                }

                SetupDivider()

                SetupPermissionRow(
                    title: "Accessibility",
                    detail: "Send your shift keys",
                    symbol: "keyboard",
                    allowed: controller.accessibilityGranted,
                    color: SetupTheme.purple
                ) {
                    controller.requestAccessibility()
                }

                SetupStatusLine(
                    text: "ClickShift never reads your typing",
                    symbol: "lock.shield.fill",
                    color: Color.white.opacity(0.42)
                )
            }
        }
    }

    private var controllerStep: some View {
        let connected = controller.state.isConnected
        return SetupStage(
            eyebrow: "CONTROLLER",
            title: connected ? "Your Click is ready" : "Wake the right Click",
            detail: connected
                ? "The Click is connected. Your trainer remains connected directly to the training app."
                : "Press + or B once while ClickShift searches. Leave your trainer connected directly to the training app.",
            symbol: connected ? "checkmark.circle.fill" : "dot.radiowaves.left.and.right",
            color: connected ? .green : SetupTheme.orange
        ) {
            SetupPanel(title: "RIGHT CLICK V2") {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke((connected ? Color.green : SetupTheme.orange).opacity(0.12), lineWidth: 1)
                            .frame(width: 72, height: 72)
                        Circle()
                            .fill((connected ? Color.green : SetupTheme.orange).opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: connected ? "checkmark" : "antenna.radiowaves.left.and.right")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(connected ? .green : SetupTheme.orange)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(connected ? "CONNECTED" : "SEARCHING")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(connected ? .green : SetupTheme.orange)
                        Text(controller.state.label)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.84))
                            .lineLimit(2)
                        if !connected {
                            ProgressView()
                                .controlSize(.small)
                                .tint(SetupTheme.orange)
                        }
                    }
                    Spacer()
                }

                Button("Search again") { controller.reconnectNow() }
                    .buttonStyle(SetupSecondaryButtonStyle())
                    .disabled(connected)
            }
        }
        .onAppear { controller.startSetupScan() }
    }

    private var completedStep: some View {
        SetupStage(
            eyebrow: "READY",
            title: "You’re all set",
            detail: "ClickShift will detect your training app, connect only to the Click, and protect every shortcut. Your trainer stays with the training app.",
            symbol: "checkmark.circle.fill",
            color: .green
        ) {
            SetupPanel(title: "YOUR SETUP") {
                SetupSummaryRow(symbol: "app.fill", text: settings.targetName, color: SetupTheme.blue)
                SetupDivider()
                SetupSummaryRow(symbol: "figure.indoor.cycle", text: "Trainer stays connected to the training app", color: SetupTheme.teal)
                SetupDivider()
                SetupSummaryRow(symbol: "lock.shield.fill", text: "App-only safety is on", color: SetupTheme.teal)
                SetupDivider()
                SetupSummaryRow(symbol: "arrow.up.arrow.down", text: "+ / B shifting", color: SetupTheme.purple)

                Toggle("Open ClickShift when I log in", isOn: Binding(
                    get: { loginController.isEnabled },
                    set: { loginController.setEnabled($0) }
                ))
                .toggleStyle(.switch)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .padding(.top, 6)
            }
        }
    }

    private var setupAccent: Color {
        switch step {
        case 0: return SetupTheme.blue
        case 1: return SetupTheme.purple
        case 2: return controller.state.isConnected ? .green : SetupTheme.orange
        default: return .green
        }
    }
}

private struct SetupStage<Content: View>: View {
    let eyebrow: String
    let title: String
    let detail: String
    let symbol: String
    let color: Color
    let content: Content

    init(
        eyebrow: String,
        title: String,
        detail: String,
        symbol: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.color = color
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: symbol)
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 64, height: 64)
                    .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .strokeBorder(color.opacity(0.2), lineWidth: 0.8)
                    }

                Text(eyebrow)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(color)
                    .padding(.top, 22)

                Text(title)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .padding(.top, 7)

                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.48))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 9)

                Spacer()
            }
            .frame(width: 250, alignment: .leading)

            content
                .frame(maxWidth: .infinity)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: 350)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.085), lineWidth: 0.8)
        }
    }
}

private struct SetupPanel<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Color.white.opacity(0.35))
            content
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(Color.white.opacity(0.065), lineWidth: 0.7)
        }
    }
}

private struct SetupHowItWorksRow: View {
    let symbol: String
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 29, height: 29)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            Spacer(minLength: 0)
        }
    }
}

private struct SetupPermissionRow: View {
    let title: String
    let detail: String
    let symbol: String
    let allowed: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            Spacer()

            if allowed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Allow", action: action)
                    .buttonStyle(SetupSecondaryButtonStyle())
            }
        }
    }
}

private struct SetupSummaryRow: View {
    let symbol: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.green)
        }
    }
}

private struct SetupStatusLine: View {
    let text: String
    let symbol: String
    let color: Color

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .padding(.top, 2)
    }
}

private struct SetupDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 1)
    }
}

private struct SetupBackdrop: View {
    var body: some View {
        Color(red: 0.027, green: 0.034, blue: 0.048)
        .ignoresSafeArea()
    }
}

private struct SetupAppIcon: View {
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
                    .foregroundStyle(SetupTheme.blue)
            }
        }
        .frame(width: size, height: size)
    }
}

private enum SetupTheme {
    static let blue = Color(red: 0.35, green: 0.68, blue: 1.0)
    static let teal = Color(red: 0.38, green: 0.86, blue: 0.78)
    static let purple = Color(red: 0.67, green: 0.53, blue: 1.0)
    static let orange = Color(red: 1.0, green: 0.62, blue: 0.34)
}

private struct SetupPrimaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.72 : 0.96))
            .padding(.horizontal, 15)
            .frame(height: 36)
            .background(color.opacity(configuration.isPressed ? 0.58 : 0.78), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.7)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SetupSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.55 : 0.76))
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Color.white.opacity(configuration.isPressed ? 0.04 : 0.065), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.7)
            }
    }
}
