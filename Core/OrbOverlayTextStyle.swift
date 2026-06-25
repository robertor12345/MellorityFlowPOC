import SwiftUI

extension BrandTheme {
    /// Copy sitting directly on the nebula orb — white type with a soft grey halo.
    static let orbOverlayText = Color.white
}

extension View {
    /// White copy with a light faded grey shadow for legibility on the orb.
    func orbOverlayTextStyle(intensity: CGFloat = 1) -> some View {
        let i = max(0.5, intensity)
        return shadow(color: Color(white: 0.38, opacity: 0.38 * i), radius: 2 * i, x: 0, y: 1)
            .shadow(color: Color(white: 0.48, opacity: 0.24 * i), radius: 8 * i, x: 0, y: 0)
            .shadow(color: Color(white: 0.55, opacity: 0.14 * i), radius: 16 * i, x: 0, y: 0)
    }

    func orbOverlayText(muted: Bool = false, intensity: CGFloat = 1) -> some View {
        foregroundStyle(BrandTheme.orbOverlayText.opacity(muted ? 0.88 : 1))
            .orbOverlayTextStyle(intensity: muted ? intensity * 0.92 : intensity)
    }
}
