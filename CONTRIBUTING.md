# Contributing

This is a private solo app repo, but it should still use a professional flow.

## Standard Workflow

1. Start from a clean `main`.
2. Create a short-lived branch for one focused change.
3. Commit small, understandable units of work.
4. Push the branch.
5. Open a pull request.
6. Let CI run.
7. Review the diff, screenshots, and verification notes.
8. Merge only when the branch is in a good state.

## Branch Naming

Use short names that explain the work:

```text
feature/start-screen
feature/reveal-animation
fix/card-detail-transition
docs/github-basics
setup/xcode-project
```

## Commit Style

Prefer commits that explain why the change exists, not just what files changed.

Good:

```text
Create a private home for the motion reveal prototype
```

Weak:

```text
update files
```

## Verification

Before opening or merging a pull request, run the relevant checks locally:

```sh
swift package resolve
swift build
```

When the real Xcode app exists, also build the app target on an iPhone simulator.

## Privacy

Do not commit:

- API keys
- Signing certificates
- Provisioning profiles
- Paid/licensed assets that should stay elsewhere
- Private `.riv` or `.lottie` files unless they are intentionally part of this private repo
