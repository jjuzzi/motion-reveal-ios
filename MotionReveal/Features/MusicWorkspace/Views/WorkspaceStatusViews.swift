import SwiftUI

struct WorkspaceImportStatusOverlay: View {
    let status: WorkspaceImportStatus
    let retryImport: (WorkspaceImportKind) -> Void

    var body: some View {
        VStack(spacing: 14) {
            if status.isLoading {
                ProgressView()
                    .controlSize(.regular)
                    .tint(Color.studioGold)
            } else {
                Image(systemName: statusIconName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(statusIconColor)
            }

            VStack(spacing: 5) {
                Text(status.title)
                    .font(StudioType.control)
                    .foregroundStyle(Color.studioText)

                Text(status.message)
                    .font(StudioType.metadataSmall)
                    .foregroundStyle(Color.studioMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let retryKind = status.retryKind {
                Button {
                    retryImport(retryKind)
                } label: {
                    Label("Try again", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.studioBackground)
                        .frame(height: 34)
                        .padding(.horizontal, 16)
                        .background(Color.studioGold, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("import-status-retry")
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: 310)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 28, x: 0, y: 18)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("import-status-overlay")
    }

    private var statusIconName: String {
        switch status {
        case .success(_, let imported, _, let skippedDuplicates):
            return imported == 0 && skippedDuplicates > 0 ? "checkmark.circle" : "checkmark"
        case .failure, .pickerFailure:
            return "exclamationmark.triangle"
        case .importing:
            return "arrow.down.doc"
        }
    }

    private var statusIconColor: Color {
        switch status {
        case .success:
            return Color.studioGold
        case .failure, .pickerFailure:
            return Color.studioRose
        case .importing:
            return Color.studioGold
        }
    }
}

private extension WorkspaceImportStatus {
    var retryKind: WorkspaceImportKind? {
        switch self {
        case .failure(let kind, _), .pickerFailure(let kind, _):
            return kind
        case .importing, .success:
            return nil
        }
    }
}

struct EmptyTrackStateView: View {
    let addTrack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "waveform.badge.plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.studioGold)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.06), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("No tracks yet")
                        .font(StudioType.rowTitle)
                        .foregroundStyle(Color.studioText)

                    Text("Import a bounce, demo, or voice memo to start the sleeve.")
                        .font(StudioType.metadataSmall)
                        .foregroundStyle(Color.studioMuted)
                }
            }

            Button(action: addTrack) {
                Label("Import audio", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.studioBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.studioGold, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("empty-import-audio")
        }
        .padding(18)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("empty-track-state")
    }
}
