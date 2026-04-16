import SwiftUI

// MARK: - Home — Start Session (no login)

struct HomeView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScreenFadeIn {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
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
                                if !state.isSignedIn {
                                    SecondaryButton(title: "Sign in (optional)") {
                                        state.showSignInSheet = true
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer(minLength: 0)
                    }
                    .frame(minWidth: geo.size.width, minHeight: geo.size.height)
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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $state.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $state.password)
                } header: {
                    Text("Optional account")
                } footer: {
                    Text("This POC stores nothing real — sign-in unlocks future sync in the full app.")
                }
            }
            .navigationTitle("Sign in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        state.isSignedIn = true
                        state.showSignInSheet = false
                        state.phase = .postSignInFeatureSlides
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Entry mode — Camera vs Quick Start

struct EntryModeView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScreenFadeIn {
            ScrollView {
                VStack(spacing: 22) {
                    FadeInTitle(text: "Choose Entry Mode", delay: 0)
                    FadeInLine(text: "Camera or Quick Start, then mood.", delay: 0.12)

                    VStack(spacing: 14) {
                        entryCard(
                            title: "Camera",
                            subtitle: "One photo to colour the experience.",
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
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(BrandTheme.goldDeep)
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: 6) {
                        FadeInLine(text: title, font: BrandTheme.title(.title3), color: BrandTheme.brown, delay: delay)
                        FadeInLine(text: subtitle, font: .caption, delay: delay + 0.06)
                    }
                    Spacer(minLength: 0)
                }
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
            ScrollView {
                VStack(spacing: 22) {
                    FadeInTitle(text: "How do you feel?", delay: 0)
                    FadeInLine(text: "We’ll adapt sound and motion to this — in seconds.", delay: 0.1)

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
            ScrollView {
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

                    if let mood = state.selectedMood {
                        FadeInLine(text: mood, font: BrandTheme.title(.title2), color: BrandTheme.brown, delay: 0.15)
                    }
                    FadeInLine(
                        text: "Sound and space eased with your breath — real-time adaptation, gently.",
                        font: .subheadline,
                        delay: 0.22
                    )

                    BrandCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Replay your calm", systemImage: "play.circle.fill")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.brown)
                            Text("Snippets and memory layer in the full app — revisit this tone anytime.")
                                .font(.caption)
                                .foregroundStyle(BrandTheme.brownMuted)
                        }
                    }
                    .padding(.horizontal, 20)

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

    private let rows: [(ConnectedFeatureStock, String, String)] = [
        (.health, "Health sync", "Wearables and resting signals, when you choose."),
        (.iot, "IoT", "Light and space that follow your session."),
        (.personalisation, "Personalisation", "Taste and timing that learn with you."),
        (.snippetsMemory, "Snippets + memory layer", "Short highlights tied to how you felt."),
        (.replayCalm, "Replay your calm", "Return to a saved calm moment — full product."),
    ]

    var body: some View {
        ScreenFadeIn {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FadeInTitle(text: "Unlock Deeper Features", delay: 0)
                    FadeInLine(text: "Optional — add when you’re ready.", delay: 0.08)

                    ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                        BrandCard {
                            HStack(alignment: .top, spacing: 14) {
                                ConnectedFeatureThumbnail(stock: row.0)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(row.1)
                                        .font(.headline)
                                        .foregroundStyle(BrandTheme.brown)
                                    Text(row.2)
                                        .font(.caption)
                                        .foregroundStyle(BrandTheme.brownMuted)
                                }
                            }
                        }
                        .opacity(1)
                        .offset(y: 0)
                        .animation(.easeOut(duration: 0.45).delay(0.06 * Double(i)), value: state.phase)
                    }
                    .padding(.horizontal, 4)

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
        .sheet(isPresented: $state.showSignInSheet) {
            OptionalSignInSheet(state: state)
        }
    }
}

