import CoreGraphics
import Foundation

struct DynamicSlotPullDecision {
    static let openThreshold = DynamicSlotPullResponse.openThreshold

    static func shouldOpen(forPull pull: CGFloat, holdTime: TimeInterval = DynamicSlotPullResponse.armHoldDuration) -> Bool {
        DynamicSlotPullResponse(rawPull: pull, holdTime: holdTime).shouldOpen
    }
}
