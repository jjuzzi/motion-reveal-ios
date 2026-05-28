import QuickLook
import SwiftUI
import UniformTypeIdentifiers

extension View {
    func workspacePresentations(
        activeMenu: Binding<WorkspaceActionKind?>,
        activeMenuTrack: MusicTrack?,
        selectedProject: MusicProject,
        currentTrack: MusicTrack,
        pendingDestructiveAction: Binding<WorkspaceDestructiveAction?>,
        isDestructiveConfirmationPresented: Binding<Bool>,
        renameDraft: Binding<WorkspaceRenameDraft?>,
        attachmentDraft: Binding<WorkspaceAttachmentDraft?>,
        songTextDraft: Binding<WorkspaceSongTextDraft?>,
        markerDraft: Binding<WorkspaceMarkerDraft?>,
        exportItem: Binding<WorkspaceExportItem?>,
        previewAttachmentURL: Binding<URL?>,
        isAudioImporterPresented: Binding<Bool>,
        isAnimatedArtworkImporterPresented: Binding<Bool>,
        isProjectCoverImporterPresented: Binding<Bool>,
        isAttachmentImporterPresented: Binding<Bool>,
        actions: WorkspacePresentationActions
    ) -> some View {
        modifier(
            WorkspacePresentationsModifier(
                activeMenu: activeMenu,
                activeMenuTrack: activeMenuTrack,
                selectedProject: selectedProject,
                currentTrack: currentTrack,
                pendingDestructiveAction: pendingDestructiveAction,
                isDestructiveConfirmationPresented: isDestructiveConfirmationPresented,
                renameDraft: renameDraft,
                attachmentDraft: attachmentDraft,
                songTextDraft: songTextDraft,
                markerDraft: markerDraft,
                exportItem: exportItem,
                previewAttachmentURL: previewAttachmentURL,
                isAudioImporterPresented: isAudioImporterPresented,
                isAnimatedArtworkImporterPresented: isAnimatedArtworkImporterPresented,
                isProjectCoverImporterPresented: isProjectCoverImporterPresented,
                isAttachmentImporterPresented: isAttachmentImporterPresented,
                actions: actions
            )
        )
    }
}

struct WorkspacePresentationActions {
    let renameProject: () -> Void
    let changeProjectCover: () -> Void
    let duplicateProject: () -> Void
    let exportProject: () -> Void
    let toggleProjectPin: () -> Void
    let deleteProject: () -> Void
    let renameTrack: (MusicTrack) -> Void
    let exportTrack: (MusicTrack) -> Void
    let replaceTrackFile: () -> Void
    let setMotionArtwork: (MusicTrack) -> Void
    let removeTrack: (MusicTrack) -> Void
    let editMarkers: () -> Void
    let addStudioFile: () -> Void
    let exportSong: (MusicTrack) -> Void
    let deleteSong: (MusicTrack) -> Void
    let trackUnavailable: () -> Void
    let performDestructiveAction: (WorkspaceDestructiveAction) -> Void
    let cancelDestructiveAction: () -> Void
    let saveRenameDraft: () -> Void
    let cancelRenameDraft: () -> Void
    let saveAttachmentDraft: () -> Void
    let cancelAttachmentDraft: () -> Void
    let saveSongTextDraft: () -> Void
    let cancelSongTextDraft: () -> Void
    let saveMarkerDraft: () -> Void
    let deleteMarkerDraft: () -> Void
    let cancelMarkerDraft: () -> Void
    let handleAudioImport: (Result<[URL], Error>) -> Void
    let handleAnimatedArtworkImport: (Result<[URL], Error>) -> Void
    let handleProjectCoverImport: (Result<[URL], Error>) -> Void
    let handleAttachmentImport: (Result<[URL], Error>) -> Void
}

private struct WorkspacePresentationsModifier: ViewModifier {
    @Binding var activeMenu: WorkspaceActionKind?
    let activeMenuTrack: MusicTrack?
    let selectedProject: MusicProject
    let currentTrack: MusicTrack
    @Binding var pendingDestructiveAction: WorkspaceDestructiveAction?
    @Binding var isDestructiveConfirmationPresented: Bool
    @Binding var renameDraft: WorkspaceRenameDraft?
    @Binding var attachmentDraft: WorkspaceAttachmentDraft?
    @Binding var songTextDraft: WorkspaceSongTextDraft?
    @Binding var markerDraft: WorkspaceMarkerDraft?
    @Binding var exportItem: WorkspaceExportItem?
    @Binding var previewAttachmentURL: URL?
    @Binding var isAudioImporterPresented: Bool
    @Binding var isAnimatedArtworkImporterPresented: Bool
    @Binding var isProjectCoverImporterPresented: Bool
    @Binding var isAttachmentImporterPresented: Bool
    let actions: WorkspacePresentationActions

    func body(content: Content) -> some View {
        content
            .overlay {
                WorkspaceActionTrayOverlay(
                    kind: activeMenu,
                    activeMenuTrack: activeMenuTrack,
                    selectedProject: selectedProject,
                    currentTrack: currentTrack,
                    dismiss: { activeMenu = nil },
                    renameProject: actions.renameProject,
                    changeProjectCover: actions.changeProjectCover,
                    duplicateProject: actions.duplicateProject,
                    exportProject: actions.exportProject,
                    toggleProjectPin: actions.toggleProjectPin,
                    deleteProject: actions.deleteProject,
                    renameTrack: actions.renameTrack,
                    exportTrack: actions.exportTrack,
                    replaceTrackFile: actions.replaceTrackFile,
                    setMotionArtwork: actions.setMotionArtwork,
                    removeTrack: actions.removeTrack,
                    editMarkers: actions.editMarkers,
                    addStudioFile: actions.addStudioFile,
                    exportSong: actions.exportSong,
                    deleteSong: actions.deleteSong,
                    trackUnavailable: actions.trackUnavailable
                )
            }
            .alert(
                pendingDestructiveAction?.title ?? "Confirm",
                isPresented: $isDestructiveConfirmationPresented,
                presenting: pendingDestructiveAction
            ) { action in
                Button(action.confirmTitle, role: .destructive) {
                    actions.performDestructiveAction(action)
                }
                Button("Cancel", role: .cancel, action: actions.cancelDestructiveAction)
            } message: { action in
                Text(action.message)
            }
            .sheet(item: $renameDraft) { _ in
                RenameSheetBindingAdapter(draft: $renameDraft) { draft in
                    WorkspaceRenameSheet(
                        draft: draft,
                        save: actions.saveRenameDraft,
                        cancel: actions.cancelRenameDraft
                    )
                }
            }
            .sheet(item: $attachmentDraft) { _ in
                AttachmentSheetBindingAdapter(draft: $attachmentDraft) { draft in
                    WorkspaceAttachmentSheet(
                        draft: draft,
                        save: actions.saveAttachmentDraft,
                        cancel: actions.cancelAttachmentDraft
                    )
                }
            }
            .sheet(item: $songTextDraft) { _ in
                SongTextSheetBindingAdapter(draft: $songTextDraft) { draft in
                    WorkspaceSongTextSheet(
                        draft: draft,
                        save: actions.saveSongTextDraft,
                        cancel: actions.cancelSongTextDraft
                    )
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { markerDraft != nil },
                    set: { isPresented in
                        if !isPresented {
                            actions.cancelMarkerDraft()
                        }
                    }
                )
            ) {
                MarkerSheetBindingAdapter(draft: $markerDraft) { draft in
                    WorkspaceMarkerSheet(
                        draft: draft,
                        save: actions.saveMarkerDraft,
                        delete: actions.deleteMarkerDraft,
                        cancel: actions.cancelMarkerDraft
                    )
                }
            }
            .sheet(item: $exportItem, content: WorkspaceExportSheet.init)
            .quickLookPreview($previewAttachmentURL)
            .sheet(isPresented: $isAudioImporterPresented) {
                WorkspaceDocumentPicker(
                    isPresented: $isAudioImporterPresented,
                    allowedContentTypes: WorkspaceImportContentPolicy.audioPickerTypes,
                    allowsMultipleSelection: WorkspaceImportContentPolicy.audioAllowsMultipleSelection,
                    onCompletion: actions.handleAudioImport
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $isAnimatedArtworkImporterPresented) {
                WorkspaceDocumentPicker(
                    isPresented: $isAnimatedArtworkImporterPresented,
                    allowedContentTypes: WorkspaceImportContentPolicy.animatedArtworkPickerTypes,
                    allowsMultipleSelection: WorkspaceImportContentPolicy.animatedArtworkAllowsMultipleSelection,
                    onCompletion: actions.handleAnimatedArtworkImport
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $isProjectCoverImporterPresented) {
                WorkspaceDocumentPicker(
                    isPresented: $isProjectCoverImporterPresented,
                    allowedContentTypes: WorkspaceImportContentPolicy.projectCoverPickerTypes,
                    allowsMultipleSelection: WorkspaceImportContentPolicy.projectCoverAllowsMultipleSelection,
                    onCompletion: actions.handleProjectCoverImport
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $isAttachmentImporterPresented) {
                WorkspaceDocumentPicker(
                    isPresented: $isAttachmentImporterPresented,
                    allowedContentTypes: WorkspaceImportContentPolicy.attachmentPickerTypes,
                    allowsMultipleSelection: WorkspaceImportContentPolicy.attachmentAllowsMultipleSelection,
                    onCompletion: actions.handleAttachmentImport
                )
                .ignoresSafeArea()
            }
    }
}
