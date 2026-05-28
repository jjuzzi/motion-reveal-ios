import SwiftUI

struct WorkspaceActionTrayOverlay: View {
    let kind: WorkspaceActionKind?
    let activeMenuTrack: MusicTrack?
    let selectedProject: MusicProject
    let currentTrack: MusicTrack
    let dismiss: () -> Void
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

    var body: some View {
        ZStack(alignment: .bottom) {
            if let kind {
                Color.black.opacity(0.36)
                    .ignoresSafeArea()
                    .onTapGesture(perform: dismiss)
                    .transition(.opacity)

                WorkspaceActionTray(
                    title: kind.title,
                    context: context(for: kind),
                    primaryActions: primaryActions(for: kind),
                    secondaryActions: secondaryActions(for: kind),
                    dismiss: dismiss
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: kind?.id)
        .allowsHitTesting(kind != nil)
        .accessibilityIdentifier("workspace-action-tray-overlay")
    }

    private func context(for kind: WorkspaceActionKind) -> String {
        switch kind {
        case .project:
            return selectedProject.title
        case .track:
            return activeMenuTrack?.title ?? "No track selected"
        case .song:
            return currentTrack.title
        }
    }

    private func primaryActions(for kind: WorkspaceActionKind) -> [WorkspaceTrayAction] {
        switch kind {
        case .project:
            return [
                WorkspaceTrayAction(title: "Rename", systemImage: "pencil", action: renameProject),
                WorkspaceTrayAction(title: "Cover", subtitle: "Image or motion artwork", systemImage: "photo", action: changeProjectCover),
                WorkspaceTrayAction(title: "Duplicate", subtitle: "Create an editable copy", systemImage: "rectangle.on.rectangle", action: duplicateProject),
                WorkspaceTrayAction(title: "Export", subtitle: "Share project package", systemImage: "square.and.arrow.up", action: exportProject),
                WorkspaceTrayAction(
                    title: selectedProject.state == .pinned ? "Unpin" : "Pin",
                    subtitle: selectedProject.state == .pinned ? "Remove from pinned" : "Keep near the top",
                    systemImage: selectedProject.state == .pinned ? "pin.slash" : "pin",
                    action: toggleProjectPin
                )
            ]
        case .track:
            guard let activeMenuTrack else {
                return [
                    WorkspaceTrayAction(title: "Unavailable", subtitle: "No track selected", systemImage: "exclamationmark.triangle", action: trackUnavailable)
                ]
            }

            return [
                WorkspaceTrayAction(title: "Rename", subtitle: "Edit track title", systemImage: "pencil") {
                    renameTrack(activeMenuTrack)
                },
                WorkspaceTrayAction(title: "Export", subtitle: "Share this audio file", systemImage: "square.and.arrow.up") {
                    exportTrack(activeMenuTrack)
                },
                WorkspaceTrayAction(title: "Replace", subtitle: "Swap source audio", systemImage: "waveform.badge.plus", action: replaceTrackFile)
            ]
        case .song:
            return [
                WorkspaceTrayAction(title: "Markers", subtitle: "Edit timing notes", systemImage: "flag", action: editMarkers),
                WorkspaceTrayAction(title: "Add File", subtitle: "Attach notes or stems", systemImage: "paperclip", action: addStudioFile),
                WorkspaceTrayAction(title: "Export", subtitle: "Share current song", systemImage: "square.and.arrow.up") {
                    exportSong(currentTrack)
                }
            ]
        }
    }

    private func secondaryActions(for kind: WorkspaceActionKind) -> [WorkspaceTrayAction] {
        switch kind {
        case .project:
            return [
                WorkspaceTrayAction(title: "Delete Project", subtitle: "Removes it from the library", systemImage: "trash", role: .destructive, action: deleteProject)
            ]
        case .track:
            guard let activeMenuTrack else { return [] }
            return [
                WorkspaceTrayAction(title: "Remove Track", subtitle: "Detach from this project", systemImage: "trash", role: .destructive) {
                    removeTrack(activeMenuTrack)
                }
            ]
        case .song:
            return [
                WorkspaceTrayAction(title: "Delete Song", subtitle: "Removes the song entry", systemImage: "trash", role: .destructive) {
                    deleteSong(currentTrack)
                }
            ]
        }
    }
}

private struct WorkspaceActionTray: View {
    let title: String
    let context: String
    let primaryActions: [WorkspaceTrayAction]
    let secondaryActions: [WorkspaceTrayAction]
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 38, height: 4)
                .padding(.top, 8)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(StudioType.control)
                        .foregroundStyle(Color.studioText)

                    Text(context)
                        .font(StudioType.metadataSmall)
                        .foregroundStyle(Color.studioMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.studioText.opacity(0.78))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.07), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close actions")
            }
            .padding(.top, 2)

            VStack(spacing: 6) {
                ForEach(primaryActions) { action in
                    WorkspaceTrayRowButton(action: action, dismiss: dismiss)
                }
            }
            .padding(6)
            .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.045), lineWidth: 1)
            }

            if !secondaryActions.isEmpty {
                VStack(spacing: 6) {
                    ForEach(secondaryActions) { action in
                        WorkspaceTrayRowButton(action: action, dismiss: dismiss)
                    }
                }
                .padding(6)
                .background(Color.studioRose.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.studioRose.opacity(0.14), lineWidth: 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: 402)
        .background(
            Color.studioPanelRaised.opacity(0.985),
            in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.035)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(0.34), radius: 26, x: 0, y: -10)
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
        .accessibilityIdentifier("workspace-action-tray")
    }
}

private struct WorkspaceTrayRowButton: View {
    let action: WorkspaceTrayAction
    let dismiss: () -> Void

    var body: some View {
        Button {
            dismiss()
            action.action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(action.iconTint)
                    .frame(width: 34, height: 34)
                    .background(action.iconFill, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(StudioType.metadata.weight(.semibold))
                        .foregroundStyle(action.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    if let subtitle = action.subtitle {
                        Text(subtitle)
                            .font(StudioType.metadataSmall)
                            .foregroundStyle(action.subtitleTint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(minHeight: action.subtitle == nil ? 48 : 54)
            .background(action.rowFill, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.title)
        .accessibilityHint(action.subtitle ?? "")
    }
}

private struct WorkspaceTrayAction: Identifiable {
    enum Role {
        case standard
        case destructive
    }

    let id = UUID()
    let title: String
    var subtitle: String?
    let systemImage: String
    var role: Role = .standard
    let action: () -> Void

    var tint: Color {
        switch role {
        case .standard:
            return Color.studioText.opacity(0.90)
        case .destructive:
            return Color.studioRose
        }
    }

    var subtitleTint: Color {
        switch role {
        case .standard:
            return Color.studioMuted
        case .destructive:
            return Color.studioRose.opacity(0.78)
        }
    }

    var iconTint: Color {
        switch role {
        case .standard:
            return Color.studioGold
        case .destructive:
            return Color.studioRose
        }
    }

    var iconFill: Color {
        switch role {
        case .standard:
            return Color.studioGold.opacity(0.11)
        case .destructive:
            return Color.studioRose.opacity(0.13)
        }
    }

    var rowFill: Color {
        switch role {
        case .standard:
            return Color.white.opacity(0.045)
        case .destructive:
            return Color.studioRose.opacity(0.08)
        }
    }
}
