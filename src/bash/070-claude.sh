# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias ccusage='npx ccusage@latest'
alias ccopen='cd ~/.claude'

pwclean() {
    find .playwright-mcp -mindepth 1 -delete
}

cctn() {
    # resolve most recent session id for cwd, then hand it to the URI handler
    local dir sid uri
    dir="$HOME/.claude/projects/$(pwd | sed 's/[^a-zA-Z0-9]/-/g')"
    sid=$(basename "$(ls -t "$dir"/*.jsonl 2>/dev/null | head -1)" .jsonl 2>/dev/null)

    if [ -z "$sid" ] || [ "$sid" = "*.jsonl" ]; then
        echo "no session transcript found in $dir" >&2
        return 1
    fi

    uri="vscode://anthropic.claude-code/open?session=$sid"

    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$uri" >/dev/null 2>&1 &
    elif command -v open >/dev/null 2>&1; then
        open "$uri"
    elif command -v wslview >/dev/null 2>&1; then
        wslview "$uri"
    elif command -v explorer.exe >/dev/null 2>&1; then
        # explorer.exe exits 1 even on success
        explorer.exe "$uri" >/dev/null 2>&1 || true
    else
        echo "No URI opener found (xdg-open, open, wslview, explorer.exe)." >&2
        return 1
    fi
}
