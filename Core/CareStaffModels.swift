import Foundation

/// Person-centred profile for one-to-one calm moments — sensory hints, life themes, and mock sound shaping.
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
    /// When true, mock mixer favours very soft onsets and avoids abrupt changes.
    var prefersGentleSoundOnsets: Bool
    /// 0 = slower / gentler pacing, 1 = slightly brighter tempo.
    var musicTempoBias: Double
    /// 0 = more nature-forward, 1 = more abstract / minimal.
    var natureVsAbstract: Double
    /// 0 = mostly instrumental, 1 = more voice-forward content.
    var voiceVsInstrumental: Double
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
            voiceVsInstrumental: 0.4
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
            voiceVsInstrumental: 0.15
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
            voiceVsInstrumental: 0.65
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
            comfortTolerance: 80
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
            comfortTolerance: 62
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
            comfortTolerance: 85
        ),
    ]
}
