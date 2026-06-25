import SwiftUI

extension View {
    /// High-contrast orb copy with a dark halo for legibility on the nebula.
    func orbOverlayTextStyle(intensity: CGFloat = 1) -> some View {
        let i = max(0.55, intensity)
        return shadow(color: Color.black.opacity(0.58 * i), radius: 1.5 * i, x: 0, y: 1)
            .shadow(color: BrandTheme.nebulaDeep.opacity(0.62 * i), radius: 3 * i, x: 0, y: 2)
            .shadow(color: Color(white: 0.18, opacity: 0.48 * i), radius: 6 * i, x: 0, y: 0)
            .shadow(color: Color(white: 0.32, opacity: 0.30 * i), radius: 14 * i, x: 0, y: 0)
    }

    func orbOverlayText(muted: Bool = false, intensity: CGFloat = 1) -> some View {
        foregroundStyle(muted ? BrandTheme.textOnOrbMuted : BrandTheme.textOnOrb)
            .orbOverlayTextStyle(intensity: muted ? intensity * 0.94 : intensity)
    }
}
