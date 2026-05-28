import Foundation

struct WorkspaceExportBuildResult: Equatable {
    let item: WorkspaceExportItem
    let failedTextExportCount: Int

    var hasTextExportFailures: Bool {
        failedTextExportCount > 0
    }
}

struct WorkspaceExportBuilder {
    let libraryStore: MusicLibraryStore

    func projectExportItem(for project: MusicProject) -> WorkspaceExportBuildResult {
        let audioFiles = project.tracks.compactMap { libraryStore.audioURL(for: $0) }
        let attachmentFiles = project.tracks.flatMap { track in
            track.attachments.compactMap { libraryStore.attachmentURL(for: $0) }
        }
        let textResult = textExportFiles(for: project.tracks)
        let files = audioFiles + attachmentFiles + textResult.files

        return WorkspaceExportBuildResult(
            item: WorkspaceExportItem(
                id: "project-\(project.id.uuidString)-\(files.count)",
                kind: .project,
                title: "Export \(project.title)",
                files: files
            ),
            failedTextExportCount: textResult.failedCount
        )
    }

    func trackExportItem(for track: MusicTrack, kind: WorkspaceExportItem.Kind) -> WorkspaceExportBuildResult {
        var files = libraryStore.audioURL(for: track).map { [$0] } ?? []
        var failedTextExportCount = 0

        if kind == .song {
            files.append(contentsOf: track.attachments.compactMap { libraryStore.attachmentURL(for: $0) })
            let textResult = textExportFiles(for: [track])
            files.append(contentsOf: textResult.files)
            failedTextExportCount = textResult.failedCount
        }

        let prefix = kind == .song ? "song" : "track"
        return WorkspaceExportBuildResult(
            item: WorkspaceExportItem(
                id: "\(prefix)-\(track.id.uuidString)-\(files.count)",
                kind: kind,
                title: "Export \(track.title)",
                files: files
            ),
            failedTextExportCount: failedTextExportCount
        )
    }

    private func textExportFiles(for tracks: [MusicTrack]) -> (files: [URL], failedCount: Int) {
        var files: [URL] = []
        var failedCount = 0

        for track in tracks {
            for document in track.textDocuments {
                do {
                    if let url = try libraryStore.textExportURL(for: track, document: document) {
                        files.append(url)
                    }
                } catch {
#if DEBUG
                    print("Text export failed for \(track.title) \(document.kind.title): \(error.localizedDescription)")
#endif
                    failedCount += 1
                }
            }
        }

        return (files, failedCount)
    }
}
