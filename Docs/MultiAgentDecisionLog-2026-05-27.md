# Multi-Agent Decision Log - 2026-05-27

## Understanding Lock

The active app goal is to keep improving `playda.te` as a native SwiftUI music workspace, with special attention to the player, waveform marker workflow, Dynamic Island/Live Activity controls, and keeping the interface simple while still functional.

## Review Roles

- Primary designer: selected a bounded pass that improves real user friction without widening the project scope.
- Skeptic/challenger: flagged duplicate Dynamic Island playback intent delivery and stale marker selection.
- Constraint guardian: flagged hidden state in gesture handling and playback/live-activity sync.
- User advocate: flagged player-sheet friction, long waveform travel, clunky controls, and split marker flows.
- Integrator: accepted changes that improve playback reliability and scrub fluidity without changing provisioning or adding dependencies.

## Decisions

### Reduce Audio Seek Pressure During Scrub

- Decision: keep waveform visual feedback immediate, but throttle live audio preview seeks to 24 Hz.
- Alternatives considered: continue seeking at 60 Hz; remove live preview entirely.
- Objection resolved: 60 Hz audio seeking can overload playback and make the scrubber feel laggy; no live preview would feel disconnected for music work.
- Resolution: accept 24 Hz audio preview plus instant local visual progress.

### Make Waveform Longer And Slimmer

- Decision: move waveform geometry into `WaveformVisualMetrics`, reduce horizontal inset, slim bars/playhead, and preserve a large hit target.
- Alternatives considered: make the player cover smaller first; leave waveform untouched until device feedback.
- Objection resolved: the user explicitly called out fat waveform and clunky controls; this is a low-risk visual/interaction pass with tests.
- Resolution: accept metrics extraction and regression coverage.

### Acknowledge Immediate Playback Intent Delivery

- Decision: add targeted pending-route consumption for `.togglePlayback` when immediate notification handling runs.
- Alternatives considered: remove persisted toggle route entirely; add App Group/shared command state.
- Objection resolved: removing persistence could break app-not-running delivery; App Group would add provisioning risk.
- Resolution: accept route acknowledgement with a test proving song-container routes are preserved.

### Update Shared Progress During Preview Seek

- Decision: `WorkspacePlaybackRuntime.previewSeek(to:)` updates shared playback progress during real playback, falling back to local progress math when no audio snapshot is available.
- Alternatives considered: keep preview state local to the waveform.
- Objection resolved: local-only preview leaves the rest of the player behind while scrubbing.
- Resolution: accept shared progress update with unit tests.

### Retired The In-App Notch Beam

- Decision: remove the foreground notch beam and its `DynamicSlotBeamMetrics`
  tests after the no-fake-Dynamic-Island direction was reinforced.
- Alternatives considered: keep tuning raw SwiftUI offsets by screenshot; remove the extra bottom highlight and rely only on the capsule stroke.
- Objection resolved: a sensor-sized foreground capsule keeps implying app-owned
  Dynamic Island pixels. The studio drawer still has a deliberate pull cue, but
  no fake hardware beam.
- Resolution: keep real-device visual validation as the final authority.

### Extract Waveform Gesture State

- Decision: move scrub preview, marker cooldown, and marker-capture gating into `WaveformGestureState`.
- Alternatives considered: keep adding one-off guards directly inside `WaveformPanel`.
- Objection resolved: view-local booleans made the marker popover glitch hard to reason about after saving or dismissing a note.
- Resolution: accept a tiny pure state object with tests for scrub throttling and marker capture blocking.

### Prove Marker Bubble Dismissal At UI Level

- Decision: extend the long-press marker bubble UI test so the marker sheet and bubble must stay dismissed after Save.
- Alternatives considered: rely only on model tests and the immediate disappearance assertion.
- Objection resolved: the reported device failure was a delayed reappearance, so a one-frame dismissal check was too weak.
- Resolution: accept a short stability-window UI regression and avoid a new IPA because app binary code did not change.

### Make Expanded Player Cover-Led

- Decision: remove the duplicate text-heavy song-container header, increase the hero cover size, and slightly reduce transport visual weight.
- Alternatives considered: redesign the whole player sheet or add more controls above the waveform.
- Objection resolved: the expanded player still felt like utility chrome, and the cover was not clearly the centerpiece.
- Resolution: accept a bounded SwiftUI layout pass with metrics tests and no new dependencies.

### Adapt DIQRScanner Notch Expansion For Audio Import

- Decision: reuse the reference's Dynamic Island-style expansion mechanics for an audio import tray, not QR scanning or camera access.
- Alternatives considered: keep `Add tracks` as a direct Files picker; revive the album-open notch swallow ritual; add camera/QR code infrastructure.
- Objection resolved: normal album taps should stay fast and clean, while the creative notch moment belongs on an intentional studio action.
- Resolution: `Add tracks` opens a notch-born import panel with material dimming, spring expansion, blurred content reveal, and a sweep-line affordance before handing off to the existing Files importer.

### Reject Loud Import Scanning

- Decision: remove animated scanning and marching-outline treatment from the import tray after visual review.
- Alternatives considered: keep the sweep line; keep a slower dashed outline; add broader particle or reaction effects from the reference packs.
- Objection resolved: the import panel should feel premium and calm, not like a loud scanner demo.
- Resolution: use a static, low-contrast audio meter field with more bottom breathing room before the Files handoff.

### Refine Chrome Action Rings

- Decision: remove filled circular back/search/link/menu button backgrounds and keep only a thin beam-style circular border.
- Alternatives considered: keep the material-filled circles; make the top chrome fully text-only.
- Objection resolved: the filled circles competed with the sleeve artwork and tray surfaces, while a hairline beam keeps the controls visible without adding weight.
- Resolution: use a shared static circular beam stroke for `WorkspaceIconButton` glyphs.

### Adapt Legacy Card Springs As Sleeve Press Feedback

- Decision: borrow only the card press/spring principle from `SwiftUI-master`, not its old sample UI code.
- Alternatives considered: add draggable stacked albums or wider 3D card choreography.
- Objection resolved: album cards should feel touch-responsive without making the library feel like a toy demo.
- Resolution: add a small Reduce Motion-aware sleeve button style for cover taps.

### Remove Lateral Screen Slides From Album Navigation

- Decision: replace library/project edge-move transitions with a short opacity change.
- Alternatives considered: keep the slide as directional navigation feedback; remove all animation.
- Objection resolved: the sideways motion felt cheap and fought the album-art hero behavior.
- Resolution: album open/back now use a quiet crossfade while preserving the cover press response and other local motion.

### Use Native Symbol Morphing, Not Gooey Canvas Chrome

- Decision: adapt the SF Symbol replacement transition for play/pause icons while rejecting the Canvas blur/alphaThreshold metaball demo for primary controls.
- Alternatives considered: port the full gooey Canvas example; keep hard icon swaps.
- Objection resolved: gooey blur is fun in isolation but too demo-like and GPU-heavy for core playback chrome.
- Resolution: use `contentTransition(.symbolEffect(.replace))` on playback icons for a native, restrained morph.

### Protect Import Actions From Bottom Player

- Decision: increase the project screen bottom content inset while the mini player is visible.
- Alternatives considered: leave users to scroll around the floating player; move the mini player into the content stack.
- Objection resolved: a floating player must not cover the import `+` actions on an empty project.
- Resolution: keep the player overlay, lift it above the bottom safe zone, and give the project scroll view enough bottom clearance during playback.

### Remove Empty-State Disc Decoration

- Decision: remove the floating CD edge from the empty-library card.
- Alternatives considered: resize and tuck the disc farther behind the sleeve; replace it with a subtler glare.
- Objection resolved: the disc looked random in the card and distracted from the sleeve identity.
- Resolution: keep the empty card focused on the blank sleeve mark and primary create action.

### Make Launch Disc Use A Notch Tray

- Decision: keep the user-taps-disc launch action, but adapt the DIQRScanner Dynamic Island expansion idea into a CD-tray motion.
- Alternatives considered: keep the side-profile swallow; use a large scanner-style square panel; auto-play the launch.
- Objection resolved: the first-run moment should feel like the real island is opening a tray, not a fake notch swallowing a random disc.
- Resolution: tapping the disc opens a narrow keyhole tray from below the real Dynamic Island, docks the disc in a circular cradle, retracts the tray back upward, and then advances to album setup. No app-drawn fake notch or mouth layer is allowed in this launch screen.

### Adopt Artwork Palette Smoothing Carefully

- Decision: adapt the ImageColorBackground stripe-average extraction pattern for custom project artwork and smooth palette transitions into existing now-playing visuals.
- Alternatives considered: import a full ShipSwift shader recipe; replace the app backdrop with a full-screen mesh gradient.
- Objection resolved: shader backgrounds could overpower the sleeve/player design, but artwork-reactive color is aligned with the app.
- Resolution: keep ShipSwift mesh/plasma/noise recipes as later texture options, while using lightweight Core Image color extraction now.

### Incorporate Pro Swift MotionReveal Recipes

- Decision: promote the timed-lyrics recipe from `/Users/joseph/codex/docs/pro-swift-motionreveal-code-recipes.md` into app domain code and focused tests.
- Alternatives considered: copy every recipe directly; leave the recipe doc as reference only; add fake-notch capsule metrics from the recipe set.
- Objection resolved: markers and intent routing already have local implementations, and launch must not reintroduce fake notch hardware.
- Resolution: add bounded LRC parsing, deterministic timed-lyric identity, source-order-preserving same-timestamp parsing, active-line lookup, a `SongTextDocument` parser bridge, and parser regression tests.

### Make First-Run Cover Setup Match Project-Cover Editing

- Decision: route the launch album setup through the same shared project-cover import path as the main workspace cover editor, and let it accept image or video covers.
- Alternatives considered: keep the launch setup image-only; add a separate launch-only importer; leave video covers for later.
- Objection resolved: the app already treats project cover as a first-class setting, so the first-run path should not be a special weaker variant.
- Resolution: launch setup now carries a file URL, previews still image/video locally, and completion uses `WorkspaceImportWorker.importProjectCover` so the same validation and storage rules apply everywhere.
- Verification: focused importer tests passed for image and video covers, clean simulator launch still reaches the Rive intro, disc tap still advances to album setup, and a fresh signed IPA was exported from the verified state.

## Remaining Objections

- Dynamic Island behavior still needs real-device validation because simulator tests cannot fully prove ActivityKit/AppIntent process behavior.
- The player sheet still has broader UX opportunities around marker capture and real-device motion tuning, but the top chrome no longer competes with the cover.
