import SwiftUI

/// PlayStation-style warm gold ambient particles: brighter, irregular multi-frequency drift, subtle twinkle.
struct GoldAmbientSparklesView: View {
    var intensity: CGFloat = 1
    var lightBackdrop: Bool = true

    private struct Particle: Identifiable {
        let id: Int
        let xFrac: CGFloat
        let yFrac: CGFloat
        let radius: CGFloat
        let driftAmplitude: CGFloat
        let driftSpeed: Double
        let driftSpeedY: Double
        let phase: CGFloat
        let twinkleSpeed: Double
        let baseOpacity: CGFloat
        /// Second-frequency multiplier (irrational-ish drift).
        let wobbleFreq: Double
        let wobblePhase: CGFloat
        let jitterAmp: CGFloat
        let curl: Double
    }

    private let particles: [Particle]

    init(particleCount: Int = 112, intensity: CGFloat = 1, lightBackdrop: Bool = true) {
        self.intensity = intensity
        self.lightBackdrop = lightBackdrop
        var gen = SplitMix64(seed: 0xF10C_B0C5)
        particles = (0..<particleCount).map { i in
            Particle(
                id: i,
                xFrac: CGFloat.random(in: 0...1, using: &gen),
                yFrac: CGFloat.random(in: 0...1, using: &gen),
                radius: CGFloat.random(in: 0.9...5.2, using: &gen),
                driftAmplitude: CGFloat.random(in: 24...118, using: &gen),
                driftSpeed: Double.random(in: 0.09...0.38, using: &gen),
                driftSpeedY: Double.random(in: 0.07...0.34, using: &gen),
                phase: CGFloat.random(in: 0...(CGFloat.pi * 2), using: &gen),
                twinkleSpeed: Double.random(in: 0.65...3.1, using: &gen),
                baseOpacity: CGFloat.random(in: 0.42...0.98, using: &gen),
                wobbleFreq: Double.random(in: 1.47...3.19, using: &gen),
                wobblePhase: CGFloat.random(in: 0...(CGFloat.pi * 2), using: &gen),
                jitterAmp: CGFloat.random(in: 3.5...18, using: &gen),
                curl: Double.random(in: 0.2...0.75, using: &gen)
            )
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 50, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let haze = CGRect(origin: .zero, size: size)
                let hazeColors: [Color] = lightBackdrop
                    ? [
                        BrandTheme.goldSoft.opacity(0.34 * Double(intensity)),
                        BrandTheme.gold.opacity(0.12 * Double(intensity)),
                        BrandTheme.creamMid.opacity(0.04 * Double(intensity)),
                        .clear,
                    ]
                    : [
                        Color(red: 0.18, green: 0.14, blue: 0.06).opacity(0.42 * Double(intensity)),
                        .clear,
                    ]
                context.fill(
                    Path(ellipseIn: haze),
                    with: .radialGradient(
                        Gradient(colors: hazeColors),
                        center: CGPoint(x: size.width * 0.5, y: size.height * 0.35),
                        startRadius: size.width * 0.08,
                        endRadius: max(size.width, size.height) * 0.72
                    )
                )

                for p in particles {
                    let fx = t * p.driftSpeed + Double(p.phase)
                    let fy = t * p.driftSpeedY * 1.13 + Double(p.phase) * 1.37
                    let wobbleX =
                        sin(fx) * Double(p.driftAmplitude)
                        + sin(t * p.driftSpeed * p.wobbleFreq + Double(p.wobblePhase)) * Double(p.driftAmplitude) * p.curl
                        + sin(t * 0.27 + Double(p.id) * 0.91) * Double(p.jitterAmp)
                    let wobbleY =
                        cos(fy) * Double(p.driftAmplitude * 0.82)
                        + cos(t * p.driftSpeedY * p.wobbleFreq * 0.88 + Double(p.wobblePhase) * 1.3) * Double(p.driftAmplitude) * 0.5
                        + sin(t * 0.19 + Double(p.id) * 0.47) * Double(p.jitterAmp * 0.7)
                    let cx = p.xFrac * size.width + CGFloat(wobbleX)
                    let cy = p.yFrac * size.height + CGFloat(wobbleY)
                    let tw = 0.38 + 0.62 * pow(sin(t * p.twinkleSpeed + Double(p.id) * 0.37), 2)
                    let op = p.baseOpacity * CGFloat(tw) * intensity

                    let core = CGRect(
                        x: cx - p.radius * 0.4,
                        y: cy - p.radius * 0.4,
                        width: p.radius * 0.8,
                        height: p.radius * 0.8
                    )
                    context.fill(
                        Path(ellipseIn: core),
                        with: .color(Color(red: 1, green: 0.96, blue: 0.78).opacity(min(1, Double(op * 1.08))))
                    )

                    let glow = CGRect(
                        x: cx - p.radius * 2.5,
                        y: cy - p.radius * 2.5,
                        width: p.radius * 5,
                        height: p.radius * 5
                    )
                    context.fill(
                        Path(ellipseIn: glow),
                        with: .radialGradient(
                            Gradient(colors: [
                                Color(red: 1, green: 0.84, blue: 0.42).opacity(Double(min(0.95, op * 0.72))),
                                Color(red: 0.9, green: 0.58, blue: 0.12).opacity(Double(op * 0.22)),
                                Color(red: 0.45, green: 0.32, blue: 0.05).opacity(Double(op * 0.08)),
                                .clear,
                            ]),
                            center: CGPoint(x: cx, y: cy),
                            startRadius: 0,
                            endRadius: p.radius * 3.4
                        )
                    )
                }
            }
            .blur(radius: 0.35)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xBADC0FFE : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return z
    }
}
