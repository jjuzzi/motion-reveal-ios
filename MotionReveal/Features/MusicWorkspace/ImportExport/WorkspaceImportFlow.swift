import Foundation
import SwiftUI

@MainActor
struct WorkspaceImportFlow {
    let libraryStore: MusicLibraryStore
    let existingAudioTracks: [MusicTrack]
    let targetAttachmentTrackID: UUID?
    let setImportStatus: (WorkspaceImportStatus) -> Void
    let finishImport: (WorkspaceImportStatus) -> Void
    let showToast: (String) -> Void
    let appendImportedTracks: ([MusicTrack]) -> Void
    let appendAttachments: ([SongAttachment], UUID) -> Void
    let presentAudioImporter: () -> Void

    nonisolated static func shouldTriggerFirstImportHandoff(
        existingTrackCount: Int,
        importedTrackCount: Int,
        isProjectScreen: Bool,
        isSongContainerOpen: Bool
    ) -> Bool {
        isProjectScreen
            && existingTrackCount == 0
            && importedTrackCount > 0
            && !isSongContainerOpen
    }

    func importAudioFiles(_ urls: [URL]) async {
        guard !urls.isEmpty else {
            WorkspaceImportDiagnostics.emptySelection(kind: .audio)
            finishImport(.failure(kind: .audio, failedFileNames: []))
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            setImportStatus(.importing(kind: .audio, total: urls.count))
        }
        do {
            try await Task.sleep(for: .milliseconds(220))
        } catch {
            return
        }

        guard !Task.isCancelled else { return }

        let result = await WorkspaceImportWorker.importAudioFiles(
            urls,
            existingTracks: existingAudioTracks,
            libraryStore: libraryStore
        )

        guard !Task.isCancelled else { return }

        guard !result.importedTracks.isEmpty else {
            finishImport(result.status)
            return
        }

        appendImportedTracks(result.importedTracks)
        finishImport(result.status)
    }

    func importAttachmentFiles(_ urls: [URL]) async {
        guard !urls.isEmpty else {
            WorkspaceImportDiagnostics.emptySelection(kind: .attachment)
            finishImport(.failure(kind: .attachment, failedFileNames: []))
            return
        }

        guard let targetAttachmentTrackID else {
            showToast("Add a track first")
            presentAudioImporter()
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            setImportStatus(.importing(kind: .attachment, total: urls.count))
        }
        do {
            try await Task.sleep(for: .milliseconds(160))
        } catch {
            return
        }

        guard !Task.isCancelled else { return }

        let result = await WorkspaceImportWorker.importAttachmentFiles(
            urls,
            libraryStore: libraryStore
        )

        guard !Task.isCancelled else { return }

        guard !result.attachments.isEmpty else {
            finishImport(result.status)
            return
        }

        appendAttachments(result.attachments, targetAttachmentTrackID)
        finishImport(result.status)
    }
}
