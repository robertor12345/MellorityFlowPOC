import SwiftUI

/// App shell — persistent orb navigation lives in `FlowRootView`.
struct AppRootView: View {
    var body: some View {
        FlowRootView()
            .preferredColorScheme(.light)
            .environment(\.font, Font.system(.body, design: .rounded))
            .task {
                // Warm the shared audio session so the first chime/music plays without delay.
                AppAudioSession.activate()
            }
    }
}
