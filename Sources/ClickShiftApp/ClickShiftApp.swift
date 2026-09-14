import AppKit
import SwiftUI

@main
struct ClickShiftApp: App {
    @StateObject private var controller = ClickController()
    @StateObject private var loginController = LaunchAtLoginController()

    var body: some Scene {
        MenuBarExtra {
            menuContent
        } label: {
            Image(systemName: controller.state.isConnected ? "bicycle.circle.fill" : "bicycle.circle")
        }
        .menuBarExtraStyle(.window)
    }

    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(controller.state.isConnected ? Color.green : Color.orange)
                    .frame(width: 9, height: 9)
                VStack(alignment: .leading, spacing: 2) {
                    Text("ClickShift")
                        .font(.headline)
                    Text(controller.state.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 5) {
                Label(
                    controller.myWhooshRunning ? "MyWhoosh is open" : "MyWhoosh is closed",
                    systemImage: controller.myWhooshRunning ? "play.circle.fill" : "pause.circle"
                )
                Label("+  →  Shift up (K)", systemImage: "plus.circle")
                Label("B  →  Shift down (I)", systemImage: "minus.circle")
                Text(controller.lastAction)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !controller.accessibilityGranted {
                Button("Enable Accessibility…") {
                    controller.requestAccessibility()
                }
                Text("Required so ClickShift can send I/K to MyWhoosh.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Test down") { controller.testShiftDown() }
                Button("Test up") { controller.testShiftUp() }
            }

            Divider()

            if controller.state == .stopped {
                Button("Start") { controller.start() }
            } else {
                Button("Reconnect now") { controller.reconnectNow() }
                Button("Stop") { controller.stop() }
            }

            Toggle(
                "Run at login for MyWhoosh detection",
                isOn: Binding(
                    get: { loginController.isEnabled },
                    set: { loginController.setEnabled($0) }
                )
            )

            if let error = loginController.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            Divider()

            Button("Quit ClickShift") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(14)
        .frame(width: 300)
        .onAppear {
            controller.refreshPermissions()
            loginController.refresh()
        }
    }
}
