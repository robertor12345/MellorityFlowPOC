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
            VStack(spacing: 28) {
                Spacer()
                FadeInTitle(text: "Starting session", delay: 0)
                FadeInLine(
                    text: "Light feedback while we prepare — no clutter.",
                    font: .caption,
                    delay: 0.1
                )

                ProgressView(value: progress, total: 1)
                    .tint(BrandTheme.goldDeep)
                    .scaleEffect(x: 1, y: 1.2, anchor: .center)
                    .padding(.horizontal, 40)

                Text(messages[tick % messages.count])
                    .font(BrandTheme.title(.title3))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(BrandTheme.brown)
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.45), value: tick)
                    .id(tick)

                Spacer()
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
                VStack(spacing: 12) {
                    if showCopy {
                        Text("Immersive space")
                            .font(BrandTheme.title(.title2))
                            .foregroundStyle(BrandTheme.cream.opacity(0.95))
                            .shadow(radius: 4)
                            .transition(.opacity.combined(with: .offset(y: 8)))
                        Text("Real-time adaptation — the core magic")
                            .font(.caption)
                            .foregroundStyle(BrandTheme.cream.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                    Text("Streaming ambient · leaf motion · gentle HR (mock)")
                        .font(.caption2)
                        .foregroundStyle(BrandTheme.cream.opacity(0.75))
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
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
                        showCopy = true
                    }
                }
            }

            VStack {
                Spacer()
                PrimaryButton(title: "End session") {
                    state.endSession()
                    state.phase = .insight
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
