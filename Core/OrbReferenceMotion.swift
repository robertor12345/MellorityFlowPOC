import CoreGraphics
import Foundation

/// Smooth symmetric orb motion — meditative 3s inhale / 3s exhale (`OrbHeartbeat.breatheCycleSeconds`).
enum OrbReferenceMotion {
    static var cycleSeconds: TimeInterval { OrbHeartbeat.breatheCycleSeconds }

    /// Inhale 0→1 over first half of cycle, exhale 1→0 over second half.
    private static func symmetricBreathe(unit u: Double) -> Double {
        0.5 - 0.5 * cos(2 * Double.pi * u)
    }

    static func pulse(at elapsed: TimeInterval, speedMultiplier: Double = 1) -> Double {
        symmetricBreathe(unit: phaseUnit(elapsed: elapsed, speedMultiplier: speedMultiplier))
    }

    static func glow(at elapsed: TimeInterval, speedMultiplier: Double = 1) -> Double {
        let breathe = symmetricBreathe(unit: phaseUnit(elapsed: elapsed, speedMultiplier: speedMultiplier))
        return 0.56 + 0.44 * breathe
    }

    static func ringExpansion(at elapsed: TimeInterval, speedMultiplier: Double = 1) -> Double {
        let breathe = symmetricBreathe(unit: phaseUnit(elapsed: elapsed, speedMultiplier: speedMultiplier))
        return 0.92 + 0.08 * breathe
    }

    static func wispDrift(at elapsed: TimeInterval, speedMultiplier: Double = 1) -> Double {
        sin(elapsed * speedMultiplier * (2.0 * Double.pi / cycleSeconds) * 1.15)
    }

    private static func phaseUnit(elapsed: TimeInterval, speedMultiplier: Double) -> Double {
        let scaled = elapsed * speedMultiplier
        let mod = scaled.truncatingRemainder(dividingBy: cycleSeconds)
        return mod / cycleSeconds
    }
}
