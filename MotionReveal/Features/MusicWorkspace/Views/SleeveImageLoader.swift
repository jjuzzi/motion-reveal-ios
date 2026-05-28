import SwiftUI
import UIKit

@MainActor
final class SleeveImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?

    private static let cache = NSCache<NSString, UIImage>()
    private static let loadQueue = DispatchQueue(label: "playdate.sleeve-image-loader", qos: .userInitiated)

    private let localFileName: String
    private var loadTask: Task<Void, Never>?

    init(localFileName: String) {
        self.localFileName = localFileName
    }

    func load() {
        guard image == nil else { return }

        let key = localFileName as NSString
        if let cachedImage = Self.cache.object(forKey: key) {
            image = cachedImage
            return
        }

        guard let url = MusicLibraryStore.projectCoverURL(for: localFileName) else {
            return
        }

        loadTask?.cancel()
        loadTask = Task { [localFileName] in
            let decodedImage = await Self.decodedImage(at: url)
            guard !Task.isCancelled else { return }

            if let decodedImage {
                Self.cache.setObject(decodedImage, forKey: localFileName as NSString)
            }
            image = decodedImage
        }
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
    }

    private static func decodedImage(at url: URL) async -> UIImage? {
        await withCheckedContinuation { continuation in
            loadQueue.async {
                continuation.resume(returning: UIImage(contentsOfFile: url.path))
            }
        }
    }
}
