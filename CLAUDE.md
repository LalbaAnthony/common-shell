# CLAUDE.md

## Overview

Personal shell configuration distributed as two sourceable profiles — one for Bash, one for PowerShell — plus installers that fetch them from GitHub raw into the user's home directory and register a login job. There is no application, no build, and no runtime; the deliverables are the config files themselves.

In the repository each profile is **split into one part file per section**; the installers concatenate the parts, in manifest order, into the single `*_extra` file the user's rc file sources. The home directory still holds exactly one file per shell.

## Tech stack

- **Bash** — Bash, not POSIX `sh` (uses `shopt`, `[[`, arrays, process substitution). No Bash-4-only syntax is present (no associative arrays, `mapfile`/`readarray`, case-modifying expansions), so no minimum version is asserted. `src/bash/*.sh` are sourced, not executed, and carry no shebang; `scripts/*.sh` declare `#!/bin/bash`.
- **PowerShell** — `src/pwsh/*.ps1` and `scripts/*.ps1` target Windows PowerShell 5.1 and PowerShell 7. Every part, and the assembled profile, parses under 5.1.
- **No package manager, no manifest, no build system.** No `package.json`, `composer.json`, `Makefile`, or equivalent exists.
- **CI**: GitHub Actions. ShellCheck pinned to `v0.11.0` (Docker image `koalaman/shellcheck`), PSScriptAnalyzer pinned to `1.25.0`.

## Structure

```
src/bash/manifest.txt              # Ordered part list — concatenated into ~/.bashrc_extra
src/bash/<NNN>-<name>.sh           # One part per section
src/pwsh/manifest.txt              # Ordered part list — concatenated into $HOME/profile_extra.ps1
src/pwsh/<NNN>-<name>.ps1
scripts/install.sh                 # Bash installer (curl | bash)
scripts/uninstall.sh
scripts/migration.sh               # Per-host actions, run by cshmgr / cshall — see Architecture
scripts/install.ps1                # PowerShell installer (irm | iex)
scripts/uninstall.ps1
scripts/migration.ps1
.github/scripts/lint-bash.sh       # ShellCheck runner — all lint logic lives here, not in the workflow
.github/scripts/lint-pwsh.ps1      # PSScriptAnalyzer runner
.github/scripts/check-manifests.sh # Fails if a manifest and its directory disagree
.github/workflows/lint.yml         # Thin: triggers, version pins, module cache
PSScriptAnalyzerSettings.psd1      # PSSA rule config
.gitattributes                     # Enforces line endings — see Gotchas
docs/dev/git.md                    # Branching and commit conventions
.claude/agents/                    # add-shell-command, shell-parity-audit — procedures that defer to this file
.claude/settings.json              # Claude Code permission allowlist for the lint and check commands
```

Current parts, by band (see "Part numbering" under Conventions):

| Band | `src/bash/` | `src/pwsh/` |
| --- | --- | --- |
| `0NN` shared | `000-core` `001-self` `002-random` `003-network` `004-python` `005-node` `006-git` `007-claude` `008-docker` `009-aliases` `010-env` `011-agoravita` | same twelve numbers and names |
| `1NN` Bash only | `101-apache` `102-sql` `103-certbot` `104-php` `105-laravel` `109-wordpress` | — |
| `2NN` PowerShell only | — | `202-vscode` `203-sleep` `204-shortcuts` |

`000-core.sh` holds the PS1 theme, history settings and the file-wide ShellCheck prose; `000-core.ps1` holds the PATH merge, the `prompt` function and a `pwsh` function. There are no entry points in the executable sense: `src/` holds what ships, `scripts/` holds what installs it.

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
bash .github/scripts/lint-bash.sh src/bash/006-git.sh scripts/install.sh
```

```powershell
./.github/scripts/lint-pwsh.ps1 -Path src/pwsh/006-git.ps1
```

Reproduce CI annotation output locally:

```bash
GITHUB_ACTIONS=true bash .github/scripts/lint-bash.sh
```

Check that both manifests still match their directories (no Docker or modules needed):

```bash
bash .github/scripts/check-manifests.sh
```

Syntax checks that need neither Docker nor PSScriptAnalyzer. The PowerShell one must run under `powershell.exe` (5.1), since PSSA does not catch 5.1 parse errors:

```bash
for f in src/bash/*.sh scripts/*.sh .github/scripts/*.sh; do bash -n "$f" || echo "FAIL $f"; done
```

```powershell
powershell.exe -NoProfile -Command {
    foreach ($f in Get-ChildItem src/pwsh/*.ps1, scripts/*.ps1, .github/scripts/*.ps1) {
        $e = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$null, [ref]$e)
        if ($e) { $f.Name; $e }
    }
}
```

Parse the assembled profile under 5.1, joined the way `install.ps1` joins it (prints nothing when clean; the nested `powershell.exe` may emit a CLIXML progress record, which is noise):

```powershell
powershell.exe -NoProfile -Command {
    $parts = Get-Content src/pwsh/manifest.txt | ForEach-Object { ($_ -split '#')[0].Trim() } | Where-Object { $_ }
    $body = ($parts | ForEach-Object { (Get-Content -Raw "src/pwsh/$_").TrimEnd("`r", "`n") }) -join "`n`n"
    $e = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput($body, [ref]$null, [ref]$e)
    $e
}
```

Install / uninstall (these modify the invoking user's home directory, shell profile and login items — see Gotchas before running):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/install.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/uninstall.sh)
```

```powershell
irm https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/install.ps1 | iex
irm https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/uninstall.ps1 | iex
```

No setup, build, run/dev, test, format, or typecheck commands exist in this repository.

## Architecture

Install flow, identical in shape on both platforms:

1. Installer downloads `raw.githubusercontent.com/<repo>/main/src/<shell>/manifest.txt` — the branch is hardcoded to `main` in `scripts/install.sh:6` and `scripts/install.ps1:5`.
2. It downloads each part the manifest names, in order, and concatenates them with one blank line between parts, under a two-line generated header.
3. It writes the result to the home directory (`~/.bashrc_extra` / `$HOME/profile_extra.ps1`) **in one shot** — Bash assembles into a `mktemp` sibling and `mv`s it into place, PowerShell buffers in memory and calls `Set-Content` once. A part that 404s aborts the install with the previously installed file untouched, rather than leaving a truncated profile for the rc file to source.
4. It appends a one-line hook to the user's rc file (`~/.bashrc` / `$PROFILE`), preceded by a blank line, if not already present.
5. It registers `cshall` to run in the background at login, overwriting any previous registration. Bash writes `${XDG_CONFIG_HOME:-~/.config}/systemd/user/common-shell-cshall.service` (`Type=simple`, `WantedBy=default.target`, `ConditionPathExists=%h/.bashrc_extra`) and enables it; the unit runs `/bin/bash -O expand_aliases -c '. "%h/.bashrc_extra"; eval cshall'` — explicit source because non-interactive bash skips `~/.bashrc`, `expand_aliases` + `eval` because `cshall` is an alias chain and a plain `bash -c` exits 127 on it. `StandardOutput=null` / `StandardError=null` keep the run out of the journal. When no systemd user manager is reachable (macOS, Git Bash, WSL without systemd, containers), this step is skipped with a message. PowerShell writes `common-shell-cshall.lnk` to `shell:startup`: the installer's own edition (`$PSHOME`) with `-NoLogo -NoProfile -NonInteractive -WindowStyle Hidden`, dot-sourcing `profile_extra.ps1` explicitly; nothing is logged. The shortcut's show command is *minimized* (`WindowStyle = 7`) on purpose — a normal start is handed to Windows Terminal when it is the default terminal, which ignores `-WindowStyle Hidden` and stays on screen; minimized stays in conhost and is hidden after ~300 ms.
6. It re-sources the rc file (no lasting effect on the caller — see Gotchas).

Manifest parsing is the same on both sides: strip everything after `#`, strip all whitespace (which also absorbs the CR of a CRLF manifest), skip empty lines. `.github/scripts/check-manifests.sh` reuses that parse so CI and the installers agree on what a manifest says.

Uninstall reverses steps 3 to 5: it first removes the login entry (`systemctl --user disable` plus the unit file, or the `.lnk`; with no reachable user manager it deletes the unit file and its `default.target.wants/` symlink by hand), then deletes the profile file, then removes the hook line from the rc file along with the blank separator line the installer wrote before it, so repeated install/uninstall cycles do not accumulate blank lines. Bash restores `~/.bashrc` byte for byte when it ended with a newline; PowerShell does not guarantee that (see Gotchas). Uninstall must survive running *inside* the login job, i.e. `cshdel` called from `migration.*` (the AGORA blocks carry it, commented out): hence no `--now`, since stopping the unit would kill the uninstall halfway. Bash rewrites `~/.bashrc` in place (not via a temp file and `mv`) so ownership and mode are preserved. Every step is a no-op with a message when its target is already absent, so uninstall is idempotent.

Self-management commands, defined in `src/bash/001-self.sh` / `src/pwsh/001-self.ps1`, all fetching from `main`:

| Command | Does |
| --- | --- |
| `cshupd` | Re-runs the installer — update is just re-install |
| `cshdel` | Runs the uninstaller |
| `cshmgr` | Runs `scripts/migration.*` |
| `cshall` | `cshmgr ; cshupd` — what the login job runs |
| `cshopen` | `cd` home and list the profile files |

`scripts/migration.sh` / `scripts/migration.ps1` branch on `$HOSTNAME` / `$env:COMPUTERNAME`: each known host gets its own block of one-off actions, and any other host is a no-op (the `cshdel` fallback for unknown hosts was removed in `f066036`). The `AGO26L004` block in `migration.ps1` calls a script outside this repo by absolute path (`C:\Users\a.lalba\projects\antho-scripts\…`). Because `cshall` runs at every login and on every manual call, every action placed there runs repeatedly and unattended — it must be idempotent and non-interactive.

CI has three independent jobs (`manifests`, `bash`, `pwsh`) on `ubuntu-latest`, each a single call into `.github/scripts/`. The scripts are the interface; the workflow only supplies pins and caching. All three emit GitHub annotations when `GITHUB_ACTIONS=true` and plain text otherwise. The `pwsh` job runs PSScriptAnalyzer under PowerShell 7 on Linux; no job runs `bash -n` or any 5.1 parse check. Triggers: `push` to `main` only, filtered to `.github/**`, `scripts/**`, `src/**`, `PSScriptAnalyzerSettings.psd1`; every `pull_request`; `workflow_dispatch`. A push to `develop` is not linted unless a PR is open.

## Conventions

- **A new section is two edits.** Create `src/<shell>/<NNN>-<name>.<ext>` *and* add it to that directory's `manifest.txt`. Neither alone works: an unlisted part is silently dropped from every install, a listed-but-absent part 404s the install. `check-manifests.sh` fails the build on either.
- **The numeric prefix encodes shell coverage** — `0NN` shared, `1NN` Bash only, `2NN` PowerShell only. See "Part numbering" below; it is the rule most likely to be got wrong.
- **PowerShell function naming.** PSScriptAnalyzer runs `PSUseApprovedVerbs` and `PSUseShouldProcessForStateChangingFunctions` on every tracked `*.ps1`, `src/pwsh/` parts included. A new `Verb-Noun` function must use an approved verb that is *not* state-changing (`New`, `Set`, `Remove`, `Start`, `Stop`, `Restart`, `Reset`, `Update` trigger the ShouldProcess rule). `Get`, `Invoke`, `Register`, `Unregister`, `Uninstall` satisfy both. Single-word function names (`Main`, `prompt`, `cshupd`) are exempt from the verb rule.
- **PSSA exclusions** (`PSScriptAnalyzerSettings.psd1`): `PSAvoidUsingWriteHost` and `PSAvoidUsingInvokeExpression` are globally disabled — coloured interactive output and `irm | iex` installs are intentional. Severity threshold is `Error` + `Warning`.
- **ShellCheck exemptions are file-scoped, not repo-wide.** There is no `.shellcheckrc`. Every `src/bash/*.sh` part carries its own header (`# shellcheck shell=bash`, then `# shellcheck disable=SC1091,SC2034,SC2142,SC2154`) because each part is linted on its own, is sourced rather than executed, and is full of single-quoted alias bodies. `000-core.sh` additionally carries the prose explaining each code; it is first in the manifest, so that explanation lands at the top of the generated file. Everything under `scripts/` and `.github/scripts/` lints strictly. Suppress new findings inline at the line, not globally.
- **Git**: per `docs/dev/git.md`, work lands on `develop` and is merged into `main`; topic branches take a `feat/`, `fix/`, `ref/`, `docs/` or `test/` prefix. Commits follow Conventional Commits, in practice with a scope (`feat(shell): …`, `feat(agoravita): …`, `refactor(shell): …`, `chore(shell): …`).
- Comments in English.

### Part numbering

The three-digit prefix on every `src/<shell>/` part encodes **which shells the section covers**. The leading digit is the band; the remaining two order parts within it.

| Band | Meaning | Lives in |
| --- | --- | --- |
| `0NN` | Section exists in **both** shells | `src/bash/` *and* `src/pwsh/` |
| `1NN` | **Bash only** | `src/bash/` |
| `2NN` | **PowerShell only** | `src/pwsh/` |

**The pairing rule.** A `0NN` number names the same section in both shells: `002-random.sh` and `002-random.ps1` are the same section, and the shared band is contiguous (`000`–`011` in both directories), so listing both directories side by side makes a missing counterpart obvious. That is the point of the scheme: after adding something to one shell, the numbers tell you whether the other shell owes you a counterpart.

**Which band does a new section get?**

- **Portable in principle** — the concept works in both shells, even if only one side is written yet: `0NN`, and create the counterpart. If the other side genuinely cannot be written now, use the shell-specific band and promote it later rather than leaving a half-empty `0NN` pair.
- **Inherently one-shell** — the section is meaningless elsewhere (`apache`, `sql`, `certbot`, `php`, `laravel`, `wordpress` are Linux-server concerns; `vscode`, `sleep`, `shortcuts` drive Windows processes and paths): `1NN` or `2NN`.

Ask "would I ever want this in the other shell?", not "have I written it yet?".

**Numbers within a band step by 1**, not 10 (since commit `6c2f0d5`). There is no room between neighbours: appending after a band's last number (`012`, `110`, `205` today) touches nothing else, and the unused numbers below a band's last part (`100`, `106`–`108`, `200`, `201`) are also free, but inserting between two occupied numbers means renaming every later part in that band and editing the manifest — in both directories for `0NN`. The bands are independent, so renumbering one never touches another. Prefixes exist to make a directory listing read in install order; the manifest, not the prefix, is what the installer reads. Nothing enforces that the two agree on order, so keep them in sync by hand.

**Promoting a section from shell-specific to shared** (say, porting `102-sql.sh` to PowerShell) is a rename plus two manifest edits: move it to the next free `0NN` in *both* directories and update both manifests. `6c2f0d5` did exactly this for agoravita (`190-` → `011-`). Renaming and updating the manifest are not optional — `check-manifests.sh` fails the build if a part is not listed, and the install 404s if the manifest names a file that is not there.

**What is not enforced.** `check-manifests.sh` verifies that each manifest matches its own directory. It does **not** check the pairing rule — nothing fails the build when `0NN-foo.sh` exists without `0NN-foo.ps1`, when the same `0NN` names different sections on the two sides, or when a part sits in the wrong band. That is a convention held by hand and by review. Pairing guarantees a counterpart *file*, not equal content: `011-agoravita.sh` defines `crij`, `kwc`, `kdev`, `atld`, `devs`; `011-agoravita.ps1` only `crij`.

## Testing

**No test framework, no test files, no test command.** Linting, `check-manifests.sh` and the syntax checks under Commands are the only automated checks, and CI runs only the first two. Behavioural verification is manual: source the profile and exercise the alias or function.

To exercise an installer end to end without touching your own home directory, serve the working tree with `python -m http.server`, rewrite only the `raw.githubusercontent.com` base URL in a *copy* of the installer, and redirect the home directory. Bash takes `HOME=…` directly. **PowerShell's `$HOME` is read-only**: it cannot be assigned, and a script that tries writes to the real home instead. Redirect it by launching `powershell.exe` with `HOMEDRIVE`/`HOMEPATH`/`USERPROFILE` set, then assert `$HOME` really moved before running anything. That redirection does **not** move `$PROFILE` or `[Environment]::GetFolderPath('Startup')` — both resolve through the known-folder API — so also rewrite `$ProfileFile = $PROFILE` (`scripts/install.ps1:11`, `scripts/uninstall.ps1:6`) and the `GetFolderPath('Startup')` calls (`scripts/install.ps1:94`, `scripts/uninstall.ps1:19`) in the copies, or the test writes the hook into your real profile and the shortcut into your real Startup folder. On the Bash side, put a logging `systemctl` stub first on `PATH` to exercise the unit path on a machine without systemd. Avoid sandbox paths containing an 8.3 short name (`A40C9~1.LAL`) — `Remove-Item -Path` reads the `~` as the home shortcut and fails.

## Environment

- No `.env.example` and no required environment variables for the repo itself.
- Installers read `$HOME`, `XDG_CONFIG_HOME` (Bash unit directory, defaults to `~/.config`), `$PROFILE`, `$PSHOME` (shortcut target) and the `Startup` known folder. Migration scripts read `$HOSTNAME` / `$env:COMPUTERNAME`.
- Lint tooling:
  - `lint-bash.sh` requires a **running** Docker daemon by default. Set `SHELLCHECK_BIN=/path/to/shellcheck` to use a local binary instead (results only match CI if the version matches). Overrides: `SHELLCHECK_VERSION`, `SHELLCHECK_SEVERITY` (default `warning`).
  - `lint-pwsh.ps1` installs PSScriptAnalyzer to `CurrentUser` scope when the pinned version is not already present. Override the pin with `-Version` or `$env:PSSA_VERSION`.
- The profiles call many external CLIs (`docker`, `git`, `curl`, `php`, `composer`, `artisan`, `wp`, `npm`, `yarn`, `npx`, `python`, `claude`, `certbot`, `openssl`, `mysql`). None are validated at source time; individual commands fail if the tool is missing.

## Gotchas

- **Nothing reads the working tree.** Installers and the `csh*` commands fetch from GitHub `main`. A local edit, or a commit on `develop`, reaches no machine until it is merged into `main` and `cshupd` runs (or the next login runs `cshall`). Never run the installers to "test" a local change — they rewrite your real home directory from `main`.
- **`.gitattributes` enforces line endings**: `*.ps1` → CRLF, `*.sh` → LF, `manifest.txt` → LF. Do not normalise these away — a CRLF shebang breaks Bash scripts on Linux. `eol=crlf` is a *checkout* rule: the blob in the repo is LF, so `raw.githubusercontent.com` serves the `.ps1` parts with LF and the installer normalises from there.
- **`src/bash/*.sh` parts have no shebang** by design (they are concatenated and sourced). Each part's ShellCheck header directives must stay above its first command or they stop applying file-wide.
- **`lint-bash.sh` prints `ShellCheck: clean.` when Docker is unreachable.** Docker's error goes to stderr, the captured report is empty, and the script still exits non-zero. Trust the exit code, not the last line.
- **Never fetch a part with `Invoke-WebRequest ….Content`.** That property is a `string` for a `text/*` response and a `byte[]` for anything else, so the result silently depends on the server's `Content-Type`; a `byte[]` stringifies into space-separated decimals and the installed profile becomes garbage. `install.ps1` decodes `.RawContentStream` as UTF-8 via `Get-RemoteText` instead, which is header-independent.
- **The hook string is duplicated across four files and must stay byte-identical.** `scripts/install.sh` / `scripts/uninstall.sh` share `BASHRC_HOOK`, and `scripts/install.ps1` / `scripts/uninstall.ps1` share `$ProfileHook`. Uninstall matches the hook by exact line equality, so editing the string in an installer without editing its uninstaller silently strands the hook in the user's rc file. The login entry names are duplicated the same way (`UNIT_NAME`/`UNIT_DIR` in the `.sh` pair, `$StartupLinkName` in the `.ps1` pair); renaming one side strands a unit or shortcut that keeps running `cshall` at every login.
- **PowerShell uninstall does not preserve the profile's bytes.** `uninstall.ps1` rewrites `$PROFILE` with `Set-Content` and no `-Encoding`. Under 5.1, a UTF-8-with-BOM profile containing non-ASCII comes back as ANSI (BOM dropped, `é` → `0xE9`, which PowerShell 7 then misreads), and an LF profile comes back CRLF. ASCII or BOM-less UTF-8 with CRLF round-trips intact. Verified under 5.1 only.
- **Hook detection is asymmetric on PowerShell.** `install.sh` checks for the exact hook line (`grep -qxF`); `install.ps1` skips if `profile_extra.ps1` appears *anywhere* in `$PROFILE` (`scripts/install.ps1:75`). A legacy or hand-written line mentioning that file blocks the real hook from being added, and `uninstall.ps1` will not remove it.
- **The reload step (6) does not update the calling session.** Bash runs the installer in a child process; PowerShell dot-sources `$PROFILE` inside `Invoke-ProfileReload`, whose scope is discarded on return. Open a new shell to load a new profile.
- **`000-core.ps1` defines a `pwsh` function** that opens a new Windows PowerShell window and ignores its arguments. Functions outrank executables, so in a session with the profile loaded `pwsh -File …` does not run PowerShell 7; call `pwsh.exe` explicitly.
- **Asymmetric install paths**: Bash installs to `~/.bashrc_extra` (dotfile), PowerShell to `$HOME/profile_extra.ps1` (no dot).
- **`scripts/install.sh` assumes `~/.bashrc` exists**; `grep` emits a stderr error when it does not, though the append still creates the file. `scripts/install.ps1` explicitly creates `$PROFILE` when missing.
- **Lint and manifest-check target discovery use `git ls-files --cached --others --exclude-standard`.** Untracked-but-not-ignored files *are* covered; files deleted from the working tree but still in the index are skipped. A file added to `.gitignore` silently drops out of CI coverage — including out of the manifest check.
- **`Invoke-ScriptAnalyzer -Settings` silently ignores a `PathInfo` object.** Pass a string (`(Resolve-Path …).Path`) or every exclusion is dropped and the run reports dozens of false failures.
- **`&&` and `||` are PowerShell 7 only.** Windows PowerShell 5.1 rejects them at *parse* time, so a single occurrence anywhere in any part makes the whole generated `profile_extra.ps1` fail to load — every function and alias in it, not just the offending line. Use `;` or `if ($?) { … }`. Same trap for `??`, `?.`, and the ternary `? :`. Inside a string literal they are harmless — `src/pwsh/005-node.ps1:54-55` builds `cd … && npm run dev` strings for a child shell. PSScriptAnalyzer does not catch this; run the 5.1 parse checks under Commands.
- **Some docs still describe the pre-`6c2f0d5` step-by-10 numbering**: `README.md:68`, the header comment of both `manifest.txt` files (line 11), and `.claude/agents/add-shell-command.md:40`, whose examples (like `shell-parity-audit.md`'s) also cite old names such as `110-sql.sh` and `060-git`. The filenames on disk and the Part numbering section above are authoritative.
