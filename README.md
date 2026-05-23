# Motion Reveal iOS

Private SwiftUI iPhone app prototype for an action-to-reveal flow: start screen,
action/reveal screen, card/result screen, and expandable detail screen.

This repository is private under `jjuzzi/motion-reveal-ios`.

## Current State

- GitHub repo is private.
- Local repo lives at `/Users/joseph/Developer/motion-reveal-ios`.
- Swift Package Manager dependency smoke test resolves:
  - Rive iOS runtime
  - Lottie iOS package

## Planned App Shape

The first app build should focus on a real usable iPhone interaction, not a
marketing landing page:

1. Start screen: quiet entry point with one primary action.
2. Action/reveal screen: user action drives a stateful reveal.
3. Item/card/result screen: result lands as a tappable card.
4. Detail screen: the card expands into a full detail view.

See `Docs/AppPlan.md` for the working product and technical plan.

## Dependencies

The root `Package.swift` is only a dependency smoke test until the real Xcode
app project exists. Add these package URLs to the app target in Xcode:

```text
https://github.com/rive-app/rive-ios
https://github.com/airbnb/lottie-spm.git
```

Link these products to the app target:

```text
RiveRuntime
Lottie
```

## Privacy Notes

Do not commit API keys, signing credentials, private `.riv` files, private
`.lottie` files, or paid/licensed assets unless they are meant to live in this
private repo.
