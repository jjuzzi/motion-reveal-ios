```markdown
# motion-reveal-ios Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill documents the key development patterns, coding conventions, and collaborative workflows for the `motion-reveal-ios` repository. The codebase is written in TypeScript and focuses on conceptual documentation and protocol design, with a strong emphasis on evolving and expanding core ideas through Markdown documents in the `Docs/` directory. The repository encourages iterative documentation, cross-document updates, and a consistent coding style.

## Coding Conventions

- **File Naming:**  
  Use PascalCase for all file names, including both code and documentation files.  
  _Example:_  
  ```
  UniversalKey.ts
  MissionMapTheWalls.md
  ```

- **Import Style:**  
  Use relative imports for all modules.  
  _Example:_  
  ```typescript
  import { UniversalKey } from './UniversalKey';
  ```

- **Export Style:**  
  Use named exports for all modules.  
  _Example:_  
  ```typescript
  // UniversalKey.ts
  export function UniversalKey() { ... }
  ```

- **Commit Messages:**  
  Freeform commit messages are used, typically around 63 characters in length.  
  _Example:_  
  ```
  Add new section on autonomy principles to UniversalKey.md
  ```

## Workflows

### Expand Existing Concept Doc
**Trigger:** When you want to elaborate on or refine an existing core concept or protocol.  
**Command:** `/expand-concept-doc`

1. Open the relevant `Docs/*.md` file (e.g., `UniversalKey.md`, `Liberator.md`).
2. Add new sections, explanations, or principles based on recent insights or discussions.
3. Commit the changes with a descriptive message referencing the new content.

_Example:_  
```
/expand-concept-doc
```

### Add New Concept or Mission Doc
**Trigger:** When you need to document a new protocol, mission, or conceptual tool.  
**Command:** `/add-concept-doc`

1. Create a new `Docs/*.md` file with a descriptive name (e.g., `RoomKey.md`, `AutonomousMission.md`).
2. Write the initial content outlining the new concept or mission.
3. Commit the new file with a message summarizing the addition.

_Example:_  
```
/add-concept-doc
```

### Update Multiple Concept Docs in Response to New Insight
**Trigger:** When a new principle or discovery affects multiple conceptual areas.  
**Command:** `/update-multiple-docs`

1. Identify all `Docs/*.md` files impacted by the new insight.
2. Edit each relevant file to add or update sections reflecting the new principle.
3. Commit all changes together with a message referencing the shared insight.

_Example:_  
```
/update-multiple-docs
```

## Testing Patterns

- **Test File Naming:**  
  Test files follow the `*.test.*` pattern (e.g., `UniversalKey.test.ts`).
- **Testing Framework:**  
  The specific framework is unknown, but tests are colocated with source files and follow standard TypeScript testing conventions.

_Example:_  
```typescript
// UniversalKey.test.ts
import { UniversalKey } from './UniversalKey';

test('UniversalKey returns correct value', () => {
  expect(UniversalKey()).toBe(/* expected value */);
});
```

## Commands

| Command                | Purpose                                                        |
|------------------------|----------------------------------------------------------------|
| /expand-concept-doc    | Expand or deepen an existing conceptual document               |
| /add-concept-doc       | Add a new conceptual, protocol, or mission document            |
| /update-multiple-docs  | Update multiple docs in response to a new principle or insight |
```
