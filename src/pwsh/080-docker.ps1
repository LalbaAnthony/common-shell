function dcb { docker compose up --build -d }
function dpa { docker ps -a }
function drm { docker rm -f @args }
function dst { docker stats }
function dim { docker images }
function dclean { docker system prune -af --volumes }
function drestart { docker restart $(docker ps -q) } # Restart all running containers

function dps {
    # Default cols minus IMAGE and COMMAND
    docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}'
}

function dexec {
    param($container)
    if (-not $container) {
        Write-Host "Usage: dexec <container_name_or_id>"
        return
    }

    docker exec -it $container /bin/bash
    if ($LASTEXITCODE -ne 0) { docker exec -it $container /bin/sh }
}

function dlogs {
    param($container)
    if (-not $container) {
        Write-Host "Usage: dlogs <container_name_or_id>"
        return
    }

    docker logs -f $container
}

function denv {
    param($container)
    if (-not $container) {
        Write-Host "Usage: denv <container_name_or_id>"
        return
    }

    docker exec -it $container env
}

function derase {
    Write-Host "WARNING: This will destroy ALL Docker volumes."
    Write-Host "Current state:"
    Write-Host "  Volumes:    $(@(docker volume ls -q 2>$null).Count)"
    Write-Host ""
    $confirm = Read-Host "Type 'ERASE' to confirm"

    if ($confirm -ne 'ERASE') {
        Write-Host "Aborted."
        return
    }

    docker volume rm $(docker volume ls -q) 2>$null

    Write-Host "All Docker volumes removed."
}

function dnuke {
    Write-Host "WARNING: This will destroy ALL Docker containers, images, volumes, networks, and build cache."
    Write-Host "Current state:"
    Write-Host "  Containers: $(@(docker ps -aq 2>$null).Count)"
    Write-Host "  Images:     $(@(docker images -q 2>$null).Count)"
    Write-Host "  Volumes:    $(@(docker volume ls -q 2>$null).Count)"
    Write-Host ""

    $token = -join ((1..6) | ForEach-Object { [char][int]((65..90) + (48..57) | Get-Random) })
    $confirm = Read-Host "Type '$token' to confirm"

    if ($confirm -cne $token) {
        Write-Host "Aborted."
        return
    }

    docker rm -f $(docker ps -aq) 2>$null
    docker volume rm $(docker volume ls -q) 2>$null
    docker system prune -a --volumes -f
    docker builder prune -a -f

    Write-Host "Docker environment wiped."
}

function ddown {
    $ids = @(docker ps -aq 2>$null)

    if ($ids.Count -eq 0) {
        Write-Host "No containers running."
        return
    }

    Write-Host "Stopping $($ids.Count) container(s)..."
    docker stop $ids
    Write-Host "All containers stopped."
}

function dwhere {
    param($container)

    if (-not $container) {
        Write-Host "Usage: dwhere <container_name_or_id>"
        return
    }

    $id = docker inspect --format '{{.Id}}' $container 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $id) {
        Write-Host "Container not found: $container"
        return
    }

    # A missing label renders as the literal '<no value>', not as an empty string
    $composeDir     = docker inspect --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' $container
    $composeProject = docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' $container
    $composeService = docker inspect --format '{{index .Config.Labels "com.docker.compose.service"}}' $container

    if ($composeDir -and $composeDir -ne '<no value>') {
        Write-Host "Origin: docker-compose"
        Write-Host "Project:  $composeProject"
        Write-Host "Service:  $composeService"
        Write-Host "Dir:      $composeDir"
    }
    else {
        Write-Host "Origin: plain docker run"

        $image   = docker inspect --format '{{.Config.Image}}' $container
        $restart = docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' $container
        $ports   = docker inspect --format '{{range $p, $b := .HostConfig.PortBindings}}  -p {{(index $b 0).HostPort}}:{{$p}} {{end}}' $container

        Write-Host ""
        Write-Host "Reconstructed command:"
        Write-Host "docker run -d \"
        if ($ports -and $ports.Trim()) { Write-Host "$ports\" }
        if ($restart -and $restart -ne 'no') { Write-Host "  --restart $restart \" }
        Write-Host "  $image"
    }

    Write-Host ""
    Write-Host "Created:  $(docker inspect --format '{{.Created}}' $container)"
    Write-Host "Started:  $(docker inspect --format '{{.State.StartedAt}}' $container)"
}
