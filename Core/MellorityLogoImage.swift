import SwiftUI

/// Mellority mark from asset catalog — `original` mode keeps PNG transparency (no template tint, no box).
struct MellorityLogoImage: View {
    var maxHeight: CGFloat = 140

    var body: some View {
        Image("MellorityLogo")
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: maxHeight)
            .accessibilityLabel("Mellority")
    }
}
