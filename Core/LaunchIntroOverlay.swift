import SwiftUI

/// Launch copy inside the orb — motion locked to the same pulse anchor as the envelope.
struct LaunchIntroOverlay: View {
    var anchor: Date
    var totalDuration: TimeInterval

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let thirdLineAfter: TimeInterval = 4.2
    private let titleFadeIn: TimeInterval = 0.85
    private let subtitleFadeStart: TimeInterval = 2.0
    private let subtitleFadeEnd: TimeInterval = 3.2

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(anchor)
            let sample = OrbPulseSample.sample(at: elapsed, mode: .calm, reduceMotion: reduceMotion)
            let fadeOutStart = max(0, totalDuration - 1.2)
            let overlayOpacity = elapsed >= fadeOutStart
                ? max(0, 1 - (elapsed - fadeOutStart) / 1.2)
                : 1.0

            let titleOpacity = min(1, max(0, elapsed / titleFadeIn))
            let subtitleOpacity = min(
                1,
                max(0, (elapsed - subtitleFadeStart) / (subtitleFadeEnd - subtitleFadeStart))
            )
            let thirdOpacity = elapsed >= thirdLineAfter
                ? min(1, (elapsed - thirdLineAfter) / 0.55)
                : 0

            VStack(spacing: 18) {
                NoteStalgiaWordmark(
                    font: .system(size: 42, weight: .medium, design: .default),
                    tracking: 5,
                    pointSize: 42
                )
                .introLegibilityShadow(intensity: 1.15)
                .opacity(titleOpacity)

                Text("Sound you can live in.")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(BrandTheme.introSubtitle)
                    .multilineTextAlignment(.center)
                    .introLegibilityShadow(intensity: 1.0)
                    .opacity(subtitleOpacity)

                Text("Take a slow breath — we're almost there.")
                    .font(.system(size: 21, weight: .medium, design: .rounded))
                    .foregroundStyle(BrandTheme.introBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .introLegibilityShadow(intensity: 0.9)
                    .opacity(thirdOpacity)
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
            .background {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(BrandTheme.cream.opacity(0.72))
                    .overlay {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(BrandTheme.nebulaLavender.opacity(0.28), lineWidth: 1)
                    }
                    .shadow(color: BrandTheme.orbShellShadow.opacity(0.35), radius: 18, y: 8)
            }
            .padding(.horizontal, BrandTheme.contentGutter)
            .scaleEffect(sample.innerContentScale)
            .offset(x: sample.contentFloatX, y: sample.contentFloatY)
            .opacity(overlayOpacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("NoteStalgia is starting. Sound you can live in.")
        }
    }
}

private extension View {
    /// Light halo + soft drop shadow so intro copy reads on the sky-blue orb.
    func introLegibilityShadow(intensity: CGFloat = 1) -> some View {
        let i = max(0.5, intensity)
        return self
            .shadow(color: BrandTheme.introTextHalo, radius: 0.5 * i, x: 0, y: 0)
            .shadow(color: BrandTheme.introTextHalo.opacity(0.65), radius: 6 * i, x: 0, y: 0)
            .shadow(color: BrandTheme.introTextShadow, radius: 5 * i, x: 0, y: 3 * i)
    }
}
