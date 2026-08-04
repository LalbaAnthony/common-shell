#!/bin/bash

set -euo pipefail

EXTRA_FILE="$HOME/.bashrc_extra"

remove_extra() {
    if [ -f "$EXTRA_FILE" ]; then
        echo "Removing $EXTRA_FILE..."
        rm "$EXTRA_FILE"
    else
        echo "$EXTRA_FILE not found, skipping."
    fi
}

main() {
    remove_extra
    echo "Bash extra uninstalled successfully!"
}

main
