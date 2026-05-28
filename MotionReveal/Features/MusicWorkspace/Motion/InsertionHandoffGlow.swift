import SwiftUI

struct InsertionHandoffGlow: View {
    let progress: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.studioGold.opacity(0.18 * progress))
                .blur(radius: 18)

            Circle()
                .fill(Color.studioMint.opacity(0.12 * progress))
                .scaleEffect(x: 1.4, y: 0.46)
                .blur(radius: 14)
        }
    }
}
