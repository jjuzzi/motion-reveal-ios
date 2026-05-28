import SwiftUI

enum DiscPlayerMouthLayer {
    case back
    case front
}

struct DiscPlayerMouth: View {
    let progress: CGFloat
    let bite: CGFloat
    let layer: DiscPlayerMouthLayer

    var body: some View {
        ZStack {
            if layer == .back {
                backMouth
            } else {
                frontMouth
            }
        }
    }

    private var backMouth: some View {
        ZStack {
            Capsule()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.98),
                            Color.black.opacity(0.88),
                            Color.black.opacity(0.24),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 78
                    )
                )
                .frame(width: 122 + progress * 14, height: 30 + progress * 7)
                .scaleEffect(x: 1 + bite * 0.025, y: 1 - bite * 0.10)
                .shadow(color: Color.black.opacity(0.52 * progress), radius: 13, x: 0, y: 5)

            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.00),
                            Color.studioGold.opacity(0.24 * progress),
                            Color.white.opacity(0.14 * progress),
                            Color.studioMint.opacity(0.18 * progress),
                            Color.white.opacity(0.00)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 0.9
                )
                .frame(width: 116 + progress * 16, height: 16 + progress * 5)
                .blur(radius: 0.4)
        }
    }

    private var frontMouth: some View {
        VStack(spacing: max(1.5, 6 - bite * 4)) {
            mouthLip(
                colors: [
                    Color.white.opacity(0.32 * progress),
                    Color.studioGold.opacity(0.18 * progress),
                    Color.black.opacity(0.82),
                    Color.black.opacity(0.96)
                ],
                alignment: .top,
                highlightOpacity: 0.22,
                shadowY: 2.5
            )

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.96),
                            Color.black.opacity(0.82),
                            Color.black.opacity(0.96)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 108 + progress * 16, height: max(4, 9 - bite * 5))
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.07 * progress), lineWidth: 0.6)
                }
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12 * progress))
                        .frame(width: 10, height: 1.2)
                        .offset(x: 8)
                }
                .overlay(alignment: .trailing) {
                    Capsule()
                        .fill(Color.studioMint.opacity(0.12 * progress))
                        .frame(width: 10, height: 1.2)
                        .offset(x: -8)
                }

            mouthLip(
                colors: [
                    Color.black.opacity(0.96),
                    Color.black.opacity(0.88),
                    Color.studioMint.opacity(0.12 * progress),
                    Color.white.opacity(0.18 * progress)
                ],
                alignment: .bottom,
                highlightOpacity: 0.12,
                shadowY: -2.5
            )
        }
        .overlay(alignment: .leading) {
            sideCap(color: Color.white.opacity(0.13 * progress), xOffset: -58 - progress * 6)
        }
        .overlay(alignment: .trailing) {
            sideCap(color: Color.studioGold.opacity(0.12 * progress), xOffset: 58 + progress * 6)
        }
        .scaleEffect(x: 1 + bite * 0.018, y: 1 - bite * 0.06)
    }

    private func mouthLip(
        colors: [Color],
        alignment: Alignment,
        highlightOpacity: Double,
        shadowY: CGFloat
    ) -> some View {
        Capsule()
            .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            .frame(width: 118 + progress * 16, height: 4.2 + bite * 1.4)
            .overlay(alignment: alignment) {
                Capsule()
                    .fill(Color.white.opacity(highlightOpacity * progress))
                    .frame(height: alignment == .top ? 0.9 : 0.8)
                    .padding(.horizontal, alignment == .top ? 18 : 22)
            }
            .shadow(color: Color.black.opacity(shadowY > 0 ? 0.50 : 0.44), radius: 5, x: 0, y: shadowY)
    }

    private func sideCap(color: Color, xOffset: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        color,
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3, height: 18 - bite * 5)
            .offset(x: xOffset)
            .blur(radius: 0.5)
    }
}
