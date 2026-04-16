import SwiftUI

/// Extended launch sequence — PS5-style gold wash, then hands off to the flow.
struct LaunchIntroView: View {
    var onFinished: () -> Void

    @State private var didFinish = false
    @State private var anchor = Date()
    /// Total runtime before calling `onFinished` (seconds).
    private let totalDuration: Double = 11.5

    var body: some View {
        ZStack {
            // Clear so parent `AppRootView` gradient + gold sparkles stay visible (no cream sheet hiding them).
            Color.clear
                .ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(anchor)
                let fadeOut = min(1, max(0, (elapsed - (totalDuration - 1.2)) / 1.2))

                VStack(spacing: 28) {
                    Spacer(minLength: 0)

                    Text("Mellority")
                        .font(.system(size: 44, weight: .thin, design: .rounded))
                        .tracking(10)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    BrandTheme.brown,
                                    BrandTheme.goldDeep,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(titleOpacity(elapsed: elapsed))
                        .scaleEffect(titleScale(elapsed: elapsed))

                    Text("Wellness audio, refined.")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(BrandTheme.brown)
                        .opacity(subtitleOpacity(elapsed: elapsed))
                        .offset(y: subtitleOffset(elapsed: elapsed))

                    if elapsed > 4.2 {
                        Text("Settle in. Your space is preparing.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.brownMuted)
                            .opacity(lineOpacity(elapsed: elapsed))
                            .padding(.top, 6)
                    }

                    Spacer(minLength: 0)

                    progressBar(progress: min(1, elapsed / totalDuration))
                        .padding(.horizontal, 36)
                        .padding(.bottom, 52)
                        .opacity(bottomChromeOpacity(elapsed: elapsed))
                }
                .opacity(1 - fadeOut)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            finish()
        }
        .onAppear {
            anchor = Date()
        }
        .task {
            try? await Task.sleep(nanoseconds: UInt64(totalDuration * 1_000_000_000))
            await MainActor.run {
                finish()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mellority is starting.")
        .accessibilityHint("Tap to skip.")
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }

    private func titleOpacity(elapsed: TimeInterval) -> Double {
        if elapsed < 0.8 { return min(1, elapsed / 0.8) }
        return 1
    }

    private func titleScale(elapsed: TimeInterval) -> CGFloat {
        if elapsed < 1.4 {
            let t = CGFloat(elapsed / 1.4)
            return 0.94 + 0.06 * easeOutCubic(t)
        }
        return 1
    }

    private func subtitleOpacity(elapsed: TimeInterval) -> Double {
        if elapsed < 2 { return 0 }
        if elapsed < 3.6 { return (elapsed - 2) / 1.6 }
        return 1
    }

    private func subtitleOffset(elapsed: TimeInterval) -> CGFloat {
        if elapsed < 3.6 { return CGFloat(12 - (elapsed - 2) * 8) }
        return 0
    }

    private func lineOpacity(elapsed: TimeInterval) -> Double {
        if elapsed < 5 { return 0 }
        if elapsed < 7 { return (elapsed - 5) / 2 }
        return 1
    }

    private func bottomChromeOpacity(elapsed: TimeInterval) -> Double {
        if elapsed < 1 { return 0 }
        return min(1, (elapsed - 1) / 2)
    }

    private func easeOutCubic(_ t: CGFloat) -> CGFloat {
        let u = 1 - t
        return 1 - u * u * u
    }

    private func progressBar(progress: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(BrandTheme.brown.opacity(0.12))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.78, blue: 0.28),
                                Color(red: 0.75, green: 0.55, blue: 0.12),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(6, geo.size.width * progress))
                    .shadow(color: Color(red: 0.95, green: 0.8, blue: 0.35).opacity(0.45), radius: 6, y: 0)
            }
        }
        .frame(height: 4)
    }
}
