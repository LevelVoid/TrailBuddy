import SwiftUI

// MARK: - Bernese Mountain Dog Color Palette
// Tricolor: jet-black body, warm rust-tan legs, white chest
// The entire app lives in this dog's world.

enum Theme {

    // MARK: Backgrounds
    /// Primary dark background — all screens
    static let nearBlack     = Color(red: 0.08, green: 0.07, blue: 0.06)
    /// Slightly lighter surface for cards / elevated elements
    static let darkSurface   = Color(red: 0.14, green: 0.12, blue: 0.10)
    /// Even lighter card surface — used for stat cards to pop
    static let elevatedCard  = Color(red: 0.18, green: 0.16, blue: 0.14)

    // MARK: Text
    /// Primary text — warm off-white
    static let warmWhite     = Color(red: 0.96, green: 0.93, blue: 0.88)
    /// Secondary / caption text
    static let warmGray      = Color(red: 0.58, green: 0.54, blue: 0.48)

    // MARK: Accents
    /// Primary — rust-tan from the dog's markings
    static let rustTan       = Color(red: 0.78, green: 0.48, blue: 0.22)
    /// Secondary highlight — muted gold
    static let mutedGold     = Color(red: 0.82, green: 0.68, blue: 0.38)
    /// Nature/altitude only — deep forest green
    static let forestGreen   = Color(red: 0.28, green: 0.50, blue: 0.30)
    /// EMERGENCY ONLY — "I'm Lost" button. No other element uses red.
    static let bloodRed      = Color(red: 0.72, green: 0.12, blue: 0.10)

    // MARK: Subtle Accents
    /// Warm glow for subtle backgrounds / highlights
    static let warmGlow      = Color(red: 0.78, green: 0.48, blue: 0.22).opacity(0.08)
    /// Card border / separator
    static let subtleBorder  = Color(red: 0.96, green: 0.93, blue: 0.88).opacity(0.06)

    // MARK: Fonts
    static func title(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func heading(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption() -> Font {
        .system(size: 13, weight: .medium, design: .rounded)
    }
    static func mono(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
}
