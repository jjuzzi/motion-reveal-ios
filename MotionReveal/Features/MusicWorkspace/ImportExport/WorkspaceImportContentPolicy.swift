import UniformTypeIdentifiers

enum WorkspaceImportContentPolicy {
    static let audioPickerTypes: [UTType] = [.audio]
    static let animatedArtworkPickerTypes: [UTType] = [.movie, .mpeg4Movie, .quickTimeMovie]
    static let projectCoverPickerTypes: [UTType] = [.image, .movie, .mpeg4Movie, .quickTimeMovie]
    static let attachmentPickerTypes: [UTType] = [.item]
    static let audioAllowsMultipleSelection = true
    static let animatedArtworkAllowsMultipleSelection = false
    static let projectCoverAllowsMultipleSelection = false
    static let attachmentAllowsMultipleSelection = true
}
