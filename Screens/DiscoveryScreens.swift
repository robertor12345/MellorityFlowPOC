import SwiftUI

// MARK: - Discovery calibration (timed snippets + traffic-light smileys — no readable copy for participants)

struct DiscoveryCalibrationView: View {
    @ObservedObject var state: SessionPOCState
    @StateObject private var audio = AmbientAudioSession()
    @State private var sliceStartedAt = Date()
    @State private var sliceDeadlineTask: Task<Void, Never>?

    var body: some View {
        ScreenFadeIn {
            VStack(spacing: 0) {
                discoveryHeader

                ScrollView {
                    VStack(spacing: 22) {
                        progressSection
                        sentimentRow
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                    .padding(.top, 12)
                }
            }
        }
        .onAppear {
            audio.volumeMultiplier = 1.12
            beginSlice(resetStartTime: true)
        }
        .onChange(of: state.discoverySnippetIndex) { _, _ in
            beginSlice(resetStartTime: true)
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

    /// Staff exit only — icon-only; instructions live off-device for the POC.
    private var discoveryHeader: some View {
        HStack {
            Button(action: leaveDiscovery) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.title2.weight(.light))
                    .foregroundStyle(BrandTheme.brownMuted)
            }
            .accessibilityLabel("Leave discovery")
            .accessibilityHint("Returns to staff profile.")

            Spacer()

            MellorityLogoImage(maxHeight: 32)
                .opacity(0.88)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var progressSection: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(sliceStartedAt)
                let frac = CGFloat(min(1, max(0, elapsed / DiscoveryFlowPOC.snippetDurationSeconds)))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(BrandTheme.creamDeep.opacity(0.55))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [BrandTheme.goldSoft, BrandTheme.gold, BrandTheme.goldDeep],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(12, frac * geo.size.width))
                            .shadow(color: BrandTheme.gold.opacity(0.22), radius: 4, y: 1)
                            .animation(.linear(duration: 1.0 / 30.0), value: frac)
                    }
                    .frame(height: 10)
                    .clipShape(Capsule())
                }
                .frame(height: 10)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Listen progress")
            }
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
                    state.setDiscoveryPick(mood)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func leaveDiscovery() {
        sliceDeadlineTask?.cancel()
        sliceDeadlineTask = nil
        audio.stop()
        state.abandonDiscoveryCalibration()
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
        audio.startFresh(photoAnchored: idxCapt % 2 == 1)

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

// MARK: - Traffic smiles (minimal)

private struct TrafficSmileyFaceButton: View {
    let sentiment: DiscoveryTrafficSentiment
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            MinimalTrafficFace(sentiment: sentiment)
                .frame(width: 96, height: 96)
                .padding(6)
                .background(
                    Circle()
                        .fill(BrandTheme.cream.opacity(isSelected ? 0.92 : 0.45))
                        .overlay(
                            Circle().strokeBorder(
                                sentiment.ringColor.opacity(isSelected ? 0.95 : 0.42),
                                lineWidth: isSelected ? 3.5 : 1.8
                            )
                        )
                        .shadow(color: sentiment.ringColor.opacity(isSelected ? 0.42 : 0.12), radius: isSelected ? 12 : 4, y: 3)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sentiment.accessibilitySummary + " mood")
        .accessibilityHint("Select how this clip feels.")
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
