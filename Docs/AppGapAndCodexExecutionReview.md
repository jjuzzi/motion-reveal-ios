# App Gap and Codex Execution Review

Date: May 24, 2026

This document is a candid checkpoint for Motion Reveal before the next build
push. It lists what the app is still lacking, what feels weak, where Codex did
not execute well enough, why those misses happened, and how to correct them.

The goal is not to dunk on the current prototype. The goal is to stop pretending
the rough parts are production-ready and give the next session a clean map.

## May 27 Update: Rive Retired

The user rejected the Rive path as too complicated. Treat older Rive-specific
recommendations in this document as historical context only. The active plan is
SwiftUI-owned ritual motion, no fake foreground Dynamic Island, and no
`RiveRuntime` dependency.

## Current Truth

The app has a working SwiftUI shell, local project/song data, audio file import,
song attachments, onboarding, a Live Activity / Dynamic Island extension, and a
side-loadable unsigned IPA.

The app is still not a polished v1. The strongest product idea is the local,
private music workspace built around song containers. The weakest execution
area is the signature motion: the sleeve/disc/Dynamic Island ritual still does
not feel as believable or premium as the original reference.

## Highest Priority Gaps

### 1. Signature Animation Is Still Below The Product Bar

The core ritual should feel like a physical music object leaving a sleeve,
rotating into edge profile, and being swallowed by the real Dynamic Island area.
The current SwiftUI fallback still reads too much like layered shapes moving on
top of the UI.

Why this matters:

- This animation is the app's main identity hook.
- If it feels cheap, the whole app feels cheap even if the data model works.
- The user explicitly values small motion quality as perceived quality.

What exists:

- SwiftUI fallback ritual in
  `MotionReveal/Features/MusicWorkspace/Motion/RitualOverlayViews.swift`.
- `WorkspaceRitualTiming.swift` shortens the root ritual waits when Reduce
  Motion is enabled, so accessibility users get a quick transition instead of
  sitting through the full choreography.
- The notch-adjacent top pull cue now stops its continuous ready-state logo spin
  when Reduce Motion is enabled, while keeping the direct pull affordance.
- The top-slot pull now routes through `DynamicSlotPullResponse`, which uses
  Motion's rubberband utility so the visible disc/thread follows the finger
  directly up to the open threshold, then resists instead of stretching
  linearly.
- Swift Package Manager now links `ShaderKit`, `Inferno`, and `Motion` in the
  app target. Treat `Motion` as a tool for future interruptible
  gesture/spring-driven top-slot interactions.
- The SwiftUI fallback disc and notch logo now use a centralized
  `StudioDiscMaterialProfile` plus a ShaderKit-backed `StudioDiscMaterialModifier`
  for restrained foil, shimmer, glass sheen, and edge highlights. Reduce Motion
  disables the animated shader path and leaves a static sheen fallback.
- Remotion pass 12 remains a reference study for timing, physicality, and
  contact-sheet comparison; it is not a Rive production handoff anymore.
- `Scripts/capture-ritual-contact-sheet.sh` now builds, installs, launches the
  app with `--auto-load-ritual`, records the booted simulator, and produces a
  contact sheet plus manifest for repeatable visual review.
- `Scripts/verify-ritual-readiness.sh` now reports a SwiftUI ritual runtime and
  marks Rive as retired instead of blocking on a `.riv` asset.
- Latest simulator evidence:
  `build/verification/in-app-ritual-20260525-032337/ritual-contact-sheet.jpg`
  and `build/verification/in-app-ritual-20260525-032337/ritual-capture.mp4`.
- The latest SwiftUI fallback adds a short-lived source slit/contact layer and
  contact shadow, then trims the top catch glow so it dies into the real
  island area instead of lingering as fake island chrome.

What is missing:

- Exact pass 12 choreography ported into the app.
- A passing visual comparison. The latest captured SwiftUI fallback does not
  hit the pass 12 standard: source emergence, top occlusion, and disc material
  response are better, but it still lacks the depth choreography and hardware
  swallow timing of the locked study.

Solution:

1. Treat Remotion pass 12 as locked choreography.
2. Keep SwiftUI responsible for navigation, gestures, Reduce Motion, data, and
   the active ritual animation.
3. Capture before/after simulator contact sheets every time the ritual changes.
4. Do not call the ritual finished until it scores at least 90/100 against the
   reference contact sheet.

Verification:

- Capture the full ritual on iPhone 16 Pro simulator with
  `Scripts/capture-ritual-contact-sheet.sh`.
- Run `Scripts/verify-ritual-readiness.sh --report-only` to confirm the SwiftUI
  ritual source is present and Rive remains retired.
- Compare against `build/remotion-ritual/contact-sheet-pass12.png`.
- Current evidence hashes:
  - In-app contact sheet:
    `742e2f32685357d45f7c819de320f28bacd0c97a3ab9a5c730f47dc993ddf855`.
  - In-app capture video:
    `c549a57f8951ed3eb9565e7bace420c996bf3690ce93404706bd90dfba4eb8c0`.
  - Locked Remotion pass 12 contact sheet:
    `4ec064aab73f438bbe9568f7d5e4c4d3d5be40fa1a6636421b433fafd2a6b7a7`.
- Verify no fake black Dynamic Island capsule is drawn.
- Verify Reduce Motion replaces the ritual with a calm, quick transition.

### 2. The Foreground Dynamic Island Story Is Still Conceptually Fragile

The app now uses a real ActivityKit / WidgetKit Live Activity for Dynamic
Island content when the app is not foregrounded. Inside the foreground app,
public iOS APIs do not let the app own the real Dynamic Island pixels. The app
uses an in-app top-edge cue instead.

Why this matters:

- The user wants the logo/function "in the notch."
- Apple allows this through Live Activities outside the foreground app, but
  foreground SwiftUI cannot draw inside system-owned Dynamic Island space.
- A fake notch inside the app immediately looks wrong.

What exists:

- `MotionRevealLiveActivity` widget extension.
- `NowPlayingActivityAttributes`.
- `NowPlayingLiveActivity`.
- URL handling for `motionreveal://song-container`.
- `OpenSongContainerIntent` exposes the song-container/studio-drawer handoff to
  App Intents, Shortcuts, Siri, and Spotlight-style system surfaces without
  pretending foreground SwiftUI can occupy the Dynamic Island.
- `PendingAppIntentRouteStore` gives the main SwiftUI scene one explicit route
  to consume when the app opens from the intent.
- A foreground top-edge pull cue.
- Simulator evidence exists at
  `build/verification/live-activity-sim-20260524-2343/`: an XcodeBuildMCP
  screenshot shows Motion Reveal's real Live Activity content in the system
  Dynamic Island while the app is backgrounded.
- `Docs/DeviceQAChecklist.md` now makes the Live Activity, App Shortcut, and
  foreground no-fake-island checks part of the side-loaded device gate.

What is missing:

- A crystal-clear product rule for what happens in foreground vs background.
- User-facing affordance that makes the foreground top-edge cue feel native,
  not like a fake Dynamic Island.
- Device testing on real iPhone hardware after side-loading, especially tapping
  the Dynamic Island/Lock Screen Live Activity back into the song container.
- Real Shortcuts/Siri/device validation for the new intent route.
- Optional future `AppEntity` support if the app needs shortcuts like "open a
  specific project" or "open a specific song container."

Solution:

1. Keep real Dynamic Island content only in the Live Activity extension.
2. In foreground, make the cue feel like a top-edge physical handle, not a
   second island.
3. Use the app logo/disc mark only as a subtle material element tucked under the
   real hardware area.
4. Document the limitation in product and engineering notes so future agents do
   not recreate the fake island.
5. Keep App Intents narrow: expose high-value verbs such as opening the current
   song container, but do not mirror the whole navigation tree.
6. Test tap/deep-link behavior from the Live Activity on a physical iPhone.

Verification:

- Background app while playing, confirm Dynamic Island shows the logo.
- Tap Dynamic Island, confirm it opens the song container path.
- Run the "Open Song Container" App Shortcut and confirm it opens the same
  studio-drawer route as the Live Activity URL.
- Foreground app, confirm there is no fake black capsule.
- Pull cue appears only when a real song/container can open.

### 3. The Product Concept Needs A Tighter First-Run Narrative

The app has onboarding now, but the product still needs a more confident
explanation through behavior rather than text. A new user should instantly
understand:

- Projects are containers.
- Songs live inside projects.
- Each song can hold audio, stems, sessions, notes, markers, refs, and exports.
- The top-edge pull reveals the song's hidden studio layer.

Current weakness:

- The app is becoming functional before the mental model is fully elegant.
- Some language still feels explanatory instead of embodied in the UI.
- The placeholder title `Motion Reveal` is useful internally but not a real
  brand.

What exists:

- A missing or unreadable local library now opens as an empty shelf instead of
  injecting sample projects or screenshot-era song residue.
- Legacy seed projects are stripped without falling back to sample content.
- The empty library state now has one primary action, "Create first sleeve,"
  and hides irrelevant shelf search/menu controls until a real project exists.
- Creating the first sleeve now activates that project and opens its project
  detail screen, putting the "Import audio" empty-track action directly in front
  of the user.

Solution:

1. Build one clean "empty to first song" guided path.
2. Replace generic explanatory copy with strong empty states and obvious actions.
3. Make the first project and first imported song feel like a ceremony, not a
   file-management chore.
4. Keep the working title neutral until naming is intentionally handled.
5. Create a separate naming/brand pass only after the core workflow feels right.

Verification:

- Fresh install has no dirty screenshot/sample song residue.
  Store-level tests now verify a missing local library loads as `[]`, and a
  fresh simulator reinstall now lands on onboarding followed by the empty
  "Create first sleeve" shelf instead of a seeded project.
- User can create/import a song without needing prior explanation.
  The first-sleeve path now routes from empty shelf -> new project -> empty
  track state, so the next visible action is importing audio. Simulator
  verification now covers tapping onboarding Start, tapping Create first sleeve,
  and landing on the new project screen with the Import audio empty-track call
  to action visible.
- Onboarding can be skipped, completed, and never repeats until version bump.
- Empty states show the next useful action, not filler.

### 4. Song Container Functionality Is Too Shallow

Song attachments exist, but the song container is not yet powerful enough to be
the center of a musician's workflow.

What exists:

- Attachments can be imported and displayed.
- Audio and attachment imports now share a visible status overlay with
  import-type-specific language, partial-failure counts, and the names of files
  that could not be copied.
- Import copying and audio metadata resolution now run through async processor
  methods instead of keeping file work main-actor-bound, and canceled import
  tasks stop before applying stale results.
- Attachment metadata is saved.
- Studio drawer can show attached files.
- The current pass adds row-level sharing for copied attachment files.
- Attachment removal now deletes the metadata row and attempts local copied-file
  cleanup behind a destructive confirmation.
- Attachment rename now uses the same native rename sheet as projects and
  tracks, changing only the local library display name.
- Attachment preview/open now uses native SwiftUI Quick Look from the file row,
  with a missing-file toast if the copied file is no longer available.
- Attachment categories now persist as editable local labels. Imports get a
  file-extension suggestion such as Audio, Session, Archive, Notes, Artwork, or
  File, but the user can replace that label in the file edit sheet.
- The studio drawer now includes an All/category filter strip derived from the
  song's actual attachment labels, with case-insensitive filtering.
- Larger studio drawers now group files under their user-authored category
  labels when the full attachment set is visible, so a dense song container is
  scannable without imposing fixed marker or file meanings.
- Studio drawer controls now respect the iOS 44pt touch floor: add/attach
  buttons and category filter chips use shared drawer touch metrics, and the
  drawer exposes named accessibility actions for open and close instead of
  relying only on drag gestures.
- Per-song Notes and Lyrics now exist as first-class local text documents inside
  each track, with a compact song-container panel and native edit sheet.
- Project search now includes song titles, imported artist/format metadata,
  attachment names/categories, marker notes, and per-song Notes/Lyrics text.
- Project export includes imported track audio plus resolved attachments.
- Song export includes the main track audio plus resolved attachments.
- Project and song export now generate shareable local text files for non-empty
  per-song Notes/Lyrics.
- Export construction now lives in `WorkspaceExportBuilder`, so project, track,
  and full song exports are built by a tested workflow object instead of
  root-view helper methods.

What is missing:

- Evidence that large audio/session files behave well on device.

Solution:

1. Test with real file types: `.wav`, `.mp3`, `.aif`, `.ptx`, `.flp`, `.zip`,
   `.pdf`, `.txt`, `.jpg`.

Verification:

- Import multiple files from Files app.
- Reopen app and confirm persistence.
- Delete an attachment and confirm local file cleanup behavior. Store-level unit
  coverage now verifies copied attachment URL resolution and idempotent removal.
- Share/export an attachment from the drawer row.
- Rename an attachment and confirm the local library display name persists.
- Tap an attachment row and confirm Quick Look presents when the local copy is
  present.
- Edit an attachment category and confirm it persists after relaunch.
- Filter the drawer by a category and confirm only matching attachments show.
- Edit Notes and Lyrics in the song container and confirm they persist after
  relaunch.
- Search for words inside Notes/Lyrics and confirm the owning song remains in
  the project results.
- Export a song/project with Notes/Lyrics and confirm generated text files are
  present in the share sheet. Unit coverage now verifies the export builder
  includes generated text files in project and song exports.
- Try unsupported or inaccessible files and confirm useful errors.
- Attempt a mixed successful/failed multi-file import and confirm the overlay
  names the failed file instead of silently doing nothing.

### 5. Waveform Markers Are Present But Not Yet Useful Enough

Markers exist visually, but the current flow is closer to a proof of concept
than a real producer note tool.

Implementation progress on May 24, 2026:

- Markers now live on each `MusicTrack` instead of one global workspace list.
- Marker arrays encode/decode with tracks and default safely for older saved
  projects.
- The song container has a visible add-marker button that creates a marker at
  the current playhead.
- Long-press marker creation now uses the touched waveform position to generate
  the marker time instead of hard-coded fake timestamps.
- Marker notes, times, and colors can be edited from a native sheet.
- Marker deletion exists from the same edit sheet.
- Tapping a marker in the waveform or marker list now jumps playback to that
  marker's timeline position.
- The May 24 PDF design pass added visible marker controls, editable notes,
  color choice, and resolved/reopened marker state. A follow-up removed
  predetermined marker categories so the user decides the marker meaning.
  See `Docs/PDFDesignSynthesis.md`.
- The marker list now has visible filters for All, Open, Resolved, and With
  notes. These filters are workflow states only; they do not impose marker
  names or marker categories.
- Marker touch targets now respect the iOS 44pt floor: waveform marker taps use
  a wider invisible hit area, the add-marker control keeps its compact visual
  mark inside a 44pt button, and filter chips now have a 44pt minimum hit
  height.
- Marker color meanings no longer depend on color alone. Each color token now
  has a distinct non-color SF Symbol for Differentiate Without Color contexts,
  marker rows/popovers/waveform hits expose richer VoiceOver summaries, and
  marker rows can grow beyond their minimum height for larger text settings.
- Unit coverage now verifies marker persistence, legacy decoding, draft
  trimming, color cycling, progress-to-time formatting, marker filtering, and
  model-level add/save/delete/resolve mutations, plus the marker hit-target
  floor, non-color marker symbols, and VoiceOver marker summary copy.

Weaknesses:

- Marker editing exists, but the flow still needs real-device QA for touch
  comfort and sheet ergonomics.
- Markers need stronger user-authored naming/annotation flow after real
  producer use.
- Markers do not yet feel like a reason to use the app.

Solution:

1. Improve user-authored marker naming/annotation after real song-container use.
2. Test marker creation/editing/deletion/resolve on real iPhone hardware.

Verification:

- Play a song, add a marker, edit its note, quit, reopen, and confirm it
  remains attached to that song.
- Tap marker and confirm playback jumps to that time.
- Filter markers by Open, Resolved, and With notes and confirm the list updates
  without hiding the underlying waveform marker positions.
- Confirm markers stay usable with VoiceOver and Dynamic Type.

### 6. Audio Playback Is Still MVP-Level

The app can import and play audio, but it is not yet a robust music app player.

What exists:

- Imported audio now uses readable file metadata when available for display
  title, artist, duration, and source format instead of always falling back to
  "Imported." Project track rows now surface a compact metadata line such as
  `Joseph · 3:12 · WAV`, or `May 25 · AIF` when artist/duration tags are
  unavailable.
- The player configures an iOS playback audio session, pauses on route loss
  such as unplugged headphones, pauses on interruption begin, and resumes after
  resumable interruptions only when playback was active before the interruption
  began. This prevents a paused track from unexpectedly starting after a phone
  call, Siri interruption, or other system audio interruption ends.
- The app declares the iOS background audio mode so playback has a platform
  path for continuing outside the foreground app.
- The mini player now keeps its transport and song-container buttons exposed as
  individual accessibility controls, uses 44pt hit areas for compact icon
  actions, and adds named accessibility actions for the swipe-only open/stop
  gestures.
- The full song-container playback strip now uses shared 44pt transport-button
  metrics for Previous, Play/Pause, and Next, so the main playback surface is no
  longer less touchable than the compact mini player.
- Standalone library/project/track ellipsis buttons now use shared workspace
  icon metrics instead of one-off 38-42pt frames, so admin menus keep the iOS
  44pt hit-target floor while retaining their named accessibility labels.
- `AudioPlaybackControllerTests` now use a fake playback engine to cover
  interruption begin/end, the system `shouldResume` option, paused-before-
  interruption behavior, and route-loss behavior without needing live hardware
  audio in the unit suite.
- Audio-session notification callbacks now immediately hop back to
  `@MainActor` before touching playback state, and failed audio-session
  reactivation aborts resume instead of calling play without an active session.
  Unit coverage posts a real `AVAudioSession.interruptionNotification` through
  `NotificationCenter` and covers the throwing-reactivation branch.
- `AudioPlaybackController` now removes audio-session observers from the same
  injected notification center it registered with, so tests and future
  non-default notification-center use do not leave stale selector observers
  behind after teardown.

Likely weak areas:

- Scrubbing precision.
- Large-file performance.
- Artwork extraction.

Solution:

1. Audit `AudioPlaybackController` against real-device playback scenarios.
2. Expand metadata extraction to include artwork and richer album/version
   display in the model.
3. Continue expanding player tests around state transitions where possible.
4. Profile large-file playback on device.

Verification:

- Import and play at least five real audio formats.
- Scrub, pause, resume, switch tracks, background app, and relaunch.
- Test AirPods/headphone route changes.
- Trigger an interruption on device and confirm playback pauses/resumes without
  stale UI state.
- Tests should fail if a paused track starts playing after a resumable
  interruption, or if route loss such as unplugged headphones allows a later
  interruption-ended event to restart playback.
- Tests should fail if `AudioPlaybackController` stops unregistering from its
  injected notification center when it deinitializes.

### 7. Visual Identity Is Not Yet Mature

The current UI is much improved from the first rejected shell, but it is not yet
a fully resolved premium music product. It still risks feeling like a stylish
prototype rather than an inevitable app.

Weaknesses:

- Brand name is unresolved.
- Icon and logo language exist, but the broader visual system is not locked.
- Some surfaces may still rely on glass/dark styling instead of strong
  information architecture.
- The app needs a calmer hierarchy so powerful features do not feel busy.

Current pass:

- The root `StudioBackdrop` now includes a restrained 3-layer starfield texture
  based on the supplied MetalForge preset
  (`speed=0.65`, `twinkleSpeed=3`, `twinkleAmount=0.3`, `layers=3`,
  `baseScale=50`, `scaleStep=80`, `density=0.145`, `starSize=0.065`). It is
  intentionally ambient: it gives the shelf and sleeve surfaces more depth
  without turning the app into a sci-fi skin.
- The starfield is deterministic and capped at 55 stars across all layers, so it
  avoids expensive overdraw. Twinkle animation pauses under Reduce Motion.
- The provided SwiftUI reference zips were treated as design references, not
  copied wholesale. The useful takeaways were palette-driven ambience from the
  image-background sample and careful overlay restraint from the toast/player
  examples.

Solution:

1. Create a visual identity board before another broad UI pass.
2. Define type scale, spacing, color roles, motion roles, and object materials.
3. Keep the UI music-native: sleeve, disc, tape, studio notes, session files,
   mix versions, references.
4. Avoid generic streaming-app clones and fake DAW dashboards.
5. Use visual verdict screenshots before and after each major UI pass.

Verification:

- Screenshot the four core states: library, project, song container, detail.
- Confirm each state is understandable without explanatory copy.
- Compare against the intended taste bar: Apple Music calm, Spotify utility,
  `[untitled]` simplicity, but with a distinct studio-container identity.
- Current simulator visual evidence exists at
  `build/verification/starfield-backdrop-20260525-033105/onboarding-starfield.jpg`
  with manifest
  `build/verification/starfield-backdrop-20260525-033105/manifest.txt`.
- Tests should fail if the starfield density drifts into a heavier overdraw
  budget or if Reduce Motion stops freezing the twinkle state.

### 8. App Architecture Needs Splitting Before More Feature Work

`MusicWorkspaceView.swift` is still about 1,209 lines. That is too large for
safe iteration, but it has moved in the right direction from the earlier
multi-thousand-line bundle.

Why this matters:

- It mixes app state, navigation, gestures, menus, onboarding, waveform UI,
  studio drawer UI, animation overlay, and utility views.
- Visual changes become risky because unrelated behavior lives nearby.
- Future agents will have a harder time making precise edits.

Solution:

Split the file into feature-owned files before adding more behavior:

- `MusicWorkspaceView.swift` - top-level composition only.
- `LibraryView.swift` - project shelf and empty library states.
- `ProjectDetailView.swift` - project screen, project search, and track list.
- `SongContainerView.swift` - focused song surface.
- `MiniPlayerView.swift` - now-playing capsule and mini waveform.
- `StudioDrawerView.swift` - attachments and hidden studio layer.
- `WaveformMarkerViews.swift` - waveform, markers, marker editor.
- `IslandSlotViews.swift` - top pull cue and foreground island affordance.
- `RitualOverlayViews.swift` - SwiftUI fallback ritual only.
- `OnboardingView.swift` - onboarding.
- `WorkspaceActionMenuContent.swift` - confirmation-dialog action menu content.
- `WorkspacePresentationModifiers.swift` - dialogs, edit sheets, Quick Look,
  and Files importers.
- `WorkspaceImportProcessor.swift` - Files import copying, audio metadata
  resolution, duplicate detection, and import status summaries.
- `WorkspaceImportFlow.swift` - import task choreography, importing status
  presentation, cancellation checkpoints, and import-result handoff.
- `WorkspaceLaunchAutomation.swift` - debug-only launch argument parsing and
  UI-test import fixture file creation.
- `WorkspaceExportBuilder.swift` - project, track, and song export file
  collection, including generated Notes/Lyrics text files and export failure
  reporting.
- `WorkspacePlaybackCoordinator.swift` - real/preview playback start, toggle,
  seek, tick, and stop decisions.
- `WorkspaceDestructiveActionExecutor.swift` - project deletion, track removal,
  and attachment removal state mutations.
- `WorkspaceProjectMutationExecutor.swift` - project creation, rename, duplicate,
  and pin state mutations.
- `WorkspaceTrackMutationExecutor.swift` - track rename, marker, song text, and
  attachment-detail state mutations.
- `WorkspaceImportMutationExecutor.swift` - imported audio and attachment append
  state mutations.
- `WorkspaceDynamicIslandCoordinator.swift` - Dynamic Island update/end routing
  decisions and ActivityKit handoff.
- `WorkspaceRitualTiming.swift` - standard versus Reduce Motion timing for
  load/create rituals.

Progress:

- The first behavior-preserving split is now in place:
  `WaveformMarkerViews.swift` owns the waveform panel, marker list, marker
  filters, marker rows, and marker note popover.
- The second behavior-preserving split is now in place:
  `StudioDrawerView.swift` owns the studio drawer, attachment grouping,
  category filter strip, empty attachment state, attachment rows, Quick Look
  opener rows, share buttons, edit buttons, and destructive remove buttons.
- The third behavior-preserving split is now in place:
  `IslandSlotViews.swift` owns the foreground top pull zone, disc/logo mark,
  and slot guide affordance, while the deeper insertion hardware still belongs
  to the ritual overlay work.
- The fourth behavior-preserving split is now in place:
  `RitualOverlayViews.swift` owns the SwiftUI fallback ritual, sleeve-to-island
  choreography, insertion hardware, disc shapes, shimmer/glow layers, and
  animated iridescent pool.
- The fifth behavior-preserving split is now in place:
  `OnboardingView.swift` owns the first-run onboarding screen, top-pull preview,
  and onboarding step rows.
- Shared primitives are now split out to support the larger flow extractions:
  `WorkspaceChromeViews.swift` owns the reusable top bar, icon actions, icon
  buttons, and menu glyph; `SleeveArtworkViews.swift` owns sleeve artwork
  rendering and its private art helpers.
- The first full flow extraction is now in place:
  `LibraryView.swift` owns the library shelf screen, coordinate-space source
  frame reader, empty library state, sleeve deck, deck meter, project spine
  list, and sleeve rows.
- The second full flow extraction is now in place:
  `ProjectDetailView.swift` owns the project detail screen, project search
  field, track list, and track action rows.
- The third full flow extraction is now in place:
  `SongContainerView.swift` owns the focused song container, container playback
  strip, song text panel, and song text cards.
- The fourth full flow extraction is now in place:
  `MiniPlayerView.swift` owns the now-playing capsule, mini transport buttons,
  sleeve play button, and mini waveform.
- `WorkspaceStatusViews.swift` is back to import/empty-track status surfaces
  instead of also carrying marker interaction UI.
- `WorkspaceActionMenuContent.swift` now owns the project, track, and song
  confirmation-dialog button content, leaving `MusicWorkspaceView.swift` to
  provide the concrete actions.
- `WorkspacePresentationModifiers.swift` now owns the confirmation dialog,
  destructive alert, edit/export sheets, Quick Look preview, and Files import
  presenters, leaving `MusicWorkspaceView.swift` to provide bindings and action
  closures.
- `WorkspaceImportProcessor.swift` now owns the file-processing part of audio
  and attachment imports, including duplicate skipping, metadata resolution,
  failed-file collection, and result-to-status mapping. New tests cover duplicate
  audio imports, same-picker-batch duplicate audio imports, unsupported audio
  selections, and partial attachment failures.
- `WorkspaceImportFlow.swift` now owns the user-facing import choreography for
  audio and attachment files: empty-selection handling, loading status, short
  feedback delay, cancellation checks, and handoff into root-owned project
  mutations. This removes the import async sequence from `MusicWorkspaceView`
  while keeping presentation and project state mutation explicit at the root.
- `WorkspaceExportBuilder.swift` now owns project/track/song export assembly,
  including local audio resolution, attachment resolution, generated Notes/Lyrics
  text files, and text-export failure counts. New tests prove project exports
  include song audio, attachments, and text notes, while track-only exports stay
  audio-only and song exports include the full container file set.
- `WorkspacePlaybackCoordinator.swift` now owns the real-versus-preview playback
  decisions, toggle/seek/tick progress updates, stop forwarding, and playback
  status copy. New tests cover preview start behavior and preview progress
  updates.
- `WorkspaceDestructiveActionExecutor.swift` now owns the project deletion,
  track removal, and attachment-row mutation outcomes. New tests cover selected
  project deletion and attachment removal.
- `WorkspaceProjectMutationExecutor.swift` now owns project creation, rename,
  duplicate, and pin state mutation outcomes. New tests cover fresh-project
  insertion and activation, selected-project rename, duplicate insertion order,
  duplicate reset-to-regular behavior, and pin toggling.
- `WorkspaceTrackMutationExecutor.swift` now owns track rename, attachment detail,
  song text, and marker state mutations. New tests cover track rename, attachment
  update and missing-attachment no-op behavior, deterministic song text updates,
  marker replacement, marker add/save, and marker resolve/delete behavior.
- `WorkspaceImportMutationExecutor.swift` now owns imported audio and attachment
  append mutations. New tests cover imported-track append order/count syncing,
  attachment append syncing, and missing-track no-op behavior.
- `WorkspaceDynamicIslandCoordinator.swift` now owns Dynamic Island action
  selection, fallback track choice, play/pause derivation, and ActivityKit
  handoff. New tests cover end-without-track, preferred-track override behavior,
  now-playing behavior, and fallback-not-playing behavior.
- `WorkspaceRitualTiming.swift` now owns standard versus Reduce Motion delay
  budgets for the load and create rituals. New tests prove the reduced-motion
  path stays under 250ms for each root transition instead of preserving the full
  multi-second choreography.
- `IslandPullGuideMotion` now owns the top pull cue's ready-state spin decision.
  A focused unit test proves the continuous spin is disabled when Reduce Motion
  is enabled.
- `MusicWorkspaceView.swift` now retains and cancels transient toast and import
  status dismissal tasks, and cancels outstanding ritual/import/playback UI
  tasks when the root view disappears. This keeps temporary feedback from being
  cleared by stale unstructured tasks after a newer toast/status appears.
- The large visual flow splits are now done. The remaining architecture debt is
  root coordination and non-destructive mutation logic: `MusicWorkspaceView.swift`
  still owns too much app state and should eventually move toward a dedicated
  workspace session model. The import flow split is the first step toward that
  session-model boundary because it isolates an async user workflow without
  hiding the root mutations.
- A small root-chrome split now moves `StudioBackdrop`, `CreateProjectButton`,
  and `ToastView` into `WorkspaceRootChromeViews.swift`, while import
  cancellation classification lives in `WorkspaceImportError.swift`.
- `WorkspaceSongContainerCoordinator.swift` now owns the pure decision for
  opening the song container: no-track failure, first-track fallback,
  preserving an existing now-playing track, and mapping deep-link/App Intent
  routes to the studio-drawer reveal. `MusicWorkspaceView.swift` still owns the
  SwiftUI state mutation and animation.
- `WorkspaceLaunchAutomation.swift` now owns debug-only launch argument parsing
  and UI-test import fixture creation. This keeps test automation scaffolding
  out of the root SwiftUI view while preserving the existing UI-test routes.
  New unit tests cover normal-launch no-op behavior and simulated Files-import
  route detection.

Verification:

- Refactor in small slices.
- Run tests after each slice.
- Confirm no user-visible behavior changes during the split.

### 9. Test Coverage Is Too Model-Heavy And Too Light On Flows

The tests cover useful model behavior, but they do not yet prove the app works
through the flows the user cares about.

Remaining missing flow coverage:

- Import audio from Files.
- Import attachments.
- Open song container by real App Shortcut on device.
- Live Activity deep link behavior.
- Real Files picker selection on physical device.
- Physical-device proof that the URL deep link behaves like the simulator
  `motionreveal://song-container` proof.
- Physical-device proof that the top-slot pull behaves like the simulator
  gesture.

What exists:

- `MotionRevealUITests` now covers the fresh install shell path:
  reset UI-test state -> onboarding -> empty library -> Create first sleeve ->
  project screen -> empty Import audio state.
- `DebugLaunchStateReset` clears onboarding, pending App Intent route, and local
  library/import folders only for debug launches using
  `--reset-ui-test-state`.
- `MotionRevealFirstRunUITests` also seeds a project/track/attachment and opens
  the song container with the studio drawer, proving the app-level container
  route renders real song context instead of stopping at model tests.
- `MotionRevealFirstRunUITests.testSeededLibraryPersistsAfterRelaunch` now
  terminates and relaunches the app without reseeding, then reopens the song
  container to prove the saved project, track, attachment type, and attachment
  filename are still present.
- `MotionRevealFirstRunUITests.testSimulatedFilesImportAddsAudioAttachmentAndPersistsAfterRelaunch`
  drives an import-adjacent UI path that writes selectable audio and attachment
  files, runs them through the same copy/import/mutate/persist pipeline as the
  Files picker result, opens the song container, then relaunches without
  reseeding to prove the imported track and attachment survive.
- `MotionRevealFirstRunUITests.testSimulatedFilesImportShowsAudioFormatMetadataInProjectRow`
  keeps the import-adjacent flow on the project screen and verifies the visible
  track row metadata includes the imported source format, so audio metadata
  display is covered at the UI layer instead of only by model tests.
- The importer now owns the current import task and cancels any previous import
  before starting the next one, avoiding overlapping unstructured import work
  when a user retries quickly.
- `WorkspaceImportProcessor` is no longer main-actor-bound for file copying and
  metadata reads. `MusicLibraryStore` is sendable by construction, and
  `MusicWorkspaceView` checks task cancellation again before mutating project
  state after an import result returns.
- `MusicWorkspaceModelTests.testWorkspaceImportProcessorHonorsCancellationBeforeCopying`
  verifies a canceled audio/attachment import does not report copied files.
- `MusicWorkspaceModelTests.testWorkspaceImportProcessorSkipsDuplicateAudioInsideSamePickerBatch`
  verifies the processor only copies one copy of a duplicated audio source
  returned in the same picker result and reports the skipped item.
- `MusicWorkspaceModelTests.testWorkspaceImportProcessorRejectsUnsupportedAudioFiles`
  verifies non-audio URLs are named as failures before copy while valid audio
  URLs in the same picker result still import.
- Duplicate-only import results now count as attention states and stay visible
  for 4.8 seconds, so "Already in this sleeve" cannot disappear like a normal
  quick success toast.
- Files picker failures now enter the same visible import-status surface as
  copy failures instead of disappearing as a generic toast. User cancellation
  stays lightweight, while unreadable picker results and partial copy failures
  remain visible for 4.8 seconds with recovery copy.
- A picker callback that succeeds but returns zero readable URLs now also enters
  the same import-status failure surface for audio and attachments. This closes
  another "Open did nothing" path by keeping the message visible long enough to
  read instead of using a short toast.
- `MotionRevealTests.MusicWorkspaceModelTests.testImportStatusReportsPickerFailureWhenNoReadableFileReturns`
  covers the empty picker-failure copy so "Open" can fail visibly instead of
  feeling like nothing happened.
- `MotionRevealTests.MusicWorkspaceModelTests.testWorkspaceImportFlowReportsEmptyAudioPickerResultAsVisibleFailure`
  and
  `testWorkspaceImportFlowReportsEmptyAttachmentPickerResultAsVisibleFailure`
  cover the flow-level empty-result routing before any file-copy work begins.
- Import status overlays now expose a purpose-built accessibility label instead
  of relying on SwiftUI to combine visual children. The VoiceOver sentence
  normalizes newline and summary separators, so partial success and failure
  states are readable when they appear.
- `MotionRevealFirstRunUITests.testMarkerCanBeAddedEditedAndPersistsAfterRelaunch`
  now opens the song container in a marker-focused state, taps the visible add
  marker control, edits the marker note through the sheet, relaunches, and
  verifies the edited marker note still appears.
- Marker note verification now waits for the exact user-entered note text after
  a controlled song-container scroll, avoiding broad accessibility queries that
  previously made the UI runner fragile during relaunch persistence checks.
- `MotionRevealFirstRunUITests.testTopSlotPullOpensSongContainerAndStudioDrawer`
  now starts on the project screen with the top slot ready, taps the visible
  notch-adjacent slot button, and proves the song container plus studio drawer
  open with the seeded song context. The production control still supports a
  downward pull, but the visible button/accessibility route keeps the action
  discoverable and testable instead of making the drawer gesture-only.
- `MusicWorkspaceModelTests.testDynamicSlotPullDecisionOpensOnlyAfterIntentionalPull`
  covers the pull threshold separately, so a future pull-threshold drift fails
  without depending on XCUITest raw drag delivery.
- `MusicWorkspaceModelTests.testDynamicSlotPullResponseRubberbandsVisualPullAfterThreshold`
  and
  `MusicWorkspaceModelTests.testDynamicSlotPullResponseRequiresHoldOrPullBeforeArming`
  protect the Motion-backed rubberband response and arming rules for the
  foreground slot cue.
- `MusicWorkspaceModelTests.testStudioDiscMaterialProfileDialsBackForReduceMotion`,
  `MusicWorkspaceModelTests.testStudioDiscMaterialProfileReducesFaceEffectsAtEdgeProfile`,
  and `MusicWorkspaceModelTests.testStudioDiscMaterialProfileClampsInputs`
  protect the ShaderKit material profile constants and the Reduce Motion
  fallback for the disc/notch-logo surface.
- `MotionRevealFirstRunUITests.testMiniPlayerKeepsTransportControlsAccessible`
  proves the seeded mini player exposes Play, Previous track, Next track, and
  Open song container as accessible buttons instead of hiding them behind the
  now-playing capsule.
- `MotionRevealFirstRunUITests.testPendingAppIntentRouteOpensSongContainerAndStudioDrawer`
  writes the same pending song-container route that `OpenSongContainerIntent`
  writes, launches the app with seeded song context, and proves the root scene
  consumes the pending route into the song container plus studio drawer.
- `WorkspaceDeepLinkRoute` now owns the URL parsing for
  `motionreveal://song-container`, with unit coverage rejecting unknown hosts
  and non-app schemes.
- `MotionRevealDeepLink.songContainerURL` is shared by the app and
  `MotionRevealLiveActivity`, so the Live Activity widget URL and the app's
  parser can no longer drift into different route strings without a test/build
  failure.
- Simulator deep-link evidence now exists at
  `build/verification/deep-link-20260524-2326/`: `simctl openurl` produced the
  real iOS "Open in Motion Reveal?" confirmation, and tapping Open routed to
  the song container plus studio drawer with the seeded song context.

Solution:

1. Add UI tests for first-run and import-adjacent flows where feasible.
2. Add integration tests around persistence and migration.
3. Add focused tests for URL handling and song-container selection.
4. Add screenshot/contact-sheet verification for the ritual.
5. Keep the App Intent route covered at the handoff-store level, then add a UI
   or device check that proves the shortcut opens the song container.

Verification:

- Tests should fail if first launch shows old fake song data.
  `MotionRevealFirstRunUITests` explicitly rejects the old screenshot seed text
  and requires the empty library/project/import route to appear.
  Current simulator suite includes first-run, song-container route, seeded
  relaunch-persistence, import-adjacent relaunch-persistence, and marker
  add/edit/relaunch, marker hit-target coverage, studio-drawer hit-target
  coverage, song-container transport hit-target coverage, mini-player
  accessibility, standalone workspace icon hit-target coverage, top-slot pull
  UI tests, imported-audio metadata row display, top-pull Reduce Motion
  coverage, marker non-color accessibility coverage, audio interruption/route-loss
  coverage, starfield density/Reduce Motion coverage, and deep-link route unit
  coverage. Current simulator verification passes `111/111` unit tests and all
  `9/9` UI flows when the UI runner is split
  into stable batches. The all-in-one UI/full-suite runner still intermittently
  kills long flows; the latest historical full-target attempt reported `5/8` UI
  tests passed and the remaining failures as XCTest runner `signal kill`, not
  assertion failures. Use focused/split UI evidence until the runner stability
  issue is separately addressed.
- Tests should fail if the import pipeline does not create a track from a
  selected file URL.
- Tests should fail if imported audio source-format metadata is not visible in
  the project row after the import flow.
- Tests should fail if an unsupported audio-file selection is copied into the
  library instead of being named as a failed file.
- Tests should fail if a duplicate audio source inside one picker batch is copied
  twice instead of being reported as skipped.
- Tests should fail if duplicate-only import feedback returns to the short
  auto-dismiss path and becomes easy to miss.
- Tests should fail if project/song export construction stops including
  resolved local audio, attachments, or generated Notes/Lyrics text files.
- Tests should fail if imported attachments disappear after relaunch; the
  remaining gap is proving the real iOS Files picker callback behaves the same
  way on physical device.
- Tests should fail if picker/copy failures stop producing readable status
  copy, but simulator tests still cannot prove the physical Files app returns
  the same kind of security-scoped URL on the side-loaded device.
- Tests should fail if an empty successful picker result goes back to a short
  toast or silent no-op instead of the visible import-status failure surface.
- Tests should fail if the import-status VoiceOver sentence regresses into
  unclear punctuation or loses the recovery message.
- Tests should fail if a marker can no longer be added, edited, or recovered
  after relaunch from the song container UI.
- Tests should fail if the simulator top-slot button/fallback can no longer
  open the song container and studio drawer, or if the pull threshold changes
  unintentionally; the remaining pull gap is physical-device proof.
- Tests should fail if the pending App Intent route no longer opens the song
  container and studio drawer in the main SwiftUI scene; the remaining App
  Shortcut gap is invoking the real Shortcuts/Siri/Spotlight surface on device.
- Tests should fail if the song-container opening decision stops preserving
  the current track, stops falling back to the first project track, or stops
  opening the studio drawer for deep-link/App Intent routes.
- Tests should fail if `motionreveal://song-container` no longer maps to the
  song-container route; simulator evidence should show the real iOS URL handoff
  opens the app and drawer.
- Tests should fail if the Live Activity widget URL stops sharing the same
  route constant as the app parser; the remaining Live Activity gap is tapping
  the hardware Dynamic Island/Lock Screen surface on a device.
- Visual review should fail if the captured ritual sheet drifts from pass 12 or
  reintroduces fake foreground Dynamic Island chrome.

### 10. Side-Loaded Device QA Is Not Complete

The app has an unsigned IPA and the user side-loaded it. Physical-device QA now
has a written gate, but the current build still needs a real Dynamic Island
iPhone pass before it can be called device-verified.

What exists:

- `Docs/DeviceQAChecklist.md` with fresh install, upgrade, Files import,
  playback, song container, Dynamic Island, App Shortcut, motion, and known
  issue gates.
- `Scripts/collect-device-qa-logs.sh` captures `devicectl`/`xcdevice`
  inventory and MotionReveal-filtered `idevicesyslog` output into
  `build/device-qa/<timestamp>/`.
- Current local device inventory shows paired iPhones as unavailable, so the
  Dynamic Island hardware pass remains pending.

What is missing:

- A completed checklist run on a physical Dynamic Island iPhone.
- Real Files app import evidence from device.
- Live Activity tap/deep-link proof from hardware.
- App Shortcut proof from Shortcuts/Siri/Spotlight on device.
- Device logs attached to any remaining import/playback/Live Activity failures.
- Physical-device execution of the generated build traceability loop. The local
  tooling now emits `build/sideload/manifest.txt` with the IPA path, SHA-256,
  bundle ID, version, timestamp, and build log path, and
  `Scripts/collect-device-qa-logs.sh` copies those fields into each device QA
  evidence manifest. The remaining gap is using that evidence during an actual
  connected-device pass.

Solution:

1. Keep `Docs/DeviceQAChecklist.md` updated after every side-loaded IPA.
2. Add every reported device issue with reproduction steps and status.
3. After each IPA, run the same checklist before calling it good.
4. Capture device logs with `Scripts/collect-device-qa-logs.sh` for import,
   playback, and Live Activity failures.
5. Do not treat simulator import, simulator Live Activity behavior, or passing
   unit tests as a substitute for the physical-device gates.
6. Keep the generated sideload manifest and copied device-QA manifest fields
   attached to every device pass.

Verification:

- Fresh install path.
- Upgrade install path.
- Import audio.
- Attach files.
- Play/pause/scrub.
- Background and Dynamic Island.
- Reopen and persistence.
- App Shortcut opens the song container/studio drawer.
- Device logs exist for any failed item.
- Device QA evidence identifies the exact IPA SHA-256 that was installed and
  tested.

## Things Codex Did Not Execute Well Enough

### 1. Codex Let The Prototype Outrun The Product Conversation

What happened:

The app shell and UI direction moved forward before the concept was fully
interviewed and locked. This produced placeholder UI the user immediately hated.

Why it happened:

- The task started with tools/resources and motion references, not a complete
  product spec.
- Codex over-weighted "make progress" and under-weighted "keep the product
  conversation alive."
- The initial reference was a motion grammar, not a full app design, but Codex
  treated the shell as if it could safely infer the product around it.

Solution:

- Before broad UI work, require a one-page product lock:
  audience, core job, first-run path, four core screens, and taste references.
- Keep temporary names and sample UI visibly disposable.
- Do not polish rejected directions.

Future prompt pattern:

```text
Before coding, restate the current product lock in 10 bullets. If any bullet is
missing or inferred, mark it as unresolved and ask or propose the smallest safe
assumption. Do not implement broad UI until the lock is complete.
```

### 2. Codex Underestimated The Signature Animation

What happened:

The main animation stayed flimsy for too long. Small SwiftUI tuning passes could
not reach the reference quality.

Why it happened:

- The animation required authored physical choreography, not just spring
  constants.
- SwiftUI shape composition is useful for prototyping but weak for nuanced
  occlusion, depth, and material response.
- Codex tried incremental parameter changes after the user had already named a
  qualitative problem.

Solution:

- Use the Remotion pass 12 study as the locked motion bible.
- Move the final ritual toward the pass 12 quality bar inside SwiftUI instead
  of restoring Rive.
- Compare contact sheets visually every iteration.
- Use `Scripts/capture-ritual-contact-sheet.sh` to generate the in-app evidence
  before claiming any motion improvement.

Future prompt pattern:

```text
Treat the animation as a product-critical asset. Do not tune by vibes only.
Capture a contact sheet, compare it to the locked reference, name the specific
frame-level mismatch, then make one targeted change.
```

### 3. Codex Initially Built A Fake Dynamic Island

What happened:

The app drew a fake notch/Dynamic Island-like capsule in foreground UI, which
looked wrong on a real iPhone.

Why it happened:

- Codex blurred the line between a visual metaphor and a system-owned hardware
  region.
- The first solution optimized for "show the idea" instead of respecting iOS
  platform boundaries.
- The foreground limitation was not documented early enough.

Solution:

- Keep ActivityKit for real Dynamic Island content.
- Keep foreground SwiftUI as a top-edge cue only.
- Ban fake black capsules in the app's design docs and visual reviews.

Future prompt pattern:

```text
For Dynamic Island work, first classify the state as foreground app, background
Live Activity, or lock screen. Only the Live Activity may render inside the real
Dynamic Island. Foreground app UI must never draw a fake island.
```

### 4. Codex Did Not Split The SwiftUI File Soon Enough

What happened:

`MusicWorkspaceView.swift` grew into a multi-thousand-line feature bundle.
Cleanup slices have moved waveform/marker interaction views into
`WaveformMarkerViews.swift` and studio drawer/attachment views into
`StudioDrawerView.swift`. The foreground pull cue now lives in
`IslandSlotViews.swift`, and the SwiftUI fallback ritual now lives in
`RitualOverlayViews.swift`. The first-run onboarding surface now lives in
`OnboardingView.swift`, but the main view still needs more flow-owned splits.

Why it happened:

- Fast iteration favored local edits in one file.
- SwiftUI makes it easy to keep adding small nested views.
- The architecture cleanup was delayed because visible product issues felt more
  urgent.

Solution:

- Continue refactoring before adding the next meaningful feature.
- Split by user flow, not by arbitrary component size.
- Add regression tests around existing behavior before moving code.

Future prompt pattern:

```text
Before adding new behavior to MusicWorkspace, check whether the touched file is
already over 500 lines. If yes, split the relevant view boundary first while
preserving behavior, then add the feature.
```

### 5. Codex Did Not Verify Physical Device Behavior Deeply Enough

What happened:

The IPA was produced and side-loaded, but some issues only showed up when the
user tested on device, such as Files import not doing anything.

Why it happened:

- Simulator success was treated as too strong a signal.
- Files app security-scoped URLs and real-device behavior need specific tests.
- Device QA lacked a repeatable checklist.
- Import file copying initially stayed too close to the main actor, which could
  make large real-device Files imports feel like the Open button did nothing.

Solution:

- Add a device QA checklist.
- Treat every side-loaded IPA as untrusted until device import/playback/storage
  paths pass.
- Make picker/copy failure states visible and long enough to read, so device
  testing can distinguish "the picker did not return a readable file" from
  "the app ignored the Open button."
- Keep transient import/toast feedback lifecycle-managed so a stale delayed
  task cannot erase the status needed for device debugging.
- Keep expensive file-copy and audio-metadata work off the main actor and
  cancel stale import tasks before they apply results.
- Capture device logs for failed flows.

Future prompt pattern:

```text
After packaging an IPA, produce a physical-device QA checklist and mark each
item pass/fail/untested. Do not call the IPA ready without listing the untested
items.
```

### 6. Codex Did Not Preserve The User's Taste Boundary Firmly Enough

What happened:

Some generated UI and names drifted into generic or disliked territory.

Why it happened:

- The app lacked a locked taste board.
- Codex interpreted "like this but music related" too broadly.
- Placeholder names and visual shells were allowed to feel more final than they
  were.

Solution:

- Maintain a taste contract document.
- Use screenshots/contact sheets as evidence, not adjectives.
- Keep rejected directions in a "do not repeat" list.

Future prompt pattern:

```text
Before visual edits, list the user's explicit dislikes and the current taste
contract. Any proposed UI that violates the list is invalid even if it is
technically clean.
```

## Structured Review Log

Primary designer:

The app should continue as a local-first, private music workspace where songs
are containers for creative assets. The signature object motion must become a
real authored asset, not a decorative SwiftUI trick.

Skeptic:

The app can fail even if it builds because the signature interaction is still
the weakest part. If the animation remains cheap, users will not trust the
premium promise.

Constraint guardian:

Do not fight iOS system ownership of the Dynamic Island. Use ActivityKit where
allowed, foreground top-edge affordances where not allowed, and keep app state
native SwiftUI.

User advocate:

The user should not have to understand implementation details. They should feel:
"this project contains my songs, this song contains my files, and the top pull
opens the hidden studio layer."

Arbiter:

The next best move is not more random UI polish. The next best move is a focused
sequence: split the giant SwiftUI surface, tune the SwiftUI ritual against the
locked pass 12 reference, then complete the song-container workflows and device
QA checklist.

## Recommended Next Build Sequence

1. Continue splitting `MusicWorkspaceView.swift` into flow-owned files without
   changing behavior.
2. Extend regression tests around import, attachments, markers, deep links, and
   App Intent handoffs.
3. Run `Scripts/capture-ritual-contact-sheet.sh` before and after any ritual
   edits.
4. Port the strongest Remotion pass 12 timing/occlusion ideas into the SwiftUI
   ritual implementation.
5. Build marker editing and attachment actions.
6. Run `Docs/DeviceQAChecklist.md` on a physical Dynamic Island iPhone.
7. Package a new IPA.
8. Run the device checklist before accepting the build.

## Definition Of A Credible V1

A credible v1 should satisfy all of these:

- Fresh install is clean.
- User can create or open a project.
- User can import a song from Files and it visibly appears.
- User can play the song.
- User can add markers at playback positions and edit marker notes.
- User can attach real files to the song.
- Top-edge pull opens the song container/studio drawer.
- App Intent shortcut opens the same song container/studio drawer route.
- Background Live Activity shows the app mark in the real Dynamic Island on
  supported devices.
- Foreground app does not draw a fake Dynamic Island.
- Signature ritual meets the pass 12 quality bar or uses a reduced motion-safe
  fallback.
- App state survives relaunch.
- IPA is packaged and device-tested against a written checklist.

## Prompt Template For Future Codex Sessions

Use this when resuming the app:

```text
You are continuing Motion Reveal at
/Users/joseph/Developer/motion-reveal-ios.

Before coding, read:
- AGENTS.md
- Docs/AppGapAndCodexExecutionReview.md
- Docs/ActiveAnimationHandoff.md
- Docs/RiveIslandRitual.md (retired path warning only)
- Scripts/capture-ritual-contact-sheet.sh
- Docs/DeviceQAChecklist.md
- Scripts/collect-device-qa-logs.sh

Product lock:
- Local-first private music workspace.
- Projects contain songs.
- Songs contain audio, markers, notes, refs, stems, DAW sessions, exports, and
  related files.
- The signature ritual is sleeve/disc/top-island insertion.
- Do not draw a fake Dynamic Island.
- Real Dynamic Island content must use the Live Activity extension.
- Foreground app uses only a top-edge cue.
- The motion quality target is Remotion pass 12.

Work pattern:
1. State the exact gap being addressed.
2. Inspect the current implementation.
3. Make the smallest useful change.
4. Run relevant tests or simulator/device verification.
5. Report changed files, evidence, and remaining risk.

Do not polish rejected placeholder UI. Do not add new dependencies unless asked.
Do not call the animation done without screenshot/contact-sheet evidence.
```
