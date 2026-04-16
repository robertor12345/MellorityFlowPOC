import SwiftUI
import Combine

/// In-memory app session — start without signing in.
final class SessionPOCState: ObservableObject {
    @Published var phase: FlowPhase = .home
    @Published var showSignInSheet = false

    /// Optional account fields (in-memory until sync ships).
    @Published var email = ""
    @Published var password = ""
    @Published var isSignedIn = false

    /// Opt-ins from post–sign-in integration slides.
    @Published var wantsHealthSync = false
    @Published var wantsIoT = false
    @Published var wantsPersonalisation = false
    @Published var wantsSnippetsMemory = false
    @Published var wantsReplayCalm = false

    @Published var capturedImage: UIImage?
    @Published var selectedMood: String?

    @Published var mockHeartRateStart: Double = 78
    @Published var mockHeartRateCurrent: Double = 72
    @Published var calmScore: Double = 0.82

    @Published var snippets: [SnippetHighlight] = []

    /// Session toggle: sync calm scenes with home lights (Hue / HomeKit style).
    @Published var sessionHomeLightsSyncEnabled = false

    // MARK: - Replay last session (visuals + audio)

    /// Set when a session ends; cleared when a new session begins or on full reset.
    @Published var replayExperienceAvailable = false
    @Published var replayMoodSnapshot: String?
    @Published var replayCalmPercentSnapshot: Int = 0
    @Published var replayHeartRateSnapshot: Int = 72

    // MARK: - Connected device detail (mock settings)

    enum HealthDataProvider: String, CaseIterable, Identifiable {
        case appleHealth = "Apple Health"
        case whoop = "WHOOP"
        case fitbit = "Fitbit"
        case garmin = "Garmin"
        var id: String { rawValue }
    }

    @Published var healthShareHeartRate = true
    @Published var healthShareRestingHR = true
    @Published var healthShareSleepStages = true
    @Published var healthShareActivity = false
    @Published var healthPreferredProvider: HealthDataProvider = .appleHealth

    @Published var iotPhilipsHueEnabled = false
    @Published var iotHomeKitEnabled = false
    @Published var iotMatterEnabled = false
    @Published var iotFollowSessionBreath = true
    @Published var iotMaxSceneBrightness: Double = 0.88

    @Published var personalisationSessionMemory = true
    @Published var personalisationAdaptationSpeed: Double = 0.5
    @Published var personalisationPreferGentleStarts = true

    @Published var snippetsAutoCapturePeaks = true
    @Published var snippetsKeepDays: SnippetRetention = .thirty
    @Published var snippetsExportMarkdown = false

    enum SnippetRetention: Int, CaseIterable, Identifiable {
        case seven = 7
        case thirty = 30
        case ninety = 90
        var id: Int { rawValue }
        var label: String { "\(rawValue) days" }
    }

    @Published var replayOfferOnInsight = true
    @Published var replayRestoreVolume = true
    @Published var replayShowMetricsOverlay = true

    private var sessionStart: Date?

    struct SnippetHighlight: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let timecode: String
    }

    /// Labels name a range of valence (including difficult states) so choices feel honest; the session still adapts tone and pace.
    let moodOptions = ["Stressed", "Anxious", "Down", "Overwhelmed", "Tired", "Calm"]

    func beginSession() {
        sessionStart = Date()
        mockHeartRateStart = Double.random(in: 72 ... 88)
        mockHeartRateCurrent = mockHeartRateStart
        snippets = []
        sessionHomeLightsSyncEnabled = false
        replayExperienceAvailable = false
        replayMoodSnapshot = nil
    }

    func addSnippet() {
        let peaks = [
            ("A quiet moment", "Sound eased with your breath", "—"),
            ("Soft focus", "Tempo matched your mood", "—"),
        ]
        let pick = peaks.randomElement() ?? peaks[0]
        snippets.append(SnippetHighlight(title: pick.0, subtitle: pick.1, timecode: pick.2))
    }

    func endSession() {
        mockHeartRateCurrent = max(58, mockHeartRateStart - Double.random(in: 4 ... 12))
        calmScore = min(0.98, calmScore + 0.05)
        replayMoodSnapshot = selectedMood
        replayCalmPercentSnapshot = Int(calmScore * 100)
        replayHeartRateSnapshot = Int(mockHeartRateCurrent)
        replayExperienceAvailable = true
    }

    func resetToHome() {
        phase = .home
        capturedImage = nil
        selectedMood = nil
        replayExperienceAvailable = false
        replayMoodSnapshot = nil
    }

    func exitPostSignInSlidesToHome() {
        phase = .home
    }

    /// Clears session state so each cold start matches default values (nothing persisted).
    func resetAllForFreshAppLaunch() {
        phase = .home
        showSignInSheet = false
        email = ""
        password = ""
        isSignedIn = false
        wantsHealthSync = false
        wantsIoT = false
        wantsPersonalisation = false
        wantsSnippetsMemory = false
        wantsReplayCalm = false
        capturedImage = nil
        selectedMood = nil
        mockHeartRateStart = 78
        mockHeartRateCurrent = 72
        calmScore = 0.82
        snippets = []
        sessionHomeLightsSyncEnabled = false
        replayExperienceAvailable = false
        replayMoodSnapshot = nil
        resetConnectedDeviceSettingsToDefaults()
    }

    private func resetConnectedDeviceSettingsToDefaults() {
        healthShareHeartRate = true
        healthShareRestingHR = true
        healthShareSleepStages = true
        healthShareActivity = false
        healthPreferredProvider = .appleHealth
        iotPhilipsHueEnabled = false
        iotHomeKitEnabled = false
        iotMatterEnabled = false
        iotFollowSessionBreath = true
        iotMaxSceneBrightness = 0.88
        personalisationSessionMemory = true
        personalisationAdaptationSpeed = 0.5
        personalisationPreferGentleStarts = true
        snippetsAutoCapturePeaks = true
        snippetsKeepDays = .thirty
        snippetsExportMarkdown = false
        replayOfferOnInsight = true
        replayRestoreVolume = true
        replayShowMetricsOverlay = true
    }
}

enum FlowPhase: Int, CaseIterable, Identifiable {
    case home = 0
    case postSignInFeatureSlides = 1
    case entryMode = 2
    case captureMoment = 3
    case moodSelect = 4
    case processingFast = 5
    case immersive = 6
    case insight = 7
    case unlockFeatures = 8
    case connectedDevices = 9
    case replayCalmSession = 10

    var id: Int { rawValue }
}
