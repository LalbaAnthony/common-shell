# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias cusage='npx ccusage@latest'
alias cvscode='cd ~/.claude && code .'

ccontinue() {
    # resolve most recent session id for cwd, then hand it to the URI handler
    DIR="$HOME/.claude/projects/$(pwd | sed 's/[^a-zA-Z0-9]/-/g')"
    SID="$(basename "$(ls -t "$DIR"/*.jsonl | head -1)" .jsonl)"
    open "vscode://anthropic.claude-code/open?session=$SID"   # xdg-open on Linux
}
