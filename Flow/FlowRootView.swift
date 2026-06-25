import SwiftUI

struct FlowRootView: View {
    @StateObject private var state = SessionPOCState()
    @State private var launchComplete = false
    @State private var launchAnchor = Date()
    @State private var launchDidFinish = false

    private let launchTotalDuration: Double = 11.5

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let style = OrbNavigationStyle.forPhase(
                state.phase,
                launchActive: !launchComplete,
                isResidentSession: state.isResidentSession
            )
            let contentInset = style.resolvedContentTopInset(safeTop: safeTop)
            let shellConfig = OrbShellConfiguration.forPhase(
                state.phase,
                launchActive: !launchComplete,
                containerSize: geo.size,
                isResidentSession: state.isResidentSession
            )

            ZStack {
                BrandBackground(showSparkles: false)

                GoldAmbientSparklesView(
                    particleCount: BrandTheme.ambientSparkleParticleCount,
                    intensity: BrandTheme.ambientSparkleIntensity
                )
                .ignoresSafeArea()
                .zIndex(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                PersistentFlowOrbShell(configuration: shellConfig, anchor: launchAnchor)
                    .zIndex(1)
                    .animation(.easeInOut(duration: 0.62), value: shellConfig)

                phaseLayer(contentInset: contentInset, style: style)
                    .zIndex(2)
                    .environment(\.flowContainerSize, geo.size)
                    .environment(\.flowOrbShellSize, CGSize(width: shellConfig.width, height: shellConfig.height))
                    .environment(\.flowOrbPulseAnchor, launchAnchor)
                    .environment(\.flowPanelPulseIntensity, shellConfig.panelPulseIntensity)
                    .environment(\.flowPanelPulseSpeed, shellConfig.panelPulseSpeed)

                if !launchComplete {
                    LaunchIntroOverlay(anchor: launchAnchor, totalDuration: launchTotalDuration)
                        .zIndex(8)
                }

                if state.residentHandoffActive {
                    ResidentStaffHandoffOverlay(
                        patientName: state.carePatient(id: state.selectedCarePatientId)?.displayName,
                        onComplete: { state.completeResidentHandoffTransition() }
                    )
                    .zIndex(12)
                    .transition(.opacity)
                }
            }
        }
        .animation(CalmMotion.ethereal, value: state.phase)
        .animation(CalmMotion.ethereal, value: launchComplete)
        .animation(CalmMotion.softFade, value: state.residentHandoffActive)
        .contentShape(Rectangle())
        .onTapGesture {
            skipLaunchIfNeeded()
        }
        .accessibilityLabel(launchComplete ? "NoteStalgia" : "NoteStalgia is starting.")
        .accessibilityHint(launchComplete ? "" : "Tap anywhere to skip.")
        .onAppear {
            launchAnchor = Date()
            state.resetAllForFreshAppLaunch()
        }
        .task {
            try? await Task.sleep(nanoseconds: UInt64(launchTotalDuration * 1_000_000_000))
            await MainActor.run { finishLaunch() }
        }
    }

    @ViewBuilder
    private func phaseLayer(contentInset: CGFloat, style: OrbNavigationStyle) -> some View {
        Group {
            switch state.phase {
            case .home:
                HomeView(state: state)
            case .entryMode:
                EntryModeView(state: state)
            case .captureMoment:
                CapturePhotoView(state: state)
            case .moodSelect:
                MoodSelectView(state: state)
            case .processingFast:
                ProcessingFastView(state: state)
            case .immersive:
                ImmersiveSessionView(state: state)
            case .insight:
                InsightView(state: state)
            case .carePatientList:
                CarePatientListView(state: state)
            case .carePatientDetail:
                CarePatientDetailView(state: state)
            case .careSessionFeedback:
                CareSessionFeedbackView(state: state)
            case .careSessionPrep:
                CareSessionPrepView(state: state)
            case .residentProfile:
                ResidentProfileView(state: state)
            case .careFaceLinkedPick:
                CarePatientListView(state: state)
            case .careDiscoveryCalibration:
                DiscoveryCalibrationView(state: state)
            case .sessionSettling:
                SessionSettlingView(state: state)
            case .careDiscoveryAgeInput:
                CareDiscoveryAgeInputView(state: state)
            case .careNewResidentProfile:
                CareNewResidentProfileView(state: state)
            case .careSessionSentimentFeedback:
                CareSessionSentimentFeedbackView(state: state)
            case .careGroupSession:
                GroupSessionView(state: state)
            case .careGroupSessionFeedback:
                GroupSessionFeedbackView(state: state)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, contentInset)
        .orbContentMotion(
            anchor: launchAnchor,
            pulseMode: style.pulseMode,
            enabled: style.floats && style.showsMenuEnvelope
        )
        .id(state.phase)
        .transition(.etherealAppear)
        .opacity(launchComplete ? 1 : 0)
        .allowsHitTesting(launchComplete && !state.residentHandoffActive)
    }

    private func skipLaunchIfNeeded() {
        guard !launchComplete else { return }
        finishLaunch()
    }

    private func finishLaunch() {
        guard !launchDidFinish else { return }
        launchDidFinish = true
        withAnimation(.easeInOut(duration: 0.62)) {
            launchComplete = true
        }
    }
}

struct BrandBackground: View {
    var showSparkles: Bool = true

    var body: some View {
        ZStack {
            BrandTheme.backgroundGradient
                .ignoresSafeArea()
            RadialGradient(
                colors: [
                    BrandTheme.nebulaPurple.opacity(0.16),
                    Color.clear,
                    BrandTheme.nebulaCyan.opacity(0.08),
                ],
                center: UnitPoint(x: 0.5, y: 0.45),
                startRadius: 20,
                endRadius: 680
            )
            .ignoresSafeArea()
            if showSparkles {
                GoldAmbientSparklesView(
                    particleCount: BrandTheme.ambientSparkleParticleCount,
                    intensity: BrandTheme.ambientSparkleIntensity
                )
                .ignoresSafeArea()
            }
        }
    }
}

struct BrandCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(BrandTheme.cream.opacity(0.94))
                    .shadow(color: BrandTheme.brown.opacity(0.08), radius: 12, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(BrandTheme.gold.opacity(0.28), lineWidth: 1)
            )
    }
}
