import RiveRuntime

enum RiveRuntimeSupport {
    static func configureForProcess() {
#if DEBUG
        RiveLog.logger = RiveLog.system(levels: .default)
#else
        RiveLog.logger = RiveLog.none
#endif
    }
}

actor RiveWorkerProvider {
    static let shared = RiveWorkerProvider()

    @MainActor
    private var cachedWorker: Worker?

    @MainActor
    func worker() async throws -> Worker {
        if let cachedWorker {
            return cachedWorker
        }

        let worker = try await Worker()
        cachedWorker = worker
        return worker
    }
}
