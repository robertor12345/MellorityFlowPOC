import SwiftUI

/// Touch-first genres for resident iPad — icons only on screen; labels for VoiceOver.
enum ResidentMusicGenre: String, CaseIterable, Identifiable, Codable, Equatable {
    case jazz
    case classical
    case pop
    case rock
    case gospel
    case country
    case soul

    var id: String { rawValue }

    var accessibilityLabel: String {
        rawValue.capitalized
    }

    var iconName: String {
        switch self {
        case .jazz: return "saxophone.fill"
        case .classical: return "pianokeys"
        case .pop: return "star.fill"
        case .rock: return "guitars.fill"
        case .gospel: return "hands.clap.fill"
        case .country: return "leaf.fill"
        case .soul: return "heart.fill"
        }
    }

    var accent: Color {
        switch self {
        case .jazz: return Color.purple.opacity(0.85)
        case .classical: return Color.blue.opacity(0.8)
        case .pop: return Color.pink.opacity(0.85)
        case .rock: return Color.orange.opacity(0.9)
        case .gospel: return Color.yellow.opacity(0.85)
        case .country: return Color.green.opacity(0.8)
        case .soul: return Color.red.opacity(0.75)
        }
    }
}

enum ResidentTrafficMood: Int, CaseIterable, Identifiable {
    case low = 0
    case mid = 1
    case high = 2
    var id: Int { rawValue }
    var color: Color {
        switch self {
        case .low: return .red.opacity(0.75)
        case .mid: return .yellow.opacity(0.85)
        case .high: return .green.opacity(0.75)
        }
    }
    var iconName: String {
        switch self {
        case .low: return "exclamationmark.circle.fill"
        case .mid: return "minus.circle.fill"
        case .high: return "checkmark.circle.fill"
        }
    }
}

enum ResidentFaceMood: Int, CaseIterable, Identifiable {
    case sad = 0
    case neutral = 1
    case happy = 2
    var id: Int { rawValue }
    var iconName: String {
        switch self {
        case .sad: return "face.dashed.fill"
        case .neutral: return "face.smiling"
        case .happy: return "face.smiling.fill"
        }
    }
}
