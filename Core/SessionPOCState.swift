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
    /// Quick Start mood tags; user may select several (order follows `moodOptions`).
    @Published private(set) var selectedMoods: Set<String> = []

    // MARK: - Care staff (mock POC)

    @Published var carePatients: [CarePatientProfile] = CareStaffMockData.initialPatients
    @Published var careSessionRecords: [CareSessionRecord] = CareStaffMockData.initialRecords
    @Published var selectedCarePatientId: UUID?
    /// Set when a guided session is started for a patient; used for feedback + banners.
    @Published var activeCarePatientId: UUID?
    @Published var isCareStaffSession: Bool = false

    /// Planned calm length (guide only). Paired with `careSessionPrep` IoT / immersive step.
    @Published var carePlannedDurationMinutes: Int = 15
    /// POC: intend VR / pass-through headset path when integrations exist.
    @Published var carePrepVRImmersiveRoute: Bool = false
    /// POC: mirror session to room display (panel, TV, bedside screen).
    @Published var carePrepRoomDisplayMirroring: Bool = false

    /// Selected labels in canonical list order (for display, replay, share).
    var selectedMoodsOrdered: [String] {
        moodOptions.filter { selectedMoods.contains($0) }
    }

    func toggleMoodSelection(_ mood: String) {
        var next = selectedMoods
        if next.contains(mood) {
            next.remove(mood)
        } else {
            next.insert(mood)
        }
        selectedMoods = next
    }

    func carePatient(id: UUID?) -> CarePatientProfile? {
        guard let id else { return nil }
        return carePatients.first { $0.id == id }
    }

    func recordsForPatient(_ patientId: UUID) -> [CareSessionRecord] {
        careSessionRecords.filter { $0.patientId == patientId }.sorted { $0.date > $1.date }
    }

    func enterPersonalSessionFlow() {
        isCareStaffSession = false
        activeCarePatientId = nil
        selectedCarePatientId = nil
        phase = .entryMode
    }

    func goBackFromEntryMode() {
        if isCareStaffSession {
            phase = .careSessionPrep
        } else {
            phase = .home
        }
    }

    func resetCarePrepForNewSession() {
        carePlannedDurationMinutes = 15
        carePrepVRImmersiveRoute = false
        carePrepRoomDisplayMirroring = false
    }

    func openCareSessionPrep() {
        resetCarePrepForNewSession()
        phase = .careSessionPrep
    }

    func continueCareSessionFromPrep() {
        guard let pid = selectedCarePatientId else { return }
        startCareGuidedSession(for: pid)
    }

    func startCareGuidedSession(for patientId: UUID) {
        selectedCarePatientId = patientId
        activeCarePatientId = patientId
        isCareStaffSession = true
        phase = .entryMode
    }

    private func appendCareSessionRecord(
        patientId: UUID,
        staffNote: String?,
        settledness: Int? = nil,
        engagement: Int? = nil,
        comfortTolerance: Int? = nil
    ) {
        let rec = CareSessionRecord(
            id: UUID(),
            patientId: patientId,
            date: Date(),
            moodSummary: replayMoodSnapshot ?? "—",
            calmPercent: Int(calmScore * 100),
            staffNote: staffNote,
            settledness: settledness,
            engagement: engagement,
            comfortTolerance: comfortTolerance
        )
        careSessionRecords.insert(rec, at: 0)
    }

    func saveCareFeedback(
        tempoBias: Double,
        natureVsAbstract: Double,
        voiceVsInstrumental: Double,
        settledness: Int,
        engagement: Int,
        comfortTolerance: Int,
        staffNote: String
    ) {
        guard let pid = activeCarePatientId ?? selectedCarePatientId,
              let idx = carePatients.firstIndex(where: { $0.id == pid }) else { return }
        var patients = carePatients
        patients[idx].musicTempoBias = tempoBias
        patients[idx].natureVsAbstract = natureVsAbstract
        patients[idx].voiceVsInstrumental = voiceVsInstrumental
        carePatients = patients
        let note = staffNote.trimmingCharacters(in: .whitespacesAndNewlines)
        appendCareSessionRecord(
            patientId: pid,
            staffNote: note.isEmpty ? nil : note,
            settledness: settledness,
            engagement: engagement,
            comfortTolerance: comfortTolerance
        )
        isCareStaffSession = false
        activeCarePatientId = nil
        selectedCarePatientId = pid
        phase = .carePatientDetail
    }

    func skipCareFeedback() {
        let pid = activeCarePatientId ?? selectedCarePatientId
        if let pid {
            appendCareSessionRecord(patientId: pid, staffNote: nil)
        }
        isCareStaffSession = false
        activeCarePatientId = nil
        if let pid { selectedCarePatientId = pid }
        phase = .carePatientDetail
    }

    func leaveInsightToUnlockFeatures() {
        if isCareStaffSession, let pid = activeCarePatientId ?? selectedCarePatientId {
            appendCareSessionRecord(patientId: pid, staffNote: nil)
        }
        isCareStaffSession = false
        activeCarePatientId = nil
        phase = .unlockFeatures
    }

    private func resetCareSessionFlags() {
        isCareStaffSession = false
        activeCarePatientId = nil
    }

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

    /// New ID each `beginSession()` so nature video + players are not reused across sessions.
    @Published var immersiveMediaSessionID = UUID()
    /// `true` when the user reached the session with a captured/library photo (not Quick Start only).
    @Published private(set) var sessionAnchoredWithPhoto = false
    /// Snapshot of `immersiveMediaSessionID` when the session ended — used to rebuild the same clip order for **Replay**.
    @Published private(set) var replaySnapshotMediaID: UUID?
    /// Whether the ended session used the **photo-anchor** visuals + audio path (vs Quick Start).
    @Published private(set) var replaySessionPhotoAnchored = false

    struct SnippetHighlight: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let timecode: String
    }

    /// Labels name a range of valence (including difficult states) so choices feel honest; the session still adapts tone and pace.
    let moodOptions = ["Stressed", "Anxious", "Down", "Overwhelmed", "Tired", "Calm"]

    func beginSession() {
        immersiveMediaSessionID = UUID()
        sessionAnchoredWithPhoto = capturedImage != nil
        sessionStart = Date()
        mockHeartRateStart = Double.random(in: 72 ... 88)
        mockHeartRateCurrent = mockHeartRateStart
        snippets = []
        sessionHomeLightsSyncEnabled = false
        replayExperienceAvailable = false
        replayMoodSnapshot = nil
        replaySnapshotMediaID = nil
        replaySessionPhotoAnchored = false
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
        replayMoodSnapshot = selectedMoodsOrdered.isEmpty
            ? nil
            : selectedMoodsOrdered.joined(separator: ", ")
        replayCalmPercentSnapshot = Int(calmScore * 100)
        replayHeartRateSnapshot = Int(mockHeartRateCurrent)
        replaySnapshotMediaID = immersiveMediaSessionID
        replaySessionPhotoAnchored = sessionAnchoredWithPhoto
        replayExperienceAvailable = true
    }

    func resetToHome() {
        phase = .home
        capturedImage = nil
        selectedMoods = []
        replayExperienceAvailable = false
        replayMoodSnapshot = nil
        replaySnapshotMediaID = nil
        replaySessionPhotoAnchored = false
        resetCareSessionFlags()
        selectedCarePatientId = nil
        resetCarePrepForNewSession()
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
        selectedMoods = []
        mockHeartRateStart = 78
        mockHeartRateCurrent = 72
        calmScore = 0.82
        snippets = []
        sessionHomeLightsSyncEnabled = false
        replayExperienceAvailable = false
        replayMoodSnapshot = nil
        replaySnapshotMediaID = nil
        replaySessionPhotoAnchored = false
        immersiveMediaSessionID = UUID()
        sessionAnchoredWithPhoto = false
        carePatients = CareStaffMockData.initialPatients
        careSessionRecords = CareStaffMockData.initialRecords
        selectedCarePatientId = nil
        resetCareSessionFlags()
        resetCarePrepForNewSession()
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
    case carePatientList = 11
    case carePatientDetail = 12
    case careSessionFeedback = 13
    case careSessionPrep = 14

    var id: Int { rawValue }
}
