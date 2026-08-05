# CLAUDE.md

## Overview

Personal shell configuration distributed as two sourceable profile files — one for Bash, one for PowerShell — plus installers that fetch them from GitHub raw into the user's home directory. There is no application, no build, and no runtime; the deliverables are the config files themselves.

In the repository each profile is **split into one part file per section**; the installers concatenate the parts, in manifest order, into the single `*_extra` file the user's rc file sources. The home directory still holds exactly one file per shell.

## Tech stack

- **Bash** — Bash, not POSIX `sh` (uses `shopt`, `[[`, arrays, process substitution). No Bash-4-only syntax is present, so no minimum minor version is asserted. `src/bash/bashrc_extra.sh` is sourced, not executed; `scripts/*.sh` declare `#!/bin/bash`.
- **PowerShell** — `src/pwsh/profile_extra.ps1` targets Windows PowerShell 5.1 and PowerShell 7 (no PS7-only syntax present).
- **No package manager, no manifest, no build system.** No `package.json`, `composer.json`, `Makefile`, or equivalent exists.
- **CI**: GitHub Actions. ShellCheck pinned to `v0.11.0` (Docker image), PSScriptAnalyzer pinned to `1.25.0`.

## Structure

```
src/bash/manifest.txt             # Ordered part list — drives concatenation into ~/.bashrc_extra
src/bash/000-core.sh              # Prompt + history; carries the file-wide ShellCheck header
src/bash/010-self.sh              # One file per banner section, prefix stepping by 10:
src/bash/020-random.sh            #   self, random, network, python, node, git, claude, docker,
src/bash/…                        #   apache, sql, certbot, php, laravel, agoravita (up to 140-)
src/pwsh/manifest.txt             # Ordered part list — concatenated into $HOME/profile_extra.ps1
src/pwsh/000-core.ps1             # prompt function
src/pwsh/010-self.ps1             # self, random, network, python, node, git, claude, docker,
src/pwsh/…                        #   scripts (up to 090-)
scripts/install.sh                # Bash installer (curl | bash)
scripts/uninstall.sh
scripts/install.ps1               # PowerShell installer (irm | iex)
scripts/uninstall.ps1
.github/scripts/lint-bash.sh      # ShellCheck runner — all lint logic lives here, not in the workflow
.github/scripts/lint-pwsh.ps1
.github/scripts/check-manifests.sh # Fails if a manifest and its directory disagree
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
./.github/scripts/lint-pwsh.ps1
```

Lint specific files:

```bash
bash .github/scripts/lint-bash.sh src/bash/bashrc_extra.sh scripts/install.sh
```

```powershell
./.github/scripts/lint-pwsh.ps1 -Path src/pwsh/profile_extra.ps1
```

Reproduce CI annotation output locally:

```bash
GITHUB_ACTIONS=true bash .github/scripts/lint-bash.sh
```

Check that both manifests still match their directories (no Docker or modules needed):

```bash
bash .github/scripts/check-manifests.sh
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

1. Installer downloads `raw.githubusercontent.com/<repo>/main/src/<shell>/manifest.txt` — the branch is hardcoded to `main` in `scripts/install.sh:6` and `scripts/install.ps1:5`.
2. It downloads each part the manifest names, in order, and concatenates them with one blank line between parts, under a two-line generated header.
3. It writes the result to the home directory (`~/.bashrc_extra` / `$HOME/profile_extra.ps1`) **in one shot** — Bash assembles into a `mktemp` sibling and `mv`s it into place, PowerShell buffers in memory and calls `Set-Content` once. A part that 404s aborts the install with the previously installed file untouched, rather than leaving a truncated profile for the rc file to source.
4. It appends a one-line hook to the user's rc file (`~/.bashrc` / `$PROFILE`) if not already present.
5. It re-sources the rc file.

Manifest parsing is the same on both sides: strip everything after `#`, strip all whitespace (which also absorbs the CR of a CRLF manifest), skip empty lines. `.github/scripts/check-manifests.sh` reuses that parse so CI and the installers agree on what a manifest says.

Uninstall reverses steps 2 and 3: it deletes the profile file, then removes the hook line from the rc file along with the blank separator line the installer wrote before it, leaving the rc file byte-identical to its pre-install state. It rewrites the rc file in place (not via a temp file and `mv`) so ownership and mode are preserved. Every step is a no-op with a message when its target is already absent, so uninstall is idempotent.

The installed profiles define `cshup` and `cshdel`, which re-run the install and uninstall scripts — so update is just re-install.

CI has three independent jobs (`manifests`, `bash`, `pwsh`) on `ubuntu-latest`, each a single call into `.github/scripts/`. The scripts are the interface; the workflow only supplies pins and caching. All three emit GitHub annotations when `GITHUB_ACTIONS=true` and plain text otherwise.

## Conventions

- **One part file per banner.** Each part still opens with its `# ====…` banner comment (`Self`, `Random`, `Network`, `Python`, `Node`, `Git`, `Claude`, `Docker`, …), so the concatenated result reads exactly like the old single file. Add new aliases and functions to the part that matches, not to a new file.
- **A new section is two edits.** Create `src/<shell>/<NNN>-<name>.<ext>` *and* add it to that directory's `manifest.txt`. Neither alone works: an unlisted part is silently dropped from every install, a listed-but-absent part 404s the install. `check-manifests.sh` fails the build on either.
- **Numeric prefixes step by 10** (`000-`, `010-`, … `140-`) so a section can be slotted between two existing ones without renumbering. They exist to make a directory listing read in install order — the manifest, not the prefix, is what the installer actually reads. Nothing enforces that the two agree on order, so keep them in sync by hand when inserting.
- **PowerShell function naming.** PSScriptAnalyzer enforces `PSUseApprovedVerbs` and `PSUseShouldProcessForStateChangingFunctions` on `scripts/`. A new `Verb-Noun` function must use an approved verb that is *not* state-changing (`New`, `Set`, `Remove`, `Start`, `Stop`, `Restart`, `Reset`, `Update` trigger the ShouldProcess rule). `Get`, `Invoke`, `Register`, `Uninstall` satisfy both. Single-word function names (`Main`, `prompt`, `cshup`) are exempt from the verb rule.
- **PSSA exclusions** (`PSScriptAnalyzerSettings.psd1`): `PSAvoidUsingWriteHost` and `PSAvoidUsingInvokeExpression` are globally disabled — coloured interactive output and `irm | iex` installs are intentional. Severity threshold is `Error` + `Warning`.
- **ShellCheck exemptions are file-scoped, not repo-wide.** There is no `.shellcheckrc`. Every `src/bash/*.sh` part carries its own two-line header (`# shellcheck shell=bash`, then `disable=SC1091,SC2034,SC2142,SC2154`) because each part is linted on its own, is sourced rather than executed, and is full of single-quoted alias bodies. `000-core.sh` additionally carries the prose explaining what each code is for; it is first in the manifest, so that explanation lands at the top of the generated file. Everything under `scripts/` lints strictly. Suppress new findings inline at the line, not globally.
- Comments in English.

## Testing

**No test framework, no test files, no test command.** Linting and `check-manifests.sh` are the only automated checks. Behavioural verification is manual: source the profile and exercise the alias or function.

To exercise an installer end to end without touching your own home directory, serve the working tree with `python -m http.server`, rewrite only the `raw.githubusercontent.com` base URL in a *copy* of the installer, and redirect the home directory. Bash takes `HOME=…` directly. **PowerShell's `$HOME` is read-only**: it cannot be assigned, and a script that tries writes to the real home instead. Redirect it by launching `powershell.exe` with `HOMEDRIVE`/`HOMEPATH`/`USERPROFILE` set, then assert `$HOME` really moved before running anything. Avoid sandbox paths containing an 8.3 short name (`A40C9~1.LAL`) — `Remove-Item -Path` reads the `~` as the home shortcut and fails.

## Environment

- No `.env.example` and no required environment variables for the repo itself.
- Installers rely only on `$HOME` / `$PROFILE` / `$env:USERPROFILE`.
- Lint tooling:
  - `lint-bash.sh` requires **Docker** by default. Set `SHELLCHECK_BIN=/path/to/shellcheck` to use a local binary instead (results only match CI if the version matches). Overrides: `SHELLCHECK_VERSION`, `SHELLCHECK_SEVERITY`.
  - `lint-pwsh.ps1` installs PSScriptAnalyzer to `CurrentUser` scope on first run. Override the pin with `-Version` or `$env:PSSA_VERSION`.
- External runtime dependency: the `ayc` / `gyc` / `cyc` functions in `src/pwsh/profile_extra.ps1` shell out to a **separate** `antho-scripts` repository expected at `%USERPROFILE%\projects\antho-scripts\`. They no-op with a message when absent.
- The profiles reference many external CLIs (`docker`, `git`, `php`, `artisan`, `wp`, `npm`, `yarn`, `npx`, `python`, `certbot`, `openssl`, `mysql`). None are validated at source time; individual aliases fail if the tool is missing.

## Gotchas

- **`.gitattributes` enforces line endings**: `*.ps1` → CRLF, `*.sh` → LF, `manifest.txt` → LF. Do not normalise these away — a CRLF shebang breaks Bash scripts on Linux. Note that `eol=crlf` is a *checkout* rule: the blob in the repo is LF, so `raw.githubusercontent.com` serves the `.ps1` parts with LF and the installer normalises from there.
- **`src/bash/*.sh` parts have no shebang** by design (they are concatenated and sourced). Each part's ShellCheck header directives must stay above its first command or they stop applying file-wide.
- **Never fetch a part with `Invoke-WebRequest ….Content`.** That property is a `string` for a `text/*` response and a `byte[]` for anything else, so the result silently depends on the server's `Content-Type`; a `byte[]` stringifies into space-separated decimals and the installed profile becomes garbage. `install.ps1` decodes `.RawContentStream` as UTF-8 via `Get-RemoteText` instead, which is header-independent.
- **The hook string is duplicated across four files and must stay byte-identical.** `scripts/install.sh` / `scripts/uninstall.sh` share `BASHRC_HOOK`, and `scripts/install.ps1` / `scripts/uninstall.ps1` share `$ProfileHook`. Uninstall matches the hook by exact line equality, so editing the string in an installer without editing its uninstaller silently strands the hook in the user's rc file.
- **Asymmetric install paths**: Bash installs to `~/.bashrc_extra` (dotfile), PowerShell to `$HOME/profile_extra.ps1` (no dot).
- **`scripts/install.sh` assumes `~/.bashrc` exists**; `grep` emits a stderr error when it does not, though the append still creates the file. `scripts/install.ps1` explicitly creates `$PROFILE` when missing.
- **Lint and manifest-check target discovery use `git ls-files --cached --others --exclude-standard`.** Untracked-but-not-ignored files *are* covered; files deleted from the working tree but still in the index are skipped. A file added to `.gitignore` silently drops out of CI coverage — including out of the manifest check.
- **`Invoke-ScriptAnalyzer -Settings` silently ignores a `PathInfo` object.** Pass a string (`(Resolve-Path …).Path`) or every exclusion is dropped and the run reports dozens of false failures.
