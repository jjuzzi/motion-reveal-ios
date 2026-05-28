import Foundation

struct WorkspaceProjectMutationExecutor {
    @discardableResult
    static func createFreshProject(
        projects: inout [MusicProject],
        id: UUID = UUID()
    ) -> MusicProject {
        var freshProject = MusicProject.freshProject
        freshProject.id = id
        projects.insert(freshProject, at: 0)
        return freshProject
    }

    @discardableResult
    static func activateCreatedProject(id: UUID, projects: inout [MusicProject]) -> MusicProject? {
        guard let index = projects.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        projects[index].state = .regular
        return projects[index]
    }

    static func renameSelectedProject(
        to title: String,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) {
        selectedProject.title = title
        updateSelectedProject(selectedProject, in: &projects)
    }

    static func updateSelectedProjectSleeve(
        to sleeve: SleeveArtwork,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) {
        selectedProject.sleeve = sleeve
        selectedProject.coverMotionArtworkIsExplicit = true
        updateSelectedProject(selectedProject, in: &projects)
    }

    static func updateSelectedProjectCover(
        sleeve: SleeveArtwork? = nil,
        motionArtwork: MotionArtwork? = nil,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) {
        if let sleeve {
            selectedProject.sleeve = sleeve
        }

        selectedProject.coverMotionArtwork = motionArtwork
        selectedProject.coverMotionArtworkIsExplicit = true
        updateSelectedProject(selectedProject, in: &projects)
    }

    @discardableResult
    static func duplicateSelectedProject(
        selectedProject: MusicProject,
        projects: inout [MusicProject],
        duplicateID: UUID = UUID()
    ) -> MusicProject {
        var duplicateProject = selectedProject
        duplicateProject.id = duplicateID
        duplicateProject.title = "\(selectedProject.title) copy"
        duplicateProject.state = .regular

        let insertionIndex = projects.firstIndex(where: { $0.id == selectedProject.id }).map { $0 + 1 } ?? 0
        projects.insert(duplicateProject, at: insertionIndex)
        return duplicateProject
    }

    @discardableResult
    static func toggleSelectedProjectPin(
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> ProjectState {
        selectedProject.state = selectedProject.state == .pinned ? .regular : .pinned
        updateSelectedProject(selectedProject, in: &projects)
        return selectedProject.state
    }

    private static func updateSelectedProject(_ selectedProject: MusicProject, in projects: inout [MusicProject]) {
        if let index = projects.firstIndex(where: { $0.id == selectedProject.id }) {
            projects[index] = selectedProject
        }
    }
}
