# GitHub Workflow

This repo uses GitHub as the durable review and handoff layer for Motion Reveal.

## Default Flow

1. Work on a feature branch.
2. Keep app source, generated project config, tests, docs, and approved runtime assets tracked.
3. Open a pull request before merging to `main`.
4. Let GitHub Actions build the Swift package and iOS app.
5. Review the diff, asset changes, and verification notes.
6. Squash merge when the branch is ready.

## Branches

- `main`: stable handoff branch.
- `feature/*`: active implementation work.
- `docs/*`: documentation-only updates.
- `asset/*`: runtime asset or motion-study work.

## CI

- `Swift Package` resolves and builds the package dependency smoke target.
- `iOS App` installs XcodeGen, generates `MotionReveal.xcodeproj`, and builds the app for the iOS simulator with code signing disabled.

## Assets

Runtime assets that ship in the app must be committed intentionally. In this app,
`MotionReveal/Resources/Rive/playdate_disc_intake.riv` is allowed through
`.gitignore` because the app bundle loads it at runtime.

Do not commit private source files, raw paid marketplace downloads, signing
materials, secrets, or large exploratory asset dumps. Keep those in local
handoff folders until they are cleaned and approved for runtime use.

## Local Before PR

Useful checks:

```sh
xcodegen generate
xcodebuild -project MotionReveal.xcodeproj \
  -scheme MotionReveal \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData \
  build CODE_SIGNING_ALLOWED=NO
git diff --check
```

For visual or motion changes, include simulator screenshots, contact sheets, or
short videos in the PR notes.
