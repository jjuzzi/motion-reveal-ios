import Foundation

enum WorkspaceDynamicIslandAction: Equatable {
    case update(
        project: MusicProject,
        track: MusicTrack,
        isPlaying: Bool,
        progress: PlaybackProgress,
        presentation: NowPlayingLiveActivityPresentation,
        canStartNewActivity: Bool
    )
    case end
}

struct WorkspaceDynamicIslandCoordinator {
    static func action(
        selectedProject: MusicProject,
        nowPlaying: MusicTrack?,
        playbackProgress: PlaybackProgress,
        preferredTrack: MusicTrack? = nil,
        isPlayingOverride: Bool? = nil,
        presentation: NowPlayingLiveActivityPresentation = .background,
        canStartNewActivity: Bool = true
    ) -> WorkspaceDynamicIslandAction {
        guard let activityTrack = preferredTrack ?? nowPlaying ?? selectedProject.tracks.first else {
            return .end
        }

        let isPlaying = isPlayingOverride ?? (nowPlaying?.id == activityTrack.id && playbackProgress.isPlaying)
        let activityProgress = progress(
            for: activityTrack,
            nowPlaying: nowPlaying,
            playbackProgress: playbackProgress,
            isPlaying: isPlaying
        )
        return .update(
            project: selectedProject,
            track: activityTrack,
            isPlaying: isPlaying,
            progress: activityProgress,
            presentation: presentation,
            canStartNewActivity: canStartNewActivity
        )
    }

    private static func progress(
        for activityTrack: MusicTrack,
        nowPlaying: MusicTrack?,
        playbackProgress: PlaybackProgress,
        isPlaying: Bool
    ) -> PlaybackProgress {
        if nowPlaying?.id == activityTrack.id {
            return PlaybackProgress(
                elapsed: playbackProgress.elapsed,
                duration: playbackProgress.duration,
                isPlaying: isPlaying,
                isRealPlayback: playbackProgress.isRealPlayback
            )
        }

        let previewProgress = PlaybackProgress.preview(for: activityTrack)
        return PlaybackProgress(
            elapsed: 0,
            duration: previewProgress.duration,
            isPlaying: false,
            isRealPlayback: false
        )
    }
}
