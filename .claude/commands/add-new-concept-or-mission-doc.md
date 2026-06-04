---
name: add-new-concept-or-mission-doc
description: Workflow command scaffold for add-new-concept-or-mission-doc in motion-reveal-ios.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-new-concept-or-mission-doc

Use this workflow when working on **add-new-concept-or-mission-doc** in `motion-reveal-ios`.

## Goal

Introduces a new conceptual, protocol, or mission document to the Docs directory.

## Common Files

- `Docs/RoomKey.md`
- `Docs/AutonomousMission.md`
- `Docs/Mission-Autonomy.md`
- `Docs/Mission-MapTheWalls.md`
- `Docs/LiveTest.md`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Create a new Docs/*.md file with a descriptive name (e.g., RoomKey.md, AutonomousMission.md, Mission-MapTheWalls.md).
- Write the initial content outlining the new concept or mission.
- Commit the new file with a message summarizing the addition.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.