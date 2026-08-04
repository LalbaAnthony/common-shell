#!/bin/bash

set -euo pipefail

EXTRA_FILE="$HOME/.bashrc_extra"

BASHRC_FILE="$HOME/.bashrc"
# Must stay byte-identical to the hook written by install.sh.
BASHRC_HOOK='[ -f ~/.bashrc_extra ] && . ~/.bashrc_extra'

remove_extra() {
    if [ -f "$EXTRA_FILE" ]; then
        echo "Removing $EXTRA_FILE..."
        rm "$EXTRA_FILE"
    else
        echo "$EXTRA_FILE not found, skipping."
    fi
}

unregister_from_bashrc() {
    if [ ! -f "$BASHRC_FILE" ]; then
        echo "$BASHRC_FILE not found, skipping."
        return
    fi

    if ! grep -qxF "$BASHRC_HOOK" "$BASHRC_FILE"; then
        echo "Hook not present in $BASHRC_FILE, skipping."
        return
    fi

    echo "Removing hook from $BASHRC_FILE..."

    local kept=()
    local line last

    # Read the whole file first: the rewrite below targets the same path.
    # `|| [ -n "$line" ]` keeps a final line that has no trailing newline.
    while IFS= read -r line || [ -n "$line" ]; do
        if [ "$line" = "$BASHRC_HOOK" ]; then
            # install.sh writes a blank separator line just before the hook.
            # Drop it too, so repeated install/uninstall cycles do not stack
            # up blank lines at the end of ~/.bashrc.
            if [ "${#kept[@]}" -gt 0 ]; then
                last="${kept[$((${#kept[@]} - 1))]}"
                if [ -z "$last" ]; then
                    kept=("${kept[@]:0:$((${#kept[@]} - 1))}")
                fi
            fi
            continue
        fi
        kept+=("$line")
    done < "$BASHRC_FILE"

    # Rewrite in place rather than via mktemp + mv, which would replace the
    # file with one owned by mktemp's 0600 mode. Everything is already in
    # memory at this point, so there is no read-while-writing hazard.
    if [ "${#kept[@]}" -gt 0 ]; then
        printf '%s\n' "${kept[@]}" > "$BASHRC_FILE"
    else
        : > "$BASHRC_FILE"
    fi
}

main() {
    remove_extra
    unregister_from_bashrc
    echo "Bash extra uninstalled successfully!"
}

main
