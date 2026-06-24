import SwiftUI

enum OrbContentTopInset: Equatable {
    case menuStandard
    case none
}

struct OrbNavigationStyle: Equatable {
    var pulseMode: OrbPulseMode
    var floats: Bool
    var showsMenuEnvelope: Bool
    var contentTopInset: OrbContentTopInset = .menuStandard
    var envelopeScale: CGFloat = 1.0

    static func forPhase(
        _ phase: FlowPhase,
        launchActive: Bool,
        isResidentSession: Bool = false
    ) -> OrbNavigationStyle {
        _ = launchActive
        _ = isResidentSession

        switch phase {
        case .immersive, .careDiscoveryCalibration, .residentProfile,
             .sessionSettling, .residentFaceIDWelcome:
            return OrbNavigationStyle(
                pulseMode: .calm,
                floats: false,
                showsMenuEnvelope: false,
                contentTopInset: .none
            )
        default:
            return OrbNavigationStyle(
                pulseMode: .calm,
                floats: false,
                showsMenuEnvelope: false,
                contentTopInset: .menuStandard
            )
        }
    }

    func envelopePadding(in size: CGSize, launchActive: Bool = false) -> (horizontal: CGFloat, vertical: CGFloat) {
        BrandLayout.panelEnvelopePadding(in: size)
    }

    func resolvedContentTopInset(safeTop: CGFloat) -> CGFloat {
        switch contentTopInset {
        case .menuStandard:
            safeTop + 8
        case .none:
            0
        }
    }
}
