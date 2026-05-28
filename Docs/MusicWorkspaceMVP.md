# Music Workspace MVP

## Requirements Summary

Build the first real app shell around the reusable dynamic-notch reveal motion.
This is still pre-brand and pre-backend. The app should feel like a useful
music-maker workspace, not a clone of the reference photography app.

Current product direction:

- The user opens a library of album/project-looking covers, similar in broad
  structure to [untitled].
- Each project contains song containers. Each song container can hold the song,
  stems, DAW sessions, references, notes, exports, and other files used to make
  that song.
- The default project experience is beautiful and player-first. Nerdier
  producer/engineer details should feel hidden until requested, then appear
  smoothly.
- Ideas belong to the project the user chooses instead of landing in a global
  unsorted inbox.
- The dynamic notch animation should borrow the reference clip's reveal grammar,
  but translate it into a music metaphor: cover art behaves like a sleeve, and a
  disc/card-like object feeds into or ejects from a top slot.

## Waveform Markers

Timestamped notes should use SoundCloud-style waveform positioning as a
functional foundation, but avoid SoundCloud's bulky profile-picture comment
markers.

- Markers render as sleek vertical lines on the waveform.
- Each marker has a user-selected color.
- Markers are toggleable so the waveform can stay clean while listening.
- Tapping a marker reveals the note or edit instruction without permanently
  cluttering the player.
- The first use case is private producer/engineer edit notes, not public social
  comments.

## Now Playing Background

When a song is playing from a project, the player surface should use the song or
project artwork to drive the ambient background color field. The
`ImageColorBackground` reference is useful here: extract a small set of dominant
colors from the artwork, animate between them when the song changes, and keep the
effect tasteful enough that the player still feels like a studio tool rather
than a visualizer.

This should be used primarily for now-playing and mini-player states, not as the
main creation ritual. The sleeve-to-island animation can borrow subtle ambient
warmth, but the full image-derived background belongs to playback.

## Acceptance Criteria

- The app opens to a music-specific workspace, not the neutral motion sandbox.
- The dynamic notch animation remains reusable under `BackPocket`.
- App-specific content lives outside the reusable notch component.
- The first build uses local sample data only.
- No final app name, backend, accounts, paid assets, or private music files are
  introduced.
- The iOS app target and test bundle compile.

## Implementation Steps

1. Keep `DynamicNotchRevealView` as the reusable animation shell.
2. Add a `MusicIdea` model with local placeholder ideas.
3. Add `MusicWorkspaceView` that uses the notch reveal for app-specific cards.
4. Point `MotionRevealApp` at the workspace view.
5. Add focused tests for sample-data uniqueness and reveal-flow behavior.
6. Verify with SwiftPM and Xcode simulator builds.

## Risks

- The product concept may change after deeper planning; keep sample data and
  information architecture easy to replace.
- The current UI is only a working shell; visual identity should wait until the
  app concept is chosen.
- The local Xcode install currently has iOS 26.5 SDK without the matching iOS
  26.5 simulator runtime, so full asset-catalog simulator builds may require
  installing that runtime in Xcode settings.

## Verification

- `swift build`
- `xcodebuild -project MotionReveal.xcodeproj -target MotionReveal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO EXCLUDED_SOURCE_FILE_NAMES=Assets.xcassets build`
- `xcodebuild -project MotionReveal.xcodeproj -target MotionRevealTests -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO EXCLUDED_SOURCE_FILE_NAMES=Assets.xcassets build`
