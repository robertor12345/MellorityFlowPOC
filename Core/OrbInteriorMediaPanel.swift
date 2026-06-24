import SwiftUI

/// Clips flowing media to the resident / visuals orb interior and keeps the logo arc frame visible.
struct OrbInteriorMediaPanel<Media: View>: View {
    var orbSize: CGSize
    /// Slightly inset so the persistent nebula shell + arc frame remain visible around the clip.
    var mediaFillScale: CGFloat = 0.90
    var showArcFrame: Bool = true
    @ViewBuilder var media: () -> Media

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.flowOrbPulseAnchor) private var flowOrbPulseAnchor
    @Environment(\.flowPanelPulseSpeed) private var flowPanelPulseSpeed

    private var pulseAnchor: Date {
        flowOrbPulseAnchor == .distantPast ? Date() : flowOrbPulseAnchor
    }

    var body: some View {
        let diameter = min(orbSize.width, orbSize.height)
        let mediaDiameter = diameter * mediaFillScale

        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(pulseAnchor) * flowPanelPulseSpeed
            let sample = OrbPulseSample.sample(
                at: elapsed,
                mode: .calm,
                reduceMotion: reduceMotion
            )
            let contentScale = sample.shellScale

            ZStack {
                media()
                    .frame(width: mediaDiameter, height: mediaDiameter)
                    .clipShape(Circle())
                    .scaleEffect(contentScale)

                if showArcFrame {
                    if diameter >= 96 {
                        NoteStalgiaOrbRippleRings(
                            diameter: diameter,
                            phase: sample.pulse,
                            glowPulse: sample.glowPulse,
                            ringExpansion: OrbReferenceMotion.ringExpansion(at: elapsed)
                        )
                    } else {
                        NoteStalgiaOrbAnimatedArcFrame(
                            diameter: diameter * 1.02,
                            lineWidth: max(1.5, diameter * 0.004),
                            swirlPhase: elapsed,
                            glowPulse: sample.glowPulse,
                            breathe: contentScale
                        )
                    }
                }
            }
            .frame(width: diameter, height: diameter)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
