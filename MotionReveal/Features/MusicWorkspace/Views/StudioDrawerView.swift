import SwiftUI

struct StudioDrawerTouchMetrics: Equatable {
    static let minimumTouchTarget: CGFloat = 44
    static let filterChipHeight: CGFloat = minimumTouchTarget
    static let compactButtonHeight: CGFloat = minimumTouchTarget
}

struct StudioDrawer<AccessoryContent: View>: View {
    @Binding var isOpen: Bool
    let attachments: [SongAttachment]
    let addAttachment: () -> Void
    let attachmentURL: (SongAttachment) -> URL?
    let previewAttachment: (SongAttachment) -> Void
    let editAttachment: (SongAttachment) -> Void
    let removeAttachment: (SongAttachment) -> Void
    private let accessoryContent: AccessoryContent
    @State private var selectedCategory = AttachmentCategoryFilter.all

    init(
        isOpen: Binding<Bool>,
        attachments: [SongAttachment],
        addAttachment: @escaping () -> Void,
        attachmentURL: @escaping (SongAttachment) -> URL?,
        previewAttachment: @escaping (SongAttachment) -> Void,
        editAttachment: @escaping (SongAttachment) -> Void,
        removeAttachment: @escaping (SongAttachment) -> Void,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self._isOpen = isOpen
        self.attachments = attachments
        self.addAttachment = addAttachment
        self.attachmentURL = attachmentURL
        self.previewAttachment = previewAttachment
        self.editAttachment = editAttachment
        self.removeAttachment = removeAttachment
        self.accessoryContent = accessoryContent()
    }

    private var categoryFilters: [String] {
        attachments.studioCategoryFilters
    }

    private var effectiveCategory: String {
        categoryFilters.contains(selectedCategory) ? selectedCategory : AttachmentCategoryFilter.all
    }

    private var filteredAttachments: [SongAttachment] {
        attachments.filteredByStudioCategory(effectiveCategory)
    }

    private var filteredAttachmentSections: [AttachmentCategorySection] {
        filteredAttachments.studioCategorySections
    }

    private var showsGroupedAttachments: Bool {
        effectiveCategory == AttachmentCategoryFilter.all
            && filteredAttachments.count >= 4
            && filteredAttachmentSections.count > 1
    }

    var body: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 52, height: 5)
                .padding(.top, 12)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Studio drawer")
                        .font(StudioType.deckTitle)
                        .foregroundStyle(Color.studioText)
                    Text("Files attached to this song.")
                        .font(StudioType.metadataSmall)
                        .foregroundStyle(Color.studioMuted)
                }

                Spacer()

                Button(action: addAttachment) {
                    Label("Add", systemImage: "paperclip")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.studioText.opacity(0.92))
                .padding(.horizontal, 15)
                .frame(height: StudioDrawerTouchMetrics.compactButtonHeight)
                .background(Color.black.opacity(0.18), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.075), lineWidth: 1)
                }
            }
            .padding(.horizontal, 22)

            if isOpen {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        attachmentContent

                        accessoryContent
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: isOpen ? 526 : 92, alignment: .top)
        .background(Color.studioPanelRaised, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.32), radius: 24, x: 0, y: -12)
        .simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    if value.translation.height < -40 {
                        setOpen(true)
                    } else if value.translation.height > 40 {
                        setOpen(false)
                    }
                }
        )
        .accessibilityAction(named: Text("Open studio drawer")) {
            setOpen(true)
        }
        .accessibilityAction(named: Text("Close studio drawer")) {
            setOpen(false)
        }
        .accessibilityIdentifier("studio-drawer")
    }

    private func setOpen(_ open: Bool) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            isOpen = open
        }
    }

    @ViewBuilder
    private var attachmentContent: some View {
        if attachments.isEmpty {
            EmptyAttachmentState(addAttachment: addAttachment)
        } else {
            AttachmentCategoryFilterStrip(
                categories: categoryFilters,
                selectedCategory: effectiveCategory,
                select: { selectedCategory = $0 }
            )

            if showsGroupedAttachments {
                ForEach(filteredAttachmentSections) { section in
                    AttachmentCategorySectionView(
                        section: section,
                        attachmentURL: attachmentURL,
                        previewAttachment: previewAttachment,
                        editAttachment: editAttachment,
                        removeAttachment: removeAttachment
                    )
                }
            } else {
                ForEach(filteredAttachments) { attachment in
                    SongAttachmentRow(
                        attachment: attachment,
                        url: attachmentURL(attachment),
                        preview: { previewAttachment(attachment) },
                        edit: { editAttachment(attachment) },
                        remove: { removeAttachment(attachment) }
                    )
                }
            }
        }
    }
}

private struct AttachmentCategorySectionView: View {
    let section: AttachmentCategorySection
    let attachmentURL: (SongAttachment) -> URL?
    let previewAttachment: (SongAttachment) -> Void
    let editAttachment: (SongAttachment) -> Void
    let removeAttachment: (SongAttachment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(section.title)
                    .font(StudioType.eyebrow)
                    .foregroundStyle(Color.studioMuted)

                Text("\(section.attachments.count)")
                    .font(StudioType.marker)
                    .foregroundStyle(Color.studioBackground)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.studioMuted.opacity(0.74), in: Capsule())
            }
            .accessibilityElement(children: .combine)

            ForEach(section.attachments) { attachment in
                SongAttachmentRow(
                    attachment: attachment,
                    url: attachmentURL(attachment),
                    preview: { previewAttachment(attachment) },
                    edit: { editAttachment(attachment) },
                    remove: { removeAttachment(attachment) }
                )
            }
        }
    }
}

private struct AttachmentCategoryFilterStrip: View {
    let categories: [String]
    let selectedCategory: String
    let select: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        select(category)
                    } label: {
                        Text(category)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(category == selectedCategory ? Color.studioBackground : Color.studioText)
                            .lineLimit(1)
                            .padding(.horizontal, 11)
                            .frame(minHeight: StudioDrawerTouchMetrics.filterChipHeight)
                            .background(category == selectedCategory ? Color.studioGold : Color.white.opacity(0.06), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show \(category) files")
                    .accessibilityValue(category == selectedCategory ? "Selected" : "")
                }
            }
            .padding(.vertical, 1)
        }
    }
}

private struct EmptyAttachmentState: View {
    let addAttachment: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.studioGold)

            Text("Drop the files that belong with this song here.")
                .font(StudioType.metadataSmall)
                .foregroundStyle(Color.studioMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: addAttachment) {
                Label("Attach files", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.studioBackground)
                    .padding(.horizontal, 15)
                    .frame(height: StudioDrawerTouchMetrics.compactButtonHeight)
                    .background(Color.studioGold, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 18)
        .background(Color.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SongAttachmentRow: View {
    let attachment: SongAttachment
    let url: URL?
    let preview: () -> Void
    let edit: () -> Void
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: preview) {
                AttachmentRow(
                    kind: attachment.kind,
                    name: attachment.name,
                    category: attachment.category,
                    subtitle: attachment.subtitle,
                    size: attachment.size,
                    color: attachment.color
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open \(attachment.name)")

            if let url {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .foregroundStyle(Color.studioText)
                .background(Color.black.opacity(0.14), in: Circle())
                .accessibilityLabel("Share \(attachment.name)")
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.studioMuted)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.14), in: Circle())
                    .accessibilityLabel("\(attachment.name) file missing")
            }

            Button(action: edit) {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.studioText)
            .background(Color.black.opacity(0.14), in: Circle())
            .accessibilityLabel("Edit \(attachment.name)")

            Button(role: .destructive, action: remove) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.studioRose)
            .background(Color.black.opacity(0.14), in: Circle())
            .accessibilityLabel("Remove \(attachment.name)")
        }
    }
}

private struct AttachmentRow: View {
    let kind: String
    let name: String
    let category: String
    let subtitle: String
    let size: String
    let color: Color

    var body: some View {
        HStack(spacing: 11) {
            Text(kind)
                .font(StudioType.marker)
                .foregroundStyle(Color.studioBackground)
                .frame(width: 42, height: 34)
                .background(color, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(StudioType.metadataSmall)
                    .foregroundStyle(Color.studioText)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(category)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.12), in: Capsule())

                    Text(subtitle)
                        .font(StudioType.metadataSmall)
                        .foregroundStyle(Color.studioMuted)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Text(size)
                .font(StudioType.metadataSmall)
                .foregroundStyle(Color.studioMuted)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
