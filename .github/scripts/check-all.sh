#!/usr/bin/env bash
#
# Runs every job of .github/workflows/checks.yml locally, in parallel, and
# reports them all. This is what the Git hooks in .githooks/ run.
#
# Usage:
#   .github/scripts/check-all.sh               Check the working tree as is.
#   .github/scripts/check-all.sh --staged      Check the index: what `git commit`
#                                              is about to record.
#   .github/scripts/check-all.sh --commit REV  Check the tree of commit REV.
#   .github/scripts/check-all.sh --pre-push    Read pre-push hook lines on stdin
#                                              and check the tip of every branch
#                                              being pushed.
#
# Checks, each named after the CI job it mirrors:
#   manifests    check-manifests.sh
#   bash-syntax  check-syntax-bash.sh
#   bash-lint    lint-bash.sh           ShellCheck; needs a running Docker daemon
#   pwsh-syntax  check-syntax-pwsh.ps1  needs powershell.exe; skipped off
#                                       Windows, where 5.1 cannot exist
#   pwsh-lint    lint-pwsh.ps1          PSScriptAnalyzer; needs pwsh, or
#                                       powershell.exe on Windows
# A missing Docker daemon or PowerShell is a failure, not a skip.
#
# Snapshots: every mode but the first exports the tree to a scratch directory
# under the Git directory and runs the checks there, from that tree's own copy
# of the check scripts - what CI checks out. Unstaged edits and untracked
# files therefore neither hide an error nor cause one. A check whose script is
# absent from the tree is skipped: CI would not run it for that tree either.
#
# Cache: a snapshot that passes has its tree hash recorded in
# <git-common-dir>/common-shell/validated-trees. A tree is skipped when it is
# recorded itself, or when its first parent's tree is recorded and the two
# differ only outside RELEVANT_PATHS. The working-tree mode neither reads nor
# writes the cache.
#
# The lint scripts' overrides (SHELLCHECK_BIN, SHELLCHECK_VERSION,
# SHELLCHECK_SEVERITY, PSSA_VERSION) are cleared, so their pinned defaults -
# the versions checks.yml pins - always apply. Call a lint script directly to
# use an override.

set -euo pipefail

# Everything the checks read: a change confined to other paths cannot change
# any outcome. Keep in step with the push `paths` filter of checks.yml.
RELEVANT_PATHS=(.gitattributes .githooks .github scripts src PSScriptAnalyzerSettings.psd1)

# Report order: the order of the jobs in checks.yml.
CHECKS=(manifests bash-syntax bash-lint pwsh-syntax pwsh-lint)

# Exit code by which a check reports "not applicable here" rather than a pass.
SKIP=77

# Validated trees kept in the cache, most recent last.
CACHE_LIMIT=1000

unset SHELLCHECK_BIN SHELLCHECK_VERSION SHELLCHECK_SEVERITY PSSA_VERSION

usage() {
    cat <<'EOF'
Usage: .github/scripts/check-all.sh [--staged | --commit REV | --pre-push]

  (no option)   Check the working tree as is.
  --staged      Check the index (pre-commit hook).
  --commit REV  Check the tree of commit REV.
  --pre-push    Check every branch tip listed on stdin (pre-push hook).
EOF
}

case "${OSTYPE:-}" in
    msys* | cygwin*) on_windows=true ;;
    *) on_windows=false ;;
esac

# Native Windows programs (git, powershell.exe) read paths handed over in the
# environment as C:/... only.
native_path() {
    if [ "$on_windows" = true ]; then
        cygpath -m "$1"
    else
        printf '%s\n' "$1"
    fi
}

# CI runs PSScriptAnalyzer under PowerShell 7: prefer it, and fall back to
# Windows PowerShell where only that exists.
pssa_exe=""
if command -v pwsh >/dev/null 2>&1; then
    pssa_exe=pwsh
elif [ "$on_windows" = true ] && command -v powershell.exe >/dev/null 2>&1; then
    pssa_exe=powershell.exe
fi

ps_flags=(-NoLogo -NoProfile -NonInteractive)
if [ "$on_windows" = true ]; then
    # Process scope only: a Restricted machine policy would refuse the scripts.
    ps_flags+=(-ExecutionPolicy Bypass)
fi

# --- Checks -----------------------------------------------------------------
# Each runs in its own subshell from the root of the tree under test, so exit
# ends that check only.

require_script() {
    if [ ! -f "$1" ]; then
        echo "$1 is not in this tree, so CI would not run it either."
        exit "$SKIP"
    fi
}

check_manifests() {
    require_script .github/scripts/check-manifests.sh
    "$BASH" .github/scripts/check-manifests.sh
}

check_bash_syntax() {
    require_script .github/scripts/check-syntax-bash.sh
    "$BASH" .github/scripts/check-syntax-bash.sh
}

check_bash_lint() {
    require_script .github/scripts/lint-bash.sh
    if ! command -v docker >/dev/null 2>&1; then
        echo "docker not found: ShellCheck runs in the pinned koalaman/shellcheck image."
        exit 1
    fi
    # Without this, lint-bash.sh reports "clean." over Docker's own error.
    if ! docker info >/dev/null 2>&1; then
        echo "Docker daemon unreachable: start Docker and retry."
        exit 1
    fi
    "$BASH" .github/scripts/lint-bash.sh
}

check_pwsh_lint() {
    require_script .github/scripts/lint-pwsh.ps1
    if [ -z "$pssa_exe" ]; then
        echo "No PowerShell found: install PowerShell 7 (pwsh) to run PSScriptAnalyzer."
        exit 1
    fi
    "$pssa_exe" "${ps_flags[@]}" -File .github/scripts/lint-pwsh.ps1
}

check_pwsh_syntax() {
    require_script .github/scripts/check-syntax-pwsh.ps1
    if [ "$on_windows" != true ]; then
        echo "Windows PowerShell 5.1 does not exist here; the windows-latest CI job runs this check."
        exit "$SKIP"
    fi
    if ! command -v powershell.exe >/dev/null 2>&1; then
        echo "powershell.exe not found."
        exit 1
    fi
    powershell.exe "${ps_flags[@]}" -File .github/scripts/check-syntax-pwsh.ps1
}

run_check() {
    case "$1" in
        manifests) check_manifests ;;
        bash-syntax) check_bash_syntax ;;
        bash-lint) check_bash_lint ;;
        pwsh-syntax) check_pwsh_syntax ;;
        pwsh-lint) check_pwsh_lint ;;
        *)
            echo "Unknown check: $1"
            exit 1
            ;;
    esac
}

# Runs every check from $1 in parallel, logging to $2, then prints one line
# per check and the log of every check that did not pass. Returns 1 when any
# check failed.
run_checks() {
    local root=$1 logs=$2
    local name i rc failed=0
    local -a pids=()

    for name in "${CHECKS[@]}"; do
        (
            cd "$root"
            run_check "$name"
        ) </dev/null >"${logs}/${name}.log" 2>&1 &
        pids+=("$!")
    done

    for i in "${!CHECKS[@]}"; do
        name=${CHECKS[$i]}
        rc=0
        wait "${pids[$i]}" || rc=$?
        case "$rc" in
            0)
                echo "  PASS  ${name}"
                ;;
            "$SKIP")
                echo "  SKIP  ${name}"
                sed 's/^/        /' "${logs}/${name}.log"
                ;;
            *)
                echo "  FAIL  ${name}"
                sed 's/^/        /' "${logs}/${name}.log"
                failed=1
                ;;
        esac
    done

    return "$failed"
}

# --- Cache ------------------------------------------------------------------

is_validated() {
    [ -f "$cache_file" ] && grep -qxF "$1" "$cache_file"
}

record_validated() {
    local tmp
    tmp="$(mktemp "${cache_file}.XXXXXX")"
    {
        if [ -f "$cache_file" ]; then
            grep -vxF "$1" "$cache_file" || true
        fi
        printf '%s\n' "$1"
    } | tail -n "$CACHE_LIMIT" >"$tmp"
    mv "$tmp" "$cache_file"
}

# --- Modes ------------------------------------------------------------------

# Checks tree $1 in a snapshot. $2 is its first parent's tree, or empty; $3
# labels the output.
check_snapshot() {
    local tree=$1 parent=$2 label=$3
    local dir index started=$SECONDS status=0

    if is_validated "$tree"; then
        echo "common-shell checks (${label}): tree ${tree:0:12} already validated."
        return 0
    fi

    if [ -n "$parent" ] && is_validated "$parent" &&
        git diff-tree --quiet "$parent" "$tree" -- "${RELEVANT_PATHS[@]}"; then
        echo "common-shell checks (${label}): no checked path changed since validated tree ${parent:0:12}."
        record_validated "$tree"
        return 0
    fi

    dir="${work}/${tree:0:12}"
    index="$(native_path "${dir}/index")"
    mkdir -p "${dir}/tree" "${dir}/logs"
    GIT_INDEX_FILE="$index" git read-tree "$tree"
    GIT_INDEX_FILE="$index" git --work-tree="$(native_path "${dir}/tree")" checkout-index --all

    echo "common-shell checks (${label}): tree ${tree:0:12}, ${#CHECKS[@]} checks in parallel"
    if (
        export GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
        GIT_DIR="$(native_path "$git_dir")"
        GIT_WORK_TREE="$(native_path "${dir}/tree")"
        # SC2030: local to this subshell on purpose - git's own value must
        # survive for the next tree.
        # shellcheck disable=SC2030
        GIT_INDEX_FILE="$index"
        run_checks "${dir}/tree" "${dir}/logs"
    ); then
        record_validated "$tree"
        echo "common-shell checks (${label}): passed in $((SECONDS - started))s."
    else
        echo "common-shell checks (${label}): FAILED in $((SECONDS - started))s."
        status=1
    fi

    # Free it now: --pre-push may check several trees in one run.
    rm -rf "$dir"
    return "$status"
}

check_commit() {
    local rev=$1 label=$2 commit tree parent=""

    if ! commit="$(git rev-parse --verify --quiet "${rev}^{commit}")"; then
        echo "common-shell checks: ${rev} is not a commit." >&2
        return 1
    fi
    tree="$(git rev-parse "${commit}^{tree}")"
    if git rev-parse --verify --quiet "${commit}^1" >/dev/null; then
        parent="$(git rev-parse "${commit}^1^{tree}")"
    fi

    check_snapshot "$tree" "$parent" "$label"
}

check_staged() {
    local index copy tree parent=""

    # git commit hands its in-progress index over in GIT_INDEX_FILE (relative
    # to the top level, where hooks run). Hash a copy: write-tree may write a
    # cache-tree extension back into the index it reads.
    # SC2031: this is git's value; check_snapshot's override is subshell-local
    # on purpose.
    # shellcheck disable=SC2031
    index="${GIT_INDEX_FILE:-$(git rev-parse --git-path index)}"
    copy="${work}/staged-index"
    cp "$index" "$copy"
    tree="$(GIT_INDEX_FILE="$(native_path "$copy")" git write-tree)"
    if git rev-parse --verify --quiet HEAD >/dev/null; then
        parent="$(git rev-parse 'HEAD^{tree}')"
    fi

    check_snapshot "$tree" "$parent" "staged"
}

# Lines are `<local ref> <local sha> <remote ref> <remote sha>`. Only branch
# updates are checked, each distinct tip once; tags and deletions are not.
check_pre_push() {
    local line local_sha remote_ref seen=" " status=0
    local -a lines=()

    # Read it all up front: nothing below may consume the hook's stdin.
    while IFS= read -r line; do
        lines+=("$line")
    done

    if [ "${#lines[@]}" -eq 0 ]; then
        return 0
    fi

    for line in "${lines[@]}"; do
        read -r _ local_sha remote_ref _ <<<"$line"

        case "$remote_ref" in
            refs/heads/*) ;;
            *) continue ;;
        esac
        case "$local_sha" in
            *[!0]*) ;;
            *) continue ;;
        esac
        case "$seen" in
            *" ${local_sha} "*) continue ;;
        esac
        seen="${seen}${local_sha} "

        check_commit "$local_sha" "${remote_ref#refs/heads/}" || status=1
    done

    return "$status"
}

check_worktree() {
    local started=$SECONDS

    mkdir -p "${work}/logs"
    echo "common-shell checks (working tree): ${#CHECKS[@]} checks in parallel"
    if run_checks "$repo_root" "${work}/logs"; then
        echo "common-shell checks (working tree): passed in $((SECONDS - started))s."
        return 0
    fi
    echo "common-shell checks (working tree): FAILED in $((SECONDS - started))s."
    return 1
}

# --- Main -------------------------------------------------------------------

mode=worktree
rev=""
case "${1:-}" in
    "") ;;
    --staged) mode=staged ;;
    --commit)
        if [ -z "${2:-}" ]; then
            usage >&2
            exit 2
        fi
        mode=commit
        rev=$2
        ;;
    --pre-push) mode=pre-push ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
git_dir="$(cd "$(git rev-parse --git-dir)" && pwd)"
state_dir="$(cd "$(git rev-parse --git-common-dir)" && pwd)/common-shell"
cache_file="${state_dir}/validated-trees"

mkdir -p "$state_dir"
work="$(mktemp -d "${state_dir}/run.XXXXXX")"
trap 'rm -rf "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

status=0
case "$mode" in
    worktree) check_worktree || status=$? ;;
    staged) check_staged || status=$? ;;
    commit) check_commit "$rev" "$rev" || status=$? ;;
    pre-push) check_pre_push || status=$? ;;
esac

if [ "$status" -ne 0 ]; then
    case "$mode" in
        staged) echo "Commit aborted. Bypass, at CI's expense: git commit --no-verify" ;;
        pre-push) echo "Push aborted. Bypass, at CI's expense: git push --no-verify" ;;
    esac
fi

exit "$status"
