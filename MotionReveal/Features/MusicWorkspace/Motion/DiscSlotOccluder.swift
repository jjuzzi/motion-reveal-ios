import SwiftUI

struct DiscSlotOccluder: View {
    let progress: CGFloat
    let bite: CGFloat
    let grip: CGFloat
    let vanish: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.98),
                            Color.black.opacity(0.90),
                            Color.black.opacity(0.42),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: 64
                    )
                )
                .frame(width: 116 + progress * 22, height: 16 + grip * 12)
                .scaleEffect(x: 1 + bite * 0.04, y: 1 - bite * 0.12)
                .opacity((0.30 + grip * 0.64) * (1 - vanish * 0.60))
                .shadow(color: Color.black.opacity(0.54 * grip), radius: 11, x: 0, y: 4)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.92 * grip),
                            Color.black.opacity(0.98 * grip),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 118 + progress * 22, height: max(4, 8 - bite * 3))
                .offset(y: 3 + bite * 2)
                .opacity(0.92 * grip * (1 - vanish * 0.45))

            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.18 * progress),
                            Color.studioGold.opacity(0.18 * progress),
                            Color.studioMint.opacity(0.10 * progress),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 0.8
                )
                .frame(width: 124 + progress * 18, height: 12 + bite * 2.5)
                .offset(y: -4)
                .blur(radius: 0.25)
                .opacity((0.34 + grip * 0.42) * (1 - vanish * 0.55))
        }
    }
}
