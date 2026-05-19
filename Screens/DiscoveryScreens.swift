import SwiftUI

// MARK: - Discovery calibration (timed snippets + traffic-light smileys — no readable copy for participants)

struct DiscoveryCalibrationView: View {
    @ObservedObject var state: SessionPOCState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var audio = AmbientAudioSession()
    @State private var sliceStartedAt = Date()
    @State private var sliceDeadlineTask: Task<Void, Never>?
    @State private var clipContentOpacity = 0.0
    /// Cancels superseded fade runs when snippets advance quickly (tap vs timer).
    @State private var clipFadeNonce: UInt = 0
    @State private var affirmationGlowTick: UInt = 0
    /// Bumps snippet after tap: 2s listen + affirmation glow (~0.4s) → commit.
    @State private var postPickAdvanceTask: Task<Void, Never>?
    @State private var discoveryExitOverlayActive = false
    @State private var discoveryCompletionExitTask: Task<Void, Never>?

    private let clipFadeOut: TimeInterval = 0.38
    private let clipFadeIn: TimeInterval = 0.46

    var body: some View {
        ZStack {
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

            if discoveryExitOverlayActive {
                DiscoveryMusicalExitTypographyOverlay()
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: discoveryExitOverlayActive)
        .onAppear {
            audio.volumeMultiplier = 1.12
            clipFadeNonce = 0
            clipContentOpacity = 0
            Task { await runDiscoveryClipTransition(skipFadeOut: true) }
        }
        .onChange(of: state.discoverySnippetIndex) { _, newIdx in
            if newIdx >= DiscoveryFlowPOC.snippetCount {
                scheduleDiscoveryCompletionExitSequence()
            } else {
                Task { await runDiscoveryClipTransition(skipFadeOut: false) }
            }
        }
        .onChange(of: state.phase) { _, phase in
            if phase != .careDiscoveryCalibration {
                cancelPostPickAdvance()
                discoveryCompletionExitTask?.cancel()
                discoveryCompletionExitTask = nil
                discoveryExitOverlayActive = false
                sliceDeadlineTask?.cancel()
                sliceDeadlineTask = nil
                audio.stop()
            }
        }
        .onDisappear {
            cancelPostPickAdvance()
            discoveryCompletionExitTask?.cancel()
            discoveryCompletionExitTask = nil
            discoveryExitOverlayActive = false
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
                    isSelected: state.discoveryPendingPick == mood,
                    pendingPick: state.discoveryPendingPick,
                    affirmationGlowTick: affirmationGlowTick
                ) {
                    advanceToNextDiscoveryClip(selected: mood)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    /// After tap: mood shows as selected immediately; streamed clip keeps playing ~2s, then affirmation glow fires, then snippet commits and cross-fades to the next clip.
    private func advanceToNextDiscoveryClip(selected mood: DiscoveryTrafficSentiment) {
        guard state.phase == .careDiscoveryCalibration else { return }
        guard state.discoverySnippetIndex < DiscoveryFlowPOC.snippetCount else { return }
        cancelPostPickAdvance()
        sliceDeadlineTask?.cancel()
        sliceDeadlineTask = nil
        state.setDiscoveryPick(mood)
        let moodCapt = mood
        let idxCapt = state.discoverySnippetIndex
        postPickAdvanceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            guard state.phase == .careDiscoveryCalibration else { return }
            guard state.discoverySnippetIndex == idxCapt else { return }
            guard state.discoveryPendingPick == moodCapt else { return }
            affirmationGlowTick += 1
            try? await Task.sleep(nanoseconds: 420_000_000)
            guard !Task.isCancelled else { return }
            guard state.phase == .careDiscoveryCalibration else { return }
            guard state.discoverySnippetIndex == idxCapt else { return }
            guard state.discoveryPendingPick == moodCapt else { return }
            state.commitDiscoverySnippetSlice()
        }
    }

    private func cancelPostPickAdvance() {
        postPickAdvanceTask?.cancel()
        postPickAdvanceTask = nil
    }

    /// Discovery is complete in `state` (tuning already applied). Fade out UI, show falling musical type, then open the resident playlist surface.
    private func scheduleDiscoveryCompletionExitSequence() {
        discoveryCompletionExitTask?.cancel()
        let prefersReducedMotion = reduceMotion
        discoveryCompletionExitTask = Task { @MainActor in
            guard state.phase == .careDiscoveryCalibration else { return }
            guard state.discoverySnippetIndex >= DiscoveryFlowPOC.snippetCount else { return }

            sliceDeadlineTask?.cancel()
            sliceDeadlineTask = nil
            cancelPostPickAdvance()
            audio.stop()

            let contentFade = prefersReducedMotion ? 0.32 : 0.44
            withAnimation(.easeOut(duration: contentFade)) {
                clipContentOpacity = 0
            }
            try? await Task.sleep(nanoseconds: UInt64((contentFade + 0.06) * 1_000_000_000.0))
            guard !Task.isCancelled else { return }
            guard state.phase == .careDiscoveryCalibration else { return }

            discoveryExitOverlayActive = true
            let overlayDwellNanoseconds =
                prefersReducedMotion ? UInt64(1_150_000_000) : UInt64(2_120_000_000)

            try? await Task.sleep(nanoseconds: overlayDwellNanoseconds)
            guard !Task.isCancelled else { return }
            guard state.phase == .careDiscoveryCalibration else { return }

            let outro = prefersReducedMotion ? 0.24 : 0.38
            withAnimation(.easeOut(duration: outro)) {
                discoveryExitOverlayActive = false
            }
            let scaledOutroNanos = outro * 940_000_000.0
            let clippedOutroNanos = max(240_000_000.0, min(900_000_000.0, scaledOutroNanos))
            let outroNanos = UInt64(clippedOutroNanos)
            try? await Task.sleep(nanoseconds: outroNanos)
            guard !Task.isCancelled else { return }
            guard state.phase == .careDiscoveryCalibration else { return }

            state.openResidentProfile()
        }
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

// MARK: - Discovery → resident typography exit

/// Falling Unicode musical glyphs — typography only, no lyric copy.
private struct DiscoveryMusicalExitTypographyOverlay: View {
    private struct Flake: Identifiable {
        let id: Int
        let text: String
        let lateral: CGFloat
        let fontSize: CGFloat
        let cascade: CGFloat
        let sway: CGFloat
        let spinSeed: CGFloat
        let pacing: CGFloat
    }

    private let flakes: [Flake]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        let marks = ["♪", "♫", "♬", "♩", "♭", "♯", "♮"]
        flakes = (0 ..< 44).map { i in
            var seed = UInt64(i * 1_973_917 + 52)

            func bump() -> UInt64 {
                seed = seed &* 6364136223846793005 &+ 1_442_695_040_888_963_407
                return seed
            }

            func unit() -> CGFloat {
                CGFloat(Double(bump() % 8192) / 8192.0)
            }

            let markIndex = Int(bump() % UInt64(max(1, marks.count)))

            return Flake(
                id: i,
                text: marks[markIndex],
                lateral: unit(),
                fontSize: unit() * 32 + 20,
                cascade: unit(),
                sway: unit() * CGFloat.pi * 2,
                spinSeed: unit() * CGFloat.pi * 2,
                pacing: 0.32 + unit() * 0.62
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 34.0, paused: false)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    LinearGradient(
                        colors: [
                            BrandTheme.cream.opacity(0),
                            BrandTheme.cream.opacity(0.76),
                            BrandTheme.goldSoft.opacity(0.26),
                            BrandTheme.creamDeep.opacity(0.92),
                            BrandTheme.brown.opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    Group {
                        if reduceMotion {
                            ForEach(flakes) { f in
                                let xNorm = CGFloat(0.04 + Double(f.lateral) * 0.92)
                                let bob =
                                    CGFloat(
                                        sin(
                                            t * (0.94 + Double(f.id % 11) * 0.038)
                                                + Double(f.spinSeed)
                                        ) * 8
                                    ) / max(h, 340)
                                let yNorm = CGFloat(0.06 + Double(f.cascade) * 0.88) + bob
                                Text(f.text)
                                    .font(.system(size: f.fontSize, weight: .light, design: .serif))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                BrandTheme.gold.opacity(0.68),
                                                BrandTheme.brown.opacity(0.45),
                                                BrandTheme.goldDeep.opacity(0.56),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .opacity(0.32 + Double(sin(t * 2.05 + Double(f.id))) * 0.12)
                                    .rotationEffect(
                                        .degrees(sin(t * 0.7 + Double(f.sway)) * (f.id.isMultiple(of: 2) ? -6 : 6))
                                    )
                                    .position(x: xNorm * w, y: yNorm * h)
                            }
                        } else {
                            let cycleDuration = 7.85
                            ForEach(flakes) { f in
                                let local = Double(f.cascade) + t * Double(f.pacing)
                                let u = CGFloat((local.truncatingRemainder(dividingBy: cycleDuration)) / cycleDuration)

                                /// Quick fade above the hull, fall through viewport, dissipate toward bottom edge.
                                let rise = min(1.0, Double(u * 11))
                                let tail = max(0.0, Double((u - 0.88) / 0.14))
                                let alpha = CGFloat(min(1.0, rise)) * CGFloat(max(0.05, 1 - tail * tail))

                                let x =
                                    CGFloat(0.04 + Double(f.lateral) * 0.92) * w
                                    + CGFloat(sin(t * 0.93 + Double(f.sway))) * CGFloat(26 + CGFloat(f.id % 17))
                                let extra = CGFloat(f.id % 5) * 4
                                let y = CGFloat(-extra) + CGFloat(h + 160 + Double(extra)) * u

                                let spin = CGFloat(sin(t * 1.06 + Double(f.spinSeed) + Double(f.id) * 0.71) * (15 + CGFloat(f.id % 9)))

                                Text(f.text)
                                    .font(.system(size: f.fontSize, weight: .light, design: .serif))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                BrandTheme.gold.opacity(0.92),
                                                BrandTheme.brown.opacity(0.5),
                                                BrandTheme.goldDeep.opacity(0.62),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .opacity(Double(alpha))
                                    .rotationEffect(.degrees(Double(spin)))
                                    .blur(radius: CGFloat(max(0.0, tail * 4.8)))
                                    .position(x: x, y: y)
                                    .shadow(color: BrandTheme.gold.opacity(0.18), radius: 3 + CGFloat(f.id % 5), y: 1)
                            }
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
                            Color(red: 0.55, green: 0.60, blue: 0.84).opacity(0.38),
                            Color(red: 0.78, green: 0.70, blue: 0.90).opacity(0.22),
                            Color(red: 0.85, green: 0.82, blue: 0.92).opacity(0.08),
                        ],
                        center: UnitPoint(x: 0.5, y: 0.94),
                        startRadius: 2,
                        endRadius: min(geo.size.width, usableH + 42) * 0.92
                    )
                    .allowsHitTesting(false)

                    LinearGradient(
                        colors: [
                            BrandTheme.gold.opacity(0.08),
                            Color.clear,
                            Color(red: 0.58, green: 0.55, blue: 0.74).opacity(0.14),
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
        let topGlow = BrandTheme.goldSoft.opacity(Double(0.72 + weave * Double(frac) * 0.22))
        let midGlow = Color(red: 0.52, green: 0.58, blue: 0.82).opacity(Double(0.48 + weave * Double(frac) * 0.28))
        let baseGlow = BrandTheme.goldDeep.opacity(Double(0.82 + frac * Double(weave * 0.16)))

        return Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [topGlow, midGlow, baseGlow],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: barW, height: h)
            .opacity(0.86 + frac * (weave * 0.13 + 0.1))
            .shadow(color: BrandTheme.gold.opacity(0.12 + weave * frac * 0.38), radius: 3 + weave * 11, y: 1)
    }
}

// MARK: - Traffic smiles (minimal)

private struct TrafficSmileyFaceButton: View {
    let sentiment: DiscoveryTrafficSentiment
    let isSelected: Bool
    let pendingPick: DiscoveryTrafficSentiment?
    let affirmationGlowTick: UInt
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressPopScale: CGFloat = 1
    @State private var glowBurst: CGFloat = 0

    var body: some View {
        Button {
            DiscoveryEtherealTapChime.playLight()
            if reduceMotion {
                pressPopScale = 1.06
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 180_000_000)
                    withAnimation(.easeOut(duration: 0.28)) { pressPopScale = 1 }
                }
            } else {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.68)) {
                    pressPopScale = 1.08
                }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 95_000_000)
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
                        pressPopScale = 1
                    }
                }
            }
            action()
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(
                        sentiment.ringColor.opacity(0.62 * glowBurst + 0.08),
                        lineWidth: 3 + glowBurst * 22
                    )
                    .frame(width: 126, height: 126)
                    .blur(radius: glowBurst * 12)

                MinimalTrafficFace(sentiment: sentiment)
                    .frame(width: 96, height: 96)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(BrandTheme.cream.opacity(isSelected ? 0.99 : 0.86))
                            .overlay(
                                Circle().strokeBorder(
                                    sentiment.ringColor.opacity(isSelected ? 1 : (0.58 + glowBurst * 0.42)),
                                    lineWidth: isSelected ? 4.2 : (2.1 + glowBurst * 3)
                                )
                            )
                            .shadow(
                                color: sentiment.ringColor.opacity(0.18 + glowBurst * 0.58),
                                radius: (isSelected ? 14 : 6) + glowBurst * 32,
                                y: 4 + glowBurst * 9
                            )
                    )
            }
            .scaleEffect(pressPopScale)
        }
        .buttonStyle(.plain)
        .onChange(of: affirmationGlowTick) { _, _ in
            guard pendingPick == sentiment else { return }
            playAffirmationGlow()
        }
        .accessibilityLabel(sentiment.accessibilitySummary + " mood")
        .accessibilityHint("Confirms mood. The next clip follows a short pause with a bright ring on your choice.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func playAffirmationGlow() {
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.55)) {
                glowBurst = 0.95
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 520_000_000)
                withAnimation(.easeOut(duration: 0.4)) { glowBurst = 0 }
            }
            return
        }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.48)) {
            glowBurst = 1
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 520_000_000)
            withAnimation(.easeOut(duration: 0.42)) {
                glowBurst = 0
            }
        }
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

    /// Pastel centre behind glyphs — bolder so discs read crisply against the sparkle field.
    var faceBackdrop: Color {
        ringColor.opacity(0.32)
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
