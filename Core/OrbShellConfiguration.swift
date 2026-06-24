import SwiftUI

enum OrbEnvelopeKind: Equatable {
    case organicBubble
    case roundedPanel
}

/// Animated envelope dimensions + pulse for the single persistent flow orb.
struct OrbShellConfiguration: Equatable {
    var width: CGFloat
    var height: CGFloat
    var opacity: CGFloat
    var pulseMode: OrbPulseMode
    var pulseSoftness: CGFloat
    var floats: Bool
    var kind: OrbEnvelopeKind
    var panelPulseSpeed: Double = 1
    var panelPulseIntensity: CGFloat = 1
    var nebulaFillOpacity: CGFloat = 1
    var showArcFrame: Bool = true
    var shellGlowScale: CGFloat = 1

    static func forPhase(
        _ phase: FlowPhase,
        launchActive: Bool,
        containerSize: CGSize,
        isResidentSession: Bool = false
    ) -> OrbShellConfiguration {
        guard containerSize.width > 1, containerSize.height > 1 else {
            return panelShell(in: .zero, width: 280, height: 280)
        }

        if launchActive {
            let size = BrandLayout.flowOrbPanelSize(in: containerSize)
            return panelShell(in: containerSize, width: size.width, height: size.height, floats: false)
        }

        switch phase {
        case .immersive:
            let nebula: CGFloat = isResidentSession ? 0.22 : 0.35
            return panelShell(in: containerSize, nebulaFillOpacity: nebula, shellGlowScale: 1.45)
        case .careDiscoveryCalibration:
            return panelShell(in: containerSize, shellGlowScale: 1.45)
        default:
            _ = isResidentSession
            return panelShell(in: containerSize, shellGlowScale: 1.45)
        }
    }

    /// One panel-sized orb on every screen — size morphs, cadence follows the reference orb loop.
    private static func panelShell(
        in containerSize: CGSize,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        nebulaFillOpacity: CGFloat = 1,
        shellGlowScale: CGFloat = 1.45,
        opacity: CGFloat = 1,
        floats: Bool = false
    ) -> OrbShellConfiguration {
        let size = BrandLayout.flowOrbPanelSize(in: containerSize)
        return OrbShellConfiguration(
            width: width ?? size.width,
            height: height ?? size.height,
            opacity: opacity,
            pulseMode: .calm,
            pulseSoftness: 1,
            floats: floats,
            kind: .organicBubble,
            panelPulseSpeed: 1,
            panelPulseIntensity: 1,
            nebulaFillOpacity: nebulaFillOpacity,
            showArcFrame: true,
            shellGlowScale: shellGlowScale
        )
    }
}

/// One orb shell that morphs size and opacity as the flow moves between pages.
struct PersistentFlowOrbShell: View {
    var configuration: OrbShellConfiguration
    var anchor: Date

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: configuration.pulseMode == .dormant)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(anchor) * configuration.panelPulseSpeed
            let sample = OrbPulseSample.sample(
                at: elapsed,
                mode: configuration.pulseMode,
                reduceMotion: reduceMotion,
                speedMultiplier: configuration.panelPulseSpeed
            )
            let shellScale = sample.shellScale
            let floatScale: CGFloat = configuration.floats ? 0.25 : 0

            ZStack {
                MorphingOrbShellBackdrop(
                    width: configuration.width,
                    height: configuration.height,
                    pulse: sample.pulse,
                    glowPulse: sample.glowPulse,
                    shellScale: shellScale,
                    kind: configuration.kind,
                    nebulaFillOpacity: configuration.nebulaFillOpacity,
                    showArcFrame: configuration.showArcFrame,
                    shellGlowScale: configuration.shellGlowScale
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(configuration.opacity)
            .offset(
                x: configuration.floats ? sample.contentFloatX * floatScale : 0,
                y: configuration.floats ? sample.contentFloatY * floatScale : 0
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct MorphingOrbShellBackdrop: View, Animatable {
    var width: CGFloat
    var height: CGFloat
    var pulse: Double
    var glowPulse: Double
    var shellScale: CGFloat
    var kind: OrbEnvelopeKind
    var nebulaFillOpacity: CGFloat = 1
    var showArcFrame: Bool = true
    var shellGlowScale: CGFloat = 1

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(width, height) }
        set {
            width = newValue.first
            height = newValue.second
        }
    }

    var body: some View {
        switch kind {
        case .organicBubble, .roundedPanel:
            MellorityOrbEnvelopeBackdrop(
                width: max(0, width),
                height: max(0, height),
                pulse: pulse,
                glowPulse: glowPulse,
                shellScale: shellScale,
                nebulaFillOpacity: nebulaFillOpacity,
                showArcFrame: showArcFrame,
                shellGlowScale: shellGlowScale
            )
        }
    }
}
