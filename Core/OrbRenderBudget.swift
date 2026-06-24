import CoreGraphics

/// Tunable orb render cost — keeps the ~10s pulse smooth at 30fps on device.
enum OrbRenderBudget {
    static let shellFramesPerSecond: Double = 30
    static let reducedMotionFramesPerSecond: Double = 20

    static func nebulaGridColumns(for diameter: CGFloat) -> Int {
        min(50, max(34, Int(diameter / 6.5)))
    }

    /// Post-blur on the volumetric nebula canvas — hides grid splats without extra samples.
    static func nebulaVolumeBlurRadius(for diameter: CGFloat) -> CGFloat {
        max(0.85, diameter * 0.0135)
    }

    static var usesLiteNebulaInterior: (CGFloat, CGFloat) -> Bool {
        { diameter, fillOpacity in
            diameter < 88 || fillOpacity < 0.22
        }
    }
}
