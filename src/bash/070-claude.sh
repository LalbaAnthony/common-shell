# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias ccopen='cd ~/.claude'
alias ccu='npx ccusage@latest'

ccl() {
    # plan usage limits as shown by /usage, read from the endpoint Claude Code itself queries
    local raw=0 cred_file creds auth token expired resp status body msg rows
    local width=0 label pct left filled bar_on bar_off color dim off reset d h m

    case ${1-} in
        '') ;;
        --json) raw=1 ;;
        *) echo "usage: cclimits [--json]" >&2; return 2 ;;
    esac

    if ! command -v jq >/dev/null 2>&1; then
        echo "cclimits needs jq" >&2
        return 1
    fi

    cred_file="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json"
    if [ -r "$cred_file" ]; then
        creds=$(cat "$cred_file") || return 1
    elif command -v security >/dev/null 2>&1; then
        # macOS keeps the credentials in the login keychain instead of a file
        creds=$(security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null)
    fi
    if [ -z "$creds" ]; then
        echo "no Claude Code credentials found ($cred_file); log in with a claude.ai account first" >&2
        return 1
    fi

    # token last: read collapses a leading empty field when IFS is a tab
    auth=$(jq -r '.claudeAiOauth // {}
        | [((.expiresAt // 0) as $e | $e > 0 and $e <= now * 1000), (.accessToken // "")]
        | @tsv' <<<"$creds") || return 1
    # jq.exe (Git Bash) ends lines with CRLF
    auth=${auth//$'\r'/}
    IFS=$'\t' read -r expired token <<<"$auth"
    if [ -z "$token" ]; then
        echo "no claude.ai OAuth token in the credentials (API-key logins have no plan limits)" >&2
        return 1
    fi
    if [ "$expired" = true ]; then
        echo "OAuth token expired; start Claude Code once to refresh it, then retry" >&2
        return 1
    fi

    # header goes through stdin so the token never shows up in the process list
    resp=$(printf 'Authorization: Bearer %s\n' "$token" |
        curl -sS --max-time 10 -H @- -H 'anthropic-beta: oauth-2025-04-20' \
            -w '\n%{http_code}' https://api.anthropic.com/api/oauth/usage) || return 1
    status=${resp##*$'\n'}
    body=${resp%$'\n'*}

    if [ "$status" != 200 ]; then
        msg=$(jq -r '.error.message // empty' <<<"$body" 2>/dev/null)
        echo "usage request failed: HTTP $status${msg:+ - $msg}" >&2
        if [ "$status" = 401 ]; then
            echo "start Claude Code once to refresh its token, then retry" >&2
        fi
        return 1
    fi

    if [ "$raw" = 1 ]; then
        jq . <<<"$body"
        return
    fi

    # one row per limit object, in API order: label, rounded %, seconds until reset
    # (empty when the API gives no reset time, '?' when it cannot be parsed)
    rows=$(jq -r '
        def cap: (.[0:1] | ascii_upcase) + .[1:];
        to_entries[]
        | select((.value | type) == "object" and (.value.utilization | type) == "number")
        | (.key
            | if . == "five_hour" then "Session (5h)"
              elif . == "seven_day" then "Weekly (7d)"
              elif startswith("seven_day_") then "Weekly " + (.[10:] | gsub("_"; " ") | cap)
              else gsub("_"; " ") | cap
              end) as $label
        | (.value.resets_at
            | if type == "string"
              then (try (sub("\\.[0-9]+"; "") | sub("(Z|[+-]00:?00)$"; "Z") | fromdateiso8601 - now | floor) catch "?")
              else null
              end) as $left
        | [$label, (.value.utilization + 0.5 | floor), $left]
        | @tsv' <<<"$body") || return 1
    rows=${rows//$'\r'/}

    if [ -z "$rows" ]; then
        echo "no usage limits in the response; inspect it with 'cclimits --json'" >&2
        return 1
    fi

    while IFS=$'\t' read -r label pct left; do
        if [ "${#label}" -gt "$width" ]; then
            width=${#label}
        fi
    done <<<"$rows"

    dim='' off=''
    if [ -t 1 ]; then
        dim=$'\e[90m' off=$'\e[0m'
    fi

    while IFS=$'\t' read -r label pct left; do
        # 20 cells, one per 5%, clamped for utilization above 100
        filled=$(( (pct + 2) / 5 ))
        if [ "$filled" -gt 20 ]; then filled=20; fi
        if [ "$filled" -lt 0 ]; then filled=0; fi
        bar_on=$(printf '%*s' "$filled" '')
        bar_off=$(printf '%*s' $(( 20 - filled )) '')
        bar_on=${bar_on// /█}
        bar_off=${bar_off// /░}

        color=''
        if [ -t 1 ]; then
            if [ "$pct" -ge 80 ]; then color=$'\e[31m'
            elif [ "$pct" -ge 50 ]; then color=$'\e[33m'
            else color=$'\e[32m'
            fi
        fi

        case $left in
            '') reset='' ;;
            '?') reset='resets ?' ;;
            *)
                if [ "$left" -lt 0 ]; then left=0; fi
                d=$(( left / 86400 )) h=$(( left % 86400 / 3600 )) m=$(( left % 3600 / 60 ))
                if [ "$d" -gt 0 ]; then reset="resets in ${d}d ${h}h"
                elif [ "$h" -gt 0 ]; then reset="resets in ${h}h ${m}m"
                else reset="resets in ${m}m"
                fi
                ;;
        esac

        printf '%-*s  %s%s%s%s%s %3d%%  %s%s%s\n' \
            "$width" "$label" "$color" "$bar_on" "$dim" "$bar_off" "$off" "$pct" "$dim" "$reset" "$off"
    done <<<"$rows"
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
