import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class MotionArtworkPreviewModel {
    private(set) var player: AVQueuePlayer?
    private var artworkIdentity: String?
    private var looper: AVPlayerLooper?

    func configure(for artwork: MotionArtwork) {
        guard artworkIdentity != artwork.playbackIdentity else { return }

        player?.pause()
        player = nil
        looper = nil
        artworkIdentity = artwork.playbackIdentity

        guard let url = Self.resolvePreviewURL(for: artwork) else {
            return
        }

        let playerItem = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .none
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false
        looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        player = queuePlayer
    }

    func updatePlayback(isEnabled: Bool) {
        guard let player else { return }

        if isEnabled {
            player.play()
        } else {
            player.pause()
        }
    }

    private static func resolvePreviewURL(for artwork: MotionArtwork) -> URL? {
        guard !artwork.localFileName.isEmpty else {
            return nil
        }

        let fileManager = FileManager.default
        guard let documentsURL = try? fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            return nil
        }

        let url = documentsURL
            .appending(path: "AnimatedArtwork", directoryHint: .isDirectory)
            .appending(path: artwork.localFileName, directoryHint: .notDirectory)

        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
}
