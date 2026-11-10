#!/usr/bin/env bash
#
# Syntax-checks shell scripts with `bash -n`, the parser that will actually
# run them. Needs neither Docker nor a network, unlike lint-bash.sh.
#
# Usage:
#   .github/scripts/check-syntax-bash.sh [file ...]
#
# With no arguments, every tracked *.sh file and every Git hook under
# .githooks/ is checked - the same set lint-bash.sh lints.
#
# Environment:
#   GITHUB_ACTIONS  When "true", findings are emitted as workflow annotations.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

targets=()
if [ "$#" -gt 0 ]; then
    targets=("$@")
else
    # --others picks up files not yet committed; the existence test drops paths
    # that are still in the index but already deleted from the working tree.
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            targets+=("$file")
        fi
    done < <(git ls-files --cached --others --exclude-standard '*.sh' '.githooks/*')
fi

if [ "${#targets[@]}" -eq 0 ]; then
    echo "No shell scripts to check."
    exit 0
fi

echo "bash ${BASH_VERSION}: syntax-checking ${#targets[@]} file(s)"

status=0
for file in "${targets[@]}"; do
    # Errors come out as `file: line N: message`.
    if ! report="$("$BASH" -n "$file" 2>&1)"; then
        status=1
        if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
            printf '%s\n' "$report" |
                sed -E 's/^(.+): line ([0-9]+): (.*)$/::error file=\1,line=\2::\3/'
        else
            printf '%s\n' "$report"
        fi
    fi
done

if [ "$status" -eq 0 ]; then
    echo "bash -n: clean."
fi

exit "$status"
