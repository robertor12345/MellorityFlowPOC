import SwiftUI

/// Drifting leaves with wind-like motion (visual only).
struct LeafBreezeLayer: View {
    private let count = 22

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            TimelineView(.animation(minimumInterval: 1.0 / 45)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(0 ..< count, id: \.self) { i in
                        leafView(i: i, t: t, w: w, h: h)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func leafView(i: Int, t: Double, w: CGFloat, h: CGFloat) -> some View {
        let seed = Double(i)
        let size = CGFloat(16 + (i % 6) * 7)
        let speed = 0.08 + 0.02 * (seed.truncatingRemainder(dividingBy: 3))
        let progress = (t * speed + seed * 0.31).truncatingRemainder(dividingBy: 1.0)
        let x = progress * (w + 100) - 50 + sin(t * 0.4 + seed) * 12
        let baseY = h * (0.12 + CGFloat((seed * 0.07).truncatingRemainder(dividingBy: 1.0)) * 0.76)
        let flutter = sin(t * 2.2 + seed * 1.7) * 18
        let y = baseY + flutter
        let roll = sin(t * 1.8 + seed) * 22 + sin(t * 3.1 + seed * 0.5) * 8
        let sway = cos(t * 1.1 + seed) * 14
        let opacity = 0.35 + 0.4 * (0.5 + 0.5 * sin(t * 0.9 + seed))

        Image(systemName: "leaf.fill")
            .font(.system(size: size))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        BrandTheme.goldSoft.opacity(0.95),
                        BrandTheme.goldDeep.opacity(0.85),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: BrandTheme.brown.opacity(0.25), radius: 2, y: 1)
            .rotationEffect(.degrees(55 + roll + sway))
            .opacity(opacity)
            .position(x: x, y: y)
    }
}
