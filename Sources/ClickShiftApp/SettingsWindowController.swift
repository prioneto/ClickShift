import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var settingsWindow: NSWindow?

    func show(
        controller: ClickController,
        loginController: LaunchAtLoginController
    ) {
        let window = settingsWindow ?? makeWindow(
            controller: controller,
            loginController: loginController
        )

        controller.refreshPermissions()
        loginController.refresh()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func makeWindow(
        controller: ClickController,
        loginController: LaunchAtLoginController
    ) -> NSWindow {
        let content = SettingsView(
            controller: controller,
            loginController: loginController
        )
        let hostingController = NSHostingController(rootView: content)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "ClickShift Settings"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 560, height: 440)
        window.setFrameAutosaveName("ClickShiftSettingsWindow")
        window.center()
        settingsWindow = window
        return window
    }
}
