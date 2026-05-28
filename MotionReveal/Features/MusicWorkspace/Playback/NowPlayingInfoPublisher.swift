import AVFoundation
import Foundation
import MediaPlayer
import UIKit

enum NowPlayingInfoPublisher {
    private static let defaultArtworkCache = NowPlayingArtworkImageCache(countLimit: 8)
    private static let coverArtworkCache = NowPlayingArtworkImageCache(countLimit: 32)
    private static let videoPreviewCache = NowPlayingArtworkImageCache(countLimit: 24)

    static func publish(
        project: MusicProject,
        track: MusicTrack,
        progress: PlaybackProgress,
        libraryStore: MusicLibraryStore
    ) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyAlbumTitle: project.title,
            MPMediaItemPropertyArtist: track.artistName ?? project.creator,
            MPMediaItemPropertyPlaybackDuration: progress.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: progress.elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: progress.isPlaying ? 1.0 : 0.0
        ]

        if let image = artworkImage(for: project, track: track, libraryStore: libraryStore) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
                image
            }
        }

#if compiler(>=6.3)
        let motionArtwork = project.displayedCoverMotionArtwork(for: track)
        if #available(iOS 26.0, *),
           let artwork = motionArtwork,
           let videoURL = libraryStore.animatedArtworkURL(for: artwork) {
            addAnimatedArtwork(artwork, videoURL: videoURL, to: &info)
        }
#endif

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    static func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    static func artworkImage(
        for project: MusicProject,
        track: MusicTrack?,
        libraryStore: MusicLibraryStore,
        targetSize: CGSize = CGSize(width: 512, height: 512)
    ) -> UIImage? {
        if let artwork = project.displayedCoverMotionArtwork(for: track),
           let videoURL = libraryStore.animatedArtworkURL(for: artwork),
           let preview = previewImageSynchronously(for: videoURL, requestedSize: targetSize) {
            return preview
        }

        switch project.sleeve {
        case .customImage(let localFileName, _):
            let cacheKey = artworkCacheKey(prefix: "cover", identifier: localFileName, size: targetSize)
            if let cachedImage = coverArtworkCache.image(forKey: cacheKey) {
                return cachedImage
            }

            if let url = MusicLibraryStore.projectCoverURL(for: localFileName),
               let image = UIImage(contentsOfFile: url.path) {
                let resolvedImage = image.preparingThumbnail(of: targetSize) ?? image
                coverArtworkCache.insert(resolvedImage, forKey: cacheKey)
                return resolvedImage
            }
            return defaultArtworkImage(size: targetSize)
        default:
            return defaultArtworkImage(size: targetSize)
        }
    }

    static func defaultArtworkImage(size: CGSize = CGSize(width: 512, height: 512)) -> UIImage {
        let cacheKey = artworkCacheKey(prefix: "default", identifier: "generated", size: size)
        if let cachedImage = defaultArtworkCache.image(forKey: cacheKey) {
            return cachedImage
        }

        let renderSize = CGSize(
            width: max(96, size.width),
            height: max(96, size.height)
        )
        let renderer = UIGraphicsImageRenderer(size: renderSize)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: renderSize)
            UIColor(red: 0.84, green: 0.82, blue: 0.72, alpha: 1).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: renderSize.width * 0.13).fill()

            UIColor(red: 0.10, green: 0.19, blue: 0.20, alpha: 1).setFill()
            let left = UIBezierPath(
                roundedRect: CGRect(
                    x: renderSize.width * 0.38,
                    y: renderSize.height * 0.24,
                    width: renderSize.width * 0.10,
                    height: renderSize.height * 0.50
                ),
                cornerRadius: renderSize.width * 0.025
            )
            left.apply(CGAffineTransform(rotationAngle: -0.10))
            left.fill()

            UIColor(red: 0.48, green: 0.73, blue: 0.62, alpha: 1).setFill()
            let right = UIBezierPath(
                roundedRect: CGRect(
                    x: renderSize.width * 0.53,
                    y: renderSize.height * 0.24,
                    width: renderSize.width * 0.10,
                    height: renderSize.height * 0.50
                ),
                cornerRadius: renderSize.width * 0.025
            )
            right.apply(CGAffineTransform(rotationAngle: 0.10))
            right.fill()
        }

        defaultArtworkCache.insert(image, forKey: cacheKey)
        return image
    }

#if compiler(>=6.3)
    @available(iOS 26.0, *)
    private static func addAnimatedArtwork(
        _ artwork: MotionArtwork,
        videoURL: URL,
        to info: inout [String: Any]
    ) {
        let animatedArtworkKey: String
        switch artwork.variant {
        case .square:
            animatedArtworkKey = MPNowPlayingInfoProperty1x1AnimatedArtwork
        case .portrait:
            animatedArtworkKey = MPNowPlayingInfoProperty3x4AnimatedArtwork
        }

        guard MPNowPlayingInfoCenter.supportedAnimatedArtworkKeys.contains(animatedArtworkKey) else {
            return
        }

        info[animatedArtworkKey] = MPMediaItemAnimatedArtwork(
            artworkID: "\(artwork.variant.rawValue)-\(artwork.localFileName)",
            previewImageRequestHandler: { requestedSize in
                await previewImage(for: videoURL, requestedSize: requestedSize)
            },
            videoAssetFileURLRequestHandler: { _ in
                videoURL
            }
        )
    }
#endif

    private static func previewImage(for videoURL: URL, requestedSize: CGSize) async -> UIImage? {
        previewImageSynchronously(for: videoURL, requestedSize: requestedSize)
    }

    private static func previewImageSynchronously(for videoURL: URL, requestedSize: CGSize) -> UIImage? {
        let cacheKey = artworkCacheKey(prefix: "video", identifier: videoURL.path, size: requestedSize)
        if let cachedImage = videoPreviewCache.image(forKey: cacheKey) {
            return cachedImage
        }

        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = requestedSize

        do {
            let image = try generator.copyCGImage(at: .zero, actualTime: nil)
            let resolvedImage = UIImage(cgImage: image)
            videoPreviewCache.insert(resolvedImage, forKey: cacheKey)
            return resolvedImage
        } catch {
            return nil
        }
    }

    private static func artworkCacheKey(prefix: String, identifier: String, size: CGSize) -> String {
        let width = Int(max(1, size.width.rounded(.up)))
        let height = Int(max(1, size.height.rounded(.up)))
        return "\(prefix):\(identifier):\(width)x\(height)"
    }
}

private final class NowPlayingArtworkImageCache: @unchecked Sendable {
    private let cache = NSCache<NSString, UIImage>()

    init(countLimit: Int) {
        cache.countLimit = countLimit
        cache.totalCostLimit = countLimit * 512 * 512 * 4
    }

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, forKey key: String) {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let cost = max(1, Int(pixelWidth * pixelHeight * 4))
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}
