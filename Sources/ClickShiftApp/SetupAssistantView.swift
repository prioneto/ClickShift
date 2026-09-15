import AppKit
import SwiftUI

struct SetupAssistantView: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var settings: AppSettings
    @ObservedObject var loginController: LaunchAtLoginController
    let onFinish: () -> Void

    @State private var step = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(width: index == step ? 34 : 18, height: 5)
                }
            }
            .padding(.top, 24)

            Group {
                switch step {
                case 0: welcomeStep
                case 1: permissionStep
                case 2: controllerStep
                default: completedStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 54)

            Divider()
            HStack {
                if step > 0 && step < 3 {
                    Button("Back") { step -= 1 }
                }
                Spacer()
                if step < 3 {
                    Button(step == 2 ? "Continue" : "Next") {
                        step += 1
                        if step == 2 { controller.startSetupScan() }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Done") {
                        settings.didCompleteSetup = true
                        controller.finishSetup()
                        onFinish()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(18)
        }
        .onAppear { controller.refreshPermissions() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            controller.refreshPermissions()
        }
        .frame(width: 660, height: 520)
    }

    private var welcomeStep: some View {
        VStack(spacing: 22) {
            SettingsWizardIcon(symbol: "arrow.up.arrow.down.circle.fill", color: .accentColor)
            VStack(spacing: 8) {
                Text("Welcome to ClickShift")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Choose the riding app ClickShift should watch and protect.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Picker("Riding app", selection: Binding(
                get: { settings.profile },
                set: { settings.selectProfile($0) }
            )) {
                ForEach(AppSettings.Profile.allCases) { profile in
                    Text(profile.title).tag(profile)
                }
            }
            .frame(width: 260)

            if settings.profile == .custom {
                TextField("Application name", text: $settings.customAppName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)
            }

            Label(
                controller.myWhooshRunning ? "\(settings.targetName) detected" : "\(settings.targetName) is not open yet",
                systemImage: controller.myWhooshRunning ? "checkmark.circle.fill" : "clock"
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(controller.myWhooshRunning ? .green : .secondary)
        }
    }

    private var permissionStep: some View {
        VStack(spacing: 22) {
            SettingsWizardIcon(symbol: "hand.raised.fill", color: .orange)
            VStack(spacing: 8) {
                Text("Allow the essentials")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Bluetooth finds the Click. Accessibility sends your configured shift keys.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 0) {
                SetupPermissionRow(
                    title: "Bluetooth",
                    detail: "Starts when the controller scan begins",
                    symbol: "wave.3.right",
                    allowed: controller.bluetoothAuthorizationGranted
                ) {
                    controller.startSetupScan()
                }
                Divider().padding(.leading, 52)
                SetupPermissionRow(
                    title: "Accessibility",
                    detail: "Required for keyboard shifting",
                    symbol: "keyboard",
                    allowed: controller.accessibilityGranted
                ) {
                    controller.requestAccessibility()
                }
            }
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var controllerStep: some View {
        VStack(spacing: 22) {
            SettingsWizardIcon(
                symbol: controller.state.isConnected ? "checkmark.circle.fill" : "dot.radiowaves.left.and.right",
                color: controller.state.isConnected ? .green : .orange
            )
            VStack(spacing: 8) {
                Text(controller.state.isConnected ? "Right Click connected" : "Wake your right Click")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(controller.state.isConnected ? "The controller is ready." : "Press + or B, then keep the controller near your Mac.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 9) {
                if !controller.state.isConnected { ProgressView().controlSize(.small) }
                Text(controller.state.label)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.quaternary, in: Capsule())

            Button("Search Again") { controller.reconnectNow() }
        }
        .onAppear { controller.startSetupScan() }
    }

    private var completedStep: some View {
        VStack(spacing: 22) {
            SettingsWizardIcon(symbol: "checkmark.circle.fill", color: .green)
            VStack(spacing: 8) {
                Text("ClickShift is ready")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("It will wait quietly, connect automatically, and send keys only when \(settings.targetName) is focused.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 430)
            }

            Toggle("Open ClickShift when I log in", isOn: Binding(
                get: { loginController.isEnabled },
                set: { loginController.setEnabled($0) }
            ))
        }
    }
}

private struct SettingsWizardIcon: View {
    let symbol: String
    let color: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 34, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 72, height: 72)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct SetupPermissionRow: View {
    let title: String
    let detail: String
    let symbol: String
    let allowed: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 28)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if allowed {
                Label("Allowed", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            } else {
                Button("Allow", action: action)
            }
        }
        .padding(14)
    }
}
