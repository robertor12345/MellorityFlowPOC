import SwiftUI

/// In-memory state for the **care-home one-to-one** session POC (corporate sign-in).
final class SessionPOCState: ObservableObject {
    @Published var phase: FlowPhase = .home
    @Published private(set) var phaseContentVisible = true
    private var phaseTransitionTask: Task<Void, Never>?

    @Published var supervisorUsername = ""
    @Published var supervisorPIN = ""
    @Published var isSignedIn = false
    @Published private(set) var pendingCareRosterAfterSignIn = false
    @Published var supervisorSignInError: String?

    /// Custom portraits keyed by patient id (captured during profile setup).
    @Published var carePatientPortraitImages: [UUID: UIImage] = [:]

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

    /// Where `leaveResidentProfileToStaff()` returns after a resident session.
    @Published var residentStaffReturnPhase: FlowPhase = .carePatientList

    /// Staff handoff veil before resident calm surface opens.
    @Published var residentHandoffActive = false

    /// New-resident discovery: provisional profile id, age input, snippet order, profile prompt.
    @Published private(set) var newResidentDiscoveryPatientId: UUID?
    @Published var newResidentAgeDraft: String = ""
    @Published private(set) var discoverySnippetOrder: [Int] = []
    @Published var newResidentProfileNameDraft: String = ""
    @Published var newResidentProfileAgeDraft: String = ""
    @Published var newResidentProfilePhoto: UIImage?

    /// Sequential post-session sentiment capture (existing residents).
    @Published var sessionSentimentStep: Int = 0
    @Published var sessionSentimentDraft = SessionSentimentDraft()

    /// Telemetry while the resident uses the instrument surface (until supervisor handoff).
    @Published private(set) var residentSurfaceMetrics = ResidentSurfaceSessionMetrics()
    @Published private(set) var residentSurfaceFeedbackPending = false

    // Live audio-reactive levels are published on `MusicReactiveBus` (isolated from navigation
    // state) so the orb + equalizer rings can react at ~24fps without re-rendering the whole flow.

    // MARK: - Group session (supervisor-led, roster compiled playlist)

    @Published var groupSessionTracks: [GroupSessionTrack] = []
    @Published var groupSessionTrackIndex: Int = 0
    @Published private(set) var groupSessionStartedAt: Date?
    @Published private(set) var groupSessionTracksPlayed: Int = 0
    @Published var groupSessionRecords: [GroupSessionRecord] = []
    @Published var groupSessionFeedbackStep: Int = 0
    @Published var groupSessionFeedbackDraft = GroupSessionFeedbackDraft()
    @Published private(set) var isGroupSessionActive = false
    private var groupSessionPlayedTrackIDs: Set<UUID> = []

    // MARK: - Discovery calibration (traffic-light smiles + timed snippets)

    @Published private(set) var discoverySnippetIndex: Int = 0
    @Published private(set) var discoveryResults: [DiscoverySnippetResult] = []
    @Published var discoveryPendingPick: DiscoveryTrafficSentiment?

    func portraitImage(for patientId: UUID) -> UIImage? {
        carePatientPortraitImages[patientId]
    }

    /// Maps logical discovery clip index → physical snippet (era / audio).
    func discoveryPhysicalSnippetIndex(logicalIndex: Int) -> Int {
        guard logicalIndex >= 0, logicalIndex < discoverySnippetOrder.count else {
            return max(0, logicalIndex)
        }
        return discoverySnippetOrder[logicalIndex]
    }

    var selectedMoodsOrdered: [String] {
        moodOptions.filter { selectedMoods.contains($0) }
    }

    func replaceSelectedMoods(_ moods: Set<String>) {
        selectedMoods = moods
    }

    func openResidentProfile() {
        guard selectedCarePatientId != nil else { return }
        residentStaffReturnPhase = .carePatientList
        withAnimation(.easeOut(duration: 0.38)) {
            phaseContentVisible = false
        }
        withAnimation(CalmMotion.softFade) {
            residentHandoffActive = true
        }
    }

    /// Resident calm surface after immersive / settling — always restore visibility.
    func returnToResidentProfile() {
        phaseContentVisible = true
        phase = .residentProfile
    }

    /// Defensive: transition tasks can occasionally leave content hidden.
    func reaffirmPhaseContentVisible() {
        guard phaseContentVisible == false else { return }
        phaseContentVisible = true
    }

    func completeResidentHandoffTransition() {
        guard residentHandoffActive, let pid = selectedCarePatientId else { return }
        residentHandoffActive = false
        enterResidentInstrumentSurface(patientId: pid, setPhase: false)
        phase = .residentProfile
        withAnimation(CalmMotion.softFade) {
            phaseContentVisible = true
        }
    }

    /// Fades out current screen content, swaps phase, then fades in — avoids overlapping UI during loads.
    func transitionToPhase(_ newPhase: FlowPhase) {
        guard phase != newPhase else { return }
        phaseTransitionTask?.cancel()
        phaseTransitionTask = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.38)) {
                phaseContentVisible = false
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            phase = newPhase
            try? await Task.sleep(nanoseconds: 60_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(CalmMotion.softFade) {
                phaseContentVisible = true
            }
        }
    }

    func leaveResidentProfileToStaff() {
        let metricsSnapshot = residentSurfaceMetrics
        clearResidentSessionSurfaceState()

        if newResidentDiscoveryPatientId != nil {
            residentSurfaceMetrics = metricsSnapshot
            prepareNewResidentProfileForm()
            phase = .careNewResidentProfile
            return
        }

        if residentSurfaceFeedbackPending, shouldOfferSessionSentimentFeedback() {
            residentSurfaceMetrics = metricsSnapshot
            beginSessionSentimentFeedback()
            return
        }

        resetResidentSurfaceMetrics()
        phase = residentStaffReturnPhase
    }

    func recordResidentGenrePlay(_ genre: ResidentMusicGenre) {
        residentSurfaceMetrics.recordGenrePlay(genre)
    }

    func recordResidentTrackChange() {
        residentSurfaceMetrics.recordTrackChange()
    }

    func recordResidentImmersiveEntry() {
        residentSurfaceMetrics.recordImmersiveEntry()
    }

    private func resetResidentSurfaceMetrics() {
        residentSurfaceMetrics = ResidentSurfaceSessionMetrics()
        residentSurfaceFeedbackPending = false
    }

    /// After choosing a genre symbol and playlist, jump into the existing calm-room pipeline.
    func prepareResidentImmersiveFromPlaylist(genre: ResidentMusicGenre) {
        recordResidentImmersiveEntry()
        residentSessionGenre = genre
        if residentTraffic == nil { residentTraffic = .mid }
        if residentFace == nil { residentFace = .neutral }
        beginResidentSessionFromMood()
        phase = .processingFast
    }

    private func enterResidentInstrumentSurface(patientId: UUID, setPhase: Bool = true) {
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
        residentSurfaceMetrics = ResidentSurfaceSessionMetrics(startedAt: Date())
        residentSurfaceFeedbackPending = true
        if setPhase {
            phaseContentVisible = true
            phase = .residentProfile
        }
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
        guard isSignedIn else { return }
        pendingCareRosterAfterSignIn = false
        phase = .carePatientList
    }

    func completeSupervisorSignIn() -> String? {
        if let error = SupervisorAuth.validate(username: supervisorUsername, pin: supervisorPIN) {
            supervisorSignInError = error
            return error
        }
        supervisorSignInError = nil
        isSignedIn = true
        pendingCareRosterAfterSignIn = false
        phaseTransitionTask?.cancel()
        phase = .supervisorWelcome
        withAnimation(CalmMotion.softFade) {
            phaseContentVisible = true
        }
        return nil
    }

    func abandonSupervisorSignIn() {
        supervisorSignInError = nil
        if !isSignedIn {
            supervisorUsername = ""
            supervisorPIN = ""
        }
    }

    /// Supervisor tapped home from roster.
    func navigateStaffToHome() {
        phase = .home
        selectedCarePatientId = nil
    }

    func beginNewResidentDiscovery() {
        guard isSignedIn else {
            phase = .home
            return
        }
        selectedCarePatientId = nil
        newResidentAgeDraft = ""
        newResidentDiscoveryPatientId = nil
        StreamAudioCache.prefetch(DiscoveryFlowPOC.snippetAudioStreamURLs)
        transitionToPhase(.careDiscoveryAgeInput)
    }

    func continueNewResidentDiscoveryFromAgeInput() -> String? {
        let trimmed = newResidentAgeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let age = Int(trimmed), (55 ... 105).contains(age) else {
            return "Enter an age between 55 and 105."
        }
        let patientId = UUID()
        let provisional = CarePatientProfile(
            id: patientId,
            displayName: "New resident",
            careContextLabel: "Discovery in progress",
            likes: [],
            dislikes: [],
            preferredLight: "Soft, indirect — avoid overhead glare.",
            scentGuidance: "Unscented room unless familiar and agreed.",
            touchComfortNotes: "Ask before touch; go slowly.",
            comfortThemes: [],
            prefersGentleSoundOnsets: true,
            musicTempoBias: 0.35,
            natureVsAbstract: 0.3,
            voiceVsInstrumental: 0.4,
            residentAgeYears: age,
            favouriteMusicGenre: .classical,
            stockPortraitAssetName: "StockPortraitSam",
            isProvisional: true,
            genrePlaylistGroups: []
        )
        carePatients.append(provisional)
        newResidentDiscoveryPatientId = patientId
        selectedCarePatientId = patientId
        activeCarePatientId = patientId
        discoverySnippetOrder = DiscoveryFlowPOC.orderedSnippetIndices(forResidentAge: age)
        discoverySnippetIndex = 0
        discoveryResults = []
        discoveryPendingPick = nil
        StreamAudioCache.prefetchDiscovery(order: discoverySnippetOrder)
        transitionToPhase(.careDiscoveryCalibration)
        return nil
    }

    func abandonNewResidentAgeInput() {
        newResidentAgeDraft = ""
        transitionToPhase(.carePatientList)
    }

    private func prepareNewResidentProfileForm() {
        guard let pid = newResidentDiscoveryPatientId,
              let patient = carePatient(id: pid) else { return }
        newResidentProfileNameDraft = ""
        newResidentProfileAgeDraft = String(patient.residentAgeYears)
        newResidentProfilePhoto = carePatientPortraitImages[pid]
    }

    func saveNewResidentProfile() -> String? {
        guard let pid = newResidentDiscoveryPatientId,
              let idx = carePatients.firstIndex(where: { $0.id == pid }) else {
            return "That profile is no longer available."
        }
        let name = newResidentProfileNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "Enter the resident’s name." }
        let ageTrim = newResidentProfileAgeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let age = Int(ageTrim), (55 ... 105).contains(age) else {
            return "Enter an age between 55 and 105."
        }
        guard newResidentProfilePhoto != nil else {
            return "Add a photo so future supervisors can recognise them."
        }

        var patients = carePatients
        patients[idx].displayName = name
        patients[idx].residentAgeYears = age
        patients[idx].careContextLabel = "New on roster"
        patients[idx].isProvisional = false
        if patients[idx].genrePlaylistGroups.isEmpty {
            patients[idx].genrePlaylistGroups = [
                DiscoveryPlaylistTuning.stubGenreGroup(for: patients[idx].favouriteMusicGenre),
            ]
        }
        carePatients = patients
        if let photo = newResidentProfilePhoto {
            carePatientPortraitImages[pid] = photo
        }

        if residentSurfaceFeedbackPending {
            appendCareSessionRecord(patientId: pid, staffNote: nil, surfaceMetrics: residentSurfaceMetrics)
        }

        newResidentDiscoveryPatientId = nil
        newResidentProfileNameDraft = ""
        newResidentProfileAgeDraft = ""
        newResidentProfilePhoto = nil
        selectedCarePatientId = pid
        resetResidentSurfaceMetrics()
        phase = .carePatientList
        return nil
    }

    func cancelNewResidentProfileSave() {
        if let pid = newResidentDiscoveryPatientId {
            carePatients.removeAll { $0.id == pid && $0.isProvisional }
            carePatientPortraitImages.removeValue(forKey: pid)
        }
        newResidentDiscoveryPatientId = nil
        newResidentProfileNameDraft = ""
        newResidentProfileAgeDraft = ""
        newResidentProfilePhoto = nil
        selectedCarePatientId = nil
        phase = .carePatientList
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
        comfortTolerance: Int? = nil,
        moodRating: Int? = nil,
        alertnessRating: Int? = nil,
        emotionalStateRating: Int? = nil,
        lucidityRating: Int? = nil,
        surfaceMetrics: ResidentSurfaceSessionMetrics? = nil
    ) {
        let metrics = surfaceMetrics ?? (residentSurfaceFeedbackPending ? residentSurfaceMetrics : nil)
        let rec = CareSessionRecord(
            id: UUID(),
            patientId: patientId,
            date: Date(),
            moodSummary: replayMoodSnapshot ?? "—",
            calmPercent: Int(calmScore * 100),
            staffNote: staffNote,
            settledness: settledness,
            engagement: engagement,
            comfortTolerance: comfortTolerance,
            moodRating: moodRating,
            alertnessRating: alertnessRating,
            emotionalStateRating: emotionalStateRating,
            lucidityRating: lucidityRating,
            sessionDurationSeconds: metrics?.durationSeconds,
            residentGenrePlayCount: metrics.map(\.totalGenrePlays).flatMap { $0 > 0 ? $0 : nil },
            residentTrackChangeCount: metrics.map(\.trackChangeCount).flatMap { $0 > 0 ? $0 : nil },
            residentImmersiveEntryCount: metrics.map(\.immersiveEntryCount).flatMap { $0 > 0 ? $0 : nil },
            residentGenresPlayedSummary: metrics?.genresPlayedSummary()
        )
        careSessionRecords.insert(rec, at: 0)
    }

    func shouldOfferSessionSentimentFeedback() -> Bool {
        guard newResidentDiscoveryPatientId == nil,
              let pid = activeCarePatientId ?? selectedCarePatientId,
              let patient = carePatient(id: pid),
              !patient.isProvisional
        else { return false }
        return residentSurfaceFeedbackPending || isCareStaffSession
    }

    func beginSessionSentimentFeedback() {
        sessionSentimentStep = 0
        sessionSentimentDraft = SessionSentimentDraft()
        phase = .careSessionSentimentFeedback
    }

    func sessionSentimentBinding(for step: CareSessionSentimentStep) -> Binding<Int?> {
        switch step {
        case .mood:
            return Binding(
                get: { self.sessionSentimentDraft.mood },
                set: { self.sessionSentimentDraft.mood = $0 }
            )
        case .alertness:
            return Binding(
                get: { self.sessionSentimentDraft.alertness },
                set: { self.sessionSentimentDraft.alertness = $0 }
            )
        case .emotionalState:
            return Binding(
                get: { self.sessionSentimentDraft.emotionalState },
                set: { self.sessionSentimentDraft.emotionalState = $0 }
            )
        case .lucidity:
            return Binding(
                get: { self.sessionSentimentDraft.lucidity },
                set: { self.sessionSentimentDraft.lucidity = $0 }
            )
        }
    }

    func advanceSessionSentimentStep() {
        sessionSentimentStep = min(sessionSentimentStep + 1, CareSessionSentimentStep.allCases.count - 1)
    }

    func retreatSessionSentimentStep() {
        sessionSentimentStep = max(sessionSentimentStep - 1, 0)
    }

    func saveSessionSentimentFeedback() {
        guard let pid = activeCarePatientId ?? selectedCarePatientId,
              let mood = sessionSentimentDraft.mood,
              let alertness = sessionSentimentDraft.alertness,
              let emotional = sessionSentimentDraft.emotionalState,
              let lucidity = sessionSentimentDraft.lucidity
        else { return }

        let note = sessionSentimentDraft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        appendCareSessionRecord(
            patientId: pid,
            staffNote: note.isEmpty ? nil : note,
            moodRating: mood,
            alertnessRating: alertness,
            emotionalStateRating: emotional,
            lucidityRating: lucidity
        )
        finishAfterSessionFeedback(patientId: pid)
    }

    func skipSessionSentimentFeedback() {
        let pid = activeCarePatientId ?? selectedCarePatientId
        if let pid {
            appendCareSessionRecord(patientId: pid, staffNote: nil)
        }
        if let pid {
            finishAfterSessionFeedback(patientId: pid)
        } else {
            phase = .carePatientList
        }
    }

    private func finishAfterSessionFeedback(patientId: UUID) {
        sessionSentimentStep = 0
        sessionSentimentDraft = SessionSentimentDraft()
        isCareStaffSession = false
        activeCarePatientId = nil
        selectedCarePatientId = patientId
        clearResidentSessionSurfaceState()
        resetResidentSurfaceMetrics()
        phase = .carePatientList
    }

    func sentimentSummary(for patientId: UUID) -> CareSessionSentimentSummary {
        CareSessionSentimentAnalytics.summary(for: recordsForPatient(patientId))
    }

    func careHomeSentimentOverview() -> CareSessionSentimentSummary {
        let roster = carePatients.filter { !$0.isProvisional }
        return CareSessionSentimentAnalytics.homeOverview(for: roster, records: careSessionRecords)
    }

    // MARK: - Group session

    func beginGroupSession() {
        guard isSignedIn else {
            phase = .home
            return
        }
        groupSessionTracks = GroupSessionPlaylistCompiler.compile(
            patients: carePatients,
            sessionRecords: careSessionRecords
        )
        groupSessionTrackIndex = 0
        groupSessionStartedAt = Date()
        groupSessionTracksPlayed = 0
        groupSessionPlayedTrackIDs = []
        groupSessionFeedbackStep = 0
        groupSessionFeedbackDraft = GroupSessionFeedbackDraft()
        isGroupSessionActive = true
        phase = .careGroupSession
    }

    func endGroupSession() {
        guard isGroupSessionActive else { return }
        isGroupSessionActive = false
        groupSessionFeedbackStep = 0
        groupSessionFeedbackDraft = GroupSessionFeedbackDraft()
        phase = .careGroupSessionFeedback
    }

    func groupSessionNextTrack() {
        guard !groupSessionTracks.isEmpty else { return }
        groupSessionTrackIndex = (groupSessionTrackIndex + 1) % groupSessionTracks.count
    }

    func groupSessionPreviousTrack() {
        guard !groupSessionTracks.isEmpty else { return }
        groupSessionTrackIndex = (groupSessionTrackIndex - 1 + groupSessionTracks.count) % groupSessionTracks.count
    }

    func groupSessionSelectTrack(at index: Int) {
        guard groupSessionTracks.indices.contains(index) else { return }
        groupSessionTrackIndex = index
    }

    func markGroupTrackPlayed() {
        guard groupSessionTracks.indices.contains(groupSessionTrackIndex) else { return }
        let id = groupSessionTracks[groupSessionTrackIndex].id
        guard !groupSessionPlayedTrackIDs.contains(id) else { return }
        groupSessionPlayedTrackIDs.insert(id)
        groupSessionTracksPlayed += 1
    }

    func groupSessionDurationSummary() -> String? {
        var parts: [String] = []
        if let startedAt = groupSessionStartedAt {
            let seconds = max(1, Int(Date().timeIntervalSince(startedAt).rounded()))
            let mins = seconds / 60
            let secs = seconds % 60
            if mins > 0 {
                parts.append(String(format: "%dm %ds", mins, secs))
            } else {
                parts.append("\(secs)s")
            }
        }
        if groupSessionTracksPlayed > 0 {
            parts.append("\(groupSessionTracksPlayed) track\(groupSessionTracksPlayed == 1 ? "" : "s") played")
        }
        if !groupSessionTracks.isEmpty {
            parts.append("\(groupSessionTracks.count) in compiled playlist")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    func groupSessionFeedbackBinding(for step: GroupSessionFeedbackStep) -> Binding<Int?> {
        switch step {
        case .morale:
            return Binding(get: { self.groupSessionFeedbackDraft.morale }, set: { self.groupSessionFeedbackDraft.morale = $0 })
        case .alertness:
            return Binding(get: { self.groupSessionFeedbackDraft.alertness }, set: { self.groupSessionFeedbackDraft.alertness = $0 })
        case .lucidity:
            return Binding(get: { self.groupSessionFeedbackDraft.lucidity }, set: { self.groupSessionFeedbackDraft.lucidity = $0 })
        case .engagement:
            return Binding(get: { self.groupSessionFeedbackDraft.engagement }, set: { self.groupSessionFeedbackDraft.engagement = $0 })
        }
    }

    func advanceGroupSessionFeedbackStep() {
        groupSessionFeedbackStep = min(groupSessionFeedbackStep + 1, GroupSessionFeedbackStep.allCases.count - 1)
    }

    func retreatGroupSessionFeedbackStep() {
        groupSessionFeedbackStep = max(groupSessionFeedbackStep - 1, 0)
    }

    func saveGroupSessionFeedback() {
        guard let morale = groupSessionFeedbackDraft.morale,
              let alertness = groupSessionFeedbackDraft.alertness,
              let lucidity = groupSessionFeedbackDraft.lucidity,
              let engagement = groupSessionFeedbackDraft.engagement
        else { return }

        let note = groupSessionFeedbackDraft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let duration = groupSessionStartedAt.map { max(1, Int(Date().timeIntervalSince($0).rounded())) } ?? 0
        let snapshot = groupSessionTracks.map(\.title)

        let rec = GroupSessionRecord(
            id: UUID(),
            date: Date(),
            durationSeconds: duration,
            tracksPlayed: groupSessionTracksPlayed,
            moraleRating: morale,
            alertnessRating: alertness,
            lucidityRating: lucidity,
            engagementRating: engagement,
            staffNote: note.isEmpty ? nil : note,
            playlistSnapshot: snapshot
        )
        groupSessionRecords.insert(rec, at: 0)
        resetGroupSessionState()
        phase = .carePatientList
    }

    func skipGroupSessionFeedback() {
        let duration = groupSessionStartedAt.map { max(1, Int(Date().timeIntervalSince($0).rounded())) } ?? 0
        let rec = GroupSessionRecord(
            id: UUID(),
            date: Date(),
            durationSeconds: duration,
            tracksPlayed: groupSessionTracksPlayed,
            moraleRating: nil,
            alertnessRating: nil,
            lucidityRating: nil,
            engagementRating: nil,
            staffNote: nil,
            playlistSnapshot: groupSessionTracks.map(\.title)
        )
        groupSessionRecords.insert(rec, at: 0)
        resetGroupSessionState()
        phase = .carePatientList
    }

    private func resetGroupSessionState() {
        groupSessionTracks = []
        groupSessionTrackIndex = 0
        groupSessionStartedAt = nil
        groupSessionTracksPlayed = 0
        groupSessionPlayedTrackIDs = []
        groupSessionFeedbackStep = 0
        groupSessionFeedbackDraft = GroupSessionFeedbackDraft()
        isGroupSessionActive = false
    }

    func latestGroupSessionSummaryLine() -> String? {
        guard let last = groupSessionRecords.first,
              let morale = last.moraleRating,
              let alertness = last.alertnessRating,
              let lucidity = last.lucidityRating,
              let engagement = last.engagementRating
        else { return nil }
        return String(format: "Last group: morale %d · alert %d · lucidity %d · engaged %d", morale, alertness, lucidity, engagement)
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
            comfortTolerance: comfortTolerance,
            surfaceMetrics: residentSurfaceFeedbackPending ? residentSurfaceMetrics : nil
        )
        resetResidentSurfaceMetrics()
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
        phaseTransitionTask?.cancel()
        phaseContentVisible = true
        phase = .home
        supervisorUsername = ""
        supervisorPIN = ""
        supervisorSignInError = nil
        isSignedIn = false
        pendingCareRosterAfterSignIn = false
        carePatientPortraitImages = [:]
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
        resetNewResidentFlowState()
        resetGroupSessionState()
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

    func startDiscoveryCalibration(for patientId: UUID) {
        guard isSignedIn else {
            phase = .home
            return
        }
        selectedCarePatientId = patientId
        activeCarePatientId = patientId
        if let patient = carePatient(id: patientId) {
            discoverySnippetOrder = DiscoveryFlowPOC.orderedSnippetIndices(forResidentAge: patient.residentAgeYears)
        } else {
            discoverySnippetOrder = Array(0..<DiscoveryFlowPOC.snippetCount)
        }
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
        if newResidentDiscoveryPatientId != nil {
            phase = .carePatientList
        } else {
            phase = .carePatientDetail
        }
    }

    private func resetDiscoveryState() {
        discoverySnippetIndex = 0
        discoveryResults = []
        discoveryPendingPick = nil
        discoverySnippetOrder = []
    }

    private func resetNewResidentFlowState() {
        newResidentDiscoveryPatientId = nil
        newResidentAgeDraft = ""
        newResidentProfileNameDraft = ""
        newResidentProfileAgeDraft = ""
        newResidentProfilePhoto = nil
        resetResidentSurfaceMetrics()
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
    /// Resident age before a new-resident discovery pass.
    case careDiscoveryAgeInput = 17
    /// Supervisor captures name, age, and photo after a new-resident session.
    case careNewResidentProfile = 18
    /// Sequential 1–10 sentiment ratings after sessions with existing residents.
    case careSessionSentimentFeedback = 19
    /// Supervisor-led group listening with compiled cross-resident playlist.
    case careGroupSession = 20
    /// Group morale / alertness / lucidity / engagement after group session ends.
    case careGroupSessionFeedback = 21
    /// Brief welcome after supervisor sign-in before the resident roster.
    case supervisorWelcome = 22

    var id: Int { rawValue }
}
