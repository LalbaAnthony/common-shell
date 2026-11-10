function hxy {
    param($location)

    npx @lalba-anthony/hexasky $location
}

function mdclean {
    param($file)

    npx @lalba-anthony/md-cleaner $file
}

function fzc {
    python -m filezilla_companion
}

function md2docx {
    param($path)

    if (-not $path) {
        Write-Host "Usage: md2docx <path>"
        return
    }

    $ErrorActionPreference = "Stop"

    $source = Resolve-Path -LiteralPath $path
    $output = [IO.Path]::ChangeExtension($source, ".docx")
    $body = [IO.File]::ReadAllBytes($source)

    Invoke-WebRequest -Method Post -Uri "https://md2-api.dev-it.app/v1/convert/default?format=docx" `
        -ContentType "text/markdown; charset=utf-8" -Body $body -OutFile $output -UseBasicParsing

    Write-Host "Written $output"
}

