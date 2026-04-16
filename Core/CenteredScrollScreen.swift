import SwiftUI

/// Scrollable column that is **vertically and horizontally centered** when content is shorter than the safe area; scrolls when content is taller.
struct CenteredScrollScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    content()
                        .frame(maxWidth: .infinity)
                    Spacer(minLength: 0)
                }
                .frame(minWidth: geo.size.width, minHeight: geo.size.height)
            }
        }
    }
}
