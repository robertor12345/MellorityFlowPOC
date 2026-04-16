import SwiftUI

/// Animated logo splash on cold launch — transitions into `FlowRootView`.
struct SplashScreenView: View {
    var onComplete: () -> Void

    @State private var logoIn = false
    @State private var titleIn = false
    @State private var glowPulse = false
    @State private var exitFade = false

    var body: some View {
        ZStack {
            BrandBackground()

            RadialGradient(
                colors: [
                    BrandTheme.goldSoft.opacity(glowPulse ? 0.35 : 0.18),
                    Color.clear,
                ],
                center: .center,
                startRadius: 40,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                MellorityLogoImage(maxHeight: 150)
                    .scaleEffect(logoIn ? 1 : 0.78)
                    .opacity(logoIn ? 1 : 0)

                Text("Mellority")
                    .font(BrandTheme.title(.largeTitle))
                    .foregroundStyle(BrandTheme.brown)
                    .opacity(titleIn ? 1 : 0)
                    .offset(y: titleIn ? 0 : 14)
            }
        }
        .opacity(exitFade ? 0 : 1)
        .task {
            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.spring(response: 0.78, dampingFraction: 0.78, blendDuration: 0)) {
                logoIn = true
            }
            withAnimation(.easeOut(duration: 0.55).delay(0.12)) {
                glowPulse = true
            }
            try? await Task.sleep(nanoseconds: 320_000_000)
            withAnimation(.easeOut(duration: 0.55)) {
                titleIn = true
            }
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            withAnimation(.easeInOut(duration: 0.5)) {
                exitFade = true
            }
            try? await Task.sleep(nanoseconds: 520_000_000)
            onComplete()
        }
    }
}
