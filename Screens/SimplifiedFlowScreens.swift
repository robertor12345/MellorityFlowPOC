import SwiftUI

// MARK: - Home — corporate sign-in + care roster

struct HomeView: View {
    @ObservedObject var state: SessionPOCState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var faceIDBusy = false
    @State private var faceIDMessage: String?
    @State private var showStaffOptions = false

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                GeometryReader { geo in
                    homeScrollContent(viewportHeight: max(geo.size.height, 400))
                        .frame(maxWidth: .infinity, minHeight: max(geo.size.height, 400))
                }
            }
        }
        .onAppear {
            state.refreshFaceIDLink()
        }
    }

    @ViewBuilder
    private func homeScrollContent(viewportHeight: CGFloat) -> some View {
        VStack(spacing: SignInPageLayout.sectionSpacing) {
            Spacer(minLength: BrandLayout.homeTopSpacer(min: viewportHeight, horizontalSizeClass: horizontalSizeClass) * 0.35)

            FadeInNoteStalgiaWordmark(magnification: SignInPageLayout.scale, delay: 0)

            VStack(spacing: SignInPageLayout.stackSpacing) {
                if !showStaffOptions {
                    ResidentFaceIDHomeSignInButton(
                        linkedPatient: state.faceIDLinkedPatient,
                        isBusy: faceIDBusy,
                        statusMessage: faceIDMessage,
                        onSignIn: { performFaceIDSignIn() }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                HomeStaffToggleButton(isExpanded: showStaffOptions) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showStaffOptions.toggle()
                    }
                }

                if showStaffOptions {
                    VStack(spacing: SignInPageLayout.points(10)) {
                        if !state.isSignedIn {
                            SignInSecondaryButton(title: "Corporate sign-in") {
                                state.openCorporateSignIn()
                            }
                        }
                        if state.isSignedIn {
                            SignInSecondaryButton(title: "One-to-one calm") {
                                state.enterOneToOneCalmFlow()
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: showStaffOptions)
            .padding(.horizontal, BrandLayout.contentGutter(for: horizontalSizeClass))

            Spacer(minLength: SignInPageLayout.sectionSpacing)
        }
    }

    private func performFaceIDSignIn() {
        guard !faceIDBusy else { return }
        faceIDBusy = true
        faceIDMessage = nil
        Task {
            let error = await state.signInWithFaceIDToResidentProfile()
            faceIDBusy = false
            faceIDMessage = error
        }
    }
}

// MARK: - Corporate sign-in (native flow page — orb shell + dissolve transition)

struct CorporateSignInView: View {
    @ObservedObject var state: SessionPOCState
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case email, password }

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen(
                backAccessibilityLabel: "Back to home",
                onBack: { state.abandonCorporateSignIn() }
            ) {
                VStack(spacing: 24) {
                    FadeInTitle(text: "Corporate sign-in", delay: 0)
                    FadeInLine(
                        text: "Staff roster, room prep, and session notes.",
                        delay: 0.08
                    )

                    BrandCard {
                        VStack(alignment: .leading, spacing: 18) {
                            labeledField(
                                title: "Email",
                                content: {
                                    TextField("you@example.com", text: $state.email)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .password }
                                }
                            )
                            labeledField(
                                title: "Password",
                                content: {
                                    SecureField("Password", text: $state.password)
                                        .textContentType(.password)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit(signInContinue)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)

                    PrimaryButton(title: "Continue", action: signInContinue)
                        .padding(.horizontal, 24)
                }
                .padding(.vertical, 28)
            }
        }
    }

    private func labeledField(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandTheme.brownMuted)
            content()
                .font(.body)
                .foregroundStyle(BrandTheme.brown)
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

    private func signInContinue() {
        state.completeCorporateSignIn()
        CalmExperienceFeedback.signInSuccess()
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
                                        .foregroundStyle(BrandTheme.brown)
                                    Text("\(patient.displayName) — \(patient.careContextLabel)")
                                        .font(.caption)
                                        .foregroundStyle(BrandTheme.brownMuted)
                                    Text("Their notes cover light, scent, touch, and sound — keep things soft. Mood tags are just for today.")
                                        .font(.caption2)
                                        .foregroundStyle(BrandTheme.brownMuted.opacity(0.95))
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

                    TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
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
                        state.phase = .residentProfile
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

