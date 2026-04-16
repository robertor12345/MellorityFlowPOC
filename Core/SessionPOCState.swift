import SwiftUI
import Combine

/// Simplified POC flow — no login required to start.
final class SessionPOCState: ObservableObject {
    @Published var phase: FlowPhase = .home
    @Published var showSignInSheet = false

    /// Optional account (mock).
    @Published var email = ""
    @Published var password = ""
    @Published var isSignedIn = false

    /// Mock opt-ins chosen on post–sign-in integration slides (POC only).
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

    /// Immersive session: mock “sync with home lights” (Hue / HomeKit style — no real bridge in POC).
    @Published var sessionHomeLightsSyncEnabled = false

    private var sessionStart: Date?

    struct SnippetHighlight: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let timecode: String
    }

    let moodOptions = ["Calm", "Focus", "Sleep", "Lift stress"]

    func beginSession() {
        sessionStart = Date()
        mockHeartRateStart = Double.random(in: 72 ... 88)
        mockHeartRateCurrent = mockHeartRateStart
        snippets = []
        sessionHomeLightsSyncEnabled = false
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
    }

    func resetToHome() {
        phase = .home
        capturedImage = nil
        selectedMood = nil
    }

    func exitPostSignInSlidesToHome() {
        phase = .home
    }

    /// Clears every POC flag/value so each cold start matches a fresh `SessionPOCState()` (no persisted demo state).
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
    }
}

enum FlowPhase: Int, CaseIterable, Identifiable {
    case home
    case postSignInFeatureSlides
    case entryMode
    case captureMoment
    case moodSelect
    case processingFast
    case immersive
    case insight
    case unlockFeatures

    var id: Int { rawValue }
}
