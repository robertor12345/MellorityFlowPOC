import SwiftUI

// MARK: - Home — supervisor username + PIN → roster

struct HomeView: View {
    @ObservedObject var state: SessionPOCState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case username, pin }

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                GeometryReader { geo in
                    homeScrollContent(viewportHeight: max(geo.size.height, 400))
                        .frame(maxWidth: .infinity, minHeight: max(geo.size.height, 400))
                }
            }
        }
    }

    @ViewBuilder
    private func homeScrollContent(viewportHeight: CGFloat) -> some View {
        VStack(spacing: SignInPageLayout.sectionSpacing) {
            Spacer(minLength: BrandLayout.homeTopSpacer(min: viewportHeight, horizontalSizeClass: horizontalSizeClass) * 0.35)

            FadeInNoteStalgiaWordmark(magnification: SignInPageLayout.scale, delay: 0)

            if state.isSignedIn {
                signedInContent
            } else {
                supervisorSignInContent
            }

            Spacer(minLength: SignInPageLayout.sectionSpacing)
        }
    }

    private var signedInContent: some View {
        VStack(spacing: SignInPageLayout.stackSpacing) {
            FadeInLine(
                text: "Signed in — open the resident roster or sign out.",
                delay: 0.06
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, BrandLayout.contentGutter(for: horizontalSizeClass))

            PrimaryButton(title: "One-to-one calm") {
                state.enterOneToOneCalmFlow()
            }
            .padding(.horizontal, 24)

            SecondaryButton(title: "Sign out") {
                state.isSignedIn = false
                state.supervisorUsername = ""
                state.supervisorPIN = ""
            }
            .padding(.horizontal, 24)
        }
    }

    private var supervisorSignInContent: some View {
        VStack(spacing: SignInPageLayout.stackSpacing) {
            FadeInLine(
                text: "Supervisor sign-in for this care home.",
                delay: 0.06
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, BrandLayout.contentGutter(for: horizontalSizeClass))

            BrandCard {
                VStack(alignment: .leading, spacing: 18) {
                    labeledField(
                        title: "Username",
                        content: {
                            TextField("Username", text: $state.supervisorUsername)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .username)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .pin }
                        }
                    )
                    labeledField(
                        title: "PIN",
                        content: {
                            SecureField("PIN", text: $state.supervisorPIN)
                                .textContentType(.oneTimeCode)
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .pin)
                                .submitLabel(.go)
                                .onSubmit(attemptSignIn)
                        }
                    )
                }
            }
            .padding(.horizontal, BrandLayout.contentGutter(for: horizontalSizeClass))

            if let error = state.supervisorSignInError, !error.isEmpty {
                Text(error)
                    .font(SignInPageLayout.captionFont)
                    .orbOverlayText(muted: true)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            PrimaryButton(title: "Continue", action: attemptSignIn)
                .padding(.horizontal, 24)
        }
    }

    private func labeledField(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandTheme.textSecondary)
            content()
                .font(.body)
                .foregroundStyle(BrandTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(BrandTheme.creamMid.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(BrandTheme.gold.opacity(0.28), lineWidth: 1)
                )
        }
    }

    private func attemptSignIn() {
        if state.completeSupervisorSignIn() == nil {
            CalmExperienceFeedback.signInSuccess()
        }
    }
}

// MARK: - Supervisor welcome (post sign-in, before roster)

struct SupervisorWelcomeView: View {
    @ObservedObject var state: SessionPOCState
    @State private var greetingVisible = false
    @State private var loaderVisible = false
    @State private var didScheduleExit = false

    private var displayName: String {
        let trimmed = state.supervisorUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Supervisor" }
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst().lowercased()
    }

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                CalmCircularLoader(diameter: 76)
                    .opacity(loaderVisible ? 1 : 0)
                    .scaleEffect(loaderVisible ? 1 : 0.92)

                Text("Welcome \(displayName)")
                    .font(BrandTheme.orbTitleFont(.largeTitle))
                    .tracking(2)
                    .orbOverlayText()
                    .multilineTextAlignment(.center)
                    .opacity(greetingVisible ? 1 : 0)
                    .offset(y: greetingVisible ? 0 : 14)
                    .scaleEffect(greetingVisible ? 1 : 0.97)
            }
            .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome \(displayName). Loading roster.")
        .onAppear {
            StreamAudioCache.prefetchWarmCatalog()
            withAnimation(CalmMotion.softFade.delay(0.12)) {
                loaderVisible = true
            }
            withAnimation(CalmMotion.gentle.delay(0.28)) {
                greetingVisible = true
            }
            guard !didScheduleExit else { return }
            didScheduleExit = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_200_000_000)
                guard state.phase == .supervisorWelcome else { return }
                state.transitionToPhase(.carePatientList)
            }
        }
    }
}

// MARK: - Entry mode — Camera vs Quick Start

struct EntryModeView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen(onBack: { state.goBackFromEntryMode() }) {
                VStack(spacing: 22) {
                    FadeInTitle(text: "How would you like to begin?", delay: 0)
                    FadeInLine(
                        text: "Use a photo as a gentle anchor, or skip straight to how you’re feeling.",
                        delay: 0.06
                    )

                    if state.isCareStaffSession, let patient = state.carePatient(id: state.activeCarePatientId) {
                        BrandCard {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "cross.case.fill")
                                    .font(.title3)
                                    .foregroundStyle(BrandTheme.goldDeep)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Together for a little while")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(BrandTheme.textPrimary)
                                    Text("\(patient.displayName) — \(patient.careContextLabel)")
                                        .font(.caption)
                                        .foregroundStyle(BrandTheme.textSecondary)
                                    Text("Their notes cover light, scent, touch, and sound — keep things soft. Mood tags are just for today.")
                                        .font(.caption2)
                                        .foregroundStyle(BrandTheme.textSecondary.opacity(0.95))
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    VStack(spacing: 14) {
                        OrbNavTile(
                            title: "Camera",
                            subtitle: "Pick or take a photo, then we’ll shape the session around it.",
                            systemImage: "camera.fill"
                        ) {
                            state.phase = .captureMoment
                        }
                        OrbNavTile(
                            title: "Quick start",
                            subtitle: "No photo — just tell us how you’re doing.",
                            systemImage: "bolt.fill"
                        ) {
                            state.phase = .moodSelect
                        }
                    }
                    .padding(.horizontal, 20)

                }
                .padding(.vertical, 28)
            }
        }
    }
}

// MARK: - Mood select

struct MoodSelectView: View {
    @ObservedObject var state: SessionPOCState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen(onBack: {
                state.phase = state.capturedImage != nil ? .captureMoment : .entryMode
            }) {
                VStack(spacing: 22) {
                    FadeInTitle(text: "How are you feeling?", delay: 0)

                    if state.isCareStaffSession, let patient = state.carePatient(id: state.activeCarePatientId) {
                        Text("With \(patient.displayName) — mood tags are just for today.")
                            .font(.caption)
                            .foregroundStyle(BrandTheme.goldDeep)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    TimelineView(.animation(minimumInterval: 1 / OrbRenderBudget.contentFramesPerSecond, paused: false)) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        Group {
                            if BrandLayout.isRegularWidth(horizontalSizeClass) {
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 20),
                                        GridItem(.flexible(), spacing: 20),
                                    ],
                                    spacing: 24
                                ) {
                                    moodOrbButtons(phase: t)
                                }
                            } else {
                                VStack(spacing: 26) {
                                    moodOrbButtons(phase: t)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                    }
                    .padding(.horizontal, 8)

                    PrimaryButton(title: "Begin") {
                        state.beginSession()
                        state.phase = .processingFast
                    }
                    .disabled(state.selectedMoods.isEmpty)
                    .opacity(state.selectedMoods.isEmpty ? 0.45 : 1)
                    .padding(.horizontal, 24)

                }
                .padding(.vertical, 28)
            }
        }
    }

    @ViewBuilder
    private func moodOrbButtons(phase t: TimeInterval) -> some View {
        ForEach(Array(state.moodOptions.enumerated()), id: \.offset) { index, mood in
            OrbMoodNavOrb(
                title: mood,
                index: index,
                phase: t,
                isSelected: state.selectedMoods.contains(mood)
            ) {
                state.toggleMoodSelection(mood)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.78), value: state.selectedMoods)
        }
    }
}

// MARK: - End session → Insight (simple + visual)

struct InsightView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        if state.isResidentSession {
            ScreenFadeIn {
                VStack {
                    Spacer()
                    OrbIconNavButton(
                        systemImage: "square.grid.2x2.fill",
                        accessibilityLabel: "Return to playlists",
                        diameter: 64
                    ) {
                        state.returnToResidentProfile()
                    }
                    .padding(.bottom, 32)
                    .safeAreaPadding(.bottom, 16)
                }
                .padding(.horizontal, BrandTheme.contentGutter)
            }
        } else {
            ScreenFadeIn {
                CenteredScrollScreen(
                    backAccessibilityLabel: "Back to profile",
                    onBack: { state.skipCareFeedback() }
                ) {
                    VStack(spacing: 24) {
                        FadeInTitle(text: "How that felt", delay: 0)
                        FadeInLine(
                            text: "A small pause — not a report card.",
                            delay: 0.1
                        )

                        PrimaryButton(title: "Jot a note & nudge the next session") {
                            state.phase = .careSessionFeedback
                        }
                        .padding(.horizontal, 24)

                        SecondaryButton(title: "Skip for now — back to profile") {
                            state.skipCareFeedback()
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 28)
                }
            }
        }
    }
}