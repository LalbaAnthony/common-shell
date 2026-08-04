# CLAUDE.md

## Overview

Personal shell configuration distributed as two sourceable profile files — one for Bash, one for PowerShell — plus installers that fetch them from GitHub raw into the user's home directory. There is no application, no build, and no runtime; the deliverables are the config files themselves.

## Tech stack

- **Bash** — Bash, not POSIX `sh` (uses `shopt`, `[[`, arrays, process substitution). No Bash-4-only syntax is present, so no minimum minor version is asserted. `src/bash/bashrc_extra.sh` is sourced, not executed; `scripts/*.sh` declare `#!/bin/bash`.
- **PowerShell** — `src/powershell/profile_extra.ps1` targets Windows PowerShell 5.1 and PowerShell 7 (no PS7-only syntax present).
- **No package manager, no manifest, no build system.** No `package.json`, `composer.json`, `Makefile`, or equivalent exists.
- **CI**: GitHub Actions. ShellCheck pinned to `v0.11.0` (Docker image), PSScriptAnalyzer pinned to `1.25.0`.

## Structure

```
src/bash/bashrc_extra.sh          # Bash profile — the deliverable, installed to ~/.bashrc_extra
src/powershell/profile_extra.ps1  # PowerShell profile — installed to $HOME/profile_extra.ps1
scripts/install.sh                # Bash installer (curl | bash)
scripts/uninstall.sh
scripts/install.ps1               # PowerShell installer (irm | iex)
scripts/uninstall.ps1
.github/scripts/lint-bash.sh      # ShellCheck runner — all lint logic lives here, not in the workflow
.github/scripts/lint-powershell.ps1
.github/workflows/lint.yml        # Thin: triggers, version pins, module cache
PSScriptAnalyzerSettings.psd1     # PSSA rule config
.gitattributes                    # Enforces line endings — see Gotchas
```

There are no entry points in the executable sense. `src/` holds what ships; `scripts/` holds what installs it.

## Commands

Lint everything (both discover their own targets via git):

```bash
bash .github/scripts/lint-bash.sh
```

```powershell
./.github/scripts/lint-powershell.ps1
```

Lint specific files:

```bash
bash .github/scripts/lint-bash.sh src/bash/bashrc_extra.sh scripts/install.sh
```

```powershell
./.github/scripts/lint-powershell.ps1 -Path src/powershell/profile_extra.ps1
```

Reproduce CI annotation output locally:

```bash
GITHUB_ACTIONS=true bash .github/scripts/lint-bash.sh
```

Install / uninstall (these modify the invoking user's home directory and shell profile — see Gotchas before running):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/install.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/uninstall.sh)
```

```powershell
irm https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/install.ps1 | iex
irm https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/uninstall.ps1 | iex
```

No setup, build, run/dev, test, format, or typecheck commands exist in this repository.

## Architecture

Install flow, identical in shape on both platforms:

1. Installer downloads the profile from `raw.githubusercontent.com/<repo>/main/src/<shell>/<file>` — the branch is hardcoded to `main` in `scripts/install.sh:6` and `scripts/install.ps1:5`.
2. It writes to the home directory (`~/.bashrc_extra` / `$HOME/profile_extra.ps1`).
3. It appends a one-line hook to the user's rc file (`~/.bashrc` / `$PROFILE`) if not already present.
4. It re-sources the rc file.

The installed profiles define `cshup` and `cshdel`, which re-run the install and uninstall scripts — so update is just re-install.

CI has two independent jobs (`bash`, `powershell`) on `ubuntu-latest`, each a single call into `.github/scripts/`. The scripts are the interface; the workflow only supplies pins and caching. Both scripts emit GitHub annotations when `GITHUB_ACTIONS=true` and plain `file:line:col: severity: message` otherwise.

## Conventions

- **Section banners.** Both profiles are organised with `# ====…` banner comments (`Self`, `Random`, `Network`, `Python`, `Node`, `Git`, `Claude`, `Docker`, …). Add new aliases and functions under the matching banner rather than appending to the end.
- **PowerShell function naming.** PSScriptAnalyzer enforces `PSUseApprovedVerbs` and `PSUseShouldProcessForStateChangingFunctions` on `scripts/`. A new `Verb-Noun` function must use an approved verb that is *not* state-changing (`New`, `Set`, `Remove`, `Start`, `Stop`, `Restart`, `Reset`, `Update` trigger the ShouldProcess rule). `Get`, `Invoke`, `Register`, `Uninstall` satisfy both. Single-word function names (`Main`, `prompt`, `cshup`) are exempt from the verb rule.
- **PSSA exclusions** (`PSScriptAnalyzerSettings.psd1`): `PSAvoidUsingWriteHost` and `PSAvoidUsingInvokeExpression` are globally disabled — coloured interactive output and `irm | iex` installs are intentional. Severity threshold is `Error` + `Warning`.
- **ShellCheck exemptions are file-scoped, not repo-wide.** There is no `.shellcheckrc`. `src/bash/bashrc_extra.sh` carries its own header directives (`# shellcheck shell=bash`, then `disable=SC1091,SC2034,SC2142,SC2154`) because it is sourced and full of single-quoted alias bodies. Everything under `scripts/` lints strictly. Suppress new findings inline at the line, not globally.
- Comments in English.

## Testing

**No test framework, no test files, no test command.** Linting is the only automated check. Behavioural verification is manual: source the profile and exercise the alias or function.

## Environment

- No `.env.example` and no required environment variables for the repo itself.
- Installers rely only on `$HOME` / `$PROFILE` / `$env:USERPROFILE`.
- Lint tooling:
  - `lint-bash.sh` requires **Docker** by default. Set `SHELLCHECK_BIN=/path/to/shellcheck` to use a local binary instead (results only match CI if the version matches). Overrides: `SHELLCHECK_VERSION`, `SHELLCHECK_SEVERITY`.
  - `lint-powershell.ps1` installs PSScriptAnalyzer to `CurrentUser` scope on first run. Override the pin with `-Version` or `$env:PSSA_VERSION`.
- External runtime dependency: the `ayc` / `gyc` / `cyc` functions in `src/powershell/profile_extra.ps1` shell out to a **separate** `antho-scripts` repository expected at `%USERPROFILE%\projects\antho-scripts\`. They no-op with a message when absent.
- The profiles reference many external CLIs (`docker`, `git`, `php`, `artisan`, `wp`, `npm`, `yarn`, `npx`, `python`, `certbot`, `openssl`, `mysql`). None are validated at source time; individual aliases fail if the tool is missing.

## Gotchas

- **`.gitattributes` enforces line endings**: `*.ps1` → CRLF, `*.sh` → LF. Do not normalise these away — a CRLF shebang breaks Bash scripts on Linux.
- **`src/bash/bashrc_extra.sh` has no shebang** by design (it is sourced). Its ShellCheck header directives must stay above the first command or they stop applying file-wide.
- **Uninstall is incomplete.** Both uninstallers delete the profile file but leave the hook line in `~/.bashrc` / `$PROFILE`. Removing the hook is a manual step.
- **Asymmetric install paths**: Bash installs to `~/.bashrc_extra` (dotfile), PowerShell to `$HOME/profile_extra.ps1` (no dot).
- **`scripts/install.sh` assumes `~/.bashrc` exists**; `grep` emits a stderr error when it does not, though the append still creates the file. `scripts/install.ps1` explicitly creates `$PROFILE` when missing.
- **Lint target discovery uses `git ls-files --cached --others --exclude-standard`.** Untracked-but-not-ignored files *are* linted; files deleted from the working tree but still in the index are skipped. A file added to `.gitignore` silently drops out of CI coverage.
- **`Invoke-ScriptAnalyzer -Settings` silently ignores a `PathInfo` object.** Pass a string (`(Resolve-Path …).Path`) or every exclusion is dropped and the run reports dozens of false failures.
