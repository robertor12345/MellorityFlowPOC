import SwiftUI

/// Hosts a long PS5-style launch intro (gold sparkles + title), then mounts the main flow.
struct AppRootView: View {
    @State private var showLaunchIntro = true

    var body: some View {
        Group {
            if showLaunchIntro {
                ZStack {
                    BrandTheme.backgroundGradient
                        .ignoresSafeArea()

                    GoldAmbientSparklesView(intensity: 1.48, lightBackdrop: true)
                        .ignoresSafeArea()

                    LaunchIntroView {
                        showLaunchIntro = false
                    }
                    .transition(.opacity)
                }
                .transition(.opacity)
            } else {
                FlowRootView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.95), value: showLaunchIntro)
        .preferredColorScheme(.light)
        .environment(\.font, Font.system(.body, design: .rounded))
    }
}
