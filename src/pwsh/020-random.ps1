# Folders
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force -Name @args }
function l { Get-ChildItem @args }
function f { Get-ChildItem -Recurse -Filter $args[0] } # Search for a file in the current directory

# Navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }
function home { Set-Location "$HOME" }

# Commands
function again { Invoke-History } # Repeat last command
function h { Get-History -Count 30 }

# Most frequently used commands
function hfreq {
    Get-History |
        ForEach-Object { ($_.CommandLine.Trim() -split '\s+')[0] } |
        Group-Object |
        Sort-Object Count -Descending |
        Select-Object -First 20 Count, Name
}

# System
function reload { . $PROFILE }

# Disk
function du20 { # Show top 20 largest files/folders in current directory
    Get-ChildItem -Force | ForEach-Object {
        if ($_.PSIsContainer) {
            $size = (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
        }
        else {
            $size = $_.Length
        }
        if ($null -eq $size) { $size = 0 }

        [PSCustomObject]@{
            Bytes = [long]$size
            Size  = '{0,10:N1} MB' -f ($size / 1MB)
            Name  = $_.Name
        }
    } | Sort-Object Bytes -Descending | Select-Object -First 20 Size, Name
}
function watchspace { # Monitor disk space every 5 seconds
    while ($true) {
        Clear-Host
        Get-PSDrive -PSProvider FileSystem |
            Where-Object { $null -ne $_.Used -or $null -ne $_.Free } |
            Format-Table -AutoSize Name,
                @{ Label = 'Used(GB)'; Expression = { '{0:N1}' -f ($_.Used / 1GB) } },
                @{ Label = 'Free(GB)'; Expression = { '{0:N1}' -f ($_.Free / 1GB) } },
                Root |
            Out-Host
        Start-Sleep -Seconds 5
    }
}

# Performance
function topcpu { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, Id, CPU, WS } # Top 10 CPU consumers
function topmem { Get-Process | Sort-Object WS -Descending | Select-Object -First 10 Name, Id, CPU, WS } # Top 10 RAM consumers

# Open the current directory in the file explorer
function exp { Invoke-Item . }

# Create a folder and cd into it
function mkcd {
    param($path)

    if (-not $path) {
        Write-Host "Usage: mkcd <folder>"
        return
    }

    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Set-Location $path
}

# Extract various archive types with a single command
function extractt {
    param($file)

    if (-not $file) {
        Write-Host "Usage: extractt <archive>"
        return
    }

    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        Write-Host "'$file' is not a valid file"
        return
    }

    # -Wildcard runs every matching branch, so each one breaks out explicitly:
    # '*.tar.gz' would otherwise fall through to '*.gz' as well.
    switch -Wildcard ($file) {
        '*.tar.bz2' { tar xjf $file; break }
        '*.tar.gz'  { tar xzf $file; break }
        '*.tar.xz'  { tar xJf $file; break }
        '*.tar.zst' { tar --zstd -xf $file; break }
        '*.tbz2'    { tar xjf $file; break }
        '*.tgz'     { tar xzf $file; break }
        '*.txz'     { tar xJf $file; break }
        '*.tar'     { tar xf $file; break }
        '*.zip'     { Expand-Archive -LiteralPath $file -DestinationPath . -Force; break }
        '*.rar'     { 7z x $file; break }
        '*.7z'      { 7z x $file; break }
        '*.gz'      { 7z x $file; break }
        '*.bz2'     { 7z x $file; break }
        '*.zst'     { 7z x $file; break }
        default     { Write-Host "'$file' is not handled by extractt()" }
    }
}

# Backup any folder quickly to timestamped tar
function backupp {
    param($path)

    if (-not $path) {
        Write-Host "Usage: backupp <file_or_folder>"
        return
    }

    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host "'$path' is not a valid file or folder"
        return
    }

    $name = (Get-Item -LiteralPath $path).Name
    tar -czf "${name}_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').tar.gz" $path
}

# Replace string in all files recursively
function rreplace {
    param($search, $replace)

    if (-not $search) {
        Write-Host "Usage: rreplace <search> <replace>"
        return
    }

    Get-ChildItem -Recurse -File | ForEach-Object {
        $content = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($null -ne $content -and $content -match $search) {
            ($content -replace $search, $replace) | Set-Content -LiteralPath $_.FullName -NoNewline
        }
    }
}

# List every file under a folder, as paths relative to it
function list_files {
    param([string]$Path = '.')

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Host "'$Path' is not a valid directory"
        return
    }

    $base = (Resolve-Path $Path).Path
    Get-ChildItem -Path $base -Recurse -File | ForEach-Object {
        $_.FullName.Substring($base.Length).TrimStart('\', '/')
    }
}
