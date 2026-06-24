import UIKit

/// Light haptics + chimes on meaningful moments only — never every tap.
@MainActor
enum CalmExperienceFeedback {
    static func lightTap() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        impact(.soft, intensity: 0.42)
        DiscoveryEtherealTapChime.playLight()
    }

    static func signInSuccess() {
        impact(.soft, intensity: 0.58)
        DiscoveryEtherealTapChime.playSuccess()
    }

    static func playlistStart() {
        impact(.soft, intensity: 0.48)
        DiscoveryEtherealTapChime.playLight()
    }

    static func discoveryPick() {
        impact(.soft, intensity: 0.44)
        DiscoveryEtherealTapChime.playLight()
    }

    static func sessionSettle() {
        impact(.soft, intensity: 0.36)
        DiscoveryEtherealTapChime.playSuccess()
    }

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }
}
