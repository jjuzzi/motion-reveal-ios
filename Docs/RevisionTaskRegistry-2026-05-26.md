# Revision Task Registry

Date: May 26, 2026

May 27 update: the old `island_disc_ritual.riv` production-asset task is
retired, but the user explicitly restored Rive as a new experimental first-run
launch asset: `MotionReveal/Resources/Rive/playdate_disc_intake.riv`. Keep the
entries below as historical context for the previous excluded asset only.

Scope: implement the accepted revision plan from
`Docs/MultiAgentWeaknessReview-2026-05-26.md`, excluding item 5
(`island_disc_ritual.riv` / old Rive production asset).

## Orchestrator Identity

The orchestrator decomposes work, prevents duplicate edits, integrates results,
and verifies quality. Specialist implementation claims are not accepted until
the repo builds and targeted tests pass.

## Excluded

- REV-5: Add the real `island_disc_ritual.riv` asset and make ritual readiness
  part of the export gate.

## Active Tasks

| ID | Revision Item | Agent | Scope | Status | Verification |
| --- | --- | --- | --- | --- | --- |
| MR-1 | 1 | swift-expert | Remote command controller and minimal `MusicWorkspaceView` wiring | complete | Command tests, model suite, simulator build |
| MR-2 | 2, 6 | ui-designer | `SongContainerView` hierarchy and visible in-app motion artwork | complete | Song-container UI smoke tests, simulator build |
| MR-3 | 3, 4, 9 | swift-expert | First-import handoff, import diagnostics, top-slot threshold tests | complete | Import/slot unit and UI tests, simulator build |
| MR-4 | 7, 10 | swift-expert | Animated artwork guardrails and dependency ledger | complete | Import-processor tests, model suite, simulator build |
| MR-5 | user add-on | orchestrator | Scrubbable waveform while playing | complete | Build plus targeted scrub test passed |

## Anti-Duplication Rules

- Only MR-1 may add remote command files or wire remote command callbacks.
- Only MR-2 may alter song-container hierarchy.
- Only MR-3 may alter import picker callbacks and slot thresholds.
- Only MR-4 may alter animated artwork validation and dependency docs.
- No task may revive `island_disc_ritual.riv`. The restored
  `playdate_disc_intake.riv` path is separate and must stay scoped to the
  first-run experiment.

## Quality Gates

- Simulator build passed on May 26, 2026.
- `MotionRevealTests/MusicWorkspaceModelTests` passed: 126 passed, 0 failed.
- Targeted UI smoke tests passed: first run, mini-player expansion, top-slot
  pull, simulated files import persistence, and seeded drawer hidden-until-pull.
- Scope check confirmed `MotionReveal/Resources/island_disc_ritual.riv` was not
  added; item 5 stayed excluded.
- Secret scan found no introduced keys, passwords, or signing artifacts.
- Any unverified device-only behavior must be reported as a remaining risk.
