import Foundation

@MainActor
enum DebugSwiftBootstrap {
    static func configureIfRequested() {
        // DebugSwift was retired from the app target so development builds do not
        // package the local debugging bundle by default.
    }
}
