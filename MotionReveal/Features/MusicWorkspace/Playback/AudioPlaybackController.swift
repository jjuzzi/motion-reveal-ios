import AVFoundation
import Foundation

@MainActor
protocol AudioPlaybackEngine: AnyObject {
    var currentTime: TimeInterval { get set }
    var duration: TimeInterval { get }
    var isPlaying: Bool { get }

    @discardableResult
    func prepareToPlay() -> Bool

    @discardableResult
    func play() -> Bool

    func pause()
    func stop()
}

extension AVAudioPlayer: AudioPlaybackEngine {}

@MainActor
final class AudioPlaybackController: NSObject {
    private var player: (any AudioPlaybackEngine)?
    private var resumeAfterInterruption = false
    private let notificationCenter: NotificationCenter
    private let makePlayer: (URL) throws -> any AudioPlaybackEngine
    private let configureAudioSessionForPlayback: @MainActor () throws -> Void
    private let reactivateAudioSession: @MainActor () throws -> Void
    private let deactivateAudioSession: @MainActor () -> Void

    init(
        player: (any AudioPlaybackEngine)? = nil,
        observesAudioSession: Bool = true,
        notificationCenter: NotificationCenter = .default,
        makePlayer: @escaping (URL) throws -> any AudioPlaybackEngine = { try AVAudioPlayer(contentsOf: $0) },
        configureAudioSessionForPlayback: @escaping @MainActor () throws -> Void = AudioPlaybackController.activatePlaybackSession,
        reactivateAudioSession: @escaping @MainActor () throws -> Void = AudioPlaybackController.reactivateSession,
        deactivateAudioSession: @escaping @MainActor () -> Void = AudioPlaybackController.deactivateSession
    ) {
        self.player = player
        self.notificationCenter = notificationCenter
        self.makePlayer = makePlayer
        self.configureAudioSessionForPlayback = configureAudioSessionForPlayback
        self.reactivateAudioSession = reactivateAudioSession
        self.deactivateAudioSession = deactivateAudioSession
        super.init()

        if observesAudioSession {
            observeAudioSession()
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func play(track: MusicTrack, libraryStore: MusicLibraryStore) throws -> PlaybackProgress? {
        guard let url = libraryStore.audioURL(for: track) else {
            if track.localFileName != nil {
                throw CocoaError(.fileNoSuchFile)
            }

            player?.stop()
            player = nil
            return nil
        }

#if os(iOS)
        try configureAudioSessionForPlayback()
#endif

        let audioPlayer = try makePlayer(url)
        _ = audioPlayer.prepareToPlay()
        _ = audioPlayer.play()
        player = audioPlayer
        return snapshot()
    }

    func togglePlayback() -> PlaybackProgress? {
        guard let player else { return nil }

        if player.isPlaying {
            player.pause()
        } else {
            _ = player.play()
        }

        return snapshot()
    }

    func seek(toFraction fraction: Double) -> PlaybackProgress? {
        guard let player else { return nil }

        seek(player: player, toFraction: fraction)
        return snapshot()
    }

    @discardableResult
    func seekSilently(toFraction fraction: Double) -> Bool {
        guard let player else { return false }

        seek(player: player, toFraction: fraction)
        return true
    }

    func stop() {
        player?.stop()
        player = nil
        resumeAfterInterruption = false
#if os(iOS)
        deactivateAudioSession()
#endif
    }

    func snapshot() -> PlaybackProgress? {
        guard let player else { return nil }

        return PlaybackProgress.real(
            elapsed: player.currentTime,
            duration: player.duration,
            isPlaying: player.isPlaying
        )
    }

    private func seek(player: any AudioPlaybackEngine, toFraction fraction: Double) {
        let clampedFraction = min(max(fraction, 0), 1)
        player.currentTime = player.duration * clampedFraction
    }

    private func observeAudioSession() {
#if os(iOS)
        let session = AVAudioSession.sharedInstance()
        notificationCenter.addObserver(
            self,
            selector: #selector(handleInterruptionNotification(_:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleRouteChangeNotification(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: session
        )
#endif
    }

#if os(iOS)
    @objc nonisolated private func handleInterruptionNotification(_ notification: Notification) {
        let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
        let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt

        Task { @MainActor [weak self] in
            self?.handleInterruption(typeValue: typeValue, optionsValue: optionsValue)
        }
    }

    @objc nonisolated private func handleRouteChangeNotification(_ notification: Notification) {
        let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt

        Task { @MainActor [weak self] in
            self?.handleRouteChange(reasonValue: reasonValue)
        }
    }
#endif
}

#if os(iOS)
extension AudioPlaybackController {
    func handleInterruption(typeValue: UInt?, optionsValue: UInt?) {
        guard let typeValue,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            resumeAfterInterruption = player?.isPlaying == true
            player?.pause()
        case .ended:
            defer { resumeAfterInterruption = false }

            guard resumeAfterInterruption, let optionsValue else {
                return
            }

            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                do {
                    try reactivateAudioSession()
                } catch {
                    return
                }
                _ = player?.play()
            }
        @unknown default:
            resumeAfterInterruption = false
            player?.pause()
        }
    }

    func handleRouteChange(reasonValue: UInt?) {
        guard let reasonValue,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
              reason == .oldDeviceUnavailable else {
            return
        }

        resumeAfterInterruption = false
        player?.pause()
    }
}
#endif

private extension AudioPlaybackController {
    static func activatePlaybackSession() throws {
#if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
#endif
    }

    static func reactivateSession() throws {
#if os(iOS)
        try AVAudioSession.sharedInstance().setActive(true)
#endif
    }

    static func deactivateSession() {
#if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
#endif
    }
}
