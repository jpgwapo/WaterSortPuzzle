import SwiftUI

/// Semantic color and spacing tokens for the game's calm, jewel-toned visual language.
enum ChromaticTheme {
    static let midnight = Color(red: 0.035, green: 0.047, blue: 0.12)
    static let deepIndigo = Color(red: 0.105, green: 0.075, blue: 0.25)
    static let violet = Color(red: 0.46, green: 0.30, blue: 0.96)
    static let azure = Color(red: 0.16, green: 0.65, blue: 0.98)
    static let aqua = Color(red: 0.19, green: 0.88, blue: 0.79)
    static let coral = Color(red: 1.00, green: 0.40, blue: 0.59)
    static let sunshine = Color(red: 1.00, green: 0.78, blue: 0.31)

    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.72)
    static let tertiaryText = Color.white.opacity(0.5)
    static let glassFill = Color.white.opacity(0.09)
    static let glassHighlight = Color.white.opacity(0.23)
    static let glassBorder = Color.white.opacity(0.17)

    static let backgroundGradient = LinearGradient(
        colors: [
            midnight,
            Color(red: 0.075, green: 0.07, blue: 0.22),
            Color(red: 0.04, green: 0.13, blue: 0.23),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let actionGradient = LinearGradient(
        colors: [violet, azure],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let liquidPalette: [Color] = [
        aqua,
        azure,
        violet,
        coral,
        sunshine,
        Color(red: 0.38, green: 0.92, blue: 0.43),
        Color(red: 1.00, green: 0.55, blue: 0.24),
    ]

    static func accent(forLevel level: Int) -> Color {
        let index = max(0, level - 1) % liquidPalette.count
        return liquidPalette[index]
    }
}

extension Font {
    static let chromaticHero = Font.system(.largeTitle, design: .rounded, weight: .black)
    static let chromaticTitle = Font.system(.title2, design: .rounded, weight: .bold)
    static let chromaticHeadline = Font.system(.headline, design: .rounded, weight: .bold)
    static let chromaticBody = Font.system(.body, design: .rounded, weight: .medium)
    static let chromaticCaption = Font.system(.caption, design: .rounded, weight: .semibold)
}
