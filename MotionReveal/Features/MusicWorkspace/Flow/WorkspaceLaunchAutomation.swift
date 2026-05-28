import Foundation

#if DEBUG
struct WorkspaceLaunchAutomationPlan: Equatable {
    let autoLoadRitual: Bool
    let autoCreateDiscPrompt: Bool
    let autoCreateDiscRitual: Bool
    let forceFullMotionRituals: Bool
    let openSongContainer: Bool
    let openMarkersContainer: Bool
    let prepareSlotPull: Bool
    let simulateFilesImport: Bool
    let simulateFailedAudioImport: Bool
    let simulatePickerFailure: Bool
    let simulateAttachmentPickerFailure: Bool
    let suppressImporterPresentation: Bool

    var shouldRun: Bool {
        autoLoadRitual
            || autoCreateDiscPrompt
            || autoCreateDiscRitual
            || openSongContainer
            || openMarkersContainer
            || prepareSlotPull
            || simulateFilesImport
            || simulateFailedAudioImport
            || simulatePickerFailure
            || simulateAttachmentPickerFailure
    }

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        autoLoadRitual = arguments.contains("--auto-load-ritual")
        autoCreateDiscPrompt = arguments.contains("--auto-create-disc-prompt")
        autoCreateDiscRitual = arguments.contains("--auto-create-disc-ritual")
        forceFullMotionRituals = arguments.contains("--force-full-motion-rituals")
        openSongContainer = arguments.contains("--open-ui-test-song-container")
        openMarkersContainer = arguments.contains("--open-ui-test-song-container-markers")
        prepareSlotPull = arguments.contains("--prepare-ui-test-slot-pull")
        simulateFilesImport = arguments.contains("--simulate-ui-test-files-import")
        simulateFailedAudioImport = arguments.contains("--simulate-ui-test-failed-audio-import")
        simulatePickerFailure = arguments.contains("--simulate-ui-test-picker-failure")
        simulateAttachmentPickerFailure = arguments.contains("--simulate-ui-test-attachment-picker-failure")
        suppressImporterPresentation = arguments.contains("--suppress-ui-test-importer-presentation")
    }
}

enum WorkspaceUITestImportFixture {
    static func write(named fileName: String, contents: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appending(path: fileName, directoryHint: .notDirectory)

        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            try Data(contents.utf8).write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }

    static func missingAudioURL(named fileName: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: fileName, directoryHint: .notDirectory)

        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }

        return url
    }
}
#endif
