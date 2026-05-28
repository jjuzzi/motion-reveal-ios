import ActivityKit
import Foundation

enum NowPlayingLiveActivityPresentation: String, Codable, Hashable {
    case inAppTransient
    case background
}

struct NowPlayingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var trackTitle: String
        var projectTitle: String
        var isPlaying: Bool
        var attachmentCount: Int
        var elapsedLabel: String
        var durationLabel: String
        var progressFraction: Double
    }

    var projectTitle: String
    var presentation: NowPlayingLiveActivityPresentation
}
