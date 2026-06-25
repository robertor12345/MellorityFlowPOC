import Foundation

struct GroupSessionTrack: Identifiable, Equatable {
    let id: UUID
    let title: String
    let genre: ResidentMusicGenre
    let sourceResidentName: String
    let score: Double
}

struct GroupSessionRecord: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let durationSeconds: Int
    let tracksPlayed: Int
    var moraleRating: Int?
    var alertnessRating: Int?
    var lucidityRating: Int?
    var engagementRating: Int?
    var staffNote: String?
    /// Track titles heard during the session (POC snapshot).
    var playlistSnapshot: [String]
}

struct GroupSessionFeedbackDraft: Equatable {
    var morale: Int?
    var alertness: Int?
    var lucidity: Int?
    var engagement: Int?
    var note: String = ""
}

enum GroupSessionFeedbackStep: Int, CaseIterable, Identifiable {
    case morale = 0
    case alertness = 1
    case lucidity = 2
    case engagement = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .morale: return "Group morale"
        case .alertness: return "Alertness"
        case .lucidity: return "Lucidity"
        case .engagement: return "Engagement"
        }
    }

    var prompt: String {
        switch self {
        case .morale: return "How would you rate the overall mood in the room?"
        case .alertness: return "How alert did the group seem?"
        case .lucidity: return "How clear and present was the group?"
        case .engagement: return "How engaged were residents with the music?"
        }
    }

    var lowCaption: String {
        switch self {
        case .morale: return "1 · Low / flat"
        case .alertness: return "1 · Very drowsy"
        case .lucidity: return "1 · Confused / distant"
        case .engagement: return "1 · Withdrawn"
        }
    }

    var highCaption: String {
        switch self {
        case .morale: return "10 · Uplifted / together"
        case .alertness: return "10 · Very alert"
        case .lucidity: return "10 · Clear / present"
        case .engagement: return "10 · Fully engaged"
        }
    }
}

/// Builds a cross-resident group playlist from favourites, genre libraries, and session telemetry.
enum GroupSessionPlaylistCompiler {
    static func compile(
        patients: [CarePatientProfile],
        sessionRecords: [CareSessionRecord],
        maxTracks: Int = 14
    ) -> [GroupSessionTrack] {
        let roster = patients.filter { !$0.isProvisional }
        guard !roster.isEmpty else { return fallbackTracks() }

        var genreScores: [ResidentMusicGenre: Double] = [:]

        for patient in roster {
            genreScores[patient.favouriteMusicGenre, default: 0] += 3
            for group in patient.genrePlaylistGroups {
                genreScores[group.genre, default: 0] += 1.5
            }
        }

        for rec in sessionRecords {
            let moodBoost = Double(rec.moodRating ?? 5) / 10.0
            let engagementBoost = Double(rec.engagement ?? rec.comfortTolerance ?? 50) / 100.0
            let weight = (moodBoost + engagementBoost) * 1.5

            if let summary = rec.residentGenresPlayedSummary {
                for genre in ResidentMusicGenre.allCases where summary.localizedCaseInsensitiveContains(genre.accessibilityLabel) {
                    genreScores[genre, default: 0] += weight * 2
                }
            }

            if let plays = rec.residentGenrePlayCount, plays > 0 {
                if let patient = roster.first(where: { $0.id == rec.patientId }) {
                    genreScores[patient.favouriteMusicGenre, default: 0] += Double(plays) * 0.4
                }
            }
        }

        let rankedGenres = genreScores.sorted { $0.value > $1.value }.map(\.key)
        let topGenres = Set(rankedGenres.prefix(4))

        var candidates: [GroupSessionTrack] = []
        for patient in roster {
            for group in patient.genrePlaylistGroups where topGenres.contains(group.genre) {
                let genreWeight = genreScores[group.genre] ?? 1
                for playlist in group.playlists {
                    for title in playlist.trackTitles {
                        candidates.append(
                            GroupSessionTrack(
                                id: UUID(),
                                title: title,
                                genre: group.genre,
                                sourceResidentName: patient.displayName,
                                score: genreWeight
                            )
                        )
                    }
                }
            }
        }

        var bestByTitle: [String: GroupSessionTrack] = [:]
        for track in candidates {
            if let existing = bestByTitle[track.title], existing.score >= track.score { continue }
            bestByTitle[track.title] = track
        }

        let ordered = bestByTitle.values.sorted { $0.score > $1.score }
        if ordered.isEmpty { return fallbackTracks(from: roster) }
        return Array(ordered.prefix(maxTracks))
    }

    private static func fallbackTracks(from roster: [CarePatientProfile] = []) -> [GroupSessionTrack] {
        if let patient = roster.first,
           let group = patient.genrePlaylistGroups.first,
           let playlist = group.playlists.first {
            return playlist.trackTitles.prefix(8).map { title in
                GroupSessionTrack(
                    id: UUID(),
                    title: title,
                    genre: group.genre,
                    sourceResidentName: patient.displayName,
                    score: 1
                )
            }
        }
        return [
            GroupSessionTrack(id: UUID(), title: "Soft piano · morning", genre: .classical, sourceResidentName: "Roster blend", score: 1),
            GroupSessionTrack(id: UUID(), title: "50s lounge — brushed drums", genre: .jazz, sourceResidentName: "Roster blend", score: 1),
            GroupSessionTrack(id: UUID(), title: "Gathering hum", genre: .gospel, sourceResidentName: "Roster blend", score: 1),
        ]
    }
}
