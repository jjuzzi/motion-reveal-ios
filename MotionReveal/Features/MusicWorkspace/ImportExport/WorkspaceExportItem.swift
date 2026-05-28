import Foundation

struct WorkspaceExportItem: Equatable, Identifiable {
    enum Kind: Equatable {
        case project
        case track
        case song
    }

    var id: String
    var kind: Kind
    var title: String
    var files: [URL]

    var hasFiles: Bool {
        !files.isEmpty
    }

    var subtitle: String {
        guard hasFiles else {
            return "No imported local file is available yet."
        }

        if files.count == 1 {
            return files[0].lastPathComponent
        }

        return "\(files.count) local files"
    }
}

extension URL {
    var workspaceExportDisplayName: String {
        deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
    }
}
