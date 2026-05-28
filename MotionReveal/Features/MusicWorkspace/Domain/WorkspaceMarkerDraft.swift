import Foundation

struct WorkspaceMarkerDraft: Equatable, Identifiable {
    let id: UUID
    let trackID: UUID
    let markerID: UUID
    var time: String
    var note: String
    var colorToken: WaveformMarkerColorToken
    var isResolved: Bool

    init(trackID: UUID, marker: WaveformMarker) {
        id = marker.id
        self.trackID = trackID
        markerID = marker.id
        time = marker.time
        note = marker.note
        colorToken = marker.colorToken
        isResolved = marker.isResolved
    }

    var trimmedTime: String {
        time.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedTime.isEmpty
    }
}
