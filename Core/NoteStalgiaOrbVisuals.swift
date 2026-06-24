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

                let topoCount = 5 + ring * 2
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

// MARK: - Animated nebula interior (gas-giant atmosphere)

struct NoteStalgiaNebulaFill: View {
    var diameter: CGFloat
    var swirlPhase: Double
    var glowPulse: Double
    /// Lower when video fills the orb interior so media stays visible beneath the arc frame.
    var fillOpacity: CGFloat = 1

    var body: some View {
        NoteStalgiaGasGiantInterior(
            diameter: diameter,
            phase: swirlPhase,
            glowPulse: glowPulse
        )
        .opacity(fillOpacity)
    }
}

/// Layered belts, storms, and contour bands — reads as a luminous gas giant.
private struct NoteStalgiaGasGiantInterior: View {
    var diameter: CGFloat
    var phase: Double
    var glowPulse: Double

    private static let bands: [GasGiantLatitudeBand] = [
        GasGiantLatitudeBand(id: 0, latitude: -0.38, thickness: 0.058, tone: 1, driftSpeed: 2.8, waveSeed: 0.4, irregularity: 0.72),
        GasGiantLatitudeBand(id: 1, latitude: -0.29, thickness: 0.044, tone: 0, driftSpeed: 3.4, waveSeed: 1.1, irregularity: 0.55),
        GasGiantLatitudeBand(id: 2, latitude: -0.20, thickness: 0.068, tone: 2, driftSpeed: 2.4, waveSeed: 2.0, irregularity: 0.88),
        GasGiantLatitudeBand(id: 3, latitude: -0.11, thickness: 0.040, tone: 3, driftSpeed: 3.1, waveSeed: 0.8, irregularity: 0.63),
        GasGiantLatitudeBand(id: 4, latitude: -0.02, thickness: 0.052, tone: 1, driftSpeed: 2.6, waveSeed: 1.7, irregularity: 0.91),
        GasGiantLatitudeBand(id: 5, latitude: 0.07, thickness: 0.074, tone: 0, driftSpeed: 3.6, waveSeed: 2.4, irregularity: 0.78),
        GasGiantLatitudeBand(id: 6, latitude: 0.16, thickness: 0.046, tone: 2, driftSpeed: 2.9, waveSeed: 0.6, irregularity: 0.67),
        GasGiantLatitudeBand(id: 7, latitude: 0.25, thickness: 0.061, tone: 3, driftSpeed: 3.2, waveSeed: 1.4, irregularity: 0.84),
        GasGiantLatitudeBand(id: 8, latitude: 0.34, thickness: 0.042, tone: 1, driftSpeed: 2.5, waveSeed: 2.8, irregularity: 0.58),
        GasGiantLatitudeBand(id: 9, latitude: 0.41, thickness: 0.050, tone: 0, driftSpeed: 3.0, waveSeed: 3.2, irregularity: 0.76),
    ]

    var body: some View {
        let wispX = CGFloat(sin(phase * 1.85)) * diameter * 0.045
        let wispY = CGFloat(cos(phase * 1.42)) * diameter * 0.038

        ZStack {
            planetBodyBase

            GasGiantCloudBandLayer(
                diameter: diameter,
                phase: phase,
                glowPulse: glowPulse,
                bands: Self.bands
            )

            GasGiantContourLayer(diameter: diameter, phase: phase, glowPulse: glowPulse)

            GasGiantStormLayer(diameter: diameter, phase: phase, glowPulse: glowPulse)
                .offset(x: wispX, y: wispY)

            turbulentShearLayer
                .rotationEffect(.degrees(phase * 16))

            planetLimbDarkening

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.22 * glowPulse),
                            BrandTheme.nebulaBeltHighlight.opacity(0.14 * glowPulse),
                            .clear,
                        ],
                        center: UnitPoint(x: 0.38, y: 0.36),
                        startRadius: 0,
                        endRadius: diameter * 0.28
                    )
                )
                .blur(radius: diameter * 0.04)

            NoteStalgiaOrbDustLayer(diameter: diameter, phase: phase, glowPulse: glowPulse)
            NoteStalgiaOrbSparkles(diameter: diameter, phase: phase, glowPulse: glowPulse)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
    }

    private var planetBodyBase: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            BrandTheme.nebulaDeep.opacity(0.92),
                            BrandTheme.nebulaBeltShadow.opacity(0.78),
                            BrandTheme.nebulaPurple.opacity(0.55),
                            BrandTheme.nebulaDeep.opacity(0.88),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.52
                    )
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            BrandTheme.nebulaCyan.opacity(0.52 * glowPulse),
                            BrandTheme.nebulaTeal.opacity(0.28),
                            .clear,
                        ],
                        center: UnitPoint(x: 0.28, y: 0.34),
                        startRadius: 0,
                        endRadius: diameter * 0.46
                    )
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            BrandTheme.nebulaPeach.opacity(0.46 * glowPulse),
                            BrandTheme.nebulaSalmon.opacity(0.30),
                            BrandTheme.nebulaMagenta.opacity(0.14),
                            .clear,
                        ],
                        center: UnitPoint(x: 0.72, y: 0.40),
                        startRadius: 0,
                        endRadius: diameter * 0.44
                    )
                )

            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            BrandTheme.nebulaCyan.opacity(0.38),
                            BrandTheme.nebulaLavender.opacity(0.22),
                            BrandTheme.nebulaPeach.opacity(0.34),
                            BrandTheme.nebulaPink.opacity(0.26),
                            BrandTheme.nebulaTeal.opacity(0.30),
                            BrandTheme.nebulaCyan.opacity(0.38),
                        ],
                        center: .center
                    )
                )
                .rotationEffect(.degrees(phase * 48))
                .blur(radius: diameter * 0.07)
                .opacity(0.82)
        }
    }

    private var turbulentShearLayer: some View {
        Circle()
            .fill(
                AngularGradient(
                    colors: [
                        BrandTheme.nebulaBeltShadow.opacity(0.22),
                        .clear,
                        BrandTheme.nebulaCyan.opacity(0.18),
                        .clear,
                        BrandTheme.nebulaPeach.opacity(0.16),
                        .clear,
                        BrandTheme.nebulaBeltShadow.opacity(0.22),
                    ],
                    center: .center
                )
            )
            .blur(radius: diameter * 0.045)
            .opacity(0.75 + 0.25 * glowPulse)
    }

    private var planetLimbDarkening: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .clear,
                        .clear,
                        BrandTheme.nebulaDeep.opacity(0.18),
                        BrandTheme.nebulaDeep.opacity(0.42),
                        BrandTheme.nebulaDeep.opacity(0.62),
                    ],
                    center: .center,
                    startRadius: diameter * 0.18,
                    endRadius: diameter * 0.52
                )
            )
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                BrandTheme.nebulaCyan.opacity(0.22 * glowPulse),
                                BrandTheme.nebulaLavender.opacity(0.12),
                                BrandTheme.nebulaPeach.opacity(0.16 * glowPulse),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: max(1, diameter * 0.003)
                    )
                    .blur(radius: 0.5)
            }
    }
}

private struct GasGiantStormLayer: View {
    var diameter: CGFloat
    var phase: Double
    var glowPulse: Double

    private struct Storm {
        let baseX: CGFloat
        let baseY: CGFloat
        let orbitRadius: CGFloat
        let orbitSpeed: Double
        let spinSpeed: Double
        let width: CGFloat
        let height: CGFloat
        let phaseOffset: Double
        let tone: Int
    }

    private static let storms: [Storm] = [
        Storm(baseX: 0.10, baseY: -0.06, orbitRadius: 0.05, orbitSpeed: 2.2, spinSpeed: -42, width: 0.36, height: 0.24, phaseOffset: 0.0, tone: 2),
        Storm(baseX: -0.14, baseY: 0.10, orbitRadius: 0.06, orbitSpeed: 1.8, spinSpeed: 36, width: 0.28, height: 0.19, phaseOffset: 1.4, tone: 1),
        Storm(baseX: 0.16, baseY: 0.12, orbitRadius: 0.045, orbitSpeed: 2.6, spinSpeed: 28, width: 0.22, height: 0.15, phaseOffset: 2.8, tone: 3),
        Storm(baseX: -0.06, baseY: -0.16, orbitRadius: 0.04, orbitSpeed: 3.1, spinSpeed: -52, width: 0.20, height: 0.13, phaseOffset: 4.2, tone: 0),
        Storm(baseX: 0.04, baseY: 0.18, orbitRadius: 0.055, orbitSpeed: 2.0, spinSpeed: 44, width: 0.24, height: 0.16, phaseOffset: 5.6, tone: 2),
    ]

    var body: some View {
        ZStack {
            ForEach(Array(Self.storms.enumerated()), id: \.offset) { index, storm in
                let t = phase * storm.orbitSpeed + storm.phaseOffset
                let x = storm.baseX + CGFloat(cos(t) * Double(storm.orbitRadius))
                let y = storm.baseY + CGFloat(sin(t * 1.18) * Double(storm.orbitRadius))
                Ellipse()
                    .fill(stormGradient(tone: storm.tone, endRadius: diameter * 0.18))
                    .frame(width: diameter * storm.width, height: diameter * storm.height)
                    .rotationEffect(.degrees(storm.spinSpeed * phase + Double(index) * 22))
                    .offset(x: diameter * x, y: diameter * y)
                    .blur(radius: diameter * (0.018 + CGFloat(index % 3) * 0.004))
            }
        }
    }

    private func stormGradient(tone: Int, endRadius: CGFloat) -> RadialGradient {
        switch tone {
        case 0:
            return RadialGradient(
                colors: [BrandTheme.nebulaBeltHighlight.opacity(0.64 * glowPulse), BrandTheme.nebulaCyan.opacity(0.22), .clear],
                center: .center, startRadius: 0, endRadius: endRadius
            )
        case 1:
            return RadialGradient(
                colors: [BrandTheme.nebulaCyan.opacity(0.66 * glowPulse), BrandTheme.nebulaTeal.opacity(0.24), .clear],
                center: .center, startRadius: 0, endRadius: endRadius
            )
        case 2:
            return RadialGradient(
                colors: [BrandTheme.nebulaLavender.opacity(0.68 * glowPulse), BrandTheme.nebulaPurple.opacity(0.30), .clear],
                center: .center, startRadius: 0, endRadius: endRadius
            )
        default:
            return RadialGradient(
                colors: [BrandTheme.nebulaPeach.opacity(0.62 * glowPulse), BrandTheme.nebulaSalmon.opacity(0.24), .clear],
                center: .center, startRadius: 0, endRadius: endRadius
            )
        }
    }
}

private struct GasGiantLatitudeBand: Identifiable {
    let id: Int
    let latitude: Double
    let thickness: CGFloat
    let tone: Int
    let driftSpeed: Double
    let waveSeed: Double
    let irregularity: Double
}

private struct GasGiantCloudBandLayer: View {
    var diameter: CGFloat
    var phase: Double
    var glowPulse: Double
    var bands: [GasGiantLatitudeBand]

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w * 0.5

            for band in bands {
                let latDrift =
                    sin(phase * band.driftSpeed * 2.3 + band.waveSeed) * 0.038
                    + cos(phase * band.driftSpeed * 1.6 + Double(band.id) * 0.9) * 0.022
                let lat = band.latitude + latDrift
                let yCenter = h * (0.5 + lat * 0.90)
                let cosLat = max(0.14, cos(lat * .pi * 0.84))
                let bandWidth = w * (0.90 + band.irregularity * 0.06) * cosLat
                let bandHeight = h * band.thickness * (0.88 + band.irregularity * 0.22)
                let rect = CGRect(
                    x: cx - bandWidth * 0.5,
                    y: yCenter - bandHeight * 0.5,
                    width: bandWidth,
                    height: bandHeight
                )

                var wavePath = Path()
                wavePath.move(to: CGPoint(x: rect.minX, y: yCenter))
                let steps = 36
                for step in 0 ... steps {
                    let t = Double(step) / Double(steps)
                    let x = rect.minX + rect.width * t
                    let wave = bandWave(
                        t: t,
                        bandHeight: bandHeight,
                        phase: phase,
                        band: band
                    )
                    let shear = sin(t * .pi * 3.2 + phase * band.driftSpeed * 2.1 + band.waveSeed) * bandHeight * 0.14
                    wavePath.addLine(to: CGPoint(x: x, y: yCenter + wave + shear))
                }
                wavePath.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY + bandHeight * 0.35))
                wavePath.addLine(to: CGPoint(x: rect.minX, y: rect.maxY + bandHeight * 0.35))
                wavePath.closeSubpath()

                let color = bandColor(tone: band.tone)
                context.fill(
                    wavePath,
                    with: .color(color.opacity(bandOpacity(tone: band.tone)))
                )

                if band.tone == 0 || band.tone == 2 || band.irregularity > 0.75 {
                    var shadowPath = Path()
                    shadowPath.move(to: CGPoint(x: rect.minX, y: yCenter + bandHeight * 0.38))
                    for step in 0 ... steps {
                        let t = Double(step) / Double(steps)
                        let x = rect.minX + rect.width * t
                        let wave = bandWave(
                            t: t,
                            bandHeight: bandHeight,
                            phase: phase,
                            band: band
                        )
                        let shear = sin(t * .pi * 3.2 + phase * band.driftSpeed * 2.1 + band.waveSeed) * bandHeight * 0.14
                        shadowPath.addLine(to: CGPoint(x: x, y: yCenter + wave + shear + bandHeight * 0.24))
                    }
                    shadowPath.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY + bandHeight * 0.55))
                    shadowPath.addLine(to: CGPoint(x: rect.minX, y: rect.maxY + bandHeight * 0.55))
                    shadowPath.closeSubpath()
                    context.fill(
                        shadowPath,
                        with: .color(BrandTheme.nebulaBeltShadow.opacity(0.28 * glowPulse))
                    )
                }
            }
        }
        .blur(radius: diameter * 0.008)
        .allowsHitTesting(false)
    }

    private func bandWave(
        t: Double,
        bandHeight: CGFloat,
        phase: Double,
        band: GasGiantLatitudeBand
    ) -> CGFloat {
        let h = bandHeight
        let speed = band.driftSpeed
        let seed = band.waveSeed
        let irregular = band.irregularity
        let primary =
            sin(t * .pi * (4.4 + irregular * 4.2) + phase * speed * 3.4 + seed) * h * (0.28 + irregular * 0.24)
        let secondary =
            cos(t * .pi * (7.8 + irregular * 2.6) + phase * speed * 2.2 + seed * 1.4) * h * (0.16 + irregular * 0.12)
        let tertiary =
            sin(t * .pi * 12.5 + phase * speed * 4.8 + Double(band.id) * 0.65) * h * 0.08 * irregular
        let bite =
            sin(t * .pi * 19.0 + phase * speed * 5.6 + seed * 2.1) * h * 0.05 * irregular
        return primary + secondary + tertiary + bite
    }

    private func bandColor(tone: Int) -> Color {
        switch tone {
        case 0: BrandTheme.nebulaBeltHighlight
        case 1: BrandTheme.nebulaCyan
        case 2: BrandTheme.nebulaLavender
        default: BrandTheme.nebulaPeach
        }
    }

    private func bandOpacity(tone: Int) -> Double {
        let base: Double = switch tone {
        case 0: 0.52
        case 1: 0.44
        case 2: 0.38
        default: 0.46
        }
        return base * (0.82 + 0.18 * glowPulse)
    }
}

private struct GasGiantContourLayer: View {
    var diameter: CGFloat
    var phase: Double
    var glowPulse: Double

    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.5
            let cy = size.height * 0.5
            let maxR = min(size.width, size.height) * 0.47

            for index in 1 ... 22 {
                let t = Double(index) / 22.0
                let latitude = -0.42 + t * 0.84
                let cosLat = max(0.12, cos(latitude * .pi * 0.86))
                let rx = maxR * cosLat
                let ry = maxR * 0.11
                let wobble = sin(phase * 2.4 + t * 8.4) * maxR * 0.018
                let rect = CGRect(
                    x: cx - rx + wobble,
                    y: cy + latitude * maxR * 1.55 - ry * 0.5,
                    width: rx * 2,
                    height: ry * 2
                )
                let alpha = (0.14 - t * 0.05) * (0.75 + 0.25 * glowPulse)
                context.stroke(
                    Path(ellipseIn: rect),
                    with: .color(BrandTheme.nebulaCyan.opacity(alpha)),
                    lineWidth: 0.55
                )
                if index.isMultiple(of: 3) {
                    context.stroke(
                        Path(ellipseIn: rect.insetBy(dx: 2.5, dy: 0.8)),
                        with: .color(BrandTheme.nebulaLavender.opacity(alpha * 0.55)),
                        lineWidth: 0.35
                    )
                }
            }

            for index in 0 ..< 9 {
                let angle = Double(index) / 9.0 * .pi * 2 + phase * 0.62
                let rx = maxR * 0.78
                var arc = Path()
                arc.addArc(
                    center: CGPoint(x: cx, y: cy),
                    radius: rx,
                    startAngle: .radians(angle - 0.55),
                    endAngle: .radians(angle + 0.55),
                    clockwise: false
                )
                context.stroke(
                    arc,
                    with: .color(BrandTheme.nebulaPeach.opacity(0.08 * glowPulse)),
                    lineWidth: 0.65
                )
            }
        }
        .allowsHitTesting(false)
    }
}

private struct NoteStalgiaOrbDustLayer: View {
    var diameter: CGFloat
    var phase: Double
    var glowPulse: Double

    private struct DustMote {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let driftX: Double
        let driftY: Double
        let twinkle: Double
        let tone: Int
        let halo: Bool
    }

    private let motes: [DustMote] = {
        var gen = SplitMix64Orb(seed: 0xD057_4A71)
        return (0..<58).map { i in
            let angle = CGFloat.random(in: 0 ... (.pi * 2), using: &gen)
            let radius = CGFloat.random(in: 0.08 ... 0.47, using: &gen)
            return DustMote(
                x: 0.5 + cos(angle) * radius,
                y: 0.5 + sin(angle) * radius,
                size: CGFloat.random(in: 0.6...2.4, using: &gen),
                driftX: Double.random(in: 0.6...2.8, using: &gen),
                driftY: Double.random(in: 0.5...2.4, using: &gen),
                twinkle: Double.random(in: 1.4...4.8, using: &gen) + Double(i) * 0.07,
                tone: Int.random(in: 0...3, using: &gen),
                halo: Bool.random(using: &gen)
            )
        }
    }()

    var body: some View {
        Canvas { context, size in
            for mote in motes {
                let driftX = sin(phase * mote.driftX + Double(mote.x * 10)) * size.width * 0.018
                let driftY = cos(phase * mote.driftY + Double(mote.y * 12)) * size.height * 0.016
                let tw = (0.18 + 0.82 * pow(sin(phase * mote.twinkle), 2)) * glowPulse
                let cx = mote.x * size.width + driftX
                let cy = mote.y * size.height + driftY
                let r = mote.size
                let rect = CGRect(x: cx - r / 2, y: cy - r / 2, width: r, height: r)
                let color = dustColor(tone: mote.tone)

                if mote.halo {
                    let haloRect = rect.insetBy(dx: -r * 0.9, dy: -r * 0.9)
                    context.fill(
                        Path(ellipseIn: haloRect),
                        with: .color(color.opacity(tw * 0.22))
                    )
                }

                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(tw)))
            }
        }
        .blur(radius: max(0.3, diameter * 0.0018))
        .allowsHitTesting(false)
    }

    private func dustColor(tone: Int) -> Color {
        switch tone {
        case 0: BrandTheme.nebulaCyan
        case 1: BrandTheme.nebulaLavender
        case 2: BrandTheme.nebulaPeach
        default: .white
        }
    }
}

private struct NoteStalgiaOrbSparkles: View {
    var diameter: CGFloat
    var phase: Double
    var glowPulse: Double = 0.72

    private struct Dot {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let twinkle: Double
        let drift: Double
        let tone: Int
    }

    private let dots: [Dot] = {
        var gen = SplitMix64Orb(seed: 0xB075_7416)
        var result: [Dot] = (0..<42).map { i in
            let angle = CGFloat.random(in: 0 ... (.pi * 2), using: &gen)
            let radius = CGFloat.random(in: 0.30 ... 0.49, using: &gen)
            return Dot(
                x: 0.5 + cos(angle) * radius,
                y: 0.5 + sin(angle) * radius,
                size: CGFloat.random(in: 1.2...3.8, using: &gen),
                twinkle: Double.random(in: 1.6...5.2, using: &gen) + Double(i) * 0.09,
                drift: Double.random(in: 0.8...3.0, using: &gen),
                tone: Int.random(in: 0...2, using: &gen)
            )
        }
        result += (0..<18).map { i in
            Dot(
                x: CGFloat.random(in: 0.22...0.78, using: &gen),
                y: CGFloat.random(in: 0.22...0.78, using: &gen),
                size: CGFloat.random(in: 0.8...2.2, using: &gen),
                twinkle: Double.random(in: 2.0...6.0, using: &gen) + Double(i) * 0.13,
                drift: Double.random(in: 1.2...3.6, using: &gen),
                tone: Int.random(in: 0...3, using: &gen)
            )
        }
        return result
    }()

    var body: some View {
        Canvas { context, size in
            for dot in dots {
                let tw = (0.32 + 0.68 * pow(sin(phase * dot.twinkle), 2)) * glowPulse
                let driftX = sin(phase * dot.drift + Double(dot.x * 8)) * 3.5
                let driftY = cos(phase * dot.drift * 1.1 + Double(dot.y * 9)) * 3.0
                let cx = dot.x * size.width + driftX
                let cy = dot.y * size.height + driftY
                let r = dot.size
                let rect = CGRect(x: cx - r / 2, y: cy - r / 2, width: r, height: r)
                let color: Color = switch dot.tone {
                case 0: BrandTheme.nebulaCyan
                case 1: BrandTheme.nebulaLavender
                case 2: BrandTheme.nebulaPeach
                default: .white
                }

                if r > 2.0 {
                    let halo = rect.insetBy(dx: -r * 0.7, dy: -r * 0.7)
                    context.fill(Path(ellipseIn: halo), with: .color(color.opacity(tw * 0.25)))
                }
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(tw)))
            }
        }
        .allowsHitTesting(false)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var bounds: CGFloat { min(width, height) }

    private var baseDiameter: CGFloat { min(width, height) }

    private var diameter: CGFloat { baseDiameter * shellScale }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(anchor)
            let swirl = reduceMotion ? 0 : elapsed * 0.95
            let breathe = OrbHeartbeat.breatheScale(forPulse: pulse)
            let glowStrength = min(1.35, shellGlowScale)
            let ringExpansion = OrbReferenceMotion.ringExpansion(at: elapsed)
            let wispDrift = OrbReferenceMotion.wispDrift(at: elapsed)

            ZStack {
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
                color: BrandTheme.nebulaPeach.opacity(0.16 * glowPulse * Double(glowStrength)),
                radius: bounds * 0.10,
                y: bounds * 0.015
            )
            .shadow(
                color: BrandTheme.nebulaMagenta.opacity(0.24 * glowPulse * Double(glowStrength)),
                radius: bounds * 0.08,
                y: bounds * 0.02
            )
            .shadow(
                color: BrandTheme.nebulaCyan.opacity(0.28 * glowPulse * Double(glowStrength)),
                radius: bounds * 0.10,
                y: -bounds * 0.01
            )
        }
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

private struct SplitMix64Orb: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xBADC0FFE : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return z
    }
}
