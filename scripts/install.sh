#!/bin/bash

set -euo pipefail

REPO="LalbaAnthony/antho-common-shell"
BRANCH="main"

EXTRA_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/src/bash/bashrc_extra.sh"
EXTRA_FILE="$HOME/.bashrc_extra"

BASHRC_FILE="$HOME/.bashrc"
BASHRC_HOOK='[ -f ~/.bashrc_extra ] && . ~/.bashrc_extra'

download_extra() {
    echo "Deleting existing bash extra if it exists..."
    rm -f "$EXTRA_FILE"

    echo "Downloading bash extra from $EXTRA_URL..."
    curl -fsSL "$EXTRA_URL" -o "$EXTRA_FILE"
}

register_in_bashrc() {
    if grep -qxF "$BASHRC_HOOK" "$BASHRC_FILE"; then
        echo "Hook already present in $BASHRC_FILE, skipping."
    else
        echo "Registering hook in $BASHRC_FILE..."
        echo "" >> "$BASHRC_FILE"
        echo "$BASHRC_HOOK" >> "$BASHRC_FILE"
    fi
}

reload_shell() {
    echo "Reloading shell..."
    # source may not propagate to the parent shell when run via curl | bash
    # shellcheck disable=SC1090
    source "$BASHRC_FILE" || true
}

main() {
    download_extra
    register_in_bashrc
    reload_shell
    echo "Bash extra installed successfully!"
}

main
