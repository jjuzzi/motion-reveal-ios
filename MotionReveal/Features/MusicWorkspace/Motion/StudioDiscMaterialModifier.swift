import ShaderKit
import SwiftUI

struct StudioDiscMaterialModifier<Mask: InsettableShape>: ViewModifier {
    let profile: StudioDiscMaterialProfile
    let mask: Mask

    func body(content: Content) -> some View {
        if profile.usesAnimatedShader {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                content
                    .shaderContext(tilt: profile.tilt, time: timeline.date.timeIntervalSinceReferenceDate)
                    .foil(intensity: profile.foilIntensity)
                    .shimmer(intensity: profile.shimmerIntensity)
                    .shader(.glassSheen(intensity: profile.glassSheenIntensity, spread: 0.42))
                    .edgeShine()
                    .clipShape(mask)
            }
        } else {
            content
                .overlay {
                    mask
                        .stroke(Color.white.opacity(profile.glassSheenIntensity), lineWidth: 1)
                        .blendMode(.screen)
                }
                .clipShape(mask)
        }
    }
}

extension View {
    func studioDiscMaterial<Mask: InsettableShape>(
        _ profile: StudioDiscMaterialProfile,
        mask: Mask
    ) -> some View {
        modifier(StudioDiscMaterialModifier(profile: profile, mask: mask))
    }
}
