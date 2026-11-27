#!/usr/bin/env bash
#
# Verifies that each src/<shell>/manifest.txt lists exactly the part files
# present in its directory.
#
# The installers concatenate the parts named by the manifest and nothing else,
# so a part that is not listed is silently absent from every install, and a
# listed part that does not exist aborts the install with a 404. Both are
# failures here instead.
#
# Usage:
#   .github/scripts/check-manifests.sh
#
# Environment:
#   GITHUB_ACTIONS  When "true", findings are emitted as workflow annotations.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

status=0

fail() {
    local file=$1 message=$2

    if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
        echo "::error file=${file}::${message}"
    else
        echo "${file}: ${message}" >&2
    fi

    status=1
}

# printf '%s\n' "" emits a blank line, which comm would then read as a real
# entry named "". Emit nothing for an empty list instead.
emit() {
    if [ -n "$1" ]; then
        printf '%s\n' "$1"
    fi
}

check_dir() {
    local dir=$1 ext=$2
    local manifest="${dir}/manifest.txt"

    # Report this directory on its own terms rather than on the global status,
    # so a clean manifest is still confirmed when the other one failed.
    local before=$status

    if [ ! -f "$manifest" ]; then
        fail "$manifest" "manifest is missing"
        return
    fi

    # Same parsing the installers do: drop comments, drop all whitespace
    # (which absorbs a CR), drop empty lines. awk always exits 0, so this is
    # safe under `set -e` even for an all-comments manifest.
    local listed
    listed="$(awk '{ sub(/#.*/, ""); gsub(/[[:space:]]/, ""); if (length($0)) print }' "$manifest")"

    if [ -z "$listed" ]; then
        fail "$manifest" "manifest lists no files"
        return
    fi

    local duplicates
    duplicates="$(printf '%s\n' "$listed" | sort | uniq -d)"
    if [ -n "$duplicates" ]; then
        local dup
        while IFS= read -r dup; do
            fail "$manifest" "listed more than once: ${dup}"
        done <<< "$duplicates"
    fi

    # Matches the lint scripts' discovery so a part is checked as soon as it
    # exists, committed or not. The existence test drops paths still in the
    # index but already gone from the working tree - without it a rename that
    # is not yet staged reports every old name as an unlisted part.
    local present
    present="$(git ls-files --cached --others --exclude-standard "${dir}/*${ext}" |
        while IFS= read -r path; do
            # An `&&` here would leave the loop exiting 1 on a missing final
            # path, which `set -o pipefail` turns into a silent abort.
            if [ -f "$path" ]; then
                printf '%s\n' "${path##*/}"
            fi
        done | sort -u)"

    local unlisted missing name
    unlisted="$(comm -13 <(emit "$listed" | sort -u) <(emit "$present"))"
    missing="$(comm -23 <(emit "$listed" | sort -u) <(emit "$present"))"

    if [ -n "$unlisted" ]; then
        while IFS= read -r name; do
            fail "${dir}/${name}" "not listed in ${manifest} - it would be dropped from every install"
        done <<< "$unlisted"
    fi

    if [ -n "$missing" ]; then
        while IFS= read -r name; do
            fail "$manifest" "lists ${name}, which does not exist in ${dir}/"
        done <<< "$missing"
    fi

    if [ "$status" -eq "$before" ]; then
        echo "${manifest}: $(printf '%s\n' "$listed" | wc -l | tr -d ' ') part(s), in sync."
    fi
}

check_dir "src/bash" ".sh"
check_dir "src/pwsh" ".ps1"

exit "$status"
