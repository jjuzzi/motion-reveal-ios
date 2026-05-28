import Foundation

enum WorkspaceTrackRemovalOutcome: Equatable {
    case removed(updatedTrack: MusicTrack?)
    case alreadyRemoved
}

enum WorkspaceAttachmentRemovalOutcome: Equatable {
    case removed(attachment: SongAttachment, updatedTrack: MusicTrack)
    case trackUnavailable
    case alreadyRemoved
}

struct WorkspaceDestructiveActionExecutor {
    static func deleteSelectedProject(
        projects: inout [MusicProject],
        selectedProject: inout MusicProject,
        screen: inout WorkspaceScreen
    ) {
        projects.removeAll { $0.id == selectedProject.id }

        if let nextProject = projects.first {
            selectedProject = nextProject
            if screen == .project {
                screen = .library
            }
        } else {
            selectedProject = MusicProject.freshProject
            screen = .library
        }
    }

    static func removeTrack(
        _ track: MusicTrack,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> WorkspaceTrackRemovalOutcome {
        guard selectedProject.tracks.contains(where: { $0.id == track.id }) else {
            return .alreadyRemoved
        }

        var updatedProject = selectedProject
        updatedProject.tracks.removeAll { $0.id == track.id }
        updatedProject.trackCount = updatedProject.tracks.count
        selectedProject = updatedProject

        if let index = projects.firstIndex(where: { $0.id == updatedProject.id }) {
            projects[index] = updatedProject
        }

        return .removed(updatedTrack: selectedProject.tracks.first)
    }

    static func removeAttachment(
        _ attachment: SongAttachment,
        fromTrackID trackID: UUID,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> WorkspaceAttachmentRemovalOutcome {
        guard let trackIndex = selectedProject.tracks.firstIndex(where: { $0.id == trackID }) else {
            return .trackUnavailable
        }

        guard let attachmentIndex = selectedProject.tracks[trackIndex].attachments.firstIndex(where: { $0.id == attachment.id }) else {
            return .alreadyRemoved
        }

        let removedAttachment = selectedProject.tracks[trackIndex].attachments.remove(at: attachmentIndex)
        let updatedTrack = selectedProject.tracks[trackIndex]

        if let projectIndex = projects.firstIndex(where: { $0.id == selectedProject.id }) {
            projects[projectIndex] = selectedProject
        }

        return .removed(attachment: removedAttachment, updatedTrack: updatedTrack)
    }
}
