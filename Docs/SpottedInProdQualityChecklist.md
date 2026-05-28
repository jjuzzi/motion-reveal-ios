# SpottedInProd Quality Checklist

Use [Spotted in Prod clips](https://www.spottedinprod.com/clips) as a live
reference library while building v1. The goal is not to copy a specific app.
Use its filters as a checklist for missing product states, interaction patterns,
and premium iOS moments.

## Product Scene Coverage

- Library and discovery: project grid, search, filtering, empty library, loaded
  library, and now-playing mini player.
- Create and import: first-run create, audio import, import progress, success,
  cancel, duplicate file, and import failure.
- Project detail: cover, metadata, track list, add tracks, more-options menu,
  rename, export, delete, and destructive confirmation.
- Playback: idle, buffering, playing, paused, scrub, next/previous, expanded
  player, background color field, and lock-screen-compatible state later.
- Song container: hidden top slot, hold plus pull reveal, marker list, marker
  note detail, add marker, edit marker, and close/collapse.
- Studio drawer: hidden by default, revealed inside the song container, with
  stems, session files, refs, lyrics, versions, and notes.
- Recovery states: no tracks, no project selected, unavailable file, unsupported
  file, deleted local file, and permission denied.

## Filter-Inspired Audit

- Flows to cover: navigation, input, onboarding, discovery, settings, data viz,
  launch screen, loading, detail view, confirmation, search, live session, edit,
  create, share/export, empty state, permissions, delete, import, and error
  state.
- Patterns to use carefully: modal, bottom sheet, tray, expand/collapse, shared
  element, context menu, slider, toast, show/hide, grid, picker, snap scrolling,
  play/pause, drawer, Dynamic Island, top tray, HUD, rubber band, and underlay.
- Gestures to map intentionally: tap for normal action, swipe for navigation or
  mini-player expansion, drag/pull for hidden studio layers, scrub for waveform,
  long press for marker creation, hold for Dynamic Island reveal, and gyroscope
  only for iridescent/ambient artwork when it earns its keep.
- Visuals to prioritize: blur, motion graphics, restrained gradient, Liquid
  Glass, cover art, cards as content objects only, menu icons, shader/iridescent
  treatment, color picker, animated path, glow, waveform, app icon, badge, and
  subtle noise.
- Design language guardrails: system-native, minimal, music-culture colorful,
  selective skeuomorphism for sleeve/disc objects, not monochrome-corporate, not
  loud everywhere, not dense utility UI.

## App-Specific Rules

- Standard ellipsis menus stay boring in the best way: rename, export, delete,
  duplicate, and metadata actions only.
- Clever gestures belong to creative/studio layers, not admin actions.
- The real Dynamic Island must be respected. Do not draw a fake island capsule.
- The studio drawer must not appear on the project screen. It lives behind the
  song container reveal.
- Marker controls belong inside the container. Playing waveforms may show subtle
  marker lines, but not a global "markers on/off" pill.
- Avoid avatar bubbles on the waveform. Markers are skinny vertical music/editor
  objects.
- Do not let the app become a bootleg `[untitled]`: keep the grid familiar, but
  make the signature identity come from the sleeve/disc ritual, waveform marker
  system, local studio drawer, and now-playing color field.

## Build Pass Order

1. Make the end-to-end v1 reliable: import, persist, play, reopen, and export
   what is reasonable for local use.
2. Add missing states from the Product Scene Coverage list before adding extra
   visual effects.
3. Polish interaction patterns: context menus, sheets, drawers, scrubbers,
   confirmations, and error handling.
4. Keep improving the SwiftUI signature disc ritual using the pass-12 motion
   benchmark as reference only.
5. Run visual review against this checklist before any IPA claim.

## Current Missing Scenes To Pull From Filters

- Import flow: file picker, import loading, duplicate-file accounting, failed
  copy accounting, and success feedback are wired. Still needs a richer Files
  permission-denied explanation and final motion polish.
- Playback flow: real local playback now has progress state, scrub, previous,
  next, and expanded-container controls. Buffering/unavailable-file recovery and
  final expanded-player polish still need product decisions.
- More-options flow: ellipsis buttons are context-specific and admin-focused,
  with rename, local-file export/share, duplicate, pin, remove, and destructive
  confirmation wired. Export only has real files after audio import.
- Song container flow: reveal exists through the top slot/mini player, but the
  container still needs marker editing and a cleaner studio drawer hierarchy.
- Creation flow: project creation needs the premium sleeve/disc ritual instead
  of a generic add transition.
- Empty and permission states: no-track treatment is wired. No-library, denied
  Files access, unsupported file, and deleted local file states need bespoke
  treatment.
- Visual identity: now-playing color fields are in place, but the app still
  needs a less `[untitled]` grid language, stronger typography, and stronger
  SwiftUI physical motion.
