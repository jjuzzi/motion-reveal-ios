# Motion Reference Plan

## Goal

Keep the SwiftUI motion study aligned with the actual music app direction. The
motion reference is `/Users/joseph/Desktop/TwiGal.MP4`; the source analysis is
`/Users/joseph/Desktop/deep-research-report(1).md`, which frames the clip as a
layered app transition rather than one pre-rendered movie.

The Figma rough frames live at:
`https://www.figma.com/design/0N6lK5qpbKzscvznVg44LZ`

Implementation notes now live in `Docs/DynamicNotchReveal.md`.

The original clip is photography-shaped. This repo should borrow only the
interaction grammar for now:

1. Start state with placeholder content.
2. Top slot grows into a focused viewport.
3. Action controls appear.
4. Focused viewport collapses back to context.
5. Result card ejects downward, overshoots, and settles.
6. Landed result card expands into a darker detail view.
7. Detail collapses back to the start state.

## Screens

1. Start screen
   - Placeholder grid only.
   - One primary action opens the focus/reveal state.
   - No product UI, brand direction, marketing copy, or onboarding wall.

2. Action/reveal screen
   - Top slot expands into a focused viewport.
   - Action controls fade and scale into view.
   - Motion is driven by SwiftUI state and spring/keyframe animation.
   - Do not add Rive for this path unless a new explicit product decision
     restores it.

3. Item/card/result screen
   - Focused viewport collapses back toward the start layout.
   - Result card ejects from the top slot and settles over the placeholder grid.
   - Card supports tap, selection, and saved/result states.
   - Lottie may be used for non-interactive polish such as confirmation.

4. Detail screen
   - Card expands into detail using SwiftUI layout transitions.
   - Detail should feel like a continuation of the result, not a separate page jump.

## Technical Direction

- SwiftUI-first iPhone app.
- Use a small state machine: `idle`, `expanded`, `ejecting`, `landed`, `detail`.
- Use `matchedGeometryEffect` for card-to-detail continuity when it fits.
- Use `KeyframeAnimator` or phased state for multi-step reveal timing.
- Keep state-machine animation assets SwiftUI-owned for this app lane.
- Prefer Lottie for non-interactive moments like loading, sparkle, or success.
- Keep the app logic deterministic and state-driven.

## Early Verification

- Build on an iPhone simulator.
- Check the four screens on small and large iPhone sizes.
- Verify animation is smooth in release/profile conditions before polishing.
- Keep private assets and credentials out of git unless intentionally committed.
