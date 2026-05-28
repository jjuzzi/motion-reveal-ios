import SwiftUI

struct StudioImportNotchTray: View {
    @Binding var isPresented: Bool
    let projectTitle: String
    let importAudio: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var isExpanded = false

    var body: some View {
        GeometryReader { proxy in
            let safeArea = proxy.safeAreaInsets
            let hasDynamicIsland = safeArea.top >= 59
            let collapsedWidth: CGFloat = DynamicIslandEdgeBeamMetrics.width
            let collapsedHeight: CGFloat = DynamicIslandEdgeBeamMetrics.height
            let expandedWidth = min(proxy.size.width - 30, 382)
            let expandedHeight: CGFloat = 394
            let collapsedTopOffset = hasDynamicIsland
                ? 11 + max(safeArea.top - 59, 0)
                : (isExpanded ? safeArea.top + 10 : -collapsedHeight)
            let expandedTopOffset = safeArea.top + (hasDynamicIsland ? 24 : 10)
            let topOffset = isExpanded ? expandedTopOffset : collapsedTopOffset

            ZStack(alignment: .top) {
                Color.black
                    .opacity(isExpanded ? 0.34 : 0)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture(perform: close)

                if showContent {
                    trayBody
                        .frame(
                            width: isExpanded ? expandedWidth : collapsedWidth,
                            height: isExpanded ? expandedHeight : collapsedHeight
                        )
                        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 34 : collapsedHeight / 2, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: isExpanded ? 34 : collapsedHeight / 2, style: .continuous)
                                .strokeBorder(Color.white.opacity(isExpanded ? 0.12 : 0.18), lineWidth: 1)
                        }
                        .shadow(color: Color.black.opacity(isExpanded ? 0.36 : 0.18), radius: isExpanded ? 28 : 10, x: 0, y: isExpanded ? 18 : 5)
                        .offset(y: topOffset)
                        .transition(.identity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .task { await start() }
        }
        .accessibilityIdentifier("studio-import-notch-tray")
    }

    private var trayBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(Color.studioBackground.opacity(0.64))
                }

            DynamicIslandEdgeBeam(isReady: true, isArmed: false, pull: 0)
                .opacity(isExpanded ? 0 : 0.86)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 0)

            expandedContent
                .padding(.horizontal, 22)
                .padding(.top, 64)
                .padding(.bottom, 34)
                .frame(maxHeight: .infinity, alignment: .top)
                .opacity(isExpanded ? 1 : 0)
                .blur(radius: isExpanded ? 0 : 14)
                .allowsHitTesting(isExpanded)
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "waveform.badge.plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.studioBackground)
                    .frame(width: 44, height: 44)
                    .background(Color.studioGold, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Import bounces")
                        .font(StudioType.deckTitle)
                        .foregroundStyle(Color.studioText)

                    Text(projectTitle)
                        .font(StudioType.metadata)
                        .foregroundStyle(Color.studioMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.studioMuted)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close import tray")
            }

            StudioImportMeterField()
                .frame(height: 84)

            HStack(spacing: 8) {
                StudioImportFormatChip(text: "WAV")
                StudioImportFormatChip(text: "AIFF")
                StudioImportFormatChip(text: "MP3")
                StudioImportFormatChip(text: "M4A")
            }

            Button(action: commitImport) {
                Label("Choose audio files", systemImage: "folder")
                    .font(StudioType.control)
                    .foregroundStyle(Color.studioBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.studioGold, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("studio-import-tray-choose-audio")
        }
    }

    @MainActor
    private func start() async {
        guard !showContent else { return }
        showContent = true
        guard !reduceMotion else {
            isExpanded = true
            return
        }

        try? await Task.sleep(for: .milliseconds(45))
        withAnimation(.interpolatingSpring(duration: 0.35, bounce: 0, initialVelocity: 0)) {
            isExpanded = true
        }
    }

    private func close() {
        guard isPresented else { return }

        let animationDuration = reduceMotion ? 0.12 : 0.24
        withAnimation(reduceMotion ? .easeOut(duration: animationDuration) : .interpolatingSpring(duration: animationDuration, bounce: 0, initialVelocity: 0)) {
            isExpanded = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            showContent = false
            isPresented = false
        }
    }

    private func commitImport() {
        let animationDuration = reduceMotion ? 0.10 : 0.20
        withAnimation(reduceMotion ? .easeOut(duration: animationDuration) : .interpolatingSpring(duration: animationDuration, bounce: 0, initialVelocity: 0)) {
            isExpanded = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            showContent = false
            isPresented = false
            importAudio()
        }
    }
}

private struct StudioImportMeterField: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.black.opacity(0.30))
            .overlay {
                VStack(spacing: 7) {
                    meterLine(color: Color.white.opacity(0.055), height: 2, inset: 22)
                    meterLine(color: Color.white.opacity(0.075), height: 2, inset: 46)
                    meterLine(color: Color.studioGold.opacity(0.42), height: 3, inset: 26)
                    meterLine(color: Color.white.opacity(0.065), height: 2, inset: 34)
                    meterLine(color: Color.white.opacity(0.045), height: 2, inset: 58)
                }
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.studioGold.opacity(0.10),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 18)
                .blur(radius: 7)
                .padding(.horizontal, 18)
                .offset(y: -4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.075), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }

    private func meterLine(color: Color, height: CGFloat, inset: CGFloat) -> some View {
        Capsule()
            .fill(color)
            .frame(height: height)
            .padding(.horizontal, inset)
    }
}

private struct StudioImportFormatChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(StudioType.metadataSmall)
            .foregroundStyle(Color.studioMuted)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(Color.white.opacity(0.055), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            }
    }
}
