import AppKit
import SwiftUI

@MainActor
final class SetupWindowController: NSObject {
    static let shared = SetupWindowController()

    private var setupWindow: NSWindow?

    func show(
        controller: ClickController,
        settings: AppSettings,
        loginController: LaunchAtLoginController
    ) {
        let content = SetupAssistantView(
            controller: controller,
            settings: settings,
            loginController: loginController
        ) { [weak self] in
            self?.setupWindow?.close()
        }

        let window: NSWindow
        if let setupWindow {
            setupWindow.contentViewController = NSHostingController(rootView: content)
            window = setupWindow
        } else {
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 550),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Set Up ClickShift"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.isMovableByWindowBackground = true
            window.contentViewController = NSHostingController(rootView: content)
            window.isReleasedWhenClosed = false
            window.center()
            setupWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        DispatchQueue.main.async {
            window.makeFirstResponder(nil)
        }
    }
}
