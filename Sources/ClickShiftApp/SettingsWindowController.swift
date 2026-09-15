import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var settingsWindow: NSWindow?

    func show(
        controller: ClickController,
        settings: AppSettings,
        loginController: LaunchAtLoginController
    ) {
        let window = settingsWindow ?? makeWindow(
            controller: controller,
            settings: settings,
            loginController: loginController
        )

        controller.refreshPermissions()
        loginController.refresh()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        DispatchQueue.main.async {
            window.makeFirstResponder(nil)
        }
    }

    private func makeWindow(
        controller: ClickController,
        settings: AppSettings,
        loginController: LaunchAtLoginController
    ) -> NSWindow {
        let content = SettingsView(
            controller: controller,
            settings: settings,
            loginController: loginController
        )
        let hostingController = NSHostingController(rootView: content)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 840, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "ClickShift Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.isMovableByWindowBackground = true
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 800, height: 550)
        window.setFrameAutosaveName("ClickShiftSettingsWindow")
        window.center()
        settingsWindow = window
        return window
    }
}
