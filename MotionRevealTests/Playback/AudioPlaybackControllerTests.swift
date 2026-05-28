import AVFoundation
import XCTest
@testable import MotionReveal

@MainActor
final class AudioPlaybackControllerTests: XCTestCase {
    func testInterruptionResumesOnlyWhenPlaybackWasActiveBeforeInterruption() {
        let player = FakeAudioPlaybackEngine(isPlaying: false)
        var activationCount = 0
        let controller = AudioPlaybackController(
            player: player,
            observesAudioSession: false,
            reactivateAudioSession: { activationCount += 1 }
        )

        controller.handleInterruption(
            typeValue: AVAudioSession.InterruptionType.began.rawValue,
            optionsValue: nil
        )
        controller.handleInterruption(
            typeValue: AVAudioSession.InterruptionType.ended.rawValue,
            optionsValue: AVAudioSession.InterruptionOptions.shouldResume.rawValue
        )

        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.pauseCallCount, 1)
        XCTAssertEqual(player.playCallCount, 0)
        XCTAssertEqual(activationCount, 0)
    }

    func testInterruptionResumesPlaybackWhenSystemSaysItShouldResume() {
        let player = FakeAudioPlaybackEngine(isPlaying: true)
        var activationCount = 0
        let controller = AudioPlaybackController(
            player: player,
            observesAudioSession: false,
            reactivateAudioSession: { activationCount += 1 }
        )

        controller.handleInterruption(
            typeValue: AVAudioSession.InterruptionType.began.rawValue,
            optionsValue: nil
        )
        XCTAssertFalse(player.isPlaying)

        controller.handleInterruption(
            typeValue: AVAudioSession.InterruptionType.ended.rawValue,
            optionsValue: AVAudioSession.InterruptionOptions.shouldResume.rawValue
        )

        XCTAssertTrue(player.isPlaying)
        XCTAssertEqual(player.pauseCallCount, 1)
        XCTAssertEqual(player.playCallCount, 1)
        XCTAssertEqual(activationCount, 1)
    }

    func testInterruptionDoesNotResumeWhenAudioSessionReactivationFails() {
        let player = FakeAudioPlaybackEngine(isPlaying: true)
        let controller = AudioPlaybackController(
            player: player,
            observesAudioSession: false,
            reactivateAudioSession: { throw CocoaError(.fileReadNoSuchFile) }
        )

        controller.handleInterruption(
            typeValue: AVAudioSession.InterruptionType.began.rawValue,
            optionsValue: nil
        )
        controller.handleInterruption(
            typeValue: AVAudioSession.InterruptionType.ended.rawValue,
            optionsValue: AVAudioSession.InterruptionOptions.shouldResume.rawValue
        )

        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.pauseCallCount, 1)
        XCTAssertEqual(player.playCallCount, 0)
    }

    func testInterruptionDoesNotResumeWithoutSystemResumeOption() {
        let player = FakeAudioPlaybackEngine(isPlaying: true)
        var activationCount = 0
        let controller = AudioPlaybackController(
            player: player,
            observesAudioSession: false,
            reactivateAudioSession: { activationCount += 1 }
        )

        controller.handleInterruption(
            typeValue: AVAudioSession.InterruptionType.began.rawValue,
            optionsValue: nil
        )
        controller.handleInterruption(
            typeValue: AVAudioSession.InterruptionType.ended.rawValue,
            optionsValue: AVAudioSession.InterruptionOptions().rawValue
        )

        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.pauseCallCount, 1)
        XCTAssertEqual(player.playCallCount, 0)
        XCTAssertEqual(activationCount, 0)
    }

    func testRouteLossPausesPlaybackAndPreventsLaterInterruptionResume() {
        let player = FakeAudioPlaybackEngine(isPlaying: true)
        let controller = AudioPlaybackController(player: player, observesAudioSession: false)

        controller.handleInterruption(
            typeValue: AVAudioSession.InterruptionType.began.rawValue,
            optionsValue: nil
        )
        controller.handleRouteChange(reasonValue: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue)
        controller.handleInterruption(
            typeValue: AVAudioSession.InterruptionType.ended.rawValue,
            optionsValue: AVAudioSession.InterruptionOptions.shouldResume.rawValue
        )

        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.pauseCallCount, 2)
        XCTAssertEqual(player.playCallCount, 0)
    }

    func testSilentSeekMovesPlayerWithoutChangingPlaybackState() {
        let player = FakeAudioPlaybackEngine(isPlaying: true, duration: 200)
        let controller = AudioPlaybackController(player: player, observesAudioSession: false)

        XCTAssertTrue(controller.seekSilently(toFraction: 0.25))

        XCTAssertEqual(player.currentTime, 50)
        XCTAssertTrue(player.isPlaying)
        XCTAssertEqual(player.playCallCount, 0)
        XCTAssertEqual(player.pauseCallCount, 0)
    }

    func testSilentSeekReturnsFalseWithoutPlayer() {
        let controller = AudioPlaybackController(player: nil, observesAudioSession: false)

        XCTAssertFalse(controller.seekSilently(toFraction: 0.25))
    }

    func testAudioSessionNotificationsHopBackToMainActor() async {
        let notificationCenter = NotificationCenter()
        let player = FakeAudioPlaybackEngine(isPlaying: true)
        var activationCount = 0
        let controller = AudioPlaybackController(
            player: player,
            observesAudioSession: true,
            notificationCenter: notificationCenter,
            reactivateAudioSession: { activationCount += 1 }
        )
        XCTAssertNotNil(controller.snapshot())

        notificationCenter.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )
        await waitForMainActorNotificationDelivery()
        XCTAssertFalse(player.isPlaying)

        notificationCenter.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
            ]
        )
        await waitForMainActorNotificationDelivery()

        XCTAssertTrue(player.isPlaying)
        XCTAssertEqual(player.pauseCallCount, 1)
        XCTAssertEqual(player.playCallCount, 1)
        XCTAssertEqual(activationCount, 1)
    }

    func testDeinitRemovesObserversFromInjectedNotificationCenter() {
        let notificationCenter = TrackingNotificationCenter()
        var controller: AudioPlaybackController? = AudioPlaybackController(
            player: FakeAudioPlaybackEngine(isPlaying: false),
            observesAudioSession: true,
            notificationCenter: notificationCenter
        )

        XCTAssertNotNil(controller?.snapshot())
        XCTAssertEqual(notificationCenter.removeObserverCallCount, 0)

        controller = nil

        XCTAssertEqual(notificationCenter.removeObserverCallCount, 1)
    }

    private func waitForMainActorNotificationDelivery() async {
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(20))
    }
}

@MainActor
private final class FakeAudioPlaybackEngine: AudioPlaybackEngine {
    var currentTime: TimeInterval = 0
    let duration: TimeInterval
    private(set) var isPlaying: Bool
    private(set) var playCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var prepareCallCount = 0

    init(isPlaying: Bool, duration: TimeInterval = 120) {
        self.isPlaying = isPlaying
        self.duration = duration
    }

    func prepareToPlay() -> Bool {
        prepareCallCount += 1
        return true
    }

    func play() -> Bool {
        playCallCount += 1
        isPlaying = true
        return true
    }

    func pause() {
        pauseCallCount += 1
        isPlaying = false
    }

    func stop() {
        stopCallCount += 1
        isPlaying = false
    }
}

private final class TrackingNotificationCenter: NotificationCenter, @unchecked Sendable {
    private(set) var removeObserverCallCount = 0

    override func removeObserver(_ observer: Any) {
        removeObserverCallCount += 1
        super.removeObserver(observer)
    }
}
