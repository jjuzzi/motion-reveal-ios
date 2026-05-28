# Agent Operating Stack

May 27 update: Rive has been explicitly restored as an experimental launch-disc
intake path after the user paid for Early Access and exported
`playdate_disc_intake.riv`. Keep the Rive path scoped, keep SwiftUI as the
Reduce Motion fallback, and verify with runtime asset loading, simulator
build/run, screenshots, and device review before treating it as final.

This app lane keeps three requested skills active as standing working rules:

- `swiftui-pro`: use for SwiftUI implementation and review. Before calling a
  SwiftUI pass done, check modern API usage, data flow, navigation, accessibility,
  performance, and code hygiene.
- `multi-agent-brainstorming`: use before large product, motion, or visual
  identity decisions. This is sequential review, not idea swarm: designer,
  skeptic, constraint guardian, user advocate, then arbiter.
- `autonomous-agents`: use for delegation discipline. Keep agent tasks bounded,
  auditable, and reversible. Prefer constrained specialist reviews over broad
  autonomous invention.

The root `AGENTS.md` makes these rules active project guidance for future agent
work in this repository.

## Operating Rules

1. Product and motion direction come first. Do not let implementation convenience
   turn the app into a bootleg reference clone.
2. SwiftUI work should stay state-driven, native, and local-first.
3. The standard ellipsis menu remains for admin actions such as rename, export,
   duplicate, move, pin, and delete.
4. Clever gestures are reserved for creative or studio layers, such as revealing
   the song container or studio drawer.
5. Big animation moments must explain the music object metaphor: sleeve, disc,
   slot, waveform, marker, version, or attached studio file.
6. Keep Rive usage limited to the explicitly restored launch-disc intake asset
   until it proves better than the SwiftUI ritual.

## Multi-Agent Review: Current Direction

### Understanding Lock

The current app is an iPhone-first, private, local-only music workspace. It
should feel like a premium native studio tool mixed with album-world culture.
It should not feel like `[untitled]` copied into a different color palette, a
Threads-style feed, or a utility table.

### Primary Designer Decision

Move the library away from a two-column cover grid and toward a physical
worktable/crate metaphor. Keep the project detail surface simple and native, but
make the project-load ritual a visible sleeve-to-slot event rather than a hidden
control.

### Skeptic Objections

- The current SwiftUI ritual may still be too abstract compared with the
  original reference video.
- A worktable metaphor can become decorative if it does not lead to better
  navigation and file organization.
- Continuing to use placeholder artwork may make the app look toy-like even if
  the layout improves.

Resolution: accepted. Treat the SwiftUI ritual as the fallback and the restored
Rive intake as the active experiment. The next premium pass should improve the
Rive asset and compare it against the SwiftUI fallback before widening runtime
usage.

### Constraint Guardian Objections

- A giant single SwiftUI file increases maintenance risk.
- Continuous shimmer/gradient motion can hurt battery and reduce-motion users.
- True Dynamic Island rendering cannot be achieved by ordinary foreground
  SwiftUI views.

Resolution: accepted. Split feature views into smaller files before the surface
grows further. Add reduce-motion handling before calling the motion pass
production-ready. Use ActivityKit/Dynamic Island APIs for real system-island
behavior later, not a fake second notch.

### User Advocate Objections

- The user has repeatedly rejected anything that feels like a copied reference
  app, so visual originality is not optional.
- The signature animation was the emotional hook from the start; it cannot be
  treated as garnish.
- Marker and studio-file interactions must stay useful and private, not social
  or cluttered.

Resolution: accepted. Prioritize a distinctive motion and object language before
adding breadth. Keep markers as slim colored waveform lines and keep studio
  details hidden until requested.

### Arbiter Disposition

REVISE.

The current direction is usable as a SwiftUI prototype, but not yet the desired
final state. The next high-value work is:

1. Split `MusicWorkspaceView.swift` into focused SwiftUI files.
2. Add reduce-motion handling around continuous shimmer and ritual animation.
3. Create a stronger art/typography direction so the app stops leaning on the
   reference app's visual vocabulary.
4. Promote the sleeve-to-slot load ritual into a more disciplined SwiftUI
   signature animation after the flow is locked.
