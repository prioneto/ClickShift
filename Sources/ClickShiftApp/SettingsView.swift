import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var loginController: LaunchAtLoginController

    var body: some View {
        TabView {
            GeneralSettingsView(
                controller: controller,
                loginController: loginController
            )
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            ControlsSettingsView(controller: controller)
                .tabItem {
                    Label("Controls", systemImage: "arrow.up.arrow.down")
                }

            PermissionsSettingsView(controller: controller)
                .tabItem {
                    Label("Permissions", systemImage: "hand.raised")
                }
        }
        .frame(width: 620, height: 500)
        .onAppear {
            controller.refreshPermissions()
            loginController.refresh()
        }
    }
}

private struct GeneralSettingsView: View {
    @ObservedObject var controller: ClickController
    @ObservedObject var loginController: LaunchAtLoginController

    var body: some View {
        Form {
            Section("Automatic behavior") {
                Toggle(
                    "Open ClickShift when you log in",
                    isOn: Binding(
                        get: { loginController.isEnabled },
                        set: { loginController.setEnabled($0) }
                    )
                )

                Text("ClickShift waits quietly for MyWhoosh, connects to the right Click when a ride starts, and disconnects when MyWhoosh closes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let error = loginController.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Connection") {
                LabeledContent("MyWhoosh") {
                    Label(
                        controller.myWhooshRunning ? "Open" : "Closed",
                        systemImage: controller.myWhooshRunning ? "checkmark.circle.fill" : "minus.circle"
                    )
                    .foregroundStyle(controller.myWhooshRunning ? Color.green : Color.secondary)
                }

                LabeledContent("Right Click v2") {
                    Label(
                        controller.state.label,
                        systemImage: controller.state.isConnected ? "checkmark.circle.fill" : "dot.radiowaves.left.and.right"
                    )
                    .foregroundStyle(controller.state.isConnected ? Color.green : Color.secondary)
                }

                HStack {
                    if controller.state == .stopped {
                        Button("Start ClickShift") { controller.start() }
                    } else {
                        Button("Reconnect Now") { controller.reconnectNow() }
                            .disabled(!controller.myWhooshRunning)
                        Button("Stop") { controller.stop() }
                    }
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
        .padding(12)
    }
}

private struct ControlsSettingsView: View {
    @ObservedObject var controller: ClickController

    var body: some View {
        Form {
            Section("Button mapping") {
                MappingRow(button: "+", action: "Shift up", output: "K", symbol: "arrow.up")
                MappingRow(button: "B", action: "Shift down", output: "I", symbol: "arrow.down")

                Text("MyWhoosh must keep its default virtual-shifting shortcuts: K for up and I for down.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Test shifting") {
                HStack {
                    Button {
                        controller.testShiftDown()
                    } label: {
                        Label("Test Shift Down", systemImage: "arrow.down")
                    }

                    Button {
                        controller.testShiftUp()
                    } label: {
                        Label("Test Shift Up", systemImage: "arrow.up")
                    }
                }

                Text(controller.lastAction)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(12)
    }
}

private struct MappingRow: View {
    let button: String
    let action: String
    let output: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Text(button)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .frame(width: 34, height: 34)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            Label(action, systemImage: symbol)
            Spacer()
            Text("Sends \(output)")
                .foregroundStyle(.secondary)
        }
    }
}

private struct PermissionsSettingsView: View {
    @ObservedObject var controller: ClickController

    var body: some View {
        Form {
            Section("Accessibility") {
                LabeledContent("Keyboard control") {
                    Label(
                        controller.accessibilityGranted ? "Allowed" : "Required",
                        systemImage: controller.accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                    )
                    .foregroundStyle(controller.accessibilityGranted ? Color.green : Color.orange)
                }

                Text("Accessibility lets ClickShift send the I and K shortcuts to MyWhoosh. It does not read what you type.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Button(controller.accessibilityGranted ? "Open Accessibility Settings" : "Enable Accessibility") {
                        if controller.accessibilityGranted {
                            openSystemSettings(anchor: "Privacy_Accessibility")
                        } else {
                            controller.requestAccessibility()
                        }
                    }
                    Button("Refresh Status") { controller.refreshPermissions() }
                    Spacer()
                }
            }

            Section("Bluetooth") {
                Text("ClickShift uses Bluetooth only while MyWhoosh is open. macOS asks for access the first time it searches for your right Click v2.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Open Bluetooth Privacy Settings") {
                    openSystemSettings(anchor: "Privacy_Bluetooth")
                }
            }

            Section("About") {
                LabeledContent("ClickShift") {
                    Text(versionLabel)
                        .foregroundStyle(.secondary)
                }
                Text("A free, local-only, open-source utility. No accounts, analytics, ads, or network service.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("View on GitHub", destination: URL(string: "https://github.com/prioneto/ClickShift")!)
            }
        }
        .formStyle(.grouped)
        .padding(12)
    }

    private var versionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "Version \(version ?? "Development")"
    }

    private func openSystemSettings(anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else { return }
        NSWorkspace.shared.open(url)
    }
}
