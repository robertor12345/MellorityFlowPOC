import SwiftUI

/// In-memory state for the **care-home one-to-one** session POC (corporate sign-in).
final class SessionPOCState: ObservableObject {
    @Published var phase: FlowPhase = .home
    @Published var showSignInSheet = false

    @Published var email = ""
    @Published var password = ""
    @Published var isSignedIn = false
    @Published private(set) var pendingCareRosterAfterSignIn = false

    @Published var capturedImage: UIImage?
    @Published private(set) var selectedMoods: Set<String> = []

    // MARK: - Care staff (sample data)

    @Published var carePatients: [CarePatientProfile] = CareStaffMockData.initialPatients
    @Published var careSessionRecords: [CareSessionRecord] = CareStaffMockData.initialRecords
    @Published var selectedCarePatientId: UUID?
    @Published var activeCarePatientId: UUID?
    @Published var isCareStaffSession: Bool = false

    @Published var carePlannedDurationMinutes: Int = 15
    @Published var carePrepVRImmersiveRoute: Bool = false
    @Published var carePrepRoomDisplayMirroring: Bool = false

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

    func enterOneToOneCalmFlow() {
        guard isSignedIn else {
            pendingCareRosterAfterSignIn = true
            showSignInSheet = true
            return
        }
        pendingCareRosterAfterSignIn = false
        phase = .carePatientList
    }

    func completeOptionalSignInFromSheet() {
        isSignedIn = true
        showSignInSheet = false
        pendingCareRosterAfterSignIn = false
        phase = .carePatientList
    }

    func abandonPendingCareRosterSignInIfNeeded() {
        if !isSignedIn { pendingCareRosterAfterSignIn = false }
    }

    func goBackFromEntryMode() {
        phase = .careSessionPrep
    }

    func resetCarePrepForNewSession() {
        carePlannedDurationMinutes = 15
        carePrepVRImmersiveRoute = false
        carePrepRoomDisplayMirroring = false
    }

    func openCareSessionPrep() {
        guard isSignedIn else {
            phase = .home
            return
        }
        resetCarePrepForNewSession()
        phase = .careSessionPrep
    }

    func continueCareSessionFromPrep() {
        guard let pid = selectedCarePatientId else { return }
        startCareGuidedSession(for: pid)
    }

    func startCareGuidedSession(for patientId: UUID) {
        guard isSignedIn else {
            phase = .home
            return
        }
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

    private func resetCareSessionFlags() {
        isCareStaffSession = false
        activeCarePatientId = nil
    }

    @Published var mockHeartRateStart: Double = 78
    @Published var mockHeartRateCurrent: Double = 72
    @Published var calmScore: Double = 0.82

    @Published var sessionHomeLightsSyncEnabled = false

    @Published var replayExperienceAvailable = false
    @Published var replayMoodSnapshot: String?
    @Published var replayCalmPercentSnapshot: Int = 0
    @Published var replayHeartRateSnapshot: Int = 72

    @Published var iotPhilipsHueEnabled = false
    @Published var iotHomeKitEnabled = false
    @Published var iotMatterEnabled = false
    @Published var iotFollowSessionBreath = true
    @Published var iotMaxSceneBrightness: Double = 0.88

    @Published var immersiveMediaSessionID = UUID()
    @Published private(set) var sessionAnchoredWithPhoto = false
    @Published private(set) var replaySnapshotMediaID: UUID?
    @Published private(set) var replaySessionPhotoAnchored = false

    let moodOptions = ["Stressed", "Anxious", "Down", "Overwhelmed", "Tired", "Calm"]

    func beginSession() {
        immersiveMediaSessionID = UUID()
        sessionAnchoredWithPhoto = capturedImage != nil
        mockHeartRateStart = Double.random(in: 72 ... 88)
        mockHeartRateCurrent = mockHeartRateStart
        sessionHomeLightsSyncEnabled = false
        replayExperienceAvailable = false
        replayMoodSnapshot = nil
        replaySnapshotMediaID = nil
        replaySessionPhotoAnchored = false
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

    func resetAllForFreshAppLaunch() {
        phase = .home
        showSignInSheet = false
        email = ""
        password = ""
        isSignedIn = false
        pendingCareRosterAfterSignIn = false
        capturedImage = nil
        selectedMoods = []
        mockHeartRateStart = 78
        mockHeartRateCurrent = 72
        calmScore = 0.82
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
        resetIoTDefaults()
    }

    private func resetIoTDefaults() {
        iotPhilipsHueEnabled = false
        iotHomeKitEnabled = false
        iotMatterEnabled = false
        iotFollowSessionBreath = true
        iotMaxSceneBrightness = 0.88
    }
}

enum FlowPhase: Int, CaseIterable, Identifiable {
    case home = 0
    case entryMode = 1
    case captureMoment = 2
    case moodSelect = 3
    case processingFast = 4
    case immersive = 5
    case insight = 6
    case carePatientList = 7
    case carePatientDetail = 8
    case careSessionFeedback = 9
    case careSessionPrep = 10

    var id: Int { rawValue }
}
