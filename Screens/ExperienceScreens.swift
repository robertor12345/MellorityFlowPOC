import SwiftUI

// MARK: - 4. AI processing

struct ProcessingView: View {
    @ObservedObject var state: SessionPOCState
    @State private var progress: CGFloat = 0
    @State private var tick = 0
    private let messages = [
        "Reading colour palette & light…",
        "Blending your preferences…",
        "Weaving spatial audio layers…",
        "Painting ethereal visuals…",
    ]

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ProgressView(value: progress, total: 1)
                .tint(BrandTheme.goldDeep)
                .padding(.horizontal, 40)
            Text(messages[tick % messages.count])
                .font(BrandTheme.title(.title3))
                .multilineTextAlignment(.center)
                .foregroundStyle(BrandTheme.brown)
                .padding(.horizontal)
            Text("Mock pipeline — image + prefs + biometrics → experience model.")
                .font(.caption)
                .foregroundStyle(BrandTheme.brownMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .task {
            progress = 0
            withAnimation(.easeInOut(duration: 2.4)) { progress = 1 }
            for i in 0..<4 {
                tick = i
                try? await Task.sleep(nanoseconds: 600_000_000)
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            state.phase = .immersive
        }
    }
}

// MARK: - 5. Immersive session

struct ImmersiveSessionView: View {
    @ObservedObject var state: SessionPOCState
    @StateObject private var ambientAudio = AmbientAudioSession()
    @State private var hrTimer: Timer?

    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    BrandTheme.etherealGradient
                        .ignoresSafeArea()
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.15 + 0.05 * sin(t + Double(i))),
                                        Color.clear,
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 120 + CGFloat(i * 20)
                                )
                            )
                            .frame(width: 200 + CGFloat(i * 30), height: 200 + CGFloat(i * 30))
                            .offset(
                                x: CGFloat(sin(t * 0.4 + Double(i)) * 40),
                                y: CGFloat(cos(t * 0.35 + Double(i)) * 50)
                            )
                            .blur(radius: 20)
                    }
                }
            }
            .ignoresSafeArea()

            LeafBreezeLayer()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        ambientAudio.isMuted.toggle()
                    } label: {
                        Image(systemName: ambientAudio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.body)
                            .foregroundStyle(BrandTheme.cream)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel(ambientAudio.isMuted ? "Unmute audio" : "Mute audio")

                    Spacer()
                    Button {
                        state.addSnippet()
                    } label: {
                        Label("Mark highlight", systemImage: "bookmark.fill")
                            .font(.caption.weight(.semibold))
                            .padding(10)
                            .background(BrandTheme.cream.opacity(0.85))
                            .foregroundStyle(BrandTheme.brown)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                Spacer()
                VStack(spacing: 16) {
                    Text("Immersive space")
                        .font(BrandTheme.title(.title2))
                        .foregroundStyle(BrandTheme.cream.opacity(0.95))
                        .shadow(radius: 4)
                    Text("Streaming ambient + high-frequency air · leaf motion · mock HR")
                        .font(.caption)
                        .foregroundStyle(BrandTheme.cream.opacity(0.85))
                        .multilineTextAlignment(.center)
                    HStack(spacing: 24) {
                        VStack {
                            Text("HR")
                                .font(.caption2)
                            Text("\(Int(state.mockHeartRateCurrent))")
                                .font(.title2.monospacedDigit())
                        }
                        .foregroundStyle(BrandTheme.cream)
                        VStack {
                            Text("Calm")
                                .font(.caption2)
                            Text("\(Int(state.calmScore * 100))%")
                                .font(.title2.monospacedDigit())
                        }
                        .foregroundStyle(BrandTheme.cream)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.bottom, 40)
            }

            VStack {
                Spacer()
                PrimaryButton(title: "End session") {
                    state.endSession()
                    state.phase = .snippets
                }
                .padding(24)
            }
        }
        .onAppear {
            ambientAudio.start()
            hrTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 1.0)) {
                    state.mockHeartRateCurrent = max(58, state.mockHeartRateCurrent - Double.random(in: 0.2 ... 0.8))
                }
            }
        }
        .onDisappear {
            hrTimer?.invalidate()
            hrTimer = nil
            ambientAudio.stop()
        }
    }
}

// MARK: - 6. Snippets

struct SnippetsView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Snippets & peaks")
                    .font(BrandTheme.title(.title))
                    .foregroundStyle(BrandTheme.brown)
                Text("Short A/V highlights and mood labels — save, replay, share in the full app.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.brownMuted)

                if state.snippets.isEmpty {
                    BrandCard {
                        Text("No highlights bookmarked — tap “Mark highlight” during a session.")
                            .foregroundStyle(BrandTheme.brownMuted)
                    }
                } else {
                    ForEach(state.snippets) { s in
                        BrandCard {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(s.title)
                                        .font(.headline)
                                        .foregroundStyle(BrandTheme.brown)
                                    Spacer()
                                    Text(s.timecode)
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(BrandTheme.goldDeep)
                                }
                                Text(s.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(BrandTheme.brownMuted)
                                HStack {
                                    Button("Save") {}
                                    Button("Replay") {}
                                    Button("Share") {}
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(BrandTheme.goldDeep)
                            }
                        }
                    }
                }

                PrimaryButton(title: "Continue") {
                    state.phase = .iotSync
                }
            }
            .padding(24)
        }
    }
}

// MARK: - 7. IoT

struct IoTSyncView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ambient space")
                    .font(BrandTheme.title(.title))
                    .foregroundStyle(BrandTheme.brown)
                Text("Sync lighting with your session mood — POC shows Hue-style presets only.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.brownMuted)

                BrandCard {
                    Toggle(isOn: $state.connectSmartHome) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Philips Hue bridge")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.brown)
                            Text("Warm dim for calm · soft pulses for breath cues")
                                .font(.caption)
                                .foregroundStyle(BrandTheme.brownMuted)
                        }
                    }
                    .tint(BrandTheme.gold)
                }

                Picker("Scene", selection: $state.hueScene) {
                    Text("Warm dim (relax)").tag("Warm dim (relax)")
                    Text("Soft pulse (breath)").tag("Soft pulse (breath)")
                    Text("Cool focus").tag("Cool focus")
                }
                .pickerStyle(.menu)
                .padding()
                .background(BrandTheme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                PrimaryButton(title: "Continue") {
                    state.phase = .summary
                }
            }
            .padding(24)
        }
    }
}

// MARK: - 8. Summary & feedback

struct SessionSummaryView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("How was that?")
                    .font(BrandTheme.title(.title))
                    .foregroundStyle(BrandTheme.brown)

                BrandCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood & body")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.brown)
                        row("Dominant palette (mock)", state.mockDominantPalette)
                        row("Heart rate start → end", "\(Int(state.mockHeartRateStart)) → \(Int(state.mockHeartRateCurrent)) bpm")
                        row("Calm index", "\(Int(state.calmScore * 100))%")
                    }
                }

                Text("Did this help you relax?")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.brown)
                HStack(spacing: 16) {
                    Button("Yes") { state.feedbackHelpful = true }
                        .buttonStyle(.borderedProminent)
                        .tint(BrandTheme.goldDeep)
                    Button("Not sure") { state.feedbackHelpful = nil }
                    Button("No") { state.feedbackHelpful = false }
                }
                .foregroundStyle(BrandTheme.brown)

                Text("Feedback trains the personalisation loop for your next session.")
                    .font(.caption)
                    .foregroundStyle(BrandTheme.brownMuted)

                PrimaryButton(title: "See what’s next") {
                    state.phase = .learning
                }
            }
            .padding(24)
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k)
                .font(.caption)
                .foregroundStyle(BrandTheme.brownMuted)
            Spacer()
            Text(v)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandTheme.brown)
        }
    }
}

// MARK: - 9. Learning loop

struct LearningLoopView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Continuous learning")
                    .font(BrandTheme.title(.title))
                    .foregroundStyle(BrandTheme.brown)
                BrandCard {
                    VStack(alignment: .leading, spacing: 10) {
                        bullet("Audio preferences refine after each session")
                        bullet("Visual styles drift toward what calms you faster")
                        bullet("Timing improves with your habits & biometrics")
                    }
                }
                Text("The full Mellority engine fuses this feedback with on-device and cloud models.")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.brownMuted)

                PrimaryButton(title: "Start another session") {
                    state.resetToCapture()
                }
                SecondaryButton(title: "Back to welcome") {
                    state.phase = .welcome
                }
            }
            .padding(24)
        }
    }

    private func bullet(_ t: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(BrandTheme.gold)
            Text(t)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.brownMuted)
        }
    }
}
