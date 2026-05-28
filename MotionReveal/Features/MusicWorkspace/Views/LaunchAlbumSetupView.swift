import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct LaunchAlbumSetupResult {
    let title: String
    let coverURL: URL?
}

struct LaunchAlbumSetupView: View {
    let finish: (LaunchAlbumSetupResult) -> Void

    @State private var title = ""
    @State private var isCoverPickerPresented = false
    @State private var selectedCoverURL: URL?
    @State private var coverImage: UIImage?
    @State private var coverIsVideo = false
    @FocusState private var isTitleFocused: Bool

    private var canContinue: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color.studioBackground
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 28)

                Button {
                    isCoverPickerPresented = true
                } label: {
                    LaunchAlbumCoverPreview(coverImage: coverImage, isVideo: coverIsVideo)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choose album cover")
                .fileImporter(
                    isPresented: $isCoverPickerPresented,
                    allowedContentTypes: WorkspaceImportContentPolicy.projectCoverPickerTypes,
                    allowsMultipleSelection: false
                ) { result in
                    handleCoverImport(result)
                }

                VStack(spacing: 10) {
                    Text("Name the album")
                        .font(StudioType.deckTitle)
                        .foregroundStyle(Color.studioText)

                    TextField("Album name", text: $title)
                        .font(StudioType.deckTitle)
                        .foregroundStyle(Color.studioText)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($isTitleFocused)
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        }
                        .onSubmit(continueSetup)
                }

                Button(action: continueSetup) {
                    Text("Create album")
                        .font(StudioType.control)
                        .foregroundStyle(Color.studioBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background {
                            StudioPrimaryButtonBackground(isEnabled: canContinue)
                        }
                }
                .buttonStyle(.plain)
                .disabled(!canContinue)
                .accessibilityIdentifier("finish-launch-album-setup")

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 28)
        }
        .accessibilityIdentifier("launch-album-setup")
    }

    private func continueSetup() {
        guard canContinue else { return }
        finish(
            LaunchAlbumSetupResult(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                coverURL: selectedCoverURL
            )
        )
    }

    private func handleCoverImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task {
                await loadCover(from: url)
            }
        case .failure:
            return
        }
    }

    private func loadCover(from url: URL) async {
        selectedCoverURL = url

        let type = UTType(filenameExtension: url.pathExtension)
        let isVideo = type?.conforms(to: .movie) == true
            || type?.conforms(to: .mpeg4Movie) == true
            || type?.conforms(to: .quickTimeMovie) == true

        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let previewImage: UIImage?
        if isVideo {
            previewImage = await Self.videoThumbnail(from: url)
        } else {
            previewImage = UIImage(contentsOfFile: url.path)
        }

        guard !Task.isCancelled else { return }

        coverIsVideo = isVideo
        coverImage = previewImage
    }

    private static func videoThumbnail(from url: URL) async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let asset = AVURLAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 1024, height: 1024)

                do {
                    let image = try generator.copyCGImage(at: .zero, actualTime: nil)
                    continuation.resume(returning: UIImage(cgImage: image))
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

private struct LaunchAlbumCoverPreview: View {
    let coverImage: UIImage?
    let isVideo: Bool

    var body: some View {
        ZStack {
            if let coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
            } else {
                SleeveArtworkView(artwork: .blank)
            }

            if isVideo {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "video.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .padding(8)
                            .background(.black.opacity(0.35), in: Circle())
                    }
                    Spacer()
                }
                .padding(12)
            }
        }
        .frame(width: 190, height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 24, x: 0, y: 14)
    }
}
