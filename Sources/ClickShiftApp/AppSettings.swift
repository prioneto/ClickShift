import AppKit
import ClickShiftCore
import Foundation

final class AppSettings: ObservableObject {
    enum Profile: String, CaseIterable, Identifiable {
        case myWhoosh
        case indieVelo
        case rouvy
        case custom

        var id: Self { self }

        var title: String {
            switch self {
            case .myWhoosh: return "MyWhoosh"
            case .indieVelo: return "TrainingPeaks Virtual"
            case .rouvy: return "ROUVY"
            case .custom: return "Custom app"
            }
        }

        fileprivate var bundleIdentifiers: Set<String> {
            switch self {
            case .myWhoosh: return ["com.whoosh.whooshgame"]
            case .indieVelo: return []
            case .rouvy: return []
            case .custom: return []
            }
        }

        fileprivate var processNames: [String] {
            switch self {
            case .myWhoosh: return ["MyWhoosh"]
            case .indieVelo: return ["TrainingPeaks Virtual", "IndieVelo", "indieVelo"]
            case .rouvy: return ["ROUVY", "Rouvy"]
            case .custom: return []
            }
        }
    }

    @Published var onlySendToTarget: Bool { didSet { save() } }
    @Published var upButton: ClickButton { didSet { save() } }
    @Published var downButton: ClickButton { didSet { save() } }
    @Published var upKey: String { didSet { save() } }
    @Published var downKey: String { didSet { save() } }
    @Published var gearStep: Int { didSet { save() } }
    @Published var profile: Profile { didSet { save() } }
    @Published var automaticallyDetectRideApp: Bool { didSet { save() } }
    @Published var customAppName: String { didSet { save() } }
    @Published var notificationsEnabled: Bool { didSet { save() } }
    @Published var didCompleteSetup: Bool { didSet { save() } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        onlySendToTarget = defaults.object(forKey: "onlySendToTarget") as? Bool ?? true
        upButton = ClickButton(rawValue: defaults.string(forKey: "upButton") ?? "plus") ?? .plus
        downButton = ClickButton(rawValue: defaults.string(forKey: "downButton") ?? "b") ?? .b
        upKey = defaults.string(forKey: "upKey") ?? "K"
        downKey = defaults.string(forKey: "downKey") ?? "I"
        gearStep = max(1, min(3, defaults.integer(forKey: "gearStep") == 0 ? 1 : defaults.integer(forKey: "gearStep")))
        profile = Profile(rawValue: defaults.string(forKey: "profile") ?? "myWhoosh") ?? .myWhoosh
        automaticallyDetectRideApp = defaults.object(forKey: "automaticallyDetectRideApp") as? Bool ?? true
        customAppName = defaults.string(forKey: "customAppName") ?? ""
        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        didCompleteSetup = defaults.bool(forKey: "didCompleteSetup")
    }

    var targetName: String {
        profile == .custom && !customAppName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? customAppName.trimmingCharacters(in: .whitespacesAndNewlines)
            : profile.title
    }

    func selectProfile(_ newProfile: Profile) {
        automaticallyDetectRideApp = false
        profile = newProfile
        if newProfile == .myWhoosh {
            upKey = "K"
            downKey = "I"
        }
    }

    func updateProfileFromRunningApps() {
        guard automaticallyDetectRideApp, let detectedProfile = detectedRunningProfile(), detectedProfile != profile else {
            return
        }
        profile = detectedProfile
    }

    private func detectedRunningProfile() -> Profile? {
        let applications = NSWorkspace.shared.runningApplications

        if let frontmost = NSWorkspace.shared.frontmostApplication,
           let profile = Self.detectableProfiles.first(where: { $0.matches(frontmost) }) {
            return profile
        }

        return Self.detectableProfiles.first { profile in
            applications.contains(where: profile.matches)
        }
    }

    func matchesTarget(_ app: NSRunningApplication?) -> Bool {
        guard let app else { return false }
        if let bundleIdentifier = app.bundleIdentifier, profile.bundleIdentifiers.contains(bundleIdentifier) {
            return true
        }
        guard let name = app.localizedName else { return false }
        let candidates = profile == .custom ? [customAppName] : profile.processNames
        return candidates.contains { candidate in
            !candidate.isEmpty && name.localizedCaseInsensitiveContains(candidate)
        }
    }

    private func save() {
        defaults.set(onlySendToTarget, forKey: "onlySendToTarget")
        defaults.set(upButton.rawValue, forKey: "upButton")
        defaults.set(downButton.rawValue, forKey: "downButton")
        defaults.set(upKey, forKey: "upKey")
        defaults.set(downKey, forKey: "downKey")
        defaults.set(gearStep, forKey: "gearStep")
        defaults.set(profile.rawValue, forKey: "profile")
        defaults.set(automaticallyDetectRideApp, forKey: "automaticallyDetectRideApp")
        defaults.set(customAppName, forKey: "customAppName")
        defaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        defaults.set(didCompleteSetup, forKey: "didCompleteSetup")
    }

    private static let detectableProfiles: [Profile] = [.myWhoosh, .indieVelo, .rouvy]
}

private extension AppSettings.Profile {
    func matches(_ app: NSRunningApplication) -> Bool {
        if let bundleIdentifier = app.bundleIdentifier, bundleIdentifiers.contains(bundleIdentifier) {
            return true
        }
        guard let name = app.localizedName else { return false }
        return processNames.contains { candidate in
            name.localizedCaseInsensitiveContains(candidate)
        }
    }
}

extension ClickButton {
    var displayName: String {
        switch self {
        case .left: return "Left"
        case .up: return "Up"
        case .right: return "Right"
        case .down: return "Down"
        case .a: return "A"
        case .b: return "B"
        case .y: return "Y"
        case .z: return "Z"
        case .minus: return "−"
        case .plus: return "+"
        }
    }
}
