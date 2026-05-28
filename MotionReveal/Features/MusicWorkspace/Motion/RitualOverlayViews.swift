import SwiftUI

struct RitualOverlay: View {
    let phase: LoadRitualPhase
    let project: MusicProject
    let sourceRect: CGRect?
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            if phase != .idle {
                Button {} label: {
                    Color.studioBackground.opacity(phase == .loading ? 0.42 : 1)
                        .ignoresSafeArea()
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(phase == .creating ? "Loading new sleeve" : "Loading sleeve")
                .accessibilityIdentifier("ritual-interaction-shield")
                .accessibilityAddTraits(.isModal)
                .transition(phase == .creating ? .identity : .opacity)

                if phase == .loading {
                    LoadRitual(project: project, sourceRect: sourceRect, reduceMotion: reduceMotion)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                }

                if phase == .creating {
                    CreateRitual(sourceRect: sourceRect, reduceMotion: reduceMotion)
                        .transition(.identity)
                }
            }
        }
        .animation(
            reduceMotion ? .easeOut(duration: 0.16) : .spring(response: 0.58, dampingFraction: 0.86),
            value: phase
        )
        .accessibilityIdentifier("ritual-overlay")
    }
}

private struct LoadRitual: View {
    let project: MusicProject
    let sourceRect: CGRect?
    let reduceMotion: Bool

    var body: some View {
        SleeveToIslandRitual(artwork: project.sleeve, sourceRect: sourceRect, reduceMotion: reduceMotion)
    }
}

private struct CreateRitual: View {
    let sourceRect: CGRect?
    let reduceMotion: Bool

    var body: some View {
        BlankCDToIslandRitual(sourceRect: sourceRect, reduceMotion: reduceMotion)
            .accessibilityIdentifier("create-ritual")
    }
}

private struct BlankCDToIslandRitual: View {
    let sourceRect: CGRect?
    let reduceMotion: Bool
    @State private var didStart = false
    @State private var discFlight: CGFloat = 0
    @State private var discVanish: CGFloat = 0
    @State private var slotGlow: CGFloat = 0
    @State private var slotBite: CGFloat = 0
    @State private var slotLoaded: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let centerX = proxy.size.width / 2
            let promptCenter = sourceRect.map { CGPoint(x: $0.midX, y: $0.midY) }
            let startX = promptCenter?.x ?? centerX
            let startY = promptCenter?.y ?? proxy.size.height * 0.50
            let safeTop = proxy.safeAreaInsets.top
            let islandY = max(28, safeTop - 36)
            let flight = smooth(discFlight)
            let entry = progress(discFlight, from: 0.68, to: 1)
            let edgeProfile = progress(discFlight, from: 0.62, to: 0.95)
            let finalVanish = progress(discFlight, from: 0.97, to: 1)
            let catchPressure = progress(discFlight, from: 0.76, to: 0.96) * (1 - finalVanish)
            let mouthProgress = max(entry, slotBite * 0.92)
            let slotGrip = progress(discFlight, from: 0.84, to: 0.985) * (1 - finalVanish)
            let swallowed = progress(discFlight, from: 0.89, to: 1)
            let intake = progress(discFlight, from: 0.72, to: 0.985)
            let intakeCurve = smooth(intake)
            let arc = -82 * CGFloat(sin(Double(flight) * Double.pi)) * (1 - intakeCurve * 0.76)
            let intakeY = islandY + 5
            let linearY = startY + (islandY - startY) * flight + arc
            let magnetizedY = linearY + (intakeY - linearY) * intakeCurve
            let discX = startX + (centerX - startX) * (flight + (1 - flight) * intakeCurve * 0.42)
            let discY = magnetizedY - progress(discFlight, from: 0.76, to: 0.93) * 11 - slotBite * slotGrip * 11 - swallowed * 28
            let sourceSize = sourceRect.map { min($0.width, $0.height) } ?? 258
            let discSize = max(18, sourceSize - edgeProfile * 154 - swallowed * 64 - finalVanish * 34)
            let discOpacity = (1 - finalVanish * 0.68) * (1 - discVanish * 0.86) * (1 - slotBite * slotGrip * 0.18)
            let discSpin = Double(flight * 132 + slotBite * slotGrip * 18)

            ZStack {
                IslandSlotHardware(progress: entry, isFront: false)
                    .frame(width: 154, height: 58)
                    .position(x: centerX, y: islandY + 12)
                    .opacity((0.12 + entry * 0.24) * (1 - finalVanish * 0.72))
                    .allowsHitTesting(false)

                DynamicIslandEdgeBeam(isReady: true, isArmed: false, pull: catchPressure * DynamicSlotPullResponse.openThreshold)
                    .position(x: centerX, y: islandY + 12)
                    .opacity((0.18 + entry * 0.70) * (1 - finalVanish * 0.72))
                    .allowsHitTesting(false)

                DiscPlayerMouth(progress: mouthProgress, bite: slotBite, layer: .back)
                    .frame(width: 162, height: 64)
                    .position(x: centerX, y: islandY + 12)
                    .opacity((0.12 + mouthProgress * 0.62) * (1 - finalVanish * 0.74))
                    .allowsHitTesting(false)

                InsertionHandoffGlow(progress: entry)
                    .frame(width: 128, height: 80)
                    .position(x: centerX, y: islandY + 8)
                    .opacity((0.14 + slotGlow * 0.16) * catchPressure * (1 - slotBite * 0.42))
                    .allowsHitTesting(false)

                BlankCDIridescenceView(reactsToMotion: false)
                    .frame(width: discSize, height: discSize)
                    .rotationEffect(.degrees(discSpin))
                    .rotation3DEffect(
                        .degrees(-84 * Double(edgeProfile)),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .center,
                        perspective: 0.72
                    )
                    .scaleEffect(
                        x: 1 - edgeProfile * 0.06,
                        y: max(0.10, 1 - edgeProfile * 0.76 - slotBite * slotGrip * 0.16 - swallowed * 0.08),
                        anchor: .center
                    )
                    .position(x: discX, y: discY)
                    .opacity(discOpacity)
                    .shadow(color: Color.studioGold.opacity(0.22 * (1 - finalVanish)), radius: 24, x: 0, y: 0)
                    .shadow(color: Color.black.opacity(0.22 * (1 - finalVanish)), radius: 22, x: 0, y: 12)
                    .allowsHitTesting(false)

                DiscSideProfile(progress: edgeProfile)
                    .frame(width: discSize * (0.92 + edgeProfile * 0.10), height: 3.5 + edgeProfile * 4.0)
                    .position(x: discX, y: discY + edgeProfile * 1.5)
                    .opacity(0.82 * edgeProfile * (1 - finalVanish) * (1 - discVanish))
                    .shadow(color: Color.studioGold.opacity(0.30 * edgeProfile), radius: 10, x: 0, y: 0)

                DiscSlotOccluder(progress: mouthProgress, bite: slotBite, grip: slotGrip, vanish: finalVanish)
                    .frame(width: 164, height: 54)
                    .position(x: centerX, y: islandY + 12)
                    .opacity((0.20 + catchPressure * 0.80 + slotGrip * slotBite * 0.24) * (1 - finalVanish * 0.72))
                    .allowsHitTesting(false)

                IslandSlotHardware(progress: entry, isFront: true)
                    .frame(width: 154, height: 58)
                    .position(x: centerX, y: islandY + 12)
                    .opacity(catchPressure * 0.52 * (1 - finalVanish * 0.82))
                    .allowsHitTesting(false)

                DiscPlayerMouth(progress: mouthProgress, bite: slotBite, layer: .front)
                    .frame(width: 162, height: 64)
                    .position(x: centerX, y: islandY + 12)
                    .opacity((catchPressure * 0.80 + slotGrip * slotBite * 0.16) * (1 - finalVanish * 0.84))
                    .allowsHitTesting(false)

                IslandLoadedPulse(progress: slotLoaded)
                    .frame(width: 128, height: 36)
                    .position(x: centerX, y: islandY + 44)
                    .allowsHitTesting(false)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .task {
                await startRitual()
            }
        }
        .ignoresSafeArea()
    }

    @MainActor
    private func startRitual() async {
        guard !didStart else { return }
        didStart = true

        if reduceMotion {
            withAnimation(.easeOut(duration: 0.20)) {
                discFlight = 1
                discVanish = 1
                slotGlow = 1
                slotBite = 1
                slotLoaded = 1
            }
            return
        }

        withAnimation(.timingCurve(0.16, 0.86, 0.14, 1, duration: 0.90)) {
            discFlight = 0.90
            slotGlow = 1
        }

        try? await Task.sleep(for: .milliseconds(640))
        guard !Task.isCancelled else { return }

        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
            slotBite = 0.74
        }

        try? await Task.sleep(for: .milliseconds(170))
        guard !Task.isCancelled else { return }

        withAnimation(.timingCurve(0.20, 0.88, 0.16, 1, duration: 0.28)) {
            discFlight = 1
            slotBite = 1
            slotLoaded = 0.68
        }

        try? await Task.sleep(for: .milliseconds(190))
        guard !Task.isCancelled else { return }

        withAnimation(.timingCurve(0.16, 0.86, 0.24, 1, duration: 0.20)) {
            discVanish = 1
        }

        withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
            slotLoaded = 1
        }
    }

    private func progress(_ value: CGFloat, from start: CGFloat, to end: CGFloat) -> CGFloat {
        smooth((value - start) / (end - start))
    }

    private func smooth(_ value: CGFloat) -> CGFloat {
        let clamped = min(max(value, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }
}

private struct SleeveToIslandRitual: View {
    let artwork: SleeveArtwork
    let sourceRect: CGRect?
    let reduceMotion: Bool
    @State private var didStart = false
    @State private var sleeveLift: CGFloat = 0
    @State private var discPeek: CGFloat = 0
    @State private var discFlight: CGFloat = 0
    @State private var discVanish: CGFloat = 0
    @State private var shimmerTilt: Double = -22
    @StateObject private var deviceTilt = StudioDeviceTiltController()

    var body: some View {
        GeometryReader { proxy in
            let centerX = proxy.size.width / 2
            let safeTop = proxy.safeAreaInsets.top
            let tableY = proxy.size.height * 0.42
            let islandY = max(28, safeTop - 36)
            let flight = smooth(discFlight)
            let reveal = smooth(discPeek)
            let entry = progress(discFlight, from: 0.76, to: 1)
            let edgeProfile = progress(discFlight, from: 0.70, to: 0.96)
            let faceVisibility = 1 - progress(discFlight, from: 0.68, to: 0.96)
            let finalVanish = progress(discFlight, from: 0.972, to: 1)
            let sourceRelease = progress(discFlight, from: 0.06, to: 0.42)
            let insertionSnap = progress(discFlight, from: 0.74, to: 0.93)
            let hardwareOcclusion = 1 - progress(discFlight, from: 0.86, to: 0.995) * 0.78
            let sourceBodyPresence = (1 - progress(discFlight, from: 0.18, to: 0.62)) * (1 - discVanish)
            let sourcePressure = progress(discPeek, from: 0.08, to: 0.82) * (1 - sourceRelease * 0.62)
            let sourceShadow = (0.78 - sourceRelease * 0.42) * (1 - discVanish)
            let catchPressure = progress(discFlight, from: 0.78, to: 0.96) * (1 - finalVanish)
            let slotGrip = progress(discFlight, from: 0.82, to: 0.985) * (1 - finalVanish)
            let mouthProgress = max(entry, slotGrip * 0.90)
            let swallowed = progress(discFlight, from: 0.86, to: 1)
            let fallbackStartX = centerX - 110
            let fallbackStartY = tableY - 72
            let sourceStartX = sourceRect.map { $0.minX + $0.width * 0.34 } ?? fallbackStartX
            let sourceStartY = sourceRect.map { $0.minY + $0.height * 0.58 } ?? fallbackStartY
            let sourceDiscSize = sourceRect.map { min(max($0.width * 0.60, 104), 126) } ?? 118
            let startX = sourceStartX
            let startY = sourceStartY
            let endX = centerX
            let endY = islandY
            let arc = -86 * CGFloat(sin(Double(flight) * Double.pi)) * (1 - entry * 0.70)
            let drift = CGFloat(sin(Double(flight) * Double.pi * 0.9)) * 6 * (1 - entry * 0.82)
            let discSpin = Double(8 + flight * 96 + reveal * 8)
            let discSize = max(22, sourceDiscSize + 4 - edgeProfile * 54 - swallowed * 22 - finalVanish * 30)
            let discX = startX + (endX - startX) * flight + drift
            let discY = startY + (endY - startY) * flight + arc - insertionSnap * 34 - swallowed * 32
            let discOpacity = (0.78 + reveal * 0.22) * (1 - finalVanish * 0.42) * (1 - discVanish * 0.84) * hardwareOcclusion
            let sourceOcclusionOpacity = 0.76 * (1 - sourceRelease) * (1 - finalVanish) * (1 - discVanish)
            let lipOpacity = 0.28 * (1 - sourceRelease * 0.82) * (1 - finalVanish) * (1 - discVanish)
            let liveTilt = deviceTilt.tilt.scaled(faceVisibility: faceVisibility, edgeProfile: edgeProfile)

            ZStack {
                IslandSlotHardware(progress: entry, isFront: false)
                    .frame(width: 178, height: 68)
                    .position(x: endX, y: endY + 10)
                    .opacity((0.24 + entry * 0.36) * (1 - finalVanish * 0.72))
                    .allowsHitTesting(false)

                DynamicIslandEdgeBeam(isReady: true, isArmed: false, pull: catchPressure * DynamicSlotPullResponse.openThreshold)
                    .position(x: endX, y: endY + 10)
                    .opacity((0.18 + entry * 0.72) * (1 - finalVanish * 0.72))
                    .allowsHitTesting(false)

                DiscPlayerMouth(progress: mouthProgress, bite: slotGrip, layer: .back)
                    .frame(width: 170, height: 66)
                    .position(x: endX, y: endY + 10)
                    .opacity((0.10 + mouthProgress * 0.54) * (1 - finalVanish * 0.74))
                    .allowsHitTesting(false)

                InsertionHandoffGlow(progress: entry)
                    .frame(width: 112, height: 74)
                    .position(x: endX, y: endY + 8)
                    .opacity(0.18 * catchPressure * (1 - discVanish))
                    .allowsHitTesting(false)

                SourceSleeveBody(
                    artwork: artwork,
                    reveal: reveal,
                    lift: sleeveLift,
                    release: sourceRelease,
                    pressure: sourcePressure,
                    shimmerTilt: shimmerTilt
                )
                .frame(width: sourceDiscSize * 1.08, height: sourceDiscSize * 0.32)
                .rotationEffect(.degrees(-6 + Double(flight) * 2.2))
                .position(
                    x: startX - 2 + flight * 5,
                    y: startY + sourceDiscSize * 0.52 - flight * 5
                )
                .opacity(max(0, sourceBodyPresence) * 0.74)
                .shadow(color: Color.black.opacity(0.32 * sourceShadow), radius: 18, x: 0, y: 12)

                DiscContactShadow(progress: sourcePressure, release: sourceRelease)
                    .frame(width: sourceDiscSize * 0.92, height: sourceDiscSize * 0.20)
                    .rotationEffect(.degrees(-6 + Double(flight) * 2.2))
                    .position(x: startX - 2 + flight * 5, y: startY + sourceDiscSize * 0.45 - flight * 5)
                    .opacity(max(0, sourceBodyPresence))

                StudioDisc(faceVisibility: faceVisibility, edgeProfile: edgeProfile)
                    .frame(width: discSize, height: discSize)
                    .rotationEffect(.degrees(discSpin))
                    .rotation3DEffect(
                        .degrees(-88 * Double(edgeProfile)),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .center,
                        perspective: 0.72
                    )
                    .rotation3DEffect(
                        .degrees(liveTilt.pitchDegrees),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .center,
                        perspective: 0.56
                    )
                    .rotation3DEffect(
                        .degrees(liveTilt.rollDegrees),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .center,
                        perspective: 0.56
                    )
                    .scaleEffect(
                        x: 0.64 + reveal * 0.36 + edgeProfile * 0.10,
                        y: max(0.14, 0.64 + reveal * 0.36 - edgeProfile * 0.70 - slotGrip * 0.12)
                    )
                    .position(
                        x: discX,
                        y: discY
                    )
                    .opacity(discOpacity)
                    .shadow(color: Color.studioGold.opacity(0.24 * (1 - finalVanish)), radius: 18, x: 0, y: 0)
                    .shadow(color: Color.studioBlue.opacity(0.16 * faceVisibility), radius: 22, x: 0, y: 4)

                SourceSleevePocketOccluder(artwork: artwork, reveal: reveal, lift: sleeveLift, shimmerTilt: shimmerTilt)
                    .frame(width: sourceDiscSize * 0.90, height: sourceDiscSize * 0.13)
                    .rotationEffect(.degrees(-6 + Double(flight) * 2))
                    .position(x: startX - 2 + flight * 5, y: startY + sourceDiscSize * 0.49 - flight * 5)
                    .opacity(max(0, sourceOcclusionOpacity))

                SourceSleeveLip(artwork: artwork, reveal: reveal, lift: sleeveLift, shimmerTilt: shimmerTilt)
                    .frame(width: 78, height: 6)
                    .rotationEffect(.degrees(-6 + Double(flight) * 2.6))
                    .position(x: startX - 2 + flight * 5, y: startY + sourceDiscSize * 0.46 - flight * 5)
                    .opacity(max(0, lipOpacity))

                DiscSideProfile(progress: edgeProfile)
                    .frame(width: discSize * (0.90 + edgeProfile * 0.12), height: 3.5 + edgeProfile * 4.0)
                    .rotationEffect(.degrees(-2 + edgeProfile * 4))
                    .position(x: discX, y: discY + edgeProfile * 1.5)
                    .opacity(0.84 * edgeProfile * (1 - finalVanish * 0.18) * (1 - discVanish * 0.68) * hardwareOcclusion)
                    .shadow(color: Color.studioGold.opacity(0.32 * edgeProfile), radius: 10, x: 0, y: 0)

                DiscSlotOccluder(progress: mouthProgress, bite: slotGrip, grip: slotGrip, vanish: finalVanish)
                    .frame(width: 168, height: 54)
                    .position(x: endX, y: endY + 10)
                    .opacity((0.18 + catchPressure * 0.70) * (1 - finalVanish * 0.74))
                    .allowsHitTesting(false)

                IslandSlotHardware(progress: entry, isFront: true)
                    .frame(width: 178, height: 68)
                    .position(x: endX, y: endY + 10)
                    .opacity(catchPressure * (1 - finalVanish * 0.82))
                    .allowsHitTesting(false)

                DiscPlayerMouth(progress: mouthProgress, bite: slotGrip, layer: .front)
                    .frame(width: 170, height: 66)
                    .position(x: endX, y: endY + 10)
                    .opacity((catchPressure * 0.74 + slotGrip * 0.12) * (1 - finalVanish * 0.84))
                    .allowsHitTesting(false)

                FlightTrail(progress: discFlight)
                    .stroke(Color.studioGold.opacity(0.07 * flight * (1 - finalVanish * 0.72)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                    .frame(width: 220, height: 220)
                    .position(x: centerX - 20, y: tableY - 92)
                    .blur(radius: 1.5)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .task {
                await startRitual()
            }
            .onAppear {
                deviceTilt.start(reduceMotion: reduceMotion)
            }
            .onDisappear {
                deviceTilt.stop()
            }
            .onChange(of: reduceMotion) { _, reduceMotion in
                if reduceMotion {
                    deviceTilt.stop()
                } else {
                    deviceTilt.start(reduceMotion: false)
                }
            }
        }
        .ignoresSafeArea()
    }

    @MainActor
    private func startRitual() async {
        guard !didStart else { return }
        didStart = true

        if reduceMotion {
            withAnimation(.easeOut(duration: 0.22)) {
                sleeveLift = 0.7
                discPeek = 0.9
                discFlight = 1
                discVanish = 1
                shimmerTilt = 0
            }
            return
        }

        withAnimation(.timingCurve(0.18, 0.82, 0.20, 1, duration: 0.30)) {
            sleeveLift = 0.82
            discPeek = 0.58
            shimmerTilt = -4
        }

        try? await Task.sleep(for: .milliseconds(90))
        guard !Task.isCancelled else { return }

        withAnimation(.timingCurve(0.16, 0.84, 0.16, 1, duration: 0.78)) {
            sleeveLift = 1
            discPeek = 1
            discFlight = 0.94
            shimmerTilt = 12
        }

        try? await Task.sleep(for: .milliseconds(620))
        guard !Task.isCancelled else { return }

        withAnimation(.timingCurve(0.10, 0.90, 0.20, 1, duration: 0.24)) {
            discFlight = 1
            discVanish = 1
        }
    }

    private func progress(_ value: CGFloat, from start: CGFloat, to end: CGFloat) -> CGFloat {
        smooth((value - start) / (end - start))
    }

    private func smooth(_ value: CGFloat) -> CGFloat {
        let clamped = min(max(value, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }
}

private struct SourceSleeveLip: View {
    let artwork: SleeveArtwork
    let reveal: CGFloat
    let lift: CGFloat
    let shimmerTilt: Double

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.black.opacity(0.26))
                .blur(radius: 5.5)
                .offset(y: 6)
                .scaleEffect(x: 0.92, y: 0.72, anchor: .center)

            Capsule()
                .fill(lipFill)
                .overlay(alignment: .topLeading) {
                    IridescentSweep(isAnimated: false)
                        .rotationEffect(.degrees(shimmerTilt))
                        .opacity(0.16 + reveal * 0.12)
                        .clipShape(Capsule())
                }
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.white.opacity(0.18 + reveal * 0.18))
                        .frame(height: 1.3)
                        .padding(.horizontal, 16)
                        .offset(y: 2)
                }
                .overlay(alignment: .bottom) {
                    Capsule()
                        .fill(Color.black.opacity(0.16))
                        .frame(height: 4)
                        .blur(radius: 2)
                        .padding(.horizontal, 8)
                        .offset(y: -2)
                }
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.10 + reveal * 0.10), lineWidth: 0.8)
                }
                .scaleEffect(x: 1, y: 0.48 + lift * 0.12, anchor: .center)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.26 + reveal * 0.18),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .padding(.horizontal, 18)
                .offset(y: -1)
        }
    }

    private var lipFill: LinearGradient {
        switch artwork {
        case .walking:
            LinearGradient(
                colors: [
                    Color(red: 0.86, green: 0.82, blue: 0.72),
                    Color(red: 0.58, green: 0.55, blue: 0.48)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .photo, .customImage:
            LinearGradient(
                colors: [
                    Color(red: 0.34, green: 0.47, blue: 0.56),
                    Color(red: 0.10, green: 0.12, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .number:
            LinearGradient(
                colors: [
                    Color(red: 0.27, green: 0.70, blue: 0.78),
                    Color(red: 0.12, green: 0.35, blue: 0.49)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .stack:
            LinearGradient(
                colors: [
                    Color.studioPanelRaised,
                    Color.studioPanel
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .blank:
            LinearGradient(
                colors: [
                    Color(red: 0.82, green: 0.81, blue: 0.72),
                    Color(red: 0.64, green: 0.62, blue: 0.53)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .columns:
            LinearGradient(
                colors: [
                    Color(red: 0.62, green: 0.70, blue: 0.62),
                    Color(red: 0.22, green: 0.30, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct SourceSleeveBody: View {
    let artwork: SleeveArtwork
    let reveal: CGFloat
    let lift: CGFloat
    let release: CGFloat
    let pressure: CGFloat
    let shimmerTilt: Double

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(bodyFill)
                .opacity(0.52 + pressure * 0.18)
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(0.60 + pressure * 0.12))
                        .frame(height: 3.4 + pressure * 1.2)
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                        .shadow(color: Color.white.opacity(0.16 * pressure), radius: 4, x: 0, y: -1)
                }
                .overlay(alignment: .top) {
                    IridescentSweep(isAnimated: false)
                        .rotationEffect(.degrees(shimmerTilt))
                        .opacity(0.08 + reveal * 0.08)
                        .mask(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .padding(.top, 2)
                                .frame(height: 26 + lift * 7)
                        )
                }
                .overlay(alignment: .bottomTrailing) {
                    HStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { index in
                            Capsule()
                                .fill(Color.black.opacity(0.12 + pressure * 0.05))
                                .frame(width: 3.5, height: 2.5 + CGFloat(index % 2) * 1.2)
                        }
                    }
                    .padding(.trailing, 18)
                    .padding(.bottom, 6)
                    .opacity(0.52 * (1 - release))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.white.opacity(0.12 + pressure * 0.08), lineWidth: 0.8)
                }

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.16 + pressure * 0.10))
                .frame(height: 6 + pressure * 2)
                .padding(.horizontal, 8)
                .offset(y: 18 + pressure * 2)
                .blur(radius: 3.5)
                .opacity((0.42 + pressure * 0.24) * (1 - release * 0.74))
        }
        .scaleEffect(x: 1 - release * 0.06, y: 1 - release * 0.08, anchor: .center)
    }

    private var bodyFill: LinearGradient {
        switch artwork {
        case .walking, .blank:
            LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.87, blue: 0.78),
                    Color(red: 0.64, green: 0.63, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .photo, .customImage:
            LinearGradient(
                colors: [
                    Color(red: 0.36, green: 0.47, blue: 0.55),
                    Color(red: 0.12, green: 0.15, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .number:
            LinearGradient(
                colors: [
                    Color(red: 0.28, green: 0.68, blue: 0.76),
                    Color(red: 0.12, green: 0.34, blue: 0.48)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .stack:
            LinearGradient(
                colors: [
                    Color.studioPanelRaised.opacity(0.98),
                    Color.studioPanel.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .columns:
            LinearGradient(
                colors: [
                    Color(red: 0.60, green: 0.68, blue: 0.58),
                    Color(red: 0.22, green: 0.30, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct DiscContactShadow: View {
    let progress: CGFloat
    let release: CGFloat

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.46 + progress * 0.16),
                        Color.black.opacity(0.22),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .blur(radius: 5.5 - min(progress * 2.2, 2.2))
            .scaleEffect(x: 0.82 + progress * 0.18, y: 0.52 + progress * 0.18, anchor: .center)
            .opacity((0.62 + progress * 0.30) * (1 - release * 0.88))
    }
}

private struct SourceSleevePocketOccluder: View {
    let artwork: SleeveArtwork
    let reveal: CGFloat
    let lift: CGFloat
    let shimmerTilt: Double

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.black.opacity(0.26 + lift * 0.12))
                .blur(radius: 7)
                .scaleEffect(x: 1.04, y: 0.72, anchor: .center)
                .offset(y: 4)

            Capsule()
                .fill(pocketFill)
                .opacity(0.18 + reveal * 0.08)
                .blur(radius: 2.4)
                .scaleEffect(x: 0.98, y: 0.54, anchor: .center)
                .offset(y: 2)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.24 + reveal * 0.14),
                            Color.studioGold.opacity(0.18),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2.6)
                .padding(.horizontal, 9)
                .offset(y: -2)

            IridescentSweep(isAnimated: false)
                .rotationEffect(.degrees(shimmerTilt))
                .opacity(0.05 + reveal * 0.04)
                .mask(Capsule().scaleEffect(x: 0.9, y: 0.38))
        }
    }

    private var pocketFill: LinearGradient {
        switch artwork {
        case .walking:
            LinearGradient(
                colors: [
                    Color(red: 0.82, green: 0.78, blue: 0.67),
                    Color(red: 0.70, green: 0.67, blue: 0.58)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .photo, .customImage:
            LinearGradient(
                colors: [
                    Color(red: 0.29, green: 0.39, blue: 0.47),
                    Color(red: 0.12, green: 0.15, blue: 0.19)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .number:
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.62, blue: 0.72),
                    Color(red: 0.12, green: 0.36, blue: 0.48)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .stack:
            LinearGradient(
                colors: [
                    Color.studioPanelRaised,
                    Color.studioPanel.opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .blank:
            LinearGradient(
                colors: [
                    Color(red: 0.80, green: 0.78, blue: 0.68),
                    Color(red: 0.63, green: 0.60, blue: 0.51)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .columns:
            LinearGradient(
                colors: [
                    Color(red: 0.54, green: 0.63, blue: 0.55),
                    Color(red: 0.22, green: 0.30, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
