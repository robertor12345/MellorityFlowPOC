import CoreGraphics
import Foundation

/// Shared reference-video orb cadence (~10s swell loop) mapped into shell scale + glow.
enum OrbHeartbeat {
    static let beatsPerMinute: Double = 6
    static var beatPeriodSeconds: TimeInterval { OrbReferenceMotion.cycleSeconds }
    static var angularFrequency: Double { (2.0 * Double.pi) / beatPeriodSeconds }

    /// Peak shell scale — sized so `flowOrbPanelSize` × `maxVisualExtentScale` stays inside the viewport.
    static let maxShellScale: CGFloat = 1.055
    static let minShellScale: CGFloat = 0.965

    /// Exterior wisps, ripple rings, and glow sit outside the scaled shell diameter.
    static let visualHeadroom: CGFloat = 1.075

    static var maxVisualExtentScale: CGFloat { maxShellScale * visualHeadroom }

    static func pulse(at elapsed: TimeInterval, speedMultiplier: Double = 1) -> Double {
        OrbReferenceMotion.pulse(at: elapsed, speedMultiplier: speedMultiplier)
    }

    static func glow(at elapsed: TimeInterval, speedMultiplier: Double = 1) -> Double {
        OrbReferenceMotion.glow(at: elapsed, speedMultiplier: speedMultiplier)
    }

    static func shellScale(forPulse pulse: Double) -> CGFloat {
        minShellScale + (maxShellScale - minShellScale) * CGFloat(pulse)
    }

    static func innerContentScale(forPulse pulse: Double) -> CGFloat {
        0.992 + 0.008 * CGFloat(pulse)
    }

    static func breatheScale(forPulse pulse: Double) -> CGFloat {
        0.988 + 0.012 * CGFloat(pulse)
    }
}
