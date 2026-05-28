import Foundation

enum WorkspaceDeepLinkRoute: Equatable {
    case songContainer

    init?(url: URL) {
        guard url.scheme == MotionRevealDeepLink.scheme else { return nil }

        switch url.host {
        case MotionRevealDeepLink.songContainerHost:
            self = .songContainer
        default:
            return nil
        }
    }
}
