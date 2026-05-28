import Foundation
import UniformTypeIdentifiers
import AVFoundation

struct WorkspaceAudioImportResult: Equatable, Sendable {
    let importedTracks: [MusicTrack]
    let failedFileNames: [String]
    let duplicateCount: Int

    var status: WorkspaceImportStatus {
        guard !importedTracks.isEmpty else {
            return duplicateCount > 0
                ? .success(kind: .audio, imported: 0, failedFileNames: failedFileNames, skippedDuplicates: duplicateCount)
                : .failure(kind: .audio, failedFileNames: failedFileNames)
        }

        return .success(
            kind: .audio,
            imported: importedTracks.count,
            failedFileNames: failedFileNames,
            skippedDuplicates: duplicateCount
        )
    }
}

struct WorkspaceAttachmentImportResult: Equatable, Sendable {
    let attachments: [SongAttachment]
    let failedFileNames: [String]

    var status: WorkspaceImportStatus {
        guard !attachments.isEmpty else {
            return .failure(kind: .attachment, failedFileNames: failedFileNames)
        }

        return .success(
            kind: .attachment,
            imported: attachments.count,
            failedFileNames: failedFileNames,
            skippedDuplicates: 0
        )
    }
}

struct WorkspaceAnimatedArtworkImportResult: Equatable, Sendable {
    let artwork: MotionArtwork?
    let failedFileNames: [String]
}

struct WorkspaceProjectCoverImportResult: Equatable, Sendable {
    let sleeve: SleeveArtwork?
    let motionArtwork: MotionArtwork?
    let failedFileNames: [String]
}

struct WorkspaceImportProcessor: Sendable {
    let libraryStore: MusicLibraryStore

    private static let maxAnimatedArtworkDuration: TimeInterval = 15
    private static let maxAnimatedArtworkFileSizeBytes: Int64 = 25_000_000

    func importAudioFiles(_ urls: [URL], existingTracks: [MusicTrack]) async -> WorkspaceAudioImportResult {
        var importedTracks: [MusicTrack] = []
        var failedFileNames: [String] = []
        var duplicateCount = 0
        var seenSourceTitles = Set(existingTracks.map { Self.normalizedSourceTitle($0.title) })

        await Task.yield()

        for url in urls {
            guard !Task.isCancelled else { break }

            guard Self.isSupportedAudioFile(url) else {
                failedFileNames.append(url.lastPathComponent)
                continue
            }

            let importedSourceTitle = Self.normalizedSourceTitle(MusicTrack.importedDisplayTitle(from: url))
            if seenSourceTitles.contains(importedSourceTitle) {
                duplicateCount += 1
                continue
            }

            do {
                let localFileName = try libraryStore.copyAudioIntoLibrary(from: url)
                let metadataURL = libraryStore.audioURL(forAudioLocalFileName: localFileName)
                let resolvedMetadata: AudioFileMetadata?
                if let metadataURL {
                    resolvedMetadata = await AudioFileMetadata.load(from: metadataURL)
                } else {
                    resolvedMetadata = nil
                }
                guard !Task.isCancelled else { break }
                let importedTrack = MusicTrack.imported(from: url, localFileName: localFileName, metadata: resolvedMetadata)
                importedTracks.append(importedTrack)
                seenSourceTitles.insert(importedSourceTitle)
                seenSourceTitles.insert(Self.normalizedSourceTitle(importedTrack.title))
            } catch {
#if DEBUG
                print("Audio import failed for \(url.lastPathComponent): \(error.localizedDescription)")
#endif
                failedFileNames.append(url.lastPathComponent)
            }
        }

        return WorkspaceAudioImportResult(
            importedTracks: importedTracks,
            failedFileNames: failedFileNames,
            duplicateCount: duplicateCount
        )
    }

    func importAttachmentFiles(_ urls: [URL]) async -> WorkspaceAttachmentImportResult {
        var attachments: [SongAttachment] = []
        var failedFileNames: [String] = []

        await Task.yield()

        for url in urls {
            guard !Task.isCancelled else { break }

            do {
                let localFileName = try libraryStore.copyAttachmentIntoLibrary(from: url)
                let fileSize = libraryStore.fileSize(forAttachmentLocalFileName: localFileName)
                guard !Task.isCancelled else { break }
                attachments.append(SongAttachment.imported(from: url, localFileName: localFileName, fileSize: fileSize))
            } catch {
#if DEBUG
                print("Attachment import failed for \(url.lastPathComponent): \(error.localizedDescription)")
#endif
                failedFileNames.append(url.lastPathComponent)
            }
        }

        return WorkspaceAttachmentImportResult(
            attachments: attachments,
            failedFileNames: failedFileNames
        )
    }

    func importAnimatedArtworkFile(_ urls: [URL]) async -> WorkspaceAnimatedArtworkImportResult {
        guard let url = urls.first else {
            return WorkspaceAnimatedArtworkImportResult(artwork: nil, failedFileNames: [])
        }

        do {
            let variant = try await Self.validateAnimatedArtworkFile(url)
            let localFileName = try libraryStore.copyAnimatedArtworkIntoLibrary(from: url)
            return WorkspaceAnimatedArtworkImportResult(
                artwork: MotionArtwork(
                    localFileName: localFileName,
                    sourceFileName: url.lastPathComponent,
                    variant: variant
                ),
                failedFileNames: []
            )
        } catch let error as AnimatedArtworkImportError {
            return WorkspaceAnimatedArtworkImportResult(
                artwork: nil,
                failedFileNames: [error.failureEntry(for: url.lastPathComponent)]
            )
        } catch {
#if DEBUG
            print("Animated artwork import failed for \(url.lastPathComponent): \(error.localizedDescription)")
#endif
            return WorkspaceAnimatedArtworkImportResult(artwork: nil, failedFileNames: [url.lastPathComponent])
        }
    }

    func importProjectCoverFile(_ urls: [URL]) async -> WorkspaceProjectCoverImportResult {
        guard let url = urls.first else {
            return WorkspaceProjectCoverImportResult(sleeve: nil, motionArtwork: nil, failedFileNames: [])
        }

        do {
            if Self.isSupportedImageFile(url) {
                let sleeve = try libraryStore.copyProjectCoverIntoLibrary(from: url)
                return WorkspaceProjectCoverImportResult(sleeve: sleeve, motionArtwork: nil, failedFileNames: [])
            }

            guard Self.isSupportedAnimatedArtworkFile(url) else {
                throw ProjectCoverImportError.unsupportedType
            }

            let variant = try await Self.validateAnimatedArtworkFile(url)
            let localFileName = try libraryStore.copyProjectCoverMotionIntoLibrary(from: url)
            return WorkspaceProjectCoverImportResult(
                sleeve: nil,
                motionArtwork: MotionArtwork(
                    localFileName: localFileName,
                    sourceFileName: url.lastPathComponent,
                    variant: variant
                ),
                failedFileNames: []
            )
        } catch let error as ProjectCoverImportError {
            return WorkspaceProjectCoverImportResult(
                sleeve: nil,
                motionArtwork: nil,
                failedFileNames: [error.failureEntry(for: url.lastPathComponent)]
            )
        } catch let error as AnimatedArtworkImportError {
            return WorkspaceProjectCoverImportResult(
                sleeve: nil,
                motionArtwork: nil,
                failedFileNames: [error.failureEntry(for: url.lastPathComponent)]
            )
        } catch {
#if DEBUG
            print("Project cover import failed for \(url.lastPathComponent): \(error.localizedDescription)")
#endif
            return WorkspaceProjectCoverImportResult(sleeve: nil, motionArtwork: nil, failedFileNames: [url.lastPathComponent])
        }
    }

    private static func normalizedSourceTitle(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func isSupportedAudioFile(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return false
        }

        return type.conforms(to: .audio)
    }

    private static func isSupportedAnimatedArtworkFile(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return false
        }

        return type.conforms(to: .movie) || type.conforms(to: .mpeg4Movie) || type.conforms(to: .quickTimeMovie)
    }

    private static func isSupportedImageFile(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return false
        }

        return type.conforms(to: .image)
    }

    private static func validateAnimatedArtworkFile(_ url: URL) async throws -> MotionArtworkVariant {
        guard isSupportedAnimatedArtworkFile(url) else {
            throw AnimatedArtworkImportError.unsupportedType
        }

        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let fileSize = try animatedArtworkFileSize(for: url)
        guard fileSize <= maxAnimatedArtworkFileSizeBytes else {
            throw AnimatedArtworkImportError.fileTooLarge(actualBytes: fileSize, maxBytes: maxAnimatedArtworkFileSizeBytes)
        }

        let asset = AVURLAsset(url: url)
        async let videoTracksTask = asset.loadTracks(withMediaType: .video)
        async let durationTask = asset.load(.duration)

        let videoTracks: [AVAssetTrack]
        do {
            videoTracks = try await videoTracksTask
        } catch {
            throw AnimatedArtworkImportError.missingVideoTrack
        }
        guard let videoTrack = videoTracks.first else {
            throw AnimatedArtworkImportError.missingVideoTrack
        }

        let duration: CMTime
        do {
            duration = try await durationTask
        } catch {
            throw AnimatedArtworkImportError.unreadableDuration
        }
        let durationSeconds = CMTimeGetSeconds(duration)
        guard durationSeconds.isFinite, durationSeconds > 0 else {
            throw AnimatedArtworkImportError.unreadableDuration
        }

        guard durationSeconds <= maxAnimatedArtworkDuration else {
            throw AnimatedArtworkImportError.durationTooLong(
                actualSeconds: durationSeconds,
                maxSeconds: maxAnimatedArtworkDuration
            )
        }

        return await motionArtworkVariant(for: videoTrack)
    }

    private static func motionArtworkVariant(for videoTrack: AVAssetTrack) async -> MotionArtworkVariant {
        guard let naturalSize = try? await videoTrack.load(.naturalSize),
              let transform = try? await videoTrack.load(.preferredTransform) else {
            return .square
        }

        let transformedSize = naturalSize.applying(transform)
        let width = abs(transformedSize.width)
        let height = abs(transformedSize.height)
        guard width > 0, height > 0 else { return .square }

        let aspectRatio = width / height
        return aspectRatio < 0.86 ? .portrait : .square
    }

    private static func animatedArtworkFileSize(for url: URL) throws -> Int64 {
        if let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
            return Int64(fileSize)
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let fileSize = attributes[.size] as? NSNumber {
            return fileSize.int64Value
        }

        throw AnimatedArtworkImportError.unreadableFileSize
    }
}

private enum AnimatedArtworkImportError: Error {
    case unsupportedType
    case unreadableFileSize
    case fileTooLarge(actualBytes: Int64, maxBytes: Int64)
    case missingVideoTrack
    case unreadableDuration
    case durationTooLong(actualSeconds: TimeInterval, maxSeconds: TimeInterval)

    func failureEntry(for fileName: String) -> String {
        "\(fileName): \(reason)"
    }

    private var reason: String {
        switch self {
        case .unsupportedType:
            return "choose a local .mov or .mp4 video"
        case .unreadableFileSize:
            return "file size could not be verified locally"
        case .fileTooLarge(let actualBytes, let maxBytes):
            return "exceeds \(Self.byteCount(maxBytes)) limit (\(Self.byteCount(actualBytes)))"
        case .missingVideoTrack:
            return "does not contain a readable video track"
        case .unreadableDuration:
            return "duration could not be verified"
        case .durationTooLong(let actualSeconds, let maxSeconds):
            return "longer than \(Self.durationLabel(maxSeconds)) limit (\(Self.durationLabel(actualSeconds)))"
        }
    }

    private static func byteCount(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private static func durationLabel(_ seconds: TimeInterval) -> String {
        PlaybackProgress.timeLabel(for: seconds)
    }
}

private enum ProjectCoverImportError: Error {
    case unsupportedType

    func failureEntry(for fileName: String) -> String {
        "\(fileName): \(reason)"
    }

    private var reason: String {
        switch self {
        case .unsupportedType:
            return "choose a local image or .mov/.mp4 video"
        }
    }
}
