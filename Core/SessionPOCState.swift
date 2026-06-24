import SwiftUI

/// In-memory state for the **care-home one-to-one** session POC (corporate sign-in).
final class SessionPOCState: ObservableObject {
    @Published var phase: FlowPhase = .home

    @Published var email = ""
    @Published var password = ""
    @Published var isSignedIn = false
    @Published private(set) var pendingCareRosterAfterSignIn = false

    @Published var capturedImage: UIImage?
    @Published private(set) var selectedMoods: Set<String> = []

    // MARK: - Resident iPad (low-text)

    @Published var isResidentSession = false
    @Published var residentSessionGenre: ResidentMusicGenre?
    @Published var residentTraffic: ResidentTrafficMood?
    @Published var residentFace: ResidentFaceMood?
    @Published var residentVoiceLine: String = ""
    /// Short “living playlist” segment index (POC: ~10s × 10 loops).
    @Published var residentLivingLoopIndex: Int = 0
    @Published var residentLivingTickInSegment: Int = 0

    // MARK: - Care staff (sample data)

    @Published var carePatients: [CarePatientProfile] = CareStaffMockData.initialPatients
    @Published var careSessionRecords: [CareSessionRecord] = CareStaffMockData.initialRecords
    @Published var selectedCarePatientId: UUID?
    @Published var activeCarePatientId: UUID?
    @Published var isCareStaffSession: Bool = false

    @Published var carePlannedDurationMinutes: Int = 15
    @Published var carePrepVRImmersiveRoute: Bool = false
    @Published var carePrepRoomDisplayMirroring: Bool = false

    /// Where `leaveResidentProfileToStaff()` returns (face grid vs staff detail).
    @Published var residentStaffReturnPhase: FlowPhase = .carePatientList

    /// Staff handoff veil before resident calm surface opens.
    @Published var residentHandoffActive = false

    /// Offer Face ID once after launch when a profile is linked (resident iPad).
    @Published var shouldOfferResidentSignInOnLaunch = false

    /// Care profile linked to device Face ID / Touch ID (Keychain).
    @Published private(set) var faceIDLinkedPatientId: UUID?

    var faceIDLinkedPatient: CarePatientProfile? {
        carePatient(id: faceIDLinkedPatientId)
    }

    init() {
        faceIDLinkedPatientId = PatientFaceIDLinkStore.linkedPatientId()
    }

    func refreshFaceIDLink() {
        faceIDLinkedPatientId = PatientFaceIDLinkStore.linkedPatientId()
    }

    func linkPatientForFaceIDSignIn(_ patientId: UUID) {
        PatientFaceIDLinkStore.setLinkedPatientId(patientId)
        faceIDLinkedPatientId = patientId
    }

    func unlinkPatientFaceID() {
        PatientFaceIDLinkStore.setLinkedPatientId(nil)
        faceIDLinkedPatientId = nil
    }

    /// Device biometrics → resident calm surface (no corporate sign-in required).
    @MainActor
    func signInWithFaceIDToResidentProfile() async -> String? {
        var linkedId = faceIDLinkedPatientId ?? PatientFaceIDLinkStore.linkedPatientId()
        if linkedId == nil, PatientBiometricAuth.usesPOCMockFlow, let first = carePatients.first {
            linkedId = first.id
            linkPatientForFaceIDSignIn(first.id)
        }
        guard let linkedId else {
            return nil
        }
        guard let patient = carePatient(id: linkedId) else {
            unlinkPatientFaceID()
            return "That linked profile is no longer on this device."
        }
        do {
            try await PatientBiometricAuth.authenticate(
                reason: "Sign in as \(patient.displayName) to open their calm surface."
            )
            residentStaffReturnPhase = .home
            beginResidentFaceIDWelcome(patientId: linkedId)
            CalmExperienceFeedback.signInSuccess()
            return nil
        } catch let error as PatientBiometricAuth.AuthFailure {
            return error.errorDescription
        } catch {
            return PatientBiometricAuth.AuthFailure.failed.errorDescription
        }
    }

    @MainActor
    func linkPatientForFaceIDSignInAfterBiometric(_ patientId: UUID) async -> String? {
        guard let patient = carePatient(id: patientId) else {
            return "That profile is not available."
        }
        do {
            try await PatientBiometricAuth.authenticate(
                reason: "Link \(PatientBiometricAuth.biometryLabel) to \(patient.displayName) on this device."
            )
            linkPatientForFaceIDSignIn(patientId)
            return nil
        } catch let error as PatientBiometricAuth.AuthFailure {
            return error.errorDescription
        } catch {
            return PatientBiometricAuth.AuthFailure.failed.errorDescription
        }
    }

    // MARK: - Discovery calibration (traffic-light smiles + timed snippets)

    @Published private(set) var discoverySnippetIndex: Int = 0
    @Published private(set) var discoveryResults: [DiscoverySnippetResult] = []
    @Published var discoveryPendingPick: DiscoveryTrafficSentiment?

    var selectedMoodsOrdered: [String] {
        moodOptions.filter { selectedMoods.contains($0) }
    }

    func replaceSelectedMoods(_ moods: Set<String>) {
        selectedMoods = moods
    }

    func openResidentProfile() {
        guard selectedCarePatientId != nil else { return }
        residentStaffReturnPhase = .carePatientDetail
        residentHandoffActive = true
    }

    func completeResidentHandoffTransition() {
        guard residentHandoffActive, let pid = selectedCarePatientId else { return }
        residentHandoffActive = false
        enterResidentInstrumentSurface(patientId: pid)
    }

    /// After Face ID — portrait welcome before the calm surface.
    func beginResidentFaceIDWelcome(patientId: UUID) {
        selectedCarePatientId = patientId
        activeCarePatientId = nil
        isResidentSession = false
        isCareStaffSession = false
        phase = .residentFaceIDWelcome
    }

    func completeResidentFaceIDWelcome() {
        guard phase == .residentFaceIDWelcome, let pid = selectedCarePatientId else { return }
        enterResidentInstrumentSurface(patientId: pid)
    }

    func leaveResidentProfileToStaff() {
        clearResidentSessionSurfaceState()
        phase = residentStaffReturnPhase
    }

    /// After choosing a genre symbol and playlist, jump into the existing calm-room pipeline.
    func prepareResidentImmersiveFromPlaylist(genre: ResidentMusicGenre) {
        residentSessionGenre = genre
        if residentTraffic == nil { residentTraffic = .mid }
        if residentFace == nil { residentFace = .neutral }
        beginResidentSessionFromMood()
        phase = .processingFast
    }

    private func enterResidentInstrumentSurface(patientId: UUID) {
        isResidentSession = true
        isCareStaffSession = false
        selectedCarePatientId = patientId
        activeCarePatientId = patientId
        residentSessionGenre = nil
        residentTraffic = nil
        residentFace = nil
        residentVoiceLine = ""
        residentLivingLoopIndex = 0
        residentLivingTickInSegment = 0
        capturedImage = nil
        replaceSelectedMoods([])
        phase = .residentProfile
    }

    func syncResidentMoodPickToMoods() {
        let t = residentTraffic ?? .mid
        let f = residentFace ?? .neutral
        var moods: Set<String> = []
        switch (t, f) {
        case (.low, .sad): moods = ["Overwhelmed", "Stressed"]
        case (.low, .neutral): moods = ["Anxious", "Tired"]
        case (.low, .happy): moods = ["Tired", "Calm"]
        case (.mid, .sad): moods = ["Down", "Anxious"]
        case (.mid, .neutral): moods = ["Tired"]
        case (.mid, .happy): moods = ["Calm", "Tired"]
        case (.high, .sad): moods = ["Down", "Calm"]
        case (.high, .neutral): moods = ["Calm"]
        case (.high, .happy): moods = ["Calm"]
        }
        replaceSelectedMoods(moods)
    }

    func beginResidentSessionFromMood() {
        syncResidentMoodPickToMoods()
        if selectedMoods.isEmpty { replaceSelectedMoods(["Calm"]) }
        isCareStaffSession = true
        isResidentSession = true
        residentLivingLoopIndex = 0
        residentLivingTickInSegment = 0
        beginSession()
    }

    func setResidentAge(for patientId: UUID, age: Int) {
        guard let i = carePatients.firstIndex(where: { $0.id == patientId }) else { return }
        var patients = carePatients
        patients[i].residentAgeYears = age
        carePatients = patients
    }

    func setFavouriteGenre(for patientId: UUID, genre: ResidentMusicGenre) {
        guard let i = carePatients.firstIndex(where: { $0.id == patientId }) else { return }
        var patients = carePatients
        patients[i].favouriteMusicGenre = genre
        carePatients = patients
    }

    func tickLivingPlaylistSegment() {
        residentLivingTickInSegment += 1
        if residentLivingTickInSegment > 9 {
            residentLivingTickInSegment = 0
            residentLivingLoopIndex = min(9, residentLivingLoopIndex + 1)
        }
    }

    func resetLivingPlaylistCounters() {
        residentLivingLoopIndex = 0
        residentLivingTickInSegment = 0
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
            openCorporateSignIn(pendingRosterAfterSignIn: true)
            return
        }
        pendingCareRosterAfterSignIn = false
        phase = .carePatientList
    }

    func openCorporateSignIn(pendingRosterAfterSignIn: Bool = false) {
        pendingCareRosterAfterSignIn = pendingRosterAfterSignIn
        phase = .corporateSignIn
    }

    /// Branch for staff after a resident profile was created / linked from face capture (POC).
    func openFaceLinkedProfilePicker() {
        guard isSignedIn else {
            phase = .home
            return
        }
        selectedCarePatientId = nil
        phase = .careFaceLinkedPick
    }

    func selectCarePatientFromFacePick(_ patientId: UUID) {
        guard isSignedIn else {
            phase = .home
            return
        }
        residentStaffReturnPhase = .careFaceLinkedPick
        enterResidentInstrumentSurface(patientId: patientId)
    }

    func completeCorporateSignIn() {
        isSignedIn = true
        pendingCareRosterAfterSignIn = false
        phase = .carePatientList
    }

    func abandonCorporateSignIn() {
        if !isSignedIn { pendingCareRosterAfterSignIn = false }
        phase = .home
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
        clearResidentSessionSurfaceState()
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
        clearResidentSessionSurfaceState()
        phase = .carePatientDetail
    }

    private func clearResidentSessionSurfaceState() {
        isResidentSession = false
        residentSessionGenre = nil
        residentTraffic = nil
        residentFace = nil
        residentVoiceLine = ""
        resetLivingPlaylistCounters()
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
        if isResidentSession {
            resetLivingPlaylistCounters()
        }
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

    /// Gentle pause before insight or returning to resident playlists.
    func finishSessionWithSettling() {
        endSession()
        phase = .sessionSettling
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
        clearResidentSessionSurfaceState()
        resetDiscoveryState()
        selectedCarePatientId = nil
        resetCarePrepForNewSession()
    }

    func resetAllForFreshAppLaunch() {
        phase = .home
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
        clearResidentSessionSurfaceState()
        resetDiscoveryState()
        resetCarePrepForNewSession()
        resetIoTDefaults()
        refreshFaceIDLink()
        if PatientBiometricAuth.usesPOCMockFlow,
           faceIDLinkedPatientId == nil,
           let first = carePatients.first {
            linkPatientForFaceIDSignIn(first.id)
        }
        shouldOfferResidentSignInOnLaunch = faceIDLinkedPatientId != nil
    }

    private func resetIoTDefaults() {
        iotPhilipsHueEnabled = false
        iotHomeKitEnabled = false
        iotMatterEnabled = false
        iotFollowSessionBreath = true
        iotMaxSceneBrightness = 0.88
    }

    func startDiscoveryCalibration(for patientId: UUID) {
        guard isSignedIn else {
            phase = .home
            return
        }
        selectedCarePatientId = patientId
        activeCarePatientId = patientId
        discoverySnippetIndex = 0
        discoveryResults = []
        discoveryPendingPick = nil
        phase = .careDiscoveryCalibration
    }

    func setDiscoveryPick(_ sentiment: DiscoveryTrafficSentiment) {
        discoveryPendingPick = sentiment
    }

    func commitDiscoverySnippetSlice() {
        let pick = discoveryPendingPick ?? .neutral
        discoveryResults.append(DiscoverySnippetResult(snippetIndex: discoverySnippetIndex, sentiment: pick))
        discoveryPendingPick = nil
        discoverySnippetIndex += 1
        if discoverySnippetIndex >= DiscoveryFlowPOC.snippetCount {
            if let pid = selectedCarePatientId ?? activeCarePatientId,
               let ix = carePatients.firstIndex(where: { $0.id == pid }) {
                var patient = carePatients[ix]
                DiscoveryPlaylistTuning.applyDiscoveryResults(discoveryResults, to: &patient)
                carePatients[ix] = patient
            }
            /// Resident instrument surface opens from `DiscoveryCalibrationView` after the exit typography animation completes.
        }
    }

    func abandonDiscoveryCalibration() {
        discoverySnippetIndex = 0
        discoveryResults = []
        discoveryPendingPick = nil
        phase = .carePatientDetail
    }

    private func resetDiscoveryState() {
        discoverySnippetIndex = 0
        discoveryResults = []
        discoveryPendingPick = nil
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
    case residentProfile = 11
    case careFaceLinkedPick = 12
    /// Timed calm snippets — patient picks traffic-light minimalist face per snippet.
    case careDiscoveryCalibration = 13
    /// Quiet breath before insight or resident return.
    case sessionSettling = 14
    /// Portrait + welcome after Face ID sign-in.
    case residentFaceIDWelcome = 15
    /// Staff corporate credentials — native flow page inside the orb shell.
    case corporateSignIn = 16

    var id: Int { rawValue }
}
