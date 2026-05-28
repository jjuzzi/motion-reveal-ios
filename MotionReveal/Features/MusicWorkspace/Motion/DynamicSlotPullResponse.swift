import CoreGraphics
import Foundation
import Motion

struct DynamicSlotPullResponse: Equatable {
    static let openThreshold: CGFloat = 48
    static let armHoldDuration: TimeInterval = 0.18
    static let visualBounds: CGFloat = 72
    static let visualLimit: CGFloat = 58

    let rawPull: CGFloat
    let visualPull: CGFloat
    let progress: CGFloat
    let isArmed: Bool
    let shouldOpen: Bool

    init(rawPull: CGFloat, holdTime: TimeInterval) {
        let pull = max(0, rawPull)
        self.rawPull = pull
        visualPull = Self.visualPull(for: pull)
        progress = Self.progress(forVisualPull: visualPull)
        isArmed = holdTime >= Self.armHoldDuration
        shouldOpen = isArmed && pull > Self.openThreshold
    }

    static func visualPull(for rawPull: CGFloat) -> CGFloat {
        let pull = max(0, rawPull)
        let rubberbanded = rubberband(
            Double(pull),
            coefficient: 0.42,
            boundsSize: Double(visualBounds),
            contentSize: Double(openThreshold + visualBounds)
        )

        return min(max(CGFloat(rubberbanded), 0), visualLimit)
    }

    static func progress(forVisualPull visualPull: CGFloat) -> CGFloat {
        min(max(visualPull / openThreshold, 0), 1)
    }
}
