# Rive Disc Intake - Experimental Runtime Path

Rive is restored as an experimental launch-disc runtime path after explicit user
approval on May 27. The app keeps the SwiftUI ritual as the Reduce Motion
fallback, while the normal-motion launch screen may use the bundled
`playdate_disc_intake.riv` asset through `RiveRuntime`.

## Current Rule

- Keep `MotionReveal/Resources/Rive/playdate_disc_intake.riv` as the only active
  launch Rive asset unless the user approves a replacement.
- Use `RiveRuntime` only for this explicitly restored experiment until it proves
  better than the SwiftUI ritual.
- Keep the launch runtime on Rive's Swift-concurrency path:
  `AsyncRiveUIViewRepresentable`, a named artboard, a named state machine, and
  the shared `RiveWorkerProvider` worker.
- Keep `CADisableMinimumFrameDurationOnPhone` in `Info.plist` while Rive requests
  120 Hz playback; Rive's Apple FAQ requires this key for ProMotion support.
- Keep referenced assets out of the launch `.riv` unless the app also adds a
  local asset loader/global worker assets for the exported referenced files.
- Keep the foreground app free of fake Dynamic Island capsules.
- Preserve the SwiftUI fallback and Reduce Motion behavior.
- Verify the `.riv` can load with the Apple runtime before treating the asset as
  production-ready.
- Audio events are promising for short tactile music-app cues, such as disc
  click, tray latch, marker hit, and import success. Prefer embedded audio for
  simple shipped SFX or referenced local audio when assets are reused. Avoid
  hosted audio for private/local-first app behavior because hosted assets are
  public by link.

## Useful Historical Constraint

The old Rive direction correctly identified one enduring product rule: the real
system Dynamic Island must stay system-owned. Foreground SwiftUI can align a
top-edge cue toward it, but it must not draw a fake island.

## Verification

Run:

```sh
Scripts/verify-ritual-readiness.sh
```

The script should report `ritual_runtime=rive-experimental-with-swiftui-fallback`
and include a SHA-256 for the bundled `.riv` asset.
