import SwiftUI
import UIKit

/// Picks the first SF Symbol name the current OS actually ships (many instrument glyphs vary by SDK).
enum SFCompat {
    nonisolated static func resolve(_ names: String...) -> String {
        resolve(Array(names))
    }

    nonisolated static func resolve(_ names: [String]) -> String {
        for name in names where UIImage(systemName: name) != nil {
            return name
        }
        return "music.note"
    }
}

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

    /// Instrument-first SF Symbols with fallbacks — some names only exist on newer SF Symbol drops.
    var iconName: String {
        switch self {
        case .jazz:
            return SFCompat.resolve(
                "saxophone.fill", "saxophone", "music.mic", "wind.instrument.fill", "tuningfork", "music.note"
            )
        case .classical:
            return SFCompat.resolve("pianokeys", "music.note.list", "tuningfork", "music.note")
        case .pop:
            return SFCompat.resolve("mic.circle.fill", "mic.fill", "music.mic", "music.note")
        case .rock:
            return SFCompat.resolve("guitars.fill", "guitar.fill", "guitars", "music.quarternote.3")
        case .gospel:
            return SFCompat.resolve("trumpet.fill", "trumpet", "speaker.wave.2.fill", "music.quarternote.3")
        case .country:
            return SFCompat.resolve("banjo.fill", "banjo", "guitars.fill", "guitars", "guitars.case.fill")
        case .soul:
            return SFCompat.resolve("headphones", "headphones.circle", "music.note.list", "music.note")
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
        case .low:
            return SFCompat.resolve("moon.zzz.fill", "moon.zzz", "moon.stars.fill", "moon.fill")
        case .mid:
            return SFCompat.resolve("cloud.sun.fill", "cloud.sun", "sun.haze.fill", "cloud.fill")
        case .high:
            return SFCompat.resolve("sun.horizon.fill", "sun.max.fill", "sun.min.fill")
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
        case .sad:
            return SFCompat.resolve("face.dashed.fill", "face.dashed", "face.frown.fill")
        case .neutral:
            return SFCompat.resolve("face.smiling", "face.smiling.inverse")
        case .happy:
            return SFCompat.resolve("face.smiling.fill", "face.smiling")
        }
    }
}
