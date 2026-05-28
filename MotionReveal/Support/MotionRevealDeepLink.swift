import Foundation

enum MotionRevealDeepLink {
    static let scheme = "motionreveal"
    static let songContainerHost = "song-container"
    static let songContainerURL = URL(string: "\(scheme)://\(songContainerHost)")
}
