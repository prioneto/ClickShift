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
                color: status.tone.nsColor,
                size: NSSize(width: 18, height: 18)
            ) {
                Image(nsImage: icon)
                    .renderingMode(.original)
            } else {
                Image(systemName: controller.state.isConnected ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle")
                    .foregroundStyle(status.tone.color)
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

    private var status: ConnectionStatus {
        ConnectionStatus(controller: controller, settings: settings)
    }
}
