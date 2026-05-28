import SwiftUI

struct StudioDisc: View {
    var faceVisibility: CGFloat = 1
    var edgeProfile: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            baseFaceLayer

            iridescentFaceLayer

            edgeLayer
        }
    }

    private var materialProfile: StudioDiscMaterialProfile {
        StudioDiscMaterialProfile(
            faceVisibility: faceVisibility,
            edgeProfile: edgeProfile,
            reduceMotion: reduceMotion
        )
    }

    private var baseFaceLayer: some View {
        let faceOpacity = 0.90 + faceVisibility * 0.08

        return Circle()
            .fill(Color(red: 0.94, green: 0.93, blue: 0.88).opacity(faceOpacity))
    }

    private var iridescentFaceLayer: some View {
        Circle()
            .fill(faceGradient)
            .blendMode(.softLight)
            .overlay { grooveLayer }
            .overlay { outerRimLayer }
            .overlay { innerRimLayer }
            .overlay { hubLayer }
            .overlay(alignment: .topLeading) { highlightDotLayer }
            .overlay { specularSliceLayer }
            .studioDiscMaterial(materialProfile, mask: Circle())
            .opacity(0.32 + faceVisibility * 0.68)
    }

    private var edgeLayer: some View {
        let edgeHeight = 3.6 + edgeProfile * 3.4
        let blurRadius = edgeProfile > 0.65 ? 0.2 : 0.7
        let edgeOpacity = edgeProfile * materialProfile.edgeOpacity
        let shadowOpacity = 0.34 * edgeProfile

        return Capsule()
            .fill(edgeGradient)
            .frame(width: 76, height: edgeHeight)
            .blur(radius: blurRadius)
            .opacity(edgeOpacity)
            .shadow(color: Color.studioGold.opacity(shadowOpacity), radius: 9, x: 0, y: 0)
    }

    private var faceGradient: AngularGradient {
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
    }

    private var edgeGradient: LinearGradient {
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
    }

    private var grooveLayer: some View {
        DiscGrooveRings()
            .stroke(Color.white.opacity(0.12 * faceVisibility), lineWidth: 0.55)
            .padding(8)
    }

    private var outerRimLayer: some View {
        Circle()
            .stroke(Color.white.opacity(0.38 * faceVisibility), lineWidth: 1)
    }

    private var innerRimLayer: some View {
        Circle()
            .stroke(Color.black.opacity(0.12 * faceVisibility), lineWidth: 3)
            .padding(26)
    }

    private var hubLayer: some View {
        Circle()
            .fill(Color.studioBackground.opacity(0.78 * faceVisibility))
            .frame(width: 18, height: 18)
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.18 * faceVisibility), lineWidth: 1)
            }
    }

    private var highlightDotLayer: some View {
        Circle()
            .fill(Color.white.opacity(0.30 * faceVisibility))
            .frame(width: 18, height: 18)
            .blur(radius: 2)
            .offset(x: 16, y: 14)
    }

    private var specularSliceLayer: some View {
        DiscSpecularSlice()
            .stroke(specularGradient, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            .padding(7)
    }

    private var specularGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.70 * faceVisibility),
                Color.white.opacity(0.22 * faceVisibility),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
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
