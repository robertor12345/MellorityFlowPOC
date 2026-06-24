import SwiftUI

// MARK: - Discovery calibration (timed snippets + traffic-light smileys — no readable copy for participants)

struct DiscoveryCalibrationView: View {
    @ObservedObject var state: SessionPOCState
    @Environment(\.flowContainerSize) private var flowContainerSize
    @Environment(\.flowOrbShellSize) private var flowOrbShellSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var audio = AmbientAudioSession()
    @State private var sliceStartedAt = Date()
    @State private var sliceDeadlineTask: Task<Void, Never>?
    @State private var clipContentOpacity = 0.0
    /// Cancels superseded fade runs when snippets advance quickly (tap vs timer).
    @State private var clipFadeNonce: UInt = 0
    @State private var affirmationGlowTick: UInt = 0
    /// Bumps snippet after tap: 2s listen + affirmation glow (~0.4s) → commit.
    @State private var postPickAdvanceTask: Task<Void, Never>?
    @State private var discoveryCompletionExitTask: Task<Void, Never>?

    private let clipFadeOut: TimeInterval = 0.20
    private let clipFadeIn: TimeInterval = 0.24

    private var orbSize: CGSize {
        if flowOrbShellSize.width > 1, flowOrbShellSize.height > 1 {
            return flowOrbShellSize
        }
        return BrandLayout.discoveryPanelSize(in: flowContainerSize)
    }

    private var orbDiameter: CGFloat {
        min(orbSize.width, orbSize.height)
    }

    var body: some View {
        ZStack {
            ScreenFadeIn {
                ZStack {
                    DiscoveryEraListeningOrb(
                        snippetIndex: state.discoverySnippetIndex,
                        sliceAnchor: sliceStartedAt,
                        orbSize: orbSize,
                        pendingPick: state.discoveryPendingPick,
                        affirmationGlowTick: affirmationGlowTick,
                        onSelectMood: { mood in
                            advanceToNextDiscoveryClip(selected: mood)
                        }
                    )
                    .opacity(clipContentOpacity)
                    .frame(width: orbDiameter, height: orbDiameter)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack {
                FlowTopBackBar(
                    accessibilityLabel: "Back to profile",
                    action: { state.abandonDiscoveryCalibration() }
                )
                Spacer(minLength: 0)
            }
            .safeAreaPadding(.top, 4)
            .zIndex(20)
        }
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
                sliceDeadlineTask?.cancel()
                sliceDeadlineTask = nil
                audio.stop()
            }
        }
        .onDisappear {
            cancelPostPickAdvance()
            discoveryCompletionExitTask?.cancel()
            discoveryCompletionExitTask = nil
            sliceDeadlineTask?.cancel()
            sliceDeadlineTask = nil
            audio.volumeMultiplier = 1
            audio.stop()
        }
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
            try? await Task.sleep(nanoseconds: 520_000_000)
            guard !Task.isCancelled else { return }
            guard state.phase == .careDiscoveryCalibration else { return }
            guard state.discoverySnippetIndex == idxCapt else { return }
            guard state.discoveryPendingPick == moodCapt else { return }
            affirmationGlowTick += 1
            try? await Task.sleep(nanoseconds: 140_000_000)
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

    /// Discovery is complete in `state` (tuning already applied). Fade out, then open the resident playlist surface.
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

            let contentFade = prefersReducedMotion ? 0.20 : 0.26
            withAnimation(.easeOut(duration: contentFade)) {
                clipContentOpacity = 0
            }
            try? await Task.sleep(nanoseconds: UInt64((contentFade + 0.04) * 1_000_000_000.0))
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

// MARK: - Era listening panel (archival media + equalizer inside circular orb)

private struct DiscoveryEraListeningOrb: View {
    let snippetIndex: Int
    let sliceAnchor: Date
    let orbSize: CGSize
    let pendingPick: DiscoveryTrafficSentiment?
    let affirmationGlowTick: UInt
    var onSelectMood: (DiscoveryTrafficSentiment) -> Void

    @StateObject private var videoLooper = DiscoverySnippetVideoLooper()
    @State private var eraMediaReady = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.flowOrbPulseAnchor) private var flowOrbPulseAnchor
    @Environment(\.flowPanelPulseIntensity) private var flowPanelPulseIntensity
    @Environment(\.flowPanelPulseSpeed) private var flowPanelPulseSpeed
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var pulseAnchor: Date {
        flowOrbPulseAnchor == .distantPast ? Date() : flowOrbPulseAnchor
    }

    private var visual: DiscoverySnippetEraVisual {
        DiscoveryEraMediaCatalog.visual(for: snippetIndex)
    }

    private var faceDiameter: CGFloat {
        min(min(orbSize.width, orbSize.height) * 0.22, BrandLayout.discoveryFaceDiameterCap(for: horizontalSizeClass))
    }

    var body: some View {
        let diameter = min(orbSize.width, orbSize.height)
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(pulseAnchor) * flowPanelPulseSpeed
            let sample = OrbPulseSample.sample(
                at: elapsed,
                mode: .calm,
                reduceMotion: reduceMotion
            )
            let contentScale = sample.shellScale

            ZStack {
                ZStack {
                    DiscoverySnippetMediaFill(
                        visual: visual,
                        player: videoLooper.player,
                        isMediaReady: $eraMediaReady
                    )
                        .frame(width: diameter, height: diameter)

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.20),
                            Color.black.opacity(0.06),
                            Color.black.opacity(0.28),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .opacity(eraMediaReady ? 1 : 0)
                    .allowsHitTesting(false)

                    VStack(spacing: 0) {
                        DiscoveryClipEtherealEqualizer(sliceAnchor: sliceAnchor, stylesOverMedia: true)
                            .frame(height: diameter * 0.34)
                            .padding(.horizontal, diameter * 0.05)
                            .padding(.top, diameter * 0.08)

                        Spacer(minLength: diameter * 0.02)

                        HStack(spacing: max(6, diameter * 0.015)) {
                            ForEach(DiscoveryTrafficSentiment.allCases) { mood in
                                TrafficSmileyFaceButton(
                                    sentiment: mood,
                                    pendingPick: pendingPick,
                                    affirmationGlowTick: affirmationGlowTick,
                                    diameter: max(72, faceDiameter)
                                ) {
                                    onSelectMood(mood)
                                }
                            }
                        }
                        .padding(.horizontal, diameter * 0.04)
                        .padding(.bottom, diameter * 0.07)
                    }
                }
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())
            }
            .scaleEffect(contentScale)
            .frame(width: diameter, height: diameter)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Listening clip from \(visual.eraYear)")
        .accessibilityValue(visual.eraEvent)
        .onAppear {
            restartEraVideo()
        }
        .onChange(of: snippetIndex) { _, _ in
            eraMediaReady = false
            restartEraVideo()
        }
        .onDisappear {
            videoLooper.stop()
        }
    }

    private func restartEraVideo() {
        guard snippetIndex < DiscoveryFlowPOC.snippetCount else {
            videoLooper.stop()
            return
        }
        let urls = visual.videoURLs
        guard urls.isEmpty == false else {
            videoLooper.stop()
            return
        }
        videoLooper.play(urls: urls)
    }
}

// MARK: - Ethereal equalizer (discovery clip progress)

private struct DiscoveryClipEtherealEqualizer: View {
    let sliceAnchor: Date
    var stylesOverMedia: Bool = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let barCount = 26

    private var barSpacing: CGFloat {
        BrandLayout.scaled(6, regular: 8, horizontalSizeClass: horizontalSizeClass)
    }

    private var equalizerHeight: CGFloat {
        BrandLayout.scaled(228, regular: 272, horizontalSizeClass: horizontalSizeClass)
    }

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
                    if !stylesOverMedia {
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
                    }

                    HStack(alignment: .bottom, spacing: barSpacing) {
                        ForEach(0 ..< barCount, id: \.self) { i in
                            etherealBar(
                                index: i,
                                phase: t,
                                sliceProgress: frac,
                                width: barW,
                                maxHeight: usableH,
                                overMedia: stylesOverMedia
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .clipShape(
                    stylesOverMedia
                        ? AnyShape(Rectangle())
                        : AnyShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
            }
            .frame(height: stylesOverMedia ? nil : equalizerHeight)
            .frame(maxHeight: stylesOverMedia ? .infinity : equalizerHeight)
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
        maxHeight maxH: CGFloat,
        overMedia: Bool = false
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
        let topGlow = overMedia
            ? BrandTheme.nebulaCyan.opacity(Double(0.82 + weave * Double(frac) * 0.14))
            : BrandTheme.goldSoft.opacity(Double(0.72 + weave * Double(frac) * 0.22))
        let midGlow = overMedia
            ? BrandTheme.nebulaLavender.opacity(Double(0.62 + weave * Double(frac) * 0.22))
            : Color(red: 0.52, green: 0.58, blue: 0.82).opacity(Double(0.48 + weave * Double(frac) * 0.28))
        let baseGlow = overMedia
            ? BrandTheme.goldSoft.opacity(Double(0.88 + frac * Double(weave * 0.12)))
            : BrandTheme.goldDeep.opacity(Double(0.82 + frac * Double(weave * 0.16)))

        return Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [topGlow, midGlow, baseGlow],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: barW, height: h)
            .opacity(overMedia ? (0.92 + frac * (weave * 0.08 + 0.06)) : (0.86 + frac * (weave * 0.13 + 0.1)))
            .shadow(
                color: (overMedia ? Color.black : BrandTheme.gold).opacity(overMedia ? 0.28 : (0.12 + weave * frac * 0.38)),
                radius: overMedia ? 2 + weave * 6 : 3 + weave * 11,
                y: 1
            )
    }
}

/// Type-erased shape helper for conditional clip shapes.
private struct AnyShape: Shape {
    private let builder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        builder = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        builder(rect)
    }
}

// MARK: - Traffic smiles (minimal)

private struct TrafficSmileyFaceButton: View {
    let sentiment: DiscoveryTrafficSentiment
    let pendingPick: DiscoveryTrafficSentiment?
    let affirmationGlowTick: UInt
    var diameter: CGFloat = 96
    var action: () -> Void

    private var faceSize: CGFloat { diameter * 0.76 }
    private var ringSize: CGFloat { diameter * 0.94 }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressPopScale: CGFloat = 1
    @State private var glowBurst: CGFloat = 0

    /// Transient press / affirmation bloom only — never a persistent selected look.
    private var luminousLevel: CGFloat {
        glowBurst > 0.01 ? glowBurst : 0.42
    }

    var body: some View {
        Button {
            CalmExperienceFeedback.discoveryPick()
            action()
            triggerInstantPressFlash()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                sentiment.ringColor.opacity(0.38 * luminousLevel + 0.12),
                                BrandTheme.logoCyan.opacity(0.22 * luminousLevel),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: ringSize * 0.72
                        )
                    )
                    .frame(width: ringSize * (1.08 + luminousLevel * 0.18), height: ringSize * (1.08 + luminousLevel * 0.18))
                    .blur(radius: 6 + luminousLevel * 16)

                Circle()
                    .strokeBorder(
                        sentiment.ringColor.opacity(0.35 + luminousLevel * 0.55),
                        lineWidth: 2.5 + luminousLevel * 24
                    )
                    .frame(width: ringSize * (1.02 + luminousLevel * 0.1), height: ringSize * (1.02 + luminousLevel * 0.1))
                    .blur(radius: luminousLevel * 14)

                MinimalTrafficFace(sentiment: sentiment)
                    .frame(width: faceSize, height: faceSize)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        .white.opacity(0.18 + luminousLevel * 0.12),
                                        sentiment.ringColor.opacity(0.58),
                                        sentiment.ringColor.opacity(0.82),
                                    ],
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: faceSize * 0.58
                                )
                            )
                            .overlay(
                                Circle().strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.88 + luminousLevel * 0.12),
                                            sentiment.ringColor.opacity(0.72 + luminousLevel * 0.28),
                                            BrandTheme.logoCyan.opacity(0.45 + luminousLevel * 0.35),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.4 + luminousLevel * 2.2
                                )
                            )
                            .shadow(color: sentiment.ringColor.opacity(0.28 + luminousLevel * 0.62), radius: 8 + luminousLevel * 36)
                            .shadow(color: BrandTheme.logoCyan.opacity(0.22 + luminousLevel * 0.48), radius: 6 + luminousLevel * 28)
                            .shadow(color: .white.opacity(luminousLevel * 0.35), radius: 4 + luminousLevel * 12)
                    )
            }
            .frame(width: diameter, height: diameter)
            .scaleEffect(pressPopScale)
        }
        .buttonStyle(.plain)
        .onChange(of: affirmationGlowTick) { _, _ in
            guard pendingPick == sentiment else { return }
            playAffirmationGlow()
        }
        .accessibilityLabel(sentiment.accessibilitySummary + " mood")
        .accessibilityHint("Confirms mood. The next clip follows a short pause with a bright ring on your choice.")
    }

    private func triggerInstantPressFlash() {
        glowBurst = 1.32
        pressPopScale = 1.12
        if reduceMotion {
            pressPopScale = 1.05
            glowBurst = 1.08
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 120_000_000)
                glowBurst = 0
                pressPopScale = 1
            }
            return
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 55_000_000)
            withAnimation(.easeOut(duration: 0.10)) {
                glowBurst = 0
                pressPopScale = 1.03
            }
            try? await Task.sleep(nanoseconds: 65_000_000)
            withAnimation(.spring(response: 0.18, dampingFraction: 0.82)) {
                pressPopScale = 1
            }
        }
    }

    private func playAffirmationGlow() {
        glowBurst = 1.35
        if reduceMotion {
            withAnimation(.linear(duration: 0.08)) { glowBurst = 1.1 }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 120_000_000)
                withAnimation(.easeOut(duration: 0.18)) { glowBurst = 0 }
            }
            return
        }
        withAnimation(.linear(duration: 0.06)) { glowBurst = 1.35 }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 120_000_000)
            withAnimation(.easeOut(duration: 0.16)) {
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

    /// Saturated traffic-light disc behind white face glyphs.
    var faceBackdrop: Color {
        ringColor.opacity(0.72)
    }
}

private struct MinimalTrafficFace: View {
    let sentiment: DiscoveryTrafficSentiment

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            sentiment.ringColor.opacity(0.88),
                            sentiment.ringColor.opacity(0.68),
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 80
                    )
                )

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
            let eyeR = w * 0.062

            ZStack {
                HStack(spacing: w * 0.28) {
                    Circle()
                        .fill(Color.white)
                        .overlay(
                            Circle()
                                .strokeBorder(sentiment.ringColor.opacity(0.55), lineWidth: 1.4)
                        )
                        .frame(width: eyeR * 2, height: eyeR * 2)
                        .shadow(color: .black.opacity(0.22), radius: 1, y: 0.5)
                    Circle()
                        .fill(Color.white)
                        .overlay(
                            Circle()
                                .strokeBorder(sentiment.ringColor.opacity(0.55), lineWidth: 1.4)
                        )
                        .frame(width: eyeR * 2, height: eyeR * 2)
                        .shadow(color: .black.opacity(0.22), radius: 1, y: 0.5)
                }
                .offset(y: -h * 0.12)

                DiscoveryMouthShape(kind: mouthKind)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 3.8, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: sentiment.ringColor.opacity(0.65), radius: 2, y: 1)
                    .shadow(color: .black.opacity(0.28), radius: 1.5, y: 0.5)
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
