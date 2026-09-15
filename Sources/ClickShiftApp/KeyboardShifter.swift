import AppKit
import ApplicationServices

final class KeyboardShifter {
    enum Direction {
        case up
        case down
    }

    var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    func requestAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    @discardableResult
    func shift(_ direction: Direction) -> Bool {
        shift(key: direction == .up ? "K" : "I", repeatCount: 1)
    }

    @discardableResult
    func shift(key: String, repeatCount: Int) -> Bool {
        guard isAccessibilityGranted else {
            requestAccessibility()
            return false
        }

        guard let keyCode = Self.keyCode(for: key) else { return false }
        let source = CGEventSource(stateID: .hidSystemState)
        for _ in 0..<max(1, min(3, repeatCount)) {
            guard
                let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
                let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
            else {
                return false
            }
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }
        return true
    }

    static func isSupported(key: String) -> Bool {
        keyCode(for: key) != nil
    }

    private static func keyCode(for key: String) -> CGKeyCode? {
        let normalized = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return keyCodes[normalized]
    }

    private static let keyCodes: [String: CGKeyCode] = [
        "A": 0, "S": 1, "D": 2, "F": 3, "H": 4, "G": 5, "Z": 6, "X": 7,
        "C": 8, "V": 9, "B": 11, "Q": 12, "W": 13, "E": 14, "R": 15,
        "Y": 16, "T": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
        "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29,
        "]": 30, "O": 31, "U": 32, "[": 33, "I": 34, "P": 35, "RETURN": 36,
        "L": 37, "J": 38, "'": 39, "K": 40, ";": 41, "\\": 42, ",": 43,
        "/": 44, "N": 45, "M": 46, ".": 47, "SPACE": 49, "LEFT": 123,
        "RIGHT": 124, "DOWN": 125, "UP": 126, "PAGE UP": 116, "PAGE DOWN": 121,
    ]
}
