import SwiftUI

struct MotionRevealCarPlayRootView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.16, green: 0.10, blue: 0.17),
                    Color(red: 0.04, green: 0.09, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "opticaldisc")
                    .font(.system(size: 56, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.cyan)

                Text("playda.te")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("CarPlay window scene is live")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))

                Text(Bundle.main.bundleIdentifier ?? "unknown bundle")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.48))
            }
            .multilineTextAlignment(.center)
            .padding(28)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("playda.te CarPlay window scene is live")
        }
    }
}

#Preview {
    MotionRevealCarPlayRootView()
}
