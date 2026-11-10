# Git usage

### Branching

We use a Git workflow based on two main branches:

| Branch    | Purpose                                                             |
| --------- | ------------------------------------------------------------------- |
| `main`    | Production-ready code. All hotfixes and critical patches land here. |
| `develop` | A development branch for ongoing work.                              |

For non-main branches, use prefixes to clarify the purpose:

| Prefix  | When to use                 | Example             |
| ------- | --------------------------- | ------------------- |
| `feat/` | New feature                 | `feat/user-auth`    |
| `fix/`  | Bug fix                     | `fix/login-error`   |
| `ref/`  | Code refactoring or cleanup | `ref/api-endpoints` |
| `docs/` | Documentation changes       | `docs/setup-guide`  |
| `test/` | Adding or updating tests    | `test/auth-module`  |

### Commits

- Conventional Commits (https://www.conventionalcommits.org/)
  - `feat: add user authentication`
  - `fix: correct product price calculation`
  - `chore: update dependencies`

### Hooks

The repository ships a `pre-commit` and a `pre-push` hook in `.githooks/` that run every job of the Checks workflow (`.github/workflows/checks.yml`) before the code leaves your machine. Enable them once per clone:

```sh
git config core.hooksPath .githooks
```

| Hook         | Checks                                                                 |
| ------------ | ---------------------------------------------------------------------- |
| `pre-commit` | The staged snapshot — exactly what the commit will record.             |
| `pre-push`   | The tip of every branch being pushed (tags and deletions are skipped). |

Both run the five CI jobs in parallel, under the same names (`manifests`, `bash-syntax`, `bash-lint`, `pwsh-syntax`, `pwsh-lint`), through `.github/scripts/check-all.sh`. Unstaged edits and untracked files are ignored: stage a fix for it to count. A tree that already passed is not checked again, nor is one whose parent passed when the commit touches nothing the checks read, so a push right after a checked commit, or a docs-only commit, costs nothing.

Requirements: a running Docker daemon (ShellCheck) and PowerShell — `pwsh`, or `powershell.exe` on Windows. A missing one fails the hook. Off Windows the 5.1 parse check is skipped with a notice; the `windows-latest` CI job still runs it.

To bypass, at the cost of finding out in CI: `git commit --no-verify`, `git push --no-verify`. To run the checks by hand: `bash .github/scripts/check-all.sh` (working tree) or `bash .github/scripts/check-all.sh --staged` (index).

### Workflows

In any case, make sure you're up to date with the remote repo before starting any work using `git fetch`/`git pull`.

Update `main` using `develop`:
```sh
git fetch

# Keep main up to date with develop
git checkout develop
git pull --rebase
git pull origin main 
git push

git checkout main
git pull --rebase
git pull origin develop
git push

# Switch back to develop for the next work
git checkout develop

# Repeat
```

