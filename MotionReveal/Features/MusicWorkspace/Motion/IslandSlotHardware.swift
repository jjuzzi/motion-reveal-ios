import SwiftUI

struct IslandSlotHardware: View {
    let progress: CGFloat
    let isFront: Bool

    var body: some View {
        ZStack {
            if !isFront {
                backLayer
            } else {
                frontLayer
            }
        }
    }

    private var backLayer: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.52),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 108 + progress * 16, height: 10 + progress * 4)
                .blur(radius: 6)
                .offset(y: 1)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.studioGold.opacity(0.18 * progress),
                            Color.studioMint.opacity(0.12 * progress),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 94 + progress * 12, height: 1.6)
                .offset(y: -6)
        }
    }

    private var frontLayer: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.14 * progress),
                            Color.black.opacity(0.0),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 106 + progress * 14, height: 8)
                .blur(radius: 2.4)

            Rectangle()
                .fill(Color.studioGold.opacity(0.16 * progress))
                .frame(width: 66, height: 1.6)
                .offset(y: -4)
                .blur(radius: 1)
        }
    }
}
