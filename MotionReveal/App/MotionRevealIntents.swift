import AppIntents
import Foundation

enum MotionRevealIntentNotification {
    static let togglePlayback = Notification.Name("MotionRevealIntentNotification.togglePlayback")
}

enum MotionRevealIntentDarwinBridge {
    static let togglePlaybackName = CFNotificationName(
        "com.jjuzzi.motionreveal.intent.togglePlayback" as CFString
    )

    static func postTogglePlayback() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            togglePlaybackName,
            nil,
            nil,
            true
        )
    }
}

final class MotionRevealIntentDarwinObserver: @unchecked Sendable {
    private let handler: @MainActor @Sendable () -> Void

    init(handler: @escaping @MainActor @Sendable () -> Void) {
        self.handler = handler
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            Self.handleNotification,
            MotionRevealIntentDarwinBridge.togglePlaybackName.rawValue,
            nil,
            .deliverImmediately
        )
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            MotionRevealIntentDarwinBridge.togglePlaybackName,
            nil
        )
    }

    private static let handleNotification: CFNotificationCallback = { _, observer, _, _, _ in
        guard let observer else { return }
        let retainedObserver = Unmanaged<MotionRevealIntentDarwinObserver>
            .fromOpaque(observer)
            .takeUnretainedValue()
        Task { @MainActor in
            retainedObserver.handler()
        }
    }
}

enum MotionRevealIntentRoute: String {
    case songContainer
    case togglePlayback
}

enum PendingAppIntentRouteStore {
    static let key = "motionReveal.pendingAppIntentRoute"

    static func request(_ route: MotionRevealIntentRoute, defaults: UserDefaults = .standard) {
        defaults.set(route.rawValue, forKey: key)
        defaults.synchronize()
    }

    static func consume(defaults: UserDefaults = .standard) -> MotionRevealIntentRoute? {
        guard let rawValue = defaults.string(forKey: key) else { return nil }

        defaults.removeObject(forKey: key)
        return MotionRevealIntentRoute(rawValue: rawValue)
    }

    @discardableResult
    static func consume(
        if expectedRoute: MotionRevealIntentRoute,
        defaults: UserDefaults = .standard
    ) -> MotionRevealIntentRoute? {
        guard let rawValue = defaults.string(forKey: key),
              let route = MotionRevealIntentRoute(rawValue: rawValue),
              route == expectedRoute else {
            return nil
        }

        defaults.removeObject(forKey: key)
        return route
    }
}

struct OpenSongContainerIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Song Container"
    static let description = IntentDescription(
        "Opens playda.te to the current song container."
    )
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        PendingAppIntentRouteStore.request(.songContainer)
        return .result()
    }
}

struct TogglePlaybackIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Toggle Playback"
    static let description = IntentDescription(
        "Toggles playback for the current playda.te song."
    )
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        PendingAppIntentRouteStore.request(.togglePlayback)
        MotionRevealIntentDarwinBridge.postTogglePlayback()
        NotificationCenter.default.post(name: MotionRevealIntentNotification.togglePlayback, object: nil)
        return .result()
    }
}

struct MotionRevealShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenSongContainerIntent(),
            phrases: [
                "Open song container in \(.applicationName)",
                "Show song container in \(.applicationName)"
            ],
            shortTitle: "Song Container",
            systemImageName: "tray.and.arrow.down.fill"
        )
    }
}
