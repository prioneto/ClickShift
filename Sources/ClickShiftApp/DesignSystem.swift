import AppKit
import SwiftUI

enum Brand {
    static let blue = Color(red: 0.2, green: 0.58, blue: 0.82)
    static let navy = Color(red: 0.13, green: 0.18, blue: 0.29)
}

extension Color {
    /// A color that resolves against the current light or dark appearance.
    init(light: NSColor, dark: NSColor) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
}

enum Surface {
    static let groupFill = Color(
        light: NSColor.black.withAlphaComponent(0.028),
        dark: NSColor.white.withAlphaComponent(0.04)
    )
    static let groupBorder = Color(
        light: NSColor.black.withAlphaComponent(0.075),
        dark: NSColor.white.withAlphaComponent(0.075)
    )
    static let separator = Color.primary.opacity(0.08)
}

struct AppIconImage: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let icon = AppAssets.image(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Brand.blue)
            }
        }
        .frame(width: size, height: size)
    }
}

/// System Settings–style rounded tile with a white glyph.
struct SymbolTile: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 20

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
            .fill(color.gradient)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
    }
}

/// Circular state indicator: filled with the tone color when active, neutral when idle.
struct StatusGlyph: View {
    let symbol: String
    let tone: ConnectionStatus.Tone
    var size: CGFloat = 26

    var body: some View {
        Circle()
            .fill(tone == .idle ? AnyShapeStyle(Color.primary.opacity(0.09)) : AnyShapeStyle(tone.color.gradient))
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(tone == .idle ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white))
            }
            .frame(width: size, height: size)
    }
}

struct StatusBadge: View {
    let status: ConnectionStatus

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(status.tone.color)
                .frame(width: 6, height: 6)
            Text(status.badge)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .frame(height: 20)
        .background(Color.primary.opacity(0.06), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

/// Keyboard key the Click button is mapped to.
struct Keycap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .padding(.horizontal, 6)
            .frame(minWidth: 22, minHeight: 20)
            .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.5)
            }
    }
}

/// Round button, matching the physical buttons on the Click.
struct ClickButtonCap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .lineLimit(1)
            .padding(.horizontal, 5)
            .frame(minWidth: 20, minHeight: 20)
            .background(Color.primary.opacity(0.07), in: Capsule())
            .overlay {
                Capsule().strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.5)
            }
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
    }
}

extension View {
    /// Hides the keyboard focus ring on custom-styled controls.
    @ViewBuilder
    func hiddenFocusRing() -> some View {
        if #available(macOS 14.0, *) {
            focusEffectDisabled()
        } else {
            focusable(false)
        }
    }
}

enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
    }

    static var versionLabel: String {
        guard let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            return "Version \(version)"
        }
        return "Version \(version) (\(build))"
    }
}
