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

    /// Instrument-first SF Symbols for the resident sandbox (staff roster echoes the same names).
    var iconName: String {
        switch self {
        case .jazz: return "saxophone.fill"
        case .classical: return "pianokeys"
        case .pop: return "mic.circle.fill"
        case .rock: return "guitars.fill"
        case .gospel: return "trumpet.fill"
        case .country: return "banjo.fill"
        case .soul: return "headphones"
        }
    }

    /// Session & roster tints — Mellority cream / gold / dusk tones (not traffic-light primaries).
    var accent: Color {
        switch self {
        case .jazz: return BrandTheme.goldSoft.opacity(0.85)
        case .classical: return Color(red: 0.52, green: 0.58, blue: 0.70).opacity(0.75)
        case .pop: return Color(red: 0.68, green: 0.62, blue: 0.78).opacity(0.7)
        case .rock: return Color(red: 0.50, green: 0.44, blue: 0.40).opacity(0.75)
        case .gospel: return Color(red: 0.78, green: 0.72, blue: 0.52).opacity(0.8)
        case .country: return Color(red: 0.48, green: 0.56, blue: 0.48).opacity(0.72)
        case .soul: return Color(red: 0.58, green: 0.52, blue: 0.62).opacity(0.72)
        }
    }
}

enum ResidentTrafficMood: Int, CaseIterable, Identifiable {
    case low = 0
    case mid = 1
    case high = 2
    var id: Int { rawValue }
    /// Muted “traffic” semantics for **profile / intake** only — not used on the resident music surface.
    var color: Color {
        switch self {
        case .low: return Color(red: 0.58, green: 0.42, blue: 0.45).opacity(0.78)
        case .mid: return Color(red: 0.70, green: 0.55, blue: 0.38).opacity(0.82)
        case .high: return Color(red: 0.44, green: 0.54, blue: 0.48).opacity(0.78)
        }
    }
    var iconName: String {
        switch self {
        case .low: return "moon.zzz"
        case .mid: return "cloud.sun"
        case .high: return "sun.horizon.fill"
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
