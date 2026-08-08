import SwiftUI

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 180, 180, 180)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - App Section (for in-app navigation)
public enum AppSection: Equatable { case workspace, settings }

// MARK: - Accent Preset
enum AccentPreset: String, CaseIterable, Identifiable {
    case gitez = "ZGit"
    case ocean = "Ocean"
    case grove = "Grove"
    case ember = "Ember"
    case iris  = "Iris"

    var id: String { rawValue }

    var primary: Color {
        switch self {
        case .gitez: return Color(hex: "#E54B45")
        case .ocean: return Color(hex: "#3B82F6")
        case .grove: return Color(hex: "#22C55E")
        case .ember: return Color(hex: "#F97316")
        case .iris:  return Color(hex: "#A855F7")
        }
    }

    var secondary: Color {
        switch self {
        case .gitez: return Color(hex: "#9B1C1C")
        case .ocean: return Color(hex: "#1D4ED8")
        case .grove: return Color(hex: "#15803D")
        case .ember: return Color(hex: "#C2410C")
        case .iris:  return Color(hex: "#7E22CE")
        }
    }
}

// MARK: - Theme Colors
struct ThemeColors {
    var background:      Color
    var sidebar:         Color
    var surface:         Color
    var surfaceElevated: Color
    var border:          Color
    var divider:         Color
    var textPrimary:     Color
    var textSecondary:   Color
    var textTertiary:    Color
    var accent:          Color
    var accentSecondary: Color
    var accentMuted:     Color
    var codeAdded:       Color
    var codeAddedFg:     Color
    var codeRemoved:     Color
    var codeRemovedFg:   Color
    var terminalBg:      Color

    // swiftlint:disable function_body_length
    static func make(_ theme: AppTheme, _ accent: AccentPreset = .gitez) -> ThemeColors {
        if theme == .light {
            return ThemeColors(
                background:      Color(hex: "#F7F7F9"),
                sidebar:         Color(hex: "#EDEDF0"),
                surface:         Color(hex: "#FFFFFF"),
                surfaceElevated: Color(hex: "#F4F4F6"),
                border:          Color.black.opacity(0.07),
                divider:         Color.black.opacity(0.055),
                textPrimary:     Color(hex: "#111114"),
                textSecondary:   Color(hex: "#6B6B72"),
                textTertiary:    Color(hex: "#A0A0A8"),
                accent:          accent.primary,
                accentSecondary: accent.secondary,
                accentMuted:     accent.primary.opacity(0.1),
                codeAdded:       Color(hex: "#DCFCE7"),
                codeAddedFg:     Color(hex: "#15803D"),
                codeRemoved:     Color(hex: "#FEE2E2"),
                codeRemovedFg:   Color(hex: "#B91C1C"),
                terminalBg:      Color(hex: "#1E1E2E")
            )
        } else {
            // .dark + .system → T3-inspired deep purple-indigo
            return ThemeColors(
                background:      Color(hex: "#171625"),
                sidebar:         Color(hex: "#131221"),
                surface:         Color(hex: "#1E1C2F"),
                surfaceElevated: Color(hex: "#252340"),
                border:          Color.white.opacity(0.08),
                divider:         Color.white.opacity(0.06),
                textPrimary:     Color(hex: "#ECEBFF"),
                textSecondary:   Color(hex: "#6B6884"),
                textTertiary:    Color(hex: "#43405E"),
                accent:          accent.primary,
                accentSecondary: accent.secondary,
                accentMuted:     accent.primary.opacity(0.14),
                codeAdded:       Color(hex: "#0D2818"),
                codeAddedFg:     Color(hex: "#4ADE80"),
                codeRemoved:     Color(hex: "#2A0D0D"),
                codeRemovedFg:   Color(hex: "#F87171"),
                terminalBg:      Color(hex: "#0E0D1A")
            )
        }
    }
}

// MARK: - Environment Key
private struct ThemeKey: EnvironmentKey {
    static let defaultValue = ThemeColors.make(.dark)
}

extension EnvironmentValues {
    var theme: ThemeColors {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
