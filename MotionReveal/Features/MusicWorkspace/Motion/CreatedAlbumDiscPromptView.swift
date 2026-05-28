import SwiftUI

private struct CreatedAlbumDiscFramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect? = nil

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

struct CreatedAlbumDiscPromptMotion: Equatable {
    let isReady: Bool
    let isPressingDisc: Bool
    let reduceMotion: Bool

    var discScale: CGFloat {
        let readyScale: CGFloat = isReady ? 1 : 0.82
        let pressScale: CGFloat = isPressingDisc && !reduceMotion ? 0.965 : 1
        return readyScale * pressScale
    }

    var discBrightness: Double {
        isPressingDisc && !reduceMotion ? -0.025 : 0
    }
}

struct CreatedAlbumDiscPromptView: View {
    let project: MusicProject
    let playDisc: (MusicProject, CGRect?) -> Void
    let recordDiscFrame: (CGRect) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isReady = false
    @State private var isPressingDisc = false
    @State private var discTapFeedbackTrigger = false
    @State private var currentDiscFrame: CGRect?

    var body: some View {
        ZStack {
            Color.studioBackground
                .ignoresSafeArea()
                .accessibilityHidden(true)

            ZStack {
                BlankCDIridescenceView()
                    .frame(width: 258, height: 258)
                    .scaleEffect(motion.discScale)
                    .opacity(isReady ? 1 : 0)
                    .brightness(motion.discBrightness)
                    .allowsHitTesting(false)
                    .background {
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: CreatedAlbumDiscFramePreferenceKey.self,
                                    value: proxy.frame(in: .named(WorkspaceCoordinateSpace.name))
                                )
                        }
                    }

                Button {
                    isPressingDisc = false
                    discTapFeedbackTrigger.toggle()
                    playDisc(project, currentDiscFrame)
                } label: {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .frame(width: 258, height: 258)
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .zIndex(2)
                .accessibilityLabel("Load new sleeve")
                .accessibilityHint("Tap the disc to send it into the top-edge player.")
                .accessibilityIdentifier("created-album-cd-prompt")
                .sensoryFeedback(.selection, trigger: discTapFeedbackTrigger)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard !reduceMotion else { return }
                            withAnimation(.spring(response: 0.18, dampingFraction: 0.72)) {
                                isPressingDisc = true
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
                                isPressingDisc = false
                            }
                        }
                )
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.14) : .spring(response: 0.54, dampingFraction: 0.82)) {
                isReady = true
            }
        }
        .onPreferenceChange(CreatedAlbumDiscFramePreferenceKey.self) { frame in
            guard let frame else { return }
            currentDiscFrame = frame
            recordDiscFrame(frame)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("created-album-disc-stage")
    }

    private var motion: CreatedAlbumDiscPromptMotion {
        CreatedAlbumDiscPromptMotion(
            isReady: isReady,
            isPressingDisc: isPressingDisc,
            reduceMotion: reduceMotion
        )
    }
}
