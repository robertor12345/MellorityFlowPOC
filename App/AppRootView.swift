import SwiftUI

/// Hosts splash animation, then the main flow (single load of `FlowRootView` behind for a smooth handoff).
struct AppRootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            FlowRootView()

            if showSplash {
                SplashScreenView {
                    showSplash = false
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: showSplash)
        .environment(\.font, Font.system(.body, design: .rounded))
        .preferredColorScheme(.light)
    }
}
