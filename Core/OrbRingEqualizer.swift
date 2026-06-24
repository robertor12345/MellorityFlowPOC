import SwiftUI

// MARK: - Oscillating ring equalizer (discovery orb + resident playlist hero)

enum OrbEqualizerMotion {
    static let barCount = 32

    static func barAmplified(index i: Int, phase t: Double, listenProgress frac: CGFloat) -> CGFloat {
        let ωA = 1.95 + Double(i % 15) * 0.068
        let ωB = 0.74 + Double((i ^ 11) % 17) * 0.049
        let wa = sin(t * ωA + Double(i) * 0.93)
        let wb = cos(t * ωB + Double(i) * 1.11)
        let weave = CGFloat((wa + wb + 1.8) / 3.6)

        let breath = 0.86 + CGFloat(sin(t * 0.47 + Double(i) * 0.08)) * 0.13
        let openness = CGFloat(sqrt(Double(frac)))
        let level = openness * CGFloat(0.38 + weave * Double(0.34 + frac * 0.28))
            + (1 - openness) * (0.12 + weave * (0.32 + frac * 0.22))
        return max(0.15, min(1, level * breath))
    }
}

/// Wiggling concentric rings hugging just outside a circular orb or glyph rim.
struct OrbRingEqualizerView: View {
    var canvasDiameter: CGFloat
    /// Exterior radius of the orb / hero disk — rings sit just outside this edge.
    var orbEdgeRadius: CGFloat
    /// 0…1 openness; discovery animates from slice timing, playlist uses 1.
    var listenProgress: CGFloat = 1

    private let ringCount = 5

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
            let frac = min(1, max(0, listenProgress))
            let t = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                let shimmer = 0.72 + 0.28 * frac

                for ring in 0 ..< ringCount {
                    let ringT = Double(ring) / Double(max(1, ringCount - 1))
                    let baseRadius = orbEdgeRadius * (1.045 + ringT * 0.095)
                    let wiggleScale = orbEdgeRadius * (0.034 - ringT * 0.007)
                    let steps = 96

                    var path = Path()
                    for step in 0 ... steps {
                        let u = Double(step) / Double(steps)
                        let angle = u * .pi * 2 - .pi / 2
                        let barIndex = Int(u * Double(OrbEqualizerMotion.barCount)) % OrbEqualizerMotion.barCount
                        let amp = OrbEqualizerMotion.barAmplified(
                            index: barIndex,
                            phase: t + ringT * 0.35,
                            listenProgress: frac
                        )
                        let radialBump = (amp - 0.38) * wiggleScale * 2.4
                        let harmonic =
                            sin(angle * 4.0 + t * (2.0 + ringT * 0.8) + Double(ring) * 0.9)
                            * wiggleScale
                            * 0.32
                        let twist =
                            cos(angle * 7.0 - t * 1.4 + Double(barIndex) * 0.15)
                            * wiggleScale
                            * 0.14
                        let radius = baseRadius + radialBump + harmonic + twist
                        let point = CGPoint(
                            x: center.x + CGFloat(cos(angle) * radius),
                            y: center.y + CGFloat(sin(angle) * radius)
                        )
                        if step == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()

                    let strokeOpacity = (0.42 - ringT * 0.14) * shimmer
                    let lineWidth = max(1.1, canvasDiameter * (0.0048 - ringT * 0.0006))

                    context.stroke(
                        path,
                        with: .color(BrandTheme.nebulaCyan.opacity(strokeOpacity)),
                        lineWidth: lineWidth + 2.8
                    )
                    context.stroke(
                        path,
                        with: .color(BrandTheme.nebulaCyan.opacity(strokeOpacity * 0.35)),
                        lineWidth: lineWidth + 5.5
                    )
                    context.stroke(
                        path,
                        with: .color(
                            (ring.isMultiple(of: 2) ? BrandTheme.nebulaLavender : BrandTheme.nebulaPeach)
                                .opacity(strokeOpacity * 0.88)
                        ),
                        lineWidth: lineWidth
                    )
                }
            }
            .allowsHitTesting(false)
        }
        .frame(width: canvasDiameter, height: canvasDiameter)
    }
}

extension OrbRingEqualizerView {
    /// Matches discovery orb ring extent — canvas larger than core, rings in a background overlay.
    static let ringCanvasOutset: CGFloat = OrbHeartbeat.maxVisualExtentScale * 1.12

    static func canvasDiameter(for coreDiameter: CGFloat) -> CGFloat {
        coreDiameter * ringCanvasOutset
    }

    static func orbEdgeRadius(for coreDiameter: CGFloat, shellScale: CGFloat = 1) -> CGFloat {
        (coreDiameter * 0.5) * OrbHeartbeat.visualHeadroom * shellScale
    }

    /// Hero glyph on resident playlist — rings hug the disk without nebula headroom.
    static func glyphOrbEdgeRadius(for diskDiameter: CGFloat) -> CGFloat {
        diskDiameter * 0.52
    }

    static func glyphRingOutwardPad(for diskDiameter: CGFloat) -> CGFloat {
        let canvas = canvasDiameter(for: diskDiameter)
        return (canvas - diskDiameter) * 0.5
    }
}
