import AVFoundation
import Foundation

struct MusicLibraryStore: Sendable {
    private let documentsURL: URL

    init(fileManager: FileManager = .default, documentsURL: URL? = nil) {
        if let documentsURL {
            self.documentsURL = documentsURL
        } else if let resolvedURL = try? fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            self.documentsURL = resolvedURL
        } else {
            self.documentsURL = fileManager.temporaryDirectory
        }
    }

    func loadProjects() -> [MusicProject] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: libraryFileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: libraryFileURL)
            let projects = try JSONDecoder().decode([MusicProject].self, from: data)
            let cleanedProjects = projects.filter(\.isPersistableLibraryProject)
            return cleanedProjects
        } catch {
            return []
        }
    }

    func saveProjects(_ projects: [MusicProject]) throws {
        try FileManager.default.createDirectory(
            at: appSupportDirectory,
            withIntermediateDirectories: true
        )

        let data = try JSONEncoder.prettySorted.encode(projects.filter(\.isPersistableLibraryProject))
        try data.write(to: libraryFileURL, options: [.atomic])
    }

    func copyAudioIntoLibrary(from url: URL) throws -> String {
        try copyFile(from: url, into: importedAudioDirectory)
    }

    func copyAttachmentIntoLibrary(from url: URL) throws -> String {
        try copyFile(from: url, into: importedAttachmentDirectory)
    }

    func copyAnimatedArtworkIntoLibrary(from url: URL) throws -> String {
        try copyFile(from: url, into: importedAnimatedArtworkDirectory)
    }

    func copyProjectCoverMotionIntoLibrary(from url: URL) throws -> String {
        try copyFile(from: url, into: importedAnimatedArtworkDirectory)
    }

    func copyProjectCoverIntoLibrary(from url: URL) throws -> SleeveArtwork {
        let localFileName = try copyFile(from: url, into: importedProjectArtworkDirectory)
        let sourceFileName = url.lastPathComponent.isEmpty ? "Album cover" : url.lastPathComponent
        return .customImage(localFileName: localFileName, sourceFileName: sourceFileName)
    }

    func saveProjectCoverData(_ data: Data, fileExtension: String = "jpg") throws -> SleeveArtwork {
        try FileManager.default.createDirectory(
            at: importedProjectArtworkDirectory,
            withIntermediateDirectories: true
        )

        let normalizedExtension = fileExtension.trimmingCharacters(in: .punctuationCharacters).isEmpty ? "jpg" : fileExtension
        let localFileName = "\(UUID().uuidString)-album-cover.\(normalizedExtension)"
        let destinationURL = importedProjectArtworkDirectory.appending(path: localFileName, directoryHint: .notDirectory)
        try data.write(to: destinationURL, options: [.atomic])
        return .customImage(localFileName: localFileName, sourceFileName: "Album cover.\(normalizedExtension)")
    }

    func fileSize(forAttachmentLocalFileName localFileName: String) -> Int64? {
        let url = importedAttachmentDirectory.appending(path: localFileName, directoryHint: .notDirectory)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
            return nil
        }

        return attributes[.size] as? Int64
    }

    func audioURL(forAudioLocalFileName localFileName: String) -> URL? {
        let url = importedAudioDirectory.appending(path: localFileName, directoryHint: .notDirectory)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func attachmentURL(for attachment: SongAttachment) -> URL? {
        guard !attachment.localFileName.isEmpty else {
            return nil
        }

        let url = importedAttachmentDirectory.appending(path: attachment.localFileName, directoryHint: .notDirectory)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func animatedArtworkURL(for artwork: MotionArtwork) -> URL? {
        guard !artwork.localFileName.isEmpty else {
            return nil
        }

        let url = importedAnimatedArtworkDirectory.appending(path: artwork.localFileName, directoryHint: .notDirectory)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func projectCoverURL(for localFileName: String) -> URL? {
        guard !localFileName.isEmpty,
              let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let url = documentsURL
            .appending(path: "ProjectArtwork", directoryHint: .isDirectory)
            .appending(path: localFileName, directoryHint: .notDirectory)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func removeAttachmentFromLibrary(localFileName: String) throws {
        guard !localFileName.isEmpty else {
            return
        }

        let url = importedAttachmentDirectory.appending(path: localFileName, directoryHint: .notDirectory)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        try FileManager.default.removeItem(at: url)
    }

    func textExportURL(for track: MusicTrack, document: SongTextDocument) throws -> URL? {
        let body = document.trimmedText
        guard !body.isEmpty else {
            return nil
        }

        try FileManager.default.createDirectory(
            at: textExportDirectory,
            withIntermediateDirectories: true
        )

        let fileName = "\(Self.safeFileComponent(track.title))-\(document.kind.rawValue).txt"
        let url = textExportDirectory.appending(path: fileName, directoryHint: .notDirectory)
        let content = """
        \(track.title)
        \(document.kind.title)

        \(body)
        """

        try Data(content.utf8).write(to: url, options: [.atomic])
        return url
    }

    private func copyFile(from url: URL, into directory: URL) throws -> String {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let rawFileName = url.lastPathComponent.isEmpty ? "attached-file" : url.lastPathComponent
        let localFileName = "\(UUID().uuidString)-\(rawFileName)"
        let destinationURL = directory.appending(path: localFileName, directoryHint: .notDirectory)

        WorkspaceImportDiagnostics.copyStarted(fileName: rawFileName, securityScopeGranted: didAccess)
        do {
            try coordinatedCopy(from: url, to: destinationURL)
        } catch {
            WorkspaceImportDiagnostics.copyFailed(fileName: rawFileName, error: error)
            throw error
        }
        WorkspaceImportDiagnostics.copySucceeded(fileName: rawFileName)
        return localFileName
    }

    func audioURL(for track: MusicTrack) -> URL? {
        guard let localFileName = track.localFileName, !localFileName.isEmpty else {
            return nil
        }

        let url = importedAudioDirectory.appending(path: localFileName, directoryHint: .notDirectory)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private var appSupportDirectory: URL {
        documentsURL.appending(path: "Library", directoryHint: .isDirectory)
    }

    private var importedAudioDirectory: URL {
        documentsURL.appending(path: "ImportedAudio", directoryHint: .isDirectory)
    }

    private var importedAttachmentDirectory: URL {
        documentsURL.appending(path: "SongAttachments", directoryHint: .isDirectory)
    }

    private var importedAnimatedArtworkDirectory: URL {
        documentsURL.appending(path: "AnimatedArtwork", directoryHint: .isDirectory)
    }

    private var importedProjectArtworkDirectory: URL {
        documentsURL.appending(path: "ProjectArtwork", directoryHint: .isDirectory)
    }

    private var libraryFileURL: URL {
        appSupportDirectory.appending(path: "projects.json", directoryHint: .notDirectory)
    }

    private var textExportDirectory: URL {
        documentsURL.appending(path: "TextExports", directoryHint: .isDirectory)
    }

    private static func safeFileComponent(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        let safeFragments = value.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? String(scalar) : "-"
        }
        let cleaned = safeFragments.joined()
            .replacingOccurrences(of: " ", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-_"))

        return cleaned.isEmpty ? "song" : cleaned
    }

    static func commonMetadataString(_ metadata: [AVMetadataItem], key: AVMetadataKey) async -> String? {
        guard let item = AVMetadataItem.metadataItems(from: metadata, withKey: key, keySpace: .common).first else {
            return nil
        }

        return (try? await item.load(.stringValue))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
    }

    static func audioDurationLabel(asset: AVURLAsset) async -> String? {
        guard let duration = try? await asset.load(.duration) else {
            return nil
        }

        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isFinite, seconds > 0 else {
            return nil
        }

        return PlaybackProgress.timeLabel(for: seconds)
    }

    private func coordinatedCopy(from sourceURL: URL, to destinationURL: URL) throws {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var copyError: Error?

        coordinator.coordinate(readingItemAt: sourceURL, options: [], error: &coordinationError) { readableURL in
            do {
                try FileManager.default.copyItem(at: readableURL, to: destinationURL)
            } catch {
                copyError = error
            }
        }

        if let coordinationError {
            throw coordinationError
        }

        if let copyError {
            throw copyError
        }
    }
}

private extension JSONEncoder {
    static var prettySorted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

extension AudioFileMetadata {
    static func load(from url: URL) async -> AudioFileMetadata {
        let asset = AVURLAsset(url: url)
        let commonMetadata = (try? await asset.load(.commonMetadata)) ?? []

        return AudioFileMetadata(
            title: await MusicLibraryStore.commonMetadataString(commonMetadata, key: .commonKeyTitle),
            artist: await MusicLibraryStore.commonMetadataString(commonMetadata, key: .commonKeyArtist),
            durationLabel: await MusicLibraryStore.audioDurationLabel(asset: asset),
            format: url.pathExtension.uppercased()
        )
    }
}

private extension MusicProject {
    var isPersistableLibraryProject: Bool {
        state != .fresh && !isLegacySeedProject
    }

    var isLegacySeedProject: Bool {
        Self.legacySeedIDs.contains(id) && tracks.allSatisfy { $0.localFileName == nil }
    }

    static let legacySeedIDs: Set<UUID> = [
        UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    ]
}
