# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias ccopen='cd ~/.claude'
alias ccu='npx ccusage@latest'

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
    # untracked files, so 'git add' is not required. All arguments are joined as an
    # optional hint. Only the message goes to stdout; status and errors go to stderr.
    #   ccom
    #   ccom fix race condition on login
    #   ccom | git commit -F -
    local hint="$*"
    local diff scope log prompt raw msg errfile err status

    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        echo "Not a git repository." >&2
        return 1
    }

    command -v claude >/dev/null 2>&1 || {
        echo "Claude Code CLI not found in PATH." >&2
        return 1
    }

    # Lockfiles and minified assets carry no intent worth describing
    local exclude=(-- . ':(exclude)*lock*' ':(exclude)*.min.*')

    # What is staged is what will be committed, so it wins when it exists
    diff=$(git diff --cached "${exclude[@]}")
    scope="staged changes"

    if [ -z "${diff//[[:space:]]/}" ]; then
        scope="working tree (nothing staged)"

        # On an unborn HEAD there is no commit to diff against yet
        if git rev-parse --verify HEAD >/dev/null 2>&1; then
            diff=$(git diff HEAD "${exclude[@]}")
        else
            diff=""
        fi

        # git diff never reports untracked files; synthesise one diff per file
        local file
        while IFS= read -r file; do
            [ -n "$file" ] || continue
            diff+=$'\n'$(git diff --no-index -- /dev/null "$file" 2>/dev/null)
        done < <(git ls-files --others --exclude-standard "${exclude[@]}")
    fi

    if [ -z "${diff//[[:space:]]/}" ]; then
        echo "Nothing to describe: no changes in the working tree." >&2
        return 1
    fi
    diff=${diff:0:60000}

    echo "Describing $scope." >&2

    # Recent history to match the repo's existing style
    log=$(git log --oneline -10 2>/dev/null)

    prompt=$(cat <<EOF
Write one commit message for the diff provided on stdin, which covers the $scope.
Format: Conventional Commits, type(scope): subject, imperative mood, max 72 chars, English.
Match the style of the recent history below when it is consistent.
Output only the message, no quotes, no code fences, no explanation.

Recent history:
$log
EOF
)

    if [ -n "$hint" ]; then
        prompt+=$'\n\nContext from the author: '"$hint"
    fi

    # Claude Code prints startup notices (e.g. the sandbox warning) on stderr; hold
    # them back and only replay them when no message comes out
    errfile=$(mktemp) || return 1
    raw=$(printf '%s\n' "$diff" | claude -p --model haiku "$prompt" 2>"$errfile")
    status=$?
    err=$(<"$errfile")
    rm -f "$errfile"

    if [ "$status" -ne 0 ]; then
        [ -z "$err" ] || printf '%s\n' "$err" >&2
        echo "Claude Code failed to produce a message." >&2
        return 1
    fi
    if [ -z "${raw//[[:space:]]/}" ]; then
        [ -z "$err" ] || printf '%s\n' "$err" >&2
        echo "Claude returned no message." >&2
        return 1
    fi

    # Drop code fences and blank lines Claude may wrap the message in
    msg=$(printf '%s\n' "$raw" | sed -e 's/\r$//' -e '/^[[:space:]]*```/d' -e '/^[[:space:]]*$/d')

    printf '%s\n' "$msg"
}
