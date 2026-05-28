import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct NowPlayingColorField: View {
    let artwork: SleeveArtwork
    let isExpanded: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false
    @State private var palette: NowPlayingPalette

    init(artwork: SleeveArtwork, isExpanded: Bool) {
        self.artwork = artwork
        self.isExpanded = isExpanded
        _palette = State(initialValue: NowPlayingPalette.fallback(for: artwork))
    }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [palette.primary.opacity(0.34), .clear],
                center: UnitPoint(x: drift ? 0.68 : 0.30, y: drift ? 0.24 : 0.34),
                startRadius: 8,
                endRadius: isExpanded ? 360 : 250
            )

            RadialGradient(
                colors: [palette.secondary.opacity(0.26), .clear],
                center: UnitPoint(x: drift ? 0.24 : 0.76, y: drift ? 0.76 : 0.64),
                startRadius: 10,
                endRadius: isExpanded ? 420 : 280
            )

            RadialGradient(
                colors: [palette.accent.opacity(0.18), .clear],
                center: UnitPoint(x: drift ? 0.54 : 0.42, y: drift ? 0.62 : 0.18),
                startRadius: 14,
                endRadius: isExpanded ? 330 : 220
            )
        }
        .blur(radius: isExpanded ? 32 : 24)
        .saturation(isExpanded ? 1.08 : 0.96)
        .opacity(isExpanded ? 0.74 : 0.46)
        .scaleEffect(drift ? 1.08 : 1.0)
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear(perform: startDrift)
        .task(id: artwork.paletteIdentity) {
            await resolvePalette()
        }
        .onChange(of: reduceMotion) { _, _ in
            startDrift()
        }
    }

    private func startDrift() {
        guard !reduceMotion else {
            drift = false
            return
        }

        withAnimation(.timingCurve(0.22, 0.86, 0.18, 1, duration: 5.8).repeatForever(autoreverses: true)) {
            drift = true
        }
    }

    @MainActor
    private func resolvePalette() async {
        let resolvedPalette = await NowPlayingPaletteResolver.palette(for: artwork)
        guard !Task.isCancelled else { return }

        if reduceMotion {
            palette = resolvedPalette
        } else {
            withAnimation(.smooth(duration: 0.65)) {
                palette = resolvedPalette
            }
        }
    }
}

struct NowPlayingCapsuleGlow: View {
    let artwork: SleeveArtwork
    @State private var palette: NowPlayingPalette

    init(artwork: SleeveArtwork) {
        self.artwork = artwork
        _palette = State(initialValue: NowPlayingPalette.fallback(for: artwork))
    }

    var body: some View {
        LinearGradient(
            colors: [
                palette.primary.opacity(0.30),
                palette.secondary.opacity(0.18),
                palette.accent.opacity(0.24)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.clear,
                    Color.black.opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .accessibilityHidden(true)
        .task(id: artwork.paletteIdentity) {
            let resolvedPalette = await NowPlayingPaletteResolver.palette(for: artwork)
            guard !Task.isCancelled else { return }

            withAnimation(.smooth(duration: 0.55)) {
                palette = resolvedPalette
            }
        }
    }
}

private struct NowPlayingPalette: Equatable, Sendable {
    let primary: StudioPaletteColor
    let secondary: StudioPaletteColor
    let accent: StudioPaletteColor

    static func fallback(for artwork: SleeveArtwork) -> NowPlayingPalette {
        switch artwork {
        case .walking:
            return NowPlayingPalette(primary: .studioGold, secondary: .studioMint, accent: .studioRose)
        case .photo:
            return NowPlayingPalette(primary: .studioBlue, secondary: .studioLavender, accent: .studioIce)
        case .number:
            return NowPlayingPalette(primary: .studioIce, secondary: .studioBlue, accent: .studioGold)
        case .stack:
            return NowPlayingPalette(primary: .studioMint, secondary: .studioRose, accent: .studioGold)
        case .blank:
            return NowPlayingPalette(primary: .studioGold, secondary: .studioRose, accent: .studioMint)
        case .columns:
            return NowPlayingPalette(primary: .studioMint, secondary: .studioGold, accent: .studioBlue)
        case .customImage:
            return NowPlayingPalette(primary: .studioBlue, secondary: .studioGold, accent: .studioRose)
        }
    }
}

private struct StudioPaletteColor: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    var opacity: Double {
        1
    }

    func opacity(_ opacity: Double) -> Color {
        Color(red: red, green: green, blue: blue).opacity(opacity)
    }

    static let studioGold = StudioPaletteColor(Color.studioGold)
    static let studioMint = StudioPaletteColor(Color.studioMint)
    static let studioRose = StudioPaletteColor(Color.studioRose)
    static let studioBlue = StudioPaletteColor(Color.studioBlue)
    static let studioLavender = StudioPaletteColor(Color.studioLavender)
    static let studioIce = StudioPaletteColor(Color.studioIce)

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(_ color: Color) {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
    }
}

private enum NowPlayingPaletteResolver {
    static func palette(for artwork: SleeveArtwork) async -> NowPlayingPalette {
        guard case .customImage(let localFileName, _) = artwork,
              let url = MusicLibraryStore.projectCoverURL(for: localFileName)
        else {
            return NowPlayingPalette.fallback(for: artwork)
        }

        return await Task.detached(priority: .userInitiated) {
            paletteFromImage(at: url) ?? NowPlayingPalette.fallback(for: artwork)
        }.value
    }

    private static func paletteFromImage(at url: URL) -> NowPlayingPalette? {
        guard let sourceImage = UIImage(contentsOfFile: url.path),
              let downsizedImage = sourceImage.downsizedForPalette(maxDimension: 180),
              let ciImage = CIImage(image: downsizedImage) else {
            return nil
        }

        let context = CIContext()
        let count = 4
        let extent = ciImage.extent
        let tileHeight = extent.height / CGFloat(count)
        let colors = (0..<count).compactMap { index -> StudioPaletteColor? in
            let cropRect = CGRect(
                x: extent.origin.x,
                y: extent.height - CGFloat(index + 1) * tileHeight,
                width: extent.width,
                height: tileHeight
            )

            let filter = CIFilter.areaAverage()
            filter.inputImage = ciImage
            filter.extent = cropRect

            guard let outputImage = filter.outputImage else { return nil }

            var bytes = [UInt8](repeating: 0, count: 4)
            context.render(
                outputImage,
                toBitmap: &bytes,
                rowBytes: 4,
                bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: CGColorSpaceCreateDeviceRGB()
            )

            return StudioPaletteColor(
                red: Double(bytes[0]) / 255,
                green: Double(bytes[1]) / 255,
                blue: Double(bytes[2]) / 255
            )
        }

        guard colors.count >= 3 else { return nil }

        return NowPlayingPalette(
            primary: colors[1].liftedForDarkUI(),
            secondary: colors[2].liftedForDarkUI(),
            accent: colors[0].liftedForDarkUI()
        )
    }
}

private extension StudioPaletteColor {
    func liftedForDarkUI() -> StudioPaletteColor {
        let maxChannel = max(red, green, blue)
        let lift = maxChannel < 0.28 ? 0.24 : 0.10

        return StudioPaletteColor(
            red: min(1, red + lift),
            green: min(1, green + lift),
            blue: min(1, blue + lift)
        )
    }
}

private extension SleeveArtwork {
    var paletteIdentity: String {
        switch self {
        case .customImage(let localFileName, _):
            return "custom:\(localFileName)"
        case .walking:
            return "walking"
        case .photo:
            return "photo"
        case .number:
            return "number"
        case .stack:
            return "stack"
        case .blank:
            return "blank"
        case .columns:
            return "columns"
        }
    }
}

private extension UIImage {
    func downsizedForPalette(maxDimension: CGFloat) -> UIImage? {
        let sourceSize = size
        guard sourceSize.width > 0, sourceSize.height > 0 else { return nil }

        let scale = min(1, maxDimension / max(sourceSize.width, sourceSize.height))
        let targetSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
