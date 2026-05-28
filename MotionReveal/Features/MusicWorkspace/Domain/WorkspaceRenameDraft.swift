import Foundation

struct WorkspaceRenameDraft: Equatable, Identifiable {
    enum Target: Equatable {
        case project
        case track(UUID)
    }

    var id: String
    var target: Target
    var title: String
    var text: String

    static func project(_ project: MusicProject) -> WorkspaceRenameDraft {
        WorkspaceRenameDraft(
            id: "project-\(project.id.uuidString)",
            target: .project,
            title: "Rename project",
            text: project.title
        )
    }

    static func track(_ track: MusicTrack) -> WorkspaceRenameDraft {
        WorkspaceRenameDraft(
            id: "track-\(track.id.uuidString)",
            target: .track(track.id),
            title: "Rename track",
            text: track.title
        )
    }

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct WorkspaceAttachmentDraft: Equatable, Identifiable {
    let id: String
    let trackID: UUID
    let attachmentID: UUID
    var name: String
    var category: String

    static func attachment(_ attachment: SongAttachment, trackID: UUID) -> WorkspaceAttachmentDraft {
        WorkspaceAttachmentDraft(
            id: "attachment-\(trackID.uuidString)-\(attachment.id.uuidString)",
            trackID: trackID,
            attachmentID: attachment.id,
            name: attachment.name,
            category: attachment.category
        )
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedCategory: String {
        category.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedName.isEmpty
    }
}

struct WorkspaceSongTextDraft: Equatable, Identifiable {
    let id: String
    let trackID: UUID
    let kind: SongTextKind
    var text: String

    static func document(_ document: SongTextDocument, trackID: UUID) -> WorkspaceSongTextDraft {
        WorkspaceSongTextDraft(
            id: "song-text-\(trackID.uuidString)-\(document.kind.rawValue)",
            trackID: trackID,
            kind: document.kind,
            text: document.text
        )
    }

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
