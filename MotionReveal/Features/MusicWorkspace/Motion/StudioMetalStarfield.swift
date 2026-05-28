import SwiftUI

struct StudioMetalStarfield: View {
    var starColor: Color = .white
    var background: Color = .studioBackground
    var speed: Float = 0.65
    var layers: Int = 3
    var baseScale: Float = 50
    var scaleStep: Float = 80
    var density: Float = 0.145
    var starSize: Float = 0.065
    var twinkleSpeed: Float = 3.0
    var twinkleAmount: Float = 0.30

    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let elapsed = Float(timeline.date.timeIntervalSince(startDate))

            background
                .colorEffect(
                    ShaderLibrary.studioStarfield(
                        .boundingRect,
                        .float(elapsed),
                        .float(speed),
                        .float(Float(layers)),
                        .float(baseScale),
                        .float(scaleStep),
                        .float(density),
                        .float(starSize),
                        .float(twinkleSpeed),
                        .float(twinkleAmount),
                        .color(starColor),
                        .color(background)
                    )
                )
        }
        .accessibilityHidden(true)
    }
}
