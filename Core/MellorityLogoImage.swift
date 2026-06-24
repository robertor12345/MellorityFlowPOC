import SwiftUI

/// NoteStalgia mark from asset catalog — full logo (orb + wordmark).
struct MellorityLogoImage: View {
    var maxHeight: CGFloat = 420

    var body: some View {
        Image("MellorityLogo")
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: maxHeight)
            .accessibilityLabel("NoteStalgia")
    }
}
