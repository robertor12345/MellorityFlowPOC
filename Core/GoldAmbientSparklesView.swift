import SwiftUI

/// PlayStation-style warm gold ambient particles: soft bloom, slow drift, subtle twinkle.
struct GoldAmbientSparklesView: View {
    /// Visual strength (boost during launch intro if desired).
    var intensity: CGFloat = 1

    private struct Particle: Identifiable {
        let id: Int
        let xFrac: CGFloat
        let yFrac: CGFloat
        let radius: CGFloat
        let driftAmplitude: CGFloat
        let driftSpeed: Double
        let phase: CGFloat
        let twinkleSpeed: Double
        let baseOpacity: CGFloat
    }

    private let particles: [Particle]

    init(particleCount: Int = 86, intensity: CGFloat = 1) {
        self.intensity = intensity
        var gen = SplitMix64(seed: 0xF10C_B0C5) // deterministic layout (POC)
        particles = (0..<particleCount).map { i in
            Particle(
                id: i,
                xFrac: CGFloat.random(in: 0...1, using: &gen),
                yFrac: CGFloat.random(in: 0...1, using: &gen),
                radius: CGFloat.random(in: 1.2...6, using: &gen),
                driftAmplitude: CGFloat.random(in: 8...56, using: &gen),
                driftSpeed: Double.random(in: 0.04...0.14, using: &gen),
                phase: CGFloat.random(in: 0...(CGFloat.pi * 2), using: &gen),
                twinkleSpeed: Double.random(in: 0.5...2.2, using: &gen),
                baseOpacity: CGFloat.random(in: 0.18...0.65, using: &gen)
            )
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 45, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let haze = CGRect(origin: .zero, size: size)
                context.fill(
                    Path(ellipseIn: haze),
                    with: .radialGradient(
                        Gradient(colors: [
                            Color(red: 0.18, green: 0.14, blue: 0.06).opacity(0.35 * Double(intensity)),
                            .clear,
                        ]),
                        center: CGPoint(x: size.width * 0.5, y: size.height * 0.35),
                        startRadius: size.width * 0.08,
                        endRadius: max(size.width, size.height) * 0.72
                    )
                )

                for p in particles {
                    let wobbleX = sin(t * p.driftSpeed + Double(p.phase)) * Double(p.driftAmplitude)
                    let wobbleY = cos(t * (p.driftSpeed * 0.85) + Double(p.phase) * 1.3) * Double(p.driftAmplitude * 0.75)
                    let cx = p.xFrac * size.width + CGFloat(wobbleX)
                    let cy = p.yFrac * size.height + CGFloat(wobbleY)
                    let tw = 0.42 + 0.58 * pow(sin(t * p.twinkleSpeed + Double(p.id) * 0.31), 2)
                    let op = p.baseOpacity * CGFloat(tw) * intensity

                    let core = CGRect(
                        x: cx - p.radius * 0.4,
                        y: cy - p.radius * 0.4,
                        width: p.radius * 0.8,
                        height: p.radius * 0.8
                    )
                    context.fill(
                        Path(ellipseIn: core),
                        with: .color(Color(red: 1, green: 0.94, blue: 0.72).opacity(Double(op)))
                    )

                    let glow = CGRect(
                        x: cx - p.radius * 2.4,
                        y: cy - p.radius * 2.4,
                        width: p.radius * 4.8,
                        height: p.radius * 4.8
                    )
                    context.fill(
                        Path(ellipseIn: glow),
                        with: .radialGradient(
                            Gradient(colors: [
                                Color(red: 0.96, green: 0.78, blue: 0.35).opacity(Double(op * 0.55)),
                                Color(red: 0.55, green: 0.38, blue: 0.08).opacity(Double(op * 0.08)),
                                .clear,
                            ]),
                            center: CGPoint(x: cx, y: cy),
                            startRadius: 0,
                            endRadius: p.radius * 3.2
                        )
                    )
                }
            }
            .blur(radius: 0.6)
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
