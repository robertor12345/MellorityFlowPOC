import SwiftUI

// MARK: - Soft press (buttons feel organic, not sharp)

struct SoftPressButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.978

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

extension View {
    func calmSoftPress() -> some View {
        buttonStyle(SoftPressButtonStyle())
    }

    func calmDissolveTransition() -> some View {
        transition(
            .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.985)),
                removal: .opacity.combined(with: .scale(scale: 1.012))
            )
        )
    }
}

// MARK: - Breath ring (replaces spinners on calm waits)

struct BreathingCalmProgressView: View {
    var diameter: CGFloat = 56
    @State private var inhale = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(BrandTheme.gold.opacity(0.22), lineWidth: 2)
                .frame(width: diameter, height: diameter)
            Circle()
                .trim(from: 0, to: 0.68)
                .stroke(
                    AngularGradient(
                        colors: [
                            BrandTheme.gold.opacity(0.15),
                            BrandTheme.goldDeep.opacity(0.55),
                            BrandTheme.gold.opacity(0.12),
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(inhale ? 24 : -12))
                .scaleEffect(inhale ? 1.06 : 0.90)
                .opacity(inhale ? 0.92 : 0.55)
        }
        .accessibilityLabel("Preparing your calm space")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                inhale = true
            }
        }
    }
}

// MARK: - Staff → resident handoff veil

struct ResidentStaffHandoffOverlay: View {
    var patientName: String?
    var onComplete: () -> Void

    @State private var veilOpacity: Double = 0
    @State private var copyOpacity: Double = 0
    @State private var orbGlow: Double = 0.4

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.28, blue: 0.38)
                .opacity(veilOpacity * 0.28)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                BreathingCalmProgressView(diameter: 72)
                    .scaleEffect(1 + orbGlow * 0.08)
                if let patientName {
                    Text(patientName)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(BrandTheme.cream)
                }
                Text("Handing to calm")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BrandTheme.cream.opacity(0.82))
            }
            .opacity(copyOpacity)
        }
        .allowsHitTesting(true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Handing device to resident calm surface")
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55)) {
                veilOpacity = 1
                copyOpacity = 1
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                orbGlow = 1
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_850_000_000)
                withAnimation(.easeInOut(duration: 0.5)) {
                    copyOpacity = 0
                    veilOpacity = 0
                }
                try? await Task.sleep(nanoseconds: 520_000_000)
                onComplete()
            }
        }
    }
}

// MARK: - Post-session settling pause

struct SessionSettlingView: View {
    @ObservedObject var state: SessionPOCState
    @State private var visible = false

    var body: some View {
        ZStack {
            VStack(spacing: 22) {
                BreathingCalmProgressView(diameter: 80)
                Text(state.isResidentSession ? "Settling" : "A quiet moment")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(BrandTheme.brown.opacity(0.88))
            }
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : 0.98)
        }
        .accessibilityLabel("Settling after session")
        .onAppear {
            CalmExperienceFeedback.sessionSettle()
            withAnimation(.easeInOut(duration: 0.65)) { visible = true }
        }
        .task {
            try? await Task.sleep(nanoseconds: 3_400_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.55)) { visible = false }
            }
            try? await Task.sleep(nanoseconds: 560_000_000)
            await MainActor.run {
                if state.isResidentSession {
                    state.phase = .residentProfile
                } else {
                    state.phase = .insight
                }
            }
        }
    }
}

// MARK: - Face ID welcome (portrait + greeting before calm surface)

struct ResidentFaceIDWelcomeView: View {
    @ObservedObject var state: SessionPOCState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var contentOpacity: Double = 0
    @State private var portraitScale: CGFloat = 0.92
    @State private var advanceTask: Task<Void, Never>?

    private var patient: CarePatientProfile? {
        state.carePatient(id: state.selectedCarePatientId)
    }

    private var portraitDiameter: CGFloat {
        BrandLayout.scaled(148, regular: 200, horizontalSizeClass: horizontalSizeClass)
    }

    var body: some View {
        ZStack {
            if let patient {
                VStack(spacing: 28) {
                    Image(patient.stockPortraitAssetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: portraitDiameter, height: portraitDiameter)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [BrandTheme.gold.opacity(0.7), BrandTheme.goldSoft.opacity(0.35)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .shadow(color: BrandTheme.brown.opacity(0.14), radius: 20, y: 8)
                        .scaleEffect(portraitScale)

                    VStack(spacing: 12) {
                        Text("Welcome")
                            .font(BrandTheme.title(.largeTitle))
                            .foregroundStyle(BrandTheme.logoPink)

                        Text(patient.displayName)
                            .font(BrandTheme.title(.title))
                            .foregroundStyle(BrandTheme.brown)
                            .multilineTextAlignment(.center)

                        Text("Your calm space is ready.")
                            .font(.title3.weight(.regular))
                            .foregroundStyle(BrandTheme.logoLavenderBlue)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, BrandLayout.contentGutter(for: horizontalSizeClass))
                .opacity(contentOpacity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Welcome, \(patient.displayName). Your calm space is ready.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { completeWelcome() }
        .onAppear { runWelcomeSequence() }
        .onDisappear {
            advanceTask?.cancel()
            advanceTask = nil
        }
    }

    private func runWelcomeSequence() {
        advanceTask?.cancel()
        withAnimation(.easeOut(duration: 0.75)) {
            contentOpacity = 1
            portraitScale = 1
        }
        advanceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            guard !Task.isCancelled else { return }
            completeWelcome()
        }
    }

    private func completeWelcome() {
        guard state.phase == .residentFaceIDWelcome else { return }
        advanceTask?.cancel()
        advanceTask = nil
        withAnimation(.easeInOut(duration: 0.55)) {
            contentOpacity = 0
            portraitScale = 1.04
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 520_000_000)
            guard state.phase == .residentFaceIDWelcome else { return }
            state.completeResidentFaceIDWelcome()
        }
    }
}
