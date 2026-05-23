# App Plan

## Goal

Build a native iPhone SwiftUI app centered on a tactile action-to-reveal
interaction. The uploaded motion reference is treated as interaction
inspiration: state changes, reveal motion, a result card, and a detail
expansion.

## Screens

1. Start screen
   - One primary action.
   - Clear visual identity.
   - No marketing copy or onboarding wall.

2. Action/reveal screen
   - User action advances app state.
   - Motion is driven by SwiftUI state and spring/keyframe animation.
   - Optional Rive animation can react to state if custom motion is needed.

3. Item/card/result screen
   - Result appears as a stable card.
   - Card supports tap, selection, and saved/result states.
   - Lottie may be used for non-interactive polish such as confirmation.

4. Detail screen
   - Card expands into detail using SwiftUI layout transitions.
   - Detail should feel like a continuation of the result, not a separate page jump.

## Technical Direction

- SwiftUI-first iPhone app.
- Use `matchedGeometryEffect` for card-to-detail continuity when it fits.
- Use `KeyframeAnimator` or phased state for multi-step reveal timing.
- Prefer Rive for state-machine animation assets.
- Prefer Lottie for non-interactive moments like loading, sparkle, or success.
- Keep the app logic deterministic and state-driven.

## Early Verification

- Build on an iPhone simulator.
- Check the four screens on small and large iPhone sizes.
- Verify animation is smooth in release/profile conditions before polishing.
- Keep private assets and credentials out of git unless intentionally committed.
