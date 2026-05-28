import SwiftUI

struct StudioBrandMark: View {
    var body: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.studioCream.opacity(0.10))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }

            StudioLigatureGlyph(size: 38, includeDot: false)
            .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 6)
            .offset(x: 2, y: -1)
        }
        .frame(width: 54, height: 54)
        .background {
            Circle()
                .fill(Color.studioBabyBlue.opacity(0.14))
                .blur(radius: 16)
                .offset(x: -12, y: -10)

            Circle()
                .fill(Color.studioBabyPink.opacity(0.14))
                .blur(radius: 18)
                .offset(x: 14, y: 12)
        }
        .accessibilityHidden(true)
    }
}

struct StudioWordmark: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            StudioLigatureGlyph(size: 23, includeDot: false)
                .frame(width: 25, height: 28)
                .offset(y: 2)
            Text("ayda.te")
                .foregroundStyle(Color.studioText)
        }
        .font(StudioType.semibold(size: 23, relativeTo: .title3))
        .accessibilityLabel("playda dot te")
    }
}

struct StudioBrandLockup: View {
    var caption: String?

    var body: some View {
        HStack(spacing: 13) {
            StudioBrandMark()

            VStack(alignment: .leading, spacing: 3) {
                StudioWordmark()

                if let caption {
                    Text(caption)
                        .font(StudioType.metadataSmall)
                        .foregroundStyle(Color.studioMuted)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
    }
}

private struct StudioLigatureGlyph: View {
    let size: CGFloat
    let includeDot: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            Text("l")
                .font(StudioType.semibold(size: size * 0.88, relativeTo: .title))
                .foregroundStyle(Color.studioBabyPink)
                .offset(x: size * 0.45, y: size * 0.02)

            Text("p")
                .font(StudioType.semibold(size: size, relativeTo: .title))
                .foregroundStyle(Color.studioBabyBlue)

            if includeDot {
                Circle()
                    .fill(Color.studioBabyPink)
                    .frame(width: size * 0.12, height: size * 0.12)
                    .offset(x: size * 0.98, y: size * 0.52)
            }
        }
        .frame(width: size * 1.16, height: size * 1.12, alignment: .leading)
        .accessibilityHidden(true)
    }
}

struct StudioPrimaryButtonBackground: View {
    let isEnabled: Bool

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: buttonColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(isEnabled ? 0.22 : 0.08), lineWidth: 1)
            }
            .shadow(color: Color.studioBabyBlue.opacity(isEnabled ? 0.22 : 0), radius: 18, x: -8, y: 8)
            .shadow(color: Color.studioBabyPink.opacity(isEnabled ? 0.18 : 0), radius: 18, x: 8, y: 10)
    }

    private var buttonColors: [Color] {
        guard isEnabled else {
            return [
                Color.studioGold.opacity(0.26),
                Color.studioGold.opacity(0.20)
            ]
        }

        return [
            Color.studioCream,
            Color.studioBabyBlue.opacity(0.88),
            Color.studioBabyPink.opacity(0.92)
        ]
    }
}
