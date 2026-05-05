import SwiftUI

// MARK: - Fast load — brief interstitial (~1s), subtle AI lines

struct ProcessingFastView: View {
    @ObservedObject var state: SessionPOCState
    @State private var progress: CGFloat = 0
    @State private var tick = 0
    private let messages = [
        "Finding the right tone…",
        "Letting the sound soften…",
        "Letting movement match your breath…",
        "Almost there…",
    ]

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(spacing: 28) {
                    FadeInTitle(text: "Ease in slowly", delay: 0)
                    FadeInLine(
                        text: "Sound and motion stay gentle so nothing arrives too fast — stay with them.",
                        font: .caption,
                        delay: 0.1
                    )
                    if state.isCareStaffSession, let p = state.carePatient(id: state.activeCarePatientId) {
                        VStack(spacing: 6) {
                            Text("With \(p.displayName) — roughly \(state.carePlannedDurationMinutes) min if it helps (pause or stop anytime).")
                            if state.carePrepVRImmersiveRoute {
                                Text("Headset path noted — same calm when your gear is connected.")
                            }
                            if state.carePrepRoomDisplayMirroring {
                                Text("Room screen noted — we can stretch visuals to the wall or bedside when it’s hooked up.")
                            }
                            if state.iotPhilipsHueEnabled || state.iotHomeKitEnabled || state.iotMatterEnabled {
                                Text("Lights are linked — scenes can drift with this session when your bridge is live.")
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(BrandTheme.goldDeep)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    }

                    ProgressView(value: progress, total: 1)
                        .tint(BrandTheme.goldDeep)
                        .scaleEffect(x: 1, y: 1.2, anchor: .center)
                        .padding(.horizontal, max(0, 40 - BrandTheme.contentGutter))
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
            let totalSeconds: Double = 3.2 / 3
            withAnimation(.easeInOut(duration: totalSeconds)) { progress = 1 }
            let steps = messages.count
            let per = UInt64((totalSeconds / Double(steps)) * 1_000_000_000)
            for i in 0..<steps {
                tick = i
                try? await Task.sleep(nanoseconds: per)
            }
            tick = steps - 1
            try? await Task.sleep(nanoseconds: UInt64(Double(200_000_000) / 3))
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
                }
                .padding(.horizontal, BrandTheme.contentGutter)
                .padding(.vertical, 12)

                if state.isCareStaffSession, let patient = state.carePatient(id: state.activeCarePatientId) {
                    VStack(spacing: 4) {
                        Text("Together · \(patient.displayName)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BrandTheme.brown)
                        Text("About \(state.carePlannedDurationMinutes) min if it helps — follow their pace")
                            .font(.caption2)
                            .foregroundStyle(BrandTheme.brownMuted)
                        if state.carePrepVRImmersiveRoute || state.carePrepRoomDisplayMirroring {
                            Text(
                                [
                                    state.carePrepVRImmersiveRoute ? "VR / immersive" : nil,
                                    state.carePrepRoomDisplayMirroring ? "Room display" : nil,
                                ]
                                .compactMap(\.self)
                                .joined(separator: " · ")
                            )
                                .font(.caption2)
                                .foregroundStyle(BrandTheme.goldDeep.opacity(0.95))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(BrandTheme.cream.opacity(0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(BrandTheme.gold.opacity(0.35), lineWidth: 1)
                    )
                    .padding(.horizontal, BrandTheme.contentGutter)
                }

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    if showCopy {
                        Text("You’re here")
                            .font(BrandTheme.title(.title2))
                            .foregroundStyle(BrandTheme.brown)
                            .transition(.opacity.combined(with: .offset(y: 8)))
                        Text("Everything shifts gently as you go.")
                            .font(.caption)
                            .foregroundStyle(BrandTheme.brownMuted)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                    Text("Music · nature video · heart rate")
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
                .padding(.horizontal, BrandTheme.contentGutter)

                SessionBottomConfigMenu(state: state)
                    .padding(.horizontal, BrandTheme.contentGutter)
                    .padding(.top, 10)

                PrimaryButton(title: "End session") {
                    state.endSession()
                    state.phase = .insight
                }
                .padding(.horizontal, BrandTheme.contentGutter)
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
