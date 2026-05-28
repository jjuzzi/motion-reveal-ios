import SwiftUI

private enum LaunchSetupStage {
    case loading
    case disc
    case albumSetup
    case complete
}

struct MusicWorkspaceView: View {
    private static let onboardingVersion = 2
    private static let previousTrackDoubleTapWindow: TimeInterval = 0.45
    private static let projectBottomInsetWithoutPlayer: CGFloat = 138
    private static let projectBottomInsetWithMiniPlayer: CGFloat = 276
    private static let miniPlayerBottomPadding: CGFloat = 52
    private static let toastBottomPaddingWithoutPlayer: CGFloat = 30
    private static let toastBottomPaddingWithMiniPlayer: CGFloat = 140

    @AppStorage("studioOnboardingVersion") private var studioOnboardingVersion = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Namespace private var heroNamespace
    @State private var projects: [MusicProject] = []
    @State private var libraryStore = MusicLibraryStore()
    @State private var libraryPersistence = WorkspaceLibraryPersistence()
    @State private var playbackRuntime = WorkspacePlaybackRuntime()
    @State private var liveActivitySync = WorkspaceLiveActivitySync()
    @State private var remoteCommandController = RemoteCommandController()
    @State private var screen: WorkspaceScreen = .library
    @State private var selectedProject = MusicProject.freshProject
    @State private var launchSetupStage: LaunchSetupStage = .loading
    @State private var ritualProject: MusicProject?
    @State private var ritualSourceRect: CGRect?
    @State private var libraryLeadSourceRect: CGRect?
    @State private var createdAlbumDiscSourceRect: CGRect?
    @State private var ritualPhase: LoadRitualPhase = .idle
    @State private var ritualTask: Task<Void, Never>?
    @State private var createdAlbumDiscPromptProject: MusicProject?
    @State private var slotReady = false
    @State private var slotArmed = false
    @State private var slotPull: CGFloat = 0
    @State private var lastPreviousTransportTap: Date?
    @State private var lastSeekBroadcastAt = Date.distantPast
    @State private var songContainerOpen = false
    @State private var selectedMarker: WaveformMarker?
    @State private var studioDrawerOpen = false
    @State private var activeMenu: WorkspaceActionKind?
    @State private var activeMenuTrack: MusicTrack?
    @State private var importStatus: WorkspaceImportStatus?
    @State private var importTask: Task<Void, Never>?
    @State private var importStatusDismissTask: Task<Void, Never>?
    @State private var playbackIntentObserver: MotionRevealIntentDarwinObserver?
    @State private var pendingDestructiveAction: WorkspaceDestructiveAction?
    @State private var isDestructiveConfirmationPresented = false
    @State private var renameDraft: WorkspaceRenameDraft?
    @State private var attachmentDraft: WorkspaceAttachmentDraft?
    @State private var songTextDraft: WorkspaceSongTextDraft?
    @State private var markerDraft: WorkspaceMarkerDraft?
    @State private var markerEditorCooldownToken = 0
    @State private var exportItem: WorkspaceExportItem?
    @State private var projectSearchText = ""
    @State private var isProjectSearchVisible = false
    @State private var previewAttachmentURL: URL?
    @State private var isSettingsPresented = false
    @State private var isImportTrayPresented = false
    @State private var isAudioImporterPresented = false
    @State private var isAnimatedArtworkImporterPresented = false
    @State private var isProjectCoverImporterPresented = false
    @State private var animatedArtworkTargetTrackID: UUID?
    @State private var isAttachmentImporterPresented = false
    @State private var toast: String?
    @State private var toastDismissTask: Task<Void, Never>?
    @State private var slotCueTask: Task<Void, Never>?
    @State private var didLoadPersistedProjects = false
#if DEBUG
    @State private var didRunLaunchAutomation = false
    @State private var debugRequestedImporterKind: WorkspaceImportKind?
#endif

    private var isRitualBlockingWorkspace: Bool {
        createdAlbumDiscPromptProject != nil || ritualPhase != .idle
    }

    private var isCreatedAlbumDiscStage: Bool {
        createdAlbumDiscPromptProject != nil || ritualPhase == .creating
    }

    private var ritualReduceMotion: Bool {
#if DEBUG
        if UserDefaults.standard.bool(forKey: DebugLaunchStateReset.forceFullMotionRitualsKey) {
            return false
        }
#endif
        return reduceMotion
    }

    private var heroMotionEnabled: Bool {
        !reduceMotion && !isRitualBlockingWorkspace
    }

    private var currentTrack: MusicTrack {
        nowPlaying ?? selectedProject.tracks.first ?? MusicTrack.placeholder
    }

    private var nowPlaying: MusicTrack? {
        get { playbackRuntime.nowPlaying }
        nonmutating set { playbackRuntime.nowPlaying = newValue }
    }

    private var playbackProgress: PlaybackProgress {
        get { playbackRuntime.progress }
        nonmutating set { playbackRuntime.progress = newValue }
    }

    private var currentTrackIndex: Int? {
        guard let nowPlaying else { return nil }
        return selectedProject.tracks.firstIndex { $0.id == nowPlaying.id }
    }

    private var currentTrackMarkers: Binding<[WaveformMarker]> {
        Binding(
            get: { currentTrack.markers },
            set: { updateMarkers($0, forTrackID: currentTrack.id) }
        )
    }

    private var canPlayPrevious: Bool {
        nowPlaying != nil
    }

    private var canPlayNext: Bool {
        guard let currentTrackIndex else { return false }
        return currentTrackIndex < selectedProject.tracks.count - 1
    }

    private var remoteCommandAvailability: RemoteCommandController.Availability {
        let hasCurrentTrack = nowPlaying != nil

        return RemoteCommandController.Availability(
            canPlay: hasCurrentTrack && !playbackRuntime.commandIsPlaying,
            canPause: hasCurrentTrack && playbackRuntime.commandIsPlaying,
            canTogglePlayback: hasCurrentTrack,
            canPlayPrevious: hasCurrentTrack,
            canPlayNext: canPlayNext,
            canChangePlaybackPosition: hasCurrentTrack && playbackRuntime.commandCanChangePlaybackPosition,
            canStop: hasCurrentTrack
        )
    }

    private var presentationActions: WorkspacePresentationActions {
        WorkspacePresentationActions(
            renameProject: { renameDraft = .project(selectedProject) },
            changeProjectCover: presentProjectCoverImporter,
            duplicateProject: duplicateSelectedProject,
            exportProject: { presentExport(exportBuilder.projectExportItem(for: selectedProject)) },
            toggleProjectPin: toggleSelectedProjectPin,
            deleteProject: { confirmDestructiveAction(.deleteProject) },
            renameTrack: { track in renameDraft = .track(track) },
            exportTrack: { track in presentExport(exportBuilder.trackExportItem(for: track, kind: .track)) },
            replaceTrackFile: presentAudioImporter,
            setMotionArtwork: presentAnimatedArtworkImporter,
            removeTrack: { track in confirmDestructiveAction(.removeTrack(track)) },
            editMarkers: { openSongContainer(revealStudioDrawer: false) },
            addStudioFile: presentAttachmentImporter,
            exportSong: { track in presentExport(exportBuilder.trackExportItem(for: track, kind: .song)) },
            deleteSong: { track in confirmDestructiveAction(.deleteSong(track)) },
            trackUnavailable: { showToast("Pick a track first") },
            performDestructiveAction: performDestructiveAction,
            cancelDestructiveAction: { pendingDestructiveAction = nil },
            saveRenameDraft: saveRenameDraft,
            cancelRenameDraft: cancelRenameDraft,
            saveAttachmentDraft: saveAttachmentDraft,
            cancelAttachmentDraft: cancelAttachmentDraft,
            saveSongTextDraft: saveSongTextDraft,
            cancelSongTextDraft: cancelSongTextDraft,
            saveMarkerDraft: saveMarkerDraft,
            deleteMarkerDraft: deleteMarkerDraft,
            cancelMarkerDraft: cancelMarkerDraft,
            handleAudioImport: handleAudioImport,
            handleAnimatedArtworkImport: handleAnimatedArtworkImport,
            handleProjectCoverImport: handleProjectCoverImport,
            handleAttachmentImport: handleAttachmentImport
        )
    }

    private var songContainerCoordinator: WorkspaceSongContainerCoordinator {
        WorkspaceSongContainerCoordinator(selectedProject: selectedProject, nowPlaying: nowPlaying)
    }

    private var importFlow: WorkspaceImportFlow {
        WorkspaceImportFlow(
            libraryStore: libraryStore,
            existingAudioTracks: selectedProject.tracks,
            targetAttachmentTrackID: currentTrackIDForAttachments(),
            setImportStatus: { status in
                WorkspaceImportDiagnostics.statusDisplayed(status)
                importStatus = status
            },
            finishImport: finishImport,
            showToast: showToast,
            appendImportedTracks: appendImportedTracks,
            appendAttachments: appendAttachments,
            presentAudioImporter: presentAudioImporter
        )
    }

    private var exportBuilder: WorkspaceExportBuilder {
        WorkspaceExportBuilder(libraryStore: libraryStore)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if !isCreatedAlbumDiscStage {
                StudioBackdrop()

                if nowPlaying != nil {
                    NowPlayingColorField(
                        artwork: selectedProject.sleeve,
                        isExpanded: songContainerOpen
                    )
                    .transition(.opacity)
                    .allowsHitTesting(false)
                }

                Group {
                    switch screen {
                    case .library:
                        LibraryScreen(
                            projects: projects,
                            heroNamespace: heroNamespace,
                            heroMotionEnabled: heroMotionEnabled,
                            openProject: { project, sourceRect in
                                loadProject(project, sourceRect: sourceRect)
                            },
                            recordLeadSourceRect: { sourceRect in
                                libraryLeadSourceRect = sourceRect
                            },
                            openMenu: openProjectMenu,
                            renameProject: { project in
                                selectedProject = project
                                renameDraft = .project(project)
                            },
                            changeProjectCover: { project in
                                selectedProject = project
                                presentProjectCoverImporter()
                            },
                            openSettings: { isSettingsPresented = true },
                            createProject: createProject
                        )
                        .transition(.opacity)
                    case .project:
                        ProjectScreen(
                            project: selectedProject,
                            heroNamespace: heroNamespace,
                            heroMotionEnabled: heroMotionEnabled,
                            searchText: $projectSearchText,
                            isSearchVisible: $isProjectSearchVisible,
                            playProject: playProject,
                            playTrack: playTrack,
                            back: returnToLibrary,
                            addTrack: presentAudioImporter,
                            renameProject: { renameDraft = .project(selectedProject) },
                            changeCover: presentProjectCoverImporter,
                            openMenu: openMenu,
                            openTrackMenu: openTrackMenu,
                            bottomContentInset: nowPlaying == nil
                                ? Self.projectBottomInsetWithoutPlayer
                                : Self.projectBottomInsetWithMiniPlayer
                        )
                        .transition(.opacity)
                    }
                }
                .blur(radius: songContainerOpen ? 18 : 0)
                .scaleEffect(songContainerOpen ? 0.965 : 1)
                .animation(.spring(response: 0.46, dampingFraction: 0.88), value: songContainerOpen)
                .allowsHitTesting(!isRitualBlockingWorkspace)
                .accessibilityHidden(isRitualBlockingWorkspace)

                if screen == .library, !projects.isEmpty {
                    CreateProjectButton(createProject: createProject)
                        .padding(.trailing, 22)
                        .padding(.bottom, 28)
                        .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(!isRitualBlockingWorkspace)
                        .accessibilityHidden(isRitualBlockingWorkspace)
                }

                if let nowPlaying, !songContainerOpen {
                    MiniPlayer(
                        project: selectedProject,
                        track: nowPlaying,
                        markers: nowPlaying.markers,
                        playbackRuntime: playbackRuntime,
                        heroNamespace: heroNamespace,
                        heroMotionEnabled: heroMotionEnabled,
                        canPlayPrevious: canPlayPrevious,
                        canPlayNext: canPlayNext,
                        openSongContainer: openSongContainer,
                        togglePlayback: togglePlayback,
                        playPrevious: handlePreviousTransportTap,
                        playNext: playNextTrack,
                        stopPlayback: stopPlayback
                    )
                    .padding(.horizontal, 18)
                    .padding(.bottom, Self.miniPlayerBottomPadding)
                    .zIndex(45)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(!isRitualBlockingWorkspace)
                    .accessibilityHidden(isRitualBlockingWorkspace)
                }

                if songContainerOpen {
                    SongContainerView(
                        project: selectedProject,
                        track: currentTrack,
                        playbackRuntime: playbackRuntime,
                        heroNamespace: heroNamespace,
                        heroMotionEnabled: heroMotionEnabled,
                        markers: currentTrackMarkers,
                        selectedMarker: $selectedMarker,
                        studioDrawerOpen: $studioDrawerOpen,
                        isMarkerEditorPresented: markerDraft != nil,
                        markerEditorCooldownToken: markerEditorCooldownToken,
                        attachments: currentTrack.attachments,
                        textDocuments: currentTrack.textDocuments,
                        togglePlayback: togglePlayback,
                        playPrevious: handlePreviousTransportTap,
                        playNext: playNextTrack,
                        seekPlayback: seekPlayback,
                        previewSeekPlayback: previewSeekPlayback,
                        addAttachment: presentAttachmentImporter,
                        attachmentURL: attachmentURL,
                        previewAttachment: previewAttachment,
                        editAttachment: { attachment in
                            attachmentDraft = .attachment(attachment, trackID: currentTrack.id)
                        },
                        removeAttachment: { attachment in
                            confirmDestructiveAction(.removeAttachment(trackID: currentTrack.id, attachment: attachment))
                        },
                        setMotionArtwork: { presentAnimatedArtworkImporter(for: currentTrack) },
                        useSampleMotionArtwork: { applySampleMotionArtwork(to: currentTrack) },
                        editSongText: editSongText,
                        addMarkerAtPlayhead: addMarkerAtPlayhead,
                        editMarker: editMarker,
                        toggleMarkerResolved: toggleMarkerResolved,
                        close: closeSongContainer,
                        openMenu: { activeMenu = .song }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(50)
                    .allowsHitTesting(!isRitualBlockingWorkspace)
                    .accessibilityHidden(isRitualBlockingWorkspace)
                }

                DynamicSlotButton(
                    isVisible: slotReady || songContainerOpen,
                    isReady: slotReady,
                    isArmed: slotArmed,
                    pull: slotPull,
                    openSongContainer: openSongContainerFromSlot,
                    setArmed: setSlotArmed,
                    setPull: setSlotPull
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(edges: .top)
                .zIndex(60)
                .allowsHitTesting(!isRitualBlockingWorkspace)
                .accessibilityHidden(isRitualBlockingWorkspace)
            }

            RitualOverlay(
                phase: ritualPhase,
                project: ritualProject ?? selectedProject,
                sourceRect: ritualSourceRect,
                reduceMotion: ritualReduceMotion
            )
            .zIndex(70)
            .allowsHitTesting(ritualPhase != .idle)

            if let createdAlbumDiscPromptProject {
                CreatedAlbumDiscPromptView(
                    project: createdAlbumDiscPromptProject,
                    playDisc: activateCreatedAlbumDiscPrompt,
                    recordDiscFrame: { sourceRect in
                        createdAlbumDiscSourceRect = sourceRect
                    }
                )
                .transition(.identity)
                .zIndex(75)
            }

            if let toast, !isRitualBlockingWorkspace {
                ToastView(message: toast)
                    .padding(
                        .bottom,
                        nowPlaying == nil
                            ? Self.toastBottomPaddingWithoutPlayer
                            : Self.toastBottomPaddingWithMiniPlayer
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(80)
            }

            if let importStatus, !isRitualBlockingWorkspace {
                WorkspaceImportStatusOverlay(
                    status: importStatus,
                    retryImport: retryImport
                )
                .transition(.scale(scale: 0.94).combined(with: .opacity))
                .zIndex(85)
            }

            if isImportTrayPresented, !isRitualBlockingWorkspace {
                StudioImportNotchTray(
                    isPresented: $isImportTrayPresented,
                    projectTitle: selectedProject.title,
                    importAudio: openAudioImporterFromTray
                )
                .transition(.identity)
                .zIndex(90)
            }

#if DEBUG
            if let debugRequestedImporterKind {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityLabel(debugRequestedImporterKind.debugRequestedImporterLabel)
                    .accessibilityIdentifier("debug-importer-requested")
            }
#endif

            if studioOnboardingVersion < Self.onboardingVersion, !isRitualBlockingWorkspace, launchSetupStage == .complete {
                StudioOnboardingView {
                    withAnimation(.spring(response: 0.48, dampingFraction: 0.88)) {
                        studioOnboardingVersion = Self.onboardingVersion
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(100)
            }

            switch launchSetupStage {
            case .loading:
                Color.studioBackground
                    .ignoresSafeArea()
                    .zIndex(120)
            case .disc:
                LaunchDiscIntroView {
                    withAnimation(.spring(response: 0.40, dampingFraction: 0.88)) {
                        launchSetupStage = .albumSetup
                    }
                }
                .transition(.identity)
                .zIndex(120)
            case .albumSetup:
                LaunchAlbumSetupView(finish: completeLaunchAlbumSetup)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .zIndex(120)
            case .complete:
                EmptyView()
            }
        }
        .coordinateSpace(name: WorkspaceCoordinateSpace.name)
        .font(StudioType.metadata)
        .preferredColorScheme(.dark)
        .statusBarHidden(isCreatedAlbumDiscStage)
        .persistentSystemOverlays(isCreatedAlbumDiscStage ? .hidden : .automatic)
        .defersSystemGestures(on: isRitualBlockingWorkspace ? .vertical : [])
        .workspacePresentations(
            activeMenu: $activeMenu,
            activeMenuTrack: activeMenuTrack,
            selectedProject: selectedProject,
            currentTrack: currentTrack,
            pendingDestructiveAction: $pendingDestructiveAction,
            isDestructiveConfirmationPresented: $isDestructiveConfirmationPresented,
            renameDraft: $renameDraft,
            attachmentDraft: $attachmentDraft,
            songTextDraft: $songTextDraft,
            markerDraft: $markerDraft,
            exportItem: $exportItem,
            previewAttachmentURL: $previewAttachmentURL,
            isAudioImporterPresented: $isAudioImporterPresented,
            isAnimatedArtworkImporterPresented: $isAnimatedArtworkImporterPresented,
            isProjectCoverImporterPresented: $isProjectCoverImporterPresented,
            isAttachmentImporterPresented: $isAttachmentImporterPresented,
            actions: presentationActions
        )
        .sheet(isPresented: $isSettingsPresented) {
            WorkspaceSettingsSheet {
                studioOnboardingVersion = 0
                isSettingsPresented = false
            }
        }
        .task {
            await loadPersistedProjectsIfNeeded()
            installPlaybackIntentObserverIfNeeded()
            handlePendingAppIntentRoute()
            updateRemoteCommandController()
#if DEBUG
            await runLaunchAutomationIfNeeded()
#endif
        }
        .onOpenURL(perform: handleIncomingURL)
        .onChange(of: remoteCommandAvailability, initial: true) { _, _ in
            updateRemoteCommandController()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                handlePendingAppIntentRoute()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: MotionRevealIntentNotification.togglePlayback)) { _ in
            handlePlaybackIntentToggle()
        }
        .onDisappear(perform: cancelWorkspaceTasks)
    }

    private func loadPersistedProjectsIfNeeded() async {
        guard !didLoadPersistedProjects else { return }
        didLoadPersistedProjects = true

        let loadedProjects = await libraryPersistence.loadProjects(from: libraryStore)
        projects = loadedProjects

        if let firstProject = loadedProjects.first {
            selectedProject = firstProject
            launchSetupStage = .complete
        } else {
            selectedProject = MusicProject.freshProject
            launchSetupStage = .disc
        }
    }

    private func completeLaunchAlbumSetup(_ setup: LaunchAlbumSetupResult) {
        Task { @MainActor in
            await completeLaunchAlbumSetup(setup)
        }
    }

    private func completeLaunchAlbumSetup(_ setup: LaunchAlbumSetupResult) async {
        var project = MusicProject.freshProject
        project.id = UUID()
        project.title = setup.title
        project.state = .regular

        if let coverURL = setup.coverURL {
            let result = await WorkspaceImportWorker.importProjectCover([coverURL], libraryStore: libraryStore)
            if let sleeve = result.sleeve {
                project.sleeve = sleeve
                project.coverMotionArtworkIsExplicit = true
            } else if let motionArtwork = result.motionArtwork {
                project.coverMotionArtwork = motionArtwork
                project.coverMotionArtworkIsExplicit = true
            }
        }

        projects = [project]
        selectedProject = project
        screen = .library
        slotReady = false
        songContainerOpen = false
        studioDrawerOpen = false
        persistProjects()

        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            launchSetupStage = .complete
        }
    }

    private func loadProject(_ project: MusicProject, sourceRect: CGRect? = nil) {
        ritualTask?.cancel()
        slotCueTask?.cancel()
        slotCueTask = nil
        slotPull = 0
        songContainerOpen = false
        selectedMarker = nil
        studioDrawerOpen = false
        projectSearchText = ""
        isProjectSearchVisible = false

        ritualSourceRect = nil
        ritualProject = nil
        ritualPhase = .idle
        selectedProject = project
        withAnimation(.easeInOut(duration: ritualReduceMotion ? 0.12 : 0.20)) {
            screen = .project
            slotReady = !selectedProject.tracks.isEmpty
        }
        syncDynamicIslandActivity()
    }

    private func returnToLibrary() {
        projectSearchText = ""
        isProjectSearchVisible = false
        slotCueTask?.cancel()
        slotCueTask = nil

        withAnimation(.easeInOut(duration: ritualReduceMotion ? 0.12 : 0.20)) {
            screen = .library
            slotReady = nowPlaying != nil
            songContainerOpen = false
            studioDrawerOpen = false
            slotPull = 0
        }

        if nowPlaying == nil {
            endDynamicIslandActivity()
        }
    }

    private func createProject() {
        guard ritualPhase == .idle, createdAlbumDiscPromptProject == nil else { return }

        ritualTask?.cancel()
        ritualSourceRect = nil
        createdAlbumDiscSourceRect = nil

        let freshProject = withAnimation(
            ritualReduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.58, dampingFraction: 0.82)
        ) {
            WorkspaceProjectMutationExecutor.createFreshProject(projects: &projects)
        }
        ritualProject = freshProject
        withAnimation(ritualReduceMotion ? .easeOut(duration: 0.14) : .spring(response: 0.54, dampingFraction: 0.86)) {
            createdAlbumDiscPromptProject = freshProject
        }
    }

    private func activateCreatedAlbumDiscPrompt(_ project: MusicProject, sourceRect: CGRect? = nil) {
        guard ritualPhase == .idle else { return }

        ritualTask?.cancel()
        ritualSourceRect = sourceRect ?? createdAlbumDiscSourceRect
        ritualProject = project
        createdAlbumDiscSourceRect = nil
        withAnimation(ritualReduceMotion ? .easeOut(duration: 0.10) : .easeOut(duration: 0.16)) {
            createdAlbumDiscPromptProject = nil
            ritualPhase = .creating
        }

        let timing = WorkspaceRitualTiming(reduceMotion: ritualReduceMotion)
        ritualTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(timing.createInsertDelayMilliseconds))
            guard !Task.isCancelled else { return }

            try? await Task.sleep(for: .milliseconds(timing.createActivateDelayMilliseconds))
            guard !Task.isCancelled else { return }

            if let activatedProject = WorkspaceProjectMutationExecutor.activateCreatedProject(id: project.id, projects: &projects) {
                selectedProject = activatedProject
                screen = .project
                slotReady = false
                projectSearchText = ""
                isProjectSearchVisible = false
                persistProjects()
                showToast("Sleeve loaded")
            }

            withAnimation(ritualReduceMotion ? .easeOut(duration: 0.10) : .easeOut(duration: 0.18)) {
                ritualPhase = .idle
            }
        }
    }

    private func playProject() {
        guard let firstTrack = selectedProject.tracks.first else {
            showToast("Add a track first")
            presentAudioImporter()
            return
        }

        playTrack(firstTrack)
    }

    private func presentAudioImporter() {
#if DEBUG
        if shouldSuppressImporterPresentationForUITest {
            debugRequestedImporterKind = .audio
            return
        }
#endif
        isImportTrayPresented = true
    }

    private func openAudioImporterFromTray() {
        isAudioImporterPresented = true
    }

    private func presentAttachmentImporter() {
        guard !selectedProject.tracks.isEmpty else {
            showToast("Add a track first")
            presentAudioImporter()
            return
        }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            songContainerOpen = true
        }
#if DEBUG
        if shouldSuppressImporterPresentationForUITest {
            debugRequestedImporterKind = .attachment
            return
        }
#endif
        isAttachmentImporterPresented = true
    }

    private func presentAnimatedArtworkImporter(for track: MusicTrack) {
        guard selectedProject.tracks.contains(where: { $0.id == track.id }) else {
            showToast("Add a track first")
            presentAudioImporter()
            return
        }

        animatedArtworkTargetTrackID = track.id
#if DEBUG
        if shouldSuppressImporterPresentationForUITest {
            debugRequestedImporterKind = .animatedArtwork
            return
        }
#endif
        isAnimatedArtworkImporterPresented = true
    }

    private func presentProjectCoverImporter() {
#if DEBUG
        if shouldSuppressImporterPresentationForUITest {
            debugRequestedImporterKind = .projectCover
            return
        }
#endif
        isProjectCoverImporterPresented = true
    }

    private func retryImport(_ kind: WorkspaceImportKind) {
        importStatusDismissTask?.cancel()
        importStatusDismissTask = nil

        withAnimation(.easeOut(duration: 0.16)) {
            importStatus = nil
        }

        switch kind {
        case .audio:
            presentAudioImporter()
        case .animatedArtwork:
            presentAnimatedArtworkImporter(for: currentTrack)
        case .projectCover:
            presentProjectCoverImporter()
        case .attachment:
            presentAttachmentImporter()
        }
    }

    private func openMenu(_ kind: WorkspaceActionKind) {
        activeMenuTrack = nil
        activeMenu = kind
    }

    private func openProjectMenu(_ project: MusicProject) {
        selectedProject = project
        activeMenuTrack = nil
        activeMenu = .project
    }

    private func openTrackMenu(_ track: MusicTrack) {
        activeMenuTrack = track
        activeMenu = .track
    }

    private func handleAudioImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            let selection = WorkspaceImportSelection(urls: urls)
            WorkspaceImportDiagnostics.pickerCompleted(
                kind: .audio,
                urlCount: selection.urls.count,
                securityScopedURLCount: selection.securityScopedURLCount
            )
            guard !selection.urls.isEmpty else {
                WorkspaceImportDiagnostics.emptySelection(kind: .audio)
                return
            }
            importTask?.cancel()
            importTask = Task { @MainActor in
                defer { selection.stopAccessing() }
                await importFlow.importAudioFiles(selection.urls)
            }
        case .failure(let error):
            WorkspaceImportDiagnostics.pickerFailed(kind: .audio, error: error)
            handleImportPickerFailure(error, kind: .audio)
        }
    }

    private func handleAnimatedArtworkImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            let selection = WorkspaceImportSelection(urls: urls)
            WorkspaceImportDiagnostics.pickerCompleted(
                kind: .animatedArtwork,
                urlCount: selection.urls.count,
                securityScopedURLCount: selection.securityScopedURLCount
            )
            guard !selection.urls.isEmpty else {
                WorkspaceImportDiagnostics.emptySelection(kind: .animatedArtwork)
                return
            }
            importTask?.cancel()
            importTask = Task { @MainActor in
                defer { selection.stopAccessing() }
                await importAnimatedArtworkFiles(selection.urls)
            }
        case .failure(let error):
            WorkspaceImportDiagnostics.pickerFailed(kind: .animatedArtwork, error: error)
            handleImportPickerFailure(error, kind: .animatedArtwork)
        }
    }

    private func handleProjectCoverImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            let selection = WorkspaceImportSelection(urls: urls)
            WorkspaceImportDiagnostics.pickerCompleted(
                kind: .projectCover,
                urlCount: selection.urls.count,
                securityScopedURLCount: selection.securityScopedURLCount
            )
            guard let url = selection.urls.first else {
                WorkspaceImportDiagnostics.emptySelection(kind: .projectCover)
                return
            }
            importTask?.cancel()
            importTask = Task { @MainActor in
                defer { selection.stopAccessing() }
                await importProjectCover(url)
            }
        case .failure(let error):
            WorkspaceImportDiagnostics.pickerFailed(kind: .projectCover, error: error)
            handleImportPickerFailure(error, kind: .projectCover)
        }
    }

    private func handleAttachmentImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            let selection = WorkspaceImportSelection(urls: urls)
            WorkspaceImportDiagnostics.pickerCompleted(
                kind: .attachment,
                urlCount: selection.urls.count,
                securityScopedURLCount: selection.securityScopedURLCount
            )
            guard !selection.urls.isEmpty else {
                WorkspaceImportDiagnostics.emptySelection(kind: .attachment)
                return
            }
            importTask?.cancel()
            importTask = Task { @MainActor in
                defer { selection.stopAccessing() }
                await importFlow.importAttachmentFiles(selection.urls)
            }
        case .failure(let error):
            WorkspaceImportDiagnostics.pickerFailed(kind: .attachment, error: error)
            handleImportPickerFailure(error, kind: .attachment)
        }
    }

    private func handleImportPickerFailure(_ error: Error, kind: WorkspaceImportKind) {
        guard !error.isUserCanceledImport else {
            return
        }

#if DEBUG
        print("Files picker failed: \(error.localizedDescription)")
#endif
        finishImport(with: .pickerFailure(kind: kind, reason: error.localizedDescription))
    }

    private func finishImport(with status: WorkspaceImportStatus) {
        WorkspaceImportDiagnostics.statusDisplayed(status)

        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
            importStatus = status
        }

        switch status {
        case .success(let kind, let imported, let failedFileNames, _):
            if imported > 0 {
                switch kind {
                case .audio:
                    showToast(imported == 1 ? "Track added" : "\(imported) tracks added")
                case .animatedArtwork:
                    showToast("Motion artwork ready")
                case .projectCover:
                    showToast("Cover updated")
                case .attachment:
                    showToast(imported == 1 ? "File attached" : "\(imported) files attached")
                }
            } else if !failedFileNames.isEmpty {
                showToast("Import failed")
            }
        case .failure(let kind, _), .pickerFailure(let kind, _):
            switch kind {
            case .audio:
                showToast("Import failed - download it in Files first")
            case .projectCover:
                showToast("Cover failed - choose a local image")
            case .animatedArtwork, .attachment:
                showToast("Attachment failed - download it in Files first")
            }
        case .importing:
            break
        }

        importStatusDismissTask?.cancel()
        importStatusDismissTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(status.autoDismissDelayMilliseconds))
            } catch {
                return
            }
            guard importStatus == status else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                importStatus = nil
            }
            importStatusDismissTask = nil
        }
    }

    private func currentTrackIDForAttachments() -> UUID? {
        if let nowPlaying {
            return nowPlaying.id
        }

        return selectedProject.tracks.first?.id
    }

    private func importAnimatedArtworkFiles(_ urls: [URL]) async {
        guard animatedArtworkTargetTrackID != nil else {
            showToast("Pick a track first")
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            importStatus = .importing(kind: .animatedArtwork, total: max(urls.count, 1))
        }

        do {
            try await Task.sleep(for: .milliseconds(180))
        } catch {
            return
        }

        guard !Task.isCancelled else { return }
        let result = await WorkspaceImportWorker.importAnimatedArtworkFile(
            urls,
            libraryStore: libraryStore
        )
        guard !Task.isCancelled else { return }

        guard let artwork = result.artwork else {
            finishImport(with: .failure(kind: .animatedArtwork, failedFileNames: result.failedFileNames))
            return
        }

        appendAnimatedArtwork(artwork)
        finishImport(with: .success(kind: .animatedArtwork, imported: 1, failedFileNames: result.failedFileNames, skippedDuplicates: 0))
    }

    private func importProjectCover(_ url: URL) async {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            importStatus = .importing(kind: .projectCover, total: 1)
        }

        do {
            try await Task.sleep(for: .milliseconds(150))
        } catch {
            return
        }

        guard !Task.isCancelled else { return }

        let result = await WorkspaceImportWorker.importProjectCover([url], libraryStore: libraryStore)
        guard !Task.isCancelled else { return }

        guard result.failedFileNames.isEmpty else {
            finishImport(with: .failure(kind: .projectCover, failedFileNames: result.failedFileNames))
            return
        }

        if let sleeve = result.sleeve {
            WorkspaceProjectMutationExecutor.updateSelectedProjectCover(
                sleeve: sleeve,
                selectedProject: &selectedProject,
                projects: &projects
            )
        } else if let motionArtwork = result.motionArtwork {
            WorkspaceProjectMutationExecutor.updateSelectedProjectCover(
                motionArtwork: motionArtwork,
                selectedProject: &selectedProject,
                projects: &projects
            )
        }

        persistProjects()
        finishImport(with: .success(kind: .projectCover, imported: 1, failedFileNames: [], skippedDuplicates: 0))
    }

    private func appendImportedTracks(_ tracks: [MusicTrack]) {
        let shouldRunFirstImportHandoff = WorkspaceImportFlow.shouldTriggerFirstImportHandoff(
            existingTrackCount: selectedProject.tracks.count,
            importedTrackCount: tracks.count,
            isProjectScreen: screen == .project,
            isSongContainerOpen: songContainerOpen
        )

        WorkspaceImportMutationExecutor.appendImportedTracks(
            tracks,
            selectedProject: &selectedProject,
            projects: &projects
        )
        persistProjects()
        slotReady = screen == .project && !selectedProject.tracks.isEmpty
        syncDynamicIslandActivity(track: tracks.first)

        if shouldRunFirstImportHandoff, let firstImportedTrack = tracks.first {
            runFirstImportHandoff(with: firstImportedTrack)
        }
    }

    private func appendAnimatedArtwork(_ artwork: MotionArtwork) {
        guard let trackID = animatedArtworkTargetTrackID,
              let updatedTrack = WorkspaceTrackMutationExecutor.setAnimatedArtwork(
                artwork,
                forTrackID: trackID,
                selectedProject: &selectedProject,
                projects: &projects
              ) else {
            showToast("Track unavailable")
            return
        }

        animatedArtworkTargetTrackID = nil
        applyUpdatedTrack(updatedTrack)
        persistProjects()

        if nowPlaying?.id == updatedTrack.id {
            publishNowPlayingInfo(track: updatedTrack)
        }
    }

    private func applySampleMotionArtwork(to track: MusicTrack) {
        guard selectedProject.tracks.contains(where: { $0.id == track.id }) else {
            showToast("Track unavailable")
            return
        }

        guard let sampleURL = Bundle.main.url(forResource: "SampleMotionArtwork", withExtension: "mp4") else {
            showToast("Sample unavailable")
            return
        }

        importTask?.cancel()
        importTask = Task { @MainActor in
            let result = await WorkspaceImportWorker.importAnimatedArtworkFile(
                [sampleURL],
                libraryStore: libraryStore
            )
            guard let artwork = result.artwork else {
                finishImport(with: .failure(kind: .animatedArtwork, failedFileNames: result.failedFileNames))
                return
            }

            animatedArtworkTargetTrackID = track.id
            appendAnimatedArtwork(
                MotionArtwork(
                    localFileName: artwork.localFileName,
                    sourceFileName: "playda.te sample loop.mp4",
                    variant: artwork.variant
                )
            )
            finishImport(with: .success(kind: .animatedArtwork, imported: 1, failedFileNames: [], skippedDuplicates: 0))
        }
    }

    private func appendAttachments(_ attachments: [SongAttachment], toTrackID trackID: UUID) {
        guard let updatedTrack = WorkspaceImportMutationExecutor.appendAttachments(
            attachments,
            toTrackID: trackID,
            selectedProject: &selectedProject,
            projects: &projects
        ) else {
            showToast("Track unavailable")
            return
        }

        if nowPlaying?.id == trackID {
            nowPlaying = updatedTrack
        }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            songContainerOpen = true
        }

        persistProjects()
    }

    private func attachmentURL(for attachment: SongAttachment) -> URL? {
        libraryStore.attachmentURL(for: attachment)
    }

    private func previewAttachment(_ attachment: SongAttachment) {
        guard let url = libraryStore.attachmentURL(for: attachment) else {
            showToast("File missing - reimport from Files")
            return
        }

        previewAttachmentURL = url
    }

    private func addMarkerAtPlayhead() {
        guard let trackID = currentTrackIDForAttachments() else {
            showToast("Add a track first")
            presentAudioImporter()
            return
        }

        guard let result = WorkspaceTrackMutationExecutor.addMarker(
            position: CGFloat(playbackProgress.fraction),
            time: playbackProgress.elapsedLabel,
            forTrackID: trackID,
            selectedProject: &selectedProject,
            projects: &projects
        ) else {
            showToast("Marker unavailable")
            return
        }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            selectedMarker = result.marker
        }
        applyUpdatedTrack(result.updatedTrack)
        persistProjects()
        markerDraft = WorkspaceMarkerDraft(trackID: trackID, marker: result.marker)
    }

    private func editMarker(_ marker: WaveformMarker) {
        guard let trackID = currentTrackIDForAttachments() else {
            showToast("Track unavailable")
            return
        }

        markerDraft = WorkspaceMarkerDraft(trackID: trackID, marker: marker)
    }

    private func saveMarkerDraft() {
        guard let draft = markerDraft, draft.canSave else { return }
        guard let result = WorkspaceTrackMutationExecutor.saveMarkerDraft(
            draft,
            selectedProject: &selectedProject,
            projects: &projects
        ) else {
            showToast("Marker unavailable")
            selectedMarker = nil
            markerDraft = nil
            markerEditorCooldownToken += 1
            return
        }

        selectedMarker = nil
        applyUpdatedTrack(result.updatedTrack)
        persistProjects()
        markerDraft = nil
        markerEditorCooldownToken += 1
        showToast("Marker saved")
    }

    private func deleteMarkerDraft() {
        guard let draft = markerDraft else { return }
        guard let result = WorkspaceTrackMutationExecutor.deleteMarkerDraft(
            draft,
            selectedProject: &selectedProject,
            projects: &projects
        ) else {
            selectedMarker = nil
            markerDraft = nil
            markerEditorCooldownToken += 1
            return
        }

        if selectedMarker?.id == result.deletedMarkerID {
            selectedMarker = nil
        }

        applyUpdatedTrack(result.updatedTrack)
        persistProjects()
        markerDraft = nil
        markerEditorCooldownToken += 1
        showToast("Marker deleted")
    }

    private func toggleMarkerResolved(_ marker: WaveformMarker) {
        guard let trackID = currentTrackIDForAttachments(),
              let result = WorkspaceTrackMutationExecutor.toggleMarkerResolved(
                marker,
                forTrackID: trackID,
                selectedProject: &selectedProject,
                projects: &projects
              ) else {
            showToast("Marker unavailable")
            return
        }

        if selectedMarker?.id == marker.id {
            selectedMarker = result.marker
        }

        applyUpdatedTrack(result.updatedTrack)
        persistProjects()
        showToast(result.marker.isResolved ? "Marker resolved" : "Marker reopened")
    }

    private func cancelMarkerDraft() {
        guard markerDraft != nil || selectedMarker != nil else { return }

        selectedMarker = nil
        markerDraft = nil
        markerEditorCooldownToken += 1
    }

    private func updateMarkers(_ markers: [WaveformMarker], forTrackID trackID: UUID) {
        guard let updatedTrack = WorkspaceTrackMutationExecutor.updateMarkers(
            markers,
            forTrackID: trackID,
            selectedProject: &selectedProject,
            projects: &projects
        ) else {
            return
        }

        if nowPlaying?.id == trackID {
            nowPlaying = updatedTrack
        }

        persistProjects()
    }

    private func applyUpdatedTrack(_ updatedTrack: MusicTrack) {
        if nowPlaying?.id == updatedTrack.id {
            nowPlaying = updatedTrack
        }
    }

    private func playTrack(_ track: MusicTrack) {
        let startResult: WorkspacePlaybackStartResult

        do {
            startResult = try playbackRuntime.start(track: track, libraryStore: libraryStore)
        } catch {
            showToast("File missing - reimport from Files")
            return
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            lastPreviousTransportTap = nil
            selectedMarker = nil
            slotReady = true
        }
        startPlaybackTicker()
        publishNowPlayingInfo(track: track)
        syncDynamicIslandActivity(track: track, isPlaying: startResult.progress.isPlaying)
        showToast(startResult.message)
    }

    private func stopPlayback() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
            playbackRuntime.stop(libraryStore: libraryStore)
            lastPreviousTransportTap = nil
            songContainerOpen = false
            selectedMarker = nil
            studioDrawerOpen = false
            slotReady = screen == .project && !selectedProject.tracks.isEmpty
        }
        NowPlayingInfoPublisher.clear()
        endDynamicIslandActivity()
        showToast("Playback stopped")
    }

    private func togglePlayback() {
        guard nowPlaying != nil else { return }

        playbackRuntime.toggle(libraryStore: libraryStore)

        if playbackProgress.isPlaying {
            startPlaybackTicker()
        }

        publishNowPlayingInfo()
        syncDynamicIslandActivity(isPlaying: playbackProgress.isPlaying)
    }

    private func playPreviousTrack() {
        guard let currentTrackIndex, currentTrackIndex > 0 else {
            showToast("First track")
            return
        }

        playTrack(selectedProject.tracks[currentTrackIndex - 1])
    }

    private func handlePreviousTransportTap() {
        handlePreviousTransportTap(at: Date())
    }

    private func restartCurrentTrackFromBeginning() {
        guard nowPlaying != nil else { return }

        playbackRuntime.seek(to: 0, libraryStore: libraryStore)
        if playbackProgress.isPlaying {
            startPlaybackTicker()
        }
        publishNowPlayingInfo()
        syncDynamicIslandActivity(isPlaying: playbackProgress.isPlaying)
    }

    private func playNextTrack() {
        guard let currentTrackIndex, currentTrackIndex < selectedProject.tracks.count - 1 else {
            showToast("Last track")
            return
        }

        playTrack(selectedProject.tracks[currentTrackIndex + 1])
    }

    private func seekPlayback(to fraction: Double) {
        guard nowPlaying != nil else { return }

        playbackRuntime.seek(to: fraction, libraryStore: libraryStore)

        let now = Date()
        guard now.timeIntervalSince(lastSeekBroadcastAt) > 0.30 else { return }
        lastSeekBroadcastAt = now
        publishNowPlayingInfo()
        syncDynamicIslandActivity(isPlaying: playbackProgress.isPlaying)
    }

    private func previewSeekPlayback(to fraction: Double) {
        guard nowPlaying != nil else { return }

        playbackRuntime.previewSeek(to: fraction)
    }

    private func updateRemoteCommandController() {
        remoteCommandController.update(
            handlers: RemoteCommandController.Handlers(
                play: handleRemotePlayCommand,
                pause: handleRemotePauseCommand,
                togglePlayback: handleRemoteTogglePlaybackCommand,
                playNext: handleRemoteNextTrackCommand,
                playPrevious: handleRemotePreviousTrackCommand,
                changePlaybackPosition: handleRemoteChangePlaybackPositionCommand,
                stop: handleRemoteStopCommand
            ),
            availability: remoteCommandAvailability
        )
    }

    private func handleRemotePlayCommand() -> RemoteCommandController.CommandResult {
        guard nowPlaying != nil else { return .noActionableNowPlayingItem }
        guard !playbackProgress.isPlaying else { return .success }

        togglePlayback()
        return .success
    }

    private func handleRemotePauseCommand() -> RemoteCommandController.CommandResult {
        guard nowPlaying != nil else { return .noActionableNowPlayingItem }
        guard playbackProgress.isPlaying else { return .success }

        togglePlayback()
        return .success
    }

    private func handleRemoteTogglePlaybackCommand() -> RemoteCommandController.CommandResult {
        guard nowPlaying != nil else { return .noActionableNowPlayingItem }

        togglePlayback()
        return .success
    }

    private func handleRemoteNextTrackCommand() -> RemoteCommandController.CommandResult {
        guard nowPlaying != nil else { return .noActionableNowPlayingItem }
        guard canPlayNext else { return .noSuchContent }

        playNextTrack()
        return .success
    }

    private func handleRemotePreviousTrackCommand() -> RemoteCommandController.CommandResult {
        let now = Date()
        switch previousTransportDecision(at: now) {
        case .restartCurrentTrack:
            lastPreviousTransportTap = now
            restartCurrentTrackFromBeginning()
            return .success
        case .playPreviousTrack:
            lastPreviousTransportTap = nil
            playPreviousTrack()
            return .success
        case .noTrack:
            return .noActionableNowPlayingItem
        case .noPreviousTrack:
            lastPreviousTransportTap = nil
            return .noSuchContent
        }
    }

    private func handleRemoteChangePlaybackPositionCommand(_ positionTime: TimeInterval) -> RemoteCommandController.CommandResult {
        guard nowPlaying != nil else { return .noActionableNowPlayingItem }
        guard playbackProgress.duration > 0 else { return .commandFailed }

        seekPlayback(to: positionTime / playbackProgress.duration)
        return .success
    }

    private func handleRemoteStopCommand() -> RemoteCommandController.CommandResult {
        guard nowPlaying != nil else { return .noActionableNowPlayingItem }

        stopPlayback()
        return .success
    }

    private func handlePreviousTransportTap(at now: Date) {
        switch previousTransportDecision(at: now) {
        case .restartCurrentTrack:
            lastPreviousTransportTap = now
            restartCurrentTrackFromBeginning()
        case .playPreviousTrack:
            lastPreviousTransportTap = nil
            playPreviousTrack()
        case .noTrack:
            break
        case .noPreviousTrack:
            lastPreviousTransportTap = nil
            playPreviousTrack()
        }
    }

    private func previousTransportDecision(at now: Date) -> RemoteCommandController.PreviousCommandDecision {
        RemoteCommandController.previousCommandDecision(
            hasCurrentTrack: nowPlaying != nil,
            canPlayPreviousTrack: currentTrackIndex.map { $0 > 0 } ?? false,
            lastPreviousCommandDate: lastPreviousTransportTap,
            now: now,
            doubleTapWindow: Self.previousTrackDoubleTapWindow
        )
    }

    private func publishNowPlayingInfo(track: MusicTrack? = nil) {
        guard let publishedTrack = track ?? nowPlaying else { return }

        NowPlayingInfoPublisher.publish(
            project: selectedProject,
            track: publishedTrack,
            progress: playbackProgress,
            libraryStore: libraryStore
        )
    }

    private func startPlaybackTicker() {
        playbackRuntime.startTicker(libraryStore: libraryStore) {
            syncDynamicIslandActivity(isPlaying: true, canStartNewActivity: false)
        }
    }

    private func persistProjects() {
        let projectsSnapshot = projects
        let store = libraryStore
        let persistence = libraryPersistence

        Task { @MainActor in
            do {
                try await persistence.saveProjects(projectsSnapshot, to: store)
            } catch {
                guard !Task.isCancelled else { return }
                showToast("Could not save library")
            }
        }
    }

    private func saveRenameDraft() {
        guard let draft = renameDraft else { return }

        let name = draft.trimmedText
        guard !name.isEmpty else { return }

        switch draft.target {
        case .project:
            WorkspaceProjectMutationExecutor.renameSelectedProject(
                to: name,
                selectedProject: &selectedProject,
                projects: &projects
            )
            showToast("Project renamed")
        case .track(let trackID):
            renameTrack(id: trackID, to: name)
            showToast("Track renamed")
        }

        persistProjects()
        renameDraft = nil
    }

    private func cancelRenameDraft() {
        renameDraft = nil
    }

    private func saveAttachmentDraft() {
        guard let draft = attachmentDraft, draft.canSave else { return }

        updateAttachmentDetails(
            trackID: draft.trackID,
            attachmentID: draft.attachmentID,
            name: draft.trimmedName,
            category: draft.trimmedCategory.isEmpty ? "File" : draft.trimmedCategory
        )
        persistProjects()
        attachmentDraft = nil
        showToast("File updated")
    }

    private func cancelAttachmentDraft() {
        attachmentDraft = nil
    }

    private func editSongText(_ kind: SongTextKind) {
        guard let trackID = currentTrackIDForAttachments(),
              let track = selectedProject.tracks.first(where: { $0.id == trackID }) else {
            showToast("Track unavailable")
            return
        }

        let document = track.textDocuments.first { $0.kind == kind } ?? SongTextDocument(kind: kind)
        songTextDraft = .document(document, trackID: trackID)
    }

    private func saveSongTextDraft() {
        guard let draft = songTextDraft else { return }

        updateSongText(
            trackID: draft.trackID,
            kind: draft.kind,
            text: draft.trimmedText
        )
        persistProjects()
        songTextDraft = nil
        showToast("\(draft.kind.title) saved")
    }

    private func cancelSongTextDraft() {
        songTextDraft = nil
    }

    private func renameTrack(id: UUID, to name: String) {
        guard let updatedTrack = WorkspaceTrackMutationExecutor.renameTrack(
            id: id,
            to: name,
            selectedProject: &selectedProject,
            projects: &projects
        ) else { return }

        if nowPlaying?.id == id {
            nowPlaying = updatedTrack
        }
    }

    private func updateAttachmentDetails(trackID: UUID, attachmentID: UUID, name: String, category: String) {
        guard let updatedTrack = WorkspaceTrackMutationExecutor.updateAttachmentDetails(
            trackID: trackID,
            attachmentID: attachmentID,
            name: name,
            category: category,
            selectedProject: &selectedProject,
            projects: &projects
        ) else { return }

        if nowPlaying?.id == trackID {
            nowPlaying = updatedTrack
        }
    }

    private func updateSongText(trackID: UUID, kind: SongTextKind, text: String) {
        guard let updatedTrack = WorkspaceTrackMutationExecutor.updateSongText(
            trackID: trackID,
            kind: kind,
            text: text,
            selectedProject: &selectedProject,
            projects: &projects
        ) else { return }

        if nowPlaying?.id == trackID {
            nowPlaying = updatedTrack
        }
    }

    private func presentExport(_ result: WorkspaceExportBuildResult) {
        if result.hasTextExportFailures {
            showToast("Text export failed")
        }
        exportItem = result.item
    }

    private func duplicateSelectedProject() {
        WorkspaceProjectMutationExecutor.duplicateSelectedProject(
            selectedProject: selectedProject,
            projects: &projects
        )
        persistProjects()
        showToast("Project duplicated")
    }

    private func toggleSelectedProjectPin() {
        let state = WorkspaceProjectMutationExecutor.toggleSelectedProjectPin(
            selectedProject: &selectedProject,
            projects: &projects
        )
        persistProjects()
        showToast(state == .pinned ? "Pinned" : "Unpinned")
    }

    private func confirmDestructiveAction(_ action: WorkspaceDestructiveAction) {
        pendingDestructiveAction = action
        isDestructiveConfirmationPresented = true
    }

    private func performDestructiveAction(_ action: WorkspaceDestructiveAction) {
        switch action {
        case .deleteProject:
            deleteSelectedProject()
        case .removeTrack(let track), .deleteSong(let track):
            removeTrack(track)
        case .removeAttachment(let trackID, let attachment):
            removeAttachment(attachment, fromTrackID: trackID)
        }

        pendingDestructiveAction = nil
    }

    private func deleteSelectedProject() {
        WorkspaceDestructiveActionExecutor.deleteSelectedProject(
            projects: &projects,
            selectedProject: &selectedProject,
            screen: &screen
        )
        stopPlaybackIfNeededForDeletedProject()
        persistProjects()
        showToast("Project deleted")
    }

    private func stopPlaybackIfNeededForDeletedProject() {
        guard nowPlaying != nil else { return }

        slotCueTask?.cancel()
        slotCueTask = nil
        playbackRuntime.stop(libraryStore: libraryStore)
        songContainerOpen = false
        selectedMarker = nil
        studioDrawerOpen = false
        slotPull = 0
    }

    private func removeTrack(_ track: MusicTrack) {
        let wasNowPlaying = nowPlaying?.id == track.id
        let outcome = WorkspaceDestructiveActionExecutor.removeTrack(
            track,
            selectedProject: &selectedProject,
            projects: &projects
        )

        guard case .removed = outcome else {
            showToast("Track already removed")
            return
        }

        if wasNowPlaying {
            stopPlayback()
        }

        activeMenuTrack = nil
        persistProjects()
        syncDynamicIslandActivity()
        showToast("Track removed")
    }

    private func removeAttachment(_ attachment: SongAttachment, fromTrackID trackID: UUID) {
        let outcome = WorkspaceDestructiveActionExecutor.removeAttachment(
            attachment,
            fromTrackID: trackID,
            selectedProject: &selectedProject,
            projects: &projects
        )

        switch outcome {
        case .trackUnavailable:
            showToast("Track unavailable")
            return
        case .alreadyRemoved:
            showToast("File already removed")
            return
        case .removed(let removedAttachment, let updatedTrack):
            if nowPlaying?.id == trackID {
                nowPlaying = updatedTrack
            }

            persistProjects()
            syncDynamicIslandActivity(track: updatedTrack)

            let persistence = libraryPersistence
            let store = libraryStore
            let localFileName = removedAttachment.localFileName
            Task { @MainActor in
                do {
                    try await persistence.removeAttachment(localFileName: localFileName, from: store)
                    showToast("File removed")
                } catch {
                    showToast("File row removed; cleanup failed")
                }
            }
        }
    }

    private func openSongContainer() {
        openSongContainer(revealStudioDrawer: false)
    }

    private func openSongContainerFromSlot() {
        openSongContainer(revealStudioDrawer: true)
    }

    private func openSongContainer(revealStudioDrawer: Bool) {
        openSongContainer(with: songContainerCoordinator.openDecision(revealStudioDrawer: revealStudioDrawer))
    }

    private func closeSongContainer() {
        slotCueTask?.cancel()
        slotCueTask = nil
        withAnimation(.spring(response: 0.48, dampingFraction: 0.88)) {
            songContainerOpen = false
            selectedMarker = nil
            studioDrawerOpen = false
            slotPull = 0
        }
    }

    private func setSlotArmed(_ armed: Bool) {
        guard slotArmed != armed else { return }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            slotArmed = armed
        }

        if armed {
            showToast("Pull for container")
        }
    }

    private func setSlotPull(_ pull: CGFloat) {
        if pull > 0 {
            slotCueTask?.cancel()
            slotCueTask = nil
        }
        slotPull = pull
    }

    private func handleIncomingURL(_ url: URL) {
        guard !url.isFileURL else {
            handleExternalAudioOpen(url)
            return
        }

        handleDeepLink(url)
    }

    private func handleExternalAudioOpen(_ url: URL) {
        prepareProjectForExternalAudioImport()
        handleAudioImport(.success([url]))
    }

    private func prepareProjectForExternalAudioImport() {
        ritualTask?.cancel()
        ritualTask = nil
        slotCueTask?.cancel()
        slotCueTask = nil
        createdAlbumDiscPromptProject = nil
        ritualPhase = .idle
        ritualProject = nil
        ritualSourceRect = nil
        createdAlbumDiscSourceRect = nil

        if let selectedProjectIndex = projects.firstIndex(where: { $0.id == selectedProject.id }) {
            if projects[selectedProjectIndex].state == .fresh,
               let activatedProject = WorkspaceProjectMutationExecutor.activateCreatedProject(
                   id: selectedProject.id,
                   projects: &projects
               ) {
                selectedProject = activatedProject
            } else {
                selectedProject = projects[selectedProjectIndex]
            }
        } else if let existingProject = projects.first(where: { $0.state != .folder }) {
            selectedProject = existingProject
        } else {
            let freshProject = WorkspaceProjectMutationExecutor.createFreshProject(projects: &projects)
            if let activatedProject = WorkspaceProjectMutationExecutor.activateCreatedProject(
                id: freshProject.id,
                projects: &projects
            ) {
                selectedProject = activatedProject
            } else {
                selectedProject = freshProject
            }
        }

        screen = .project
        slotReady = !selectedProject.tracks.isEmpty
        slotPull = 0
        songContainerOpen = false
        studioDrawerOpen = false
        projectSearchText = ""
        isProjectSearchVisible = false
        persistProjects()
    }

    private func handleDeepLink(_ url: URL) {
        guard let route = WorkspaceDeepLinkRoute(url: url) else { return }
        openSongContainer(with: songContainerCoordinator.openDecision(for: route))
    }

    private func handlePendingAppIntentRoute() {
        guard didLoadPersistedProjects else { return }
        guard let route = PendingAppIntentRouteStore.consume() else { return }

        switch route {
        case .songContainer:
            openSongContainer(with: songContainerCoordinator.openDecision(for: route))
        case .togglePlayback:
            handlePlaybackIntentToggle()
        }
    }

    private func handlePlaybackIntentToggle() {
        PendingAppIntentRouteStore.consume(if: .togglePlayback)
        guard nowPlaying != nil else { return }

        togglePlayback()
    }

    private func openSongContainer(with decision: WorkspaceSongContainerOpenDecision) {
        switch decision {
        case .needsTrack:
            showToast("Add a track first")
            presentAudioImporter()
        case .open(let track, let revealStudioDrawer):
            nowPlaying = track
            withAnimation(.spring(response: 0.52, dampingFraction: 0.86)) {
                selectedMarker = nil
                songContainerOpen = true
                slotReady = true
                studioDrawerOpen = revealStudioDrawer
            }
        }
    }

    private func runFirstImportHandoff(with track: MusicTrack) {
        openSongContainer(with: .open(track: track, revealStudioDrawer: false))
        scheduleSlotReadyCue()
    }

    private func scheduleSlotReadyCue() {
        slotCueTask?.cancel()
        slotCueTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(260))
            } catch {
                return
            }

            guard songContainerOpen, !studioDrawerOpen else { return }

            let cuePull = min(DynamicSlotPullResponse.openThreshold * 0.22, 12)
            withAnimation(.easeOut(duration: 0.18)) {
                slotPull = cuePull
            }

            do {
                try await Task.sleep(for: .milliseconds(420))
            } catch {
                return
            }

            guard songContainerOpen, !studioDrawerOpen else { return }

            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                slotPull = 0
            }
            slotCueTask = nil
        }
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            toast = message
        }

        toastDismissTask?.cancel()
        toastDismissTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(1250))
            } catch {
                return
            }
            guard toast == message else { return }
            withAnimation(.easeOut(duration: 0.16)) {
                toast = nil
            }
            toastDismissTask = nil
        }
    }

    private func cancelWorkspaceTasks() {
        ritualTask?.cancel()
        ritualTask = nil
        importTask?.cancel()
        importTask = nil
        importStatusDismissTask?.cancel()
        importStatusDismissTask = nil
        toastDismissTask?.cancel()
        toastDismissTask = nil
        slotCueTask?.cancel()
        slotCueTask = nil
        playbackRuntime.cancelTicker()
        remoteCommandController.disable()
        liveActivitySync.cancel()
        playbackIntentObserver = nil
    }

    private func installPlaybackIntentObserverIfNeeded() {
        guard playbackIntentObserver == nil else { return }

        playbackIntentObserver = MotionRevealIntentDarwinObserver {
            NotificationCenter.default.post(
                name: MotionRevealIntentNotification.togglePlayback,
                object: nil
            )
        }
    }

    private func syncDynamicIslandActivity(
        track: MusicTrack? = nil,
        isPlaying: Bool? = nil,
        presentation: NowPlayingLiveActivityPresentation = .background,
        canStartNewActivity: Bool? = nil
    ) {
        liveActivitySync.perform(
            WorkspaceDynamicIslandCoordinator.action(
                selectedProject: selectedProject,
                nowPlaying: nowPlaying,
                playbackProgress: playbackProgress,
                preferredTrack: track,
                isPlayingOverride: isPlaying,
                presentation: presentation,
                canStartNewActivity: canStartNewActivity ?? (scenePhase == .active)
            )
        )
    }

    private func endDynamicIslandActivity() {
        liveActivitySync.perform(.end)
    }

#if DEBUG
    private var shouldSuppressImporterPresentationForUITest: Bool {
        WorkspaceLaunchAutomationPlan().suppressImporterPresentation
    }

    @MainActor
    private func runLaunchAutomationIfNeeded() async {
        guard !didRunLaunchAutomation else { return }
        let launchAutomation = WorkspaceLaunchAutomationPlan()
        guard launchAutomation.shouldRun else { return }

        didRunLaunchAutomation = true
        try? await Task.sleep(for: .milliseconds(650))

        if launchAutomation.simulateFilesImport {
            screen = .project
            slotReady = !selectedProject.tracks.isEmpty
            await simulateFilesImportForUITest()
        }

        if launchAutomation.simulateFailedAudioImport {
            screen = .project
            slotReady = !selectedProject.tracks.isEmpty
            await simulateFailedAudioImportForUITest()
        } else if launchAutomation.simulatePickerFailure {
            screen = .project
            slotReady = !selectedProject.tracks.isEmpty
            simulatePickerFailureForUITest()
        } else if launchAutomation.simulateAttachmentPickerFailure {
            screen = .project
            slotReady = !selectedProject.tracks.isEmpty
            simulateAttachmentPickerFailureForUITest()
        } else if launchAutomation.autoCreateDiscPrompt {
            createProject()
        } else if launchAutomation.autoCreateDiscRitual {
            createProject()
            try? await Task.sleep(for: .milliseconds(720))
            if let project = createdAlbumDiscPromptProject {
                activateCreatedAlbumDiscPrompt(project)
            }
        } else if launchAutomation.prepareSlotPull {
            screen = .project
            slotReady = !selectedProject.tracks.isEmpty
        } else if launchAutomation.openSongContainer || launchAutomation.openMarkersContainer {
            screen = .project
            slotReady = !selectedProject.tracks.isEmpty
            openSongContainer(revealStudioDrawer: false)
        } else {
            loadProject(selectedProject, sourceRect: libraryLeadSourceRect)
        }
    }

    @MainActor
    private func simulateFilesImportForUITest() async {
        guard let audioURL = WorkspaceUITestImportFixture.write(
            named: "Phone Bounce.wav",
            contents: "fake audio selected through UI test automation"
        ) else {
            showToast("UI test audio fixture failed")
            return
        }

        await importFlow.importAudioFiles([audioURL])

        guard !selectedProject.tracks.isEmpty,
              let attachmentURL = WorkspaceUITestImportFixture.write(
                named: "session notes.pdf",
                contents: "fake attachment selected through UI test automation"
              )
        else {
            return
        }

        await importFlow.importAttachmentFiles([attachmentURL])
    }

    @MainActor
    private func simulateFailedAudioImportForUITest() async {
        let missingAudioURL = WorkspaceUITestImportFixture.missingAudioURL(named: "Missing Phone Bounce.wav")
        await importFlow.importAudioFiles([missingAudioURL])
    }

    @MainActor
    private func simulatePickerFailureForUITest() {
        let error = NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadNoSuchFileError,
            userInfo: [NSLocalizedDescriptionKey: "The selected item is not available."]
        )
        handleImportPickerFailure(error, kind: .audio)
    }

    @MainActor
    private func simulateAttachmentPickerFailureForUITest() {
        let error = NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadNoSuchFileError,
            userInfo: [NSLocalizedDescriptionKey: "The selected attachment is not available."]
        )
        handleImportPickerFailure(error, kind: .attachment)
    }
#endif
}

#Preview("Music Workspace") {
    MusicWorkspaceView()
}
