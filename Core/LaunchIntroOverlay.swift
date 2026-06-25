import SwiftUI
import UIKit

/// Launch copy inside the orb — motion locked to the same pulse anchor as the envelope.
struct LaunchIntroOverlay: View {
    var anchor: Date
    var totalDuration: TimeInterval

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let titleFadeIn: TimeInterval = 1.35
    private let subtitleStart: TimeInterval = 1.55
    private let thirdLineStart: TimeInterval = 5.1
    private let wordStagger: TimeInterval = 0.52
    private let wordFadeDuration: TimeInterval = 0.78

    var body: some View {
        TimelineView(.animation(minimumInterval: OrbRenderBudget.contentFrameInterval(reduceMotion: reduceMotion), paused: false)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(anchor)
            let sample = OrbPulseSample.sample(at: elapsed, mode: .calm, reduceMotion: reduceMotion)
            let fadeOutStart = max(0, totalDuration - 1.2)
            let overlayOpacity = elapsed >= fadeOutStart
                ? max(0, 1 - (elapsed - fadeOutStart) / 1.2)
                : 1.0

            let titleOpacity = reduceMotion
                ? min(1, max(0, elapsed / 0.4))
                : min(1, max(0, elapsed / titleFadeIn))

            VStack(spacing: 22) {
                NoteStalgiaWordmark(
                    font: .system(size: 60, weight: .semibold, design: .rounded),
                    tracking: 6,
                    pointSize: 60
                )
                .opacity(titleOpacity)
                .offset(y: reduceMotion ? 0 : (1 - titleOpacity) * 14)

                IntroStaggeredWords(
                    text: "Sound that takes you back....",
                    elapsed: elapsed,
                    startAt: reduceMotion ? 0.3 : subtitleStart,
                    wordStagger: reduceMotion ? 0 : wordStagger,
                    fadeDuration: reduceMotion ? 0.35 : wordFadeDuration,
                    pointSize: 40,
                    weight: .semibold,
                    legibilityIntensity: 1.08
                )

                IntroStaggeredWords(
                    text: "Take a slow breath — we're almost there.",
                    elapsed: elapsed,
                    startAt: reduceMotion ? 0.6 : thirdLineStart,
                    wordStagger: reduceMotion ? 0 : wordStagger,
                    fadeDuration: reduceMotion ? 0.35 : wordFadeDuration,
                    pointSize: 32,
                    weight: .medium,
                    muted: true,
                    legibilityIntensity: 1.0
                )
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, BrandTheme.contentGutter)
            .scaleEffect(sample.innerContentScale)
            .offset(x: sample.contentFloatX, y: sample.contentFloatY)
            .opacity(overlayOpacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("NoteStalgia is starting. Sound that takes you back.")
        }
    }
}

/// Fades each word in sequentially.
private struct IntroStaggeredWords: View {
    let text: String
    let elapsed: TimeInterval
    let startAt: TimeInterval
    var wordStagger: TimeInterval
    var fadeDuration: TimeInterval
    let pointSize: CGFloat
    let weight: Font.Weight
    var muted: Bool = false
    var legibilityIntensity: CGFloat = 1

    var body: some View {
        Text(staggeredAttributedString)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .orbOverlayTextStyle(intensity: legibilityIntensity)
    }

    private var staggeredAttributedString: AttributedString {
        let words = text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        var line = AttributedString()
        let uiWeight = weight.uiFontWeight
        let textColor = muted ? BrandTheme.textOnOrbMuted : BrandTheme.textOnOrb
        let baseAlpha: CGFloat = muted ? 0.92 : 1

        for (index, word) in words.enumerated() {
            let progress = wordProgress(for: index)
            var chunk = AttributedString((index == 0 ? "" : " ") + word)
            var attributes = AttributeContainer()
            attributes.font = .systemFont(ofSize: pointSize, weight: uiWeight)
            attributes.foregroundColor = UIColor(textColor).withAlphaComponent(baseAlpha * progress)
            chunk.mergeAttributes(attributes)
            line.append(chunk)
        }
        return line
    }

    private func wordProgress(for index: Int) -> CGFloat {
        let start = startAt + Double(index) * wordStagger
        return CGFloat(min(1, max(0, (elapsed - start) / max(0.001, fadeDuration))))
    }
}

private extension Font.Weight {
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .ultraLight: .ultraLight
        case .thin: .thin
        case .light: .light
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .heavy: .heavy
        case .black: .black
        default: .regular
        }
    }
}
