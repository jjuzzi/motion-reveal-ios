# Multi-Agent Weakness Review

Date: May 26, 2026

Disposition: REVISE

May 27 update: this review predates the user decision to retire Rive. Treat
Rive-specific asset recommendations below as historical context only. The active
path is SwiftUI-owned signature motion, no fake foreground Dynamic Island, and
no `RiveRuntime` dependency.

This review used the multi-agent brainstorming structure: primary designer,
skeptic, constraint guardian, user advocate, and arbiter. The goal was to find
weaknesses in the current app and convert them into implementable improvements.
Useful or intuitive missing behaviors count as weaknesses when their absence
makes the app less obvious, less premium, or less reliable.

## Understanding Lock

- App direction: local-first, private, iPhone-first music workspace.
- Core mental model: projects are sleeves; songs live inside projects; each song
  owns audio, notes, markers, motion artwork, and attached studio files.
- Signature interaction: blank disc appears after creating a project, then enters
  the top slot/notch player after the user taps it.
- Studio drawer rule: the drawer should stay hidden until the user intentionally
  holds the top slot/dynamic-notch cue and pulls down.
- Platform rule: real Dynamic Island content is ActivityKit/WidgetKit when the
  app is backgrounded; foreground SwiftUI must use a top-edge cue, not a fake
  system island.
- Current review boundary: identify weaknesses and implementation candidates,
  not broad new product scope.

## Primary Designer Draft

The app has the right raw ingredients: local library state, document import,
audio playback, song container, studio drawer, markers, notes/lyrics, animated
artwork wiring, Live Activity, and the created-disc stage. The next product pass
should not add random surfaces. It should tighten four loops:

1. First sleeve to first imported song.
2. Playing track to full song container.
3. Top slot hold/pull to studio drawer.
4. Background playback to Dynamic Island controls.

## Skeptic Review

### Objection 1: The signature ritual still needs production-quality motion.

Evidence:

- `Scripts/verify-ritual-readiness.sh --report-only` now reports a SwiftUI
  ritual runtime and marks Rive as retired.
- The app still needs contact-sheet evidence that the SwiftUI ritual reaches
  the pass 12 quality bar.
- `Docs/RiveIslandRitual.md` is now a retired-path warning, not an asset
  contract to implement.

Risk:

The fallback may keep improving, but the app can still feel like a shape demo
instead of a premium object ritual.

Implementable improvement:

- Keep the ritual SwiftUI-owned and port the strongest pass 12 timing,
  occlusion, and contact-shadow ideas into the app implementation.
- Add an automated visual-readiness gate to the IPA/export checklist so a build
  cannot be called visually final without fresh contact-sheet evidence.

### Objection 2: The top slot gesture can be discovered by accident, not intent.

Evidence:

- `DynamicSlotPullResponse.armHoldDuration` is `0.12`.
- `DynamicSlotPullResponse.openThreshold` is `34`.
- `DynamicSlotButton` uses `DragGesture(minimumDistance: 0)` over a
  `300 x 112` invisible zone.

Risk:

The gesture may open too easily, especially near the iPhone system area, while
still being hard for a new user to understand deliberately.

Implementable improvement:

- Increase the arm duration and/or threshold after real-device testing.
- Add a tiny progressive affordance only after a song is playing.
- Add UI tests for short tap, short drag, long hold without pull, successful
  hold-and-pull, and Reduce Motion behavior.

### Objection 3: The song container now has the right pieces, but it still reads
as panels rather than one focused music instrument.

Evidence:

- `SongContainerView` stacks artwork/playback, waveform, motion artwork, song
  text, and markers in a scroll view.
- The copy still explains the concept: "Main bounce, edit markers, and studio
  attachments stay inside this song."

Risk:

The screen can feel like a dashboard instead of the natural place to work on one
song.

Implementable improvement:

- Make waveform plus play controls the hero surface.
- Turn notes, lyrics, motion artwork, and markers into a compact mode rail or
  segmented row.
- Keep the drawer out of the default layout unless opened from the top slot.

### Objection 4: The import path is better, but the user failure mode is still
"nothing happened."

Evidence:

- `WorkspaceDocumentPicker.documentPickerWasCancelled` dismisses silently.
- The same app-level result surface handles empty selection, picker failure, and
  copy failure, but real Files provider behavior still needs device proof.

Risk:

If a provider returns no readable URL or the user thinks they selected a file,
the app may look inert, which was already reported in testing.

Implementable improvement:

- Add a post-dismiss fallback timer for importer-presented-without-result in
  debug logging and device QA.
- Add device log collection around picker presentation, completion, security
  scoped URL count, and file-copy result.
- Add a share extension later for sources that do not hand off clean document
  URLs.

## Constraint Guardian Review

### Objection 5: Playback is not yet system-control complete.

Evidence:

- `NowPlayingInfoPublisher` publishes metadata.
- `AudioPlaybackController` manages local playback.
- No `MPRemoteCommandCenter` usage exists in the repo.
- The Live Activity pause/play button uses `TogglePlaybackIntent`, but system
  media controls need remote command handlers too.

Risk:

Lock Screen, headphones, car controls, and CarPlay-adjacent transport controls
may show information but not reliably control playback.

Implementable improvement:

- Add a `RemoteCommandController` that wires play, pause, toggle, next,
  previous, seek/change position, and stop to the existing workspace playback
  coordinator.
- Mirror the user-requested previous-button behavior: first press restarts,
  second press within the double-tap window goes to previous.
- Add unit tests for command decisions without depending on real hardware audio.

### Objection 6: Large media and artwork can become a performance problem.

Evidence:

- Animated artwork preview generation uses `AVAssetImageGenerator` on demand.
- Import processors copy files sequentially.
- The app accepts broad audio and attachment file sizes, but device large-file
  QA is still listed as missing.

Risk:

Large WAVs, long videos, and session archives may cause slow UI, repeated frame
generation, or storage surprises.

Implementable improvement:

- Cache animated artwork preview images by artwork ID.
- Record copied file size and reject or warn on extreme animated artwork
  lengths/sizes.
- Move expensive metadata/artwork inspection behind cancellable background
  work, then publish status to the UI.

### Objection 7: The dependency surface is heavier than the actual shipped
behavior.

Evidence:

- `project.yml` links Lottie, ShaderKit, Inferno, and Motion.
- Current code uses ShaderKit for disc material and Motion for rubberbanding.
- Lottie and Inferno have little or no product-facing usage right now.

Risk:

Build/signing complexity and future maintenance rise before the user sees value.

Implementable improvement:

- Keep accepted packages for now, but create a dependency ledger that records:
  used now, reserved for imminent feature, or remove candidate.
- Remove or quarantine packages that do not survive the next visual pass.

### Objection 8: `MusicWorkspaceView` is still too large for safe iteration.

Evidence:

- `MusicWorkspaceView.swift` is about 1,612 lines.
- `MusicWorkspaceModels.swift` is about 1,075 lines.

Risk:

Feature work will keep touching the same root file, increasing regression
probability for imports, playback, state, gestures, sheets, and Live Activity
sync.

Implementable improvement:

- Split remote commands, import presentation state, ritual state, and
  now-playing state into focused coordinators.
- Split large model definitions into project, track, attachment, marker, import
  status, and UI draft files.
- Lock behavior with targeted tests before each split.

## User Advocate Review

### Objection 9: The app does not yet teach itself through the first song.

Evidence:

- The empty shelf has a clear first action.
- After the disc ritual, the user lands on the project screen with import audio,
  but there is no guided "first song became a container" moment after import.

Risk:

Users may understand "I added audio" but not "this song now has a hidden studio
container with files, notes, markers, and motion artwork."

Implementable improvement:

- After the first successful import in a new project, open the song container
  once with a restrained one-time cue.
- Keep the studio drawer closed, but briefly show the top-slot pull affordance.
- Add a one-time "song container ready" state rather than more onboarding text.

### Objection 10: Motion artwork is wired, but the UI makes it feel optional and
small.

Evidence:

- `MotionArtworkPanel` is a compact row with `Sample` and `Set`.
- The user has to already understand why animated artwork matters.

Risk:

The feature exists technically but does not feel like a premium music-product
capability.

Implementable improvement:

- Turn sample motion artwork into a first-run feature demo only after a real
  track is imported.
- Show live artwork in the expanded song container and Now Playing surfaces,
  not just as metadata.
- Make "Set Motion Artwork" visible from the song container mode controls, while
  keeping replacement/admin actions in the ellipsis menu.

### Objection 11: Markers are functional but not yet emotionally useful.

Evidence:

- Markers can be created, edited, filtered, resolved, and jumped to.
- The app intentionally removed predetermined marker names.

Risk:

Without a faster capture flow, markers may feel like another form rather than a
producer tool.

Implementable improvement:

- Add quick marker capture at playhead with immediate inline rename/note focus.
- Let the marker inherit playback context automatically.
- Keep user-authored labels; do not reintroduce dictated marker categories.

### Objection 12: Some controls compete for attention.

Evidence:

- Expanded song container contains artwork play, playback strip, waveform,
  motion artwork panel, song text panel, and marker list before the drawer.
- The mini player has previous, artwork/play, expandable title/waveform, next,
  and container button in one capsule.

Risk:

Dense functionality can become "busy" instead of "clever and intuitive."

Implementable improvement:

- Use one primary action per state:
  - project screen: import/play
  - mini player: play/pause and expand
  - song container: waveform/playback
  - top slot pull: reveal studio drawer
- Demote secondary actions into mode controls or ellipsis menus.

## Arbiter Decision

Accepted:

- The SwiftUI ritual needs the clearest next production-quality pass.
- Top slot gesture tuning needs real-device proof.
- Remote command center is a real weakness because the app is becoming a music
  player.
- First-song education should happen through behavior, not another text-heavy
  onboarding screen.
- Song container should be reorganized around waveform/playback first.
- Large file/artwork behavior needs constraints before the app claims robust
  local-first media handling.
- Architecture splitting should continue before adding broad new behavior.

Rejected:

- Rebuild the whole UI from scratch. The app has enough useful structure now;
  the weakness is hierarchy and ritual quality, not total replacement.
- Add predetermined marker titles. The user explicitly rejected dictated marker
  names.
- Make the foreground cue a fake Dynamic Island. The platform boundary is clear.
- Add more third-party animation systems before the SwiftUI path is proven.

## Prioritized Implementable Improvements

1. Add `RemoteCommandController` for system play/pause/seek/next/previous.
2. Rework the expanded song container hierarchy around waveform and transport
   as the hero, with notes/markers/artwork as modes.
3. Add a first-import handoff: after first audio import in a new sleeve, open
   the song container once and pulse the top-slot pull cue.
4. Tune the top-slot hold/pull thresholds and add gesture regression tests.
5. Make SwiftUI ritual readiness and contact-sheet comparison part of the
   IPA/export gate.
6. Surface animated artwork visually inside the song container and Now Playing
   UI, not just system metadata.
7. Add large-file and animated-artwork constraints: preview caching, duration
   checks, file-size warnings, and device QA cases.
8. Continue splitting `MusicWorkspaceView.swift` and `MusicWorkspaceModels.swift`
   into smaller ownership files before large new features.
9. Add import diagnostics for picker-dismissed-without-result and unsupported
   provider handoffs.
10. Add a dependency ledger and remove packages that are not pulling their
    weight after the next visual pass.

## Exit Criteria Check

- Understanding Lock completed: yes.
- Skeptic invoked: yes.
- Constraint Guardian invoked: yes.
- User Advocate invoked: yes.
- Objections resolved or rejected: yes.
- Decision Log complete: yes.
- Arbiter disposition: REVISE.
