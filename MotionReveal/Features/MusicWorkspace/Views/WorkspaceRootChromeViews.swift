import SwiftUI

struct StudioBackdrop: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.studioBackground
                .ignoresSafeArea()

            if reduceMotion {
                StudioStarfieldBackdrop(reduceMotion: true)
                    .opacity(0.62)
                    .ignoresSafeArea()
            } else {
                StudioMetalStarfield()
                    .opacity(0.68)
                    .ignoresSafeArea()
            }

            LinearGradient(
                colors: [
                    Color.white.opacity(0.018),
                    Color.clear,
                    Color.black.opacity(0.26)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.studioBabyBlue.opacity(0.105),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 10,
                endRadius: 520
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.studioBabyPink.opacity(0.090),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 560
            )
            .ignoresSafeArea()
        }
    }
}

struct StudioStarfieldPreset {
    static let layerCount = 3
    static let speed = 0.65
    static let twinkleSpeed = 3.0
    static let twinkleAmount = 0.30
    static let baseScale = 50.0
    static let scaleStep = 80.0
    static let density = 0.145
    static let starSize = 0.065

    static func starCount(forLayer layer: Int) -> Int {
        max(6, Int((baseScale + Double(layer) * scaleStep) * density))
    }

    static var totalStarCount: Int {
        (0..<layerCount).reduce(0) { count, layer in
            count + starCount(forLayer: layer)
        }
    }

    static func opacity(seed: Double, layer: Int, time: TimeInterval, reduceMotion: Bool) -> Double {
        let baseOpacity = 0.20 + Double(layer) * 0.09
        guard !reduceMotion else { return baseOpacity }

        let wave = sin(time * twinkleSpeed * speed + seed * 6.28318530718)
        return baseOpacity + ((wave + 1) / 2) * twinkleAmount
    }
}

private struct StudioStarfieldBackdrop: View {
    let reduceMotion: Bool

    private static let layers: [[StudioStar]] = (0..<StudioStarfieldPreset.layerCount).map { layer in
        StudioStar.makeLayer(layer)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

                for (layer, stars) in Self.layers.enumerated() {
                    for star in stars {
                        let opacity = StudioStarfieldPreset.opacity(
                            seed: star.seed,
                            layer: layer,
                            time: time,
                            reduceMotion: reduceMotion
                        )
                        let radius = max(0.55, (CGFloat(layer) + 1) * 0.38 + CGFloat(star.seed) * 0.65)
                        let rect = CGRect(
                            x: star.x * size.width,
                            y: star.y * size.height,
                            width: radius + CGFloat(StudioStarfieldPreset.starSize) * 6,
                            height: radius + CGFloat(StudioStarfieldPreset.starSize) * 6
                        )

                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(Color.white.opacity(opacity))
                        )
                    }
                }
            }
        }
        .blendMode(.screen)
        .accessibilityHidden(true)
    }
}

private struct StudioStar: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let seed: Double

    static func makeLayer(_ layer: Int) -> [StudioStar] {
        let count = StudioStarfieldPreset.starCount(forLayer: layer)
        var stars: [StudioStar] = []
        stars.reserveCapacity(count)

        for index in 0..<count {
            var state = UInt64((layer + 1) * 1103515245 + (index + 11) * 2654435761)
            let x = randomUnit(&state)
            let y = randomUnit(&state)
            let seed = randomUnit(&state)

            stars.append(StudioStar(id: layer * 1_000 + index, x: CGFloat(x), y: CGFloat(y), seed: seed))
        }

        return stars
    }

    private static func randomUnit(_ state: inout UInt64) -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) & 0xFFFF_FFFF) / Double(UInt32.max)
    }
}

struct CreateProjectButton: View {
    let createProject: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: createProject) {
                Image(systemName: "plus")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Color.studioBackground)
                    .frame(width: 58, height: 58)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.studioCream,
                                Color.studioBabyBlue.opacity(0.94),
                                Color.studioBabyPink.opacity(0.88)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                    .shadow(color: Color.studioBabyBlue.opacity(0.20), radius: 18, x: -5, y: 8)
                    .shadow(color: Color.studioBabyPink.opacity(0.16), radius: 18, x: 6, y: 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create project")
            .accessibilityIdentifier("create-project")
        }
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        toastContent
            .accessibilityIdentifier("toast")
    }

    @ViewBuilder
    private var toastContent: some View {
        label
            .background(Color.black.opacity(0.74), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
    }

    private var label: some View {
        Text(message)
            .font(StudioType.control)
            .foregroundStyle(Color.studioText)
            .padding(.horizontal, 16)
            .frame(height: 42)
            .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 10)
    }
}
