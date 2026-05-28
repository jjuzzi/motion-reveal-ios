import Foundation

#if DEBUG
enum DebugLaunchStateReset {
    static let resetArgument = "--reset-ui-test-state"
    static let seedSongContainerArgument = "--seed-ui-test-song-container"
    static let seedFilesImportProjectArgument = "--seed-ui-test-files-import-project"
    static let pendingSongContainerIntentArgument = "--pending-ui-test-song-container-intent"
    static let autoCreateDiscPromptArgument = "--auto-create-disc-prompt"
    static let autoCreateDiscRitualArgument = "--auto-create-disc-ritual"
    static let forceFullMotionRitualsArgument = "--force-full-motion-rituals"
    static let simulateFailedAudioImportArgument = "--simulate-ui-test-failed-audio-import"
    static let simulatePickerFailureArgument = "--simulate-ui-test-picker-failure"
    static let simulateAttachmentPickerFailureArgument = "--simulate-ui-test-attachment-picker-failure"
    static let forceFullMotionRitualsKey = "forceFullMotionRitualsForUITest"

    static func runIfNeeded(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        defaults: UserDefaults = .standard,
        fileManager: FileManager = .default
    ) {
        guard arguments.contains(resetArgument)
            || arguments.contains(seedSongContainerArgument)
            || arguments.contains(seedFilesImportProjectArgument)
            || arguments.contains(pendingSongContainerIntentArgument)
            || arguments.contains(autoCreateDiscPromptArgument)
            || arguments.contains(autoCreateDiscRitualArgument)
            || arguments.contains(forceFullMotionRitualsArgument)
            || arguments.contains(simulateFailedAudioImportArgument)
            || arguments.contains(simulatePickerFailureArgument)
            || arguments.contains(simulateAttachmentPickerFailureArgument)
        else { return }

        defaults.removeObject(forKey: "studioOnboardingVersion")
        defaults.removeObject(forKey: PendingAppIntentRouteStore.key)
        defaults.set(arguments.contains(forceFullMotionRitualsArgument), forKey: forceFullMotionRitualsKey)

        guard let documentsURL = try? fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            return
        }

        ["Library", "ImportedAudio", "SongAttachments", "AnimatedArtwork", "TextExports"].forEach { component in
            let url = documentsURL.appending(path: component, directoryHint: .isDirectory)
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
        }

        if arguments.contains(autoCreateDiscPromptArgument)
            || arguments.contains(autoCreateDiscRitualArgument)
            || arguments.contains(simulateFailedAudioImportArgument)
            || arguments.contains(simulatePickerFailureArgument)
            || arguments.contains(simulateAttachmentPickerFailureArgument) {
            defaults.set(Int.max, forKey: "studioOnboardingVersion")
        }

        if arguments.contains(seedSongContainerArgument) {
            defaults.set(Int.max, forKey: "studioOnboardingVersion")
            seedSongContainerLibrary(in: documentsURL, fileManager: fileManager)
        } else if arguments.contains(seedFilesImportProjectArgument) {
            defaults.set(Int.max, forKey: "studioOnboardingVersion")
            seedFilesImportLibrary(in: documentsURL, fileManager: fileManager)
        }

        if arguments.contains(pendingSongContainerIntentArgument) {
            defaults.set(Int.max, forKey: "studioOnboardingVersion")
            PendingAppIntentRouteStore.request(.songContainer, defaults: defaults)
        }
    }

    private static func seedSongContainerLibrary(in documentsURL: URL, fileManager: FileManager) {
        let track = MusicTrack(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            title: "UI test bounce",
            date: "Device QA",
            duration: "1:12",
            attachments: [
                SongAttachment(
                    id: UUID(uuidString: "22222222-3333-4444-5555-666666666666")!,
                    kind: "WAV",
                    name: "rough bounce.wav",
                    category: "Audio",
                    subtitle: "Seeded UI test file",
                    size: "12 MB",
                    localFileName: "ui-test-rough-bounce.wav"
                )
            ],
            markers: [
                WaveformMarker(
                    id: UUID(uuidString: "33333333-4444-5555-6666-777777777777")!,
                    position: 0.42,
                    height: 0.62,
                    colorToken: .gold,
                    time: "0:30",
                    note: ""
                )
            ]
        )

        let project = MusicProject(
            id: UUID(uuidString: "44444444-5555-6666-7777-888888888888")!,
            title: "UI Test Project",
            creator: "Device QA",
            trackCount: 1,
            runtime: "1:12",
            sleeve: .blank,
            state: .regular,
            tracks: [track]
        )

        do {
            let libraryDirectory = documentsURL.appending(path: "Library", directoryHint: .isDirectory)
            try fileManager.createDirectory(at: libraryDirectory, withIntermediateDirectories: true)
            let data = try JSONEncoder.debugPrettySorted.encode([project])
            try data.write(to: libraryDirectory.appending(path: "projects.json"), options: [.atomic])
        } catch {
#if DEBUG
            print("UI test seed failed: \(error.localizedDescription)")
#endif
        }
    }

    private static func seedFilesImportLibrary(in documentsURL: URL, fileManager: FileManager) {
        let project = MusicProject(
            id: UUID(uuidString: "55555555-6666-7777-8888-999999999999")!,
            title: "Files Import Test",
            creator: "Device QA",
            trackCount: 0,
            runtime: "",
            sleeve: .blank,
            state: .regular,
            tracks: []
        )

        do {
            let libraryDirectory = documentsURL.appending(path: "Library", directoryHint: .isDirectory)
            try fileManager.createDirectory(at: libraryDirectory, withIntermediateDirectories: true)
            let data = try JSONEncoder.debugPrettySorted.encode([project])
            try data.write(to: libraryDirectory.appending(path: "projects.json"), options: [.atomic])
        } catch {
#if DEBUG
            print("UI test import seed failed: \(error.localizedDescription)")
#endif
        }
    }
}

private extension JSONEncoder {
    static var debugPrettySorted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
#endif
