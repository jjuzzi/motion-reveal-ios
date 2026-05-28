import RiveRuntime
import SwiftUI

struct LaunchDiscRiveIntroView: View {
    let finish: () -> Void

    @State private var isReady = false
    @State private var isPlaying = false
    @State private var didFinish = false
    @State private var tapFeedback = false
    @State private var finishTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                SwiftUI.Color.studioBackground
                    .ignoresSafeArea()

                AsyncRiveUIViewRepresentable {
                    let worker = try await RiveWorkerProvider.shared.worker()
                    let file = try await File(source: .local("playdate_disc_intake", .main), worker: worker)
                    let artboard = try await file.createArtboard("playdate_disc_intake")
                    let stateMachine = try await artboard.createStateMachine("DiscIntake")
                    return try await Rive(
                        file: file,
                        artboard: artboard,
                        stateMachine: stateMachine,
                        dataBind: .none,
                        fit: .contain(alignment: .center),
                        backgroundColor: RiveRuntime.Color(red: 0, green: 0, blue: 0, alpha: 0)
                    )
                }
                .frameRate(.range(minimum: 60, maximum: 120, preferred: 120))
                .paused(!isPlaying)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .opacity(isReady ? 1 : 0)
                .allowsHitTesting(false)

                Button(action: triggerLoad) {
                    Circle()
                        .fill(SwiftUI.Color.white.opacity(0.001))
                        .frame(width: min(240, proxy.size.width * 0.62), height: min(240, proxy.size.width * 0.62))
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.57)
                .disabled(didFinish)
                .accessibilityLabel("Load playda.te")
                .accessibilityHint("Tap the disc to play the intake animation.")
                .accessibilityIdentifier("launch-disc-intro")
                .sensoryFeedback(.selection, trigger: tapFeedback)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.18)) {
                isReady = true
            }
        }
        .onDisappear {
            finishTask?.cancel()
            finishTask = nil
        }
    }

    private func triggerLoad() {
        guard !didFinish else { return }
        didFinish = true
        tapFeedback.toggle()
        isPlaying = true

        finishTask?.cancel()
        finishTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1_650))
            guard !Task.isCancelled else { return }
            finish()
        }
    }

}
