import ActivityKit
import Foundation

enum NowPlayingLiveActivity {
    static func update(
        project: MusicProject,
        track: MusicTrack,
        isPlaying: Bool,
        progress: PlaybackProgress,
        presentation: NowPlayingLiveActivityPresentation,
        canStartNewActivity: Bool = true
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = NowPlayingActivityAttributes.ContentState(
            trackTitle: track.title,
            projectTitle: project.title,
            isPlaying: isPlaying,
            attachmentCount: track.attachments.count,
            elapsedLabel: progress.elapsedLabel,
            durationLabel: progress.durationLabel,
            progressFraction: progress.fraction
        )
        let content = ActivityContent(state: state, staleDate: nil)

        if let activity = Activity<NowPlayingActivityAttributes>.activities.first(where: { $0.attributes.presentation == presentation }) {
            await activity.update(content)
            return
        }

        guard canStartNewActivity else {
            return
        }

        do {
            if #available(iOS 18.0, *) {
                _ = try Activity.request(
                    attributes: NowPlayingActivityAttributes(
                        projectTitle: project.title,
                        presentation: presentation
                    ),
                    content: content,
                    pushType: nil,
                    style: presentation.activityStyle
                )
            } else {
                _ = try Activity.request(
                    attributes: NowPlayingActivityAttributes(
                        projectTitle: project.title,
                        presentation: .background
                    ),
                    content: content,
                    pushType: nil
                )
            }
        } catch {
#if DEBUG
            print("Live Activity request failed: \(error.localizedDescription)")
#endif
        }
    }

    static func end() async {
        for activity in Activity<NowPlayingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

private extension NowPlayingLiveActivityPresentation {
    @available(iOS 18.0, *)
    var activityStyle: ActivityStyle {
        switch self {
        case .inAppTransient:
            return .transient
        case .background:
            return .standard
        }
    }
}
