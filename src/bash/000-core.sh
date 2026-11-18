# This fragment is concatenated into ~/.bashrc_extra, which is sourced from
# ~/.bashrc, so it carries no shebang.
# shellcheck shell=bash
#
# File-wide ShellCheck exemptions, all specific to an interactive profile:
#   SC1091 - sourced paths (e.g. .venv/bin/activate) only exist at runtime.
#   SC2034 - colour variables are consumed by PS1 and by interactive use.
#   SC2142 - `$2` inside single-quoted awk programs is an awk field, not an arg.
#   SC2154 - variables in single-quoted alias bodies are expanded by the subshell.
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

RED='\[\e[31m\]'
GREEN='\[\e[32m\]'
YELLOW='\[\e[33m\]'
BLUE='\[\e[34m\]'
MAGENTA='\[\e[35m\]'
CYAN='\[\e[36m\]'
WHITE='\[\e[97m\]'
GRAY='\[\e[90m\]'
RESET='\[\e[0m\]'

# Theme
export PS1="\$([ \"\$(id -u)\" = \"0\" ] && echo \"${RED}\" || echo \"${CYAN}\")\u${WHITE}@${GREEN}\h${RESET}:${YELLOW}\w\$(branch=\$(git branch 2>/dev/null | grep '^*' | colrm 1 2); [ -n \"\$branch\" ] && echo \"${GRAY} (\$branch)${RESET}\")${RESET} \$ "

# History
export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTIGNORE="&:ls:cd:cd -:pwd:exit:clear"
shopt -s histappend
set +H # Disable ! style history expansion

# Open a file, directory, URL or URI with the desktop's default handler and
# return without waiting for it: the Bash counterpart of PowerShell's
# Start-Process <target>. Status 1 on bad usage or when no opener exists.
xopen() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: xopen <path|url|uri>" >&2
        return 1
    fi

    local target=$1

    if command -v xdg-open >/dev/null 2>&1; then
        # xdg-open can block until the handler exits. Detach it inside a
        # subshell, so job control neither reports it nor hangs it up
        (xdg-open "$target" >/dev/null 2>&1 &)
    elif command -v open >/dev/null 2>&1; then
        open "$target"
    elif command -v wslview >/dev/null 2>&1; then
        wslview "$target"
    elif command -v explorer.exe >/dev/null 2>&1; then
        # explorer.exe only understands Windows paths; URLs and URIs pass as is
        if [ -e "$target" ]; then
            if command -v cygpath >/dev/null 2>&1; then
                target=$(cygpath -aw "$target")
            elif command -v wslpath >/dev/null 2>&1; then
                target=$(wslpath -aw "$target")
            fi
        fi
        # explorer.exe exits 1 even on success
        explorer.exe "$target" >/dev/null 2>&1 || true
    else
        echo "xopen: no opener found (xdg-open, open, wslview, explorer.exe)." >&2
        return 1
    fi
}

# Numbered menu, one item per line, read from the terminal. Prints the 1-based
# index of the chosen item on stdout; the menu and prompt go to stderr, so it
# works inside $(...). Re-prompts on invalid input. Status 1 on bad usage or
# end of input (Ctrl-D).
#   idx=$(xselect "preset" "${names[@]}") || return
xselect() {
    if [ "$#" -lt 2 ]; then
        echo "Usage: xselect <prompt> <item>..." >&2
        return 1
    fi

    local label=$1
    shift

    # select lays items out in columns sized to COLUMNS; 1 forces one per line
    local COLUMNS=1 PS3="$label (1-$#): " REPLY _
    select _ in "$@"; do
        # No leading zero: (( 08 )) is an invalid octal literal
        if [[ $REPLY =~ ^[1-9][0-9]*$ ]] && (( REPLY <= $# )); then
            echo "$REPLY"
            return 0
        fi
        echo "invalid choice" >&2
    done
    return 1
}
