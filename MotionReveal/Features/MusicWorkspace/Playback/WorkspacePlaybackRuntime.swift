import Foundation
import Observation

@MainActor
@Observable
final class WorkspacePlaybackRuntime {
    var nowPlaying: MusicTrack?
    var progress = PlaybackProgress.idle
    private(set) var commandIsPlaying = false
    private(set) var commandCanChangePlaybackPosition = false

    let audioPlayback = AudioPlaybackController()

    private var tickerTask: Task<Void, Never>?
    private var lastLiveActivityProgressSyncSecond: Int?
    private let tickInterval: TimeInterval = 1.0 / 20.0

    var hasTrack: Bool {
        nowPlaying != nil
    }

    func start(track: MusicTrack, libraryStore: MusicLibraryStore) throws -> WorkspacePlaybackStartResult {
        let coordinator = WorkspacePlaybackCoordinator(audioPlayback: audioPlayback, libraryStore: libraryStore)
        let startResult = try coordinator.start(track: track)
        nowPlaying = track
        progress = startResult.progress
        syncRemoteCommandState()
        lastLiveActivityProgressSyncSecond = nil
        return startResult
    }

    func replaceNowPlayingTrack(_ track: MusicTrack) {
        guard nowPlaying?.id == track.id else { return }
        nowPlaying = track
    }

    func toggle(libraryStore: MusicLibraryStore) {
        guard nowPlaying != nil else { return }
        let coordinator = WorkspacePlaybackCoordinator(audioPlayback: audioPlayback, libraryStore: libraryStore)
        progress = coordinator.toggle(current: progress)
        syncRemoteCommandState()
    }

    func seek(to fraction: Double, libraryStore: MusicLibraryStore) {
        guard nowPlaying != nil else { return }
        let coordinator = WorkspacePlaybackCoordinator(audioPlayback: audioPlayback, libraryStore: libraryStore)
        progress = coordinator.seek(current: progress, to: fraction)
        syncRemoteCommandState()
    }

    func previewSeek(to fraction: Double) {
        guard nowPlaying != nil, progress.isRealPlayback else { return }

        if audioPlayback.seekSilently(toFraction: fraction),
           let snapshot = audioPlayback.snapshot() {
            progress = snapshot
        } else {
            progress = progress.seek(toFraction: fraction)
        }
    }

    func stop(libraryStore: MusicLibraryStore) {
        tickerTask?.cancel()
        tickerTask = nil
        WorkspacePlaybackCoordinator(audioPlayback: audioPlayback, libraryStore: libraryStore).stop()
        nowPlaying = nil
        progress = .idle
        syncRemoteCommandState()
        lastLiveActivityProgressSyncSecond = nil
    }

    func resetWithoutStoppingAudio() {
        tickerTask?.cancel()
        tickerTask = nil
        nowPlaying = nil
        progress = .idle
        syncRemoteCommandState()
        lastLiveActivityProgressSyncSecond = nil
    }

    func startTicker(
        libraryStore: MusicLibraryStore,
        syncLiveActivity: @escaping @MainActor () -> Void
    ) {
        tickerTask?.cancel()

        tickerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(50))
                } catch {
                    return
                }

                guard let self, self.nowPlaying != nil else { return }

                let coordinator = WorkspacePlaybackCoordinator(audioPlayback: self.audioPlayback, libraryStore: libraryStore)
                self.progress = coordinator.tick(current: self.progress, by: self.tickInterval)
                self.syncRemoteCommandState()

                guard self.progress.isPlaying else { continue }

                let elapsedSecond = Int(self.progress.elapsed.rounded(.down))
                guard elapsedSecond != self.lastLiveActivityProgressSyncSecond else { continue }

                self.lastLiveActivityProgressSyncSecond = elapsedSecond
                syncLiveActivity()
            }
        }
    }

    func cancelTicker() {
        tickerTask?.cancel()
        tickerTask = nil
        lastLiveActivityProgressSyncSecond = nil
    }

    private func syncRemoteCommandState() {
        if commandIsPlaying != progress.isPlaying {
            commandIsPlaying = progress.isPlaying
        }

        let canChangePlaybackPosition = progress.duration > 0
        if commandCanChangePlaybackPosition != canChangePlaybackPosition {
            commandCanChangePlaybackPosition = canChangePlaybackPosition
        }
    }
}
