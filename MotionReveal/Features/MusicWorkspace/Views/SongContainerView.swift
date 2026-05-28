import SwiftUI

struct SongContainerTouchMetrics: Equatable {
    static let minimumTouchTarget: CGFloat = 44
    static let secondaryTransportButtonSize: CGFloat = 44
    static let primaryTransportButtonSize: CGFloat = 48
}

struct SongContainerLayoutMetrics: Equatable {
    static let horizontalPadding: CGFloat = 22
    static let topChromePadding: CGFloat = 56
    static let heroArtworkSize: CGFloat = 304
    static let heroGlowSize: CGFloat = 318
    static let heroCornerRadius: CGFloat = 42
    static let heroGlowBlur: CGFloat = 30
    static let transportSpacing: CGFloat = 38
    static let transportMinHeight: CGFloat = 56
}

struct SongContainerView: View {
    let project: MusicProject
    let track: MusicTrack
    let playbackRuntime: WorkspacePlaybackRuntime
    let heroNamespace: Namespace.ID
    let heroMotionEnabled: Bool
    @Binding var markers: [WaveformMarker]
    @Binding var selectedMarker: WaveformMarker?
    @Binding var studioDrawerOpen: Bool
    let isMarkerEditorPresented: Bool
    let markerEditorCooldownToken: Int
    let attachments: [SongAttachment]
    let textDocuments: [SongTextDocument]
    let togglePlayback: () -> Void
    let playPrevious: () -> Void
    let playNext: () -> Void
    let seekPlayback: (Double) -> Void
    let previewSeekPlayback: (Double) -> Void
    let addAttachment: () -> Void
    let attachmentURL: (SongAttachment) -> URL?
    let previewAttachment: (SongAttachment) -> Void
    let editAttachment: (SongAttachment) -> Void
    let removeAttachment: (SongAttachment) -> Void
    let setMotionArtwork: () -> Void
    let useSampleMotionArtwork: () -> Void
    let editSongText: (SongTextKind) -> Void
    let addMarkerAtPlayhead: () -> Void
    let editMarker: (WaveformMarker) -> Void
    let toggleMarkerResolved: (WaveformMarker) -> Void
    let close: () -> Void
    let openMenu: () -> Void

    var body: some View {
        let progress = playbackRuntime.progress

        ZStack(alignment: .bottom) {
            Color.studioBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    SongContainerChromeBar(
                        trackTitle: track.title,
                        close: close,
                        openMenu: openMenu
                    )
                    .padding(.top, SongContainerLayoutMetrics.topChromePadding)

                    SongContainerHeroPanel(
                        project: project,
                        track: track,
                        progress: progress,
                        heroNamespace: heroNamespace,
                        heroMotionEnabled: heroMotionEnabled,
                        attachments: attachments
                    )

                    WaveformPanel(
                        progress: progress,
                        markers: $markers,
                        selectedMarker: $selectedMarker,
                        seekPlayback: seekPlayback,
                        previewSeekPlayback: previewSeekPlayback,
                        editMarker: editMarker,
                        isMarkerEditorPresented: isMarkerEditorPresented,
                        markerEditorCooldownToken: markerEditorCooldownToken
                    )
                    .frame(height: 172)

                    PlaybackStrip(
                        progress: progress,
                        togglePlayback: togglePlayback,
                        playPrevious: playPrevious,
                        playNext: playNext
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SongContainerLayoutMetrics.horizontalPadding)
                .padding(.bottom, studioDrawerOpen ? 516 : 130)
            }
            .accessibilityIdentifier("song-container")

            if studioDrawerOpen {
                StudioDrawer(
                    isOpen: $studioDrawerOpen,
                    attachments: attachments,
                    addAttachment: addAttachment,
                    attachmentURL: attachmentURL,
                    previewAttachment: previewAttachment,
                    editAttachment: editAttachment,
                    removeAttachment: removeAttachment
                ) {
                    StudioDrawerToolsPanel(
                        markers: markers,
                        selectedMarker: $selectedMarker,
                        textDocuments: textDocuments,
                        addMarkerAtPlayhead: addMarkerAtPlayhead,
                        editMarker: editMarker,
                        seekToMarker: seekPlayback,
                        toggleMarkerResolved: toggleMarkerResolved,
                        editSongText: editSongText
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height > 120 {
                        close()
                    }
                }
        )
    }
}

private struct SongContainerChromeBar: View {
    let trackTitle: String
    let close: () -> Void
    let openMenu: () -> Void

    var body: some View {
        HStack {
            WorkspaceIconButton(
                action: WorkspaceIconAction(systemName: "chevron.up", label: "Close song container", action: close)
            )

            Spacer()

            WorkspaceIconButton(
                action: WorkspaceIconAction(systemName: "ellipsis", label: "Song actions", action: openMenu)
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Song container for \(trackTitle)")
    }
}

private struct SongContainerHeroPanel: View {
    let project: MusicProject
    let track: MusicTrack
    let progress: PlaybackProgress
    let heroNamespace: Namespace.ID
    let heroMotionEnabled: Bool
    let attachments: [SongAttachment]

    private var metadataLine: String {
        track.metadataLine.isEmpty ? project.creator : track.metadataLine
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                NowPlayingCapsuleGlow(artwork: project.sleeve)
                    .frame(width: SongContainerLayoutMetrics.heroGlowSize, height: SongContainerLayoutMetrics.heroGlowSize)
                    .clipShape(RoundedRectangle(cornerRadius: SongContainerLayoutMetrics.heroCornerRadius + 4, style: .continuous))
                    .blur(radius: SongContainerLayoutMetrics.heroGlowBlur)
                    .opacity(0.34)
                    .offset(y: 10)

                MotionSleeveArtworkView(artwork: project.sleeve, motionArtwork: project.displayedCoverMotionArtwork(for: track))
                    .frame(width: SongContainerLayoutMetrics.heroArtworkSize, height: SongContainerLayoutMetrics.heroArtworkSize)
                    .workspaceHeroMatched(
                        id: WorkspaceHeroMotion.nowPlayingArtworkID(track.id),
                        in: heroNamespace,
                        isEnabled: heroMotionEnabled
                    )
                    .clipShape(RoundedRectangle(cornerRadius: SongContainerLayoutMetrics.heroCornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: SongContainerLayoutMetrics.heroCornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.34), radius: 22, x: 0, y: 16)
            }
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)

            VStack(spacing: 7) {
                Text(track.title)
                    .font(StudioType.deckTitle)
                    .foregroundStyle(Color.studioText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text(metadataLine)
                    .font(StudioType.metadata)
                    .foregroundStyle(Color.studioMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            SongContainerStatusRow(
                progress: progress,
                track: track,
                attachmentCount: attachments.count
            )
        }
        .padding(.top, 6)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(track.title), \(metadataLine)")
    }
}

private struct SongContainerStatusRow: View {
    let progress: PlaybackProgress
    let track: MusicTrack
    let attachmentCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SongContainerMetadataBadge(
                    title: progress.isRealPlayback ? "Audio" : "Preview",
                    systemName: progress.isRealPlayback ? "waveform" : "play.circle.fill"
                )

                if let format = track.audioFormat {
                    SongContainerMetadataBadge(
                        title: format.uppercased(),
                        systemName: "music.note"
                    )
                }

                if track.animatedArtwork != nil {
                    SongContainerMetadataBadge(
                        title: "Motion ready",
                        systemName: "sparkles.tv"
                    )
                }

                if attachmentCount > 0 {
                    SongContainerMetadataBadge(
                        title: "\(attachmentCount) files",
                        systemName: "tray.full"
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct SongContainerMetadataBadge: View {
    let title: String
    let systemName: String

    var body: some View {
        Label(title, systemImage: systemName)
            .font(StudioType.metadataSmall.weight(.semibold))
            .foregroundStyle(Color.studioText)
            .padding(.horizontal, 10)
            .frame(minHeight: SongContainerTouchMetrics.minimumTouchTarget)
            .background(Color.white.opacity(0.06), in: Capsule())
    }
}

private struct StudioDrawerToolsPanel: View {
    let markers: [WaveformMarker]
    @Binding var selectedMarker: WaveformMarker?
    let textDocuments: [SongTextDocument]
    let addMarkerAtPlayhead: () -> Void
    let editMarker: (WaveformMarker) -> Void
    let seekToMarker: (Double) -> Void
    let toggleMarkerResolved: (WaveformMarker) -> Void
    let editSongText: (SongTextKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarkerListView(
                markers: markers,
                selectedMarker: $selectedMarker,
                addMarkerAtPlayhead: addMarkerAtPlayhead,
                editMarker: editMarker,
                seekToMarker: seekToMarker,
                toggleResolved: toggleMarkerResolved
            )

            SongTextPanel(
                documents: textDocuments,
                edit: editSongText
            )
        }
        .padding(.top, 4)
    }
}

private struct PlaybackStrip: View {
    let progress: PlaybackProgress
    let togglePlayback: () -> Void
    let playPrevious: () -> Void
    let playNext: () -> Void

    var body: some View {
        HStack(spacing: SongContainerLayoutMetrics.transportSpacing) {
            Button(action: playPrevious) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.studioText.opacity(0.56))
                    .frame(
                        width: SongContainerTouchMetrics.secondaryTransportButtonSize,
                        height: SongContainerTouchMetrics.secondaryTransportButtonSize
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Restart or previous track")

            Button(action: togglePlayback) {
                Image(systemName: progress.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(Color.studioText)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(
                        width: SongContainerTouchMetrics.primaryTransportButtonSize,
                        height: SongContainerTouchMetrics.primaryTransportButtonSize
                    )
                    .background(Color.white.opacity(0.075), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.095), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(progress.isPlaying ? "Pause" : "Play")
            .accessibilityValue("\(progress.elapsedLabel) of \(progress.durationLabel)")

            Button(action: playNext) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.studioText.opacity(0.56))
                    .frame(
                        width: SongContainerTouchMetrics.secondaryTransportButtonSize,
                        height: SongContainerTouchMetrics.secondaryTransportButtonSize
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next track")
        }
        .frame(maxWidth: .infinity, minHeight: SongContainerLayoutMetrics.transportMinHeight)
    }
}

private struct SongTextPanel: View {
    let documents: [SongTextDocument]
    let edit: (SongTextKind) -> Void

    private var normalizedDocuments: [SongTextDocument] {
        SongTextDocument.normalizedSet(from: documents)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes and lyrics")
                .font(StudioType.eyebrow)
                .foregroundStyle(Color.studioMuted)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    ForEach(normalizedDocuments) { document in
                        SongTextCard(document: document, edit: { edit(document.kind) })
                    }
                }

                VStack(spacing: 8) {
                    ForEach(normalizedDocuments) { document in
                        SongTextCard(document: document, edit: { edit(document.kind) })
                    }
                }
            }
        }
        .accessibilityIdentifier("song-text-panel")
    }
}

private struct SongTextCard: View {
    let document: SongTextDocument
    let edit: () -> Void

    var body: some View {
        Button(action: edit) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Image(systemName: document.kind.systemName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.studioGold)
                        .frame(width: 18, height: 18)

                    Text(document.kind.title)
                        .font(StudioType.metadataSmall)
                        .foregroundStyle(Color.studioText)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }

                Text(document.previewText)
                    .font(StudioType.metadataSmall)
                    .foregroundStyle(document.isEmpty ? Color.studioMuted.opacity(0.66) : Color.studioMuted)
                    .italic(document.isEmpty)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit \(document.kind.title)")
    }
}
