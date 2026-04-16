import SwiftUI

// MARK: - Fast load — under 5s, subtle AI lines

struct ProcessingFastView: View {
    @ObservedObject var state: SessionPOCState
    @State private var progress: CGFloat = 0
    @State private var tick = 0
    private let messages = [
        "Tuning to your mood…",
        "Softening the sound field…",
        "Balancing motion with breath…",
        "Almost there…",
    ]

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(spacing: 28) {
                    FadeInTitle(text: "Starting session", delay: 0)
                    FadeInLine(
                        text: "Subtle AI feedback while we prepare — quick, not busy.",
                        font: .caption,
                        delay: 0.1
                    )

                    ProgressView(value: progress, total: 1)
                        .tint(BrandTheme.goldDeep)
                        .scaleEffect(x: 1, y: 1.2, anchor: .center)
                        .padding(.horizontal, 40)
                        .frame(maxWidth: .infinity)

                    Text(messages[tick % messages.count])
                        .font(BrandTheme.title(.title3))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(BrandTheme.brown)
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.45), value: tick)
                        .id(tick)
                }
                .padding(.vertical, 28)
            }
        }
        .task {
            progress = 0
            let totalSeconds: Double = 3.2
            withAnimation(.easeInOut(duration: totalSeconds)) { progress = 1 }
            let steps = messages.count
            let per = UInt64((totalSeconds / Double(steps)) * 1_000_000_000)
            for i in 0..<steps {
                tick = i
                try? await Task.sleep(nanoseconds: per)
            }
            tick = steps - 1
            try? await Task.sleep(nanoseconds: 200_000_000)
            state.phase = .immersive
        }
    }
}

// MARK: - Immersive — real-time adaptation

struct ImmersiveSessionView: View {
    @ObservedObject var state: SessionPOCState
    @StateObject private var ambientAudio = AmbientAudioSession()
    @State private var hrTimer: Timer?
    @State private var showCopy = false

    var body: some View {
        ZStack {
            NatureVideoCompilationView(
                mediaSessionID: state.immersiveMediaSessionID,
                photoAnchored: state.sessionAnchoredWithPhoto
            )

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.14), location: 0),
                    .init(color: .clear, location: 0.38),
                    .init(color: .clear, location: 0.62),
                    .init(color: .black.opacity(0.22), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()

            VStack(spacing: 0) {
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

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    if showCopy {
                        Text("Immersive space")
                            .font(BrandTheme.title(.title2))
                            .foregroundStyle(BrandTheme.brown)
                            .transition(.opacity.combined(with: .offset(y: 8)))
                        Text("Real-time adaptation — the core magic")
                            .font(.caption)
                            .foregroundStyle(BrandTheme.brownMuted)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                    Text("Meditation audio · nature video · heart rate")
                        .font(.caption2)
                        .foregroundStyle(BrandTheme.brownMuted)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("HR")
                                .font(.caption2)
                                .foregroundStyle(BrandTheme.brownMuted)
                            Text("\(Int(state.mockHeartRateCurrent))")
                                .font(.title2.monospacedDigit())
                                .foregroundStyle(BrandTheme.brown)
                        }
                        VStack(spacing: 4) {
                            Text("Calm")
                                .font(.caption2)
                                .foregroundStyle(BrandTheme.brownMuted)
                            Text("\(Int(state.calmScore * 100))%")
                                .font(.title2.monospacedDigit())
                                .foregroundStyle(BrandTheme.brown)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(BrandTheme.cream.opacity(0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(BrandTheme.gold.opacity(0.28), lineWidth: 1)
                    )
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

                SessionBottomConfigMenu(state: state)
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                PrimaryButton(title: "End session") {
                    state.endSession()
                    state.phase = .insight
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)
                .safeAreaPadding(.bottom, 16)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
                    showCopy = true
                }
            }
        }
        .onAppear {
            ambientAudio.volumeMultiplier = 1
            // Distinct Mixkit reel + ambient stream when session is photo-anchored vs Quick Start.
            ambientAudio.startFresh(photoAnchored: state.sessionAnchoredWithPhoto)
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

// MARK: - Replay last session (same video + ambient audio pipeline)

struct ReplayCalmSessionView: View {
    @ObservedObject var state: SessionPOCState
    @StateObject private var ambientAudio = AmbientAudioSession()

    var body: some View {
        ZStack {
            NatureVideoCompilationView(
                mediaSessionID: state.replaySnapshotMediaID ?? state.immersiveMediaSessionID,
                photoAnchored: state.replaySessionPhotoAnchored
            )

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.18), location: 0),
                    .init(color: .clear, location: 0.38),
                    .init(color: .clear, location: 0.62),
                    .init(color: .black.opacity(0.26), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()

            VStack(spacing: 0) {
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
                }
                .padding()

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    Text("Replay your calm")
                        .font(BrandTheme.title(.title2))
                        .foregroundStyle(BrandTheme.cream)
                        .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                    if let mood = state.replayMoodSnapshot {
                        Text(mood)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.cream.opacity(0.95))
                            .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                    }
                    Text("Same nature visuals and meditation audio as your session.")
                        .font(.caption)
                        .foregroundStyle(BrandTheme.cream.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.25), radius: 3, y: 1)

                    if state.replayShowMetricsOverlay {
                        HStack(spacing: 24) {
                            VStack(spacing: 4) {
                                Text("HR")
                                    .font(.caption2)
                                    .foregroundStyle(BrandTheme.brownMuted)
                                Text("\(state.replayHeartRateSnapshot)")
                                    .font(.title2.monospacedDigit())
                                    .foregroundStyle(BrandTheme.brown)
                            }
                            VStack(spacing: 4) {
                                Text("Calm")
                                    .font(.caption2)
                                    .foregroundStyle(BrandTheme.brownMuted)
                                Text("\(state.replayCalmPercentSnapshot)%")
                                    .font(.title2.monospacedDigit())
                                    .foregroundStyle(BrandTheme.brown)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(BrandTheme.cream.opacity(0.92))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(BrandTheme.gold.opacity(0.28), lineWidth: 1)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)

                SessionBottomConfigMenu(state: state)
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                PrimaryButton(title: "End replay") {
                    ambientAudio.stop()
                    state.phase = .insight
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)
                .safeAreaPadding(.bottom, 16)
            }
        }
        .onAppear {
            if !state.replayExperienceAvailable {
                state.phase = .insight
                return
            }
            ambientAudio.volumeMultiplier = state.replayRestoreVolume ? 1 : 0.72
            ambientAudio.startFresh(photoAnchored: state.replaySessionPhotoAnchored)
        }
        .onDisappear {
            ambientAudio.stop()
        }
    }
}
