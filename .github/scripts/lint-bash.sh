#!/usr/bin/env bash
#
# Lints shell scripts with a pinned ShellCheck.
#
# Usage:
#   .github/scripts/lint-bash.sh [file ...]
#
# With no arguments, every tracked *.sh file in the repository is linted.
#
# Environment:
#   SHELLCHECK_VERSION   Docker image tag to pin (default: v0.11.0).
#   SHELLCHECK_SEVERITY  Minimum severity to fail on (default: warning).
#   SHELLCHECK_BIN       Path to a local shellcheck binary. When set, Docker is
#                        not used - handy for offline runs, at the cost of
#                        matching CI only if the versions line up.
#   GITHUB_ACTIONS       When "true", findings are emitted as workflow
#                        annotations so they land on the PR diff.

set -euo pipefail

SHELLCHECK_VERSION="${SHELLCHECK_VERSION:-v0.11.0}"
SHELLCHECK_SEVERITY="${SHELLCHECK_SEVERITY:-warning}"

cd "$(git rev-parse --show-toplevel)"

targets=()
if [ "$#" -gt 0 ]; then
    targets=("$@")
else
    # --others picks up files not yet committed; the existence test drops paths
    # that are still in the index but already deleted from the working tree.
    while IFS= read -r file; do
        [ -f "$file" ] && targets+=("$file")
    done < <(git ls-files --cached --others --exclude-standard '*.sh')
fi

if [ "${#targets[@]}" -eq 0 ]; then
    echo "No shell scripts to lint."
    exit 0
fi

run_shellcheck() {
    if [ -n "${SHELLCHECK_BIN:-}" ]; then
        "$SHELLCHECK_BIN" "$@"
        return
    fi

    # Docker needs a native host path; Git Bash / Cygwin report a POSIX one.
    local host_path="$PWD"
    case "${OSTYPE:-}" in
        msys* | cygwin*) host_path="$(pwd -W)" ;;
    esac

    MSYS_NO_PATHCONV=1 docker run --rm \
        --volume "${host_path}:/mnt" \
        --workdir /mnt \
        "koalaman/shellcheck:${SHELLCHECK_VERSION}" "$@"
}

echo "ShellCheck ${SHELLCHECK_VERSION}: linting ${#targets[@]} file(s) at severity '${SHELLCHECK_SEVERITY}'"

status=0
output="$(run_shellcheck \
    --severity="$SHELLCHECK_SEVERITY" \
    --format=gcc \
    "${targets[@]}")" || status=$?

if [ -z "$output" ]; then
    echo "ShellCheck: clean."
    exit "$status"
fi

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    # `file:line:col: severity: message` -> `::severity file=...,line=...::message`
    printf '%s\n' "$output" | sed -E \
        -e 's/^([^:]+):([0-9]+):([0-9]+): error: /::error file=\1,line=\2,col=\3::/' \
        -e 's/^([^:]+):([0-9]+):([0-9]+): warning: /::warning file=\1,line=\2,col=\3::/' \
        -e 's/^([^:]+):([0-9]+):([0-9]+): note: /::notice file=\1,line=\2,col=\3::/'
else
    printf '%s\n' "$output"
fi

# Guard against a non-empty report that somehow carried a zero exit code.
exit "$((status == 0 ? 1 : status))"
