# Motion Reveal iOS Agent Guidance

This repo is an iPhone-first SwiftUI music-app lane. Keep the active operating
stack from `Docs/AgentOperatingStack.md` in force for all work under this tree.

## Required Skills

- Use `/Users/joseph/.agents/skills/swiftui-pro/SKILL.md` whenever reading,
  writing, or reviewing SwiftUI. Apply it as a quality gate for modern APIs,
  data flow, navigation, accessibility, Reduce Motion, performance, and file
  hygiene.
- Use `/Users/joseph/.codex/skills/multi-agent-brainstorming/SKILL.md` before
  large product, motion, visual-identity, or interaction-model decisions. Keep
  the process sequential and logged: primary designer, skeptic, constraint
  guardian, user advocate, arbiter.
- Use `/Users/joseph/.codex/skills/autonomous-agents/SKILL.md` for delegation
  discipline. Agent work must be constrained, auditable, reversible, and scoped
  to specialist tasks. Treat helper-agent output as a proposal until verified.

## Product Direction

- This is not a clone of `[untitled]`. Borrow only useful simplicity; do not
  preserve the reference app's layout vocabulary when it fights the music
  product.
- The app is local-first, private, iPhone-first, and music/studio oriented.
- The signature motion is the sleeve/disc/slot ritual. Treat it as a primary
  product moment, not decorative garnish.
- Standard ellipsis menus remain for admin actions such as rename, duplicate,
  export, move, pin, and delete.
- Clever gestures are reserved for creative or studio layers, such as opening
  the song container or studio drawer.

## Implementation Rules

- Prefer SwiftUI-native state and composition.
- Break large feature surfaces into focused files before adding more behavior.
- Preserve the feature-local folder layout documented in
  `Docs/ProjectStructure.md`.
- Do not add new third-party frameworks unless the user asks or approves. Lottie
  remains an accepted motion resource for this lane. Rive has been explicitly
  restored as an experimental launch-disc intake path; keep it scoped to the
  approved `.riv` asset unless the user expands that decision.
- Respect Reduce Motion before calling motion-heavy work production-ready.
- Verify meaningful SwiftUI changes with XcodeBuildMCP build/run or simulator
  tests when available.
