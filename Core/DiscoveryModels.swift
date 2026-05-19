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
    /// Number of sequential 30s listens — **must match** ``snippetAudioStreamURLs``.
    static var snippetCount: Int { snippetAudioStreamURLs.count }
    static let snippetDurationSeconds: TimeInterval = 30

    /// One **distinct streamed clip** per discovery snippet (indexed `0 ..< snippetCount`).
    ///
    /// **Retro / ~1950s-style instrumentals** via [Kevin MacLeod — incompetech.com](https://incompetech.com). Licensed **Creative Commons BY** (typically 4.0) — attribution required for public builds; credit *Kevin MacLeod (incompetech.com)* in app credits / readme.
    static let snippetAudioStreamURLs: [URL] = [
        URL(string: "https://incompetech.com/music/royalty-free/mp3-royaltyfree/Sock%20Hop.mp3")!, // diner / sock-hop rock
        URL(string: "https://incompetech.com/music/royalty-free/mp3-royaltyfree/Malt%20Shop%20Bop.mp3")!, // malt-shop bop
        URL(string: "https://incompetech.com/music/royalty-free/mp3-royaltyfree/Vivacity.mp3")!, // brassy upbeat (late‑50s / early‑60s feel)
        URL(string: "https://incompetech.com/music/royalty-free/mp3-royaltyfree/Jazz%20Brunch.mp3")!, // combo jazz groove
        URL(string: "https://incompetech.com/music/royalty-free/mp3-royaltyfree/Cool%20Blast.mp3")!, // cooler dance jazz
        URL(string: "https://incompetech.com/music/royalty-free/mp3-royaltyfree/Americana.mp3")!, // country-western nostalgic
    ]

    static func snippetAudioStreamURL(snippetIndex: Int) -> URL {
        let urls = snippetAudioStreamURLs
        precondition(!urls.isEmpty, "DiscoveryFlowPOC.snippetAudioStreamURLs must not be empty")
        let bounded = snippetIndex % urls.count
        return urls[bounded]
    }
}
