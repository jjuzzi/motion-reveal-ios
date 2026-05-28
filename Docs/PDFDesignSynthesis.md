# PDF Design Synthesis

Date: May 24, 2026

Sources reviewed:

- `/Users/joseph/Downloads/101 Dos and Don'ts For UI Design .pdf`
- `/Users/joseph/Downloads/UI Pedia.pdf`

This is a working synthesis for Motion Reveal. It does not reproduce the PDFs;
it converts the useful guidance into app-specific design rules.

## Core Learnings

### Language

Use human language for visible labels. Avoid generic command words when the app
can say what the action actually does.

Applied rule:

- Prefer `Jump to marker`, `Resolve marker`, `Reopen marker`, `Add marker at
  playhead`, and `Edit marker` over abstract verbs like `Open`, `Submit`, or
  unlabeled icons.

### Scanability

Long text blocks slow users down. Related content needs headings, icon-label
pairs, and visible grouping.

Applied rule:

- Marker rows now show time, user-authored note, resolve status, and edit
  affordance in one scanable row.
- The app does not assign creative labels to markers; empty markers show a
  neutral note prompt until the user writes their own meaning.

### Alignment And Spacing

The PDFs repeatedly emphasize common alignment axes, consistent gaps, and
proximity. If two things belong together, they should be close. If they are
different actions, they need enough separation to prevent accidental taps.

Applied rule:

- Marker content stays in the main row.
- Resolve and edit controls are separate 44-point tap targets.
- Time and status are visually grouped because they describe the same marker.

### Button Hierarchy

Primary actions should stand out. Secondary actions should be visible but quieter.
Destructive or completion actions should not visually compete with the main
navigation path.

Applied rule:

- Add marker remains the strongest action in the marker header.
- Resolve uses a checkmark circle, visible but not louder than add/edit.
- Edit stays secondary with a pencil icon.

### Touch Targets

Mobile targets must account for fingers, not cursors. Small visible icons can be
acceptable only when the hit area is large enough.

Applied rule:

- Resolve and edit buttons use 44-point touch frames.
- Marker pin taps on the waveform keep an expanded clear hit area.

### Color Discipline

The PDFs warn against too many saturated colors and too many competing
selection colors. Color should carry meaning without becoming noise.

Applied rule:

- Marker colors remain limited to four tokens.
- Categories do not add new color families; they reuse the marker color.
- Resolved markers dim instead of adding another saturated state color.

### Cards Versus Lists

Homogeneous repeated data should usually be a list, not a pile of cards. Lists
support comparison and scanning.

Applied rule:

- Markers remain a compact list, not separate decorative cards.
- Each marker row is one repeated item with consistent layout.

### Status And Feedback

Users should understand what happened after an action. Microinteractions should
be functional: feedback, state, continuity, or error prevention.

Applied rule:

- Resolving a marker updates the row visually and shows a toast.
- Tapping a marker moves playback, reinforcing the time relationship.
- Resolved markers remain visible so users do not lose context.

### Forms

Small forms should stay single-column. Important instructions should not be
hidden behind tooltips. Form choices should use the control type that matches
the decision.

Applied rule:

- Marker editing stays in a native single-column sheet.
- Color is a segmented picker because it is one visual choice.
- Resolved state is a toggle because it is binary.
- Color remains a segmented control because there are four visible choices.

### Motion

Animation should communicate relationship and state, not decorate every surface.

Applied rule:

- Marker changes use small spring/opacity feedback only.
- Signature animation work remains separate; the marker pass avoids adding
  extra decorative motion.

## Implemented Pass

This pass focused on the marker system because it was the clearest intersection
between the PDF rules and the current gap report.

Implemented:

- Predetermined marker categories removed; marker meaning comes from the
  user's own note.
- Resolved chip visible only when useful on marker rows and marker popover.
- Resolved/reopened marker state.
- Quick resolve/reopen button with a 44-point tap target.
- Resolved markers dim and strikethrough their note.
- Marker edit sheet includes user note, color, and resolved state.
- Legacy marker decode ignores older category payloads and defaults resolved to
  `false`.

Verification:

- `test_sim` passed with 34 tests, 0 failures.

## Remaining Design Work From The PDFs

- Review all icon-only buttons for 44-point hit areas and clear labels.
- Reduce repeated glass/card styling where a simple list or section would scan
  faster.
- Audit text line lengths and Dynamic Type behavior in the song container.
- Replace remaining generic copy with concrete music-workflow language.
- Add skeleton/loading states where file operations may feel stalled.
- Use the same icon family and visual weight across every action button.
