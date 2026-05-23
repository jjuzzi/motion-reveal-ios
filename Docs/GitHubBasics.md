# GitHub Basics For This App

This repo is the online home for the app code. The local folder on this Mac is:

```text
/Users/joseph/Developer/motion-reveal-ios
```

The private GitHub repo is:

```text
https://github.com/jjuzzi/motion-reveal-ios
```

## The Mental Model

Git is the version history. GitHub is the private online copy, review surface,
backup, issue tracker, and automation runner.

Think of it like this:

- `main`: the clean version of the project.
- branch: a temporary work lane for one change.
- commit: a saved checkpoint.
- push: upload local commits to GitHub.
- pull request: a review page for a branch before it joins `main`.
- CI: GitHub automatically building/checking the project.

## Normal Pro Workflow

1. Make or switch to a branch.

```sh
git switch -c feature/start-screen
```

2. Work on files.

3. Check what changed.

```sh
git status
git diff
```

4. Commit a checkpoint.

```sh
git add .
git commit -m "Build the first start screen"
```

5. Push the branch.

```sh
git push -u origin feature/start-screen
```

6. Open a pull request.

```sh
gh pr create --fill
```

7. Let GitHub Actions run.

8. Merge when it is good.

## How GitHub Desktop Fits

GitHub Desktop gives you buttons for the same basic actions:

- See changed files.
- Write a commit message.
- Commit.
- Push.
- Create a branch.
- Open a pull request.
- Pull the latest `main`.

The command line is more exact. GitHub Desktop is friendlier when you want to
see the diff and history.

## Rules Of Thumb

- Do not work directly on `main` for bigger changes.
- Keep each branch focused on one idea.
- Commit when the project is in a meaningful state.
- Push often enough that your work is backed up.
- Pull requests are useful even when you are solo because they create a review
  checkpoint and a clean record of decisions.
- CI is your smoke alarm; do not ignore failing checks.

## What To Ask An Agent

Good prompts:

```text
Create a branch for the start screen and open a PR when it builds.
```

```text
Review this PR like a senior iOS engineer and list only blocking issues.
```

```text
Merge the PR if CI passed and the diff only touches the intended files.
```

```text
Add a GitHub issue for the reveal animation work with acceptance criteria.
```

Less useful:

```text
Do stuff on GitHub.
```

## Privacy Check

The repo is private. To verify:

```sh
gh repo view jjuzzi/motion-reveal-ios --json visibility,isPrivate
```

To see who has access:

```sh
gh api repos/jjuzzi/motion-reveal-ios/collaborators --jq '.[] | .login'
```
