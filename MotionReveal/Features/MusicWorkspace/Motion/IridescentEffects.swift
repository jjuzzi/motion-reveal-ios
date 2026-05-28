import SwiftUI

struct IridescentSweep: View {
    var isAnimated = true
    @State private var travel = false

    var body: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.studioBlue.opacity(0.34),
                Color.studioGold.opacity(0.28),
                Color.studioRose.opacity(0.30),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .scaleEffect(1.8)
        .offset(x: travel ? 160 : -160, y: travel ? 70 : -70)
        .blendMode(.screen)
        .onAppear {
            guard isAnimated else { return }
            withAnimation(.timingCurve(0.16, 0.92, 0.18, 1, duration: 1.45).repeatForever(autoreverses: false)) {
                travel = true
            }
        }
    }
}

struct IridescentPool: View {
    var isAnimated = true
    @State private var drift = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.studioBlue.opacity(0.22))
                .frame(width: 210, height: 210)
                .blur(radius: 34)
                .offset(x: drift ? 82 : -68, y: drift ? -36 : 42)

            Circle()
                .fill(Color.studioRose.opacity(0.18))
                .frame(width: 188, height: 188)
                .blur(radius: 38)
                .offset(x: drift ? -70 : 92, y: drift ? 38 : -48)

            Circle()
                .fill(Color.studioGold.opacity(0.16))
                .frame(width: 142, height: 142)
                .blur(radius: 28)
                .offset(x: drift ? 16 : -24, y: drift ? 78 : 20)
        }
        .onAppear {
            guard isAnimated else { return }
            withAnimation(.timingCurve(0.22, 0.86, 0.18, 1, duration: 3.2).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}
