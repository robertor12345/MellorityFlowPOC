import Foundation

/// Traffic-light calibrated sentiment **only** for Discovery listening snippets (explicit red / amber / green).
enum DiscoveryTrafficSentiment: Int, CaseIterable, Identifiable {
    /// Red — unpleasant / draining for them.
    case unpleasant = 0
    /// Amber — mixed / unsure.
    case neutral = 1
    /// Green — pleasant / settling for them.
    case pleasant = 2

    var id: Int { rawValue }

    var accessibilitySummary: String {
        switch self {
        case .unpleasant: return "Unpleasant"
        case .neutral: return "Neutral"
        case .pleasant: return "Pleasant"
        }
    }
}

struct DiscoverySnippetResult: Identifiable, Equatable {
    var id: Int { snippetIndex }
    let snippetIndex: Int
    let sentiment: DiscoveryTrafficSentiment
}

enum DiscoveryFlowPOC {
    /// Number of sequential 30s listens in this calibration pass.
    static let snippetCount = 6
    static let snippetDurationSeconds: TimeInterval = 30
}
