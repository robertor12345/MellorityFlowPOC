import SwiftUI
import AudioToolbox

private enum DiscoverySelectionFeedback {
    /// System “Peek” acknowledgement — audible over streamed clip when a mood face is tapped.
    static func playTapChime() {
        AudioServicesPlaySystemSound(SystemSoundID(1104))
    }
}
// MARK: - Discovery calibration (timed snippets + traffic-light smileys — no readable copy for participants)

struct DiscoveryCalibrationView: View {
    @ObservedObject var state: SessionPOCState
    @StateObject private var audio = AmbientAudioSession()
    @State private var sliceStartedAt = Date()
    @State private var sliceDeadlineTask: Task<Void, Never>?
    @State private var clipContentOpacity = 0.0
    /// Cancels superseded fade runs when snippets advance quickly (tap vs timer).
    @State private var clipFadeNonce: UInt = 0

    private let clipFadeOut: TimeInterval = 0.38
    private let clipFadeIn: TimeInterval = 0.46

    var body: some View {
        ScreenFadeIn {
            VStack(spacing: 0) {
                // Top chrome stays light; main content is centred as a vertical cluster.
                HStack {
                    Spacer(minLength: 16)
                    discoveryHeaderIntrinsic
                        .frame(maxWidth: 520)
                    Spacer(minLength: 16)
                }

                Spacer(minLength: 20)

                HStack(spacing: 0) {
                    Spacer(minLength: 16)
                    VStack(spacing: 22) {
                        progressSection
                        sentimentRow
                    }
                    .frame(maxWidth: 520)
                    .opacity(clipContentOpacity)
                    Spacer(minLength: 16)
                }

                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            audio.volumeMultiplier = 1.12
            clipFadeNonce = 0
            clipContentOpacity = 0
            Task { await runDiscoveryClipTransition(skipFadeOut: true) }
        }
        .onChange(of: state.discoverySnippetIndex) { _, _ in
            Task { await runDiscoveryClipTransition(skipFadeOut: false) }
        }
        .onChange(of: state.phase) { _, phase in
            if phase != .careDiscoveryCalibration {
                sliceDeadlineTask?.cancel()
                sliceDeadlineTask = nil
                audio.stop()
            }
        }
        .onDisappear {
            sliceDeadlineTask?.cancel()
            sliceDeadlineTask = nil
            audio.volumeMultiplier = 1
            audio.stop()
        }
    }

    /// Brand mark only — no exits during calibration so the clip flow isn’t interrupted.
    private var discoveryHeaderIntrinsic: some View {
        HStack {
            Spacer(minLength: 0)
            MellorityLogoImage(maxHeight: 32)
                .opacity(0.88)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var progressSection: some View {
        VStack(spacing: 0) {
            DiscoveryClipEtherealEqualizer(sliceAnchor: sliceStartedAt)
                .padding(.vertical, 12)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(BrandTheme.cream.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(BrandTheme.gold.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private var sentimentRow: some View {
        HStack(spacing: 16) {
            ForEach(DiscoveryTrafficSentiment.allCases) { mood in
                TrafficSmileyFaceButton(
                    sentiment: mood,
                    isSelected: state.discoveryPendingPick == mood
                ) {
                    advanceToNextDiscoveryClip(selected: mood)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    /// Locks in the tapped mood immediately and advances to the next clip (does not wait for 30s).
    private func advanceToNextDiscoveryClip(selected mood: DiscoveryTrafficSentiment) {
        guard state.phase == .careDiscoveryCalibration else { return }
        guard state.discoverySnippetIndex < DiscoveryFlowPOC.snippetCount else { return }
        sliceDeadlineTask?.cancel()
        sliceDeadlineTask = nil
        audio.stop()
        state.setDiscoveryPick(mood)
        state.commitDiscoverySnippetSlice()
    }

    /// Cross-fades the equalizer + mood row between clips (`skipFadeOut` for first paint).
    @MainActor
    private func runDiscoveryClipTransition(skipFadeOut: Bool) async {
        clipFadeNonce += 1
        let token = clipFadeNonce

        guard state.phase == .careDiscoveryCalibration else {
            clipContentOpacity = 1
            return
        }
        guard state.discoverySnippetIndex < DiscoveryFlowPOC.snippetCount else {
            clipContentOpacity = 1
            return
        }

        if !skipFadeOut {
            withAnimation(.easeOut(duration: clipFadeOut)) {
                clipContentOpacity = 0
            }
            let ns = UInt64((clipFadeOut * 1000 + 35) * 1_000_000)
            try? await Task.sleep(nanoseconds: ns)
            guard token == clipFadeNonce else { return }
            guard state.phase == .careDiscoveryCalibration else { return }
            guard state.discoverySnippetIndex < DiscoveryFlowPOC.snippetCount else {
                clipContentOpacity = 1
                return
            }
        }

        beginSlice(resetStartTime: true)

        guard token == clipFadeNonce else { return }
        withAnimation(.easeIn(duration: clipFadeIn)) {
            clipContentOpacity = 1
        }
    }

    private func beginSlice(resetStartTime: Bool) {
        sliceDeadlineTask?.cancel()
        sliceDeadlineTask = nil

        guard state.phase == .careDiscoveryCalibration else { return }
        guard state.discoverySnippetIndex < DiscoveryFlowPOC.snippetCount else { return }

        if resetStartTime {
            sliceStartedAt = Date()
        }

        let idxCapt = state.discoverySnippetIndex

        audio.stop()
        audio.startFresh(streamURL: DiscoveryFlowPOC.snippetAudioStreamURL(snippetIndex: idxCapt))

        sliceDeadlineTask = Task { @MainActor in
            let ns = UInt64(DiscoveryFlowPOC.snippetDurationSeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: ns)
            guard !Task.isCancelled else { return }
            guard state.phase == .careDiscoveryCalibration else { return }
            guard state.discoverySnippetIndex == idxCapt else { return }
            audio.stop()
            state.commitDiscoverySnippetSlice()
        }
    }
}

// MARK: - Ethereal equalizer (discovery clip progress)

private struct DiscoveryClipEtherealEqualizer: View {
    let sliceAnchor: Date
    private let barCount = 26
    /// Wider spacing reads better alongside the taller bar area on iPad.
    private let barSpacing: CGFloat = 6

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 45.0, paused: false)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(sliceAnchor)
            let frac = CGFloat(min(1, max(0, elapsed / DiscoveryFlowPOC.snippetDurationSeconds)))
            let t = timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { geo in
                let innerH = geo.size.height
                let usableH = innerH - 10
                let totalSpacing = CGFloat(barCount - 1) * barSpacing
                let barW = max(2, (geo.size.width - totalSpacing - 8) / CGFloat(barCount))

                ZStack {
                    RadialGradient(
                        colors: [
                            Color(red: 0.55, green: 0.60, blue: 0.84).opacity(0.22),
                            Color(red: 0.78, green: 0.70, blue: 0.90).opacity(0.10),
                            Color.clear,
                        ],
                        center: UnitPoint(x: 0.5, y: 0.94),
                        startRadius: 2,
                        endRadius: min(geo.size.width, usableH + 42) * 0.92
                    )
                    .allowsHitTesting(false)

                    LinearGradient(
                        colors: [
                            BrandTheme.gold.opacity(0.03),
                            Color.clear,
                            Color(red: 0.58, green: 0.55, blue: 0.74).opacity(0.06),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .allowsHitTesting(false)

                    HStack(alignment: .bottom, spacing: barSpacing) {
                        ForEach(0 ..< barCount, id: \.self) { i in
                            etherealBar(
                                index: i,
                                phase: t,
                                sliceProgress: frac,
                                width: barW,
                                maxHeight: usableH
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .frame(height: 228)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Listen progress")
            .accessibilityValue("\(Int((frac * 100).rounded())) percent through this clip")
        }
    }

    private func etherealBar(
        index i: Int,
        phase t: Double,
        sliceProgress frac: CGFloat,
        width barW: CGFloat,
        maxHeight maxH: CGFloat
    ) -> some View {
        let ωA = 1.95 + Double(i % 15) * 0.068
        let ωB = 0.74 + Double((i ^ 11) % 17) * 0.049
        let wa = sin(t * ωA + Double(i) * 0.93)
        let wb = cos(t * ωB + Double(i) * 1.11)
        let weave = CGFloat((wa + wb + 1.8) / 3.6)

        let breath = 0.86 + CGFloat(sin(t * 0.47 + Double(i) * 0.08)) * 0.13
        let openness = CGFloat(sqrt(Double(frac)))
        let level = openness * CGFloat(0.38 + weave * Double(0.34 + frac * 0.28))
            + (1 - openness) * (0.12 + weave * (0.32 + frac * 0.22))
        let amplified = max(0.15, min(1, level * breath))

        let h = max(5, amplified * maxH)
        let topGlow = BrandTheme.goldSoft.opacity(Double(0.42 + weave * Double(frac) * 0.42))
        let midGlow = Color(red: 0.52, green: 0.58, blue: 0.82).opacity(Double(0.22 + weave * Double(frac) * 0.35))
        let baseGlow = BrandTheme.goldDeep.opacity(Double(0.62 + frac * Double(weave * 0.28)))

        return Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [topGlow, midGlow, baseGlow],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: barW, height: h)
            .opacity(0.55 + frac * (weave * 0.28 + 0.2))
            .shadow(color: BrandTheme.gold.opacity(0.08 + weave * frac * 0.34), radius: 3 + weave * 9, y: 1)
    }
}

// MARK: - Traffic smiles (minimal)

private struct TrafficSmileyFaceButton: View {
    let sentiment: DiscoveryTrafficSentiment
    let isSelected: Bool
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressPopScale: CGFloat = 1
    @State private var glowBurst: CGFloat = 0

    var body: some View {
        Button {
            DiscoverySelectionFeedback.playTapChime()
            if reduceMotion {
                glowBurst = 0.85
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 220_000_000)
                    withAnimation(.easeOut(duration: 0.35)) { glowBurst = 0 }
                }
            } else {
                withAnimation(.spring(response: 0.29, dampingFraction: 0.52)) {
                    pressPopScale = 1.16
                    glowBurst = 1
                }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 115_000_000)
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.68)) {
                        pressPopScale = 1
                    }
                    try? await Task.sleep(nanoseconds: 340_000_000)
                    withAnimation(.easeOut(duration: 0.36)) {
                        glowBurst = 0
                    }
                }
            }
            action()
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(
                        sentiment.ringColor.opacity(0.62 * glowBurst + 0.08),
                        lineWidth: 3 + glowBurst * 18
                    )
                    .frame(width: 126, height: 126)
                    .blur(radius: glowBurst * 10)

                MinimalTrafficFace(sentiment: sentiment)
                    .frame(width: 96, height: 96)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(BrandTheme.cream.opacity(isSelected ? 0.92 : 0.45))
                            .overlay(
                                Circle().strokeBorder(
                                    sentiment.ringColor.opacity(isSelected ? 0.98 : (0.42 + glowBurst * 0.5)),
                                    lineWidth: isSelected ? 4 : (1.8 + glowBurst * 3)
                                )
                            )
                            .shadow(
                                color: sentiment.ringColor.opacity(0.12 + glowBurst * 0.55),
                                radius: (isSelected ? 12 : 4) + glowBurst * 28,
                                y: 3 + glowBurst * 8
                            )
                    )
            }
            .scaleEffect(pressPopScale)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sentiment.accessibilitySummary + " mood")
        .accessibilityHint("Ends this clip and goes to the next when selected.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private extension DiscoveryTrafficSentiment {
    /// Face disc border / emphasis (traffic colours).
    var ringColor: Color {
        switch self {
        case .unpleasant:
            Color(red: 0.92, green: 0.24, blue: 0.22)
        case .neutral:
            Color(red: 1.0, green: 0.72, blue: 0.16)
        case .pleasant:
            Color(red: 0.24, green: 0.72, blue: 0.38)
        }
    }

    /// Subtle pastel fill behind the glyphs.
    var faceBackdrop: Color {
        ringColor.opacity(0.12)
    }
}

private struct MinimalTrafficFace: View {
    let sentiment: DiscoveryTrafficSentiment

    var body: some View {
        ZStack {
            Circle()
                .fill(sentiment.faceBackdrop)

            MinimalFaceGlyph(sentiment: sentiment)
        }
    }
}

private struct MinimalFaceGlyph: View {
    let sentiment: DiscoveryTrafficSentiment

    private var mouthKind: DiscoveryMouthShape.MouthKind {
        switch sentiment {
        case .unpleasant: return .frown
        case .neutral: return .flat
        case .pleasant: return .smile
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let eyeR = w * 0.055

            ZStack {
                HStack(spacing: w * 0.28) {
                    Circle()
                        .strokeBorder(sentiment.ringColor, lineWidth: 2.6)
                        .frame(width: eyeR * 2, height: eyeR * 2)
                    Circle()
                        .strokeBorder(sentiment.ringColor, lineWidth: 2.6)
                        .frame(width: eyeR * 2, height: eyeR * 2)
                }
                .offset(y: -h * 0.12)

                DiscoveryMouthShape(kind: mouthKind)
                    .stroke(sentiment.ringColor, style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round))
                    .frame(width: w * 0.52, height: h * 0.38)
                    .offset(y: h * 0.18)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Simple minimalist mouth strokes for discovery traffic faces.
private struct DiscoveryMouthShape: Shape {
    enum MouthKind { case frown, flat, smile }

    var kind: MouthKind

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let midX = rect.midX
        switch kind {
        case .flat:
            let y = rect.midY * 1.06
            p.move(to: CGPoint(x: w * 0.12, y: y))
            p.addLine(to: CGPoint(x: w * 0.88, y: y))

        case .smile:
            let yAnchor = rect.minY + rect.height * 0.35
            p.move(to: CGPoint(x: w * 0.10, y: yAnchor))
            p.addQuadCurve(to: CGPoint(x: w * 0.90, y: yAnchor), control: CGPoint(x: midX, y: rect.maxY))

        case .frown:
            let yAnchor = rect.maxY - rect.height * 0.08
            p.move(to: CGPoint(x: w * 0.10, y: yAnchor))
            p.addQuadCurve(to: CGPoint(x: w * 0.90, y: yAnchor), control: CGPoint(x: midX, y: rect.minY))
        }
        return p
    }
}
