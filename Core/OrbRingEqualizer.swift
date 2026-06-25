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
    /// When true, rings read the live `MusicReactiveBus` each frame and follow the music's spectrum.
    /// Read directly inside the per-frame Canvas so the parent view never re-renders for audio.
    var reactsToMusic: Bool = false

    private let ringCount = 5

    // The polygon geometry (angle, spectrum bar index, and angle's sin/cos) is identical every
    // frame and across all rings — precompute once instead of ~485 trig calls per frame.
    private static let stepCount = 96
    private static let angles: [Double] = (0 ... stepCount).map {
        Double($0) / Double(stepCount) * .pi * 2 - .pi / 2
    }
    private static let cosAngles: [Double] = angles.map(Foundation.cos)
    private static let sinAngles: [Double] = angles.map(Foundation.sin)
    private static let angle4: [Double] = angles.map { $0 * 4.0 }
    private static let angle7: [Double] = angles.map { $0 * 7.0 }
    private static let barIndices: [Int] = (0 ... stepCount).map {
        Int(Double($0) / Double(stepCount) * Double(OrbEqualizerMotion.barCount)) % OrbEqualizerMotion.barCount
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / OrbRenderBudget.contentFramesPerSecond, paused: false)) { timeline in
            let frac = min(1, max(0, listenProgress))
            let t = timeline.date.timeIntervalSinceReferenceDate
            let liveSnapshot = reactsToMusic ? MusicReactiveBus.shared.snapshot : nil
            let audioBandLevels: [CGFloat]? = (liveSnapshot?.isActive == true) ? liveSnapshot?.bands : nil
            let usesLiveAudio = (audioBandLevels?.count ?? 0) >= OrbEqualizerMotion.barCount

            Canvas { context, size in
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                let shimmer = 0.72 + 0.28 * frac
                let steps = Self.stepCount

                for ring in 0 ..< ringCount {
                    let ringT = Double(ring) / Double(max(1, ringCount - 1))
                    let baseRadius = orbEdgeRadius * (1.045 + ringT * 0.095)
                    let wiggleScale = orbEdgeRadius * (0.034 - ringT * 0.007)
                    let harmonicPhase = t * (2.0 + ringT * 0.8) + Double(ring) * 0.9
                    let synthPhase = t + ringT * 0.35

                    var path = Path()
                    for step in 0 ... steps {
                        let barIndex = Self.barIndices[step]
                        let amp: CGFloat
                        if usesLiveAudio, let levels = audioBandLevels {
                            amp = max(0.12, min(1, levels[barIndex]))
                        } else {
                            amp = OrbEqualizerMotion.barAmplified(
                                index: barIndex,
                                phase: synthPhase,
                                listenProgress: frac
                            )
                        }
                        let radialBump = (amp - (usesLiveAudio ? 0.28 : 0.38)) * wiggleScale * (usesLiveAudio ? 3.6 : 2.4)
                        let harmonic = usesLiveAudio
                            ? 0
                            : sin(Self.angle4[step] + harmonicPhase) * wiggleScale * 0.32
                        let twist = usesLiveAudio
                            ? 0
                            : cos(Self.angle7[step] - t * 1.4 + Double(barIndex) * 0.15) * wiggleScale * 0.14
                        let radius = baseRadius + radialBump + harmonic + twist
                        let point = CGPoint(
                            x: center.x + CGFloat(Self.cosAngles[step] * radius),
                            y: center.y + CGFloat(Self.sinAngles[step] * radius)
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
