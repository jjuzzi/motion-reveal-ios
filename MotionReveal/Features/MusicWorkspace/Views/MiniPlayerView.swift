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
                motionArtwork: project.displayedCoverMotionArtwork(for: track),
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

                    MiniWaveform(markers: markers, progress: progress)
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
                .opacity(0.16)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .background(Color.studioPanelRaised.opacity(0.97), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.34), radius: 18, x: 0, y: 10)
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
    let progress: PlaybackProgress
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progressAnchorElapsed: TimeInterval = 0
    @State private var progressAnchorDate = Date()
    private static let bars = Array([CGFloat].waveformBars[12..<41])

    private var timelinePaused: Bool {
        reduceMotion || !progress.isPlaying
    }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: timelinePaused)) { timeline in
                let liveFraction = displayedFraction(at: timeline.date)

                ZStack {
                    Canvas(rendersAsynchronously: true) { context, size in
                        let bars = Self.bars
                        let horizontalInset: CGFloat = 5
                        let barSpacing: CGFloat = 2
                        let availableWidth = max(1, size.width - horizontalInset * 2)
                        let barWidth = max(1.25, (availableWidth - CGFloat(bars.count - 1) * barSpacing) / CGFloat(bars.count))
                        let playedThreshold = CGFloat(min(max(liveFraction, 0), 1))
                        let phase = CGFloat(timeline.date.timeIntervalSinceReferenceDate)
                        let bedRect = CGRect(x: 0, y: 2, width: size.width, height: size.height - 4)
                        let bedPath = Path(roundedRect: bedRect, cornerRadius: bedRect.height / 2)

                        context.fill(bedPath, with: .color(Color.black.opacity(0.14)))

                        for (index, height) in bars.enumerated() {
                            let barFraction = CGFloat(index) / CGFloat(max(bars.count - 1, 1))
                            let distance = abs(barFraction - playedThreshold)
                            let active = Self.activeFalloff(distance: distance)
                            let pulse = reduceMotion || !progress.isPlaying ? 0 : sin(phase * 4.8 + CGFloat(index) * 0.42)
                            let liftedHeight = max(4, 22 * height * (1 + active * (0.14 + 0.035 * pulse)))
                            let x = horizontalInset + CGFloat(index) * (barWidth + barSpacing)
                            let rect = CGRect(
                                x: x,
                                y: size.height / 2 - liftedHeight / 2,
                                width: barWidth,
                                height: liftedHeight
                            )
                            let color = Self.barColor(
                                barFraction: barFraction,
                                playedThreshold: playedThreshold,
                                activeFalloff: active
                            )

                            context.fill(
                                Path(roundedRect: rect, cornerRadius: barWidth / 2),
                                with: .color(color)
                            )
                        }

                        let playheadX = horizontalInset + availableWidth * playedThreshold
                        let playheadRect = CGRect(
                            x: playheadX - 1,
                            y: size.height / 2 - 12,
                            width: 2,
                            height: 24
                        )

                        context.drawLayer { layer in
                            layer.addFilter(.shadow(color: Color.studioGold.opacity(0.22), radius: 3, x: 0, y: 0))
                            layer.fill(
                                Path(roundedRect: playheadRect, cornerRadius: 1),
                                with: .color(Color.white.opacity(0.86))
                            )
                        }
                    }

                    ForEach(markers) { marker in
                        Capsule()
                            .fill(marker.color.opacity(0.74))
                            .frame(width: 1.5, height: max(11, 24 * marker.height))
                            .position(x: 5 + (proxy.size.width - 10) * marker.position, y: proxy.size.height / 2)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onAppear {
            resetProgressAnchor(to: progress)
        }
        .onChange(of: progress) { _, newProgress in
            resetProgressAnchor(to: newProgress)
        }
    }

    private func displayedFraction(at date: Date) -> Double {
        guard progress.isPlaying, !reduceMotion, progress.duration > 0 else {
            return progress.fraction
        }

        let elapsed = min(progress.duration, progressAnchorElapsed + max(0, date.timeIntervalSince(progressAnchorDate)))
        return min(max(elapsed / progress.duration, 0), 1)
    }

    private func resetProgressAnchor(to progress: PlaybackProgress) {
        progressAnchorElapsed = progress.elapsed
        progressAnchorDate = Date()
    }

    private static func activeFalloff(distance: CGFloat) -> CGFloat {
        let radius: CGFloat = 0.13
        let normalized = max(0, 1 - distance / radius)
        return normalized * normalized
    }

    private static func barColor(
        barFraction: CGFloat,
        playedThreshold: CGFloat,
        activeFalloff: CGFloat
    ) -> Color {
        if activeFalloff > 0.48 {
            return Color.white.opacity(0.60 + Double(activeFalloff) * 0.24)
        }

        if barFraction <= playedThreshold {
            return Color.studioGold.opacity(0.42 + Double(activeFalloff) * 0.30)
        }

        return Color.studioText.opacity(0.18 + Double(activeFalloff) * 0.22)
    }
}
