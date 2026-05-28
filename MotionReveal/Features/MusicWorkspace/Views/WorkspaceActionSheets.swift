import SwiftUI

struct RenameSheetBindingAdapter<Content: View>: View {
    @Binding var draft: WorkspaceRenameDraft?
    let content: (Binding<WorkspaceRenameDraft>) -> Content

    var body: some View {
        if let currentDraft = draft {
            content(Binding(
                get: { draft ?? currentDraft },
                set: { updatedDraft in
                    guard draft != nil else { return }
                    draft = updatedDraft
                }
            ))
        }
    }
}

struct AttachmentSheetBindingAdapter<Content: View>: View {
    @Binding var draft: WorkspaceAttachmentDraft?
    let content: (Binding<WorkspaceAttachmentDraft>) -> Content

    var body: some View {
        if let currentDraft = draft {
            content(Binding(
                get: { draft ?? currentDraft },
                set: { updatedDraft in
                    guard draft != nil else { return }
                    draft = updatedDraft
                }
            ))
        }
    }
}

struct SongTextSheetBindingAdapter<Content: View>: View {
    @Binding var draft: WorkspaceSongTextDraft?
    let content: (Binding<WorkspaceSongTextDraft>) -> Content

    var body: some View {
        if let currentDraft = draft {
            content(Binding(
                get: { draft ?? currentDraft },
                set: { draft = $0 }
            ))
        }
    }
}

struct WorkspaceRenameSheet: View {
    @Binding var draft: WorkspaceRenameDraft
    let save: () -> Void
    let cancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $draft.text, axis: .vertical)
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(save)
                } footer: {
                    Text("This only changes the name inside this local library.")
                }
            }
            .navigationTitle(draft.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(draft.trimmedText.isEmpty)
                }
            }
        }
        .presentationDetents([.height(230), .medium])
        .accessibilityIdentifier("rename-sheet")
    }
}

struct WorkspaceAttachmentSheet: View {
    @Binding var draft: WorkspaceAttachmentDraft
    let save: () -> Void
    let cancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $draft.name, axis: .vertical)
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)

                    TextField("Category", text: $draft.category)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(save)
                } footer: {
                    Text("Category is just a local label. Change it to whatever this song needs.")
                }
            }
            .navigationTitle("Edit file")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!draft.canSave)
                }
            }
        }
        .presentationDetents([.height(280), .medium])
        .accessibilityIdentifier("attachment-sheet")
    }
}

struct WorkspaceSongTextSheet: View {
    @Binding var draft: WorkspaceSongTextDraft
    let save: () -> Void
    let cancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(draft.kind.placeholder)
                    .font(StudioType.metadata)
                    .foregroundStyle(Color.studioMuted)

                TextEditor(text: $draft.text)
                    .font(StudioType.metadata)
                    .foregroundStyle(Color.studioText)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 260)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(Color.studioBackground.ignoresSafeArea())
            .navigationTitle(draft.kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("song-text-sheet")
    }
}

struct MarkerSheetBindingAdapter<Content: View>: View {
    @Binding var draft: WorkspaceMarkerDraft?
    let content: (Binding<WorkspaceMarkerDraft>) -> Content

    var body: some View {
        if let currentDraft = draft {
            content(Binding(
                get: { draft ?? currentDraft },
                set: { updatedDraft in
                    if draft != nil {
                        draft = updatedDraft
                    }
                }
            ))
        }
    }
}

struct WorkspaceMarkerSheet: View {
    @Binding var draft: WorkspaceMarkerDraft
    let save: () -> Void
    let delete: () -> Void
    let cancel: () -> Void
    @FocusState private var focusedField: MarkerFocusField?

    private enum MarkerFocusField {
        case note
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Time", text: $draft.time)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.next)
                        .accessibilityIdentifier("marker-time-field")

                    TextField("Note", text: $draft.note, axis: .vertical)
                        .lineLimit(3...7)
                        .textInputAutocapitalization(.sentences)
                        .focused($focusedField, equals: .note)
                        .accessibilityIdentifier("marker-note-field")
                } header: {
                    Text("Marker")
                } footer: {
                    Text("Markers stay inside this song container.")
                }

                Section {
                    Picker("Color", selection: $draft.colorToken) {
                        ForEach(WaveformMarkerColorToken.allCases, id: \.self) { token in
                            Text(token.title).tag(token)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Color")
                }

                Section {
                    Toggle("Resolved", isOn: $draft.isResolved)
                        .accessibilityIdentifier("marker-resolved-toggle")
                } header: {
                    Text("Status")
                }

                Section {
                    Button("Delete Marker", role: .destructive, action: delete)
                }
            }
            .navigationTitle("Edit Marker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!draft.canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            focusedField = .note
        }
        .accessibilityIdentifier("marker-sheet")
    }
}

struct WorkspaceExportSheet: View {
    let item: WorkspaceExportItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()

                Capsule()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 34, height: 4)

                Spacer()
            }
            .overlay(alignment: .trailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.studioMuted)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.055), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close share sheet")
            }
            .padding(.horizontal, 20)
            .padding(.top, 9)

            VStack(alignment: .leading, spacing: 4) {
                Text("Share")
                    .font(StudioType.control)
                    .foregroundStyle(Color.studioText)

                Text(item.hasFiles ? "\(item.files.count) file\(item.files.count == 1 ? "" : "s") ready" : "No local files ready")
                    .font(StudioType.metadataSmall)
                    .foregroundStyle(Color.studioMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        WorkspaceExportHeader(item: item)

                    if item.hasFiles {
                        VStack(spacing: 10) {
                            ForEach(item.files, id: \.self) { file in
                                WorkspaceExportFileRow(file: file)
                            }
                        }
                    } else {
                        WorkspaceExportEmptyState()
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: 382)
        .background(Color.studioPanelRaised.ignoresSafeArea())
        .presentationDetents([item.hasFiles ? .medium : .height(320), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(22)
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("export-sheet")
    }
}

private struct WorkspaceExportHeader: View {
    let item: WorkspaceExportItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color.studioGold.opacity(0.13))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(Color.studioGold.opacity(0.24), lineWidth: 1)
                    }

                Image(systemName: item.kind.symbolName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.studioGold)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(StudioType.metadata.weight(.semibold))
                    .foregroundStyle(Color.studioText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(item.kind.title)
                    .font(StudioType.metadataSmall)
                    .foregroundStyle(Color.studioMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        }
    }
}

private struct WorkspaceExportFileRow: View {
    let file: URL

    var body: some View {
        ShareLink(item: file) {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(file.exportAccent.opacity(0.15))

                    Image(systemName: file.exportSymbolName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(file.exportAccent)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(file.workspaceExportDisplayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.studioText)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(file.pathExtension.uppercased().workspaceFallback("FILE"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.studioMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.studioGold)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.055), in: Circle())
            }
            .padding(.horizontal, 12)
            .frame(height: 70)
            .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct WorkspaceExportEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.studioGold.opacity(0.72))
                .frame(width: 58, height: 58)
                .background(Color.white.opacity(0.055), in: Circle())

            Text("Nothing to share yet")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.studioText)

            Text("Import audio or attach studio files first, then export them from here.")
                .font(StudioType.metadata)
                .foregroundStyle(Color.studioMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.studioPanel.opacity(0.72), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        }
    }
}

private extension WorkspaceExportItem.Kind {
    var title: String {
        switch self {
        case .project:
            return "Project export"
        case .track:
            return "Track export"
        case .song:
            return "Song container export"
        }
    }

    var symbolName: String {
        switch self {
        case .project:
            return "square.stack.3d.up.fill"
        case .track:
            return "waveform"
        case .song:
            return "music.note.list"
        }
    }
}

private extension URL {
    var exportSymbolName: String {
        switch pathExtension.lowercased() {
        case "wav", "wave", "aif", "aiff", "mp3", "m4a", "aac", "flac":
            return "waveform"
        case "txt", "md", "rtf", "pdf", "doc", "docx":
            return "doc.text"
        case "png", "jpg", "jpeg", "heic", "gif":
            return "photo"
        case "mov", "mp4", "m4v":
            return "film"
        default:
            return "doc"
        }
    }

    var exportAccent: Color {
        switch pathExtension.lowercased() {
        case "wav", "wave", "aif", "aiff", "mp3", "m4a", "aac", "flac":
            return .studioGold
        case "txt", "md", "rtf", "pdf", "doc", "docx":
            return .studioMint
        case "png", "jpg", "jpeg", "heic", "gif":
            return .studioBlue
        case "mov", "mp4", "m4v":
            return .studioRose
        default:
            return .studioMuted
        }
    }
}

private extension String {
    func workspaceFallback(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
