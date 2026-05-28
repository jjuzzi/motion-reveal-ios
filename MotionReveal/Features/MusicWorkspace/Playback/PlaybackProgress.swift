import Foundation

struct PlaybackProgress: Equatable, Sendable {
    var elapsed: TimeInterval
    var duration: TimeInterval
    var isPlaying: Bool
    var isRealPlayback: Bool

    var fraction: Double {
        guard duration > 0 else { return 0 }
        return min(max(elapsed / duration, 0), 1)
    }

    var elapsedLabel: String {
        Self.timeLabel(for: elapsed)
    }

    var durationLabel: String {
        Self.timeLabel(for: duration)
    }

    func advanced(by interval: TimeInterval) -> PlaybackProgress {
        guard isPlaying else { return self }

        let nextElapsed = min(elapsed + interval, duration)
        return PlaybackProgress(
            elapsed: nextElapsed,
            duration: duration,
            isPlaying: nextElapsed < duration,
            isRealPlayback: isRealPlayback
        )
    }

    func seek(toFraction fraction: Double) -> PlaybackProgress {
        let clampedFraction = min(max(fraction, 0), 1)
        return PlaybackProgress(
            elapsed: duration * clampedFraction,
            duration: duration,
            isPlaying: isPlaying,
            isRealPlayback: isRealPlayback
        )
    }

    func timeLabel(atFraction fraction: Double) -> String {
        let clampedFraction = min(max(fraction, 0), 1)
        return Self.timeLabel(for: duration * clampedFraction)
    }

    func toggledPlayback() -> PlaybackProgress {
        guard elapsed < duration else {
            return PlaybackProgress(
                elapsed: 0,
                duration: duration,
                isPlaying: true,
                isRealPlayback: isRealPlayback
            )
        }

        return PlaybackProgress(
            elapsed: elapsed,
            duration: duration,
            isPlaying: !isPlaying,
            isRealPlayback: isRealPlayback
        )
    }

    static let idle = PlaybackProgress(
        elapsed: 0,
        duration: 168,
        isPlaying: false,
        isRealPlayback: false
    )

    static func preview(for track: MusicTrack) -> PlaybackProgress {
        PlaybackProgress(
            elapsed: 0,
            duration: durationSeconds(from: track.duration) ?? 168,
            isPlaying: true,
            isRealPlayback: false
        )
    }

    static func real(elapsed: TimeInterval, duration: TimeInterval, isPlaying: Bool) -> PlaybackProgress {
        PlaybackProgress(
            elapsed: elapsed,
            duration: max(duration, 1),
            isPlaying: isPlaying,
            isRealPlayback: true
        )
    }

    static func durationSeconds(from label: String) -> TimeInterval? {
        let parts = label.split(separator: ":").compactMap { TimeInterval($0) }
        guard parts.count == 2 else { return nil }
        return parts[0] * 60 + parts[1]
    }

    static func timeLabel(for seconds: TimeInterval) -> String {
        let clampedSeconds = max(0, Int(seconds.rounded(.down)))
        return "\(clampedSeconds / 60):\(String(format: "%02d", clampedSeconds % 60))"
    }
}
