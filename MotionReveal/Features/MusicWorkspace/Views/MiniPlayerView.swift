import SwiftUI

struct MiniPlayer: View {
    let project: MusicProject
    let track: MusicTrack
    let markers: [WaveformMarker]
    let playbackRuntime: WorkspacePlaybackRuntime
    let heroNamespace: Namespace.ID
    let heroMotionEnabled: Bool
    let canPlayPrevious: Bool
    let canPlayNext: Bool
    let openSongContainer: () -> Void
    let togglePlayback: () -> Void
    let playPrevious: () -> Void
    let playNext: () -> Void
    let stopPlayback: () -> Void
    @State private var expandFeedbackTrigger = 0

    var body: some View {
        let progress = playbackRuntime.progress

        HStack(spacing: 8) {
            MiniTransportButton(
                systemName: "backward.fill",
                label: "Restart or previous track",
                isEnabled: canPlayPrevious,
                action: playPrevious
            )

            MotionSleeveArtworkView(
                artwork: project.sleeve,
                motionArtwork: track.animatedArtwork ?? project.displayedCoverMotionArtwork,
                playbackPolicy: .still
            )
                .workspaceHeroMatched(
                    id: WorkspaceHeroMotion.nowPlayingArtworkID(track.id),
                    in: heroNamespace,
                    isEnabled: heroMotionEnabled
                )
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    MiniPlayButton(progress: progress, togglePlayback: togglePlayback)
            }

            Button(action: expandNowPlaying) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title)
                            .font(StudioType.metadata.weight(.semibold))
                            .foregroundStyle(Color.studioText)
                            .lineLimit(1)

                        Text("\(project.title) - \(project.creator)")
                            .font(StudioType.metadataSmall)
                            .foregroundStyle(Color.studioMuted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                    MiniWaveform(markers: markers, progress: progress.fraction)
                        .frame(width: 78, height: 28)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Expand now playing")
            .accessibilityHint("Opens the full screen song container.")
            .accessibilityIdentifier("mini-player-expand")

            MiniTransportButton(systemName: "forward.fill", label: "Next track", isEnabled: canPlayNext, action: playNext)
                .zIndex(2)
        }
        .padding(.vertical, 7)
        .padding(.leading, 8)
        .padding(.trailing, 8)
        .frame(height: 58)
        .background {
            NowPlayingCapsuleGlow(artwork: project.sleeve)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .opacity(0.24)
        }
        .background(Color.studioPanelRaised.opacity(0.84), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 16, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .simultaneousGesture(
            DragGesture(minimumDistance: 6)
                .onEnded { value in
                    if value.translation.height < -42 {
                        openSongContainer()
                    } else if value.translation.height > 58 {
                        stopPlayback()
                    }
                }
        )
        .sensoryFeedback(.impact(weight: .medium), trigger: expandFeedbackTrigger)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Now playing \(track.title), \(progress.elapsedLabel) of \(progress.durationLabel)")
        .accessibilityAction(named: Text("Open song container"), openSongContainer)
        .accessibilityAction(named: Text("Stop playback"), stopPlayback)
        .accessibilityIdentifier("mini-player")
    }

    private func expandNowPlaying() {
        expandFeedbackTrigger += 1
        openSongContainer()
    }
}

private struct MiniTransportButton: View {
    let systemName: String
    let label: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Color.studioText.opacity(isEnabled ? 0.82 : 0.28))
                .frame(width: 30, height: 44)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

private struct MiniPlayButton: View {
    let progress: PlaybackProgress
    let togglePlayback: () -> Void

    var body: some View {
        Button(action: togglePlayback) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.42))
                    .frame(width: 24, height: 24)

                Image(systemName: progress.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 9.5, weight: .black))
                    .foregroundStyle(Color.studioText)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 34, height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(progress.isPlaying ? "Pause" : "Play")
    }
}

private struct MiniWaveform: View {
    let markers: [WaveformMarker]
    let progress: Double
    private let bars = Array([CGFloat].waveformBars[12..<41])

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                HStack(spacing: 2) {
                    ForEach(Array(bars.enumerated()), id: \.offset) { index, height in
                        let progressIndex = min(
                            max(Int(progress * Double(max(bars.count - 1, 1))), 0),
                            bars.count - 1
                        )

                        if index == progressIndex {
                            Capsule()
                                .fill(Color.studioGold)
                                .frame(width: 1.6, height: 24)
                        } else {
                            Capsule()
                                .fill(Color.studioText.opacity(index < progressIndex ? 0.78 : 0.28))
                                .frame(width: 1.8, height: max(4, 23 * height))
                        }
                    }
                }
                .padding(.horizontal, 4)
                .clipped()

                ForEach(markers) { marker in
                    Capsule()
                        .fill(marker.color.opacity(0.78))
                        .frame(width: 1.5, height: max(11, 24 * marker.height))
                        .position(x: 4 + (proxy.size.width - 8) * marker.position, y: proxy.size.height / 2)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
