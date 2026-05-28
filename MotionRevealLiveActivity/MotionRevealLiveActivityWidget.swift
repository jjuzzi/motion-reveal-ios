import ActivityKit
import SwiftUI
import WidgetKit

@main
struct MotionRevealLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        MotionRevealLiveActivityWidget()
    }
}

struct MotionRevealLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NowPlayingActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color(red: 0.08, green: 0.075, blue: 0.06))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    StudioIslandLogo()
                        .frame(width: 34, height: 34)
                        .padding(.leading, 2)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.trackTitle)
                            .font(.headline.weight(.semibold))
                            .lineLimit(1)
                            .contentTransition(.opacity)

                        Text(context.state.projectTitle)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .contentTransition(.opacity)
                    }
                    .animation(.smooth(duration: 0.22), value: context.state.trackTitle)
                    .animation(.smooth(duration: 0.22), value: context.state.projectTitle)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    IslandPlaybackButton(isPlaying: context.state.isPlaying)
                        .animation(.snappy(duration: 0.2), value: context.state.isPlaying)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedIslandPlaybackSurface(
                        drawerLabel: drawerLabel(for: context),
                        elapsedLabel: context.state.elapsedLabel,
                        durationLabel: context.state.durationLabel,
                        progressFraction: context.state.progressFraction,
                        isPlaying: context.state.isPlaying
                    )
                    .animation(.smooth(duration: 0.35), value: context.state.progressFraction)
                    .animation(.snappy(duration: 0.24), value: context.state.attachmentCount)
                }
            } compactLeading: {
                CompactIslandRegion(isPlaying: context.state.isPlaying) {
                    StudioIslandLogo()
                        .frame(width: 22, height: 22)
                }
            } compactTrailing: {
                CompactIslandRegion(isPlaying: context.state.isPlaying) {
                    IslandPlaybackButton(isPlaying: context.state.isPlaying, compact: true)
                        .animation(.snappy(duration: 0.2), value: context.state.isPlaying)
                }
            } minimal: {
                StudioIslandLogo()
                    .frame(width: 20, height: 20)
                    .islandBorderBeam(
                        cornerRadius: 10,
                        beamBlur: 7,
                        isEnabled: context.state.isPlaying
                    )
            }
            .widgetURL(MotionRevealDeepLink.songContainerURL)
            .keylineTint(Color(red: 0.92, green: 0.80, blue: 0.42))
        }
    }

    private func drawerLabel(for context: ActivityViewContext<NowPlayingActivityAttributes>) -> String {
        if context.state.attachmentCount == 1 {
            return "1 file in song container"
        }

        return "\(context.state.attachmentCount) files in song container"
    }
}

private enum LiveActivityIslandMetrics {
    static let compactSideMaxWidth: CGFloat = 52
    static let compactHeight: CGFloat = 37
    static let compactCornerRadius: CGFloat = 18.5
    static let expandedSurfaceCornerRadius: CGFloat = 17
    static let expandedSurfaceBeamBlur: CGFloat = 4.5
}

private struct CompactIslandRegion<Content: View>: View {
    let isPlaying: Bool
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.18))
                .islandBorderBeam(
                    cornerRadius: LiveActivityIslandMetrics.compactCornerRadius,
                    beamBlur: 1.1,
                    isEnabled: isPlaying
                )

            content
        }
        .frame(
            width: LiveActivityIslandMetrics.compactSideMaxWidth,
            height: LiveActivityIslandMetrics.compactHeight,
            alignment: .center
        )
        .accessibilityElement(children: .contain)
    }
}

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<NowPlayingActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            StudioIslandLogo()
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(context.state.trackTitle)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(context.state.isPlaying ? "Playing" : "Paused")
                        .contentTransition(.opacity)
                    Text("\(context.state.elapsedLabel) / \(context.state.durationLabel)")
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .animation(.snappy(duration: 0.2), value: context.state.isPlaying)
                .animation(.linear(duration: 0.18), value: context.state.elapsedLabel)

                ActivityProgressBar(fraction: context.state.progressFraction)
            }

            Spacer(minLength: 8)

            IslandPlaybackButton(isPlaying: context.state.isPlaying)
                .animation(.snappy(duration: 0.2), value: context.state.isPlaying)
        }
        .padding(.vertical, 10)
        .animation(.smooth(duration: 0.35), value: context.state.progressFraction)
        .islandBorderBeam(
            cornerRadius: 18,
            beamBlur: 12,
            isEnabled: context.state.isPlaying
        )
    }
}

private struct ExpandedIslandPlaybackSurface: View {
    let drawerLabel: String
    let elapsedLabel: String
    let durationLabel: String
    let progressFraction: Double
    let isPlaying: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(drawerLabel, systemImage: "tray.and.arrow.down.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.92, green: 0.80, blue: 0.42))

                Spacer(minLength: 8)

                Text("\(elapsedLabel) / \(durationLabel)")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.18), value: elapsedLabel)
            }

            ActivityProgressBar(fraction: progressFraction)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Color.black.opacity(0.18),
            in: RoundedRectangle(
                cornerRadius: LiveActivityIslandMetrics.expandedSurfaceCornerRadius,
                style: .continuous
            )
        )
        .islandBorderBeam(
            cornerRadius: LiveActivityIslandMetrics.expandedSurfaceCornerRadius,
            beamBlur: LiveActivityIslandMetrics.expandedSurfaceBeamBlur,
            isEnabled: isPlaying
        )
    }
}

private struct ActivityProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            let clamped = min(max(fraction, 0), 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.48, green: 0.90, blue: 1.00),
                                Color(red: 0.92, green: 0.80, blue: 0.42)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, proxy.size.width * clamped))
            }
        }
        .frame(height: 4)
        .animation(.smooth(duration: 0.35), value: min(max(fraction, 0), 1))
        .accessibilityLabel("Playback progress")
        .accessibilityValue("\(Int(min(max(fraction, 0), 1) * 100)) percent")
    }
}

private struct IslandPlaybackButton: View {
    let isPlaying: Bool
    var compact = false

    var body: some View {
        Button(intent: TogglePlaybackIntent()) {
            playbackGlyph
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
    }

    @ViewBuilder
    private var playbackGlyph: some View {
        if compact {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: isPlaying ? 9.4 : 10.4, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.94))
                .offset(x: isPlaying ? 0 : 0.8)
                .contentTransition(.opacity)
                .frame(width: 28, height: 28)
        } else {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .offset(x: isPlaying ? 0 : 1)
                .contentTransition(.opacity)
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.09), in: Circle())
                .islandBorderBeam(
                    cornerRadius: 16,
                    beamBlur: 3.5,
                    isEnabled: isPlaying
                )
        }
    }
}

private struct StudioIslandLogo: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.92),
                            Color(red: 0.44, green: 0.74, blue: 0.92),
                            Color(red: 0.92, green: 0.52, blue: 0.64),
                            Color(red: 0.94, green: 0.78, blue: 0.36),
                            Color.white.opacity(0.92)
                        ],
                        center: .center
                    )
                )

            Circle()
                .fill(Color.black.opacity(0.72))
                .frame(width: 7, height: 7)

            Circle()
                .stroke(Color.white.opacity(0.45), lineWidth: 0.8)
        }
    }
}

private extension View {
    func islandBorderBeam(
        cornerRadius: CGFloat,
        beamBlur: CGFloat = 9,
        isEnabled: Bool
    ) -> some View {
        modifier(
            IslandBorderBeamEffect(
                cornerRadius: cornerRadius,
                beamBlur: beamBlur,
                isEnabled: isEnabled
            )
        )
    }
}

private struct IslandBorderBeamEffect: ViewModifier {
    let cornerRadius: CGFloat
    let beamBlur: CGFloat
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isEnabled {
                    IslandBorderBeam(cornerRadius: cornerRadius, beamBlur: beamBlur)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.65)
                }
            }
    }
}

private struct IslandBorderBeam: View {
    let cornerRadius: CGFloat
    let beamBlur: CGFloat

    var body: some View {
        let borderGradient = AngularGradient(
            colors: [
                Color(red: 0.92, green: 0.80, blue: 0.42).opacity(0.72),
                Color(red: 0.48, green: 0.90, blue: 1.00).opacity(0.60),
                Color(red: 1.00, green: 0.45, blue: 0.82).opacity(0.52),
                Color(red: 0.92, green: 0.80, blue: 0.42).opacity(0.72)
            ],
            center: .center
        )
        let beamGradient = LinearGradient(
            colors: [
                Color(red: 0.36, green: 1.00, blue: 0.68),
                Color(red: 0.35, green: 0.70, blue: 1.00),
                Color(red: 1.00, green: 0.45, blue: 0.82),
                Color(red: 0.98, green: 0.74, blue: 0.30)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(borderGradient, lineWidth: 0.95)
                .opacity(0.76)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(beamGradient, lineWidth: 1.8)
                .blur(radius: beamBlur)
                .opacity(0.26)
                .mask {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(borderGradient, lineWidth: 2.8)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }
}
