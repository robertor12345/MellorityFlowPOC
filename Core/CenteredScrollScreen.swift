import SwiftUI

/// Scrollable column that is **vertically and horizontally centered** when content is shorter than the safe area; scrolls when content is taller.
struct CenteredScrollScreen<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var backTitle: String = "Back"
    var backAccessibilityLabel: String?
    var onBack: (() -> Void)?
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    content()
                        .frame(maxWidth: BrandLayout.menuColumnMaxWidth)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, BrandLayout.contentGutter(for: horizontalSizeClass))
                    Spacer(minLength: 0)
                }
                .frame(minWidth: geo.size.width, minHeight: geo.size.height)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if let onBack {
                    FlowTopBackBar(
                        title: backTitle,
                        accessibilityLabel: backAccessibilityLabel,
                        action: onBack
                    )
                }
            }
        }
    }
}
