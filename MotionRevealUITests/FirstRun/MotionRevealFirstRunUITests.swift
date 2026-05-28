import XCTest

@MainActor
final class MotionRevealFirstRunUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        executionTimeAllowance = 90
    }

    @MainActor
    func testFreshInstallOnboardingCreatesFirstSleeveAndShowsImportAudio() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [DebugLaunchArgument.resetUIState]
        app.launch()

        XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 5))

        app.buttons["Start"].tap()

        XCTAssertTrue(app.element("empty-library-state").waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["old screenshot seed"].exists)

        app.buttons["Create first sleeve"].tap()

        XCTAssertTrue(app.element("created-album-cd-prompt").waitForExistence(timeout: 5))
        XCTAssertFalse(app.element("project-screen").waitForExistence(timeout: 1))
        XCTAssertFalse(app.buttons["Create first sleeve"].exists)
        XCTAssertFalse(app.element("toast").exists)
        XCTAssertFalse(app.element("import-status-overlay").exists)
        XCTAssertFalse(app.element("studio-onboarding").exists)

        app.element("created-album-cd-prompt").tap()

        XCTAssertFalse(app.element("project-screen").waitForExistence(timeout: 1))
        XCTAssertFalse(app.element("toast").exists)
        XCTAssertFalse(app.element("import-status-overlay").exists)
        XCTAssertFalse(app.element("studio-onboarding").exists)

        XCTAssertTrue(app.element("project-screen").waitForExistence(timeout: 8))
        XCTAssertTrue(app.element("empty-track-state").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Import audio"].exists)
    }

    @MainActor
    func testDebugAutoCreateDiscRitualReachesProjectScreen() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.autoCreateDiscRitual
        ]
        app.launch()

        XCTAssertTrue(app.element("project-screen").waitForExistence(timeout: 8))
        XCTAssertTrue(app.element("empty-track-state").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Import audio"].exists)
    }

    @MainActor
    func testCreatedAlbumDiscPromptIsTheOnlySurfaceUntilTapped() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.forceFullMotionRituals
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 5))
        app.buttons["Start"].tap()

        XCTAssertTrue(app.element("empty-library-state").waitForExistence(timeout: 5))
        app.buttons["Create first sleeve"].tap()

        XCTAssertTrue(app.element("created-album-disc-stage").waitForExistence(timeout: 5))
        XCTAssertTrue(app.element("created-album-cd-prompt").waitForExistence(timeout: 5))
        saveScreenEvidence(named: "motionreveal-cd-only-prompt", settleFor: 2)

        XCTAssertFalse(app.element("project-screen").exists)
        XCTAssertFalse(app.element("library-screen").exists)
        XCTAssertFalse(app.element("dynamic-slot").exists)
        XCTAssertFalse(app.buttons["Create first sleeve"].exists)
        XCTAssertFalse(app.buttons["Import audio"].exists)
        XCTAssertFalse(app.element("toast").exists)
        XCTAssertFalse(app.element("import-status-overlay").exists)
        XCTAssertFalse(app.element("studio-onboarding").exists)

        app.element("created-album-cd-prompt").tap()
        XCTAssertFalse(app.element("created-album-disc-stage").exists)
        XCTAssertFalse(app.element("created-album-cd-prompt").exists)
        XCTAssertFalse(app.element("project-screen").exists)
        XCTAssertFalse(app.element("library-screen").exists)
        XCTAssertFalse(app.element("dynamic-slot").exists)
        saveScreenEvidence(named: "motionreveal-cd-entering-notch", settleFor: 0.95)

        XCTAssertTrue(app.element("project-screen").waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Import audio"].exists)
        saveScreenEvidence(named: "motionreveal-cd-loaded-project", settleFor: 1.1)
    }

    @MainActor
    func testCreatedAlbumDiscPromptSupportsImmediateTapIntoNotch() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.autoCreateDiscPrompt,
            DebugLaunchArgument.forceFullMotionRituals
        ]
        app.launch()

        let discPrompt = app.element("created-album-cd-prompt")
        XCTAssertTrue(discPrompt.waitForExistence(timeout: 8))
        discPrompt.tap()

        XCTAssertFalse(app.element("created-album-disc-stage").exists)
        XCTAssertFalse(app.element("created-album-cd-prompt").exists)
        XCTAssertFalse(app.element("project-screen").exists)
        XCTAssertFalse(app.element("library-screen").exists)
        saveScreenEvidence(named: "motionreveal-cd-immediate-tap-entering-notch", settleFor: 0.45)

        XCTAssertTrue(app.element("project-screen").waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Import audio"].exists)
    }

    @MainActor
    func testSeededSongContainerRouteKeepsStudioDrawerHiddenUntilPull() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedSongContainer,
            DebugLaunchArgument.openSongContainer
        ]
        app.launch()

        XCTAssertTrue(app.element("song-container").waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["UI test bounce"].exists)
        XCTAssertFalse(app.staticTexts["Studio drawer"].waitForExistence(timeout: 1))

        revealStudioDrawerFromSlot(in: app)
        XCTAssertTrue(app.staticTexts["WAV"].exists)
    }

    @MainActor
    func testPendingAppIntentRouteKeepsStudioDrawerHiddenUntilPull() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedSongContainer,
            DebugLaunchArgument.pendingSongContainerIntent
        ]
        app.launch()

        assertSeededTrackContext(in: app)
        XCTAssertFalse(app.staticTexts["Studio drawer"].waitForExistence(timeout: 1))
        revealStudioDrawerFromSlot(in: app)
        assertStudioDrawerVisible(in: app)
    }

    @MainActor
    func testMiniPlayerKeepsTransportControlsAccessible() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedSongContainer,
            DebugLaunchArgument.prepareSlotPull
        ]
        app.launch()

        XCTAssertTrue(app.element("project-screen").waitForExistence(timeout: 8))
        app.buttons["Play UI test bounce, Device QA · 1:12"].tap()
        XCTAssertTrue(app.element("mini-player").waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Play"].exists || app.buttons["Pause"].exists)
        XCTAssertTrue(app.buttons["Restart or previous track"].exists)
        XCTAssertTrue(app.buttons["Next track"].exists)
        XCTAssertTrue(app.buttons["Open song container"].exists)
    }

    @MainActor
    func testMiniPlayerExpandsIntoFullScreenSongContainer() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedSongContainer,
            DebugLaunchArgument.prepareSlotPull
        ]
        app.launch()

        XCTAssertTrue(app.element("project-screen").waitForExistence(timeout: 8))
        app.buttons["Play UI test bounce, Device QA · 1:12"].tap()
        XCTAssertTrue(app.element("mini-player").waitForExistence(timeout: 5))

        app.buttons["Expand now playing"].tap()

        XCTAssertTrue(app.element("song-container").waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["UI test bounce"].exists)
        XCTAssertFalse(app.staticTexts["Studio drawer"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testSeededLibraryPersistsAfterRelaunch() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedSongContainer,
            DebugLaunchArgument.openSongContainer
        ]
        app.launch()

        assertSeededSongContainer(in: app)

        app.terminate()
        app.launchArguments = [DebugLaunchArgument.openSongContainer]
        app.launch()

        assertSeededSongContainer(in: app)
    }

    @MainActor
    func testSimulatedFilesImportAddsAudioAttachmentAndPersistsAfterRelaunch() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedFilesImportProject,
            DebugLaunchArgument.simulateFilesImport,
            DebugLaunchArgument.openSongContainer
        ]
        app.launch()

        assertImportedFilesSongContainer(in: app)

        app.terminate()
        app.launchArguments = [DebugLaunchArgument.openSongContainer]
        app.launch()

        assertImportedFilesSongContainer(in: app)
    }

    @MainActor
    func testSimulatedFilesImportShowsAudioFormatMetadataInProjectRow() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedFilesImportProject,
            DebugLaunchArgument.simulateFilesImport
        ]
        app.launch()

        XCTAssertTrue(app.element("project-screen").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Phone Bounce"].waitForExistence(timeout: 5))

        let metadataLine = app.staticTexts["track-metadata-line"].firstMatch
        XCTAssertTrue(metadataLine.waitForExistence(timeout: 5))
        XCTAssertTrue(
            metadataLine.label.contains("WAV"),
            "Expected imported audio metadata line to include source format, got: \(metadataLine.label)"
        )
    }

    @MainActor
    func testFailedAudioImportShowsVisibleRecoveryOverlay() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedFilesImportProject,
            DebugLaunchArgument.simulateFailedAudioImport
        ]
        app.launch()

        XCTAssertTrue(app.element("project-screen").waitForExistence(timeout: 10))

        let overlay = app.element("import-status-overlay")
        XCTAssertTrue(overlay.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Import failed"].exists)
        XCTAssertTrue(app.staticTexts["Could not copy Missing Phone Bounce.wav.\nIn Files, download the audio locally first, then try again."].exists)
        XCTAssertTrue(app.element("import-status-retry").exists)

        saveScreenEvidence(named: "motionreveal-failed-audio-import-recovery", settleFor: 1)
        XCTAssertTrue(overlay.exists, "Failure feedback should stay visible long enough to read.")
    }

    @MainActor
    func testFilesPickerProviderFailureShowsVisibleRecoveryOverlay() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedFilesImportProject,
            DebugLaunchArgument.simulatePickerFailure,
            DebugLaunchArgument.suppressImporterPresentation
        ]
        app.launch()

        XCTAssertTrue(app.element("project-screen").waitForExistence(timeout: 10))

        let overlay = app.element("import-status-overlay")
        XCTAssertTrue(overlay.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Files could not open"].exists)
        let providerMessage = NSPredicate(
            format: "label CONTAINS %@ AND label CONTAINS %@",
            "The selected item is not available.",
            "download the audio locally"
        )
        XCTAssertTrue(app.staticTexts.matching(providerMessage).firstMatch.exists)
        XCTAssertTrue(app.element("import-status-retry").exists)

        saveScreenEvidence(named: "motionreveal-picker-provider-failure-recovery", settleFor: 1)
        XCTAssertTrue(overlay.exists, "Picker failure feedback should stay visible long enough to read.")

        app.element("import-status-retry").tap()

        XCTAssertFalse(overlay.waitForExistence(timeout: 1))
        let retryRequest = app.element("debug-importer-requested")
        XCTAssertTrue(retryRequest.waitForExistence(timeout: 2))
        XCTAssertEqual(retryRequest.label, "Audio importer requested")
    }

    @MainActor
    func testFilesAttachmentPickerProviderFailureRetryRequestsAttachmentImporter() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedSongContainer,
            DebugLaunchArgument.simulateAttachmentPickerFailure,
            DebugLaunchArgument.suppressImporterPresentation
        ]
        app.launch()

        XCTAssertTrue(app.element("project-screen").waitForExistence(timeout: 12))

        let overlay = app.element("import-status-overlay")
        XCTAssertTrue(overlay.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Files could not open"].exists)
        let providerMessage = NSPredicate(
            format: "label CONTAINS %@ AND label CONTAINS %@",
            "The selected attachment is not available.",
            "download the file locally"
        )
        XCTAssertTrue(app.staticTexts.matching(providerMessage).firstMatch.exists)
        XCTAssertTrue(app.element("import-status-retry").exists)

        app.element("import-status-retry").tap()

        XCTAssertFalse(overlay.waitForExistence(timeout: 1))
        let retryRequest = app.element("debug-importer-requested")
        XCTAssertTrue(retryRequest.waitForExistence(timeout: 2))
        XCTAssertEqual(retryRequest.label, "Attachment importer requested")
    }

    @MainActor
    func testMarkerCanBeAddedEditedAndPersistsAfterRelaunch() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedSongContainer,
            DebugLaunchArgument.openSongContainerMarkers
        ]
        app.launch()

        assertSeededTrackContext(in: app)
        revealMarkerControls(in: app)

        app.buttons["Add marker at playhead"].tap()
        XCTAssertTrue(app.element("marker-sheet").waitForExistence(timeout: 5))
        let noteField = app.element("marker-note-field")
        XCTAssertTrue(noteField.waitForExistence(timeout: 5))
        noteField.tap()
        noteField.typeText("tighten marker pocket")
        app.buttons["Save"].tap()
        waitForElementToDisappear(app.element("marker-sheet"), timeout: 3)

        assertMarkerNote("tighten marker pocket", in: app)

        app.terminate()
        app.launchArguments = [DebugLaunchArgument.openSongContainerMarkers]
        app.launch()

        revealMarkerControls(in: app)
        assertMarkerNote("tighten marker pocket", in: app)
        app.terminate()
    }

    @MainActor
    func testLongPressWaveformCreatesTappableAddNoteBubble() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedSongContainer,
            DebugLaunchArgument.openSongContainerMarkers
        ]
        app.launch()

        assertSeededTrackContext(in: app)

        let waveform = app.element("waveform-panel")
        XCTAssertTrue(waveform.waitForExistence(timeout: 5))
        waveform.press(forDuration: 0.65)

        let addNoteBubble = app.buttons["marker-note-popover"]
        XCTAssertTrue(addNoteBubble.waitForExistence(timeout: 3))
        XCTAssertFalse(app.element("marker-sheet").exists)

        addNoteBubble.tap()

        XCTAssertTrue(app.element("marker-sheet").waitForExistence(timeout: 5))
        let noteField = app.element("marker-note-field")
        XCTAssertTrue(noteField.waitForExistence(timeout: 5))
        noteField.tap()
        noteField.typeText("tap bubble note")
        app.buttons["Save"].tap()
        waitForElementToDisappear(app.element("marker-sheet"), timeout: 3)
        XCTAssertFalse(addNoteBubble.waitForExistence(timeout: 1))
        assertElementStaysGone(app.element("marker-sheet"), duration: 1.2)
        assertElementStaysGone(addNoteBubble, duration: 1.2)

        revealMarkerControls(in: app)
        assertMarkerNote("tap bubble note", in: app)
    }

    @MainActor
    func testTopSlotPullOpensSongContainerAndStudioDrawer() {
        continueAfterFailure = false

        let app = XCUIApplication()
        defer { app.terminate() }
        app.launchArguments = [
            DebugLaunchArgument.resetUIState,
            DebugLaunchArgument.seedSongContainer,
            DebugLaunchArgument.prepareSlotPull
        ]
        app.launch()

        XCTAssertTrue(app.element("project-screen").waitForExistence(timeout: 8))
        let slot = app.element("dynamic-slot")
        XCTAssertTrue(slot.waitForExistence(timeout: 5))

        slot.tap()
        XCTAssertFalse(app.element("song-container").waitForExistence(timeout: 1))

        revealStudioDrawerFromSlot(in: app)
        XCTAssertTrue(app.element("song-container").waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["UI test bounce"].exists)
        assertStudioDrawerVisible(in: app)
        XCTAssertTrue(app.staticTexts["WAV"].exists)
    }

    private func assertSeededSongContainer(in app: XCUIApplication) {
        assertSeededTrackContext(in: app)
        revealStudioDrawerFromSlot(in: app)
        assertStudioDrawerVisible(in: app)
        XCTAssertTrue(app.staticTexts["WAV"].exists)
        XCTAssertTrue(app.staticTexts["rough bounce.wav"].exists)
    }

    private func assertSeededTrackContext(in app: XCUIApplication) {
        XCTAssertTrue(app.element("song-container").waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["UI test bounce"].exists)
    }

    private func assertImportedFilesSongContainer(in app: XCUIApplication) {
        XCTAssertTrue(app.element("song-container").waitForExistence(timeout: 10))
        revealStudioDrawerFromSlot(in: app)
        assertStudioDrawerVisible(in: app)
        XCTAssertTrue(app.staticTexts["Phone Bounce"].exists)
        XCTAssertTrue(app.staticTexts["PDF"].exists)
        XCTAssertTrue(app.staticTexts["session notes.pdf"].exists)
    }

    private func revealStudioDrawerFromSlot(in app: XCUIApplication) {
        let slot = app.element("dynamic-slot")
        XCTAssertTrue(slot.waitForExistence(timeout: 5))

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.09))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.29))
        start.press(forDuration: 0.35)
        start.press(forDuration: 0.02, thenDragTo: end)
    }

    private func assertStudioDrawerVisible(in app: XCUIApplication) {
        let drawerTitle = app.staticTexts["Studio drawer"]
        if drawerTitle.waitForExistence(timeout: 3) {
            return
        }

        let songContainer = app.scrollViews["song-container"].firstMatch
        for _ in 0..<3 where !drawerTitle.exists {
            songContainer.swipeUp()
        }

        XCTAssertTrue(drawerTitle.waitForExistence(timeout: 5))
    }

    private func revealMarkerControls(in app: XCUIApplication) {
        let addMarkerButton = app.buttons["Add marker at playhead"]
        guard !addMarkerButton.waitForExistence(timeout: 2) || !addMarkerButton.isHittable else { return }

        revealStudioDrawerFromSlot(in: app)
        if addMarkerButton.waitForExistence(timeout: 2), addMarkerButton.isHittable {
            return
        }

        let songContainer = app.scrollViews["song-container"].firstMatch
        for _ in 0..<3 where !addMarkerButton.isHittable {
            songContainer.swipeUp()
        }

        XCTAssertTrue(addMarkerButton.waitForExistence(timeout: 5))
    }

    private func assertMarkerNote(_ note: String, in app: XCUIApplication) {
        let songContainer = app.scrollViews["song-container"].firstMatch
        let markerList = app.scrollViews["marker-list"].firstMatch

        for _ in 0..<4 {
            if let markerSummary = markerList.value as? String,
               markerSummary.contains(note) {
                return
            }

            songContainer.swipeUp()
        }

        XCTFail("Expected marker note '\(note)' to appear")
    }

    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        _ = XCTWaiter.wait(for: [expectation], timeout: timeout)
    }

    private func assertElementStaysGone(_ element: XCUIElement, duration: TimeInterval) {
        let deadline = Date().addingTimeInterval(duration)

        while Date() < deadline {
            XCTAssertFalse(element.exists)
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
    }

    private func saveScreenEvidence(named name: String, settleFor delay: TimeInterval = 0) {
        if delay > 0 {
            RunLoop.current.run(until: Date().addingTimeInterval(delay))
        }

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let outputURL = URL(fileURLWithPath: "/tmp").appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: outputURL, options: .atomic)
    }
}

private extension XCUIApplication {
    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any)[identifier]
    }
}

private enum DebugLaunchArgument {
    static let resetUIState = "--reset-ui-test-state"
    static let seedSongContainer = "--seed-ui-test-song-container"
    static let seedFilesImportProject = "--seed-ui-test-files-import-project"
    static let simulateFilesImport = "--simulate-ui-test-files-import"
    static let simulateFailedAudioImport = "--simulate-ui-test-failed-audio-import"
    static let simulatePickerFailure = "--simulate-ui-test-picker-failure"
    static let simulateAttachmentPickerFailure = "--simulate-ui-test-attachment-picker-failure"
    static let suppressImporterPresentation = "--suppress-ui-test-importer-presentation"
    static let openSongContainer = "--open-ui-test-song-container"
    static let openSongContainerMarkers = "--open-ui-test-song-container-markers"
    static let prepareSlotPull = "--prepare-ui-test-slot-pull"
    static let pendingSongContainerIntent = "--pending-ui-test-song-container-intent"
    static let autoCreateDiscPrompt = "--auto-create-disc-prompt"
    static let autoCreateDiscRitual = "--auto-create-disc-ritual"
    static let forceFullMotionRituals = "--force-full-motion-rituals"
}
