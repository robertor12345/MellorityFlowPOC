import Foundation

/// In-the-moment comfort signal while listening on the resident playlist surface (not discovery calibration).
enum ResidentPlaylistComfortChoice: String, Equatable {
    case feelsGood
    case trySomethingElse
    case implicitNeutral
}

enum PlaylistComfortInvitePhase: Equatable {
    case hidden
    case visible
}

enum PlaylistComfortTiming {
    /// Wait after track/genre start before inviting feedback.
    static let settleSeconds: TimeInterval = 12
    /// Fade invite if untouched.
    static let inviteVisibleSeconds: TimeInterval = 4
    static let maxPromptsPerSession = 3
}

extension ResidentPlaylistComfortChoice {
    var accessibilityLabel: String {
        switch self {
        case .feelsGood: return "Feels good"
        case .trySomethingElse: return "Try something else"
        case .implicitNeutral: return "No response"
        }
    }
}
