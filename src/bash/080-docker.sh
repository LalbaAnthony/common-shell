# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias dcb='docker compose up --build -d'
alias dps='docker ps'
alias dpa='docker ps -a'
alias drm='docker rm -f'
alias dst='docker stats'
alias dim='docker images'
alias dclean='docker system prune -af --volumes'
alias drestart='docker restart $(docker ps -q)' # Restart all running containers

dexec() {
    if [ -z "$1" ]; then
        echo "Usage: dexec <container_name_or_id>"
        return 1
    fi

    docker exec -it "$1" /bin/bash || docker exec -it "$1" /bin/sh
}

dlogs() {
    if [ -z "$1" ]; then
        echo "Usage: dlogs <container_name_or_id>"
        return 1
    fi

    docker logs -f "$1"
}

denv() {
    if [ -z "$1" ]; then
        echo "Usage: denv <container_name_or_id>"
        return 1
    fi

    docker exec -it "$1" env
}

derase() {
    echo "WARNING: This will destroy ALL Docker volumes."
    echo "Current state:"
    echo "  Volumes: $(docker volume ls -q 2>/dev/null | wc -l)"
    echo ""
    read -rp "Type 'ERASE' to confirm: " confirm

    if [ "$confirm" != "ERASE" ]; then
        echo "Aborted."
        return 1
    fi

    # shellcheck disable=SC2046 # word splitting is wanted: one arg per volume ID
    docker volume rm $(docker volume ls -q) 2>/dev/null

    echo "All Docker volumes removed."
}

ddown() {
    local ids
    ids=$(docker ps -aq 2>/dev/null)

    if [ -z "$ids" ]; then
        echo "No containers running."
        return 0
    fi

    echo "Stopping $(echo "$ids" | wc -l) container(s)..."
    docker stop $ids
    echo "All containers stopped."
}

dwhere() {
    if [ -z "$1" ]; then
        echo "Usage: dwhere <container_name_or_id>"
        return 1
    fi

    local id
    id=$(docker inspect --format '{{.Id}}' "$1" 2>/dev/null)
    if [ -z "$id" ]; then
        echo "Container not found: $1"
        return 1
    fi

    local compose_dir compose_project compose_service
    compose_dir=$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' "$1")
    compose_project=$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' "$1")
    compose_service=$(docker inspect --format '{{index .Config.Labels "com.docker.compose.service"}}' "$1")

    if [ -n "$compose_dir" ]; then
        echo "Origin: docker-compose"
        echo "Project:  $compose_project"
        echo "Service:  $compose_service"
        echo "Dir:      $compose_dir"
    else
        echo "Origin: plain docker run"

        local image restart ports envs
        image=$(docker inspect --format '{{.Config.Image}}' "$1")
        restart=$(docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' "$1")
        ports=$(docker inspect --format '{{range $p, $b := .HostConfig.PortBindings}}  -p {{(index $b 0).HostPort}}:{{$p}} {{end}}' "$1")
        envs=$(docker inspect --format '{{range .Config.Env}}  -e {{.}} {{end}}' "$1")

        echo ""
        echo "Reconstructed command:"
        printf "docker run -d \\\n"
        [ -n "$ports" ]   && printf "%s\\\n" "$ports"
        [ "$restart" != "no" ] && [ -n "$restart" ] && printf "  --restart %s \\\n" "$restart"
        printf "  %s\n" "$image"
    fi

    echo ""
    echo "Created:  $(docker inspect --format '{{.Created}}' "$1")"
    echo "Started:  $(docker inspect --format '{{.State.StartedAt}}' "$1")"
}
