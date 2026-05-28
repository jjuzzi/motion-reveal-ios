# Dependency Ledger

This pass documents package intent after restoring the scoped Rive launch-disc
experiment.

## Used Now

### ShaderKit

- Status: `used-now`
- Why: disc material rendering depends on shader-backed styling today.
- Evidence: `MotionReveal/Features/MusicWorkspace/StudioDiscMaterialModifier.swift`

### Motion

- Status: `used-now`
- Why: slot-pull response logic already imports and uses the package.
- Evidence: `MotionReveal/Features/MusicWorkspace/DynamicSlotPullResponse.swift`

## Reserved

### Rive

- Status: `used-now`
- Why: first-run launch uses `playdate_disc_intake.riv` through the official
  Apple runtime, with SwiftUI retained as the Reduce Motion fallback.
- Evidence: `MotionReveal/Features/MusicWorkspace/Views/LaunchDiscRiveIntroView.swift`,
  `MotionReveal/Resources/Rive/playdate_disc_intake.riv`.
- Notes: keep Rive scoped to this restored experiment until the asset proves
  better than the SwiftUI ritual.

### Lottie

- Status: `reserved`
- Why: runtime availability is tracked and the dependency smoke target confirms the package resolves, but no current feature surface depends on it.
- Evidence: `MotionReveal/Support/MotionRuntimeAvailability.swift`, `Sources/DependencySmokeTest/DependencySmokeTest.swift`
- Notes: keep reserved until a concrete animation surface lands or the package is formally retired.

## Remove Candidate


### Inferno

- Status: `remove-candidate`
- Why: declared in `project.yml`, but this pass found no in-repo import or direct runtime usage.
- Evidence: `project.yml`
- Notes: do not remove in this pass. Re-check generated project references and any uncommitted experimental branches before pruning.
