# Agent Review - Build 11 Marker Flow

## Understanding Lock

- App lane: native SwiftUI iOS app, not Expo. Do not add Expo or React Native dependencies.
- Current priority: keep marker note sheet from reappearing after Save, keep waveform scrubbing fluid, preserve signed IPA and CarPlay entitlement flow.
- Constraints: no new dependencies, no automatic install, keep build artifacts in `/Users/joseph/Desktop/playda.te`.

## Review Loop

### Primary Designer

Decision: add a stable accessibility hook to the selected marker note popover and cover the Save dismissal path with a UI regression test.

### Skeptic

Objection: code clearing `selectedMarker` is not enough proof because a sheet dismissal race could reselect the marker.

Resolution: accepted. UI test now verifies the popover exists before editing and is gone after Save.

### Constraint Guardian

Objection: broad refactors or new UI layers could destabilize the current build.

Resolution: accepted. Change is scoped to an accessibility identifier and one UI assertion helper.

### User Advocate

Objection: if the note bubble reappears after Save, the app feels glitchy and untrustworthy.

Resolution: accepted. Test now protects the exact visible behavior.

### Arbiter

Decision: acceptable narrow pass. It increases confidence without changing user-facing layout or adding dependencies.

## Decision Log

- Chosen: UI regression around marker popover dismissal.
- Rejected: deeper marker architecture refactor, because current risk is a visible regression and code already clears state.
- Rejected: Expo UI implementation, because project is native SwiftUI and the Expo skill does not apply to this repo shape.
- Verification target: build plus focused UI test when simulator environment allows.
