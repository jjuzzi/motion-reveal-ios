import CoreMotion
import Foundation

struct StudioDeviceTilt: Equatable {
    static let zero = StudioDeviceTilt(pitchDegrees: 0, rollDegrees: 0)

    let pitchDegrees: Double
    let rollDegrees: Double

    init(pitchDegrees: Double, rollDegrees: Double) {
        self.pitchDegrees = pitchDegrees
        self.rollDegrees = rollDegrees
    }

    init(attitudePitch: Double, attitudeRoll: Double, reduceMotion: Bool) {
        guard !reduceMotion else {
            self = .zero
            return
        }

        pitchDegrees = Self.clamped(attitudePitch * 180 / .pi * 0.18)
        rollDegrees = Self.clamped(attitudeRoll * 180 / .pi * 0.18)
    }

    func scaled(faceVisibility: CGFloat, edgeProfile: CGFloat) -> StudioDeviceTilt {
        let visibility = min(max(Double(faceVisibility), 0), 1)
        let face = 1 - min(max(Double(edgeProfile), 0), 1)
        let amount = visibility * face

        return StudioDeviceTilt(
            pitchDegrees: pitchDegrees * amount,
            rollDegrees: rollDegrees * amount
        )
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, -7), 7)
    }
}

@MainActor
final class StudioDeviceTiltController: ObservableObject {
    @Published private(set) var tilt = StudioDeviceTilt.zero

    private let motionManager: CMMotionManager

    init(motionManager: CMMotionManager = CMMotionManager()) {
        self.motionManager = motionManager
    }

    func start(reduceMotion: Bool) {
        guard !reduceMotion, motionManager.isDeviceMotionAvailable else {
            stop()
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let attitude = motion?.attitude else { return }

            self.tilt = StudioDeviceTilt(
                attitudePitch: attitude.pitch,
                attitudeRoll: attitude.roll,
                reduceMotion: reduceMotion
            )
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        tilt = .zero
    }
}
