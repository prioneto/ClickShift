import AppKit
import SwiftUI

/// Single description of ClickShift's state, shared by the menu-bar icon, the panel, and Settings.
struct ConnectionStatus {
    enum Tone {
        case ready
        case working
        case idle
        case problem

        var color: Color {
            switch self {
            case .ready: return .green
            case .working: return .orange
            case .idle: return .secondary
            case .problem: return .red
            }
        }

        var nsColor: NSColor {
            switch self {
            case .ready: return .systemGreen
            case .working: return .systemOrange
            case .idle: return .secondaryLabelColor
            case .problem: return .systemRed
            }
        }
    }

    let tone: Tone
    /// Short label for badges, e.g. "Connected".
    let badge: String
    let title: String
    let detail: String
    let symbol: String

    /// Pass `includesPermissions: false` to describe only the controller connection.
    init(controller: ClickController, settings: AppSettings, includesPermissions: Bool = true) {
        let app = settings.targetName

        if includesPermissions && !controller.accessibilityGranted && controller.myWhooshRunning {
            self.init(.problem, "Action needed", "Accessibility needed", "Allow access so ClickShift can send shift keys", "exclamationmark.triangle.fill")
            return
        }

        switch controller.state {
        case .connected:
            self.init(.ready, "Connected", "Connected", "Ready to shift in \(app)", "checkmark")
        case .waitingForMyWhoosh:
            self.init(.idle, "Waiting", "Waiting for \(app)", "Connects automatically when \(app) opens", "moon.zzz.fill")
        case .stopped:
            self.init(.idle, "Paused", "Paused", "Start ClickShift when you’re ready to ride", "pause.fill")
        case .scanning:
            self.init(.working, "Searching", "Searching…", "Press a button on the right Click to wake it", "dot.radiowaves.left.and.right")
        case .foundLeft:
            self.init(.working, "Searching", "Only the left Click found", "Wake the right Click — ClickShift uses only that one", "dot.radiowaves.left.and.right")
        case .waitingForWake:
            self.init(.working, "Searching", "Waiting for the Click", "Press a button on the right Click to wake it", "dot.radiowaves.left.and.right")
        case .connecting:
            self.init(.working, "Connecting", "Connecting…", "Setting up the right Click", "dot.radiowaves.left.and.right")
        case .reconnecting:
            self.init(.working, "Reconnecting", "Reconnecting…", "Wake the right Click if it went to sleep", "arrow.triangle.2.circlepath")
        case .bluetoothOff:
            self.init(.problem, "Action needed", "Bluetooth unavailable", "Turn on Bluetooth and allow ClickShift to use it", "exclamationmark.triangle.fill")
        case .failed(let message):
            self.init(.problem, "Action needed", "Connection problem", message, "exclamationmark.triangle.fill")
        }
    }

    private init(_ tone: Tone, _ badge: String, _ title: String, _ detail: String, _ symbol: String) {
        self.tone = tone
        self.badge = badge
        self.title = title
        self.detail = detail
        self.symbol = symbol
    }
}
