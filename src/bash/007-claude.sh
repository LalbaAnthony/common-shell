# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias cc='; claude'
alias ccinstall='npm install -g @anthropic-ai/claude-code'
alias ccgo='cd ~/.claude'
alias ccu='npx -y ccusage@latest'

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

cscratchpad() {
    # list the 30 most recently modified files across all Claude Code scratchpads
    local base="${TMPDIR:-${TEMP:-/tmp}}/claude"

    if [ ! -d "$base" ]; then
        echo "no claude temp dir found at $base" >&2
        return 1
    fi

    {
        printf 'LastWriteTime\tProject\tSession\tName\tLength\tFullName\n'
        find "$base" -type f -path '*/scratchpad/*' \
            -printf '%T@\t%TY-%Tm-%Td %TH:%TM:%TS\t%P\t%s\t%p\n' 2>/dev/null |
            sort -t $'\t' -k1,1 -rn |
            head -30 |
            awk -F'\t' '{
                n = split($3, p, "/")
                printf "%s\t%s\t%s\t%s\t%s\t%s\n", substr($2, 1, 19), p[1], substr(p[2], 1, 8), p[n], $4, $5
            }'
    } | column -t -s $'\t'
}

pwclean() {
    find .playwright-mcp -mindepth 1 -delete
}

ccom() {
    # Suggest a commit message using Claude Code (headless mode). Describes the staged
    # diff when something is staged, otherwise the whole working tree including
    # untracked files, so 'git add' is not required.
    # Built for pipelines: on success, stdout carries the one-line message and nothing
    # else is written anywhere. On failure, stdout stays empty, stderr gets exactly one
    # 'ccom: <reason>' line and the status is 1. git warnings and Claude Code notices
    # are discarded, never replayed.
    #   ccom
    #   ccom | git commit -F -
    local diff scope untracked file log prompt raw msg status

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "ccom: not a git repository." >&2
        return 1
    fi

    if ! command -v claude >/dev/null 2>&1; then
        echo "ccom: Claude Code CLI not found in PATH." >&2
        return 1
    fi

    # Lockfiles and minified assets carry no intent worth describing
    local exclude=(-- . ':(exclude)*lock*' ':(exclude)*.min.*')

    # Every git call discards stderr (on Windows, git diff warns about line endings
    # there) and is judged by its exit status instead.
    # What is staged is what will be committed, so it wins when it exists
    if ! diff=$(git diff --cached "${exclude[@]}" 2>/dev/null); then
        echo "ccom: git diff failed." >&2
        return 1
    fi
    scope="staged changes"

    if [ -z "${diff//[[:space:]]/}" ]; then
        scope="working tree (nothing staged)"
        diff=""

        # On an unborn HEAD there is no commit to diff against yet
        if git rev-parse --verify HEAD >/dev/null 2>&1; then
            if ! diff=$(git diff HEAD "${exclude[@]}" 2>/dev/null); then
                echo "ccom: git diff failed." >&2
                return 1
            fi
        fi

        if ! untracked=$(git ls-files --others --exclude-standard "${exclude[@]}" 2>/dev/null); then
            echo "ccom: git ls-files failed." >&2
            return 1
        fi

        # git diff never reports untracked files; synthesise one diff per file.
        # --no-index exits 1 whenever the two sides differ, i.e. always here
        while IFS= read -r file; do
            [ -n "$file" ] || continue
            diff+=$'\n'$(git diff --no-index -- /dev/null "$file" 2>/dev/null)
        done <<<"$untracked"
    fi

    if [ -z "${diff//[[:space:]]/}" ]; then
        echo "ccom: nothing to describe, the working tree is clean." >&2
        return 1
    fi
    diff=${diff:0:60000}

    # Recent history to match the repo's existing style; empty on an unborn HEAD
    log=$(git log --oneline -10 2>/dev/null)

    prompt=$(cat <<EOF
Write one commit message for the diff provided on stdin, which covers the $scope.
Format: Conventional Commits, type(scope): subject, imperative mood, max 72 chars, English.
Match the style of the recent history below when it is consistent.
Output only the message, on a single line, no quotes, no code fences, no explanation.
Never use double quotes anywhere in the message; quote names or values with single quotes instead.

Recent history:
$log
EOF
)

    # Claude Code prints startup notices (e.g. the sandbox warning) on stderr. The
    # group discards them, and a broken-pipe error from printf too
    raw=$({ printf '%s\n' "$diff" | claude -p --model haiku "$prompt"; } 2>/dev/null)
    status=$?
    if [ "$status" -ne 0 ]; then
        echo "ccom: Claude Code failed (exit $status)." >&2
        return 1
    fi

    # Keep the first line shaped like a Conventional Commits subject: drops code
    # fences, blank lines and any preamble Claude adds despite the prompt. Double
    # quotes become single quotes whatever the prompt obtained
    msg=$(printf '%s\n' "$raw" |
        tr -d '\r' |
        sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/\"/'/g" |
        grep -E -m 1 '^[a-z]+(\([^()]+\))?!?: [^[:space:]]')

    if [ -z "$msg" ]; then
        echo "ccom: Claude Code returned no valid commit message." >&2
        return 1
    fi

    printf '%s\n' "$msg"
}
