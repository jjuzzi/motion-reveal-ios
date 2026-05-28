import Foundation
import OSLog

struct WorkspaceImportSelection: Equatable, Sendable {
    let urls: [URL]
    private let securityScopedURLs: [URL]

    init(urls: [URL]) {
        self.urls = urls
        securityScopedURLs = urls.filter { $0.startAccessingSecurityScopedResource() }
    }

    var securityScopedURLCount: Int {
        securityScopedURLs.count
    }

    func stopAccessing() {
        securityScopedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
    }
}

enum WorkspaceImportDiagnostics {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.jjuzzi.motionreveal",
        category: "Import"
    )

    static func pickerCompleted(kind: WorkspaceImportKind, urlCount: Int, securityScopedURLCount: Int) {
        logger.info(
            "Files picker completed kind=\(kind.diagnosticName, privacy: .public) urls=\(urlCount, privacy: .public) securityScoped=\(securityScopedURLCount, privacy: .public)"
        )
    }

    static func pickerFailed(kind: WorkspaceImportKind, error: Error) {
        logger.error(
            "Files picker failed kind=\(kind.diagnosticName, privacy: .public) error=\(error.localizedDescription, privacy: .public)"
        )
    }

    static func emptySelection(kind: WorkspaceImportKind) {
        logger.warning("Files picker returned empty selection kind=\(kind.diagnosticName, privacy: .public)")
    }

    static func copyStarted(fileName: String, securityScopeGranted: Bool) {
        logger.info(
            "Import copy started file=\(fileName, privacy: .private) securityScopeGranted=\(securityScopeGranted, privacy: .public)"
        )
    }

    static func copySucceeded(fileName: String) {
        logger.info("Import copy succeeded file=\(fileName, privacy: .private)")
    }

    static func copyFailed(fileName: String, error: Error) {
        logger.error(
            "Import copy failed file=\(fileName, privacy: .private) error=\(error.localizedDescription, privacy: .public)"
        )
    }

    static func statusDisplayed(_ status: WorkspaceImportStatus) {
        logger.info("Import status displayed \(status.diagnosticSummary, privacy: .public)")
    }
}

private extension WorkspaceImportKind {
    var diagnosticName: String {
        switch self {
        case .audio:
            return "audio"
        case .animatedArtwork:
            return "animatedArtwork"
        case .projectCover:
            return "projectCover"
        case .attachment:
            return "attachment"
        }
    }
}

private extension WorkspaceImportStatus {
    var diagnosticSummary: String {
        switch self {
        case .importing(let kind, let total):
            return "outcome=importing kind=\(kind.diagnosticName) total=\(total)"
        case .success(let kind, let imported, let failedFileNames, let skippedDuplicates):
            return "outcome=success kind=\(kind.diagnosticName) imported=\(imported) failed=\(failedFileNames.count) duplicates=\(skippedDuplicates)"
        case .failure(let kind, let failedFileNames):
            return "outcome=failure kind=\(kind.diagnosticName) failed=\(failedFileNames.count)"
        case .pickerFailure(let kind, let reason):
            return "outcome=pickerFailure kind=\(kind.diagnosticName) reason=\(reason)"
        }
    }
}
