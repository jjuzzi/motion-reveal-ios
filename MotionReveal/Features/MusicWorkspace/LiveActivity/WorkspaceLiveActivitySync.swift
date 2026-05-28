import Foundation

@MainActor
final class WorkspaceLiveActivitySync {
    private var syncTask: Task<Void, Never>?

    func perform(_ action: WorkspaceDynamicIslandAction) {
        syncTask?.cancel()
        syncTask = Task {
            guard !Task.isCancelled else { return }

            switch action {
            case .update(let project, let track, let isPlaying, let progress, let presentation, let canStartNewActivity):
                await NowPlayingLiveActivity.update(
                    project: project,
                    track: track,
                    isPlaying: isPlaying,
                    progress: progress,
                    presentation: presentation,
                    canStartNewActivity: canStartNewActivity
                )
            case .end:
                await NowPlayingLiveActivity.end()
            }
        }
    }

    func cancel() {
        syncTask?.cancel()
        syncTask = nil
    }
}
