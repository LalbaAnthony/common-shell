# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

hxy () {
    local location=${1:-Toulouse}
    npx @lalba-anthony/hexasky "$location"
}

mdclean () {
    npx @lalba-anthony/md-cleaner $1
}

ayc () {
    cshupd
}

md2docx () {
    if [ -z "$1" ]; then
        echo "Usage: md2docx <path>"
        return 1
    fi

    local source output
    source=$(realpath -e -- "$1") || return 1

    if [[ "${source##*/}" == *.* ]]; then
        output="${source%.*}.docx"
    else
        output="${source}.docx"
    fi

    curl -sS --fail -X POST "https://md2-api.dev-it.app//v1/convert/default?format=docx" \
        -H "Content-Type: text/markdown; charset=utf-8" \
        --data-binary "@${source}" -o "$output" || return 1

    echo "Written $output"
}
