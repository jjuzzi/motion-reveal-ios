import CoreGraphics

struct StudioDiscMaterialProfile: Equatable {
    let foilIntensity: Double
    let shimmerIntensity: Double
    let glassSheenIntensity: Double
    let edgeOpacity: Double
    let usesAnimatedShader: Bool
    let tilt: CGPoint

    init(faceVisibility: CGFloat = 1, edgeProfile: CGFloat = 0, reduceMotion: Bool = false) {
        let face = Self.clamped(faceVisibility)
        let edge = Self.clamped(edgeProfile)

        usesAnimatedShader = !reduceMotion && face > 0.12
        foilIntensity = reduceMotion ? 0.14 : Self.clamped(0.18 + face * 0.28 - edge * 0.16, lower: 0.10, upper: 0.46)
        shimmerIntensity = reduceMotion ? 0 : Self.clamped(0.08 + face * 0.20 - edge * 0.10, lower: 0, upper: 0.28)
        glassSheenIntensity = reduceMotion ? 0.12 : Self.clamped(0.14 + face * 0.22, lower: 0.10, upper: 0.36)
        edgeOpacity = Self.clamped(0.18 + edge * 0.82, lower: 0.08, upper: 1)
        tilt = CGPoint(x: 0.22 + edge * 0.10, y: -0.18 - face * 0.08)
    }

    private static func clamped(_ value: CGFloat, lower: Double = 0, upper: Double = 1) -> Double {
        min(max(Double(value), lower), upper)
    }
}
