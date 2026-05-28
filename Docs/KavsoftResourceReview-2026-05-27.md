# Kavsoft Resource Review - 2026-05-27

Reviewed local Kavsoft sample archives as references only. Do not copy sample
projects wholesale.

## Borrow Now

- Liquid Glass Toasts: use the native iOS 26 glass toast idea for playda.te's
  existing status feedback, with the current capsule fallback on older systems.
- Apple Music Bottom Bar: keep the principle of a persistent mini player that
  can expand into the focused player. Do not add a tab shell.
- Permissions Sheet: borrow the recovery pattern for real Files/import failures:
  clear status, one next action, and a Settings escape hatch only when the
  system requires it.

## Borrow Later

- Keyframe/Microinteractions: the slide-to-cancel and keyframe icon replacement
  are useful references for future marker voice-note or recording flows, not for
  the current player pass.
- Custom Animated Toolbar: useful reference for a future project/song bottom
  action bar, especially search-plus-primary-action behavior. Avoid adding a
  broad app tab shell.
- iOS 26 Onboarding Animation: the screenshot zoom/pager grammar could improve
  onboarding, but playda.te should stay action-first and avoid a decorative
  landing page.
- Dynamic/Resizable/Floating Sheets: useful if song text, marker edit,
  permission recovery, or file-detail sheets need detent polish. Prefer the
  simple geometry-driven detent pattern over UIKit private hierarchy probing.
- Toolbar Transitions: useful reference for future bottom toolbar actions inside
  project or song detail, but current custom chrome should stay simpler.
- Dynamic Tab Indicators: the scroll-aware indicator math is useful as a small
  reference for marker filters or drawer category strips, not as app navigation.

## Avoid

- Dynamic Island Toasts: do not integrate the foreground overlay-window fake
  Dynamic Island pattern. playda.te already uses real ActivityKit surfaces when
  outside the foreground app and should not draw fake system hardware in-app.
- Dynamic Island QR Scanner and Dynamic Island Metaball Header: avoid the
  foreground fake-island container. The permission-denied recovery copy is
  useful, but the island expansion pattern is not.
- Shape Morphing directory: the provided folder was empty at review time.
