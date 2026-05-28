import Foundation

struct WorkspaceImportMutationExecutor {
    @discardableResult
    static func appendImportedTracks(
        _ tracks: [MusicTrack],
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> MusicProject {
        selectedProject.tracks.append(contentsOf: tracks)
        selectedProject.trackCount = selectedProject.tracks.count
        updateSelectedProject(selectedProject, in: &projects)
        return selectedProject
    }

    static func appendAttachments(
        _ attachments: [SongAttachment],
        toTrackID trackID: UUID,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> MusicTrack? {
        guard let trackIndex = selectedProject.tracks.firstIndex(where: { $0.id == trackID }) else {
            return nil
        }

        selectedProject.tracks[trackIndex].attachments.append(contentsOf: attachments)
        selectedProject.trackCount = selectedProject.tracks.count
        updateSelectedProject(selectedProject, in: &projects)
        return selectedProject.tracks[trackIndex]
    }

    private static func updateSelectedProject(_ selectedProject: MusicProject, in projects: inout [MusicProject]) {
        if let index = projects.firstIndex(where: { $0.id == selectedProject.id }) {
            projects[index] = selectedProject
        } else {
            projects.insert(selectedProject, at: 0)
        }
    }
}
