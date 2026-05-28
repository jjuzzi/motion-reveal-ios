import Foundation

struct WorkspacePlaybackStartResult: Equatable, Sendable {
    let progress: PlaybackProgress
    let message: String
}

@MainActor
struct WorkspacePlaybackCoordinator {
    let audioPlayback: AudioPlaybackController
    let libraryStore: MusicLibraryStore

    func start(track: MusicTrack) throws -> WorkspacePlaybackStartResult {
        let progress = try audioPlayback.play(track: track, libraryStore: libraryStore) ?? .preview(for: track)
        return WorkspacePlaybackStartResult(
            progress: progress,
            message: progress.isRealPlayback ? "Playing" : "Previewing"
        )
    }

    func toggle(current progress: PlaybackProgress) -> PlaybackProgress {
        if progress.isRealPlayback, let realProgress = audioPlayback.togglePlayback() {
            return realProgress
        }

        return progress.toggledPlayback()
    }

    func seek(current progress: PlaybackProgress, to fraction: Double) -> PlaybackProgress {
        if progress.isRealPlayback, let realProgress = audioPlayback.seek(toFraction: fraction) {
            return realProgress
        }

        return progress.seek(toFraction: fraction)
    }

    func tick(current progress: PlaybackProgress, by interval: TimeInterval = 0.25) -> PlaybackProgress {
        if progress.isRealPlayback, let snapshot = audioPlayback.snapshot() {
            return snapshot
        }

        return progress.advanced(by: interval)
    }

    func stop() {
        audioPlayback.stop()
    }
}
