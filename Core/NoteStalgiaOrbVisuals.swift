import SwiftUI

/// Legacy logo arc pair — kept for compact icon orbs.
private struct NoteStalgiaOrbLogoArc: Shape {
    var startDegrees: Double
    var endDegrees: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.48
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startDegrees),
            endAngle: .degrees(endDegrees),
            clockwise: false
        )
        return path
    }
}

/// Slow-rotating glowing arc frame — interlocking upper / lower sweeps like the NoteStalgia logo.
struct NoteStalgiaOrbAnimatedArcFrame: View {
    var diameter: CGFloat
    var lineWidth: CGFloat = 2
    var swirlPhase: Double = 0
    var glowPulse: Double = 0.72
    var breathe: CGFloat = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Upper-right sweep over the top toward the left; lower-left sweep under the bottom toward the right.
    private static let upperArc = (start: -52.0, end: 128.0)
    private static let lowerArc = (start: 148.0, end: 308.0)

    var body: some View {
        let spin = reduceMotion ? 0.0 : sin((swirlPhase / 0.35) * OrbHeartbeat.angularFrequency) * 3.5
        let shimmer = reduceMotion ? 1.0 : (0.78 + 0.22 * glowPulse)

        ZStack {
            logoArcStrokes(
                lineWidth: lineWidth * 4.4,
                gradient: LinearGradient(
                    colors: [
                        BrandTheme.logoPink.opacity(0.34 * shimmer),
                        BrandTheme.logoCyan.opacity(0.28 * shimmer),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                blur: lineWidth * 3
            )

            logoArcStrokes(
                lineWidth: lineWidth,
                gradient: LinearGradient(
                    colors: [
                        .white.opacity(0.96),
                        BrandTheme.logoCyan.opacity(0.90),
                        BrandTheme.logoPink.opacity(0.86),
                        .white.opacity(0.94),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                blur: 0
            )
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(breathe)
        .rotationEffect(.degrees(spin))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func logoArcStrokes(lineWidth lw: CGFloat, gradient: LinearGradient, blur: CGFloat) -> some View {
        ZStack {
            NoteStalgiaOrbLogoArc(startDegrees: Self.upperArc.start, endDegrees: Self.upperArc.end)
                .stroke(gradient, style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
            NoteStalgiaOrbLogoArc(startDegrees: Self.lowerArc.start, endDegrees: Self.lowerArc.end)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)
                )
        }
        .blur(radius: blur)
    }
}

/// Legacy alias — prefer ``NoteStalgiaOrbAnimatedArcFrame``.
typealias NoteStalgiaOrbArcFrame = NoteStalgiaOrbAnimatedArcFrame

// MARK: - Reference orb ripple rings (concentric glass shells from reference video)

struct NoteStalgiaOrbRippleRings: View {
    var diameter: CGFloat
    var phase: Double
    var glowPulse: Double
    var ringExpansion: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            let baseRadius = min(size.width, size.height) * 0.46
            let shimmer = 0.72 + 0.28 * glowPulse

            for ring in 0 ..< 3 {
                let ringBias = Double(ring) * 0.055
                let expand = ringExpansion + ringBias + phase * 0.018
                let radius = baseRadius * expand
                let ringRect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                let strokeOpacity = (0.34 - Double(ring) * 0.08) * shimmer
                context.stroke(
                    Path(ellipseIn: ringRect),
                    with: .color(.white.opacity(strokeOpacity)),
                    lineWidth: max(0.6, diameter * 0.0018)
                )

                let topoCount = 3 + ring
                for line in 1 ... topoCount {
                    let inset = CGFloat(line) * max(0.8, diameter * 0.0032)
                    let inner = radius - inset
                    guard inner > radius * 0.55 else { continue }
                    let innerRect = CGRect(
                        x: center.x - inner,
                        y: center.y - inner,
                        width: inner * 2,
                        height: inner * 2
                    )
                    context.stroke(
                        Path(ellipseIn: innerRect),
                        with: .color(BrandTheme.nebulaCyan.opacity(0.07 * shimmer)),
                        lineWidth: 0.45
                    )
                }
            }
        }
        .frame(width: diameter * 1.22, height: diameter * 1.22)
        .rotationEffect(.degrees(reduceMotion ? 0 : phase * 4.5))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Reference orb exterior smoke wisps

struct NoteStalgiaOrbExteriorWisps: View {
    var diameter: CGFloat
    var swirlPhase: Double
    var glowPulse: Double
    var drift: Double = 0

    var body: some View {
        let sway = CGFloat(sin(swirlPhase * 0.85 + drift * 0.4)) * diameter * 0.018
        let lift = CGFloat(cos(swirlPhase * 0.62)) * diameter * 0.012

        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            BrandTheme.nebulaCyan.opacity(0.72 * glowPulse),
                            BrandTheme.nebulaTeal.opacity(0.28),
                            .clear,
                        ],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
                .frame(width: diameter * 1.05, height: diameter * 0.34)
                .offset(x: -diameter * 0.42 + sway, y: lift * 0.4)
                .blur(radius: diameter * 0.07)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            BrandTheme.nebulaPeach.opacity(0.68 * glowPulse),
                            BrandTheme.nebulaSalmon.opacity(0.42),
                            BrandTheme.nebulaLavender.opacity(0.18),
                            .clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: diameter * 1.12, height: diameter * 0.40)
                .offset(x: diameter * 0.40 - sway * 0.6, y: -lift * 0.25)
                .blur(radius: diameter * 0.075)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            BrandTheme.nebulaLavender.opacity(0.24 * glowPulse),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.22
                    )
                )
                .frame(width: diameter * 0.55, height: diameter * 0.28)
                .offset(x: diameter * 0.08, y: -diameter * 0.34 + lift)
                .blur(radius: diameter * 0.05)
        }
        .frame(width: diameter * 1.45, height: diameter * 1.15)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Animated nebula interior (reference video match)

struct NoteStalgiaNebulaFill: View {
    var diameter: CGFloat
    var swirlPhase: Double
    var glowPulse: Double
    /// Lower when video fills the orb interior so media stays visible beneath the arc frame.
    var fillOpacity: CGFloat = 1

    var body: some View {
        ReferenceOrbNebulaInterior(
            diameter: diameter,
            phase: swirlPhase,
            glowPulse: glowPulse,
            fillOpacity: fillOpacity
        )
        .opacity(fillOpacity)
    }
}

// MARK: - Full orb shell (menu circle · panels · icon size)

struct NoteStalgiaNebulaOrbShell: View {
    var width: CGFloat
    var height: CGFloat
    var pulse: Double
    var glowPulse: Double
    var shellScale: CGFloat
    var anchor: Date = Date()
    var showArcFrame: Bool = true
    var nebulaFillOpacity: CGFloat = 1
    var shellGlowScale: CGFloat = 1
    /// When set, the parent timeline drives animation (avoids a second 60fps timer).
    var animationElapsed: TimeInterval? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var bounds: CGFloat { min(width, height) }

    private var baseDiameter: CGFloat { min(width, height) }

    private var diameter: CGFloat { baseDiameter * shellScale }

    private var shellFrameInterval: Double {
        1 / (reduceMotion ? OrbRenderBudget.reducedMotionFramesPerSecond : OrbRenderBudget.shellFramesPerSecond)
    }

    var body: some View {
        Group {
            if let animationElapsed {
                orbShellContent(elapsed: animationElapsed)
            } else {
                TimelineView(.animation(minimumInterval: shellFrameInterval, paused: false)) { timeline in
                    orbShellContent(elapsed: timeline.date.timeIntervalSince(anchor))
                }
            }
        }
    }

    private func orbShellContent(elapsed: TimeInterval) -> some View {
        let swirl = reduceMotion ? 0 : elapsed * 0.32
        let breathe = OrbHeartbeat.breatheScale(forPulse: pulse)
        let glowStrength = min(1.35, shellGlowScale)
        let ringExpansion = OrbReferenceMotion.ringExpansion(at: elapsed)
        let wispDrift = OrbReferenceMotion.wispDrift(at: elapsed)

        return ZStack {
            proceduralOrbInterior(
                swirl: swirl,
                breathe: breathe,
                glowStrength: glowStrength,
                pulse: pulse,
                ringExpansion: ringExpansion,
                wispDrift: wispDrift
            )
        }
        .frame(width: diameter * OrbHeartbeat.visualHeadroom, height: diameter * OrbHeartbeat.visualHeadroom)
        .shadow(
            color: BrandTheme.nebulaMagenta.opacity(0.22 * glowPulse * Double(glowStrength)),
            radius: bounds * 0.11,
            y: bounds * 0.018
        )
    }

    @ViewBuilder
    private func proceduralOrbInterior(
        swirl: Double,
        breathe: CGFloat,
        glowStrength: CGFloat,
        pulse: Double,
        ringExpansion: Double,
        wispDrift: Double
    ) -> some View {
        NoteStalgiaOrbExteriorWisps(
            diameter: diameter,
            swirlPhase: swirl,
            glowPulse: glowPulse,
            drift: wispDrift
        )

        nebulaGlowLayer(glowStrength: glowStrength)
            .scaleEffect(breathe)

        NoteStalgiaNebulaFill(
            diameter: diameter,
            swirlPhase: swirl,
            glowPulse: glowPulse,
            fillOpacity: nebulaFillOpacity
        )
        .scaleEffect(breathe)

        if showArcFrame {
            if diameter >= 96 {
                NoteStalgiaOrbRippleRings(
                    diameter: diameter,
                    phase: pulse,
                    glowPulse: glowPulse,
                    ringExpansion: ringExpansion
                )
                .scaleEffect(breathe)
            } else {
                NoteStalgiaOrbAnimatedArcFrame(
                    diameter: diameter * 1.01,
                    lineWidth: max(1.5, diameter * 0.004),
                    swirlPhase: swirl,
                    glowPulse: glowPulse,
                    breathe: breathe
                )
            }
        }
    }

    private func nebulaGlowLayer(glowStrength: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        BrandTheme.nebulaCyan.opacity(glowPulse * 0.52 * Double(glowStrength)),
                        BrandTheme.nebulaLavender.opacity(glowPulse * 0.28 * Double(glowStrength)),
                        BrandTheme.nebulaPeach.opacity(glowPulse * 0.18 * Double(glowStrength)),
                        .clear,
                    ],
                    center: .center,
                    startRadius: diameter * 0.06,
                    endRadius: diameter * 0.58
                )
            )
            .frame(width: diameter * 1.02, height: diameter * 1.02)
            .blur(radius: diameter * 0.05)
    }
}

// MARK: - Brand wordmark

struct NoteStalgiaWordmark: View {
    var font: Font = BrandTheme.title(.largeTitle)
    var tracking: CGFloat = 4
    /// Main wordmark point size — scales the ™ mark proportionally.
    var pointSize: CGFloat = 28

    private var trademarkSize: CGFloat { max(8, pointSize * 0.30) }
    private var trademarkBaselineOffset: CGFloat { pointSize * 0.42 }

    var body: some View {
        (Text("NoteStalgia")
            .font(font)
            .tracking(tracking)
         + Text("™")
            .font(.system(size: trademarkSize, weight: .medium, design: .default))
            .baselineOffset(trademarkBaselineOffset))
            .foregroundStyle(.white)
            .accessibilityLabel("NoteStalgia")
    }
}

