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
        if #available(macOS 14.0, *) {
            hostingController.sceneBridgingOptions = []
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 740, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // An empty unified toolbar gives the taller title bar, so the traffic
        // lights line up with the page title drawn by SettingsView.
        window.toolbar = NSToolbar(identifier: "ClickShiftSettingsToolbar")
        window.toolbarStyle = .unified
        window.titlebarSeparatorStyle = .none
        window.title = "ClickShift Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.contentViewController = hostingController
        window.setContentSize(NSSize(width: 740, height: 540))
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 680, height: 460)
        window.setFrameAutosaveName("ClickShiftSettings")
        window.center()
        settingsWindow = window
        return window
    }
}
