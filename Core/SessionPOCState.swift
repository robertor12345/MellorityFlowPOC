import SwiftUI
import Combine

/// Shared mock state for the POC flow (no real backend).
final class SessionPOCState: ObservableObject {
    @Published var phase: FlowPhase = .welcome
    @Published var email = ""
    @Published var password = ""

    @Published var healthGranted = false
    @Published var cameraGranted = false
    @Published var audioGranted = false
    @Published var iotGranted = false

    @Published var moodGoals: Set<String> = []
    @Published var genres: Set<String> = []
    @Published var tempo: String = "Slow"
    @Published var connectFitness = false
    @Published var connectMindfulness = false
    @Published var connectSmartHome = false

    @Published var capturedImage: UIImage?
    @Published var mockDominantPalette: String = "Warm amber / soft sage"
    @Published var mockHeartRateStart: Double = 78
    @Published var mockHeartRateCurrent: Double = 72
    @Published var calmScore: Double = 0.82

    @Published var snippets: [SnippetHighlight] = []

    @Published var hueScene: String = "Warm dim (relax)"
    @Published var feedbackHelpful: Bool?

    private var sessionStart: Date?

    struct SnippetHighlight: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let timecode: String
    }

    func beginSession() {
        sessionStart = Date()
        mockHeartRateStart = Double.random(in: 72 ... 88)
        mockHeartRateCurrent = mockHeartRateStart
        snippets = []
    }

    func addSnippet() {
        let peaks = [
            ("Deep Calm Achieved", "Breathing aligned with soundscape", "04:12"),
            ("Clarity lift", "Tempo shifted to match your focus", "08:40"),
            ("Soft landing", "Warm tones as HR eased", "—"),
        ]
        let pick = peaks.randomElement() ?? peaks[0]
        snippets.append(SnippetHighlight(title: pick.0, subtitle: pick.1, timecode: pick.2))
    }

    func endSession() {
        mockHeartRateCurrent = max(58, mockHeartRateStart - Double.random(in: 4 ... 12))
        calmScore = min(0.98, calmScore + 0.05)
    }

    func resetToCapture() {
        phase = .captureHome
        capturedImage = nil
    }
}

enum FlowPhase: Int, CaseIterable, Identifiable {
    case welcome
    case authChoice
    case signUp
    case login
    case permissions
    case personalization
    case captureHome
    case capturePhoto
    case processing
    case immersive
    case snippets
    case iotSync
    case summary
    case learning

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .authChoice: return "Account"
        case .signUp: return "Sign up"
        case .login: return "Log in"
        case .permissions: return "Permissions"
        case .personalization: return "Your preferences"
        case .captureHome: return "Start session"
        case .capturePhoto: return "Capture moment"
        case .processing: return "Creating your space"
        case .immersive: return "Session"
        case .snippets: return "Highlights"
        case .iotSync: return "Ambient space"
        case .summary: return "Summary"
        case .learning: return "Your journey"
        }
    }
}
