import SwiftUI

/// Mellority calm brand: cream, chocolate brown, gold (#F5F5DC / #4B3621 / #D4AF37).
enum BrandTheme {
    static let cream = Color(red: 0.965, green: 0.965, blue: 0.88)
    static let creamMid = Color(red: 0.93, green: 0.91, blue: 0.84)
    static let creamDeep = Color(red: 0.88, green: 0.85, blue: 0.78)
    static let brown = Color(red: 0.294, green: 0.212, blue: 0.129)
    static let brownMuted = Color(red: 0.38, green: 0.30, blue: 0.22)
    static let gold = Color(red: 0.831, green: 0.686, blue: 0.216)
    static let goldSoft = Color(red: 0.88, green: 0.78, blue: 0.55)
    static let goldDeep = Color(red: 0.62, green: 0.48, blue: 0.22)

    static let backgroundGradient = LinearGradient(
        colors: [cream, creamMid, creamDeep.opacity(0.85)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let etherealGradient = LinearGradient(
        colors: [
            Color(red: 0.45, green: 0.55, blue: 0.75).opacity(0.35),
            Color(red: 0.75, green: 0.65, blue: 0.85).opacity(0.25),
            cream.opacity(0.9),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Immersive session: sky, water, forest hints (used with layered mountains + leaves).
    static let sessionNatureSkyGradient = LinearGradient(
        colors: [
            Color(red: 0.68, green: 0.80, blue: 0.93),
            Color(red: 0.80, green: 0.88, blue: 0.90).opacity(0.92),
            Color(red: 0.72, green: 0.83, blue: 0.78).opacity(0.65),
            Color(red: 0.88, green: 0.90, blue: 0.82).opacity(0.85),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Rounded system — simple, modern UI (replaces previous serif titles).
    static func title(_ style: Font.TextStyle = .title) -> Font {
        .system(style, design: .rounded)
    }

    static func buttonLabel(_ style: Font.TextStyle = .headline) -> Font {
        .system(style, design: .rounded, weight: .semibold)
    }
}
