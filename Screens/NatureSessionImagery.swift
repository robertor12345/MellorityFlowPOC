import SwiftUI

/// Layered session backdrop: sky, soft light, mountains, water, drifting leaves, and light nature symbols.
struct NatureSessionImagery: View {
    var body: some View {
        ZStack {
            SessionSkyAndMist()
            NatureAmbientOrbs()
            MountainSilhouetteStack()
            LakeWaterStack()
            NatureSymbolDrift()
            LeafBreezeLayer(leafCount: 16)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Sky

private struct SessionSkyAndMist: View {
    var body: some View {
        ZStack {
            BrandTheme.sessionNatureSkyGradient
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.white.opacity(0.45),
                    Color.clear,
                    Color(red: 0.55, green: 0.72, blue: 0.68).opacity(0.12),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Horizon mist
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.35),
                        Color.white.opacity(0.12),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .blur(radius: 18)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Soft orbs (forest / water light)

private struct NatureAmbientOrbs: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0 ..< 8, id: \.self) { i in
                    let colors: [Color] = [
                        Color(red: 0.55, green: 0.75, blue: 0.82),
                        Color(red: 0.70, green: 0.82, blue: 0.72),
                        BrandTheme.goldSoft,
                        Color(red: 0.78, green: 0.72, blue: 0.88),
                    ]
                    let c = colors[i % colors.count]
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [c.opacity(0.22 + 0.06 * sin(t * 0.9 + Double(i))), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 90 + CGFloat(i * 18)
                            )
                        )
                        .frame(width: 180 + CGFloat(i * 28), height: 180 + CGFloat(i * 28))
                        .offset(
                            x: CGFloat(sin(t * 0.35 + Double(i) * 0.7)) * (38 + CGFloat(i * 5)),
                            y: CGFloat(cos(t * 0.28 + Double(i) * 0.55)) * (48 + CGFloat(i * 4))
                        )
                        .blur(radius: 22)
                }
            }
        }
    }
}

// MARK: - Mountains

private struct MountainSilhouetteStack: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let drift = CGFloat(sin(t * 0.06)) * 14
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack(alignment: .bottom) {
                    // Distant range
                    BackMountainRange(drift: drift * 0.35)
                        .frame(width: w, height: h * 0.52)
                        .opacity(0.72)

                    // Nearer, darker range
                    FrontMountainRange(drift: drift)
                        .frame(width: w, height: h * 0.48)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}

private struct BackMountainRange: View {
    var drift: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let o = drift
            Path { p in
                p.move(to: CGPoint(x: -60 + o, y: h + 8))
                p.addLine(to: CGPoint(x: w * 0.06 + o, y: h * 0.62))
                p.addLine(to: CGPoint(x: w * 0.22 + o, y: h * 0.38))
                p.addLine(to: CGPoint(x: w * 0.42 + o, y: h * 0.52))
                p.addLine(to: CGPoint(x: w * 0.62 + o, y: h * 0.32))
                p.addLine(to: CGPoint(x: w * 0.82 + o, y: h * 0.48))
                p.addLine(to: CGPoint(x: w + 60 + o, y: h * 0.58))
                p.addLine(to: CGPoint(x: w + 60 + o, y: h + 8))
                p.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.42, green: 0.52, blue: 0.48).opacity(0.55),
                        Color(red: 0.24, green: 0.34, blue: 0.30).opacity(0.85),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

private struct FrontMountainRange: View {
    var drift: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let o = drift
            Path { p in
                p.move(to: CGPoint(x: -50 + o, y: h + 6))
                p.addLine(to: CGPoint(x: w * 0.04 + o, y: h * 0.55))
                p.addLine(to: CGPoint(x: w * 0.18 + o, y: h * 0.72))
                p.addLine(to: CGPoint(x: w * 0.34 + o, y: h * 0.42))
                p.addLine(to: CGPoint(x: w * 0.50 + o, y: h * 0.58))
                p.addLine(to: CGPoint(x: w * 0.66 + o, y: h * 0.36))
                p.addLine(to: CGPoint(x: w * 0.80 + o, y: h * 0.52))
                p.addLine(to: CGPoint(x: w + 50 + o, y: h * 0.62))
                p.addLine(to: CGPoint(x: w + 50 + o, y: h + 6))
                p.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.22, green: 0.32, blue: 0.28),
                        Color(red: 0.10, green: 0.16, blue: 0.15),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - Water

private struct LakeWaterStack: View {
    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack(alignment: .bottom) {
                    LakeBandShape(phase: t * 1.1, secondary: false)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.68, blue: 0.72).opacity(0.38),
                                    Color(red: 0.28, green: 0.45, blue: 0.55).opacity(0.52),
                                    Color(red: 0.18, green: 0.32, blue: 0.42).opacity(0.65),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: h * 0.40)
                        .offset(y: 6)

                    LakeBandShape(phase: t * 1.35 + 1.7, secondary: true)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.14),
                                    Color(red: 0.5, green: 0.75, blue: 0.78).opacity(0.22),
                                    Color.clear,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: h * 0.22)
                        .blur(radius: 2)
                        .offset(y: -h * 0.06)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}

private struct LakeBandShape: Shape {
    var phase: Double
    var secondary: Bool

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let bottom = rect.maxY
        let steps = 56
        let amp1: CGFloat = secondary ? 4 : 7
        let amp2: CGFloat = secondary ? 2.5 : 4

        var topPoints: [CGPoint] = []
        for i in 0 ... steps {
            let xf = CGFloat(i) / CGFloat(steps)
            let x = xf * rect.width
            let w1 = sin(Double(xf) * Double.pi * (secondary ? 9 : 7) + phase * (secondary ? 1.4 : 1.0))
            let w2 = sin(phase * 0.9 + Double(xf) * 4.2)
            let y = rect.minY + CGFloat(w1) * amp1 + CGFloat(w2) * amp2
            topPoints.append(CGPoint(x: x, y: y))
        }

        path.move(to: CGPoint(x: 0, y: bottom))
        path.addLine(to: CGPoint(x: 0, y: topPoints[0].y))
        for pt in topPoints {
            path.addLine(to: pt)
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: bottom))
        path.closeSubpath()
        return path
    }
}

// MARK: - Small drifting nature symbols (water · mountains · trees · leaves)

private struct NatureSymbolDrift: View {
    private let symbols = [
        "drop.fill",
        "water.waves",
        "mountain.2.fill",
        "tree.fill",
        "leaf.fill",
        "cloud.fill",
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            TimelineView(.animation(minimumInterval: 1.0 / 35)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(0 ..< symbols.count, id: \.self) { i in
                        let seed = Double(i)
                        let slow = 0.04 + 0.015 * (seed.truncatingRemainder(dividingBy: 3))
                        let px = (t * slow + seed * 0.4).truncatingRemainder(dividingBy: 1.0)
                        let x = px * (w + 80) - 40 + sin(t * 0.35 + seed) * 20
                        let baseY = h * (0.18 + CGFloat((seed * 0.11).truncatingRemainder(dividingBy: 1.0)) * 0.62)
                        let flutter = sin(t * 1.8 + seed * 2) * 16
                        let sz: CGFloat = 14 + CGFloat(i % 4) * 5
                        let op = 0.14 + 0.12 * (0.5 + 0.5 * sin(t * 0.7 + seed))

                        Image(systemName: symbols[i])
                            .font(.system(size: sz))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.55, green: 0.70, blue: 0.78).opacity(0.95),
                                        BrandTheme.goldSoft.opacity(0.75),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(op)
                            .rotationEffect(.degrees(sin(t * 0.9 + seed) * 10))
                            .position(x: x, y: baseY + flutter)
                    }
                }
            }
        }
    }
}
