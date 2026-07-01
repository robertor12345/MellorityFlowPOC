import Foundation

// Stock portrait assets live in `App/Assets.xcassets` (POC placeholders). Replace with
// your own licensed imagery and consent before shipping.

/// Person-centred profile for one-to-one calm moments — sensory hints, life themes, and adaptive sound shaping preferences.
struct CarePatientProfile: Identifiable, Equatable {
    let id: UUID
    var displayName: String
    var careContextLabel: String
    var likes: [String]
    var dislikes: [String]
    /// Lighting / glare hints for a low-stimulation space (Namaste-style calm room).
    var preferredLight: String
    /// Scent guidance — gentle, optional; many homes avoid strong perfume.
    var scentGuidance: String
    /// Touch consent / comfort (e.g. hand rest OK, prefers not).
    var touchComfortNotes: String
    /// Reminiscence anchors — garden, seaside, faith, baking, etc.
    var comfortThemes: [String]
    /// When true, the mixer favours very soft onsets and avoids abrupt changes.
    var prefersGentleSoundOnsets: Bool
    /// 0 = slower / gentler pacing, 1 = slightly brighter tempo.
    var musicTempoBias: Double
    /// 0 = more nature-forward, 1 = more abstract / minimal.
    var natureVsAbstract: Double
    /// 0 = mostly instrumental, 1 = more voice-forward content.
    var voiceVsInstrumental: Double
    /// Approximate age for era-biased snippet algorithm (peak years ~15–30 from birth year implied).
    var residentAgeYears: Int
    /// Preferred genre for resident iPad playlists.
    var favouriteMusicGenre: ResidentMusicGenre
    /// Asset name in `Assets.xcassets` (stock portrait fallback).
    var stockPortraitAssetName: String
    /// Temporary profile created during new-resident discovery — replaced when supervisor saves details.
    var isProvisional: Bool
    /// Curated playlists keyed by genre — shown when staff opens this profile (e.g. from face-linked photo).
    var genrePlaylistGroups: [CareGenrePlaylistGroup]
    var homeId: UUID = CareTenancyMockData.mapleLodgeId
    var wingId: String = CareTenancyMockData.wingResidential
    var roomLabel: String = ""
    var isActive: Bool = true
}

/// Saved playlist linked to a genre for resident calm sessions (POC stubs).
struct CarePlaylistEntry: Identifiable, Equatable {
    let id: UUID
    var title: String
    var trackCount: Int
    var durationMinutes: Int
    /// Song titles for the in-app playlist player (subset is fine for POC demos).
    var trackTitles: [String]
}

/// Playlists grouped under one genre on a patient’s profile.
struct CareGenrePlaylistGroup: Identifiable, Equatable {
    var id: ResidentMusicGenre { genre }
    var genre: ResidentMusicGenre
    var playlists: [CarePlaylistEntry]
}

struct CareSessionRecord: Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let date: Date
    let moodSummary: String
    let calmPercent: Int
    var staffNote: String?
    /// 0–100: seemed more settled vs distressed after the moment (nil if not captured).
    var settledness: Int?
    /// 0–100: withdrawn vs engaged / connected.
    var engagement: Int?
    /// 0–100: struggled to tolerate vs comfortable throughout.
    var comfortTolerance: Int?
    /// Supervisor 1–10 ratings (nil if skipped).
    var moodRating: Int?
    var alertnessRating: Int?
    var emotionalStateRating: Int?
    var lucidityRating: Int?
    /// Resident calm-surface session length (seconds).
    var sessionDurationSeconds: Int?
    var residentGenrePlayCount: Int?
    var residentTrackChangeCount: Int?
    var residentImmersiveEntryCount: Int?
    var residentGenresPlayedSummary: String?
    /// Session context tags (time of day, prior state, environment).
    var sessionTimeOfDay: String? = nil
    var preSessionState: String? = nil
    var sessionContextSummary: String? = nil
    var residentLedSession: Bool? = nil
    var distressOrPRNNearby: Bool? = nil
    /// Generated at save time for handover / care-plan use.
    var insightNarrative: String? = nil
    var insightSuggestedNextStep: String? = nil
    var insightHandoverText: String? = nil
    var insightFamilyText: String? = nil
    var lightsDimmed: Bool? = nil
}

enum CareStaffMockData {
    static let elena = UUID(uuidString: "aaaaaaaa-bbbb-4ccc-8ddd-111111111101")!
    static let james = UUID(uuidString: "aaaaaaaa-bbbb-4ccc-8ddd-111111111102")!
    static let sam = UUID(uuidString: "aaaaaaaa-bbbb-4ccc-8ddd-111111111103")!

    static let initialPatients: [CarePatientProfile] = [
        CarePatientProfile(
            id: elena,
            displayName: "Elena M.",
            careContextLabel: "Room 12A · Residential",
            likes: ["Soft piano", "Rain at the window", "Short, unhurried blocks"],
            dislikes: ["Sudden tempo shifts", "Bright percussion", "Busy chatter nearby"],
            preferredLight: "Soft, indirect — avoid overhead glare.",
            scentGuidance: "Unscented room or a single mild linen spray if asked.",
            touchComfortNotes: "Comfortable with light hand rest; prefers warning before touch.",
            comfortThemes: ["Garden mornings", "Church bells from childhood", "Baking bread"],
            prefersGentleSoundOnsets: true,
            musicTempoBias: 0.35,
            natureVsAbstract: 0.22,
            voiceVsInstrumental: 0.4,
            residentAgeYears: 82,
            favouriteMusicGenre: .classical,
            stockPortraitAssetName: "StockPortraitElena",
            isProvisional: false,
            genrePlaylistGroups: [
                CareGenrePlaylistGroup(
                    genre: .classical,
                    playlists: [
                        CarePlaylistEntry(
                            id: UUID(uuidString: "cccc1111-1111-4111-8111-111111111101")!,
                            title: "Soft piano · morning",
                            trackCount: 14,
                            durationMinutes: 42,
                            trackTitles: ["Before sunrise", "Kitchen light", "Slow arpeggio", "Grey sky calm", "Tea steam", "Window rain"]
                        ),
                        CarePlaylistEntry(
                            id: UUID(uuidString: "cccc1111-1111-4111-8111-111111111102")!,
                            title: "Strings — unhurried",
                            trackCount: 11,
                            durationMinutes: 38,
                            trackTitles: ["Cello entry", "Quiet bowing", "Second theme", "Soft release", "Held chord out"]
                        ),
                    ]
                ),
                CareGenrePlaylistGroup(
                    genre: .gospel,
                    playlists: [
                        CarePlaylistEntry(
                            id: UUID(uuidString: "cccc1111-1111-4111-8111-111111111103")!,
                            title: "Hymns — gentle choir",
                            trackCount: 9,
                            durationMinutes: 33,
                            trackTitles: ["Gathering hum", "Soft refrain", "Organ pad", "Amen sway", "Room hush"]
                        ),
                    ]
                ),
            ]
        ),
        CarePatientProfile(
            id: james,
            displayName: "James R.",
            careContextLabel: "Day program · Quiet lounge",
            likes: ["Low strings", "Very slow builds", "Predictable loops"],
            dislikes: ["Crowded highs", "Fast rhythm guitar", "Screen glare"],
            preferredLight: "Dimmer side of room; natural daylight diffused.",
            scentGuidance: "No strong scents — can startle.",
            touchComfortNotes: "Prefers weighted blanket offered verbally first; minimal touch.",
            comfortThemes: ["Fishing trips", "Northern hills", "Jazz from the 50s"],
            prefersGentleSoundOnsets: true,
            musicTempoBias: 0.2,
            natureVsAbstract: 0.55,
            voiceVsInstrumental: 0.15,
            residentAgeYears: 76,
            favouriteMusicGenre: .jazz,
            stockPortraitAssetName: "StockPortraitJames",
            isProvisional: false,
            genrePlaylistGroups: [
                CareGenrePlaylistGroup(
                    genre: .jazz,
                    playlists: [
                        CarePlaylistEntry(
                            id: UUID(uuidString: "cccc2222-2222-4222-8222-222222222201")!,
                            title: "50s lounge — brushed drums",
                            trackCount: 12,
                            durationMinutes: 48,
                            trackTitles: ["Hi-hat swell", "Walking line", "Muted brass", "Night ride", "Last call sway", "Dim lights"]
                        ),
                        CarePlaylistEntry(
                            id: UUID(uuidString: "cccc2222-2222-4222-8222-222222222202")!,
                            title: "Late-night sax — very slow",
                            trackCount: 8,
                            durationMinutes: 36,
                            trackTitles: ["Single reed breath", "Blue room", "Curtain fringe", "Soft cadence"]
                        ),
                    ]
                ),
                CareGenrePlaylistGroup(
                    genre: .soul,
                    playlists: [
                        CarePlaylistEntry(
                            id: UUID(uuidString: "cccc2222-2222-4222-8222-222222222203")!,
                            title: "Warm vocals, soft band",
                            trackCount: 10,
                            durationMinutes: 40,
                            trackTitles: ["Intro Rhodes", "Verse hush", "Chorus lift", "Outro lamp", "Silk tail"]
                        ),
                    ]
                ),
            ]
        ),
        CarePatientProfile(
            id: sam,
            displayName: "Sam K.",
            careContextLabel: "1:1 · Outreach",
            likes: ["Gentle spoken reassurance", "Ocean loops", "Birdsong far in the distance"],
            dislikes: ["Repetitive chime alarms", "Footsteps in echoey hall"],
            preferredLight: "Warm lamp; blinds half-closed in afternoon.",
            scentGuidance: "Optional: citrus peel on a plate — familiar, not sprayed.",
            touchComfortNotes: "Enjoys steady shoulder presence; say their name softly first.",
            comfortThemes: ["Seaside holidays", "Children’s laughter", "Sunday roast"],
            prefersGentleSoundOnsets: true,
            musicTempoBias: 0.5,
            natureVsAbstract: 0.3,
            voiceVsInstrumental: 0.65,
            residentAgeYears: 71,
            favouriteMusicGenre: .classical,
            stockPortraitAssetName: "StockPortraitSam",
            isProvisional: false,
            genrePlaylistGroups: [
                CareGenrePlaylistGroup(
                    genre: .classical,
                    playlists: [
                        CarePlaylistEntry(
                            id: UUID(uuidString: "cccc3333-3333-4333-8333-333333333301")!,
                            title: "Ocean + piano blend",
                            trackCount: 15,
                            durationMinutes: 45,
                            trackTitles: ["Tide in", "Sparse keys", "Gull distance", "Sand light", "Wave fold", "Dock rope"]
                        ),
                    ]
                ),
                CareGenrePlaylistGroup(
                    genre: .pop,
                    playlists: [
                        CarePlaylistEntry(
                            id: UUID(uuidString: "cccc3333-3333-4333-8333-333333333302")!,
                            title: "Light nostalgia — soft hooks",
                            trackCount: 13,
                            durationMinutes: 44,
                            trackTitles: ["Old radio fuzz", "Tape warmth", "Hum-along", "Summer brake", "Street lights"]
                        ),
                    ]
                ),
            ]
        ),
    ]

    static let initialRecords: [CareSessionRecord] = [
        CareSessionRecord(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4ccc-8ddd-222222222201")!,
            patientId: elena,
            date: Date().addingTimeInterval(-86_400 * 2),
            moodSummary: "Anxious, Tired",
            calmPercent: 71,
            staffNote: "Eyes closed most of time; shorter block next visit.",
            settledness: 72,
            engagement: 58,
            comfortTolerance: 80,
            moodRating: 6,
            alertnessRating: 5,
            emotionalStateRating: 7,
            lucidityRating: 6,
            sessionDurationSeconds: 720,
            residentGenrePlayCount: 4,
            residentTrackChangeCount: 2,
            residentImmersiveEntryCount: 1,
            residentGenresPlayedSummary: "Classical ×2, Gospel ×2",
            sessionTimeOfDay: "Afternoon",
            preSessionState: "Withdrawn / low engagement",
            sessionContextSummary: "Afternoon · Before: withdrawn / low engagement · Lights dimmed · Resident-led",
            residentLedSession: true,
            distressOrPRNNearby: false,
            insightNarrative: "Elena M. spent 12m 0s · Classical ×2, Gospel ×2 · 1 therapeutic visual access during a reminiscence music session.",
            insightSuggestedNextStep: "Repeat a similar session starting with classical in the afternoon with soft lighting and offer the calm-room visuals again.",
            insightHandoverText: nil,
            insightFamilyText: nil,
            lightsDimmed: true
        ),
        CareSessionRecord(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4ccc-8ddd-222222222202")!,
            patientId: elena,
            date: Date().addingTimeInterval(-86_400 * 9),
            moodSummary: "Calm",
            calmPercent: 84,
            staffNote: nil,
            settledness: nil,
            engagement: nil,
            comfortTolerance: nil
        ),
        CareSessionRecord(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4ccc-8ddd-222222222203")!,
            patientId: james,
            date: Date().addingTimeInterval(-86_400 * 1),
            moodSummary: "Overwhelmed",
            calmPercent: 62,
            staffNote: "Dim lights helped; even slower intro next time.",
            settledness: 55,
            engagement: 44,
            comfortTolerance: 62,
            moodRating: 4,
            alertnessRating: 5,
            emotionalStateRating: 4,
            lucidityRating: 7
        ),
        CareSessionRecord(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4ccc-8ddd-222222222204")!,
            patientId: sam,
            date: Date().addingTimeInterval(-86_400 * 4),
            moodSummary: "Down, Stressed",
            calmPercent: 68,
            staffNote: "Voice + ocean landed well; stayed for full length.",
            settledness: 68,
            engagement: 74,
            comfortTolerance: 85,
            moodRating: 7,
            alertnessRating: 6,
            emotionalStateRating: 8,
            lucidityRating: 7
        ),
    ]
}
