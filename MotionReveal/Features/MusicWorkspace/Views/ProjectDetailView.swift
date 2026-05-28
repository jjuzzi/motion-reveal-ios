import SwiftUI

struct ProjectScreen: View {
    let project: MusicProject
    @Binding var searchText: String
    @Binding var isSearchVisible: Bool
    let playProject: () -> Void
    let playTrack: (MusicTrack) -> Void
    let back: () -> Void
    let addTrack: () -> Void
    let renameProject: () -> Void
    let changeCover: () -> Void
    let openMenu: (WorkspaceActionKind) -> Void
    let openTrackMenu: (MusicTrack) -> Void
    let isMiniPlayerVisible: Bool
    let bottomContentPadding: CGFloat

    private var filteredTracks: [MusicTrack] {
        project.tracks.filteredByStudioSearch(searchText)
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static let topScrollAnchor = "project-screen-top"

    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        WorkspaceTopBar(
                            eyebrow: nil,
                            title: nil,
                            leadingAction: WorkspaceIconAction(systemName: "chevron.left", label: "Back", action: back),
                            trailingButtons: [
                                WorkspaceIconAction(systemName: "link", label: "Copy link") {},
                                WorkspaceIconAction(systemName: "magnifyingglass", label: "Search project") {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                        isSearchVisible.toggle()
                                        if !isSearchVisible {
                                            searchText = ""
                                        }
                                    }
                                },
                                WorkspaceIconAction(systemName: "ellipsis", label: "Project actions") {
                                    openMenu(.project)
                                }
                            ]
                        )
                        .padding(.top, 60)
                        .id(Self.topScrollAnchor)

                        VStack(alignment: .leading, spacing: 18) {
                            let artworkSideLength = artworkSideLength(in: proxy.size)

                            MotionSleeveArtworkView(artwork: project.sleeve, motionArtwork: project.displayedCoverMotionArtwork)
                                .frame(width: artworkSideLength, height: artworkSideLength)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                }
                                .shadow(color: .black.opacity(0.35), radius: 26, x: 0, y: 16)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .contextMenu {
                                    Button("Change Cover", systemImage: "photo") {
                                        changeCover()
                                    }

                                    Button("Rename Project", systemImage: "pencil") {
                                        renameProject()
                                    }
                                }
                                .accessibilityHint("Touch and hold for cover and rename options.")

                            HStack(alignment: .bottom, spacing: 14) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(project.title)
                                        .font(StudioType.projectTitle)
                                        .foregroundStyle(Color.studioText)
                                        .lineLimit(2)
                                        .contextMenu {
                                            Button("Rename Project", systemImage: "pencil") {
                                                renameProject()
                                            }
                                        }

                                    Text(project.metadata)
                                        .font(StudioType.metadata)
                                        .foregroundStyle(Color.studioMuted)
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 12)

                                Button(action: playProject) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 19, weight: .bold))
                                        .foregroundStyle(Color.studioBackground)
                                        .offset(x: 1)
                                        .frame(width: 56, height: 56)
                                        .background(Color.studioText, in: Circle())
                                        .shadow(color: Color.studioText.opacity(0.16), radius: 12, x: 0, y: 4)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Play project")
                                .accessibilityIdentifier("project-play")
                            }

                            if isSearchVisible {
                                ProjectSearchField(searchText: $searchText)
                            }

                            Button(action: addTrack) {
                                Label("Add tracks", systemImage: "plus")
                                    .font(StudioType.control)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .foregroundStyle(Color.studioText)
                                    .background(Color.black.opacity(0.16), in: Capsule())
                                    .overlay {
                                        Capsule()
                                            .stroke(Color.white.opacity(0.075), lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("add-tracks")

                            if project.tracks.isEmpty {
                                EmptyTrackStateView(addTrack: addTrack)
                            } else if filteredTracks.isEmpty, isSearching {
                                ContentUnavailableView.search
                                    .foregroundStyle(Color.studioMuted)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 28)
                            } else {
                                TrackList(
                                    tracks: filteredTracks,
                                    playTrack: playTrack,
                                    openMenu: openTrackMenu
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, bottomContentPadding)
                }
                .scrollBounceBehavior(.basedOnSize)
                .accessibilityIdentifier("project-screen")
                .onChange(of: project.id) {
                    scrollProxy.scrollTo(Self.topScrollAnchor, anchor: .top)
                }
            }
        }
    }

    private func artworkSideLength(in size: CGSize) -> CGFloat {
        let maxWidth = max(0, size.width - 44)
        guard isMiniPlayerVisible, !project.tracks.isEmpty else {
            return maxWidth
        }

        let compactLength = min(maxWidth, size.height * 0.34)
        return max(238, compactLength)
    }
}

private struct ProjectSearchField: View {
    @Binding var searchText: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.studioMuted)

            TextField("Search songs, notes, lyrics", text: $searchText)
                .font(StudioType.metadata)
                .foregroundStyle(Color.studioText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.studioMuted)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear project search")
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, searchText.isEmpty ? 14 : 2)
        .frame(height: 50)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.075), lineWidth: 1)
        }
        .onAppear {
            isFocused = true
        }
        .accessibilityIdentifier("project-search-field")
    }
}

private struct TrackList: View {
    let tracks: [MusicTrack]
    let playTrack: (MusicTrack) -> Void
    let openMenu: (MusicTrack) -> Void

    var body: some View {
        VStack(spacing: 3) {
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                TrackRow(
                    index: index + 1,
                    track: track,
                    playTrack: { playTrack(track) },
                    openMenu: { openMenu(track) }
                )
            }
        }
        .accessibilityIdentifier("track-list")
    }
}

private struct TrackRow: View {
    let index: Int
    let track: MusicTrack
    let playTrack: () -> Void
    let openMenu: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: playTrack) {
                HStack(spacing: 14) {
                    Text("\(index)")
                        .font(StudioType.metadata)
                        .foregroundStyle(Color.studioMuted)
                        .frame(width: 26, alignment: .trailing)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(StudioType.rowTitle)
                            .foregroundStyle(Color.studioText)
                            .lineLimit(1)

                        Text(track.metadataLine)
                            .font(StudioType.metadataSmall)
                            .foregroundStyle(Color.studioMuted)
                            .lineLimit(1)
                            .accessibilityIdentifier("track-metadata-line")
                    }

                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play \(track.title), \(track.metadataLine)")

            Button(action: openMenu) {
                MenuIconGlyph(systemName: "ellipsis")
                    .frame(width: WorkspaceIconMetrics.standaloneActionSize, height: WorkspaceIconMetrics.standaloneActionSize)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .accessibilityLabel("\(track.title) actions")
        }
        .padding(.vertical, 11)
    }
}
