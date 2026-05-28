import Foundation

struct WorkspaceSongContainerCoordinator {
    let selectedProject: MusicProject
    let nowPlaying: MusicTrack?

    func openDecision(revealStudioDrawer: Bool) -> WorkspaceSongContainerOpenDecision {
        if let nowPlaying {
            return .open(track: nowPlaying, revealStudioDrawer: revealStudioDrawer)
        }

        guard let firstTrack = selectedProject.tracks.first else {
            return .needsTrack
        }

        return .open(track: firstTrack, revealStudioDrawer: revealStudioDrawer)
    }

    func openDecision(for route: WorkspaceDeepLinkRoute) -> WorkspaceSongContainerOpenDecision {
        switch route {
        case .songContainer:
            openDecision(revealStudioDrawer: false)
        }
    }

    func openDecision(for route: MotionRevealIntentRoute) -> WorkspaceSongContainerOpenDecision {
        switch route {
        case .songContainer:
            openDecision(revealStudioDrawer: false)
        case .togglePlayback:
            openDecision(revealStudioDrawer: false)
        }
    }
}

enum WorkspaceSongContainerOpenDecision: Equatable {
    case open(track: MusicTrack, revealStudioDrawer: Bool)
    case needsTrack
}
