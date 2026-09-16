# Folders
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force -Name @args }
function l { Get-ChildItem @args }
function f { Get-ChildItem -Recurse -Filter $args[0] }

# Navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }
function home { Set-Location "$HOME" }
function exp { Invoke-Item . }

# Commands
function again { Invoke-History }

function mkcd {
    param($path)
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Set-Location $path
}

function list_files {
    param([string]$Path = '.')
    $base = (Resolve-Path $Path).Path
    Get-ChildItem -Path $base -Recurse -File | ForEach-Object {
        $_.FullName.Substring($base.Length).TrimStart('\', '/')
    }
}