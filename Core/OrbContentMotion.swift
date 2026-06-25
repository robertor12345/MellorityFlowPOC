import SwiftUI

/// Applies the same breathe + float as the menu orb shell so inner content drifts in sync.
struct OrbContentMotion: ViewModifier {
    var anchor: Date
    var pulseMode: OrbPulseMode
    var enabled: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if enabled && !reduceMotion {
            TimelineView(.animation(minimumInterval: OrbRenderBudget.contentFrameInterval(reduceMotion: reduceMotion), paused: pulseMode == .dormant)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(anchor)
            let sample = OrbPulseSample.sample(
                at: elapsed,
                mode: pulseMode,
                reduceMotion: reduceMotion
            )
                content
                    .scaleEffect(sample.innerContentScale)
                    .offset(x: sample.contentFloatX, y: sample.contentFloatY)
            }
        } else {
            content
        }
    }
}

extension View {
    func orbContentMotion(anchor: Date, pulseMode: OrbPulseMode, enabled: Bool = true) -> some View {
        modifier(OrbContentMotion(anchor: anchor, pulseMode: pulseMode, enabled: enabled))
    }
}
