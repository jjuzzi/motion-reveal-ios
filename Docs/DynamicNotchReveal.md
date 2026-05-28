# Dynamic Notch Reveal

This is a back-pocket motion prototype, not the app design.

## Purpose

The reference clip at `/Users/joseph/Desktop/TwiGal.MP4` has a useful motion
idea: a small top notch expands into a focused surface, an action happens, a
card ejects down from the notch, then the card can expand into detail. The
current repo captures that pattern as reusable SwiftUI code so it can be
inserted later after the real music-app concept is planned.

## Local Tooling

- SF Symbols is installed at `/Applications/SF Symbols.app`.
- XcodeGen is installed at `/opt/homebrew/bin/xcodegen`.
- The Xcode target no longer links `RiveRuntime`. Lottie remains available
  through Swift Package Manager for future lightweight motion surfaces.

No extra asset download is required yet. The motion is SwiftUI layout and spring
physics first. Do not reintroduce Rive without a new explicit product decision.

## Files

- `MotionReveal/BackPocket/DynamicNotchReveal/DynamicNotchRevealFlow.swift`
- `MotionReveal/BackPocket/DynamicNotchReveal/DynamicNotchRevealView.swift`
- `MotionReveal/BackPocket/DynamicNotchReveal/DynamicNotchRevealDemoView.swift`
- `MotionRevealTests/DynamicNotchRevealFlowTests.swift`

## Integration Notes

`DynamicNotchRevealView` is generic over the surrounding context, expanded-notch
content, result card, and detail overlay. When the app is planned, keep the
motion shell and replace only the placeholder closures with real product
content.

The production music ritual must not draw a second black capsule below the real
Dynamic Island. In foreground SwiftUI, aim motion into the top-center safe-area
island position and let the object vanish as it reaches system-owned space. Real
Dynamic Island content requires the later ActivityKit/widget-extension path.

The studio drawer is not default song-container furniture. Standard playback
entry opens the focused waveform and markers; the top-center island hold-and-pull
is the special gesture that reveals attached studio files.

Current phases:

1. `idle`
2. `expanded`
3. `ejecting`
4. `landed`
5. `detail`

The demo app opens to `DynamicNotchRevealDemoView` only so the motion can be
played and inspected on the simulator. The current app entry point now uses
`MusicWorkspaceView`, which incorporates the reusable notch reveal into the
first music-app shell. Keep the demo view available as a reference harness.
