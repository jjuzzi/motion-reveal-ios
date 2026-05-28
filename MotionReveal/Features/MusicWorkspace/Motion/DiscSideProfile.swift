import SwiftUI

struct DiscSideProfile: View {
    let progress: CGFloat

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.90),
                        Color.studioRose.opacity(0.70),
                        Color.studioGold.opacity(0.98),
                        Color.studioMint.opacity(0.76),
                        Color.studioBlue.opacity(0.82)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.26 + progress * 0.20), lineWidth: 0.8)
            }
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(Color.black.opacity(0.18 * progress))
                    .frame(height: 2.2)
                    .blur(radius: 1.2)
                    .padding(.horizontal, 5)
                    .offset(y: 0.5)
            }
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Color.white.opacity(0.34 * progress))
                    .frame(height: 1.2)
                    .padding(.horizontal, 8)
                    .offset(y: 1.2)
            }
            .blur(radius: 0.25)
    }
}
