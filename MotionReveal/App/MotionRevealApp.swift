import SwiftUI

@main
struct MotionRevealApp: App {
    init() {
        RiveRuntimeSupport.configureForProcess()
#if DEBUG
        DebugLaunchStateReset.runIfNeeded()
        DebugSwiftBootstrap.configureIfRequested()
#endif
    }

    var body: some Scene {
        WindowGroup {
            MusicWorkspaceView()
        }
    }
}
