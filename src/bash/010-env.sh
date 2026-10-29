# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

cpenv () {
    local candidates=(
        ".env.example"
        ".env.sample"
        ".env.dist"
        ".env.template"
    )

    local template=""
    local candidate
    for candidate in "${candidates[@]}"; do
        if [ -f "$candidate" ]; then
            template="$candidate"
            break
        fi
    done

    if [ -z "$template" ]; then
        echo "No env template found here (looked for: ${candidates[*]})."
        return 1
    fi

    if [ -e ".env" ]; then
        local confirm
        read -r -p "'.env' already exists. Overwrite it with '$template'? [Y/n] " confirm
        if [[ "$confirm" =~ ^[Nn] ]]; then
            echo "Aborted."
            return 1
        fi
    fi

    cp "$template" ".env" || return 1
    echo "Copied '$template' to '.env'."
}
