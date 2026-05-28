import Foundation

actor WorkspaceLibraryPersistence {
    func loadProjects(from store: MusicLibraryStore) -> [MusicProject] {
        store.loadProjects()
    }

    func saveProjects(_ projects: [MusicProject], to store: MusicLibraryStore) throws {
        try store.saveProjects(projects)
    }

    func removeAttachment(localFileName: String, from store: MusicLibraryStore) throws {
        try store.removeAttachmentFromLibrary(localFileName: localFileName)
    }
}
