# playda.te iOS

Private SwiftUI iPhone motion-study repo for the action-to-reveal animation
from the reference clip. The Xcode targets still use the original
`MotionReveal` identifiers so existing provisioning profiles keep working, but
the shipped app name is `playda.te`.

This repository is private under `jjuzzi/motion-reveal-ios`.

## Current State

- GitHub repo is private.
- Local repo lives at `/Users/joseph/Developer/motion-reveal-ios`.
- Swift Package Manager dependency smoke test resolves Lottie.
- The Xcode app target resolves Lottie, ShaderKit, Inferno, and Motion.
- Xcode app shell exists under `MotionReveal.xcodeproj`.

## Planned App Shape

The first app shell is a local music idea workspace:

1. Start state: local queue of music ideas.
2. Action/reveal state: top slot expands into a focused listening/reveal area.
3. Result state: idea card ejects downward and settles.
4. Detail state: the card expands into tempo, key, ingredients, and next steps.

See `Docs/MusicWorkspaceMVP.md` for the first MVP plan and
`Docs/DynamicNotchReveal.md` for the reusable animation prototype notes.
See `Docs/AgentOperatingStack.md` for the active SwiftUI, brainstorming, and
autonomous-agent workflow used for this app lane.
Use `Docs/SpottedInProdQualityChecklist.md` as the scene/pattern audit while
building toward the first installable v1.
Use `Docs/ios-music-app-code-recipes.md` as the reusable Apple-platform recipe
library for animated artwork, audio import/share flows, Dynamic Island, and
haptics work.

## Dependencies

The root `Package.swift` remains a lightweight dependency smoke test. The Xcode
app target links these package URLs through Swift Package Manager:

```text
https://github.com/airbnb/lottie-spm.git
https://github.com/jamesrochabrun/ShaderKit.git
https://github.com/twostraws/Inferno.git
https://github.com/b3ll/Motion.git
```

Link these products to the app target:

```text
Lottie
ShaderKit
ShaderKitUI
Inferno
Motion
```

## Privacy Notes

Do not commit API keys, signing credentials, private `.lottie` files, or
paid/licensed assets unless they are meant to live in this private repo.
