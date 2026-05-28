import SwiftUI

struct MusicProject: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var title: String
    var creator: String
    var trackCount: Int
    var runtime: String
    var sleeve: SleeveArtwork
    var coverMotionArtwork: MotionArtwork? = nil
    var coverMotionArtworkIsExplicit: Bool? = nil
    var state: ProjectState
    var tracks: [MusicTrack]

    var metadata: String {
        if state == .folder {
            return "\(trackCount) items"
        }

        if runtime.isEmpty {
            return "\(creator) - \(trackCount) tracks"
        }

        return "\(creator) - \(trackCount) tracks - \(runtime)"
    }

    var displayedCoverMotionArtwork: MotionArtwork? {
        if let coverMotionArtwork {
            return coverMotionArtwork
        }

        guard coverMotionArtworkIsExplicit != true else {
            return nil
        }

        return tracks.first(where: { $0.animatedArtwork != nil })?.animatedArtwork
    }

    var legacyCoverMotionArtwork: MotionArtwork? {
        tracks.first(where: { $0.animatedArtwork != nil })?.animatedArtwork
    }
}

enum ProjectState: Codable, Equatable, Sendable {
    case pinned
    case regular
    case folder
    case locked
    case fresh
}

struct MusicTrack: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var date: String
    var duration: String
    var localFileName: String?
    var artistName: String?
    var audioFormat: String?
    var animatedArtwork: MotionArtwork?
    var attachments: [SongAttachment] = []
    var markers: [WaveformMarker] = []
    var textDocuments: [SongTextDocument] = SongTextDocument.emptySet

    init(
        id: UUID,
        title: String,
        date: String,
        duration: String,
        localFileName: String? = nil,
        artistName: String? = nil,
        audioFormat: String? = nil,
        animatedArtwork: MotionArtwork? = nil,
        attachments: [SongAttachment] = [],
        markers: [WaveformMarker] = [],
        textDocuments: [SongTextDocument] = SongTextDocument.emptySet
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.localFileName = localFileName
        self.artistName = artistName?.trimmingCharacters(in: .whitespacesAndNewlines).workspaceNilIfEmpty
        self.audioFormat = audioFormat?.trimmingCharacters(in: .whitespacesAndNewlines).workspaceNilIfEmpty
        self.animatedArtwork = animatedArtwork
        self.attachments = attachments
        self.markers = markers
        self.textDocuments = SongTextDocument.normalizedSet(from: textDocuments)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case date
        case duration
        case localFileName
        case artistName
        case audioFormat
        case animatedArtwork
        case attachments
        case markers
        case textDocuments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(String.self, forKey: .date)
        duration = try container.decode(String.self, forKey: .duration)
        localFileName = try container.decodeIfPresent(String.self, forKey: .localFileName)
        artistName = try container.decodeIfPresent(String.self, forKey: .artistName)
        audioFormat = try container.decodeIfPresent(String.self, forKey: .audioFormat)
        animatedArtwork = try container.decodeIfPresent(MotionArtwork.self, forKey: .animatedArtwork)
        attachments = try container.decodeIfPresent([SongAttachment].self, forKey: .attachments) ?? []
        markers = try container.decodeIfPresent([WaveformMarker].self, forKey: .markers) ?? []
        textDocuments = SongTextDocument.normalizedSet(
            from: try container.decodeIfPresent([SongTextDocument].self, forKey: .textDocuments) ?? []
        )
    }

    var metadataLine: String {
        let lead = artistName ?? date
        let values = [
            lead,
            duration == "Imported" ? nil : duration,
            audioFormat
        ]

        return values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines).workspaceNilIfEmpty }
            .joined(separator: " · ")
    }
}

struct AudioFileMetadata: Equatable, Sendable {
    var title: String?
    var artist: String?
    var durationLabel: String?
    var format: String

    var hasReadableTags: Bool {
        title != nil || artist != nil || durationLabel != nil
    }
}

enum SongTextKind: String, Codable, Equatable, CaseIterable, Identifiable, Sendable {
    case notes
    case lyrics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notes:
            return "Notes"
        case .lyrics:
            return "Lyrics"
        }
    }

    var systemName: String {
        switch self {
        case .notes:
            return "text.badge.plus"
        case .lyrics:
            return "music.mic"
        }
    }

    var placeholder: String {
        switch self {
        case .notes:
            return "Session notes, decisions, reminders."
        case .lyrics:
            return "Lyrics, topline ideas, phrases."
        }
    }
}

struct SongTextDocument: Codable, Equatable, Identifiable, Sendable {
    var kind: SongTextKind
    var text: String
    var updatedAt: Date?

    var id: String { kind.id }

    init(kind: SongTextKind, text: String = "", updatedAt: Date? = nil) {
        self.kind = kind
        self.text = text
        self.updatedAt = updatedAt
    }

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmpty: Bool {
        trimmedText.isEmpty
    }

    var previewText: String {
        isEmpty ? kind.placeholder : trimmedText
    }

    static let emptySet = SongTextKind.allCases.map { SongTextDocument(kind: $0) }

    static func normalizedSet(from documents: [SongTextDocument]) -> [SongTextDocument] {
        SongTextKind.allCases.map { kind in
            documents.first { $0.kind == kind } ?? SongTextDocument(kind: kind)
        }
    }
}

struct MotionArtwork: Codable, Equatable, Sendable {
    var localFileName: String
    var sourceFileName: String
    var variant: MotionArtworkVariant

    var displayName: String {
        sourceFileName.isEmpty ? "Motion artwork" : sourceFileName
    }

    var playbackIdentity: String {
        "\(variant.rawValue):\(localFileName)"
    }
}

enum MotionArtworkVariant: String, Codable, Equatable, Sendable {
    case square
    case portrait
}

struct SongAttachment: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var kind: String
    var name: String
    var category: String
    var subtitle: String
    var size: String
    var localFileName: String

    init(
        id: UUID,
        kind: String,
        name: String,
        category: String,
        subtitle: String,
        size: String,
        localFileName: String
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.category = category.isEmpty ? "File" : category
        self.subtitle = subtitle
        self.size = size
        self.localFileName = localFileName
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case name
        case category
        case subtitle
        case size
        case localFileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(String.self, forKey: .kind)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? Self.suggestedCategory(forKind: kind)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        size = try container.decode(String.self, forKey: .size)
        localFileName = try container.decode(String.self, forKey: .localFileName)
    }

    var color: Color {
        switch kind {
        case "WAV", "AIFF", "MP3", "M4A":
            return .studioGold
        case "ZIP":
            return .studioMint
        case "PTX", "LOGICX":
            return .studioBlue
        case "TXT", "MD", "PDF":
            return .studioRose
        default:
            return .studioLavender
        }
    }
}

enum WaveformMarkerColorToken: String, Codable, Equatable, CaseIterable, Sendable {
    case rose
    case gold
    case blue
    case mint

    var color: Color {
        switch self {
        case .rose:
            return .studioRose
        case .gold:
            return .studioGold
        case .blue:
            return .studioBlue
        case .mint:
            return .studioMint
        }
    }

    var title: String {
        switch self {
        case .rose:
            return "Rose"
        case .gold:
            return "Gold"
        case .blue:
            return "Blue"
        case .mint:
            return "Mint"
        }
    }

    var symbolName: String {
        switch self {
        case .rose:
            return "diamond.fill"
        case .gold:
            return "circle.fill"
        case .blue:
            return "square.fill"
        case .mint:
            return "triangle.fill"
        }
    }
}

struct WaveformMarker: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var position: CGFloat
    var height: CGFloat
    var colorToken: WaveformMarkerColorToken
    var isResolved: Bool
    var time: String
    var note: String

    var color: Color {
        colorToken.color
    }

    init(
        id: UUID,
        position: CGFloat,
        height: CGFloat,
        colorToken: WaveformMarkerColorToken,
        isResolved: Bool = false,
        time: String,
        note: String
    ) {
        self.id = id
        self.position = min(max(position, 0), 1)
        self.height = max(height, 0.01)
        self.colorToken = colorToken
        self.isResolved = isResolved
        self.time = time
        self.note = note
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case position
        case height
        case colorToken
        case isResolved
        case time
        case note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        position = min(max(try container.decode(CGFloat.self, forKey: .position), 0), 1)
        height = max(try container.decode(CGFloat.self, forKey: .height), 0.01)
        colorToken = try container.decodeIfPresent(WaveformMarkerColorToken.self, forKey: .colorToken) ?? .gold
        isResolved = try container.decodeIfPresent(Bool.self, forKey: .isResolved) ?? false
        time = try container.decode(String.self, forKey: .time)
        note = try container.decode(String.self, forKey: .note)
    }

    static func created(
        position: CGFloat,
        time: String,
        existingCount: Int,
        note: String = ""
    ) -> WaveformMarker {
        let tokens = WaveformMarkerColorToken.allCases
        return WaveformMarker(
            id: UUID(),
            position: position,
            height: 0.54 + CGFloat(existingCount % 4) * 0.08,
            colorToken: tokens[existingCount % tokens.count],
            isResolved: false,
            time: time,
            note: note
        )
    }

    var accessibilitySummary: String {
        let status = isResolved ? "Resolved" : "Open"
        let noteSummary = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "no note"
            : "note: \(note.trimmingCharacters(in: .whitespacesAndNewlines))"

        return "\(status) \(colorToken.title.lowercased()) marker at \(time), \(noteSummary)"
    }
}

enum WaveformMarkerFilter: String, Equatable, CaseIterable, Identifiable, Sendable {
    case all
    case open
    case resolved
    case noted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .open:
            return "Open"
        case .resolved:
            return "Resolved"
        case .noted:
            return "With notes"
        }
    }
}

struct StudioAttachment: Identifiable {
    let id: UUID
    var kind: String
    var name: String
    var subtitle: String
    var size: String
    var color: Color
}

struct AttachmentCategorySection: Equatable, Identifiable, Sendable {
    var title: String
    var attachments: [SongAttachment]

    var id: String {
        title.lowercased()
    }
}

enum AttachmentCategoryFilter {
    static let all = "All"
}

enum SleeveArtwork: Codable, Equatable, Sendable {
    case walking
    case photo
    case number
    case stack
    case blank
    case columns
    case customImage(localFileName: String, sourceFileName: String)

    private enum CodingKeys: String, CodingKey {
        case walking
        case photo
        case number
        case stack
        case blank
        case columns
        case customImage
        case localFileName
        case sourceFileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.walking) {
            self = .walking
        } else if container.contains(.photo) {
            self = .photo
        } else if container.contains(.number) {
            self = .number
        } else if container.contains(.stack) {
            self = .stack
        } else if container.contains(.blank) {
            self = .blank
        } else if container.contains(.columns) {
            self = .columns
        } else if container.contains(.customImage) {
            let imageContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .customImage)
            self = .customImage(
                localFileName: try imageContainer.decode(String.self, forKey: .localFileName),
                sourceFileName: try imageContainer.decodeIfPresent(String.self, forKey: .sourceFileName) ?? "Album cover"
            )
        } else {
            self = .blank
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .walking:
            try container.encode(EmptyPayload(), forKey: .walking)
        case .photo:
            try container.encode(EmptyPayload(), forKey: .photo)
        case .number:
            try container.encode(EmptyPayload(), forKey: .number)
        case .stack:
            try container.encode(EmptyPayload(), forKey: .stack)
        case .blank:
            try container.encode(EmptyPayload(), forKey: .blank)
        case .columns:
            try container.encode(EmptyPayload(), forKey: .columns)
        case .customImage(let localFileName, let sourceFileName):
            var imageContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .customImage)
            try imageContainer.encode(localFileName, forKey: .localFileName)
            try imageContainer.encode(sourceFileName, forKey: .sourceFileName)
        }
    }
}

private struct EmptyPayload: Codable, Equatable, Sendable {}

extension SleeveArtwork {
    var sourceFileName: String? {
        guard case .customImage(_, let sourceFileName) = self else { return nil }
        return sourceFileName
    }
}

enum WorkspaceScreen: Equatable, Sendable {
    case library
    case project
}

enum WorkspaceActionKind: String, Identifiable {
    case project
    case track
    case song

    var id: String { rawValue }

    var title: String {
        switch self {
        case .project:
            return "Project actions"
        case .track:
            return "Track actions"
        case .song:
            return "Song actions"
        }
    }
}

enum WorkspaceImportKind: Equatable, Sendable {
    case audio
    case animatedArtwork
    case projectCover
    case attachment

    var importingTitle: String {
        switch self {
        case .audio:
            return "Importing audio"
        case .animatedArtwork:
            return "Importing motion artwork"
        case .projectCover:
            return "Updating cover"
        case .attachment:
            return "Attaching files"
        }
    }

    var singularSuccessTitle: String {
        switch self {
        case .audio:
            return "Track imported"
        case .animatedArtwork:
            return "Motion artwork set"
        case .projectCover:
            return "Cover updated"
        case .attachment:
            return "File attached"
        }
    }

    var pluralSuccessTitle: String {
        switch self {
        case .audio:
            return "Tracks imported"
        case .animatedArtwork:
            return "Motion artwork set"
        case .projectCover:
            return "Cover updated"
        case .attachment:
            return "Files attached"
        }
    }

    var recoveryMessage: String {
        switch self {
        case .audio:
            return "In Files, download the audio locally first, then try again."
        case .animatedArtwork:
            return "Choose a local .mov or .mp4 motion-artwork file under 25 MB and 0:15, then try again."
        case .projectCover:
            return "Choose a local image or video from Files, then try again."
        case .attachment:
            return "In Files, download the file locally first, then try again."
        }
    }

#if DEBUG
    var debugRequestedImporterLabel: String {
        switch self {
        case .audio:
            return "Audio importer requested"
        case .animatedArtwork:
            return "Motion artwork importer requested"
        case .projectCover:
            return "Project cover importer requested"
        case .attachment:
            return "Attachment importer requested"
        }
    }
#endif
}

enum WorkspaceImportStatus: Equatable, Sendable {
    case importing(kind: WorkspaceImportKind, total: Int)
    case success(kind: WorkspaceImportKind, imported: Int, failedFileNames: [String], skippedDuplicates: Int)
    case failure(kind: WorkspaceImportKind, failedFileNames: [String])
    case pickerFailure(kind: WorkspaceImportKind, reason: String)

    var title: String {
        switch self {
        case .importing(let kind, _):
            return kind.importingTitle
        case .success(let kind, let imported, _, let skippedDuplicates):
            if imported == 0, skippedDuplicates > 0 {
                return "Already in this sleeve"
            }
            return imported == 1 ? kind.singularSuccessTitle : kind.pluralSuccessTitle
        case .failure:
            return "Import failed"
        case .pickerFailure:
            return "Files could not open"
        }
    }

    var message: String {
        switch self {
        case .importing(let kind, let total):
            if kind == .audio {
                return total == 1 ? "Copying one audio file into the project." : "Copying \(total) audio files into the project."
            }
            if kind == .animatedArtwork {
                return "Copying motion artwork into this song."
            }
            if kind == .projectCover {
                return "Copying cover art into this project."
            }
            return total == 1 ? "Copying one file into this song." : "Copying \(total) files into this song."
        case .success(_, let imported, let failedFileNames, let skippedDuplicates):
            var parts: [String] = []
            if imported > 0 {
                parts.append(imported == 1 ? "1 added" : "\(imported) added")
            }
            if skippedDuplicates > 0 {
                parts.append(skippedDuplicates == 1 ? "1 duplicate skipped" : "\(skippedDuplicates) duplicates skipped")
            }
            if !failedFileNames.isEmpty {
                parts.append(failedFileNames.count == 1 ? "1 failed" : "\(failedFileNames.count) failed")
            }
            return [parts.joined(separator: " · "), failedSummary(fileNames: failedFileNames)]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
        case .failure(let kind, let failedFileNames):
            let failureSummary = failedFileNames.isEmpty
                ? "Files did not return a readable local copy."
                : failedSummary(fileNames: failedFileNames, kind: kind)
            return [failureSummary, kind.recoveryMessage]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
        case .pickerFailure(let kind, let reason):
            return [
                "Files could not hand the selection back to the app.",
                reason.trimmingCharacters(in: .whitespacesAndNewlines),
                kind.recoveryMessage
            ]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
        }
    }

    var isLoading: Bool {
        if case .importing = self {
            return true
        }

        return false
    }

    var needsAttention: Bool {
        switch self {
        case .failure, .pickerFailure:
            return true
        case .success(_, _, let failedFileNames, let skippedDuplicates):
            return !failedFileNames.isEmpty || skippedDuplicates > 0
        case .importing:
            return false
        }
    }

    var autoDismissDelayMilliseconds: Int {
        switch self {
        case .failure, .pickerFailure:
            return 9_000
        default:
            return needsAttention ? 4_800 : 1_150
        }
    }

    var accessibilityLabel: String {
        [title, message.accessibilitySentence]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }

    private func failedSummary(fileNames: [String], kind: WorkspaceImportKind? = nil) -> String {
        guard !fileNames.isEmpty else {
            return ""
        }

        let action = (kind == .animatedArtwork || kind == .projectCover) ? "use" : "copy"

        if fileNames.count == 1, let fileName = fileNames.first {
            return "Could not \(action) \(fileName)."
        }

        let visibleNames = fileNames.prefix(2).joined(separator: ", ")
        let remainingCount = fileNames.count - 2
        return remainingCount > 0
            ? "Could not \(action) \(visibleNames), and \(remainingCount) more."
            : "Could not \(action) \(visibleNames)."
    }
}

private extension String {
    var accessibilitySentence: String {
        let normalized = replacingOccurrences(of: " · ", with: ", ")

        guard normalized.contains("\n") else {
            return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return normalized
            .split(separator: "\n")
            .map { line in
                let sentence = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let last = sentence.last, !".!?".contains(last) else {
                    return sentence
                }
                return "\(sentence)."
            }
            .joined(separator: " ")
    }
}

enum WorkspaceDestructiveAction: Equatable, Identifiable {
    case deleteProject
    case removeTrack(MusicTrack)
    case deleteSong(MusicTrack)
    case removeAttachment(trackID: UUID, attachment: SongAttachment)

    var id: String {
        switch self {
        case .deleteProject:
            return "delete-project"
        case .removeTrack(let track):
            return "remove-track-\(track.id.uuidString)"
        case .deleteSong(let track):
            return "delete-song-\(track.id.uuidString)"
        case .removeAttachment(let trackID, let attachment):
            return "remove-attachment-\(trackID.uuidString)-\(attachment.id.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .deleteProject:
            return "Delete project?"
        case .removeTrack:
            return "Remove track?"
        case .deleteSong:
            return "Delete song?"
        case .removeAttachment:
            return "Remove file?"
        }
    }

    var message: String {
        switch self {
        case .deleteProject:
            return "This removes the project from this library."
        case .removeTrack(let track):
            return "\(track.title) will be removed from the project."
        case .deleteSong(let track):
            return "\(track.title) will be removed from this song container and project."
        case .removeAttachment(_, let attachment):
            return "\(attachment.name) will be removed from this song container and its local copied file will be deleted."
        }
    }

    var confirmTitle: String {
        switch self {
        case .deleteProject:
            return "Delete Project"
        case .removeTrack:
            return "Remove Track"
        case .deleteSong:
            return "Delete Song"
        case .removeAttachment:
            return "Remove File"
        }
    }
}

enum LoadRitualPhase: Equatable {
    case idle
    case creating
    case loading
}

extension MusicProject {
    static let sampleProjects: [MusicProject] = [
        MusicProject(
            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            title: "Untitled project",
            creator: "Draft",
            trackCount: 0,
            runtime: "",
            sleeve: .blank,
            state: .regular,
            tracks: []
        )
    ]

    static let freshProject = MusicProject(
        id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
        title: "Untitled project",
        creator: "Draft",
        trackCount: 0,
        runtime: "",
        sleeve: .blank,
        state: .fresh,
        tracks: []
    )
}

extension MusicTrack {
    static let placeholder = MusicTrack(
        id: UUID(uuidString: "aaaaaaa0-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
        title: "No track selected",
        date: "Add audio",
        duration: "0:00"
    )

    static func imported(from url: URL, localFileName: String?, metadata: AudioFileMetadata? = nil) -> MusicTrack {
        MusicTrack(
            id: UUID(),
            title: importedDisplayTitle(from: url, metadata: metadata),
            date: Date.now.formatted(.dateTime.month(.abbreviated).day()),
            duration: metadata?.durationLabel ?? "Imported",
            localFileName: localFileName,
            artistName: metadata?.artist,
            audioFormat: metadata?.format
        )
    }

    static func importedDisplayTitle(from url: URL, metadata: AudioFileMetadata? = nil) -> String {
        if let metadataTitle = metadata?.title?.trimmingCharacters(in: .whitespacesAndNewlines),
           !metadataTitle.isEmpty {
            return metadataTitle
        }

        let invalidCharacters = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "/"))
        let title = url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: invalidCharacters)

        return title.isEmpty ? "Imported audio" : title
    }

    func matchesImportedSource(_ url: URL) -> Bool {
        title.localizedCaseInsensitiveCompare(Self.importedDisplayTitle(from: url)) == .orderedSame
    }

    func matchesStudioSearch(_ query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return true
        }

        let searchableValues = [
            title,
            date,
            duration,
            artistName ?? "",
            audioFormat ?? ""
        ] + attachments.flatMap { attachment in
            [
                attachment.name,
                attachment.normalizedCategory,
                attachment.kind,
                attachment.subtitle,
                attachment.size
            ]
        } + markers.flatMap { marker in
            [
                marker.time,
                marker.note
            ]
        } + textDocuments.flatMap { document in
            [
                document.kind.title,
                document.trimmedText
            ]
        }

        return searchableValues.contains {
            $0.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    static let sampleTracks: [MusicTrack] = []
}

extension SongAttachment {
    var normalizedCategory: String {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedCategory.isEmpty ? "File" : trimmedCategory
    }

    static func imported(from url: URL, localFileName: String, fileSize: Int64?) -> SongAttachment {
        let fileExtension = url.pathExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        let kind = fileExtension.isEmpty ? "FILE" : fileExtension.uppercased()

        return SongAttachment(
            id: UUID(),
            kind: String(kind.prefix(6)),
            name: url.lastPathComponent.isEmpty ? "Attached file" : url.lastPathComponent,
            category: suggestedCategory(forKind: kind),
            subtitle: Date.now.formatted(.dateTime.month(.abbreviated).day()),
            size: fileSize.map(Self.fileSizeLabel) ?? "File",
            localFileName: localFileName
        )
    }

    static func suggestedCategory(forKind kind: String) -> String {
        switch kind.uppercased() {
        case "WAV", "AIFF", "AIF", "MP3", "M4A":
            return "Audio"
        case "PTX", "LOGICX", "FLP", "ALS":
            return "Session"
        case "ZIP":
            return "Archive"
        case "TXT", "MD", "PDF", "DOC", "DOCX":
            return "Notes"
        case "JPG", "JPEG", "PNG", "HEIC":
            return "Artwork"
        default:
            return "File"
        }
    }

    private static func fileSizeLabel(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

extension Array where Element == SongAttachment {
    var studioCategoryFilters: [String] {
        var categoriesByLowercaseName: [String: String] = [:]
        for attachment in self {
            let category = attachment.normalizedCategory
            let key = category.lowercased()
            if categoriesByLowercaseName[key] == nil {
                categoriesByLowercaseName[key] = category
            }
        }

        let categories = Swift.Array(categoriesByLowercaseName.values)
        return [AttachmentCategoryFilter.all] + categories.sorted { first, second in
            first.localizedCaseInsensitiveCompare(second) == .orderedAscending
        }
    }

    func filteredByStudioCategory(_ category: String) -> [SongAttachment] {
        guard category != AttachmentCategoryFilter.all else {
            return self
        }

        return filter { $0.normalizedCategory.localizedCaseInsensitiveCompare(category) == .orderedSame }
    }

    var studioCategorySections: [AttachmentCategorySection] {
        let grouped = Dictionary(grouping: self, by: \.normalizedCategory)

        return grouped
            .map { category, attachments in
                AttachmentCategorySection(title: category, attachments: attachments)
            }
            .sorted { first, second in
                first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }
    }
}

extension Array where Element == MusicTrack {
    func filteredByStudioSearch(_ query: String) -> [MusicTrack] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return self
        }

        return filter { $0.matchesStudioSearch(trimmedQuery) }
    }
}

extension Array where Element == WaveformMarker {
    func filtered(by filter: WaveformMarkerFilter) -> [WaveformMarker] {
        switch filter {
        case .all:
            return self
        case .open:
            return self.filter { !$0.isResolved }
        case .resolved:
            return self.filter(\.isResolved)
        case .noted:
            return self.filter {
                !$0.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
    }

    func count(for filter: WaveformMarkerFilter) -> Int {
        filtered(by: filter).count
    }
}

extension WaveformMarker {
    static let sampleMarkers: [WaveformMarker] = [
        WaveformMarker(
            id: UUID(uuidString: "bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            position: 0.24,
            height: 0.82,
            colorToken: .rose,
            time: "0:42",
            note: "Cut air before the verse pickup."
        ),
        WaveformMarker(
            id: UUID(uuidString: "bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            position: 0.48,
            height: 0.70,
            colorToken: .gold,
            time: "1:22",
            note: "Lower lead vocal two dB before hook."
        ),
        WaveformMarker(
            id: UUID(uuidString: "bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            position: 0.73,
            height: 0.76,
            colorToken: .blue,
            time: "2:05",
            note: "Try muting the counter melody here."
        )
    ]
}

extension StudioAttachment {
    static let sampleAttachments: [StudioAttachment] = [
        StudioAttachment(
            id: UUID(uuidString: "ccccccc1-cccc-cccc-cccc-cccccccccccc")!,
            kind: "WAV",
            name: "main bounce.wav",
            subtitle: "Main playback file",
            size: "48 MB",
            color: .studioGold
        ),
        StudioAttachment(
            id: UUID(uuidString: "ccccccc2-cccc-cccc-cccc-cccccccccccc")!,
            kind: "ZIP",
            name: "Beat stems - kick, snare, 808, melody.zip",
            subtitle: "Stem pack",
            size: "326 MB",
            color: .studioMint
        ),
        StudioAttachment(
            id: UUID(uuidString: "ccccccc3-cccc-cccc-cccc-cccccccccccc")!,
            kind: "PTX",
            name: "vocal comp.ptx",
            subtitle: "Pro Tools session",
            size: "18 MB",
            color: .studioBlue
        ),
        StudioAttachment(
            id: UUID(uuidString: "ccccccc4-cccc-cccc-cccc-cccccccccccc")!,
            kind: "REF",
            name: "reference mix notes.txt",
            subtitle: "Mix direction",
            size: "4 KB",
            color: .studioRose
        ),
        StudioAttachment(
            id: UUID(uuidString: "ccccccc5-cccc-cccc-cccc-cccccccccccc")!,
            kind: "LYR",
            name: "hook rewrite lyrics.md",
            subtitle: "Writing notes",
            size: "12 KB",
            color: .studioLavender
        ),
        StudioAttachment(
            id: UUID(uuidString: "ccccccc6-cccc-cccc-cccc-cccccccccccc")!,
            kind: "MIX",
            name: "mix v7 alt master.wav",
            subtitle: "Older version",
            size: "52 MB",
            color: .studioIce
        )
    ]
}

extension Array where Element == CGFloat {
    static let waveformBars: [CGFloat] = [
        0.17, 0.25, 0.14, 0.46, 0.62, 0.71, 0.86, 0.68, 0.54, 0.92, 0.80, 0.48,
        0.35, 0.22, 0.44, 0.58, 0.66, 0.74, 0.52, 0.31, 0.23, 0.47, 0.76, 0.88,
        0.70, 0.57, 0.39, 0.28, 0.50, 0.64, 0.72, 0.45, 0.29, 0.36, 0.80, 0.91,
        0.77, 0.52, 0.38, 0.61, 0.83, 0.69, 0.57, 0.43, 0.30, 0.21, 0.40, 0.59,
        0.73, 0.88, 0.79, 0.63, 0.46, 0.34, 0.25, 0.39, 0.55, 0.70, 0.84, 0.76,
        0.58, 0.41
    ]
}

private extension String {
    var workspaceNilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

extension Color {
    static let studioBackground = Color(red: 0.050, green: 0.052, blue: 0.050)
    static let studioPanel = Color(red: 0.105, green: 0.108, blue: 0.104)
    static let studioPanelRaised = Color(red: 0.136, green: 0.139, blue: 0.132)
    static let studioText = Color(red: 0.949, green: 0.941, blue: 0.918)
    static let studioMuted = Color(red: 0.949, green: 0.941, blue: 0.918).opacity(0.58)
    static let studioSoftLine = Color.white.opacity(0.09)
    static let studioGold = Color(red: 0.847, green: 0.765, blue: 0.478)
    static let studioRose = Color(red: 0.824, green: 0.557, blue: 0.514)
    static let studioBlue = Color(red: 0.537, green: 0.659, blue: 0.847)
    static let studioMint = Color(red: 0.498, green: 0.725, blue: 0.616)
    static let studioLavender = Color(red: 0.749, green: 0.655, blue: 0.929)
    static let studioIce = Color(red: 0.659, green: 0.784, blue: 0.847)
    static let studioCream = Color(red: 1.000, green: 0.945, blue: 0.855)
    static let studioBabyBlue = Color(red: 0.388, green: 0.780, blue: 1.000)
    static let studioBabyPink = Color(red: 1.000, green: 0.663, blue: 0.804)
}
