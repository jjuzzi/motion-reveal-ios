# Active Animation Handoff

## Goal

Develop the signature sleeve/disc/top-edge animation until it feels native and
premium. Rive is now restored as an experimental launch-disc intake asset, with
SwiftUI preserved as the Reduce Motion fallback.

The Remotion motion study remains useful as a motion reference. The active
implementation path is now: Rive for the first-run disc intake experiment,
SwiftUI for fallback and for broader ritual surfaces until the Rive asset earns
more scope.

## Current Product Direction

- iPhone-first, local/private music studio app.
- Not a clone of `[untitled]`.
- Signature motion: a disc emerges from the existing sleeve/card surface,
  rotates from face-on to edge-on, and visually tucks toward the real top
  hardware area.
- Do not draw a fake black capsule or fake Dynamic Island.
- The real system island should act as the occluder.
- Rive audio events are approved as a promising experiment for short tactile
  app sounds. Keep them local-first: embedded for one-off shipped SFX,
  referenced for reusable local assets, and no hosted/CDN audio for private app
  behavior.
- The first-run album setup now reuses the same project-cover import path as
  the main workspace cover editor, so it accepts either an image or a video
  instead of staying image-only.
- Standard ellipsis menus stay standard for rename/export/delete/etc.
- Clever gestures are reserved for creative/studio layers like the song
  container and studio drawer.

## Decision Log - 2026-05-24 No-Fake-Island Pull Cue

- Decision: keep the song-container pull cue as a small disc/chevron aligned
  into the real top island zone, with no drawn black capsule.
- Alternative rejected: foreground SwiftUI fake island hardware; it reads as a
  second notch and conflicts with the real system Dynamic Island.
- Skeptic objection: a cue below the island looks flimsy and decorative.
- Resolution: move the cue upward so it tucks into the system island area, and
  hide it entirely until an actual song container can open.
- Constraint: true pixels inside the Dynamic Island require ActivityKit/widget
  work later; the SwiftUI app can only align motion toward the system-owned
  area.
- Arbiter: acceptable for v1 if the fake capsule is gone, empty projects do not
  show the pull cue, and tests plus simulator screenshots verify the flow.

## Important Files

- `MotionReveal/Features/MusicWorkspace/Views/MusicWorkspaceView.swift`
  - SwiftUI fallback ritual lives around `RitualOverlay`,
    `SleeveToIslandRitual`, `StudioDisc`, `SourceSleeveLip`, and
    `DiscSideProfile`.
  - Current transition timing is being tuned in `loadProject(_:)`.
- `Docs/RiveIslandRitual.md`
  - Restored Rive contract for `playdate_disc_intake.riv`, including the
    no-fake-island constraint and SwiftUI fallback requirement.
- `build/verification/ritual-pass25-contact.jpg`
  - Latest reviewed SwiftUI fallback contact sheet.
- `build/verification/twigal-contact.jpg`
  - Extracted benchmark contact sheet from the user reference video.
- `Remotion/ritual-motion-study/`
  - Remotion motion lab for authoring and reviewing the sleeve/disc/island
    ritual outside SwiftUI and the restored Rive experiment.
- `build/remotion-ritual/island-disc-ritual.mp4`
  - First rendered Remotion motion study, 108 frames at 30 fps.
- `build/remotion-ritual/contact-sheet.png`
  - Seven-frame contact sheet from the first Remotion motion study.
- `build/remotion-ritual/island-disc-ritual-pass5.mp4`
  - Earlier Remotion motion study, 132 frames at 30 fps.
- `build/remotion-ritual/contact-sheet-pass5.png`
  - Eight-frame contact sheet from Remotion pass 5.
- `build/remotion-ritual/island-disc-ritual-pass7.mp4`
  - Earlier Remotion motion study, 132 frames at 30 fps.
- `build/remotion-ritual/contact-sheet-pass7.png`
  - Eight-frame contact sheet from Remotion pass 7.
- `build/remotion-ritual/island-disc-ritual-pass12.mp4`
  - Current best Remotion motion study, 132 frames at 30 fps.
- `build/remotion-ritual/contact-sheet-pass12.png`
  - Eight-frame contact sheet from Remotion pass 12.
- `build/remotion-ritual/contact-sheet-pass12-top.png`
  - Focused top-catch contact sheet from Remotion pass 12.
- `build/reference-contact-sheets/`
  - Contact sheets extracted from the supplied TwiGal and Dynamic Island
    reference videos.

## Current Findings

- Pass 12 improved the mechanics:
  - no duplicate flying project card
  - disc starts readable face-on with center hole
  - disc pitches toward edge-on
  - side profile tucks under the real Dynamic Island instead of drawing a fake
    capsule
  - project screen no longer slides laterally under the overlay
  - the debug-style "Project loaded" toast is gone
  - the heavy blackout and decorative blurred light blobs were reduced so the
    disc reads as the primary physical object
- Pass 21 established the first credible SwiftUI fallback:
  - anchors the ritual source to the measured lead sleeve frame instead of a
    hard-coded floating origin
  - keeps the disc readable face-on at the sleeve, then rotates it toward a
    thinner edge profile
  - snaps the final travel upward so the edge tucks under the real Dynamic
    Island mask instead of hovering below it
  - keeps the debug capture path source-aware without requiring Simulator
    window clicks
- Pass 25 is the current best SwiftUI fallback:
  - makes the disc face more solid and less transparent over the sleeve artwork
  - turns the source pocket into contact shadow and hairline highlight instead
    of a painted beige bar
  - moves the perspective flip earlier so the top handoff reads more edge-on
    as the disc tucks under the real Dynamic Island
  - preserves the source-aware debug capture path without foreground Simulator
    interaction
- Pass 26 improves the in-app SwiftUI fallback:
  - adds a short-lived source slit/contact layer at the measured sleeve origin
  - adds an early disc contact shadow so the disc reads as leaving a physical
    pocket instead of floating over the card
  - reduces the top catch glow and trail so the handoff does not linger as fake
    foreground Dynamic Island chrome
  - latest evidence:
    `build/verification/in-app-ritual-20260524-233900/ritual-contact-sheet.jpg`
- Pass 26 is still not benchmark quality:
  - the source emergence is improved but still reads like a SwiftUI composition,
    not an authored physical object leaving a sleeve
  - the motion needs reference-level occlusion, easing, depth, and contact-shadow
    choreography before calling the signature ritual done
  - current `$visual-verdict` score is `78/100`; target threshold remains `90+`
- Current runtime validation on May 27:
  - clean simulator launch still reaches the Rive intro disc path first
  - tapping the disc advances into album setup correctly
  - Cursor MCP with Rive is working in the current tooling setup
  - shared project-cover import tests now pass for both image and video inputs
  - fresh signed IPA exported from this state at
    `build/export/MotionReveal.ipa`
- Remotion pass 1 now exists as a higher-fidelity motion reference:
  - uses a 393x852 iPhone composition, 108 frames, 30 fps
  - disc starts face-on with an iridescent surface and center hole
  - sleeve uses a slit, lip highlight, fabric texture, glow, and contact shadow
  - disc lifts, pitches toward edge profile, and tucks under the top hardware
    island mask
  - rendered MP4 is H.264, so ffprobe reports width `392` because H.264 rounds
    odd dimensions; still frames preserve the 393px source canvas
  - this is a motion bible/prototype, not a runtime asset pipeline
- Remotion pass 5 is the current best motion-study baseline:
  - extends timing to 132 frames at 30 fps
  - extracts reference contact sheets from all supplied TwiGal clips and the
    Dynamic Island motion clip
  - keeps the disc readable face-on at the source, then pitches into a clearer
    edge profile near the island
  - delays the final top travel so the edge profile is visible before being
    swallowed by the hardware mask
  - adds source and island iridescent reaction glows plus a subtle device-glass
    frame so the top element reads more like hardware context
  - still scores below target because the source object and island reaction do
    not yet have the staged, authored quality of the references
- Remotion pass 7 is the current best motion-study baseline:
  - incorporates the useful ideas from the downloaded references without
    importing their whole sample projects
  - uses ImageColorBackground only as a subtle ambient principle in the ritual;
    the full artwork-derived background belongs to actual now-playing playback
  - adds BorderBeam-style release/catch glints but reduces the island-side beam
    so it does not read like a fake decorative Dynamic Island
  - adds a staged album object behind the sleeve: cover plane, side depth,
    paper grain, small artwork, and track-strip accents
  - keeps the disc mechanics from pass 5: face-on start, clearer edge profile,
    and top-slot insertion
  - current visual verdict is `86/100`, still below the `90+` target
- Remotion pass 9 is the current best motion-study baseline:
  - keeps pass 7's album-object staging
  - adds a more deliberate top catch: elastic island lip, swallowed-edge glint,
    and a soft catch ripple
  - shortens the post-catch magnetic trace so it no longer reads like a hanging
    line from the island
  - current visual verdict is `88/100`, still below the `90+` target
- Remotion pass 12 is the current best motion-study benchmark:
  - preserves the readable face-on disc start, center hole, and iridescent
    physical object read
  - pitches the disc into a thinner edge profile before it reaches the hardware
    island area
  - tightens the swallow/catch timing so the top glint disappears into the real
    island area instead of lingering as a fake underline or thread
  - reduces the post-catch beam, slot pressure, and pull-thread opacity so the
    ritual feels more like hardware absorption than decorative UI
  - uses the downloaded ImageColorBackground idea only as faint ambient color;
    reserve the full artwork-reactive background for now-playing/song playback
  - visual verdict is `90/100`, meeting the motion-study threshold for porting
    the ideas into SwiftUI
- Previously verified edit:
  - `loadProject(_:)` now accepts an optional source rect, swaps to the project
    screen without transition animation after `1520ms`, keeps the ritual overlay
    up for `520ms`, lowers the ritual backdrop opacity, removes the loading
    toast, and mutes the sleeve rack background glow.

## Verification So Far

Latest verified state:

```sh
xcodebuild -project MotionReveal.xcodeproj \
  -scheme MotionReveal \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=C1D9D1D5-611A-4EFA-A76C-D118509A9C0D' \
  -derivedDataPath DerivedData \
  test CODE_SIGNING_ALLOWED=NO
```

Result on May 24, 2026: `10 tests, 0 failures`.

Latest visual artifacts:

- `build/verification/ritual-pass25-contact.jpg`
- `build/verification/ritual-pass25.mp4`
- `build/verification/ritual-pass25-frames/`
- `build/remotion-ritual/contact-sheet.png`
- `build/remotion-ritual/island-disc-ritual.mp4`
- `build/remotion-ritual/contact-sheet-pass5.png`
- `build/remotion-ritual/island-disc-ritual-pass5.mp4`
- `build/remotion-ritual/contact-sheet-pass7.png`
- `build/remotion-ritual/contact-sheet-pass7-top.png`
- `build/remotion-ritual/island-disc-ritual-pass7.mp4`
- `build/remotion-ritual/contact-sheet-pass9.png`
- `build/remotion-ritual/contact-sheet-pass9-top.png`
- `build/remotion-ritual/island-disc-ritual-pass9.mp4`
- `build/remotion-ritual/contact-sheet-pass11.png`
- `build/remotion-ritual/contact-sheet-pass11-top.png`
- `build/remotion-ritual/island-disc-ritual-pass11.mp4`
- `build/remotion-ritual/contact-sheet-pass12.png`
- `build/remotion-ritual/contact-sheet-pass12-top.png`
- `build/remotion-ritual/island-disc-ritual-pass12.mp4`
- `build/reference-contact-sheets/twigal-1.png`
- `build/reference-contact-sheets/twigal-2.png`
- `build/reference-contact-sheets/twigal-3.png`
- `build/reference-contact-sheets/dynamic-island-ref.png`
- `.omx/state/motion-ritual/ralph-progress.json`

Simulator should be used in background only:

- Prefer `xcodebuild` and `xcrun simctl`.
- Do not use foreground `build_run_sim`.
- After captures, run:

```sh
osascript -e 'tell application "Simulator" to quit'
```

## Recommended Next Step

1. Continue improving the SwiftUI ritual directly, using pass 12 as a reference
   only where it helps.
2. Preserve the exact grammar: face-on disc at the sleeve, visible center hole,
   edge-on pitch near the island, fast hardware swallow, no fake Dynamic Island.
3. Keep ImageColorBackground reserved for now-playing/song playback surfaces,
   not the creation ritual.
4. Use pass 12 as the reference for any future SwiftUI visual reviews.
5. If later implementation drops below this contact sheet quality, return to
   the Remotion timing before adding new ideas.

## Suggested Prompt For Another CLI Agent

Read `/Users/joseph/Developer/motion-reveal-ios/Docs/ActiveAnimationHandoff.md`,
then review the current worktree for the top-edge disc insertion animation. Do
not change files yet. Report:

- whether Remotion pass 12 still holds up as a useful SwiftUI reference
- the smallest implementation move to improve the SwiftUI ritual without losing quality
- anything in SwiftUI that would recreate the earlier fake-island or lingering
  underline problems
- any risks to Reduce Motion, maintainability, or simulator verification
