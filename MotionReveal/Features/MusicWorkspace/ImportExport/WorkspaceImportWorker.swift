import Foundation

enum WorkspaceImportWorker {
    static func importAudioFiles(
        _ urls: [URL],
        existingTracks: [MusicTrack],
        libraryStore: MusicLibraryStore
    ) async -> WorkspaceAudioImportResult {
        let task = Task.detached(priority: .userInitiated) {
            await WorkspaceImportProcessor(libraryStore: libraryStore)
                .importAudioFiles(urls, existingTracks: existingTracks)
        }

        return await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    static func importAttachmentFiles(
        _ urls: [URL],
        libraryStore: MusicLibraryStore
    ) async -> WorkspaceAttachmentImportResult {
        let task = Task.detached(priority: .userInitiated) {
            await WorkspaceImportProcessor(libraryStore: libraryStore)
                .importAttachmentFiles(urls)
        }

        return await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    static func importAnimatedArtworkFile(
        _ urls: [URL],
        libraryStore: MusicLibraryStore
    ) async -> WorkspaceAnimatedArtworkImportResult {
        let task = Task.detached(priority: .userInitiated) {
            await WorkspaceImportProcessor(libraryStore: libraryStore)
                .importAnimatedArtworkFile(urls)
        }

        return await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    static func importProjectCover(
        _ urls: [URL],
        libraryStore: MusicLibraryStore
    ) async -> WorkspaceProjectCoverImportResult {
        let task = Task.detached(priority: .userInitiated) {
            await WorkspaceImportProcessor(libraryStore: libraryStore)
                .importProjectCoverFile(urls)
        }

        return await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    static func saveProjectCoverData(
        _ data: Data,
        libraryStore: MusicLibraryStore
    ) async throws -> SleeveArtwork {
        let task = Task.detached(priority: .userInitiated) {
            try libraryStore.saveProjectCoverData(data)
        }

        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }
}
