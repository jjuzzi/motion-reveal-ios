import CarPlay
import UIKit

@MainActor
final class MotionRevealCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, @preconcurrency CPNowPlayingTemplateObserver {
    private var interfaceController: CPInterfaceController?
    private var projects: [MusicProject] = []
    private var selectedProject: MusicProject?
    private var selectedTrackIndex: Int?
    private var playbackProgress: PlaybackProgress = .idle
    private var progressTimer: Timer?
    private let libraryStore = MusicLibraryStore()
    private let playbackController = AudioPlaybackController()

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        interfaceController.prefersDarkUserInterfaceStyle = true

        reloadProjects()
        configureNowPlayingTemplate()
        interfaceController.setRootTemplate(makeProjectListTemplate(), animated: true)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        progressTimer?.invalidate()
        progressTimer = nil
        self.interfaceController = nil
    }

    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        guard let selectedProject, let selectedTrackIndex else { return }
        interfaceController?.pushTemplate(makeTrackListTemplate(project: selectedProject, currentTrackIndex: selectedTrackIndex), animated: true)
    }

    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        guard let selectedProject else { return }
        interfaceController?.pushTemplate(makeTrackListTemplate(project: selectedProject, currentTrackIndex: selectedTrackIndex), animated: true)
    }
}

private extension MotionRevealCarPlaySceneDelegate {
    func reloadProjects() {
        projects = libraryStore
            .loadProjects()
            .filter { !$0.tracks.isEmpty }
    }

    func configureNowPlayingTemplate() {
        let template = CPNowPlayingTemplate.shared
        template.isUpNextButtonEnabled = true
        template.upNextTitle = "Tracks"
        template.isAlbumArtistButtonEnabled = true
        template.add(self)
        updateNowPlayingButtons()
    }

    func makeProjectListTemplate() -> CPListTemplate {
        reloadProjects()

        let items: [CPListItem]
        if projects.isEmpty {
            let empty = CPListItem(
                text: "No playable projects",
                detailText: "Add tracks in playda.te first.",
                image: NowPlayingInfoPublisher.defaultArtworkImage(size: CPListItem.maximumImageSize)
            )
            empty.isEnabled = false
            items = [empty]
        } else {
            items = projects.map { project in
                let item = CPListItem(
                    text: project.title,
                    detailText: project.metadata,
                    image: NowPlayingInfoPublisher.artworkImage(
                        for: project,
                        track: project.tracks.first,
                        libraryStore: libraryStore,
                        targetSize: CPListItem.maximumImageSize
                    ),
                    accessoryImage: nil,
                    accessoryType: .disclosureIndicator
                )
                item.handler = { [weak self] _, completion in
                    guard let self else {
                        completion()
                        return
                    }

                    let template = self.makeTrackListTemplate(project: project, currentTrackIndex: nil)
                    self.interfaceController?.pushTemplate(template, animated: true) { _, _ in
                        completion()
                    }
                }
                return item
            }
        }

        let section = CPListSection(items: items)
        return CPListTemplate(title: "playda.te", sections: [section])
    }

    func makeTrackListTemplate(project: MusicProject, currentTrackIndex: Int?) -> CPListTemplate {
        let items = project.tracks.enumerated().map { index, track in
            let item = CPListItem(
                text: track.title,
                detailText: track.metadataLine,
                image: NowPlayingInfoPublisher.artworkImage(
                    for: project,
                    track: track,
                    libraryStore: libraryStore,
                    targetSize: CPListItem.maximumImageSize
                )
            )
            item.isPlaying = selectedProject?.id == project.id && selectedTrackIndex == index && playbackProgress.isPlaying
            item.playingIndicatorLocation = .trailing
            item.handler = { [weak self] _, completion in
                guard let self else {
                    completion()
                    return
                }

                self.startPlayback(project: project, trackIndex: index)
                self.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true) { _, _ in
                    completion()
                }
            }
            return item
        }

        let section = CPListSection(items: items)
        return CPListTemplate(title: project.title, sections: [section])
    }

    func startPlayback(project: MusicProject, trackIndex: Int) {
        guard project.tracks.indices.contains(trackIndex) else { return }
        let track = project.tracks[trackIndex]

        do {
            if let progress = try playbackController.play(track: track, libraryStore: libraryStore) {
                selectedProject = project
                selectedTrackIndex = trackIndex
                playbackProgress = progress
                publishNowPlaying()
                updateNowPlayingButtons()
                startProgressTimer()
            }
        } catch {
            presentPlaybackError()
        }
    }

    func playPreviousTrack() {
        guard let selectedProject, let selectedTrackIndex else { return }
        let previousIndex = max(0, selectedTrackIndex - 1)

        if previousIndex == selectedTrackIndex {
            playbackProgress = playbackController.seek(toFraction: 0) ?? playbackProgress
            publishNowPlaying()
            return
        }

        startPlayback(project: selectedProject, trackIndex: previousIndex)
    }

    func playNextTrack() {
        guard let selectedProject, let selectedTrackIndex else { return }
        let nextIndex = min(selectedProject.tracks.count - 1, selectedTrackIndex + 1)
        guard nextIndex != selectedTrackIndex else { return }
        startPlayback(project: selectedProject, trackIndex: nextIndex)
    }

    func togglePlayback() {
        if selectedProject == nil {
            guard let firstProject = projects.first else { return }
            startPlayback(project: firstProject, trackIndex: 0)
            return
        }

        playbackProgress = playbackController.togglePlayback() ?? playbackProgress
        publishNowPlaying()
        updateNowPlayingButtons()

        if playbackProgress.isPlaying {
            startProgressTimer()
        } else {
            progressTimer?.invalidate()
            progressTimer = nil
        }
    }

    func updateNowPlayingButtons() {
        let canGoBack = selectedTrackIndex.map { $0 > 0 } ?? false
        let canGoForward = {
            guard let selectedProject, let selectedTrackIndex else { return false }
            return selectedTrackIndex < selectedProject.tracks.count - 1
        }()

        let previous = CPNowPlayingImageButton(image: symbolImage("backward.fill")) { [weak self] _ in
            self?.playPreviousTrack()
        }
        previous.isEnabled = selectedTrackIndex != nil
        previous.isSelected = canGoBack

        let playPause = CPNowPlayingImageButton(
            image: symbolImage(playbackProgress.isPlaying ? "pause.fill" : "play.fill")
        ) { [weak self] _ in
            self?.togglePlayback()
        }

        let next = CPNowPlayingImageButton(image: symbolImage("forward.fill")) { [weak self] _ in
            self?.playNextTrack()
        }
        next.isEnabled = canGoForward

        CPNowPlayingTemplate.shared.updateNowPlayingButtons([previous, playPause, next])
    }

    func publishNowPlaying() {
        guard let selectedProject,
              let selectedTrackIndex,
              selectedProject.tracks.indices.contains(selectedTrackIndex) else {
            return
        }

        playbackProgress = playbackController.snapshot() ?? playbackProgress
        NowPlayingInfoPublisher.publish(
            project: selectedProject,
            track: selectedProject.tracks[selectedTrackIndex],
            progress: playbackProgress,
            libraryStore: libraryStore
        )
    }

    func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.publishNowPlaying()
            }
        }
    }

    func presentPlaybackError() {
        let action = CPAlertAction(title: "OK", style: .default, handler: { _ in })
        let alert = CPAlertTemplate(titleVariants: ["Track unavailable"], actions: [action])
        interfaceController?.presentTemplate(alert, animated: true, completion: nil)
    }
}

private func symbolImage(_ systemName: String) -> UIImage {
    let configuration = UIImage.SymbolConfiguration(pointSize: 30, weight: .semibold)
    return UIImage(systemName: systemName, withConfiguration: configuration) ?? UIImage()
}

private extension CPInterfaceController {
    func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool) {
        setRootTemplate(rootTemplate, animated: animated, completion: nil)
    }

    func pushTemplate(_ templateToPush: CPTemplate, animated: Bool) {
        pushTemplate(templateToPush, animated: animated, completion: nil)
    }
}
