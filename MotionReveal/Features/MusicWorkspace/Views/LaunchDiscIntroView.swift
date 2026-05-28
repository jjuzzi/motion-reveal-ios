import SwiftUI

struct LaunchDiscIntroView: View {
    let finish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isReady = false
    @State private var loadTrigger = 0
    @State private var didFinish = false
    @State private var tapFeedback = false
    @State private var finishTask: Task<Void, Never>?

    var body: some View {
        Group {
            if reduceMotion {
                GeometryReader { proxy in
                    let metrics = LaunchDiscIntroMetrics(proxy: proxy)

                    PhaseAnimator(
                        LaunchDiscTrayPhase.sequence,
                        trigger: loadTrigger
                    ) { phase in
                        launchScene(metrics: metrics, progress: phase.progress)
                    } animation: { phase in
                        nil
                    }
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.14)) {
                            isReady = true
                        }
                    }
                }
            } else {
                LaunchDiscRiveIntroView(finish: finish)
            }
        }
        .onDisappear {
            finishTask?.cancel()
            finishTask = nil
        }
    }

    private func launchScene(metrics: LaunchDiscIntroMetrics, progress: Double) -> some View {
        ZStack {
            Color.studioBackground
                .ignoresSafeArea()

            if metrics.hasDynamicIsland {
                LaunchDiscTrayCradle(
                    progress: progress,
                    discDiameter: trayDiscDiameter(metrics: metrics)
                )
                .frame(width: metrics.trayWidth, height: metrics.trayHeight)
                .position(x: metrics.centerX, y: trayCenterY(metrics: metrics, progress: progress))
                .opacity(trayOpacity(progress: progress))
                .allowsHitTesting(false)
            }

            launchDisc(metrics: metrics, progress: progress)

            Button(action: triggerLoad) {
                Circle()
                    .fill(Color.white.opacity(0.001))
                    .frame(width: metrics.discHitSize, height: metrics.discHitSize)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .position(x: metrics.centerX, y: metrics.restingDiscCenterY)
            .disabled(didFinish)
            .accessibilityLabel("Load playda.te")
            .accessibilityHint("Tap the disc to load it into the top slot.")
            .accessibilityIdentifier("launch-disc-intro")
            .sensoryFeedback(.selection, trigger: tapFeedback)
        }
    }

    private func launchDisc(metrics: LaunchDiscIntroMetrics, progress: Double) -> some View {
        let dock = smoothStep(progress, from: 0.18, to: 0.52)
        let retract = smoothStep(progress, from: 0.58, to: 0.94)
        let vanish = smoothStep(progress, from: 0.86, to: 1)
        let fallbackVanish = metrics.hasDynamicIsland ? vanish : smoothStep(progress, from: 0.12, to: 0.86)
        let dockY = trayDiscCenterY(metrics: metrics, progress: progress)
        let slotY = metrics.slotY + 8
        let discY = if metrics.hasDynamicIsland {
            metrics.restingDiscCenterY + (dockY - metrics.restingDiscCenterY) * dock + (slotY - dockY) * retract
        } else {
            metrics.restingDiscCenterY
        }
        let dockedSize = trayDiscDiameter(metrics: metrics)
        let finalSize: CGFloat = 78
        let discSize = if metrics.hasDynamicIsland {
            metrics.discSize + (dockedSize - metrics.discSize) * dock + (finalSize - dockedSize) * retract
        } else {
            metrics.discSize * (1 - fallbackVanish * 0.08)
        }
        let liftArc = metrics.hasDynamicIsland ? sin(dock * .pi) * -20 : 0
        let retractCompression = metrics.hasDynamicIsland ? max(0.12, 1 - vanish * 0.82) : 1

        return BlankCDIridescenceView()
            .frame(width: discSize, height: discSize)
            .scaleEffect(x: 1 - fallbackVanish * 0.18, y: retractCompression)
            .rotation3DEffect(
                .degrees(-dock * 4 + retract * 7),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.62
            )
            .rotationEffect(.degrees(dock * -5 + retract * 16))
            .scaleEffect(isReady ? 1 : 0.82)
            .opacity((isReady ? 1.0 : 0.0) * (1 - fallbackVanish))
            .brightness(progress > 0 && !reduceMotion ? -0.025 : 0)
            .shadow(color: Color.studioGold.opacity(isReady ? 0.20 * (1 - fallbackVanish) : 0), radius: 34 - dock * 12, x: 0, y: 18 - dock * 12)
            .position(x: metrics.centerX, y: discY + liftArc - vanish * 6)
            .allowsHitTesting(false)
    }

    private func trayOpacity(progress: Double) -> Double {
        let appear = smoothStep(progress, from: 0.02, to: 0.16)
        let disappear = smoothStep(progress, from: 0.82, to: 0.98)
        return appear * (1 - disappear)
    }

    private func trayCenterY(metrics: LaunchDiscIntroMetrics, progress: Double) -> CGFloat {
        let open = smoothStep(progress, from: 0.02, to: 0.34)
        let retract = smoothStep(progress, from: 0.60, to: 0.94)
        let stowedY = metrics.slotY + 22
        return stowedY + (metrics.trayCenterY - stowedY) * open + (stowedY - metrics.trayCenterY) * retract
    }

    private func trayDiscCenterY(metrics: LaunchDiscIntroMetrics, progress: Double) -> CGFloat {
        trayCenterY(metrics: metrics, progress: min(progress, LaunchDiscTrayPhase.discDocked.progress)) + metrics.trayDiscCenterOffset
    }

    private func trayDiscDiameter(metrics: LaunchDiscIntroMetrics) -> CGFloat {
        min(154, metrics.discSize * 0.66)
    }

    private func triggerLoad() {
        guard !didFinish else { return }
        didFinish = true
        tapFeedback.toggle()

        if reduceMotion {
            loadTrigger += 1
            finishTask?.cancel()
            finishTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(260))
                guard !Task.isCancelled else { return }
                finish()
            }
            return
        }

        loadTrigger += 1

        finishTask?.cancel()
        finishTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1_620))
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    private func smoothStep(_ value: Double, from start: Double, to end: Double) -> Double {
        let raw = min(1, max(0, (value - start) / (end - start)))
        return raw * raw * (3 - 2 * raw)
    }
}

private enum LaunchDiscTrayPhase: Equatable {
    case idle
    case trayExtended
    case discDocked
    case trayRetracted
    case complete

    static let sequence: [LaunchDiscTrayPhase] = [
        .idle,
        .trayExtended,
        .discDocked,
        .trayRetracted,
        .complete
    ]

    var progress: Double {
        switch self {
        case .idle:
            return 0
        case .trayExtended:
            return 0.34
        case .discDocked:
            return 0.58
        case .trayRetracted:
            return 0.94
        case .complete:
            return 1
        }
    }

    var animation: Animation? {
        switch self {
        case .idle:
            return nil
        case .trayExtended:
            return .interpolatingSpring(duration: 0.42, bounce: 0.05, initialVelocity: 0.08)
        case .discDocked:
            return .timingCurve(0.22, 0.92, 0.18, 1, duration: 0.46)
        case .trayRetracted:
            return .timingCurve(0.22, 0.88, 0.20, 1, duration: 0.54)
        case .complete:
            return .easeOut(duration: 0.16)
        }
    }
}

private struct LaunchDiscTrayCradle: View {
    let progress: Double
    let discDiameter: CGFloat

    var body: some View {
        let open = smoothStep(progress, from: 0.02, to: 0.34)
        let dock = smoothStep(progress, from: 0.18, to: 0.52)
        let retract = smoothStep(progress, from: 0.60, to: 0.94)
        let active = max(open, 1 - retract)
        let cupScale = 0.94 + dock * 0.06
        let gateCompression = 1 - retract * 0.12

        ZStack {
            LaunchDiscTrayShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.025 * active),
                            Color.black.opacity(0.10 * active),
                            Color.black.opacity(0.20 * active)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    LaunchDiscTrayShape()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.11 * active),
                                    Color.studioGold.opacity(0.20 * active),
                                    Color.studioMint.opacity(0.14 * active),
                                    Color.white.opacity(0.035 * active)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.85
                        )
                }
                .shadow(color: Color.black.opacity(0.24 * active), radius: 16, x: 0, y: 14)
                .scaleEffect(x: gateCompression, y: 1, anchor: .top)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18 * active),
                            Color.studioGold.opacity(0.34 * dock),
                            Color.studioMint.opacity(0.18 * active),
                            Color.white.opacity(0.08 * active)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: discDiameter + 14, height: discDiameter + 14)
                .scaleEffect(cupScale)
                .offset(y: 42)

            Circle()
                .stroke(Color.white.opacity(0.06 * active), lineWidth: 8)
                .frame(width: discDiameter - 24, height: discDiameter - 24)
                .offset(y: 42)
                .blur(radius: 0.4)

            HStack(spacing: discDiameter - 32) {
                Capsule().frame(width: 5, height: 104)
                Capsule().frame(width: 5, height: 104)
            }
            .foregroundStyle(Color.black.opacity(0.22 * active))
            .offset(y: 28)
        }
        .scaleEffect(x: 0.96 + open * 0.04, y: 0.90 + open * 0.10, anchor: .top)
        .rotation3DEffect(
            .degrees(-7 + open * 7 - retract * 3),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.74
        )
        .accessibilityHidden(true)
    }

    private func smoothStep(_ value: Double, from start: Double, to end: Double) -> Double {
        let raw = min(1, max(0, (value - start) / (end - start)))
        return raw * raw * (3 - 2 * raw)
    }
}

private struct LaunchDiscTrayShape: Shape {
    func path(in rect: CGRect) -> Path {
        let centerX = rect.midX
        let stemWidth = rect.width * 0.22
        let cupDiameter = rect.width * 0.82
        let stemRect = CGRect(
            x: centerX - stemWidth / 2,
            y: rect.minY + rect.height * 0.02,
            width: stemWidth,
            height: rect.height * 0.52
        )
        let cupRect = CGRect(
            x: centerX - cupDiameter / 2,
            y: rect.minY + rect.height * 0.38,
            width: cupDiameter,
            height: cupDiameter
        )

        var path = Path()
        path.addRoundedRect(in: stemRect, cornerSize: CGSize(width: stemWidth * 0.28, height: stemWidth * 0.28))
        path.addEllipse(in: cupRect)
        return path
    }
}

private struct LaunchDiscIntroMetrics {
    let centerX: CGFloat
    let slotY: CGFloat
    let restingDiscCenterY: CGFloat
    let discSize: CGFloat
    let discHitSize: CGFloat
    let hasDynamicIsland: Bool
    let trayWidth: CGFloat
    let trayHeight: CGFloat
    let trayCenterY: CGFloat
    let trayDiscCenterOffset: CGFloat

    init(proxy: GeometryProxy) {
        let safeTop = proxy.safeAreaInsets.top
        hasDynamicIsland = safeTop >= 59
        centerX = proxy.size.width / 2
        slotY = max(38, safeTop - 18)
        restingDiscCenterY = proxy.size.height * 0.56
        discSize = min(258, proxy.size.width * 0.66)
        discHitSize = discSize
        trayWidth = min(184, proxy.size.width * 0.46)
        trayHeight = trayWidth * 1.18
        trayCenterY = slotY + trayHeight * 0.72
        trayDiscCenterOffset = trayHeight * 0.20
    }
}
