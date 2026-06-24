import SwiftUI

/// App shell — persistent orb navigation lives in `FlowRootView`.
struct AppRootView: View {
    var body: some View {
        FlowRootView()
            .preferredColorScheme(.light)
            .environment(\.font, Font.system(.body, design: .rounded))
    }
}
