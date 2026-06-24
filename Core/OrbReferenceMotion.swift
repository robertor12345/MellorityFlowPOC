import CoreGraphics
import Foundation

/// Pulse + glow sampled from the reference orb video (~10.04s loop).
enum OrbReferenceMotion {
    static let cycleSeconds: TimeInterval = 10.04166666666667

    /// Normalized swell — orb radius grows from ~354px to ~433px across the clip.
    private static let pulseKeyframes: [(time: Double, value: Double)] = [
        (0.000, 0.00), (0.084, 0.18), (0.167, 0.18), (0.251, 0.05),
        (0.335, 0.35), (0.418, 0.51), (0.502, 0.51), (0.586, 0.67),
        (0.669, 0.75), (0.753, 0.84), (0.837, 0.84), (0.920, 0.92),
        (1.000, 1.00),
    ]

    /// Normalized luminance swell — peaks mid-cycle as the orb brightens.
    private static let glowKeyframes: [(time: Double, value: Double)] = [
        (0.000, 0.00), (0.167, 0.12), (0.335, 0.38), (0.502, 0.62),
        (0.669, 1.00), (0.753, 0.96), (0.837, 0.90), (1.000, 0.92),
    ]

    static func pulse(at elapsed: TimeInterval, speedMultiplier: Double = 1) -> Double {
        let u = phaseUnit(elapsed: elapsed, speedMultiplier: speedMultiplier)
        return interpolate(pulseKeyframes, u)
    }

    static func glow(at elapsed: TimeInterval, speedMultiplier: Double = 1) -> Double {
        let u = phaseUnit(elapsed: elapsed, speedMultiplier: speedMultiplier)
        let key = interpolate(glowKeyframes, u)
        return 0.56 + 0.44 * key
    }

    static func ringExpansion(at elapsed: TimeInterval, speedMultiplier: Double = 1) -> Double {
        let u = phaseUnit(elapsed: elapsed, speedMultiplier: speedMultiplier)
        return 0.92 + 0.08 * interpolate(pulseKeyframes, u)
    }

    static func wispDrift(at elapsed: TimeInterval, speedMultiplier: Double = 1) -> Double {
        sin(elapsed * speedMultiplier * (2.0 * Double.pi / cycleSeconds) * 1.15)
    }

    private static func phaseUnit(elapsed: TimeInterval, speedMultiplier: Double) -> Double {
        let scaled = elapsed * speedMultiplier
        let mod = scaled.truncatingRemainder(dividingBy: cycleSeconds)
        return mod / cycleSeconds
    }

    private static func interpolate(_ keys: [(time: Double, value: Double)], _ unit: Double) -> Double {
        guard let first = keys.first else { return 0.5 }
        guard unit > first.time else { return first.value }
        guard let last = keys.last else { return first.value }
        guard unit < last.time else { return last.value }

        for index in 0 ..< keys.count - 1 {
            let a = keys[index]
            let b = keys[index + 1]
            if unit >= a.time, unit <= b.time {
                let span = max(0.0001, b.time - a.time)
                let t = (unit - a.time) / span
                let smooth = t * t * (3 - 2 * t)
                return a.value + (b.value - a.value) * smooth
            }
        }
        return last.value
    }
}
