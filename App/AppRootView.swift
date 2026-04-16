import SwiftUI

/// Hosts a long PS5-style launch intro (gold sparkles + title), then mounts the main flow.
struct AppRootView: View {
    @State private var showLaunchIntro = true

    var body: some View {
        Group {
            if showLaunchIntro {
                ZStack {
                    Color(red: 0.04, green: 0.04, blue: 0.05)
                        .ignoresSafeArea()

                    GoldAmbientSparklesView(intensity: 1.22)
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
        .preferredColorScheme(showLaunchIntro ? .dark : .light)
        .environment(\.font, Font.system(.body, design: .rounded))
    }
}
