import SwiftUI

struct StudioDisc: View {
    var faceVisibility: CGFloat = 1
    var edgeProfile: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let materialProfile = StudioDiscMaterialProfile(
            faceVisibility: faceVisibility,
            edgeProfile: edgeProfile,
            reduceMotion: reduceMotion
        )

        ZStack {
            Circle()
                .fill(Color(red: 0.94, green: 0.93, blue: 0.88).opacity(0.90 + faceVisibility * 0.08))

            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.70),
                            Color.studioBlue.opacity(0.64),
                            Color.studioLavender.opacity(0.58),
                            Color.studioRose.opacity(0.62),
                            Color.studioGold.opacity(0.70),
                            Color.white.opacity(0.70)
                        ],
                        center: .center
                    )
                )
                .blendMode(.softLight)
                .overlay {
                    DiscGrooveRings()
                        .stroke(Color.white.opacity(0.12 * faceVisibility), lineWidth: 0.55)
                        .padding(8)
                }
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.38 * faceVisibility), lineWidth: 1)
                }
                .overlay {
                    Circle()
                        .stroke(Color.black.opacity(0.12 * faceVisibility), lineWidth: 3)
                        .padding(26)
                }
                .overlay {
                    Circle()
                        .fill(Color.studioBackground.opacity(0.78 * faceVisibility))
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.white.opacity(0.18 * faceVisibility), lineWidth: 1))
                }
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(Color.white.opacity(0.30 * faceVisibility))
                        .frame(width: 18, height: 18)
                        .blur(radius: 2)
                        .offset(x: 16, y: 14)
                }
                .overlay {
                    DiscSpecularSlice()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.70 * faceVisibility),
                                    .white.opacity(0.22 * faceVisibility),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                        )
                        .padding(7)
                }
                .studioDiscMaterial(materialProfile, mask: Circle())
                .opacity(0.32 + faceVisibility * 0.68)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.78),
                            Color.studioGold.opacity(0.92),
                            Color.studioMint.opacity(0.64),
                            Color.studioBlue.opacity(0.74)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 76, height: 3.6 + edgeProfile * 3.4)
                .blur(radius: edgeProfile > 0.65 ? 0.2 : 0.7)
                .opacity(edgeProfile * materialProfile.edgeOpacity)
                .shadow(color: Color.studioGold.opacity(0.34 * edgeProfile), radius: 9, x: 0, y: 0)
        }
    }
}

private struct DiscGrooveRings: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2

        for radius in stride(from: maxRadius * 0.34, through: maxRadius * 0.94, by: 4.2) {
            path.addEllipse(
                in: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
            )
        }

        return path
    }
}

private struct DiscSpecularSlice: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(214),
            endAngle: .degrees(248),
            clockwise: false
        )
        return path
    }
}
