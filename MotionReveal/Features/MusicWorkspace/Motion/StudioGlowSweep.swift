import SwiftUI

struct StudioGlowSweep<Content: View>: View {
    let baseColor: Color
    let glowColor: Color
    let duration: Double
    let bandWidth: CGFloat
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    init(
        baseColor: Color = Color.studioGold.opacity(0.46),
        glowColor: Color = Color.studioGold.opacity(0.92),
        duration: Double = 2.4,
        bandWidth: CGFloat = 82,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.baseColor = baseColor
        self.glowColor = glowColor
        self.duration = duration
        self.bandWidth = bandWidth
        self.content = content
    }

    var body: some View {
        let shape = content()

        shape
            .hidden()
            .overlay {
                GeometryReader { proxy in
                    Rectangle()
                        .fill(baseColor)
                        .overlay {
                            if reduceMotion {
                                glowColor.opacity(0.26)
                            } else {
                                LinearGradient(
                                    colors: [.clear, glowColor, .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: bandWidth)
                                .offset(x: animate ? proxy.size.width / 2 + bandWidth : -proxy.size.width / 2 - bandWidth)
                            }
                        }
                        .mask { shape }
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}
