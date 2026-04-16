import SwiftUI

// MARK: - Home — Start Session (no login)

struct HomeView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(spacing: 28) {
                    MellorityLogoImage(maxHeight: 140)
                        .frame(maxWidth: .infinity)

                    FadeInTitle(text: "Mellority", delay: 0.05)
                    FadeInLine(
                        text: "Calm that meets you where you are.",
                        font: BrandTheme.title(.title3),
                        color: BrandTheme.brownMuted,
                        delay: 0.15
                    )
                    FadeInLine(
                        text: state.isSignedIn
                            ? "You’re signed in — sync when you’re ready."
                            : "No account needed to begin.",
                        font: .subheadline,
                        delay: 0.28
                    )

                    VStack(spacing: 12) {
                        PrimaryButton(title: "Start Session") {
                            state.phase = .entryMode
                        }
                        if state.isSignedIn {
                            SecondaryButton(title: "Connected devices") {
                                state.phase = .connectedDevices
                            }
                        }
                        if !state.isSignedIn {
                            SecondaryButton(title: "Sign in") {
                                state.showSignInSheet = true
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }
            }
        }
        .sheet(isPresented: $state.showSignInSheet) {
            OptionalSignInSheet(state: state)
        }
    }
}

// MARK: - Optional sign-in

struct OptionalSignInSheet: View {
    @ObservedObject var state: SessionPOCState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case email, password }

    var body: some View {
        ZStack {
            BrandBackground()
                .ignoresSafeArea()

            CenteredScrollScreen {
                VStack(spacing: 24) {
                    HStack {
                        Spacer()
                        Button("Close") { dismiss() }
                            .font(BrandTheme.buttonLabel(.subheadline))
                            .foregroundStyle(BrandTheme.brownMuted)
                    }

                    FadeInTitle(text: "Sign in", delay: 0)
                    FadeInLine(
                        text: "Sign in to sync preferences across your devices when available.",
                        font: .subheadline,
                        color: BrandTheme.brownMuted,
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
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .password }
                                }
                            )
                            labeledField(
                                title: "Password",
                                content: {
                                    SecureField("Required to sign in", text: $state.password)
                                        .textContentType(.password)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit(signInContinue)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)

                    VStack(spacing: 12) {
                        PrimaryButton(title: "Continue", action: signInContinue)
                        SecondaryButton(title: "Cancel") {
                            dismiss()
                        }
                    }
                }
                .padding(24)
            }
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(22)
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
        state.isSignedIn = true
        state.showSignInSheet = false
        state.phase = .postSignInFeatureSlides
        dismiss()
    }
}

// MARK: - Entry mode — Camera vs Quick Start

struct EntryModeView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(spacing: 22) {
                    FadeInTitle(text: "Choose Entry Mode", delay: 0)
                    FadeInLine(text: "Camera: pick or take a photo, confirm, then session — or Quick Start for mood only.", delay: 0.12)

                    VStack(spacing: 14) {
                        entryCard(
                            title: "Camera",
                            subtitle: "Upload or take a photo, confirm, then your session starts.",
                            systemImage: "camera.fill",
                            delay: 0.2
                        ) {
                            state.phase = .captureMoment
                        }
                        entryCard(
                            title: "Quick Start",
                            subtitle: "Skip capture — mood only.",
                            systemImage: "bolt.fill",
                            delay: 0.32
                        ) {
                            state.phase = .moodSelect
                        }
                    }
                    .padding(.horizontal, 20)

                    SecondaryButton(title: "Back") { state.phase = .home }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
                .padding(.vertical, 28)
            }
        }
    }

    private func entryCard(
        title: String,
        subtitle: String,
        systemImage: String,
        delay: Double,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            BrandCard {
                VStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.title)
                        .foregroundStyle(BrandTheme.goldDeep)
                    FadeInLine(text: title, font: BrandTheme.title(.title3), color: BrandTheme.brown, delay: delay)
                    FadeInLine(text: subtitle, font: .caption, delay: delay + 0.06)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mood select

struct MoodSelectView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(spacing: 22) {
                    FadeInTitle(text: "How do you feel?", delay: 0)
                    FadeInLine(text: "We’ll adapt sound and motion to this — in seconds.", delay: 0.06)
                    FadeInLine(
                        text: "There’s no wrong answer — pick what fits closest right now.",
                        font: .caption,
                        color: BrandTheme.brownMuted.opacity(0.95),
                        delay: 0.14
                    )

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Array(state.moodOptions.enumerated()), id: \.offset) { i, mood in
                            let selected = state.selectedMood == mood
                            Button {
                                state.selectedMood = mood
                            } label: {
                                Text(mood)
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(selected ? BrandTheme.goldSoft.opacity(0.85) : BrandTheme.cream.opacity(0.9))
                                    .foregroundStyle(BrandTheme.brown)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(selected ? BrandTheme.gold : BrandTheme.gold.opacity(0.25), lineWidth: selected ? 2 : 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .opacity(1)
                            .animation(.easeOut(duration: 0.35).delay(Double(i) * 0.05), value: state.selectedMood)
                        }
                    }
                    .padding(.horizontal, 20)

                    PrimaryButton(title: "Begin") {
                        state.beginSession()
                        state.phase = .processingFast
                    }
                    .disabled(state.selectedMood == nil)
                    .opacity(state.selectedMood == nil ? 0.45 : 1)
                    .padding(.horizontal, 24)

                    SecondaryButton(title: "Back") {
                        state.phase = state.capturedImage != nil ? .captureMoment : .entryMode
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 28)
            }
        }
    }
}

// MARK: - End session → Insight (simple + visual)

struct InsightView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(spacing: 24) {
                    FadeInTitle(text: "Your calm", delay: 0)
                    FadeInLine(text: "A quiet snapshot — not a dashboard.", delay: 0.1)

                    ZStack {
                        Circle()
                            .stroke(BrandTheme.gold.opacity(0.35), lineWidth: 14)
                            .frame(width: 160, height: 160)
                        Circle()
                            .trim(from: 0, to: state.calmScore)
                            .stroke(
                                AngularGradient(colors: [BrandTheme.goldSoft, BrandTheme.goldDeep], center: .center),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Text("\(Int(state.calmScore * 100))")
                                .font(BrandTheme.title(.largeTitle))
                                .foregroundStyle(BrandTheme.brown)
                            Text("calm")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(BrandTheme.brownMuted)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)

                    FadeInLine(
                        text: "Sound and space eased with your breath — real-time adaptation, gently.",
                        font: .subheadline,
                        delay: 0.22
                    )

                    if state.replayOfferOnInsight {
                        Button {
                            state.phase = .replayCalmSession
                        } label: {
                            BrandCard {
                                VStack(alignment: .center, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "play.circle.fill")
                                        Text("Replay your calm")
                                    }
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.brown)
                                    Text(
                                        state.replayExperienceAvailable
                                            ? "Same nature visuals and meditation audio as the session you just finished."
                                            : "Finish a session first — then you can replay it here."
                                    )
                                    .font(.caption)
                                    .foregroundStyle(BrandTheme.brownMuted)
                                    .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .opacity(state.replayExperienceAvailable ? 1 : 0.5)
                        }
                        .buttonStyle(.plain)
                        .disabled(!state.replayExperienceAvailable)
                        .padding(.horizontal, 20)
                    }

                    PrimaryButton(title: "Unlock deeper features") {
                        state.phase = .unlockFeatures
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 28)
            }
        }
    }
}

// MARK: - Deeper features (post-session)

struct UnlockFeaturesView: View {
    @ObservedObject var state: SessionPOCState
    @State private var openFeaturePanel: UnlockFeaturePanel?

    private let rows: [(ConnectedFeatureStock, String, String)] = [
        (.health, "Health sync", "Wearables and resting signals, when you choose."),
        (.iot, "IoT", "Light and space that follow your session."),
        (.personalisation, "Personalisation", "Taste and timing that learn with you."),
        (.snippetsMemory, "Snippets + memory layer", "Short highlights tied to how you felt."),
        (.replayCalm, "Replay your calm", "Return to a saved calm moment anytime."),
    ]

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(alignment: .center, spacing: 18) {
                    FadeInTitle(text: "Unlock Deeper Features", delay: 0)
                    FadeInLine(text: "Tap a feature to learn more — add when you’re ready.", delay: 0.08)

                    ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                        Button {
                            openFeaturePanel = UnlockFeaturePanel(stockId: row.0.id)
                        } label: {
                            BrandCard {
                                HStack(alignment: .top, spacing: 14) {
                                    ConnectedFeatureThumbnail(stock: row.0)
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text(row.1)
                                                .font(.headline)
                                                .foregroundStyle(BrandTheme.brown)
                                            Image(systemName: "chevron.right.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(BrandTheme.gold.opacity(0.85))
                                        }
                                        Text(row.2)
                                            .font(.caption)
                                            .foregroundStyle(BrandTheme.brownMuted)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .opacity(1)
                        .offset(y: 0)
                        .animation(.easeOut(duration: 0.45).delay(0.06 * Double(i)), value: state.phase)
                    }
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)

                    PrimaryButton(title: "Start another session") {
                        state.resetToHome()
                    }
                    if !state.isSignedIn {
                        SecondaryButton(title: "Sign in for sync") {
                            state.showSignInSheet = true
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(24)
            }
        }
        .sheet(item: $openFeaturePanel) { panel in
            UnlockFeatureDetailSheet(panel: panel)
        }
        .sheet(isPresented: $state.showSignInSheet) {
            OptionalSignInSheet(state: state)
        }
    }
}

