import AVFoundation
import CoreGraphics
import CoreVideo
import UIKit
import XCTest
@testable import MotionReveal

final class MusicWorkspaceModelTests: XCTestCase {
    func testLaunchAutomationPlanIgnoresNormalLaunchArguments() {
#if DEBUG
        let plan = WorkspaceLaunchAutomationPlan(arguments: ["MotionReveal"])

        XCTAssertFalse(plan.shouldRun)
        XCTAssertFalse(plan.simulateFilesImport)
        XCTAssertFalse(plan.simulateFailedAudioImport)
        XCTAssertFalse(plan.simulatePickerFailure)
        XCTAssertFalse(plan.simulateAttachmentPickerFailure)
        XCTAssertFalse(plan.suppressImporterPresentation)
        XCTAssertFalse(plan.autoCreateDiscPrompt)
        XCTAssertFalse(plan.openSongContainer)
#endif
    }

    func testLaunchAutomationPlanDetectsUITestRoutes() {
#if DEBUG
        let plan = WorkspaceLaunchAutomationPlan(arguments: [
            "MotionReveal",
            "--simulate-ui-test-files-import",
            "--simulate-ui-test-failed-audio-import",
            "--simulate-ui-test-picker-failure",
            "--simulate-ui-test-attachment-picker-failure",
            "--suppress-ui-test-importer-presentation",
            "--auto-create-disc-prompt",
            "--open-ui-test-song-container"
        ])

        XCTAssertTrue(plan.shouldRun)
        XCTAssertTrue(plan.simulateFilesImport)
        XCTAssertTrue(plan.simulateFailedAudioImport)
        XCTAssertTrue(plan.simulatePickerFailure)
        XCTAssertTrue(plan.simulateAttachmentPickerFailure)
        XCTAssertTrue(plan.suppressImporterPresentation)
        XCTAssertTrue(plan.autoCreateDiscPrompt)
        XCTAssertTrue(plan.openSongContainer)
        XCTAssertFalse(plan.prepareSlotPull)
#endif
    }

    func testSampleProjectsHaveUniqueIdentifiers() {
        let ids = Set(MusicProject.sampleProjects.map(\.id))

        XCTAssertEqual(ids.count, MusicProject.sampleProjects.count)
    }

    func testSampleProjectsHaveUsableMetadata() {
        for project in MusicProject.sampleProjects {
            XCTAssertFalse(project.title.isEmpty)
            XCTAssertFalse(project.creator.isEmpty)
            XCTAssertGreaterThanOrEqual(project.trackCount, 0)
            XCTAssertFalse(project.metadata.isEmpty)
        }
    }

    func testSampleTracksContainPlaybackLabels() {
        for track in MusicTrack.sampleTracks {
            XCTAssertFalse(track.title.isEmpty)
            XCTAssertFalse(track.date.isEmpty)
            XCTAssertFalse(track.duration.isEmpty)
        }
    }

    func testPlaybackProgressParsesTrackDurations() {
        XCTAssertEqual(PlaybackProgress.durationSeconds(from: "2:48"), 168)
        XCTAssertEqual(PlaybackProgress.durationSeconds(from: "10:03"), 603)
        XCTAssertNil(PlaybackProgress.durationSeconds(from: "Imported"))
    }

    func testPlaybackProgressFormatsTimeLabels() {
        XCTAssertEqual(PlaybackProgress.timeLabel(for: 0), "0:00")
        XCTAssertEqual(PlaybackProgress.timeLabel(for: 9.9), "0:09")
        XCTAssertEqual(PlaybackProgress.timeLabel(for: 185.2), "3:05")
    }

    func testPlaybackProgressAdvancesAndStopsAtDuration() {
        let progress = PlaybackProgress(
            elapsed: 167.8,
            duration: 168,
            isPlaying: true,
            isRealPlayback: false
        )
        let advanced = progress.advanced(by: 1)

        XCTAssertEqual(advanced.elapsed, 168)
        XCTAssertFalse(advanced.isPlaying)
        XCTAssertEqual(advanced.fraction, 1)
    }

    func testPlaybackProgressToggleRestartsCompletedTrack() {
        let progress = PlaybackProgress(
            elapsed: 168,
            duration: 168,
            isPlaying: false,
            isRealPlayback: false
        )
        let toggled = progress.toggledPlayback()

        XCTAssertEqual(toggled.elapsed, 0)
        XCTAssertTrue(toggled.isPlaying)
    }

    func testPlaybackProgressSeekClampsFractions() {
        let progress = PlaybackProgress(
            elapsed: 0,
            duration: 200,
            isPlaying: true,
            isRealPlayback: false
        )

        XCTAssertEqual(progress.seek(toFraction: 0.25).elapsed, 50)
        XCTAssertEqual(progress.seek(toFraction: -1).elapsed, 0)
        XCTAssertEqual(progress.seek(toFraction: 2).elapsed, 200)
    }

    @MainActor
    func testWorkspacePlaybackRuntimePreviewSeekUpdatesSharedProgressDuringRealPlayback() {
        let runtime = WorkspacePlaybackRuntime()
        runtime.nowPlaying = MusicTrack.placeholder
        runtime.progress = .real(elapsed: 8, duration: 100, isPlaying: true)

        runtime.previewSeek(to: 0.42)

        XCTAssertEqual(runtime.progress.elapsed, 42, accuracy: 0.001)
        XCTAssertTrue(runtime.progress.isPlaying)
        XCTAssertTrue(runtime.progress.isRealPlayback)
    }

    @MainActor
    func testWorkspacePlaybackRuntimePreviewSeekIgnoresPreviewOnlyPlayback() {
        let runtime = WorkspacePlaybackRuntime()
        runtime.nowPlaying = MusicTrack.placeholder
        runtime.progress = PlaybackProgress(elapsed: 8, duration: 100, isPlaying: true, isRealPlayback: false)

        runtime.previewSeek(to: 0.42)

        XCTAssertEqual(runtime.progress.elapsed, 8, accuracy: 0.001)
    }

    func testWaveformScrubMetricsSeparateScrubPreviewFromMarkerPresses() {
        XCTAssertTrue(WaveformScrubMetrics.shouldScrub(translation: CGSize(width: 8, height: 0)))
        XCTAssertFalse(WaveformScrubMetrics.shouldScrub(translation: CGSize(width: 7, height: 0)))
        XCTAssertFalse(WaveformScrubMetrics.shouldScrub(translation: CGSize(width: 12, height: 23)))

        XCTAssertFalse(WaveformScrubMetrics.shouldCancelTouch(translation: CGSize(width: 0, height: 22)))
        XCTAssertTrue(WaveformScrubMetrics.shouldCancelTouch(translation: CGSize(width: 0, height: 23)))

        XCTAssertTrue(WaveformScrubMetrics.shouldBeginLongPress(
            isScrubbing: false,
            hasAddedMarkerDuringCurrentPress: false,
            hasSelectedMarker: false,
            isCoolingDown: false
        ))
        XCTAssertFalse(WaveformScrubMetrics.shouldBeginLongPress(
            isScrubbing: true,
            hasAddedMarkerDuringCurrentPress: false,
            hasSelectedMarker: false,
            isCoolingDown: false
        ))
        XCTAssertFalse(WaveformScrubMetrics.shouldBeginLongPress(
            isScrubbing: false,
            hasAddedMarkerDuringCurrentPress: true,
            hasSelectedMarker: false,
            isCoolingDown: false
        ))
        XCTAssertFalse(WaveformScrubMetrics.shouldBeginLongPress(
            isScrubbing: false,
            hasAddedMarkerDuringCurrentPress: false,
            hasSelectedMarker: true,
            isCoolingDown: false
        ))
        XCTAssertFalse(WaveformScrubMetrics.shouldBeginLongPress(
            isScrubbing: false,
            hasAddedMarkerDuringCurrentPress: false,
            hasSelectedMarker: false,
            isCoolingDown: true
        ))
    }

    func testWaveformScrubMetricsUseLocalPreviewLabelWhileDragging() {
        let progress = PlaybackProgress(
            elapsed: 10,
            duration: 100,
            isPlaying: true,
            isRealPlayback: false
        )

        XCTAssertEqual(
            WaveformScrubMetrics.displayedElapsedLabel(for: progress, scrubFraction: nil),
            "0:10"
        )
        XCTAssertEqual(
            WaveformScrubMetrics.displayedElapsedLabel(for: progress, scrubFraction: 0.75),
            "1:15"
        )
    }

    func testWaveformScrubMetricsThrottleLiveSeekToFrameCadence() {
        let firstCommit = Date(timeIntervalSince1970: 100)

        XCTAssertGreaterThanOrEqual(WaveformScrubMetrics.liveScrubSeekInterval, 1.0 / 24.0)
        XCTAssertTrue(WaveformScrubMetrics.shouldCommitLiveScrub(lastCommit: nil, now: firstCommit))
        XCTAssertFalse(WaveformScrubMetrics.shouldCommitLiveScrub(
            lastCommit: firstCommit,
            now: firstCommit.addingTimeInterval(WaveformScrubMetrics.liveScrubSeekInterval / 2)
        ))
        XCTAssertTrue(WaveformScrubMetrics.shouldCommitLiveScrub(
            lastCommit: firstCommit,
            now: firstCommit.addingTimeInterval(WaveformScrubMetrics.liveScrubSeekInterval + 0.001)
        ))
    }

    func testWaveformGestureStateScrubsWithThrottledPreviewCommits() {
        var state = WaveformGestureState()
        let firstCommit = Date(timeIntervalSince1970: 100)

        XCTAssertTrue(state.beginScrub(at: 0.4, now: firstCommit))
        XCTAssertTrue(state.isScrubbing)
        XCTAssertEqual(state.scrubFraction, 0.4)
        XCTAssertEqual(state.lastLiveScrubSeekDate, firstCommit)

        let tooSoon = firstCommit.addingTimeInterval(WaveformScrubMetrics.liveScrubSeekInterval / 2)
        XCTAssertFalse(state.beginScrub(at: 0.6, now: tooSoon))
        XCTAssertEqual(state.scrubFraction, 0.6)
        XCTAssertEqual(state.lastLiveScrubSeekDate, firstCommit)

        state.finishScrub(at: 0.75)
        XCTAssertFalse(state.isScrubbing)
        XCTAssertEqual(state.scrubFraction, 0.75)
        XCTAssertNil(state.lastLiveScrubSeekDate)
    }

    func testWaveformGestureStateBlocksMarkerCaptureDuringCooldownsAndScrubs() {
        var state = WaveformGestureState()
        let now = Date(timeIntervalSince1970: 200)

        XCTAssertTrue(state.canBeginLongPress(
            now: now,
            hasSelectedMarker: false,
            isMarkerEditorPresented: false
        ))

        _ = state.beginScrub(at: 0.25, now: now)
        XCTAssertFalse(state.canBeginLongPress(
            now: now,
            hasSelectedMarker: false,
            isMarkerEditorPresented: false
        ))

        state.cancelLongPressState(resetScrubbing: true)
        state.markAddedMarker(now: now)
        XCTAssertFalse(state.canBeginLongPress(
            now: now.addingTimeInterval(0.1),
            hasSelectedMarker: false,
            isMarkerEditorPresented: false
        ))
        XCTAssertFalse(state.shouldCommitTapSeek(translation: .zero))

        state.lockMarkerCapture(until: now.addingTimeInterval(2))
        XCTAssertFalse(state.canBeginLongPress(
            now: now.addingTimeInterval(1),
            hasSelectedMarker: false,
            isMarkerEditorPresented: false
        ))
    }

    func testWaveformVisualMetricsKeepLongSlimWaveformWithLargeTouchTarget() {
        let rect = WaveformVisualMetrics.trackRect(in: CGSize(width: 360, height: 172))

        XCTAssertLessThanOrEqual(WaveformVisualMetrics.horizontalInset, 2)
        XCTAssertGreaterThanOrEqual(rect.width, 356)
        XCTAssertGreaterThanOrEqual(rect.height, MarkerTouchMetrics.minimumTouchTarget)
        XCTAssertLessThan(WaveformVisualMetrics.maxBarHeight, rect.height)
        XCTAssertLessThan(WaveformVisualMetrics.playheadWidth, 2)
        XCTAssertGreaterThan(WaveformVisualMetrics.barWidth(in: rect.width), WaveformVisualMetrics.playheadWidth)
    }

    @MainActor
    func testRemotePreviousCommandRestartsCurrentTrackOnFirstPress() {
        let now = Date()

        let decision = RemoteCommandController.previousCommandDecision(
            hasCurrentTrack: true,
            canPlayPreviousTrack: true,
            lastPreviousCommandDate: nil,
            now: now,
            doubleTapWindow: 0.45
        )

        XCTAssertEqual(decision, .restartCurrentTrack)
    }

    @MainActor
    func testRemotePreviousCommandMovesToPreviousTrackOnSecondPressWithinWindow() {
        let now = Date()

        let decision = RemoteCommandController.previousCommandDecision(
            hasCurrentTrack: true,
            canPlayPreviousTrack: true,
            lastPreviousCommandDate: now.addingTimeInterval(-0.2),
            now: now,
            doubleTapWindow: 0.45
        )

        XCTAssertEqual(decision, .playPreviousTrack)
    }

    @MainActor
    func testRemotePreviousCommandRestartsAgainAfterWindowExpires() {
        let now = Date()

        let decision = RemoteCommandController.previousCommandDecision(
            hasCurrentTrack: true,
            canPlayPreviousTrack: true,
            lastPreviousCommandDate: now.addingTimeInterval(-0.6),
            now: now,
            doubleTapWindow: 0.45
        )

        XCTAssertEqual(decision, .restartCurrentTrack)
    }

    @MainActor
    func testRemotePreviousCommandReportsMissingPreviousTrackOnSecondPressAtLibraryStart() {
        let now = Date()

        let decision = RemoteCommandController.previousCommandDecision(
            hasCurrentTrack: true,
            canPlayPreviousTrack: false,
            lastPreviousCommandDate: now.addingTimeInterval(-0.2),
            now: now,
            doubleTapWindow: 0.45
        )

        XCTAssertEqual(decision, .noPreviousTrack)
    }

    @MainActor
    func testRemotePreviousCommandReportsMissingTrackWhenNothingIsPlaying() {
        let now = Date()

        let decision = RemoteCommandController.previousCommandDecision(
            hasCurrentTrack: false,
            canPlayPreviousTrack: false,
            lastPreviousCommandDate: now.addingTimeInterval(-0.2),
            now: now,
            doubleTapWindow: 0.45
        )

        XCTAssertEqual(decision, .noTrack)
    }

    func testPlaybackProgressFormatsMarkerTimeAtFraction() {
        let progress = PlaybackProgress(
            elapsed: 42,
            duration: 185,
            isPlaying: true,
            isRealPlayback: false
        )

        XCTAssertEqual(progress.timeLabel(atFraction: 0.25), "0:46")
        XCTAssertEqual(progress.timeLabel(atFraction: -1), "0:00")
        XCTAssertEqual(progress.timeLabel(atFraction: 2), "3:05")
    }

    @MainActor
    func testWorkspacePlaybackCoordinatorStartsPreviewForTrackWithoutLocalFile() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let track = MusicTrack(
            id: UUID(),
            title: "Sketch",
            date: "May 24",
            duration: "2:00"
        )
        let coordinator = WorkspacePlaybackCoordinator(
            audioPlayback: AudioPlaybackController(),
            libraryStore: MusicLibraryStore(documentsURL: storeRoot)
        )

        let result = try coordinator.start(track: track)

        XCTAssertEqual(result.message, "Previewing")
        XCTAssertEqual(result.progress.duration, 120)
        XCTAssertTrue(result.progress.isPlaying)
        XCTAssertFalse(result.progress.isRealPlayback)
    }

    @MainActor
    func testWorkspacePlaybackCoordinatorUpdatesPreviewProgress() {
        let coordinator = WorkspacePlaybackCoordinator(
            audioPlayback: AudioPlaybackController(),
            libraryStore: MusicLibraryStore()
        )
        let progress = PlaybackProgress(
            elapsed: 10,
            duration: 100,
            isPlaying: true,
            isRealPlayback: false
        )

        XCTAssertEqual(coordinator.toggle(current: progress).isPlaying, false)
        XCTAssertEqual(coordinator.seek(current: progress, to: 0.25).elapsed, 25)
        XCTAssertEqual(coordinator.tick(current: progress).elapsed, 10.25)
    }

    func testWorkspaceDestructiveActionExecutorDeletesSelectedProject() {
        let firstProject = makeProject(title: "First", trackCount: 1)
        let secondProject = makeProject(title: "Second", trackCount: 1)
        var projects = [firstProject, secondProject]
        var selectedProject = firstProject
        var screen = WorkspaceScreen.project

        WorkspaceDestructiveActionExecutor.deleteSelectedProject(
            projects: &projects,
            selectedProject: &selectedProject,
            screen: &screen
        )

        XCTAssertEqual(projects, [secondProject])
        XCTAssertEqual(selectedProject, secondProject)
        XCTAssertEqual(screen, .library)
    }

    func testWorkspaceDestructiveActionExecutorRemovesAttachment() {
        let attachment = SongAttachment(
            id: UUID(),
            kind: "PDF",
            name: "lyrics.pdf",
            category: "Lyrics",
            subtitle: "May 24",
            size: "12 KB",
            localFileName: "lyrics-local.pdf"
        )
        let track = MusicTrack(
            id: UUID(),
            title: "Hook",
            date: "May 24",
            duration: "1:00",
            attachments: [attachment]
        )
        var selectedProject = makeProject(title: "Project", tracks: [track])
        var projects = [selectedProject]

        let outcome = WorkspaceDestructiveActionExecutor.removeAttachment(
            attachment,
            fromTrackID: track.id,
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(outcome, .removed(attachment: attachment, updatedTrack: selectedProject.tracks[0]))
        XCTAssertTrue(selectedProject.tracks[0].attachments.isEmpty)
        XCTAssertEqual(projects[0], selectedProject)
    }

    func testWorkspaceProjectMutationExecutorRenamesSelectedProject() {
        var selectedProject = makeProject(title: "Draft")
        var projects = [selectedProject]

        WorkspaceProjectMutationExecutor.renameSelectedProject(
            to: "Final Mixes",
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(selectedProject.title, "Final Mixes")
        XCTAssertEqual(projects[0], selectedProject)
    }

    func testWorkspaceProjectMutationExecutorCreatesAndActivatesFreshProject() {
        let existingProject = makeProject(title: "Existing")
        let freshID = UUID()
        var projects = [existingProject]

        let freshProject = WorkspaceProjectMutationExecutor.createFreshProject(
            projects: &projects,
            id: freshID
        )

        XCTAssertEqual(freshProject.id, freshID)
        XCTAssertEqual(freshProject.state, .fresh)
        XCTAssertEqual(projects.map(\.id), [freshID, existingProject.id])

        let activatedProject = WorkspaceProjectMutationExecutor.activateCreatedProject(id: freshID, projects: &projects)

        XCTAssertEqual(activatedProject?.id, freshID)
        XCTAssertEqual(activatedProject?.state, .regular)
        XCTAssertEqual(projects[0].state, .regular)
        XCTAssertNil(WorkspaceProjectMutationExecutor.activateCreatedProject(id: UUID(), projects: &projects))
    }

    func testWorkspaceProjectMutationExecutorDuplicatesProjectAfterSelectedProject() {
        let firstProject = makeProject(title: "First")
        let selectedProject = makeProject(title: "Selected")
        let lastProject = makeProject(title: "Last")
        let duplicateID = UUID()
        var projects = [firstProject, selectedProject, lastProject]

        let duplicate = WorkspaceProjectMutationExecutor.duplicateSelectedProject(
            selectedProject: selectedProject,
            projects: &projects,
            duplicateID: duplicateID
        )

        XCTAssertEqual(duplicate.id, duplicateID)
        XCTAssertEqual(duplicate.title, "Selected copy")
        XCTAssertEqual(duplicate.state, .regular)
        XCTAssertEqual(projects.map(\.id), [firstProject.id, selectedProject.id, duplicateID, lastProject.id])
    }

    func testWorkspaceProjectMutationExecutorTogglesSelectedProjectPin() {
        var selectedProject = makeProject(title: "Pin Me")
        var projects = [selectedProject]

        let pinnedState = WorkspaceProjectMutationExecutor.toggleSelectedProjectPin(
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(pinnedState, .pinned)
        XCTAssertEqual(selectedProject.state, .pinned)
        XCTAssertEqual(projects[0], selectedProject)

        let regularState = WorkspaceProjectMutationExecutor.toggleSelectedProjectPin(
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(regularState, .regular)
        XCTAssertEqual(selectedProject.state, .regular)
        XCTAssertEqual(projects[0], selectedProject)
    }

    func testWorkspaceTrackMutationExecutorRenamesTrack() {
        let track = MusicTrack(id: UUID(), title: "Scratch", date: "May 24", duration: "0:30")
        var selectedProject = makeProject(title: "Project", tracks: [track])
        var projects = [selectedProject]

        let updatedTrack = WorkspaceTrackMutationExecutor.renameTrack(
            id: track.id,
            to: "Hook Idea",
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(updatedTrack?.title, "Hook Idea")
        XCTAssertEqual(selectedProject.tracks[0].title, "Hook Idea")
        XCTAssertEqual(projects[0], selectedProject)
    }

    func testWorkspaceTrackMutationExecutorUpdatesAttachmentDetails() {
        let attachment = SongAttachment(
            id: UUID(),
            kind: "PDF",
            name: "old.pdf",
            category: "File",
            subtitle: "May 24",
            size: "8 KB",
            localFileName: "old-local.pdf"
        )
        let track = MusicTrack(
            id: UUID(),
            title: "Hook",
            date: "May 24",
            duration: "1:00",
            attachments: [attachment]
        )
        var selectedProject = makeProject(title: "Project", tracks: [track])
        var projects = [selectedProject]

        let updatedTrack = WorkspaceTrackMutationExecutor.updateAttachmentDetails(
            trackID: track.id,
            attachmentID: attachment.id,
            name: "new.pdf",
            category: "Lyrics",
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(updatedTrack?.attachments[0].name, "new.pdf")
        XCTAssertEqual(updatedTrack?.attachments[0].category, "Lyrics")
        XCTAssertEqual(projects[0], selectedProject)

        let missingUpdate = WorkspaceTrackMutationExecutor.updateAttachmentDetails(
            trackID: track.id,
            attachmentID: UUID(),
            name: "missing.pdf",
            category: "Missing",
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertNil(missingUpdate)
        XCTAssertEqual(selectedProject.tracks[0].attachments[0].name, "new.pdf")
    }

    func testWorkspaceTrackMutationExecutorUpdatesSongTextWithDeterministicDate() {
        let track = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let updatedAt = Date(timeIntervalSince1970: 1_771_718_400)
        var selectedProject = makeProject(title: "Project", tracks: [track])
        var projects = [selectedProject]

        let updatedTrack = WorkspaceTrackMutationExecutor.updateSongText(
            trackID: track.id,
            kind: .lyrics,
            text: "words",
            selectedProject: &selectedProject,
            projects: &projects,
            updatedAt: updatedAt
        )

        let lyrics = updatedTrack?.textDocuments.first { $0.kind == .lyrics }
        XCTAssertEqual(lyrics?.text, "words")
        XCTAssertEqual(lyrics?.updatedAt, updatedAt)
        XCTAssertEqual(updatedTrack?.textDocuments.count, SongTextKind.allCases.count)
        XCTAssertEqual(projects[0], selectedProject)
    }

    func testWorkspaceTrackMutationExecutorUpdatesMarkers() {
        let track = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let marker = WaveformMarker(
            id: UUID(),
            position: 0.25,
            height: 0.8,
            colorToken: .mint,
            time: "0:15",
            note: "tighten"
        )
        var selectedProject = makeProject(title: "Project", tracks: [track])
        var projects = [selectedProject]

        let updatedTrack = WorkspaceTrackMutationExecutor.updateMarkers(
            [marker],
            forTrackID: track.id,
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(updatedTrack?.markers, [marker])
        XCTAssertEqual(
            WorkspaceTrackMutationExecutor.markers(forTrackID: track.id, selectedProject: selectedProject),
            [marker]
        )
        XCTAssertEqual(projects[0], selectedProject)
    }

    func testWorkspaceTrackMutationExecutorAddsAndSavesMarkerDrafts() throws {
        let track = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        var selectedProject = makeProject(title: "Project", tracks: [track])
        var projects = [selectedProject]

        let addResult = WorkspaceTrackMutationExecutor.addMarker(
            position: 0.4,
            time: "0:24",
            forTrackID: track.id,
            selectedProject: &selectedProject,
            projects: &projects
        )

        let addedMarker = try XCTUnwrap(addResult?.marker)
        XCTAssertEqual(addedMarker.position, 0.4)
        XCTAssertEqual(addedMarker.time, "0:24")
        XCTAssertEqual(addResult?.updatedTrack.markers, [addedMarker])

        var draft = WorkspaceMarkerDraft(trackID: track.id, marker: addedMarker)
        draft.time = " 0:30 "
        draft.note = "  tighten hook  "
        draft.colorToken = .mint
        draft.isResolved = true

        let saveResult = WorkspaceTrackMutationExecutor.saveMarkerDraft(
            draft,
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(saveResult?.marker.time, "0:30")
        XCTAssertEqual(saveResult?.marker.note, "tighten hook")
        XCTAssertEqual(saveResult?.marker.colorToken, .mint)
        XCTAssertEqual(saveResult?.marker.isResolved, true)
        XCTAssertEqual(saveResult?.updatedTrack.markers.first, saveResult?.marker)
        XCTAssertEqual(projects[0], selectedProject)
    }

    func testWorkspaceTrackMutationExecutorTogglesAndDeletesMarkerDrafts() {
        var marker = WaveformMarker.created(position: 0.25, time: "0:15", existingCount: 0, note: "fix")
        marker.isResolved = false
        let track = MusicTrack(
            id: UUID(),
            title: "Hook",
            date: "May 24",
            duration: "1:00",
            markers: [marker]
        )
        var selectedProject = makeProject(title: "Project", tracks: [track])
        var projects = [selectedProject]

        let toggleResult = WorkspaceTrackMutationExecutor.toggleMarkerResolved(
            marker,
            forTrackID: track.id,
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(toggleResult?.marker.id, marker.id)
        XCTAssertEqual(toggleResult?.marker.isResolved, true)
        XCTAssertEqual(toggleResult?.updatedTrack.markers.first?.isResolved, true)

        let deleteResult = WorkspaceTrackMutationExecutor.deleteMarkerDraft(
            WorkspaceMarkerDraft(trackID: track.id, marker: marker),
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(deleteResult?.deletedMarkerID, marker.id)
        XCTAssertEqual(deleteResult?.updatedTrack.markers, [])
        XCTAssertEqual(projects[0], selectedProject)
    }

    func testWorkspaceImportMutationExecutorAppendsImportedTracks() {
        let existingTrack = MusicTrack(id: UUID(), title: "Verse", date: "May 24", duration: "0:45")
        let importedTrack = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        var selectedProject = makeProject(title: "Project", tracks: [existingTrack])
        var projects = [selectedProject]

        let updatedProject = WorkspaceImportMutationExecutor.appendImportedTracks(
            [importedTrack],
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(updatedProject.tracks.map(\.id), [existingTrack.id, importedTrack.id])
        XCTAssertEqual(updatedProject.trackCount, 2)
        XCTAssertEqual(selectedProject, updatedProject)
        XCTAssertEqual(projects[0], updatedProject)
    }

    func testWorkspaceImportMutationExecutorPersistsSelectedProjectWhenMissingFromLibrary() {
        let importedTrack = MusicTrack(id: UUID(), title: "Open In bounce", date: "May 26", duration: "1:00")
        var selectedProject = makeProject(title: "External import target", tracks: [])
        var projects: [MusicProject] = []

        let updatedProject = WorkspaceImportMutationExecutor.appendImportedTracks(
            [importedTrack],
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(updatedProject.tracks.map(\.id), [importedTrack.id])
        XCTAssertEqual(projects.map(\.id), [updatedProject.id])
        XCTAssertEqual(projects[0], selectedProject)
    }

    func testWorkspaceImportMutationExecutorAppendsAttachments() {
        let track = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let attachment = SongAttachment(
            id: UUID(),
            kind: "ZIP",
            name: "stems.zip",
            category: "Stems",
            subtitle: "May 24",
            size: "1 MB",
            localFileName: "stems-local.zip"
        )
        var selectedProject = makeProject(title: "Project", tracks: [track])
        var projects = [selectedProject]

        let updatedTrack = WorkspaceImportMutationExecutor.appendAttachments(
            [attachment],
            toTrackID: track.id,
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(updatedTrack?.attachments, [attachment])
        XCTAssertEqual(selectedProject.trackCount, 1)
        XCTAssertEqual(projects[0], selectedProject)

        let missingTrack = WorkspaceImportMutationExecutor.appendAttachments(
            [attachment],
            toTrackID: UUID(),
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertNil(missingTrack)
        XCTAssertEqual(selectedProject.tracks[0].attachments, [attachment])
    }

    func testWorkspaceTrackMutationExecutorSetsAnimatedArtwork() {
        let track = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let artwork = MotionArtwork(
            localFileName: "motion-artwork.mov",
            sourceFileName: "cover-loop.mov",
            variant: .square
        )
        var selectedProject = makeProject(title: "Project", tracks: [track])
        var projects = [selectedProject]

        let updatedTrack = WorkspaceTrackMutationExecutor.setAnimatedArtwork(
            artwork,
            forTrackID: track.id,
            selectedProject: &selectedProject,
            projects: &projects
        )

        XCTAssertEqual(updatedTrack?.animatedArtwork, artwork)
        XCTAssertEqual(selectedProject.tracks[0].animatedArtwork, artwork)
        XCTAssertEqual(projects[0].tracks[0].animatedArtwork, artwork)
    }

    func testProjectCoverMotionArtworkUsesStoredProjectCover() {
        let firstTrack = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let artwork = MotionArtwork(
            localFileName: "motion-artwork.mov",
            sourceFileName: "cover-loop.mov",
            variant: .square
        )
        let secondTrack = MusicTrack(
            id: UUID(),
            title: "Verse",
            date: "May 24",
            duration: "0:48",
            animatedArtwork: artwork
        )
        let project = makeProject(title: "Project", tracks: [firstTrack, secondTrack])
        let storedProject = MusicProject(
            id: project.id,
            title: project.title,
            creator: project.creator,
            trackCount: project.trackCount,
            runtime: project.runtime,
            sleeve: project.sleeve,
            coverMotionArtwork: artwork,
            coverMotionArtworkIsExplicit: true,
            state: project.state,
            tracks: project.tracks
        )

        XCTAssertEqual(storedProject.coverMotionArtwork, artwork)
        XCTAssertEqual(storedProject.displayedCoverMotionArtwork, artwork)
    }

    func testProjectCoverMotionArtworkFallsBackToLegacyTrackArtworkWhenUnset() {
        let firstTrack = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let artwork = MotionArtwork(
            localFileName: "motion-artwork.mov",
            sourceFileName: "cover-loop.mov",
            variant: .square
        )
        let secondTrack = MusicTrack(
            id: UUID(),
            title: "Verse",
            date: "May 24",
            duration: "0:48",
            animatedArtwork: artwork
        )
        let project = makeProject(title: "Project", tracks: [firstTrack, secondTrack])

        XCTAssertNil(project.coverMotionArtwork)
        XCTAssertEqual(project.displayedCoverMotionArtwork, artwork)
    }

    func testMotionArtworkPlaybackIdentityChangesWhenFileOrVariantChanges() {
        let squareArtwork = MotionArtwork(
            localFileName: "motion-artwork.mov",
            sourceFileName: "cover-loop.mov",
            variant: .square
        )
        let replacedArtwork = MotionArtwork(
            localFileName: "replacement-loop.mov",
            sourceFileName: "cover-loop.mov",
            variant: .square
        )
        let portraitArtwork = MotionArtwork(
            localFileName: "motion-artwork.mov",
            sourceFileName: "cover-loop.mov",
            variant: .portrait
        )

        XCTAssertNotEqual(squareArtwork.playbackIdentity, replacedArtwork.playbackIdentity)
        XCTAssertNotEqual(squareArtwork.playbackIdentity, portraitArtwork.playbackIdentity)
    }

    func testWorkspaceDynamicIslandCoordinatorEndsWhenNoTrackIsAvailable() {
        let project = makeProject(title: "Empty")

        let action = WorkspaceDynamicIslandCoordinator.action(
            selectedProject: project,
            nowPlaying: nil,
            playbackProgress: .idle
        )

        XCTAssertEqual(action, .end)
    }

    func testWorkspaceDynamicIslandCoordinatorUsesPreferredTrackAndOverride() {
        let firstTrack = MusicTrack(id: UUID(), title: "Verse", date: "May 24", duration: "0:45")
        let preferredTrack = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let project = makeProject(title: "Project", tracks: [firstTrack, preferredTrack])
        let progress = PlaybackProgress(elapsed: 4, duration: 60, isPlaying: true, isRealPlayback: false)

        let action = WorkspaceDynamicIslandCoordinator.action(
            selectedProject: project,
            nowPlaying: firstTrack,
            playbackProgress: progress,
            preferredTrack: preferredTrack,
            isPlayingOverride: false
        )

        XCTAssertEqual(
            action,
            .update(
                project: project,
                track: preferredTrack,
                isPlaying: false,
                progress: PlaybackProgress(elapsed: 0, duration: 60, isPlaying: false, isRealPlayback: false),
                presentation: .background,
                canStartNewActivity: true
            )
        )
    }

    func testWorkspaceDynamicIslandCoordinatorUsesNowPlayingWhenAvailable() {
        let firstTrack = MusicTrack(id: UUID(), title: "Verse", date: "May 24", duration: "0:45")
        let nowPlaying = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let project = makeProject(title: "Project", tracks: [firstTrack, nowPlaying])
        let progress = PlaybackProgress(elapsed: 4, duration: 60, isPlaying: true, isRealPlayback: false)

        let action = WorkspaceDynamicIslandCoordinator.action(
            selectedProject: project,
            nowPlaying: nowPlaying,
            playbackProgress: progress
        )

        XCTAssertEqual(
            action,
            .update(
                project: project,
                track: nowPlaying,
                isPlaying: true,
                progress: progress,
                presentation: .background,
                canStartNewActivity: true
            )
        )
    }

    func testWorkspaceDynamicIslandCoordinatorFallbackTrackIsNotPlayingWhenNowPlayingDiffers() {
        let firstTrack = MusicTrack(id: UUID(), title: "Verse", date: "May 24", duration: "0:45")
        let nowPlaying = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let project = makeProject(title: "Project", tracks: [firstTrack])
        let progress = PlaybackProgress(elapsed: 4, duration: 60, isPlaying: true, isRealPlayback: false)

        let action = WorkspaceDynamicIslandCoordinator.action(
            selectedProject: project,
            nowPlaying: nil,
            playbackProgress: progress,
            preferredTrack: firstTrack
        )
        let fallbackAction = WorkspaceDynamicIslandCoordinator.action(
            selectedProject: project,
            nowPlaying: nowPlaying,
            playbackProgress: progress,
            preferredTrack: firstTrack
        )

        let idleFirstTrackProgress = PlaybackProgress(elapsed: 0, duration: 45, isPlaying: false, isRealPlayback: false)
        XCTAssertEqual(
            action,
            .update(
                project: project,
                track: firstTrack,
                isPlaying: false,
                progress: idleFirstTrackProgress,
                presentation: .background,
                canStartNewActivity: true
            )
        )
        XCTAssertEqual(
            fallbackAction,
            .update(
                project: project,
                track: firstTrack,
                isPlaying: false,
                progress: idleFirstTrackProgress,
                presentation: .background,
                canStartNewActivity: true
            )
        )
    }

    func testWorkspaceDynamicIslandCoordinatorCanRequestTransientInAppPresentation() {
        let track = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let project = makeProject(title: "Project", tracks: [track])

        let action = WorkspaceDynamicIslandCoordinator.action(
            selectedProject: project,
            nowPlaying: track,
            playbackProgress: .preview(for: track),
            presentation: .inAppTransient
        )

        XCTAssertEqual(
            action,
            .update(
                project: project,
                track: track,
                isPlaying: true,
                progress: .preview(for: track),
                presentation: .inAppTransient,
                canStartNewActivity: true
            )
        )
    }

    func testWorkspaceSongContainerCoordinatorUsesFirstTrackWhenNothingIsPlaying() {
        let firstTrack = MusicTrack(id: UUID(), title: "Verse", date: "May 24", duration: "0:45")
        let secondTrack = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let project = makeProject(title: "Project", tracks: [firstTrack, secondTrack])
        let coordinator = WorkspaceSongContainerCoordinator(selectedProject: project, nowPlaying: nil)

        let decision = coordinator.openDecision(revealStudioDrawer: false)

        XCTAssertEqual(decision, .open(track: firstTrack, revealStudioDrawer: false))
    }

    func testWorkspaceSongContainerCoordinatorKeepsNowPlayingTrack() {
        let firstTrack = MusicTrack(id: UUID(), title: "Verse", date: "May 24", duration: "0:45")
        let nowPlaying = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let project = makeProject(title: "Project", tracks: [firstTrack, nowPlaying])
        let coordinator = WorkspaceSongContainerCoordinator(selectedProject: project, nowPlaying: nowPlaying)

        let decision = coordinator.openDecision(revealStudioDrawer: true)

        XCTAssertEqual(decision, .open(track: nowPlaying, revealStudioDrawer: true))
    }

    func testWorkspaceSongContainerCoordinatorRequestsImportWhenProjectHasNoTracks() {
        let project = makeProject(title: "Empty")
        let coordinator = WorkspaceSongContainerCoordinator(selectedProject: project, nowPlaying: nil)

        XCTAssertEqual(coordinator.openDecision(revealStudioDrawer: true), .needsTrack)
    }

    func testWorkspaceSongContainerCoordinatorKeepsRoutesDrawerClosed() {
        let track = MusicTrack(id: UUID(), title: "Hook", date: "May 24", duration: "1:00")
        let project = makeProject(title: "Project", tracks: [track])
        let coordinator = WorkspaceSongContainerCoordinator(selectedProject: project, nowPlaying: nil)

        let deepLinkDecision = coordinator.openDecision(for: WorkspaceDeepLinkRoute.songContainer)
        let intentDecision = coordinator.openDecision(for: MotionRevealIntentRoute.songContainer)

        XCTAssertEqual(deepLinkDecision, .open(track: track, revealStudioDrawer: false))
        XCTAssertEqual(intentDecision, .open(track: track, revealStudioDrawer: false))
    }

    func testImportedTrackTitleUsesReadableFileName() {
        let url = URL(fileURLWithPath: "/tmp/Main_Bounce_v9.wav")
        let track = MusicTrack.imported(from: url, localFileName: "local.wav")

        XCTAssertEqual(track.title, "Main Bounce v9")
        XCTAssertEqual(track.duration, "Imported")
        XCTAssertEqual(track.localFileName, "local.wav")
        XCTAssertEqual(track.audioFormat, nil)
        XCTAssertEqual(track.metadataLine, track.date)
    }

    func testImportedTrackTitleFallsBackForEmptyFileName() {
        let url = URL(fileURLWithPath: "/")

        XCTAssertEqual(MusicTrack.importedDisplayTitle(from: url), "Imported audio")
    }

    func testImportedTrackUsesReadableAudioMetadata() {
        let url = URL(fileURLWithPath: "/tmp/Main_Bounce_v9.wav")
        let metadata = AudioFileMetadata(
            title: "Tagged bounce",
            artist: "Joseph",
            durationLabel: "3:12",
            format: "WAV"
        )

        let track = MusicTrack.imported(from: url, localFileName: "local.wav", metadata: metadata)

        XCTAssertEqual(track.title, "Tagged bounce")
        XCTAssertEqual(track.duration, "3:12")
        XCTAssertEqual(track.artistName, "Joseph")
        XCTAssertEqual(track.audioFormat, "WAV")
        XCTAssertEqual(track.metadataLine, "Joseph · 3:12 · WAV")
        XCTAssertTrue(metadata.hasReadableTags)
    }

    func testImportedTrackMetadataLineFallsBackToDateAndFormat() {
        let url = URL(fileURLWithPath: "/tmp/rough_mix.aif")
        let metadata = AudioFileMetadata(
            title: nil,
            artist: nil,
            durationLabel: nil,
            format: "AIF"
        )

        let track = MusicTrack.imported(from: url, localFileName: "local.aif", metadata: metadata)

        XCTAssertEqual(track.title, "rough mix")
        XCTAssertEqual(track.duration, "Imported")
        XCTAssertEqual(track.metadataLine, "\(track.date) · AIF")
    }

    func testImportedTrackDetectsDuplicateSourceTitles() {
        let track = MusicTrack.imported(
            from: URL(fileURLWithPath: "/tmp/Main_Bounce_v9.wav"),
            localFileName: "local.wav"
        )

        XCTAssertTrue(track.matchesImportedSource(URL(fileURLWithPath: "/tmp/main bounce v9.aif")))
        XCTAssertFalse(track.matchesImportedSource(URL(fileURLWithPath: "/tmp/different_bounce.wav")))
    }

    func testImportStatusSummarizesPartialResults() {
        let status = WorkspaceImportStatus.success(
            kind: .audio,
            imported: 2,
            failedFileNames: ["bad.wav"],
            skippedDuplicates: 1
        )

        XCTAssertEqual(status.title, "Tracks imported")
        XCTAssertEqual(status.message, "2 added · 1 duplicate skipped · 1 failed\nCould not copy bad.wav.")
        XCTAssertFalse(status.isLoading)
        XCTAssertTrue(status.needsAttention)
        XCTAssertEqual(status.autoDismissDelayMilliseconds, 4_800)
        XCTAssertEqual(
            status.accessibilityLabel,
            "Tracks imported. 2 added, 1 duplicate skipped, 1 failed. Could not copy bad.wav."
        )
    }

    func testImportStatusSummarizesDuplicateOnlyResults() {
        let status = WorkspaceImportStatus.success(
            kind: .audio,
            imported: 0,
            failedFileNames: [],
            skippedDuplicates: 2
        )

        XCTAssertEqual(status.title, "Already in this sleeve")
        XCTAssertEqual(status.message, "2 duplicates skipped")
        XCTAssertTrue(status.needsAttention)
        XCTAssertEqual(status.autoDismissDelayMilliseconds, 4_800)
        XCTAssertEqual(status.accessibilityLabel, "Already in this sleeve. 2 duplicates skipped")
    }

    func testImportStatusReportsAttachmentFailuresWithRecovery() {
        let status = WorkspaceImportStatus.failure(
            kind: .attachment,
            failedFileNames: ["session.ptx", "lyrics.pdf", "refs.zip"]
        )

        XCTAssertEqual(status.title, "Import failed")
        XCTAssertEqual(
            status.message,
            "Could not copy session.ptx, lyrics.pdf, and 1 more.\nIn Files, download the file locally first, then try again."
        )
        XCTAssertTrue(status.needsAttention)
        XCTAssertEqual(status.autoDismissDelayMilliseconds, 9_000)
        XCTAssertEqual(
            status.accessibilityLabel,
            "Import failed. Could not copy session.ptx, lyrics.pdf, and 1 more. In Files, download the file locally first, then try again."
        )
    }

    func testImportStatusReportsAnimatedArtworkConstraintFailuresWithRecovery() {
        let status = WorkspaceImportStatus.failure(
            kind: .animatedArtwork,
            failedFileNames: ["cover-loop.mp4: longer than 0:15 limit (0:16)"]
        )

        XCTAssertEqual(status.title, "Import failed")
        XCTAssertEqual(
            status.message,
            "Could not use cover-loop.mp4: longer than 0:15 limit (0:16).\nChoose a local .mov or .mp4 motion-artwork file under 25 MB and 0:15, then try again."
        )
        XCTAssertTrue(status.needsAttention)
        XCTAssertEqual(status.autoDismissDelayMilliseconds, 9_000)
        XCTAssertEqual(
            status.accessibilityLabel,
            "Import failed. Could not use cover-loop.mp4: longer than 0:15 limit (0:16). Choose a local .mov or .mp4 motion-artwork file under 25 MB and 0:15, then try again."
        )
    }

    func testImportStatusReportsPickerFailureWhenNoReadableFileReturns() {
        let status = WorkspaceImportStatus.failure(
            kind: .audio,
            failedFileNames: []
        )

        XCTAssertEqual(status.title, "Import failed")
        XCTAssertEqual(
            status.message,
            "Files did not return a readable local copy.\nIn Files, download the audio locally first, then try again."
        )
        XCTAssertTrue(status.needsAttention)
        XCTAssertEqual(status.autoDismissDelayMilliseconds, 9_000)
        XCTAssertEqual(
            status.accessibilityLabel,
            "Import failed. Files did not return a readable local copy. In Files, download the audio locally first, then try again."
        )
    }

    func testImportStatusReportsFilesPickerProviderFailures() {
        let status = WorkspaceImportStatus.pickerFailure(
            kind: .audio,
            reason: "The selected item is not available."
        )

        XCTAssertEqual(status.title, "Files could not open")
        XCTAssertEqual(
            status.message,
            "Files could not hand the selection back to the app.\nThe selected item is not available.\nIn Files, download the audio locally first, then try again."
        )
        XCTAssertTrue(status.needsAttention)
        XCTAssertEqual(status.autoDismissDelayMilliseconds, 9_000)
        XCTAssertEqual(
            status.accessibilityLabel,
            "Files could not open. Files could not hand the selection back to the app. The selected item is not available. In Files, download the audio locally first, then try again."
        )
    }

    func testImportStatusReportsAttachmentPickerProviderFailures() {
        let status = WorkspaceImportStatus.pickerFailure(
            kind: .attachment,
            reason: "The selected attachment is not available."
        )

        XCTAssertEqual(status.title, "Files could not open")
        XCTAssertEqual(
            status.message,
            "Files could not hand the selection back to the app.\nThe selected attachment is not available.\nIn Files, download the file locally first, then try again."
        )
        XCTAssertTrue(status.needsAttention)
        XCTAssertEqual(status.autoDismissDelayMilliseconds, 9_000)
        XCTAssertEqual(
            status.accessibilityLabel,
            "Files could not open. Files could not hand the selection back to the app. The selected attachment is not available. In Files, download the file locally first, then try again."
        )
    }

    func testImportErrorRecognizesUserCanceledFilesPicker() {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
        let providerError = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError)

        XCTAssertTrue(cancelError.isUserCanceledImport)
        XCTAssertFalse(providerError.isUserCanceledImport)
    }

    func testRenameDraftTrimsNames() {
        var draft = WorkspaceRenameDraft.project(MusicProject.freshProject)
        draft.text = "  new hook pass  "

        XCTAssertEqual(draft.trimmedText, "new hook pass")
    }

    func testRenameDraftSupportsAttachments() {
        let trackID = UUID()
        let attachment = SongAttachment(
            id: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!,
            kind: "PDF",
            name: "lyrics.pdf",
            category: "Lyrics",
            subtitle: "May 24",
            size: "12 KB",
            localFileName: "local-lyrics.pdf"
        )

        let draft = WorkspaceAttachmentDraft.attachment(attachment, trackID: trackID)

        XCTAssertEqual(draft.id, "attachment-\(trackID.uuidString)-\(attachment.id.uuidString)")
        XCTAssertEqual(draft.trackID, trackID)
        XCTAssertEqual(draft.attachmentID, attachment.id)
        XCTAssertEqual(draft.name, "lyrics.pdf")
        XCTAssertEqual(draft.category, "Lyrics")
    }

    func testSongTextDraftTrimsInput() {
        let trackID = UUID()
        let document = SongTextDocument(kind: .lyrics, text: "  first line  ")

        let draft = WorkspaceSongTextDraft.document(document, trackID: trackID)

        XCTAssertEqual(draft.id, "song-text-\(trackID.uuidString)-lyrics")
        XCTAssertEqual(draft.trackID, trackID)
        XCTAssertEqual(draft.kind, .lyrics)
        XCTAssertEqual(draft.trimmedText, "first line")
    }

    func testExportItemReportsAvailability() {
        let emptyExport = WorkspaceExportItem(
            id: "empty",
            kind: .track,
            title: "Export",
            files: []
        )
        let fileExport = WorkspaceExportItem(
            id: "file",
            kind: .track,
            title: "Export",
            files: [URL(fileURLWithPath: "/tmp/bounce.wav")]
        )

        XCTAssertFalse(emptyExport.hasFiles)
        XCTAssertTrue(fileExport.hasFiles)
        XCTAssertEqual(fileExport.subtitle, "bounce.wav")
    }

    func testWorkspaceExportBuilderBuildsProjectExportWithSongFiles() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let sourceAudioURL = storeRoot.appending(path: "rough bounce.wav")
        let sourceAttachmentURL = storeRoot.appending(path: "session notes.pdf")
        try Data("audio".utf8).write(to: sourceAudioURL)
        try Data("attachment".utf8).write(to: sourceAttachmentURL)

        let audioLocalFileName = try store.copyAudioIntoLibrary(from: sourceAudioURL)
        let attachmentLocalFileName = try store.copyAttachmentIntoLibrary(from: sourceAttachmentURL)
        let attachment = SongAttachment.imported(
            from: sourceAttachmentURL,
            localFileName: attachmentLocalFileName,
            fileSize: store.fileSize(forAttachmentLocalFileName: attachmentLocalFileName)
        )
        let track = MusicTrack(
            id: UUID(uuidString: "11111111-aaaa-bbbb-cccc-111111111111")!,
            title: "Hook / Verse?",
            date: "May 25",
            duration: "1:23",
            localFileName: audioLocalFileName,
            attachments: [attachment],
            textDocuments: [
                SongTextDocument(kind: .notes, text: "Arrangement note"),
                SongTextDocument(kind: .lyrics)
            ]
        )
        let project = MusicProject(
            id: UUID(uuidString: "22222222-aaaa-bbbb-cccc-222222222222")!,
            title: "Exportable Sleeve",
            creator: "Draft",
            trackCount: 1,
            runtime: "1:23",
            sleeve: .blank,
            state: .regular,
            tracks: [track]
        )

        let result = WorkspaceExportBuilder(libraryStore: store).projectExportItem(for: project)
        let fileNames = result.item.files.map(\.lastPathComponent)

        XCTAssertEqual(result.failedTextExportCount, 0)
        XCTAssertEqual(result.item.kind, .project)
        XCTAssertEqual(result.item.title, "Export Exportable Sleeve")
        XCTAssertEqual(result.item.files.count, 3)
        XCTAssertTrue(result.item.id.hasPrefix("project-\(project.id.uuidString)-3"))
        XCTAssertTrue(fileNames.contains { $0.hasSuffix("rough bounce.wav") })
        XCTAssertTrue(fileNames.contains { $0.hasSuffix("session notes.pdf") })
        XCTAssertTrue(fileNames.contains("Hook_-_Verse-notes.txt"))
    }

    func testWorkspaceExportBuilderSeparatesTrackAndSongExports() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let sourceAudioURL = storeRoot.appending(path: "mix aif.aif")
        let sourceAttachmentURL = storeRoot.appending(path: "logic session.zip")
        try Data("audio".utf8).write(to: sourceAudioURL)
        try Data("attachment".utf8).write(to: sourceAttachmentURL)

        let audioLocalFileName = try store.copyAudioIntoLibrary(from: sourceAudioURL)
        let attachmentLocalFileName = try store.copyAttachmentIntoLibrary(from: sourceAttachmentURL)
        let trackID = UUID(uuidString: "33333333-aaaa-bbbb-cccc-333333333333")!
        let track = MusicTrack(
            id: trackID,
            title: "Mix A",
            date: "May 25",
            duration: "2:45",
            localFileName: audioLocalFileName,
            attachments: [
                SongAttachment.imported(
                    from: sourceAttachmentURL,
                    localFileName: attachmentLocalFileName,
                    fileSize: store.fileSize(forAttachmentLocalFileName: attachmentLocalFileName)
                )
            ],
            textDocuments: [
                SongTextDocument(kind: .lyrics, text: "hook line")
            ]
        )
        let builder = WorkspaceExportBuilder(libraryStore: store)

        let trackResult = builder.trackExportItem(for: track, kind: .track)
        let songResult = builder.trackExportItem(for: track, kind: .song)

        XCTAssertEqual(trackResult.item.kind, .track)
        XCTAssertEqual(trackResult.item.id, "track-\(trackID.uuidString)-1")
        XCTAssertEqual(trackResult.item.files.count, 1)
        XCTAssertEqual(songResult.item.kind, .song)
        XCTAssertEqual(songResult.item.id, "song-\(trackID.uuidString)-3")
        XCTAssertEqual(songResult.item.files.count, 3)
        XCTAssertEqual(songResult.failedTextExportCount, 0)
        XCTAssertTrue(songResult.item.files.map(\.lastPathComponent).contains("Mix_A-lyrics.txt"))
    }

    func testImportedTrackCodableRoundTripPreservesLocalFileName() throws {
        let track = MusicTrack.imported(
            from: URL(fileURLWithPath: "/tmp/bounce_v1.wav"),
            localFileName: "local-bounce.wav"
        )

        let data = try JSONEncoder().encode(track)
        let decodedTrack = try JSONDecoder().decode(MusicTrack.self, from: data)

        XCTAssertEqual(decodedTrack, track)
    }

    func testImportedTrackDecodesLegacyPayloadWithoutMarkersAndAttachments() throws {
        let data = Data("""
        {
          "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          "title": "Legacy bounce",
          "date": "May 24",
          "duration": "Imported",
          "localFileName": "legacy.wav"
        }
        """.utf8)

        let decodedTrack = try JSONDecoder().decode(MusicTrack.self, from: data)

        XCTAssertEqual(decodedTrack.title, "Legacy bounce")
        XCTAssertEqual(decodedTrack.attachments, [])
        XCTAssertEqual(decodedTrack.markers, [])
        XCTAssertEqual(decodedTrack.textDocuments, SongTextDocument.emptySet)
        XCTAssertNil(decodedTrack.artistName)
        XCTAssertNil(decodedTrack.audioFormat)
    }

    func testImportedTrackCodableRoundTripPreservesMarkers() throws {
        var track = MusicTrack.imported(
            from: URL(fileURLWithPath: "/tmp/bounce_v1.wav"),
            localFileName: "local-bounce.wav"
        )
        track.markers = [
            WaveformMarker(
                id: UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!,
                position: 0.25,
                height: 0.7,
                colorToken: .mint,
                isResolved: true,
                time: "0:46",
                note: "Mute the pickup."
            )
        ]

        let data = try JSONEncoder().encode(track)
        let decodedTrack = try JSONDecoder().decode(MusicTrack.self, from: data)

        XCTAssertEqual(decodedTrack.markers, track.markers)
    }

    func testImportedTrackCodableRoundTripPreservesSongTextDocuments() throws {
        var track = MusicTrack.imported(
            from: URL(fileURLWithPath: "/tmp/bounce_v1.wav"),
            localFileName: "local-bounce.wav"
        )
        track.textDocuments = SongTextDocument.normalizedSet(from: [
            SongTextDocument(kind: .notes, text: "Ask producer about second verse."),
            SongTextDocument(kind: .lyrics, text: "Hold me back / let it fall")
        ])

        let data = try JSONEncoder().encode(track)
        let decodedTrack = try JSONDecoder().decode(MusicTrack.self, from: data)

        XCTAssertEqual(decodedTrack.textDocuments, track.textDocuments)
    }

    func testStudioSearchMatchesSongTextAttachmentsAndMarkers() {
        var track = MusicTrack.imported(
            from: URL(fileURLWithPath: "/tmp/hook_bounce.wav"),
            localFileName: "local-hook.wav"
        )
        track.attachments = [
            SongAttachment(
                id: UUID(),
                kind: "PDF",
                name: "reference.pdf",
                category: "References",
                subtitle: "May 24",
                size: "9 KB",
                localFileName: "reference.pdf"
            )
        ]
        track.textDocuments = SongTextDocument.normalizedSet(from: [
            SongTextDocument(kind: .notes, text: "Try half-time drums in the bridge."),
            SongTextDocument(kind: .lyrics, text: "silver line on the way home")
        ])
        track.markers = [
            WaveformMarker.created(position: 0.5, time: "1:00", existingCount: 0, note: "tighten pre-hook")
        ]

        XCTAssertTrue(track.matchesStudioSearch("half-time"))
        XCTAssertTrue(track.matchesStudioSearch("silver line"))
        XCTAssertTrue(track.matchesStudioSearch("references"))
        XCTAssertTrue(track.matchesStudioSearch("pre-hook"))
        XCTAssertFalse(track.matchesStudioSearch("kick folder"))
        XCTAssertEqual([track].filteredByStudioSearch("bridge").map(\.id), [track.id])
    }

    func testWaveformMarkerDecodesLegacyPayloadWithoutResolvedState() throws {
        let data = Data("""
        {
          "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
          "position": 0.35,
          "height": 0.7,
          "colorToken": "gold",
          "category": "hook",
          "time": "1:04",
          "note": "Old marker"
        }
        """.utf8)

        let marker = try JSONDecoder().decode(WaveformMarker.self, from: data)

        XCTAssertFalse(marker.isResolved)
        XCTAssertEqual(marker.colorToken, .gold)
        XCTAssertEqual(marker.note, "Old marker")
    }

    func testSongAttachmentBuildsReadableMetadata() {
        let attachment = SongAttachment.imported(
            from: URL(fileURLWithPath: "/tmp/session_folder/lead_vocal.ptx"),
            localFileName: "local-lead-vocal.ptx",
            fileSize: 1_500_000
        )

        XCTAssertEqual(attachment.kind, "PTX")
        XCTAssertEqual(attachment.name, "lead_vocal.ptx")
        XCTAssertEqual(attachment.category, "Session")
        XCTAssertEqual(attachment.localFileName, "local-lead-vocal.ptx")
        XCTAssertFalse(attachment.size.isEmpty)
    }

    func testSongAttachmentDecodesLegacyPayloadWithoutCategory() throws {
        let data = Data("""
        {
          "id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
          "kind": "PDF",
          "name": "lyrics.pdf",
          "subtitle": "May 24",
          "size": "12 KB",
          "localFileName": "local-lyrics.pdf"
        }
        """.utf8)

        let attachment = try JSONDecoder().decode(SongAttachment.self, from: data)

        XCTAssertEqual(attachment.category, "Notes")
    }

    func testSongAttachmentCategoryFiltersAreSortedAndCaseInsensitive() {
        let attachments = [
            SongAttachment(
                id: UUID(),
                kind: "WAV",
                name: "bounce.wav",
                category: "Audio",
                subtitle: "May 24",
                size: "1 MB",
                localFileName: "local-bounce.wav"
            ),
            SongAttachment(
                id: UUID(),
                kind: "PDF",
                name: "lyrics.pdf",
                category: "Notes",
                subtitle: "May 24",
                size: "12 KB",
                localFileName: "local-lyrics.pdf"
            ),
            SongAttachment(
                id: UUID(),
                kind: "TXT",
                name: "idea.txt",
                category: "notes",
                subtitle: "May 24",
                size: "4 KB",
                localFileName: "local-idea.txt"
            )
        ]

        XCTAssertEqual(attachments.studioCategoryFilters, ["All", "Audio", "Notes"])
        XCTAssertEqual(attachments.filteredByStudioCategory("NOTES").map(\.name), ["lyrics.pdf", "idea.txt"])
        XCTAssertEqual(attachments.filteredByStudioCategory(AttachmentCategoryFilter.all).count, 3)
    }

    func testSongAttachmentCategorySectionsAreSortedAndGrouped() {
        let attachments = [
            SongAttachment(
                id: UUID(),
                kind: "TXT",
                name: "idea.txt",
                category: "Notes",
                subtitle: "May 24",
                size: "4 KB",
                localFileName: "local-idea.txt"
            ),
            SongAttachment(
                id: UUID(),
                kind: "WAV",
                name: "bounce.wav",
                category: "Audio",
                subtitle: "May 24",
                size: "2 MB",
                localFileName: "local-bounce.wav"
            ),
            SongAttachment(
                id: UUID(),
                kind: "PDF",
                name: "lyrics.pdf",
                category: "Notes",
                subtitle: "May 24",
                size: "12 KB",
                localFileName: "local-lyrics.pdf"
            )
        ]

        let sections = attachments.studioCategorySections

        XCTAssertEqual(sections.map(\.title), ["Audio", "Notes"])
        XCTAssertEqual(sections.first?.attachments.map(\.name), ["bounce.wav"])
        XCTAssertEqual(sections.last?.attachments.map(\.name), ["idea.txt", "lyrics.pdf"])
    }

    func testMusicLibraryStorePersistsProjects() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let store = MusicLibraryStore(documentsURL: storeRoot)
        var project = MusicProject.freshProject
        project.title = "saved sleeve"
        project.state = .regular
        project.tracks = [
            MusicTrack.imported(
                from: URL(fileURLWithPath: "/tmp/saved_bounce.wav"),
                localFileName: "saved-bounce.wav"
            )
        ]
        project.trackCount = project.tracks.count

        try store.saveProjects([project])

        XCTAssertEqual(store.loadProjects(), [project])
    }

    func testMusicLibraryStoreStartsWithCleanEmptyLibrary() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let store = MusicLibraryStore(documentsURL: storeRoot)

        XCTAssertEqual(store.loadProjects(), [])
    }

    func testMusicLibraryStoreRemovesLegacySeedProjects() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let legacyProject = MusicProject(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "old screenshot seed",
            creator: "Draft",
            trackCount: 0,
            runtime: "",
            sleeve: .blank,
            state: .regular,
            tracks: []
        )

        try store.saveProjects([legacyProject])

        XCTAssertEqual(store.loadProjects(), [])
    }

    func testMusicLibraryStoreDoesNotPersistFreshDiscStageProjects() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let regularProject = makeProject(title: "Committed sleeve")
        var freshProject = MusicProject.freshProject
        freshProject.id = UUID()

        try store.saveProjects([freshProject, regularProject])

        XCTAssertEqual(store.loadProjects().map(\.id), [regularProject.id])
    }

    func testMusicLibraryStoreDropsPreviouslyPersistedFreshDiscStageProjects() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let regularProject = makeProject(title: "Recovered sleeve")
        var staleFreshProject = MusicProject.freshProject
        staleFreshProject.id = UUID()

        let libraryDirectory = storeRoot.appending(path: "Library", directoryHint: .isDirectory)
        let libraryFile = libraryDirectory.appending(path: "projects.json", directoryHint: .notDirectory)
        try FileManager.default.createDirectory(at: libraryDirectory, withIntermediateDirectories: true)
        let stalePayload = try JSONEncoder().encode([staleFreshProject, regularProject])
        try stalePayload.write(to: libraryFile, options: .atomic)

        XCTAssertEqual(store.loadProjects().map(\.id), [regularProject.id])
    }

    func testMusicLibraryStoreCopiesAudioAndResolvesLocalURL() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let sourceURL = storeRoot.appending(path: "source.wav")
        try Data("fake audio".utf8).write(to: sourceURL)

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let localFileName = try store.copyAudioIntoLibrary(from: sourceURL)
        let track = MusicTrack.imported(from: sourceURL, localFileName: localFileName)

        let resolvedURL = try XCTUnwrap(store.audioURL(for: track))
        XCTAssertTrue(FileManager.default.fileExists(atPath: resolvedURL.path))
        XCTAssertTrue(resolvedURL.lastPathComponent.hasSuffix("source.wav"))
    }

    @MainActor
    func testWorkspaceImportProcessorCopiesAudioAndSkipsDuplicates() async throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let duplicateURL = storeRoot.appending(path: "Main_Bounce_v9.wav")
        let newURL = storeRoot.appending(path: "Hook_Idea.aif")
        try Data("existing audio".utf8).write(to: duplicateURL)
        try Data("new audio".utf8).write(to: newURL)

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let existingTrack = MusicTrack.imported(from: duplicateURL, localFileName: "existing-main.wav")
        let result = await WorkspaceImportProcessor(libraryStore: store)
            .importAudioFiles([duplicateURL, newURL], existingTracks: [existingTrack])

        XCTAssertEqual(result.importedTracks.count, 1)
        XCTAssertEqual(result.importedTracks.first?.title, "Hook Idea")
        XCTAssertEqual(result.duplicateCount, 1)
        XCTAssertTrue(result.failedFileNames.isEmpty)
        XCTAssertEqual(
            result.status,
            .success(kind: .audio, imported: 1, failedFileNames: [], skippedDuplicates: 1)
        )

        let localFileName = try XCTUnwrap(result.importedTracks.first?.localFileName)
        XCTAssertNotNil(store.audioURL(forAudioLocalFileName: localFileName))
    }

    @MainActor
    func testWorkspaceImportProcessorSkipsDuplicateAudioInsideSamePickerBatch() async throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let sourceURL = storeRoot.appending(path: "Same_Bounce.wav")
        try Data("same audio".utf8).write(to: sourceURL)

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let result = await WorkspaceImportProcessor(libraryStore: store)
            .importAudioFiles([sourceURL, sourceURL], existingTracks: [])

        XCTAssertEqual(result.importedTracks.count, 1)
        XCTAssertEqual(result.importedTracks.first?.title, "Same Bounce")
        XCTAssertEqual(result.duplicateCount, 1)
        XCTAssertTrue(result.failedFileNames.isEmpty)
        XCTAssertEqual(
            result.status,
            .success(kind: .audio, imported: 1, failedFileNames: [], skippedDuplicates: 1)
        )
    }

    @MainActor
    func testWorkspaceImportProcessorRejectsUnsupportedAudioFiles() async throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let textURL = storeRoot.appending(path: "lyrics.txt")
        let audioURL = storeRoot.appending(path: "scratch_loop.wav")
        try Data("not audio".utf8).write(to: textURL)
        try Data("fake audio".utf8).write(to: audioURL)

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let result = await WorkspaceImportProcessor(libraryStore: store)
            .importAudioFiles([textURL, audioURL], existingTracks: [])

        XCTAssertEqual(result.importedTracks.count, 1)
        XCTAssertEqual(result.importedTracks.first?.title, "scratch loop")
        XCTAssertEqual(result.failedFileNames, ["lyrics.txt"])
        XCTAssertEqual(result.duplicateCount, 0)
        XCTAssertEqual(
            result.status,
            .success(kind: .audio, imported: 1, failedFileNames: ["lyrics.txt"], skippedDuplicates: 0)
        )
    }

    @MainActor
    func testWorkspaceImportFlowReportsEmptyAudioPickerResultAsVisibleFailure() async throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        var finishedStatus: WorkspaceImportStatus?
        var loadingStatus: WorkspaceImportStatus?
        var toastMessages: [String] = []
        var appendedTracks: [MotionReveal.MusicTrack] = []

        let flow = WorkspaceImportFlow(
            libraryStore: MusicLibraryStore(documentsURL: storeRoot),
            existingAudioTracks: [],
            targetAttachmentTrackID: nil,
            setImportStatus: { loadingStatus = $0 },
            finishImport: { finishedStatus = $0 },
            showToast: { toastMessages.append($0) },
            appendImportedTracks: { appendedTracks.append(contentsOf: $0) },
            appendAttachments: { _, _ in },
            presentAudioImporter: {}
        )

        await flow.importAudioFiles([])

        XCTAssertNil(loadingStatus)
        XCTAssertEqual(finishedStatus, .failure(kind: .audio, failedFileNames: []))
        XCTAssertTrue(toastMessages.isEmpty)
        XCTAssertTrue(appendedTracks.isEmpty)
    }

    @MainActor
    func testWorkspaceImportFlowReportsEmptyAttachmentPickerResultAsVisibleFailure() async throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let trackID = UUID()
        var finishedStatus: WorkspaceImportStatus?
        var loadingStatus: WorkspaceImportStatus?
        var toastMessages: [String] = []
        var appendedAttachments: [SongAttachment] = []

        let flow = WorkspaceImportFlow(
            libraryStore: MusicLibraryStore(documentsURL: storeRoot),
            existingAudioTracks: [],
            targetAttachmentTrackID: trackID,
            setImportStatus: { loadingStatus = $0 },
            finishImport: { finishedStatus = $0 },
            showToast: { toastMessages.append($0) },
            appendImportedTracks: { _ in },
            appendAttachments: { attachments, _ in appendedAttachments.append(contentsOf: attachments) },
            presentAudioImporter: {}
        )

        await flow.importAttachmentFiles([])

        XCTAssertNil(loadingStatus)
        XCTAssertEqual(finishedStatus, .failure(kind: .attachment, failedFileNames: []))
        XCTAssertTrue(toastMessages.isEmpty)
        XCTAssertTrue(appendedAttachments.isEmpty)
    }

    func testWorkspaceImportFlowTriggersFirstImportHandoffOnlyForFirstProjectImport() {
        XCTAssertTrue(
            WorkspaceImportFlow.shouldTriggerFirstImportHandoff(
                existingTrackCount: 0,
                importedTrackCount: 1,
                isProjectScreen: true,
                isSongContainerOpen: false
            )
        )
        XCTAssertFalse(
            WorkspaceImportFlow.shouldTriggerFirstImportHandoff(
                existingTrackCount: 1,
                importedTrackCount: 1,
                isProjectScreen: true,
                isSongContainerOpen: false
            )
        )
        XCTAssertFalse(
            WorkspaceImportFlow.shouldTriggerFirstImportHandoff(
                existingTrackCount: 0,
                importedTrackCount: 1,
                isProjectScreen: false,
                isSongContainerOpen: false
            )
        )
        XCTAssertFalse(
            WorkspaceImportFlow.shouldTriggerFirstImportHandoff(
                existingTrackCount: 0,
                importedTrackCount: 1,
                isProjectScreen: true,
                isSongContainerOpen: true
            )
        )
    }

    func testWorkspaceImportSelectionKeepsPickedURLsForAsyncImport() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let audioURL = storeRoot.appending(path: "selected.wav")
        let attachmentURL = storeRoot.appending(path: "notes.pdf")
        try Data("audio".utf8).write(to: audioURL)
        try Data("notes".utf8).write(to: attachmentURL)

        let selection = WorkspaceImportSelection(urls: [audioURL, attachmentURL])
        defer { selection.stopAccessing() }

        XCTAssertEqual(selection.urls, [audioURL, attachmentURL])
        XCTAssertLessThanOrEqual(selection.securityScopedURLCount, selection.urls.count)
    }

    func testWorkspaceImportContentPolicyScopesAudioPickerToAudioFiles() {
        XCTAssertEqual(WorkspaceImportContentPolicy.audioPickerTypes, [.audio])
        XCTAssertEqual(WorkspaceImportContentPolicy.attachmentPickerTypes, [.item])
        XCTAssertTrue(WorkspaceImportContentPolicy.audioAllowsMultipleSelection)
        XCTAssertTrue(WorkspaceImportContentPolicy.attachmentAllowsMultipleSelection)
    }

    func testMusicLibraryStoreCopiesAttachmentsAndReportsSize() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let sourceURL = storeRoot.appending(path: "session.ptx")
        try Data("fake session".utf8).write(to: sourceURL)

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let localFileName = try store.copyAttachmentIntoLibrary(from: sourceURL)

        XCTAssertTrue(localFileName.hasSuffix("session.ptx"))
        XCTAssertEqual(store.fileSize(forAttachmentLocalFileName: localFileName), 12)
    }

    func testWorkspaceImportProcessorCopiesAttachmentsAndReportsFailures() async throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let sourceURL = storeRoot.appending(path: "session.ptx")
        let missingURL = storeRoot.appending(path: "missing.pdf")
        try Data("fake session".utf8).write(to: sourceURL)

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let result = await WorkspaceImportProcessor(libraryStore: store)
            .importAttachmentFiles([sourceURL, missingURL])

        XCTAssertEqual(result.attachments.count, 1)
        XCTAssertEqual(result.attachments.first?.name, "session.ptx")
        XCTAssertEqual(result.failedFileNames, ["missing.pdf"])
        XCTAssertEqual(
            result.status,
            .success(kind: .attachment, imported: 1, failedFileNames: ["missing.pdf"], skippedDuplicates: 0)
        )
    }

    @MainActor
    func testWorkspaceImportProcessorCopiesImageProjectCover() async throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let coverURL = storeRoot.appending(path: "album-cover.png")
        try Self.makeSolidImagePNG(at: coverURL)

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let result = await WorkspaceImportProcessor(libraryStore: store)
            .importProjectCoverFile([coverURL])

        XCTAssertNil(result.motionArtwork)
        let sleeve = try XCTUnwrap(result.sleeve)

        if case let .customImage(localFileName, sourceFileName) = sleeve {
            XCTAssertEqual(sourceFileName, "album-cover.png")
            XCTAssertTrue(FileManager.default.fileExists(
                atPath: storeRoot.appending(path: "ProjectArtwork", directoryHint: .isDirectory)
                    .appending(path: localFileName, directoryHint: .notDirectory).path
            ))
        } else {
            XCTFail("Expected a custom image sleeve")
        }

        XCTAssertTrue(result.failedFileNames.isEmpty)
    }

    @MainActor
    func testWorkspaceImportProcessorCopiesVideoProjectCover() async throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let coverURL = storeRoot.appending(path: "album-cover.mp4")
        try await Self.makeAnimatedArtworkVideo(
            at: coverURL,
            durationSeconds: 3,
            frameSize: CGSize(width: 96, height: 96)
        )

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let result = await WorkspaceImportProcessor(libraryStore: store)
            .importProjectCoverFile([coverURL])

        XCTAssertNil(result.sleeve)
        let motionArtwork = try XCTUnwrap(result.motionArtwork)
        XCTAssertEqual(motionArtwork.sourceFileName, "album-cover.mp4")
        XCTAssertEqual(motionArtwork.variant, .square)
        XCTAssertNotNil(store.animatedArtworkURL(for: motionArtwork))
        XCTAssertTrue(result.failedFileNames.isEmpty)
    }

    func testWorkspaceImportProcessorHonorsCancellationBeforeCopying() async throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let audioURL = storeRoot.appending(path: "canceled-bounce.wav")
        let attachmentURL = storeRoot.appending(path: "canceled-session.ptx")
        try Data("audio".utf8).write(to: audioURL)
        try Data("session".utf8).write(to: attachmentURL)

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let audioTask = Task {
            await WorkspaceImportProcessor(libraryStore: store)
                .importAudioFiles([audioURL], existingTracks: [])
        }
        audioTask.cancel()

        let attachmentTask = Task {
            await WorkspaceImportProcessor(libraryStore: store)
                .importAttachmentFiles([attachmentURL])
        }
        attachmentTask.cancel()

        let audioResult = await audioTask.value
        let attachmentResult = await attachmentTask.value

        XCTAssertTrue(audioResult.importedTracks.isEmpty)
        XCTAssertTrue(audioResult.failedFileNames.isEmpty)
        XCTAssertEqual(audioResult.duplicateCount, 0)
        XCTAssertTrue(attachmentResult.attachments.isEmpty)
        XCTAssertTrue(attachmentResult.failedFileNames.isEmpty)
    }

    func testWorkspaceImportProcessorCopiesValidAnimatedArtwork() async throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let artworkURL = storeRoot.appending(path: "portrait-loop.mp4")
        try await Self.makeAnimatedArtworkVideo(
            at: artworkURL,
            durationSeconds: 4,
            frameSize: CGSize(width: 72, height: 120)
        )

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let result = await WorkspaceImportProcessor(libraryStore: store)
            .importAnimatedArtworkFile([artworkURL])

        let artwork = try XCTUnwrap(result.artwork)
        XCTAssertTrue(result.failedFileNames.isEmpty)
        XCTAssertEqual(artwork.sourceFileName, "portrait-loop.mp4")
        XCTAssertEqual(artwork.variant, .portrait)
        XCTAssertNotNil(store.animatedArtworkURL(for: artwork))
    }

    func testWorkspaceImportProcessorRejectsAnimatedArtworkLongerThanLimit() async throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let artworkURL = storeRoot.appending(path: "too-long-loop.mp4")
        try await Self.makeAnimatedArtworkVideo(
            at: artworkURL,
            durationSeconds: 16.5,
            frameSize: CGSize(width: 96, height: 96)
        )

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let result = await WorkspaceImportProcessor(libraryStore: store)
            .importAnimatedArtworkFile([artworkURL])

        XCTAssertNil(result.artwork)
        XCTAssertEqual(result.failedFileNames.count, 1)
        XCTAssertTrue(result.failedFileNames[0].hasPrefix("too-long-loop.mp4: longer than 0:15 limit"))
        let importedDirectory = storeRoot.appending(path: "AnimatedArtwork", directoryHint: .isDirectory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: importedDirectory.path))
    }

    func testWorkspaceImportProcessorRejectsAnimatedArtworkLargerThanLimit() async throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let artworkURL = storeRoot.appending(path: "oversized-loop.mp4")
        try Data(count: 26_200_000).write(to: artworkURL)

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let result = await WorkspaceImportProcessor(libraryStore: store)
            .importAnimatedArtworkFile([artworkURL])

        XCTAssertNil(result.artwork)
        XCTAssertEqual(result.failedFileNames, ["oversized-loop.mp4: exceeds 25 MB limit (26.2 MB)"])
        let importedDirectory = storeRoot.appending(path: "AnimatedArtwork", directoryHint: .isDirectory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: importedDirectory.path))
    }

    func testMusicLibraryStoreResolvesAndRemovesAttachments() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let sourceURL = storeRoot.appending(path: "lyrics.pdf")
        try Data("fake lyrics".utf8).write(to: sourceURL)

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let localFileName = try store.copyAttachmentIntoLibrary(from: sourceURL)
        let attachment = SongAttachment.imported(from: sourceURL, localFileName: localFileName, fileSize: nil)

        let resolvedURL = try XCTUnwrap(store.attachmentURL(for: attachment))
        XCTAssertTrue(FileManager.default.fileExists(atPath: resolvedURL.path))

        try store.removeAttachmentFromLibrary(localFileName: localFileName)

        XCTAssertNil(store.attachmentURL(for: attachment))
        XCTAssertFalse(FileManager.default.fileExists(atPath: resolvedURL.path))
        XCTAssertNoThrow(try store.removeAttachmentFromLibrary(localFileName: localFileName))
    }

    func testMusicLibraryStoreWritesSongTextExports() throws {
        let storeRoot = try makeTemporaryStoreRoot()
        defer { try? FileManager.default.removeItem(at: storeRoot) }

        let store = MusicLibraryStore(documentsURL: storeRoot)
        let track = MusicTrack(
            id: UUID(),
            title: "Hook / Verse?",
            date: "May 24",
            duration: "Imported"
        )
        let lyrics = SongTextDocument(kind: .lyrics, text: "  first line\nsecond line  ")
        let emptyNotes = SongTextDocument(kind: .notes)

        let exportURL = try XCTUnwrap(store.textExportURL(for: track, document: lyrics))
        let content = try String(contentsOf: exportURL, encoding: .utf8)

        XCTAssertEqual(exportURL.lastPathComponent, "Hook_-_Verse-lyrics.txt")
        XCTAssertTrue(content.contains("Hook / Verse?"))
        XCTAssertTrue(content.contains("Lyrics"))
        XCTAssertTrue(content.contains("first line\nsecond line"))
        XCTAssertNil(try store.textExportURL(for: track, document: emptyNotes))
    }

    func testSampleMarkersStayInsideWaveformBounds() {
        for marker in WaveformMarker.sampleMarkers {
            XCTAssertGreaterThanOrEqual(marker.position, 0.0)
            XCTAssertLessThanOrEqual(marker.position, 1.0)
            XCTAssertGreaterThan(marker.height, 0.0)
            XCTAssertFalse(marker.colorToken.title.isEmpty)
            XCTAssertFalse(marker.colorToken.symbolName.isEmpty)
            XCTAssertFalse(marker.time.isEmpty)
            XCTAssertFalse(marker.note.isEmpty)
        }
    }

    func testMarkerColorTokensHaveDistinctNonColorSymbols() {
        let symbols = Set(WaveformMarkerColorToken.allCases.map(\.symbolName))

        XCTAssertEqual(symbols.count, WaveformMarkerColorToken.allCases.count)
    }

    func testCreatedMarkerCyclesColorAndClampsPosition() {
        let marker = WaveformMarker.created(
            position: 2,
            time: "1:11",
            existingCount: 3
        )

        XCTAssertEqual(marker.position, 1)
        XCTAssertEqual(marker.colorToken, .mint)
        XCTAssertFalse(marker.isResolved)
        XCTAssertEqual(marker.time, "1:11")
        XCTAssertEqual(marker.note, "")
    }

    func testMarkerAccessibilitySummaryIncludesStatusShapeTimeAndUserNote() {
        var marker = WaveformMarker.created(
            position: 0.4,
            time: "0:40",
            existingCount: 2,
            note: "  tighten hook  "
        )
        marker.isResolved = true

        XCTAssertEqual(marker.colorToken, .blue)
        XCTAssertEqual(
            marker.accessibilitySummary,
            "Resolved blue marker at 0:40, note: tighten hook"
        )
    }

    func testBlankMarkerAccessibilitySummaryDoesNotInventUserMeaning() {
        let marker = WaveformMarker.created(
            position: 0.1,
            time: "0:10",
            existingCount: 0
        )

        XCTAssertEqual(
            marker.accessibilitySummary,
            "Open rose marker at 0:10, no note"
        )
    }

    func testWaveformMarkerFiltersUseStatusAndUserNotes() {
        let openBlank = WaveformMarker.created(position: 0.2, time: "0:20", existingCount: 0)
        var openNoted = WaveformMarker.created(position: 0.4, time: "0:40", existingCount: 1, note: "  tighten hook  ")
        openNoted.isResolved = false
        var resolvedNoted = WaveformMarker.created(position: 0.6, time: "1:00", existingCount: 2, note: "done")
        resolvedNoted.isResolved = true

        let markers = [openBlank, openNoted, resolvedNoted]

        XCTAssertEqual(markers.filtered(by: .all).map(\.id), markers.map(\.id))
        XCTAssertEqual(markers.filtered(by: .open).map(\.id), [openBlank.id, openNoted.id])
        XCTAssertEqual(markers.filtered(by: .resolved).map(\.id), [resolvedNoted.id])
        XCTAssertEqual(markers.filtered(by: .noted).map(\.id), [openNoted.id, resolvedNoted.id])
        XCTAssertEqual(markers.count(for: .noted), 2)
    }

    func testMarkerTouchMetricsRespectMinimumIOSHitTargets() {
        XCTAssertGreaterThanOrEqual(MarkerTouchMetrics.waveformMarkerHitWidth, MarkerTouchMetrics.minimumTouchTarget)
        XCTAssertGreaterThanOrEqual(MarkerTouchMetrics.markerFilterHitHeight, MarkerTouchMetrics.minimumTouchTarget)
        XCTAssertGreaterThanOrEqual(MarkerTouchMetrics.minimumTouchTarget, 44)
        XCTAssertLessThanOrEqual(MarkerTouchMetrics.compactIconVisualDiameter, MarkerTouchMetrics.minimumTouchTarget)
    }

    func testWaveformMarkerEditorCooldownIsLongerThanCaptureCooldown() {
        XCTAssertGreaterThan(
            WaveformScrubMetrics.markerEditorDismissalCooldown,
            WaveformScrubMetrics.markerCaptureCooldown
        )
        XCTAssertGreaterThanOrEqual(WaveformScrubMetrics.markerSelectionDismissalCooldown, 0.4)
    }

    func testWaveformScrubMetricsClampFractionAndDetectHorizontalScrubs() {
        XCTAssertEqual(WaveformScrubMetrics.fraction(for: -20, width: 200), 0)
        XCTAssertEqual(WaveformScrubMetrics.fraction(for: 50, width: 200), 0.25)
        XCTAssertEqual(WaveformScrubMetrics.fraction(for: 260, width: 200), 1)
        XCTAssertEqual(WaveformScrubMetrics.fraction(for: 50, width: 1), 0)

        XCTAssertFalse(WaveformScrubMetrics.shouldScrub(translation: CGSize(width: 6, height: 0)))
        XCTAssertTrue(WaveformScrubMetrics.shouldScrub(translation: CGSize(width: 24, height: 3)))
        XCTAssertFalse(WaveformScrubMetrics.shouldScrub(translation: CGSize(width: 24, height: 30)))
    }

    func testStudioDrawerTouchMetricsRespectMinimumIOSHitTargets() {
        XCTAssertGreaterThanOrEqual(StudioDrawerTouchMetrics.filterChipHeight, StudioDrawerTouchMetrics.minimumTouchTarget)
        XCTAssertGreaterThanOrEqual(StudioDrawerTouchMetrics.compactButtonHeight, StudioDrawerTouchMetrics.minimumTouchTarget)
        XCTAssertGreaterThanOrEqual(StudioDrawerTouchMetrics.minimumTouchTarget, 44)
    }

    func testSongContainerTouchMetricsRespectMinimumIOSHitTargets() {
        XCTAssertGreaterThanOrEqual(SongContainerTouchMetrics.secondaryTransportButtonSize, SongContainerTouchMetrics.minimumTouchTarget)
        XCTAssertGreaterThanOrEqual(SongContainerTouchMetrics.primaryTransportButtonSize, SongContainerTouchMetrics.minimumTouchTarget)
        XCTAssertGreaterThanOrEqual(SongContainerTouchMetrics.minimumTouchTarget, 44)
    }

    func testSongContainerLayoutKeepsCoverAsExpandedPlayerCenterpiece() {
        XCTAssertGreaterThanOrEqual(SongContainerLayoutMetrics.heroArtworkSize, 300)
        XCTAssertGreaterThan(SongContainerLayoutMetrics.heroGlowSize, SongContainerLayoutMetrics.heroArtworkSize)
        XCTAssertLessThanOrEqual(SongContainerLayoutMetrics.horizontalPadding * 2 + SongContainerLayoutMetrics.heroArtworkSize, 390)
        XCTAssertLessThanOrEqual(SongContainerLayoutMetrics.transportMinHeight, 60)
        XCTAssertLessThanOrEqual(SongContainerTouchMetrics.primaryTransportButtonSize, 50)
    }

    func testWorkspaceIconMetricsRespectMinimumIOSHitTargets() {
        XCTAssertGreaterThanOrEqual(WorkspaceIconMetrics.chromeButtonSize, WorkspaceIconMetrics.minimumTouchTarget)
        XCTAssertGreaterThanOrEqual(WorkspaceIconMetrics.standaloneActionSize, WorkspaceIconMetrics.minimumTouchTarget)
        XCTAssertGreaterThanOrEqual(WorkspaceIconMetrics.minimumTouchTarget, 44)
    }

    func testMarkerDraftTrimsInput() {
        let marker = WaveformMarker.created(position: 0.5, time: " 1:00 ", existingCount: 0)
        var draft = WorkspaceMarkerDraft(trackID: UUID(), marker: marker)
        draft.note = "  tighten hook  "
        draft.isResolved = true

        XCTAssertEqual(draft.trimmedTime, "1:00")
        XCTAssertEqual(draft.trimmedNote, "tighten hook")
        XCTAssertTrue(draft.isResolved)
        XCTAssertTrue(draft.canSave)
    }

    func testStudioAttachmentsCoverExpectedMockedFileTypes() {
        let kinds = Set(StudioAttachment.sampleAttachments.map(\.kind))

        XCTAssertTrue(kinds.isSuperset(of: ["WAV", "ZIP", "PTX", "REF", "LYR", "MIX"]))
    }

    func testIslandPullGuideMotionRespectsReduceMotion() {
        let readyMotion = IslandPullGuideMotion(isReady: true, reduceMotion: false)
        XCTAssertTrue(readyMotion.usesContinuousSpin)
        XCTAssertEqual(readyMotion.rotationDegrees, 360)

        let reducedMotion = IslandPullGuideMotion(isReady: true, reduceMotion: true)
        XCTAssertFalse(reducedMotion.usesContinuousSpin)
        XCTAssertEqual(reducedMotion.rotationDegrees, 0)

        let restingMotion = IslandPullGuideMotion(isReady: false, reduceMotion: false)
        XCTAssertFalse(restingMotion.usesContinuousSpin)
        XCTAssertEqual(restingMotion.rotationDegrees, 0)
    }

    func testCreatedAlbumDiscPromptMotionRespectsReduceMotion() {
        let resting = CreatedAlbumDiscPromptMotion(
            isReady: false,
            isPressingDisc: false,
            reduceMotion: false
        )
        let pressed = CreatedAlbumDiscPromptMotion(
            isReady: true,
            isPressingDisc: true,
            reduceMotion: false
        )
        let reducedPressed = CreatedAlbumDiscPromptMotion(
            isReady: true,
            isPressingDisc: true,
            reduceMotion: true
        )

        XCTAssertEqual(resting.discScale, 0.82)
        XCTAssertLessThan(pressed.discScale, 1)
        XCTAssertLessThan(pressed.discBrightness, 0)
        XCTAssertEqual(reducedPressed.discScale, 1)
        XCTAssertEqual(reducedPressed.discBrightness, 0)
    }

    func testBlankCDIridescenceMotionPolicyDisablesLiveMotionWhenNeeded() {
        let live = BlankCDIridescenceMotionPolicy(
            reactsToMotion: true,
            reduceMotion: false,
            launchArguments: []
        )
        let explicitStatic = BlankCDIridescenceMotionPolicy(
            reactsToMotion: false,
            reduceMotion: false,
            launchArguments: []
        )
        let reduced = BlankCDIridescenceMotionPolicy(
            reactsToMotion: true,
            reduceMotion: true,
            launchArguments: []
        )
        let uiTest = BlankCDIridescenceMotionPolicy(
            reactsToMotion: true,
            reduceMotion: false,
            launchArguments: [DebugLaunchStateReset.resetArgument]
        )

        XCTAssertTrue(live.usesLiveMotion)
        XCTAssertFalse(explicitStatic.usesLiveMotion)
        XCTAssertFalse(reduced.usesLiveMotion)
        XCTAssertFalse(uiTest.usesLiveMotion)
    }

    func testBlankCDIridescenceMaterialCouplesReflectionAndSpectrumToTilt() {
        let neutral = BlankCDIridescenceMaterial(lightX: 0, lightY: 0)
        let tilted = BlankCDIridescenceMaterial(lightX: 0.7, lightY: -0.45)

        XCTAssertEqual(neutral.lightPoint.x, 0.5)
        XCTAssertEqual(neutral.lightPoint.y, 0.42)
        XCTAssertNotEqual(neutral.lightPoint.x, tilted.lightPoint.x)
        XCTAssertNotEqual(neutral.lightPoint.y, tilted.lightPoint.y)
        XCTAssertNotEqual(neutral.spectralAngleDegrees, tilted.spectralAngleDegrees)
        XCTAssertNotEqual(neutral.reflectionBandStart.x, tilted.reflectionBandStart.x)
        XCTAssertNotEqual(neutral.reflectionBandEnd.y, tilted.reflectionBandEnd.y)
        XCTAssertGreaterThan(tilted.spectralOpacity, neutral.spectralOpacity)
        XCTAssertGreaterThan(tilted.grooveOpacity, neutral.grooveOpacity)
        XCTAssertGreaterThan(tilted.edgeAlpha, neutral.edgeAlpha)
        XCTAssertLessThan(tilted.reflectionEndRadius, neutral.reflectionEndRadius)
    }

    func testDynamicSlotPullDecisionOpensOnlyAfterIntentionalPull() {
        XCTAssertFalse(
            DynamicSlotPullDecision.shouldOpen(
                forPull: DynamicSlotPullDecision.openThreshold + 8,
                holdTime: DynamicSlotPullResponse.armHoldDuration - 0.01
            )
        )
        XCTAssertFalse(
            DynamicSlotPullDecision.shouldOpen(
                forPull: DynamicSlotPullDecision.openThreshold,
                holdTime: DynamicSlotPullResponse.armHoldDuration
            )
        )
        XCTAssertFalse(
            DynamicSlotPullDecision.shouldOpen(
                forPull: DynamicSlotPullDecision.openThreshold - 0.1,
                holdTime: DynamicSlotPullResponse.armHoldDuration
            )
        )
        XCTAssertTrue(
            DynamicSlotPullDecision.shouldOpen(
                forPull: DynamicSlotPullDecision.openThreshold + 0.1,
                holdTime: DynamicSlotPullResponse.armHoldDuration
            )
        )
    }

    func testDynamicSlotPullResponseRubberbandsVisualPullAfterThreshold() {
        let belowThreshold = DynamicSlotPullResponse(rawPull: 24, holdTime: 0)
        let beyondThreshold = DynamicSlotPullResponse(rawPull: 124, holdTime: 0.2)

        XCTAssertEqual(belowThreshold.visualPull, 24, accuracy: 0.001)
        XCTAssertLessThan(beyondThreshold.visualPull, beyondThreshold.rawPull)
        XCTAssertLessThanOrEqual(beyondThreshold.visualPull, DynamicSlotPullResponse.visualLimit)
        XCTAssertEqual(beyondThreshold.progress, 1)
        XCTAssertTrue(beyondThreshold.isArmed)
        XCTAssertTrue(beyondThreshold.shouldOpen)
    }

    func testDynamicSlotPullResponseRequiresHoldBeforeArming() {
        XCTAssertFalse(DynamicSlotPullResponse(rawPull: 4, holdTime: 0.05).isArmed)
        XCTAssertFalse(
            DynamicSlotPullResponse(
                rawPull: DynamicSlotPullResponse.openThreshold + 12,
                holdTime: DynamicSlotPullResponse.armHoldDuration - 0.01
            ).isArmed
        )
        XCTAssertFalse(
            DynamicSlotPullResponse(
                rawPull: DynamicSlotPullResponse.openThreshold + 12,
                holdTime: DynamicSlotPullResponse.armHoldDuration - 0.01
            ).shouldOpen
        )
        XCTAssertTrue(
            DynamicSlotPullResponse(
                rawPull: 4,
                holdTime: DynamicSlotPullResponse.armHoldDuration + 0.01
            ).isArmed
        )
        XCTAssertTrue(
            DynamicSlotPullResponse(
                rawPull: DynamicSlotPullResponse.openThreshold + 12,
                holdTime: DynamicSlotPullResponse.armHoldDuration + 0.01
            ).shouldOpen
        )
    }

    func testStudioDiscMaterialProfileDialsBackForReduceMotion() {
        let animated = StudioDiscMaterialProfile(faceVisibility: 1, edgeProfile: 0, reduceMotion: false)
        let reduced = StudioDiscMaterialProfile(faceVisibility: 1, edgeProfile: 0, reduceMotion: true)

        XCTAssertTrue(animated.usesAnimatedShader)
        XCTAssertFalse(reduced.usesAnimatedShader)
        XCTAssertGreaterThan(animated.foilIntensity, reduced.foilIntensity)
        XCTAssertGreaterThan(animated.shimmerIntensity, reduced.shimmerIntensity)
        XCTAssertEqual(reduced.shimmerIntensity, 0)
    }

    func testStudioDiscMaterialProfileReducesFaceEffectsAtEdgeProfile() {
        let face = StudioDiscMaterialProfile(faceVisibility: 1, edgeProfile: 0, reduceMotion: false)
        let edge = StudioDiscMaterialProfile(faceVisibility: 1, edgeProfile: 1, reduceMotion: false)

        XCTAssertLessThan(edge.foilIntensity, face.foilIntensity)
        XCTAssertLessThan(edge.shimmerIntensity, face.shimmerIntensity)
        XCTAssertGreaterThan(edge.edgeOpacity, face.edgeOpacity)
    }

    func testStudioDiscMaterialProfileClampsInputs() {
        let low = StudioDiscMaterialProfile(faceVisibility: -1, edgeProfile: -1, reduceMotion: false)
        let high = StudioDiscMaterialProfile(faceVisibility: 4, edgeProfile: 4, reduceMotion: false)

        XCTAssertFalse(low.usesAnimatedShader)
        XCTAssertGreaterThanOrEqual(low.foilIntensity, 0.10)
        XCTAssertLessThanOrEqual(high.foilIntensity, 0.46)
        XCTAssertEqual(high.edgeOpacity, 1)
    }

    func testStudioDeviceTiltDampsAndClampsMotionInput() {
        let tilt = StudioDeviceTilt(attitudePitch: .pi, attitudeRoll: -.pi, reduceMotion: false)

        XCTAssertEqual(tilt.pitchDegrees, 7)
        XCTAssertEqual(tilt.rollDegrees, -7)
    }

    func testStudioDeviceTiltScalesOutForEdgeProfileAndReduceMotion() {
        let reduced = StudioDeviceTilt(attitudePitch: 1, attitudeRoll: 1, reduceMotion: true)
        let visible = StudioDeviceTilt(pitchDegrees: 6, rollDegrees: -4)
        let edge = visible.scaled(faceVisibility: 1, edgeProfile: 1)
        let hidden = visible.scaled(faceVisibility: 0, edgeProfile: 0)

        XCTAssertEqual(reduced, .zero)
        XCTAssertEqual(edge, .zero)
        XCTAssertEqual(hidden, .zero)
        XCTAssertEqual(visible.scaled(faceVisibility: 1, edgeProfile: 0), visible)
    }

    func testStudioStarfieldPresetMatchesReferenceDensityWithoutOverdrawing() {
        XCTAssertEqual(StudioStarfieldPreset.layerCount, 3)
        XCTAssertEqual(StudioStarfieldPreset.starCount(forLayer: 0), 7)
        XCTAssertEqual(StudioStarfieldPreset.starCount(forLayer: 1), 18)
        XCTAssertEqual(StudioStarfieldPreset.starCount(forLayer: 2), 30)
        XCTAssertEqual(StudioStarfieldPreset.totalStarCount, 55)
    }

    func testStudioStarfieldPresetRespectsReduceMotion() {
        let animatedA = StudioStarfieldPreset.opacity(seed: 0.42, layer: 1, time: 0, reduceMotion: false)
        let animatedB = StudioStarfieldPreset.opacity(seed: 0.42, layer: 1, time: 1, reduceMotion: false)
        let reducedA = StudioStarfieldPreset.opacity(seed: 0.42, layer: 1, time: 0, reduceMotion: true)
        let reducedB = StudioStarfieldPreset.opacity(seed: 0.42, layer: 1, time: 1, reduceMotion: true)

        XCTAssertNotEqual(animatedA, animatedB)
        XCTAssertEqual(reducedA, reducedB)
    }

    func testPendingAppIntentRouteStoreConsumesSongContainerRouteOnce() {
        let defaults = UserDefaults.standard
        let oldValue = defaults.string(forKey: PendingAppIntentRouteStore.key)
        defer {
            if let oldValue {
                defaults.set(oldValue, forKey: PendingAppIntentRouteStore.key)
            } else {
                defaults.removeObject(forKey: PendingAppIntentRouteStore.key)
            }
        }

        PendingAppIntentRouteStore.request(.songContainer, defaults: defaults)

        XCTAssertEqual(PendingAppIntentRouteStore.consume(defaults: defaults), .songContainer)
        XCTAssertNil(PendingAppIntentRouteStore.consume(defaults: defaults))
    }

    func testPendingAppIntentRouteStoreConsumesPlaybackToggleRouteOnce() {
        let defaults = UserDefaults.standard
        let oldValue = defaults.string(forKey: PendingAppIntentRouteStore.key)
        defer {
            if let oldValue {
                defaults.set(oldValue, forKey: PendingAppIntentRouteStore.key)
            } else {
                defaults.removeObject(forKey: PendingAppIntentRouteStore.key)
            }
        }

        PendingAppIntentRouteStore.request(.togglePlayback, defaults: defaults)

        XCTAssertEqual(PendingAppIntentRouteStore.consume(defaults: defaults), .togglePlayback)
        XCTAssertNil(PendingAppIntentRouteStore.consume(defaults: defaults))
    }

    func testPendingAppIntentRouteStoreCanAcknowledgeOnlyExpectedToggleRoute() {
        let defaults = UserDefaults.standard
        let oldValue = defaults.string(forKey: PendingAppIntentRouteStore.key)
        defer {
            if let oldValue {
                defaults.set(oldValue, forKey: PendingAppIntentRouteStore.key)
            } else {
                defaults.removeObject(forKey: PendingAppIntentRouteStore.key)
            }
        }

        PendingAppIntentRouteStore.request(.songContainer, defaults: defaults)
        XCTAssertNil(PendingAppIntentRouteStore.consume(if: .togglePlayback, defaults: defaults))
        XCTAssertEqual(PendingAppIntentRouteStore.consume(defaults: defaults), .songContainer)

        PendingAppIntentRouteStore.request(.togglePlayback, defaults: defaults)
        XCTAssertEqual(PendingAppIntentRouteStore.consume(if: .togglePlayback, defaults: defaults), .togglePlayback)
        XCTAssertNil(PendingAppIntentRouteStore.consume(defaults: defaults))
    }

    func testTogglePlaybackIntentDoesNotForceAppForegroundLaunch() {
        XCTAssertFalse(TogglePlaybackIntent.openAppWhenRun)
    }

    func testIntentDarwinBridgePostsTogglePlaybackNotification() {
        let expectation = expectation(description: "Darwin toggle notification")
        let observer = MotionRevealIntentDarwinObserver {
            expectation.fulfill()
        }

        MotionRevealIntentDarwinBridge.postTogglePlayback()

        wait(for: [expectation], timeout: 2)
        withExtendedLifetime(observer) {}
    }

    func testWorkspaceDeepLinkRouteParsesSongContainerURL() throws {
        let url = try XCTUnwrap(MotionRevealDeepLink.songContainerURL)
        let route = try XCTUnwrap(WorkspaceDeepLinkRoute(url: url))

        XCTAssertEqual(route, WorkspaceDeepLinkRoute.songContainer)
        XCTAssertEqual(url.absoluteString, "motionreveal://song-container")
        XCTAssertNil(WorkspaceDeepLinkRoute(url: URL(string: "motionreveal://unknown")!))
        XCTAssertNil(WorkspaceDeepLinkRoute(url: URL(string: "https://song-container")!))
    }

    func testWorkspaceRitualTimingShortensForReduceMotion() {
        let standard = WorkspaceRitualTiming(reduceMotion: false)
        let reduced = WorkspaceRitualTiming(reduceMotion: true)

        XCTAssertLessThan(reduced.totalLoadDelayMilliseconds, standard.totalLoadDelayMilliseconds)
        XCTAssertLessThan(reduced.totalCreateDelayMilliseconds, standard.totalCreateDelayMilliseconds)
        XCTAssertLessThanOrEqual(reduced.totalLoadDelayMilliseconds, 250)
        XCTAssertLessThanOrEqual(reduced.totalCreateDelayMilliseconds, 250)
        XCTAssertLessThanOrEqual(standard.totalCreateDelayMilliseconds, 1_800)
        XCTAssertGreaterThanOrEqual(standard.totalCreateDelayMilliseconds, 1_600)
    }

    private func makeTemporaryStoreRoot() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "MotionRevealTests-\(UUID().uuidString)", directoryHint: .isDirectory)

        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func makeAnimatedArtworkVideo(
        at url: URL,
        durationSeconds: TimeInterval,
        frameSize: CGSize
    ) async throws {
        let writer = try AVAssetWriter(
            outputURL: url,
            fileType: url.pathExtension.lowercased() == "mov" ? .mov : .mp4
        )
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: frameSize.width,
            AVVideoHeightKey: frameSize.height
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: Int(frameSize.width),
                kCVPixelBufferHeightKey as String: Int(frameSize.height),
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ]
        )

        XCTAssertTrue(writer.canAdd(input))
        writer.add(input)
        XCTAssertTrue(writer.startWriting())
        writer.startSession(atSourceTime: .zero)

        let pixelBuffer = try Self.makeSolidPixelBuffer(width: Int(frameSize.width), height: Int(frameSize.height))
        let frameDuration = CMTime(value: 1, timescale: 30)
        let endTime = CMTime(seconds: durationSeconds, preferredTimescale: 600)
        let finalFrameTime = durationSeconds > (1.0 / 30.0) ? CMTimeSubtract(endTime, frameDuration) : .zero

        while !input.isReadyForMoreMediaData {
            await Task.yield()
        }
        XCTAssertTrue(adaptor.append(pixelBuffer, withPresentationTime: .zero))

        while !input.isReadyForMoreMediaData {
            await Task.yield()
        }
        XCTAssertTrue(adaptor.append(pixelBuffer, withPresentationTime: finalFrameTime))

        input.markAsFinished()
        await Self.finishWriting(writer)

        if writer.status == .failed, let error = writer.error {
            throw error
        }
    }

    private static func makeSolidPixelBuffer(width: Int, height: Int) throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary,
            &pixelBuffer
        )
        XCTAssertEqual(status, kCVReturnSuccess)

        let resolvedPixelBuffer = try XCTUnwrap(pixelBuffer)
        CVPixelBufferLockBaseAddress(resolvedPixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(resolvedPixelBuffer, []) }

        if let baseAddress = CVPixelBufferGetBaseAddress(resolvedPixelBuffer) {
            memset(baseAddress, 0, CVPixelBufferGetDataSize(resolvedPixelBuffer))
        }

        return resolvedPixelBuffer
    }

    private static func makeSolidImagePNG(at url: URL, size: CGSize = CGSize(width: 16, height: 16)) throws {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        let data = try XCTUnwrap(image.pngData())
        try data.write(to: url)
    }

    private static func finishWriting(_ writer: AVAssetWriter) async {
        await withCheckedContinuation { continuation in
            writer.finishWriting {
                continuation.resume()
            }
        }
    }

    private func makeProject(title: String, trackCount: Int = 0, tracks: [MotionReveal.MusicTrack] = []) -> MusicProject {
        MusicProject(
            id: UUID(),
            title: title,
            creator: "Joseph",
            trackCount: trackCount == 0 ? tracks.count : trackCount,
            runtime: "",
            sleeve: .blank,
            state: .regular,
            tracks: tracks
        )
    }
}
