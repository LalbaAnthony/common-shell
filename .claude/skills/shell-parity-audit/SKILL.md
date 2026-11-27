---
name: shell-parity-audit
description: Audit and reconcile the shared `0NN` sections between `src/bash/` and `src/pwsh/` — compare commands, comments and behavioural decisions across the two shells, then level each side up to the more elaborate implementation. Use for requests like "audit the 0NN bash vs powershell parts and list the non-language differences", "check 006-git parity between both shells", "port whatever's missing between the shared sections".
argument-hint: [pairs to audit, e.g. 006 008] [exclusions]
context: fork
model: inherit
---

You audit **parity** between the two shells of a personal shell-profile repo, then converge them. `src/bash/*.sh` is concatenated into `~/.bashrc_extra`, `src/pwsh/*.ps1` into `$HOME/profile_extra.ps1`. There is no build and no runtime. The part files are the deliverable.

`CLAUDE.md` at the repo root is the authority — in particular its Part numbering, Conventions and Gotchas sections; this file is the procedure. Where the two disagree, `CLAUDE.md` wins.

You do not see the conversation that invoked you. The scope the caller asked for, if any: $ARGUMENTS

## Scope

The `0NN` band, and only the `0NN` band: a `0NN` number names the _same_ section in both directories, so those are the only pairs parity means anything for. `1NN` (Bash only) and `2NN` (PowerShell only) are out of scope — do not propose porting them unless asked.

Default exclusions, because they are not comparable section-for-section:

- `000-core.*` — carries the file-wide ShellCheck header on the Bash side and the prompt function on the PowerShell side.
- `009-aliases.*` — personal, machine-specific content.

When the caller named pairs or a different exclusion list above, that replaces the defaults; otherwise audit every `0NN` pair minus the defaults.

**Do not use git.** No `git diff`, no `git log`, no committing, no stashing. Read the working tree as it stands. (The repo's own check and lint scripts call `git ls-files` internally for target discovery — running them is fine; pass explicit paths when you want to avoid it.)

## Part 1 — the audit

For each `0NN` pair, compare three things, in this order:

1. **Commands present.** Which aliases/functions exist on one side and not the other.
2. **Comments.** Section headers (`# Folders`, `# Navigation`, `# Node`, …), trailing `# explanation` on individual commands, and block comments above functions. A comment that exists on one side and not the other is a finding.
3. **Decisions.** Where both sides implement the same command but chose differently: argument guards, error handling, exit-code gating, output and feedback, safety checks, idempotency checks, fallbacks.

### The classification rule — this is the whole point of the audit

Report only differences that are **not** forced by the language or the OS.

Ignore (not findings):

- Syntax: `alias x='…'` vs `function x { … }`, `[ -z "$1" ]` vs `(-not $x)`, `$?`/`||` vs `$LASTEXITCODE`, `echo` vs `Write-Host`, `local` vs `param`.
- Platform-only concepts: `sudo`, `systemctl`, `/var/www`, `apt`, `journalctl`, `lsof` vs `Get-NetTCPConnection`, `xdg-open` vs `Invoke-Item`, `.venv/bin/` vs `.venv\Scripts\`, package managers (`dpkg`/`winget`).
- Cosmetic idiom: `head -n 10` vs `Select-Object -First 10`.

Report (findings):

- A portable command missing from one side. Portable means "the concept works in both shells", not "a literal translation exists". `topcpu` is portable (`ps aux --sort` ↔ `Get-Process | Sort-Object`); `jlog` is not.
- A comment present on one side only.
- Divergent behavioural decisions: one side guards an empty argument and the other does not, one side gates a push on the commit succeeding and the other does not, one side checks whether a tool is already installed and the other reinstalls blindly, one side reports what it killed and the other is silent.
- Latent bugs, including ones both sides share, when you are already rewriting that function.
- Internal inconsistencies within one shell (e.g. `$env:USERPROFILE` in one part and `$HOME` in every other).

Present the findings **per pair**, shortest path to the point: what differs, which side is the weaker one. Call out anything that is an outright bug separately from a mere gap — the user wants to know which is which.

## Part 2 — the convergence

Then bring **each** part up to its counterpart's level, in both directions. "Most elaborate" wins: the side with the guard, the feedback, the safety check or the comment is the one the other side is rewritten towards.

Rules:

- Port the _intent_ under each platform's idiom. Never transliterate. If no sane equivalent exists on one platform, leave that side alone and say so in the report — do not invent a fake Windows equivalent of a Linux-only tool.
- Keep the section order, grouping headers and naming of each file intact. Do not reorder existing commands, renumber parts, or touch `1NN`/`2NN`.
- When both sides are already equivalent, change nothing. A pair with no findings is a valid outcome; say so and move on.
- Never leave a `TODO`. Implement it, or state it as out of scope.

### Traps that have already bitten this repo

- **Line endings are enforced by `.gitattributes`.** Write `*.ps1` with CRLF and `*.sh` with LF. If you generate a file through Bash, convert afterwards (`perl -pi -e 's/\r?\n/\r\n/' file.ps1`) and confirm with `file`.
- **`&&`, `||`, `??`, `?.` and the ternary `? :` are PowerShell 7 only.** 5.1 rejects them at _parse_ time, which kills the whole generated `profile_extra.ps1` — every function in it. Use `;` or `if ($?) { … }`. PSScriptAnalyzer does not catch this. Inside a string literal they are harmless.
- **`switch -Wildcard` runs every branch that matches.** `'*.tar.gz'` falls through to `'*.gz'` unless each branch ends in an explicit `break`.
- **PSSA flags `$x -ne $null`.** Write `$null -ne $x`; `PSPossibleIncorrectComparisonWithNull` is a Warning and the threshold is Warning.
- **A missing Docker label renders as the literal `<no value>`**, not as an empty string, so `[ -n "$label" ]` is true for a container that has none.
- Calling `.Trim()` or `.Substring()` on a possibly-`$null` native-command result throws under `Set-StrictMode`.
- A `Verb-Noun` PowerShell function must use an approved verb that is not state-changing (`Get`, `Invoke`, `Register`, `Unregister`, `Uninstall`); `New`, `Set`, `Remove`, `Start`, `Stop`, `Restart`, `Reset`, `Update` trip `PSUseShouldProcessForStateChangingFunctions`. Single-word names are exempt.
- A new `src/bash/*.sh` part opens with exactly these two lines, above any command, and no shebang:

  ```
  # shellcheck shell=bash
  # shellcheck disable=SC1091,SC2034,SC2142,SC2154
  ```

  Parity work usually edits existing parts, so this rarely applies — but an inline `# shellcheck disable=SCxxxx` at the offending line does, for anything new you introduce (word splitting in `docker rm -f $(docker ps -aq)`, for instance, needs `SC2046`).

## Part 3 — verification

Parity work touches many files at once, so verify the whole set, not just the files you remember editing. Run everything that applies, from the repo root, and report the real output.

All five CI checks at once, on the working tree, under Git Bash (from PowerShell, a bare `bash` may resolve to WSL's):

```bash
bash .github/scripts/check-all.sh
```

It needs a running Docker daemon and PowerShell. When either is missing, run the checks one by one instead:

```bash
bash .github/scripts/check-manifests.sh
bash .github/scripts/check-syntax-bash.sh
bash .github/scripts/lint-bash.sh src/bash/<file>.sh ...
```

```powershell
$files = (Get-ChildItem src\pwsh\*.ps1 | ForEach-Object { "src/pwsh/$($_.Name)" })
./.github/scripts/lint-pwsh.ps1 -Path $files
powershell.exe -NoProfile -File .github/scripts/check-syntax-pwsh.ps1
```

- `lint-bash.sh` needs Docker, or `SHELLCHECK_BIN=/path/to/shellcheck` for a local binary. It prints `ShellCheck: clean.` even when Docker is unreachable — trust its exit code, not its last line.
- `check-syntax-pwsh.ps1` is the only check that catches 5.1 parse errors: it parses every `*.ps1` and then the profile assembled the way `install.ps1` assembles it, since a part that is fine alone can still break the assembled file. It must run under `powershell.exe` (5.1) and refuses PowerShell 7.
- If a check cannot run, **say so plainly** — never report an unrun check as passed.

Then assemble both profiles the way the installers do — manifest order, everything after `#` and all whitespace stripped from each manifest line, empty lines skipped, one blank line between parts — into the scratchpad or another temporary directory outside the repo, and `bash -n` the Bash one.

Finish with a load smoke test: source the changed Bash parts in a subshell and `type -t` every function you added or renamed; dot-source the assembled PowerShell profile under `powershell.exe -NoProfile -File` and `Get-Command` the same list. Exercise the pure ones that have no side effects (`randpass`, `list_files`, `topcpu`, argument-guard paths) and show the output. In a session with the profile loaded, `pwsh` is a function from `000-core.ps1` that ignores its arguments — call `pwsh.exe` explicitly.

Never run the installers to verify. They rewrite the invoking user's home directory, rc file and login items, and they fetch from GitHub `main` rather than the working tree.

## Part 4 — the report

Your final message is the report; it is all the caller receives. In this order:

1. **The findings**, grouped per `0NN` pair, with the weaker side named. Bugs flagged apart from gaps. If a pair had no findings, one line saying so.
2. **What you changed**, and in particular every decision that alters existing behaviour rather than just adding to it — the user must be able to veto each one individually.
3. **Anything you deliberately left diverged**, and why (genuine OS or language constraint).
4. **Verification results verbatim**, including any check you could not run.
5. Whether the manifests still match their directories — they only need editing if parity work added or removed a part file.
6. That the change reaches a machine only once it is merged into `main` and `cshupd` runs (or the next login runs `cshall`), since installers fetch from GitHub `main`, not from the working tree.
