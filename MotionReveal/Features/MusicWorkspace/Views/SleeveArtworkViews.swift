import SwiftUI
import UIKit

struct SleeveArtworkView: View {
    let artwork: SleeveArtwork

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                baseFill

                switch artwork {
                case .walking:
                    WalkingSleeveArt()
                case .photo:
                    PhotoSleeveArt()
                case .number:
                    Text("89")
                        .font(.system(size: proxy.size.width * 0.38, weight: .black, design: .serif))
                        .foregroundStyle(Color(red: 0.92, green: 0.77, blue: 0.62))
                        .shadow(color: .black.opacity(0.20), radius: 5, x: 0, y: 3)
                case .stack:
                    StackSleeveArt()
                        .padding(proxy.size.width * 0.08)
                case .blank:
                    BlankSleeveArt()
                        .padding(proxy.size.width * 0.20)
                case .columns:
                    ColumnsSleeveArt()
                        .padding(proxy.size.width * 0.20)
                case .customImage(let localFileName, _):
                    CustomSleeveImage(localFileName: localFileName)
                }
            }
            .overlay {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.16),
                        Color.clear,
                        Color.black.opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    @ViewBuilder
    private var baseFill: some View {
        switch artwork {
        case .walking:
            LinearGradient(
                colors: [Color(red: 0.91, green: 0.88, blue: 0.81), Color(red: 0.98, green: 0.94, blue: 0.86)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .photo:
            LinearGradient(
                colors: [Color(red: 0.39, green: 0.52, blue: 0.61), Color(red: 0.14, green: 0.16, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .number:
            LinearGradient(
                colors: [Color(red: 0.27, green: 0.72, blue: 0.80), Color(red: 0.14, green: 0.42, blue: 0.56)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .stack:
            Color.studioPanelRaised
        case .blank:
            LinearGradient(
                colors: [Color(red: 0.78, green: 0.77, blue: 0.68), Color(red: 0.92, green: 0.91, blue: 0.84)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .columns:
            LinearGradient(
                colors: [Color(red: 0.68, green: 0.74, blue: 0.67), Color(red: 0.28, green: 0.37, blue: 0.34)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .customImage:
            Color.black
        }
    }
}

enum MotionArtworkPlaybackPolicy {
    case still
    case animated
}

struct MotionSleeveArtworkView: View {
    let artwork: SleeveArtwork
    let motionArtwork: MotionArtwork?
    var playbackPolicy: MotionArtworkPlaybackPolicy = .animated

    var body: some View {
        ZStack {
            SleeveArtworkView(artwork: artwork)

            if playbackPolicy == .animated, let motionArtwork {
                MotionArtworkVideoSurface(artwork: motionArtwork)
                    .transition(.opacity)
            }
        }
    }
}

private struct CustomSleeveImage: View {
    let localFileName: String
    @StateObject private var loader: SleeveImageLoader

    init(localFileName: String) {
        self.localFileName = localFileName
        _loader = StateObject(wrappedValue: SleeveImageLoader(localFileName: localFileName))
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                BlankSleeveArt()
                    .padding(28)
            }
        }
        .task(id: localFileName) {
            loader.load()
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

private struct WalkingSleeveArt: View {
    var body: some View {
        HStack(spacing: 18) {
            FigureShape(color: Color(red: 0.09, green: 0.28, blue: 0.32), flipped: false)
            FigureShape(color: Color(red: 0.26, green: 0.64, blue: 0.53), flipped: true)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
    }
}

private struct FigureShape: View {
    let color: Color
    let flipped: Bool

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(Color(red: 0.37, green: 0.20, blue: 0.11))
                .frame(width: 16, height: 16)

            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(color)
                .frame(width: 20, height: 42)
                .rotationEffect(.degrees(flipped ? 7 : -7))

            HStack(spacing: 5) {
                Capsule()
                    .fill(Color.black.opacity(0.70))
                    .frame(width: 6, height: 28)
                    .rotationEffect(.degrees(flipped ? -22 : 18))
                Capsule()
                    .fill(Color.black.opacity(0.70))
                    .frame(width: 6, height: 28)
                    .rotationEffect(.degrees(flipped ? 24 : -18))
            }
        }
    }
}

private struct PhotoSleeveArt: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.24))
                .frame(width: 82, height: 82)
                .offset(x: 34, y: -22)

            Circle()
                .fill(Color.black.opacity(0.36))
                .frame(width: 76, height: 76)
                .offset(x: -28, y: 22)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(width: 96, height: 54)
                .rotationEffect(.degrees(-8))
        }
    }
}

private struct StackSleeveArt: View {
    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                Color.studioMint
                Color(red: 0.83, green: 0.79, blue: 0.70)
            }
            GridRow {
                LinearGradient(colors: [.studioRose, .studioGold], startPoint: .topLeading, endPoint: .bottomTrailing)
                Color.black.opacity(0.58)
                    .overlay {
                        VStack(spacing: 3) {
                            Capsule().fill(Color.studioGold).frame(width: 32, height: 3)
                            Capsule().fill(Color.studioMint).frame(width: 46, height: 3)
                            Capsule().fill(Color.studioRose).frame(width: 38, height: 3)
                        }
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct BlankSleeveArt: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(red: 0.15, green: 0.25, blue: 0.25))
                .frame(width: 15)
                .rotationEffect(.degrees(-9))

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.studioMint.opacity(0.95))
                .frame(width: 15)
                .rotationEffect(.degrees(7))
        }
    }
}

private struct ColumnsSleeveArt: View {
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill([Color.studioGold, .studioRose, .studioBlue, .studioMint][index])
                    .frame(width: 14, height: CGFloat(60 + index * 9))
            }
        }
    }
}
