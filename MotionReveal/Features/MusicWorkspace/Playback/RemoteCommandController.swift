import Foundation
import MediaPlayer

final class RemoteCommandController {
    enum CommandResult: Equatable {
        case success
        case noActionableNowPlayingItem
        case noSuchContent
        case commandFailed

        var handlerStatus: MPRemoteCommandHandlerStatus {
            switch self {
            case .success:
                .success
            case .noActionableNowPlayingItem:
                .noActionableNowPlayingItem
            case .noSuchContent:
                .noSuchContent
            case .commandFailed:
                .commandFailed
            }
        }
    }

    enum PreviousCommandDecision: Equatable {
        case restartCurrentTrack
        case playPreviousTrack
        case noTrack
        case noPreviousTrack
    }

    struct Availability: Equatable {
        var canPlay: Bool
        var canPause: Bool
        var canTogglePlayback: Bool
        var canPlayPrevious: Bool
        var canPlayNext: Bool
        var canChangePlaybackPosition: Bool
        var canStop: Bool

        static let disabled = Availability(
            canPlay: false,
            canPause: false,
            canTogglePlayback: false,
            canPlayPrevious: false,
            canPlayNext: false,
            canChangePlaybackPosition: false,
            canStop: false
        )
    }

    struct Handlers {
        var play: () -> CommandResult
        var pause: () -> CommandResult
        var togglePlayback: () -> CommandResult
        var playNext: () -> CommandResult
        var playPrevious: () -> CommandResult
        var changePlaybackPosition: (TimeInterval) -> CommandResult
        var stop: () -> CommandResult

        static func inactive() -> Handlers {
            Handlers(
                play: { .commandFailed },
                pause: { .commandFailed },
                togglePlayback: { .commandFailed },
                playNext: { .commandFailed },
                playPrevious: { .commandFailed },
                changePlaybackPosition: { _ in .commandFailed },
                stop: { .commandFailed }
            )
        }
    }

    private let commandCenter: MPRemoteCommandCenter
    private var handlers = Handlers.inactive()
    private var registeredTargets = RegisteredTargets()
    private var isRegistered = false

    init(commandCenter: MPRemoteCommandCenter = .shared()) {
        self.commandCenter = commandCenter
    }

    func update(handlers: Handlers, availability: Availability) {
        self.handlers = handlers

        if !isRegistered {
            registerTargets()
        }

        applyAvailability(availability)
    }

    func disable() {
        handlers = .inactive()
        applyAvailability(.disabled)

        guard isRegistered else { return }

        registeredTargets.removeAll(from: commandCenter)
        registeredTargets = RegisteredTargets()
        isRegistered = false
    }

    static func previousCommandDecision(
        hasCurrentTrack: Bool,
        canPlayPreviousTrack: Bool,
        lastPreviousCommandDate: Date?,
        now: Date,
        doubleTapWindow: TimeInterval
    ) -> PreviousCommandDecision {
        guard hasCurrentTrack else {
            return .noTrack
        }

        guard let lastPreviousCommandDate,
              now.timeIntervalSince(lastPreviousCommandDate) <= doubleTapWindow else {
            return .restartCurrentTrack
        }

        return canPlayPreviousTrack ? .playPreviousTrack : .noPreviousTrack
    }
}

private extension RemoteCommandController {
    struct RegisteredTargets {
        var play: Any?
        var pause: Any?
        var togglePlayback: Any?
        var playNext: Any?
        var playPrevious: Any?
        var changePlaybackPosition: Any?
        var stop: Any?

        func removeAll(from commandCenter: MPRemoteCommandCenter) {
            commandCenter.playCommand.removeTarget(play)
            commandCenter.pauseCommand.removeTarget(pause)
            commandCenter.togglePlayPauseCommand.removeTarget(togglePlayback)
            commandCenter.nextTrackCommand.removeTarget(playNext)
            commandCenter.previousTrackCommand.removeTarget(playPrevious)
            commandCenter.changePlaybackPositionCommand.removeTarget(changePlaybackPosition)
            commandCenter.stopCommand.removeTarget(stop)
        }
    }

    func registerTargets() {
        registeredTargets.play = commandCenter.playCommand.addTarget { [weak self] _ in
            Self.runOnMain {
                guard let self else { return .commandFailed }
                return self.handlers.play().handlerStatus
            }
        }
        registeredTargets.pause = commandCenter.pauseCommand.addTarget { [weak self] _ in
            Self.runOnMain {
                guard let self else { return .commandFailed }
                return self.handlers.pause().handlerStatus
            }
        }
        registeredTargets.togglePlayback = commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Self.runOnMain {
                guard let self else { return .commandFailed }
                return self.handlers.togglePlayback().handlerStatus
            }
        }
        registeredTargets.playNext = commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Self.runOnMain {
                guard let self else { return .commandFailed }
                return self.handlers.playNext().handlerStatus
            }
        }
        registeredTargets.playPrevious = commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Self.runOnMain {
                guard let self else { return .commandFailed }
                return self.handlers.playPrevious().handlerStatus
            }
        }
        registeredTargets.changePlaybackPosition = commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            Self.runOnMain {
                guard let self,
                      let event = event as? MPChangePlaybackPositionCommandEvent else {
                    return .commandFailed
                }

                return self.handlers.changePlaybackPosition(event.positionTime).handlerStatus
            }
        }
        registeredTargets.stop = commandCenter.stopCommand.addTarget { [weak self] _ in
            Self.runOnMain {
                guard let self else { return .commandFailed }
                return self.handlers.stop().handlerStatus
            }
        }
        isRegistered = true
    }

    func applyAvailability(_ availability: Availability) {
        commandCenter.playCommand.isEnabled = availability.canPlay
        commandCenter.pauseCommand.isEnabled = availability.canPause
        commandCenter.togglePlayPauseCommand.isEnabled = availability.canTogglePlayback
        commandCenter.previousTrackCommand.isEnabled = availability.canPlayPrevious
        commandCenter.nextTrackCommand.isEnabled = availability.canPlayNext
        commandCenter.changePlaybackPositionCommand.isEnabled = availability.canChangePlaybackPosition
        commandCenter.stopCommand.isEnabled = availability.canStop
    }

    static func runOnMain(_ work: @escaping () -> MPRemoteCommandHandlerStatus) -> MPRemoteCommandHandlerStatus {
        if Thread.isMainThread {
            return work()
        }

        return DispatchQueue.main.sync(execute: work)
    }
}
