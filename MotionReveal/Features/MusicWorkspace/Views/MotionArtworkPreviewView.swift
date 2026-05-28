import SwiftUI

struct MotionArtworkVideoSurface: View {
    let artwork: MotionArtwork
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = MotionArtworkPreviewModel()

    var body: some View {
        Group {
            if let player = model.player, !reduceMotion {
                LoopingVideoPlayer(player: player)
                    .disabled(true)
                    .allowsHitTesting(false)
            }
        }
        .task(id: artwork.playbackIdentity) {
            model.configure(for: artwork)
            model.updatePlayback(isEnabled: !reduceMotion)
        }
        .onChange(of: reduceMotion) { _, isReduced in
            model.updatePlayback(isEnabled: !isReduced)
        }
        .onDisappear {
            model.updatePlayback(isEnabled: false)
        }
        .accessibilityHidden(true)
    }
}

struct MotionArtworkPreviewView: View {
    let artwork: MotionArtwork
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = MotionArtworkPreviewModel()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.studioPanelRaised,
                            Color.studioBackground.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let player = model.player, !reduceMotion {
                LoopingVideoPlayer(player: player)
                    .disabled(true)
                    .allowsHitTesting(false)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: reduceMotion ? "sparkles.rectangle.stack" : "video.slash")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.studioGold)

                    Text(reduceMotion ? "Motion paused for Reduce Motion" : "Preview unavailable")
                        .font(StudioType.metadataSmall)
                        .foregroundStyle(Color.studioText)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.58)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 8) {
                    Image(systemName: reduceMotion ? "pause.circle.fill" : "sparkles")
                        .font(.caption.weight(.bold))

                    Text(reduceMotion ? "Motion ready" : "Looping preview")
                        .lineLimit(1)
                }
                .font(StudioType.metadataSmall.weight(.semibold))
                .foregroundStyle(Color.white)
                .padding(12)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .task(id: artwork.playbackIdentity) {
            model.configure(for: artwork)
            model.updatePlayback(isEnabled: !reduceMotion)
        }
        .onChange(of: reduceMotion) { _, isReduced in
            model.updatePlayback(isEnabled: !isReduced)
        }
        .onDisappear {
            model.updatePlayback(isEnabled: false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Motion artwork preview")
        .accessibilityValue(reduceMotion ? "Paused for Reduce Motion" : artwork.displayName)
    }
}
