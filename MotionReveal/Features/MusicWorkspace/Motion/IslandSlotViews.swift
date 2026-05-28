import SwiftUI

struct DiscEdge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let materialProfile = StudioDiscMaterialProfile(
            faceVisibility: 0.82,
            edgeProfile: 0.18,
            reduceMotion: reduceMotion
        )

        Circle()
            .fill(
                AngularGradient(
                    colors: [
                        Color.white.opacity(0.88),
                        Color.studioBlue.opacity(0.85),
                        Color.studioRose.opacity(0.90),
                        Color.studioGold.opacity(0.95),
                        Color.white.opacity(0.88)
                    ],
                    center: .center
                )
            )
            .studioDiscMaterial(materialProfile, mask: Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.36), lineWidth: 1))
            .shadow(color: Color.studioGold.opacity(0.22), radius: 8, x: 0, y: 0)
    }
}

struct StudioIslandLogoMark: View {
    var body: some View {
        ZStack {
            DiscEdge()

            Circle()
                .fill(Color.black.opacity(0.72))
                .frame(width: 7, height: 7)

            Circle()
                .stroke(Color.white.opacity(0.42), lineWidth: 0.8)
        }
    }
}

struct DynamicSlotButton: View {
    let isVisible: Bool
    let isReady: Bool
    let isArmed: Bool
    let pull: CGFloat
    let openSongContainer: () -> Void
    let setArmed: (Bool) -> Void
    let setPull: (CGFloat) -> Void
    @State private var pressBeganAt: Date?
    @State private var hasLongPressed = false
    @State private var armToken = UUID()
    @State private var feedbackTrigger = 0
    @State private var openFeedbackTrigger = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear

            DynamicIslandEdgeBeam(
                isReady: isReady,
                isArmed: isArmed,
                pull: pull
            )
            .offset(y: DynamicIslandEdgeBeamMetrics.yOffset)
            .opacity(edgeBeamOpacity)
            .transition(.opacity)

            if pullGuideOpacity > 0 {
                IslandPullGuide(isReady: isReady, isArmed: isArmed, pull: pull)
                    .offset(y: 7 + min(pull * 0.12, 13))
                    .opacity(pullGuideOpacity)
                    .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .top)))
            }
        }
        .frame(width: 300, height: 112, alignment: .top)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.18), value: isVisible)
        .allowsHitTesting(isVisible)
        .contentShape(Rectangle())
        .gesture(slotGesture)
        .simultaneousGesture(holdGesture)
        .sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger)
        .sensoryFeedback(.success, trigger: openFeedbackTrigger)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Studio drawer pull zone")
        .accessibilityHint("Hold near the top edge and pull down to reveal the studio drawer.")
        .accessibilityIdentifier("dynamic-slot")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text("Open studio drawer")) {
            openFeedbackTrigger += 1
            openSongContainer()
        }
    }

    private var pullGuideOpacity: Double {
        if isArmed || pull > 4 {
            return 1
        }

        return 0
    }

    private var edgeBeamOpacity: Double {
        if isReady || isArmed || pull > 0 {
            return 1
        }

        return 0.72
    }

    private var holdGesture: some Gesture {
        LongPressGesture(minimumDuration: DynamicSlotPullResponse.armHoldDuration, maximumDistance: 22)
            .onEnded { _ in
                armForPull()
            }
    }

    private var slotGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let now = Date()
                if pressBeganAt == nil {
                    pressBeganAt = now
                }

                let holdTime = now.timeIntervalSince(pressBeganAt ?? now)
                let response = DynamicSlotPullResponse(
                    rawPull: value.translation.height,
                    holdTime: hasLongPressed ? DynamicSlotPullResponse.armHoldDuration : holdTime
                )
                setArmed(response.isArmed)
                setPull(response.visualPull)

                if response.shouldOpen {
                    openFeedbackTrigger += 1
                    resetGesture()
                    openSongContainer()
                }
            }
            .onEnded { _ in
                resetGesture()
            }
    }

    private func resetGesture() {
        pressBeganAt = nil
        hasLongPressed = false
        armToken = UUID()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            setArmed(false)
            setPull(0)
        }
    }

    private func armForPull() {
        hasLongPressed = true
        let token = UUID()
        armToken = token
        feedbackTrigger += 1
        setArmed(true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard armToken == token else { return }
            resetGesture()
        }
    }
}

enum DynamicIslandEdgeBeamMetrics {
    static let width: CGFloat = 132
    static let height: CGFloat = 43
    static let yOffset: CGFloat = 8.6
    static let baseStroke: CGFloat = 1.55
    static let chaseStroke: CGFloat = 0.75
    static let glowStroke: CGFloat = 2.1
    static let glowBlur: CGFloat = 1.15
}

struct DynamicIslandEdgeBeam: View {
    let isReady: Bool
    let isArmed: Bool
    let pull: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: CGFloat {
        DynamicSlotPullResponse.progress(forVisualPull: pull)
    }

    var body: some View {
        DynamicIslandEdgeBeamRing(
            progress: progress,
            isActive: isReady || isArmed || pull > 0,
            isAnimated: !reduceMotion && isReady
        )
        .frame(width: DynamicIslandEdgeBeamMetrics.width, height: DynamicIslandEdgeBeamMetrics.height)
        .shadow(
            color: Color.studioGold.opacity(isArmed ? 0.16 : 0.07),
            radius: isArmed ? 7 : 4,
            x: 0,
            y: 0
        )
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

private struct DynamicIslandEdgeBeamRing: View {
    let progress: CGFloat
    let isActive: Bool
    let isAnimated: Bool

    var body: some View {
        if isAnimated {
            KeyframeAnimator(initialValue: 0.0, repeating: true) { value in
                ring(value: value)
            } keyframes: { _ in
                LinearKeyframe(1, duration: 3.1)
            }
        } else {
            ring(value: 0.16)
        }
    }

    private func ring(value: Double) -> some View {
        let rotation = value * 360
        let activeLift = isActive ? 1.0 : 0.64
        let cornerRadius = DynamicIslandEdgeBeamMetrics.height / 2
        let baseGradient = LinearGradient(
            colors: [
                Color.studioGold.opacity(0.46 * activeLift),
                Color.studioMint.opacity(0.32 * activeLift),
                Color.white.opacity(0.18 * activeLift),
                Color.studioRose.opacity(0.24 * activeLift),
                Color.studioGold.opacity(0.46 * activeLift)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        let chaseGradient = AngularGradient(
            colors: [
                .clear,
                Color.studioGold.opacity(0.86),
                Color.studioMint.opacity(0.92),
                Color.white.opacity(0.76),
                .clear
            ],
            center: .center,
            startAngle: .degrees(132 + rotation),
            endAngle: .degrees(292 + rotation)
        )
        let glowGradient = LinearGradient(
            colors: [
                Color.studioMint.opacity(0.74),
                Color.studioBlue.opacity(0.56),
                Color.studioRose.opacity(0.54),
                Color.studioGold.opacity(0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(baseGradient, lineWidth: DynamicIslandEdgeBeamMetrics.baseStroke)
                .opacity(0.78 + progress * 0.10)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(glowGradient, lineWidth: DynamicIslandEdgeBeamMetrics.glowStroke)
                .blur(radius: DynamicIslandEdgeBeamMetrics.glowBlur)
                .opacity((0.11 + progress * 0.07) * activeLift)
                .mask {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(chaseGradient, lineWidth: DynamicIslandEdgeBeamMetrics.glowStroke)
                }

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(chaseGradient, lineWidth: DynamicIslandEdgeBeamMetrics.chaseStroke)
                .opacity((0.78 + progress * 0.10) * activeLift)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct IslandPullGuide: View {
    let isReady: Bool
    let isArmed: Bool
    let pull: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var motion: IslandPullGuideMotion {
        IslandPullGuideMotion(isReady: isReady, reduceMotion: reduceMotion)
    }

    var body: some View {
        ZStack(alignment: .top) {
            IslandPullCapsule(
                isReady: isReady,
                isArmed: isArmed,
                pull: pull
            ) {
                StudioIslandLogoMark()
                    .frame(width: isArmed ? 23 : 20, height: isArmed ? 23 : 20)
                    .rotationEffect(.degrees(motion.rotationDegrees))
                    .shadow(color: Color.studioGold.opacity(0.34), radius: 11, x: 0, y: 0)
                    .animation(
                        motion.usesContinuousSpin ? .linear(duration: 3.2).repeatForever(autoreverses: false) : .easeOut(duration: 0.12),
                        value: motion
                    )
            }

            IslandPullThread(isArmed: isArmed, pull: pull)
                .padding(.top, 38)
        }
        .frame(width: 184, height: 82, alignment: .top)
    }
}

private struct IslandPullCapsule<Content: View>: View {
    let isReady: Bool
    let isArmed: Bool
    let pull: CGFloat
    @ViewBuilder let content: Content

    private var width: CGFloat {
        82 + progress * 18 + (isArmed ? 6 : 0)
    }

    private var height: CGFloat {
        30 + progress * 5 + (isArmed ? 1 : 0)
    }

    private var progress: CGFloat {
        DynamicSlotPullResponse.progress(forVisualPull: pull)
    }

    var body: some View {
        HStack(spacing: 6) {
            content

            Circle()
                .fill(Color.studioGold.opacity(isArmed ? 0.72 : 0.24))
                .frame(width: 4 + progress * 3, height: 4 + progress * 3)
                .opacity(isArmed || progress > 0.15 ? 1 : 0)
        }
        .frame(width: width, height: height)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(isArmed || progress > 0.08 ? 0.12 : 0),
                    Color.studioGold.opacity(isArmed || progress > 0.08 ? 0.10 : 0)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: Capsule()
        )
        .overlay {
            if isArmed || progress > 0.08 {
                Capsule()
                    .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
            }
        }
        .clipShape(Capsule())
        .islandSlotBorderBeam(
            cornerRadius: height / 2,
            beamBlur: 2 + progress * 1.2,
            isEnabled: isArmed || pull > 2
        )
        .shadow(color: Color.studioGold.opacity(isArmed || progress > 0.08 ? 0.14 : 0), radius: 18, x: 0, y: 8)
        .shadow(color: Color.studioGold.opacity(isArmed ? 0.20 : 0.04), radius: 8, x: 0, y: 0)
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: progress)
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: isArmed)
    }
}

private struct IslandPullThread: View {
    let isArmed: Bool
    let pull: CGFloat

    private var progress: CGFloat {
        DynamicSlotPullResponse.progress(forVisualPull: pull)
    }

    var body: some View {
        VStack(spacing: 5) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.studioGold.opacity(0.42),
                            Color.studioMint.opacity(0.24),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1.4, height: 6 + min(pull * 0.28, 24))

            Circle()
                .fill(Color.studioGold.opacity(0.50))
                .frame(width: 3 + progress * 3, height: 3 + progress * 3)
                .shadow(color: Color.studioGold.opacity(0.28), radius: 5, x: 0, y: 0)
        }
        .opacity(isArmed || pull > 4 ? 0.72 : 0)
        .animation(.easeOut(duration: 0.16), value: isArmed)
        .animation(.easeOut(duration: 0.16), value: progress)
    }
}

private extension View {
    func islandSlotBorderBeam(
        cornerRadius: CGFloat,
        beamBlur: CGFloat,
        isEnabled: Bool
    ) -> some View {
        modifier(
            IslandSlotBorderBeamEffect(
                cornerRadius: cornerRadius,
                beamBlur: beamBlur,
                isEnabled: isEnabled
            )
        )
    }
}

private struct IslandSlotBorderBeamEffect: ViewModifier {
    let cornerRadius: CGFloat
    let beamBlur: CGFloat
    let isEnabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if isEnabled {
                    IslandSlotBorderBeam(
                        cornerRadius: cornerRadius,
                        beamBlur: beamBlur,
                        isAnimated: !reduceMotion
                    )
                }
            }
    }
}

private struct IslandSlotBorderBeam: View {
    let cornerRadius: CGFloat
    let beamBlur: CGFloat
    let isAnimated: Bool

    var body: some View {
        if isAnimated {
            KeyframeAnimator(initialValue: 0.0, repeating: true) { value in
                beam(value: value)
            } keyframes: { _ in
                LinearKeyframe(1, duration: 2.65)
            }
        } else {
            beam(value: 0.18)
        }
    }

    private func beam(value: Double) -> some View {
        let rotation = value * 360
        let borderGradient = AngularGradient(
            colors: [
                .clear,
                Color.studioGold,
                Color.studioMint.opacity(0.92),
                Color.studioRose.opacity(0.86),
                .clear
            ],
            center: .center,
            startAngle: .degrees(130 + rotation),
            endAngle: .degrees(300 + rotation)
        )
        let beamGradient = LinearGradient(
            colors: [
                Color.studioMint,
                Color.studioBlue,
                Color.studioRose,
                Color.studioGold
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let baseGradient = LinearGradient(
            colors: [
                Color.studioGold.opacity(0.58),
                Color.studioMint.opacity(0.46),
                Color.studioRose.opacity(0.34),
                Color.studioGold.opacity(0.58)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        return ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(baseGradient, lineWidth: 0.9)
                .opacity(0.84)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(beamGradient, lineWidth: 1.8)
                .blur(radius: beamBlur)
                .opacity(0.34)
                .mask {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(borderGradient, lineWidth: 2.8)
                }

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(borderGradient, lineWidth: 0.95)
                .opacity(0.88)
        }
        .padding(0)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }
}

struct IslandPullGuideMotion: Equatable {
    let rotationDegrees: Double
    let usesContinuousSpin: Bool

    init(isReady: Bool, reduceMotion: Bool) {
        usesContinuousSpin = isReady && !reduceMotion
        rotationDegrees = usesContinuousSpin ? 360 : 0
    }
}
