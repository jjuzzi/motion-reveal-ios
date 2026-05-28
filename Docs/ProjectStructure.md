# Project Structure

This project keeps app code grouped by product feature first, then by local
responsibility inside each feature. Prefer moving code into an existing feature
lane before adding new top-level folders.

## MotionReveal

- `App/`: app entry point, launch reset helpers, and App Intent definitions.
- `CarPlay/`: CarPlay scene and root view.
- `Features/MusicWorkspace/`: the main playda.te workspace feature.
- `BackPocket/`: reusable prototypes that are not the active app surface.
- `Support/`: shared app/extension support types.
- `Resources/`: bundled media and fixture-like app assets.

## MusicWorkspace

- `Domain/`: local model types, drafts, filters, and route parsing.
- `Data/`: persistence and local-library storage.
- `Playback/`: audio playback, now-playing metadata, remote commands, and shared
  playback progress.
- `ImportExport/`: document pickers, import workers, export builders, and
  destructive file actions.
- `LiveActivity/`: ActivityKit/Dynamic Island coordination only. Foreground UI
  must not draw fake Dynamic Island hardware.
- `Motion/`: sleeve/disc/top-edge ritual views, motion policy, shaders, and
  motion math.
- `Views/`: SwiftUI screens, chrome, sheets, status surfaces, and reusable view
  components.
- `Flow/`: workspace coordinators and mutation executors that connect views to
  domain/data work.
- `Style/`: feature-local typography, colors, and reusable visual constants.

## Tests

- `MotionRevealTests/MusicWorkspace/`: broad workspace model and coordinator
  regression tests.
- `MotionRevealTests/Playback/`: audio controller tests.
- `MotionRevealTests/BackPocket/`: prototype flow tests.
- `MotionRevealUITests/FirstRun/`: first-run and UI journey tests.

## Rules

- Keep files behavior-focused; avoid putting unrelated view, model, and runtime
  types in the same file.
- Keep generated Xcode project state in sync with `project.yml` by running
  `xcodegen generate` after file moves.
- Keep Rive retired unless the user explicitly restores it. Remove retired
  helper scripts instead of leaving active-looking entry points.
