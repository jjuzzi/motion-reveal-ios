import Foundation
import SwiftUI

struct WorkspaceMarkerMutationResult: Equatable {
    let marker: WaveformMarker
    let updatedTrack: MusicTrack
}

struct WorkspaceMarkerDeletionResult: Equatable {
    let deletedMarkerID: UUID
    let updatedTrack: MusicTrack
}

struct WorkspaceTrackMutationExecutor {
    static func markers(forTrackID trackID: UUID, selectedProject: MusicProject) -> [WaveformMarker]? {
        selectedProject.tracks.first(where: { $0.id == trackID })?.markers
    }

    static func renameTrack(
        id trackID: UUID,
        to title: String,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> MusicTrack? {
        updateTrack(trackID, selectedProject: &selectedProject, projects: &projects) { track in
            track.title = title
            return true
        }
    }

    static func updateAttachmentDetails(
        trackID: UUID,
        attachmentID: UUID,
        name: String,
        category: String,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> MusicTrack? {
        updateTrack(trackID, selectedProject: &selectedProject, projects: &projects) { track in
            guard let attachmentIndex = track.attachments.firstIndex(where: { $0.id == attachmentID }) else {
                return false
            }

            track.attachments[attachmentIndex].name = name
            track.attachments[attachmentIndex].category = category
            return true
        }
    }

    static func updateSongText(
        trackID: UUID,
        kind: SongTextKind,
        text: String,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject],
        updatedAt: Date = Date()
    ) -> MusicTrack? {
        updateTrack(trackID, selectedProject: &selectedProject, projects: &projects) { track in
            var documents = track.textDocuments
            let updatedDocument = SongTextDocument(
                kind: kind,
                text: text,
                updatedAt: text.isEmpty ? nil : updatedAt
            )

            if let documentIndex = documents.firstIndex(where: { $0.kind == kind }) {
                documents[documentIndex] = updatedDocument
            } else {
                documents.append(updatedDocument)
            }

            track.textDocuments = SongTextDocument.normalizedSet(from: documents)
            return true
        }
    }

    static func setAnimatedArtwork(
        _ artwork: MotionArtwork,
        forTrackID trackID: UUID,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> MusicTrack? {
        updateTrack(trackID, selectedProject: &selectedProject, projects: &projects) { track in
            track.animatedArtwork = artwork
            return true
        }
    }

    static func updateMarkers(
        _ markers: [WaveformMarker],
        forTrackID trackID: UUID,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> MusicTrack? {
        updateTrack(trackID, selectedProject: &selectedProject, projects: &projects) { track in
            track.markers = markers
            return true
        }
    }

    static func addMarker(
        position: CGFloat,
        time: String,
        forTrackID trackID: UUID,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> WorkspaceMarkerMutationResult? {
        var createdMarker: WaveformMarker?
        guard let updatedTrack = updateTrack(trackID, selectedProject: &selectedProject, projects: &projects, mutate: { track in
            let marker = WaveformMarker.created(
                position: position,
                time: time,
                existingCount: track.markers.count
            )
            track.markers.append(marker)
            createdMarker = marker
            return true
        }), let createdMarker else {
            return nil
        }

        return WorkspaceMarkerMutationResult(marker: createdMarker, updatedTrack: updatedTrack)
    }

    static func saveMarkerDraft(
        _ draft: WorkspaceMarkerDraft,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> WorkspaceMarkerMutationResult? {
        guard draft.canSave else { return nil }

        var savedMarker: WaveformMarker?
        guard let updatedTrack = updateTrack(draft.trackID, selectedProject: &selectedProject, projects: &projects, mutate: { track in
            guard let markerIndex = track.markers.firstIndex(where: { $0.id == draft.markerID }) else {
                return false
            }

            track.markers[markerIndex].time = draft.trimmedTime
            track.markers[markerIndex].note = draft.trimmedNote
            track.markers[markerIndex].colorToken = draft.colorToken
            track.markers[markerIndex].isResolved = draft.isResolved
            savedMarker = track.markers[markerIndex]
            return true
        }), let savedMarker else {
            return nil
        }

        return WorkspaceMarkerMutationResult(marker: savedMarker, updatedTrack: updatedTrack)
    }

    static func deleteMarkerDraft(
        _ draft: WorkspaceMarkerDraft,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> WorkspaceMarkerDeletionResult? {
        guard let updatedTrack = updateTrack(draft.trackID, selectedProject: &selectedProject, projects: &projects, mutate: { track in
            track.markers.removeAll { $0.id == draft.markerID }
            return true
        }) else {
            return nil
        }

        return WorkspaceMarkerDeletionResult(deletedMarkerID: draft.markerID, updatedTrack: updatedTrack)
    }

    static func toggleMarkerResolved(
        _ marker: WaveformMarker,
        forTrackID trackID: UUID,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject]
    ) -> WorkspaceMarkerMutationResult? {
        var updatedMarker: WaveformMarker?
        guard let updatedTrack = updateTrack(trackID, selectedProject: &selectedProject, projects: &projects, mutate: { track in
            guard let markerIndex = track.markers.firstIndex(where: { $0.id == marker.id }) else {
                return false
            }

            track.markers[markerIndex].isResolved.toggle()
            updatedMarker = track.markers[markerIndex]
            return true
        }), let updatedMarker else {
            return nil
        }

        return WorkspaceMarkerMutationResult(marker: updatedMarker, updatedTrack: updatedTrack)
    }

    private static func updateTrack(
        _ trackID: UUID,
        selectedProject: inout MusicProject,
        projects: inout [MusicProject],
        mutate: (inout MusicTrack) -> Bool
    ) -> MusicTrack? {
        guard let trackIndex = selectedProject.tracks.firstIndex(where: { $0.id == trackID }) else {
            return nil
        }

        guard mutate(&selectedProject.tracks[trackIndex]) else {
            return nil
        }

        let updatedTrack = selectedProject.tracks[trackIndex]

        if let projectIndex = projects.firstIndex(where: { $0.id == selectedProject.id }) {
            projects[projectIndex] = selectedProject
        }

        return updatedTrack
    }
}
