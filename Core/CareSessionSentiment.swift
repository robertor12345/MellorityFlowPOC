import Foundation

/// Supervisor 1–10 ratings captured after a calm session (existing residents).
struct SessionSentimentDraft: Equatable {
    var mood: Int?
    var alertness: Int?
    var emotionalState: Int?
    var lucidity: Int?
    var note: String = ""
}

enum CareSessionSentimentStep: Int, CaseIterable, Identifiable {
    case mood = 0
    case alertness = 1
    case emotionalState = 2
    case lucidity = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .mood: return "Mood"
        case .alertness: return "Alertness"
        case .emotionalState: return "Emotional state"
        case .lucidity: return "Lucidity"
        }
    }

    var prompt: String {
        switch self {
        case .mood: return "How did their mood seem right now?"
        case .alertness: return "How alert did they appear?"
        case .emotionalState: return "How would you describe their emotional state?"
        case .lucidity: return "How clear or present did they seem?"
        }
    }

    var lowCaption: String {
        switch self {
        case .mood: return "1 · Very low / unsettled"
        case .alertness: return "1 · Very drowsy"
        case .emotionalState: return "1 · Distressed / flat"
        case .lucidity: return "1 · Confused / unclear"
        }
    }

    var highCaption: String {
        switch self {
        case .mood: return "10 · Bright / settled"
        case .alertness: return "10 · Very alert"
        case .emotionalState: return "10 · Calm / positive"
        case .lucidity: return "10 · Clear / present"
        }
    }
}

struct CareSessionSentimentSummary: Equatable {
    let sessionCount: Int
    let averageMood: Double?
    let averageAlertness: Double?
    let averageEmotionalState: Double?
    let averageLucidity: Double?

    var hasData: Bool {
        sessionCount > 0 && (averageMood != nil || averageAlertness != nil || averageEmotionalState != nil || averageLucidity != nil)
    }

    func formattedAveragesLine() -> String? {
        guard hasData else { return nil }
        var parts: [String] = []
        if let v = averageMood { parts.append(String(format: "Mood %.1f", v)) }
        if let v = averageAlertness { parts.append(String(format: "Alert %.1f", v)) }
        if let v = averageEmotionalState { parts.append(String(format: "Emotion %.1f", v)) }
        if let v = averageLucidity { parts.append(String(format: "Lucidity %.1f", v)) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

enum CareSessionSentimentAnalytics {
    static func summary(for records: [CareSessionRecord]) -> CareSessionSentimentSummary {
        let rated = records.filter {
            $0.moodRating != nil || $0.alertnessRating != nil || $0.emotionalStateRating != nil || $0.lucidityRating != nil
        }
        return CareSessionSentimentSummary(
            sessionCount: rated.count,
            averageMood: average(rated.compactMap(\.moodRating)),
            averageAlertness: average(rated.compactMap(\.alertnessRating)),
            averageEmotionalState: average(rated.compactMap(\.emotionalStateRating)),
            averageLucidity: average(rated.compactMap(\.lucidityRating))
        )
    }

    static func homeOverview(for patients: [CarePatientProfile], records: [CareSessionRecord]) -> CareSessionSentimentSummary {
        let ids = Set(patients.map(\.id))
        let relevant = records.filter { ids.contains($0.patientId) }
        return summary(for: relevant)
    }

    private static func average(_ values: [Int]) -> Double? {
        guard !values.isEmpty else { return nil }
        return Double(values.reduce(0, +)) / Double(values.count)
    }
}
