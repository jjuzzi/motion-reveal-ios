import SwiftUI

struct IslandLoadedPulse: View {
    let progress: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.09 * progress),
                            Color.studioMint.opacity(0.08 * progress),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 104 + progress * 10, height: 3.6)
                .blur(radius: 1.4)

            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color.studioGold,
                            Color.studioMint,
                            Color.studioBlue,
                            Color.studioRose,
                            Color.studioGold
                        ],
                        center: .center
                    )
                )
                .frame(width: 20 + progress * 3, height: 20 + progress * 3)
                .overlay {
                    Circle()
                        .fill(Color.black.opacity(0.58))
                        .frame(width: 5.5, height: 5.5)
                }
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.30 * progress), lineWidth: 0.7)
                }
                .shadow(color: Color.studioGold.opacity(0.44 * progress), radius: 12, x: 0, y: 0)
                .offset(x: -45 + progress * 4)

            Circle()
                .stroke(Color.studioMint.opacity(0.24 * progress), lineWidth: 1)
                .frame(width: 29 + progress * 9, height: 29 + progress * 9)
                .blur(radius: 0.4)
                .offset(x: -45 + progress * 4)
        }
        .scaleEffect(0.92 + progress * 0.08)
        .opacity(progress)
    }
}
