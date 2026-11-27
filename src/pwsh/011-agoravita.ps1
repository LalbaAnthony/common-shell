#  -------- Ample --------

# Run a command in every CRIJ site: `crij git status -sb`, or `crij { git pull; composer install }`
function crij {
    if ($args.Count -eq 0) {
        Write-Host "Usage: crij <command> [args...]"
        return
    }

    # Not `$command, $commandArgs = $args`: a one-word command would splat a positional $null
    $command = $args[0]
    $commandArgs = @($args | Select-Object -Skip 1)
    $root = Join-Path $HOME 'Desktop\Projets\Ample\CRIJ'

    foreach ($site in 'auch', 'aveyron', 'herault', 'occitanie', 'po', 'tarn', 'tarn-et-garonne') {
        $dir = Join-Path $root "crij-$site"
        Write-Host "=== crij-$site ==="

        $ok = $false
        if (Test-Path -LiteralPath $dir -PathType Container) {
            Push-Location -LiteralPath $dir
            try {
                # Cmdlets and functions never set LASTEXITCODE, so a stale value would read as a failure
                $global:LASTEXITCODE = 0
                & $command @commandArgs
                $ok = $? -and $LASTEXITCODE -eq 0
            }
            catch {
                # Unknown command, or a terminating error thrown by the command itself
                Write-Host $_.Exception.Message
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Host "No such directory: $dir"
        }

        if (-not $ok) { Write-Host "ERREUR dans $dir" }
    }
}

#  -------- Kronos --------

function 3M {
    if ($args.Count -eq 0) {
        Write-Host "Usage: 3M <command> [args...]"
        return
    }

    # Not `$command, $commandArgs = $args`: a one-word command would splat a positional $null
    $command = $args[0]
    $commandArgs = @($args | Select-Object -Skip 1)
    $root = Join-Path $HOME 'Desktop\Projets\Kronos\3M'

    foreach ($site in 'mousses', 'mousquetons') {
        $dir = Join-Path $root "3-$site"
        Write-Host "=== 3-$site ==="

        $ok = $false
        if (Test-Path -LiteralPath $dir -PathType Container) {
            Push-Location -LiteralPath $dir
            try {
                # Cmdlets and functions never set LASTEXITCODE, so a stale value would read as a failure
                $global:LASTEXITCODE = 0
                & $command @commandArgs
                $ok = $? -and $LASTEXITCODE -eq 0
            }
            catch {
                # Unknown command, or a terminating error thrown by the command itself
                Write-Host $_.Exception.Message
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Host "No such directory: $dir"
        }

        if (-not $ok) { Write-Host "ERREUR dans $dir" }
    }
}

#  -------- Common --------

# Relay a directory between two hosts through this machine: pull <src> into a local staging dir, then push it to <dst>
#   rrelay [-p src_port] [-P dst_port] [-t staging_dir] <src> <dst> [rsync args...]
#   rrelay -p 2222 old@host-a:/var/www/site/uploads new@host-b:/var/www/site/uploads --exclude=cache/
# The contents of <src> land in <dst>, trailing slash or not. Extra arguments go to both legs (--exclude, --delete...).
# The push drops ownership and sets dirs 775 / files 664; a --chmod in the extra arguments is applied after that.
# Before the pull, a dry run sizes it and stops when the staging dir's volume lacks the room.
# A staging dir created here is removed on success and kept on failure; `-t <dir>` reruns incrementally from it.
# A dir given with -t is never removed.
# Needs an rsync.exe on PATH and an ssh in its runtime's /usr/bin (MSYS2: `pacman -S rsync openssh`), or $env:RSYNC_RSH.
# That ssh reads ~/.ssh in MSYS2's home: `db_home: windows` in MSYS2's /etc/nsswitch.conf makes it %USERPROFILE%.
# rsync reads the colon of C:\ as a host separator, so it runs from inside the staging dir and only ever sees it as ./
# - which is also why <src> and <dst> must both be remote.
function rrelay {
    $usage = 'Usage: rrelay [-p src_port] [-P dst_port] [-t staging_dir] <src> <dst> [rsync args...]'
    $argv = @($args)
    $srcPort = ''
    $dstPort = ''
    $tmp = ''
    $ownTmp = $true

    # Parsed by hand, as getopts would: parameter names are case-insensitive, so -p and -P cannot both be declared
    $i = 0
    while ($i -lt $argv.Count -and "$($argv[$i])" -like '-?*') {
        $opt = [string]$argv[$i]
        if (($opt -cnotin '-p', '-P', '-t') -or ($i + 1 -ge $argv.Count)) {
            Write-Host $usage
            return
        }
        switch -CaseSensitive ($opt) {
            '-p' { $srcPort = [string]$argv[$i + 1] }
            '-P' { $dstPort = [string]$argv[$i + 1] }
            '-t' { $tmp = [string]$argv[$i + 1]; $ownTmp = $false }
        }
        $i += 2
    }

    if ($argv.Count - $i -lt 2) {
        Write-Host $usage
        return
    }
    $src = [string]$argv[$i]
    $dst = [string]$argv[$i + 1]
    $rsyncArgs = @()
    if ($argv.Count -gt $i + 2) { $rsyncArgs = $argv[($i + 2)..($argv.Count - 1)] }

    foreach ($port in $srcPort, $dstPort) {
        if ($port -and $port -notmatch '^[0-9]+$') {
            Write-Host "Invalid port: $port"
            return
        }
    }
    foreach ($spec in $src, $dst) {
        if ($spec -notlike '*:*' -or $spec -match '^[A-Za-z]:([\\/]|$)') {
            Write-Host "Not a remote path: $spec (expected [user@]host:path)"
            return
        }
    }
    if (-not (Get-Command rsync -ErrorAction SilentlyContinue)) {
        Write-Host 'rsync not found'
        return
    }

    # Relay the contents, never the directory itself; a bare `host:` (remote home) is left alone
    if ($src -notmatch '[/:]$') { $src += '/' }
    if ($dst -notmatch '[/:]$') { $dst += '/' }

    # Not the Windows OpenSSH client that `ssh` resolves to: an MSYS2 rsync cannot get a byte through it (code 12,
    # 0 bytes received). The ssh of rsync's own runtime works; $env:RSYNC_RSH overrides it, as it does for rsync itself.
    # No port option unless one is given, so the ssh config still applies
    $ssh = '/usr/bin/ssh'
    if ($env:RSYNC_RSH) { $ssh = $env:RSYNC_RSH }
    $pullSsh = $ssh
    $pushSsh = $ssh
    if ($srcPort) { $pullSsh += " -p $srcPort" }
    if ($dstPort) { $pushSsh += " -p $dstPort" }

    # Under $HOME, as in the Bash version. A failed Push-Location must stop here: rsync would then pull into,
    # and push from, whatever directory the caller is in
    try {
        if ($ownTmp) {
            $tmp = Join-Path $HOME ('rrelay.' + [System.IO.Path]::GetRandomFileName().Replace('.', ''))
        }
        else {
            $tmp = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($tmp)
        }
        $null = [System.IO.Directory]::CreateDirectory($tmp)
        Push-Location -LiteralPath $tmp -ErrorAction Stop
    }
    catch {
        Write-Host "Cannot use staging dir ${tmp}: $($_.Exception.Message)"
        return
    }

    $formatSize = {
        param([double]$bytes)
        $units = 'B', 'KiB', 'MiB', 'GiB', 'TiB'
        $u = 0
        while ($bytes -ge 1024 -and $u -lt $units.Count - 1) { $bytes /= 1024; $u++ }
        '{0:F1} {1}' -f $bytes, $units[$u]
    }

    $rc = 0
    $enoughRoom = $true
    $staged = $false
    try {
        # Room check, before anything is staged. A dry-run pull sizes exactly what the pull will write here: the extra
        # arguments (--exclude...) apply, and what a -t dir already holds is not counted again. A du of <src> would see
        # neither, and would need the transport (port, ssh, host::module) rebuilt by hand
        Write-Host "=== Room check: $src -> $tmp ==="
        $stats = rsync -an --stats --no-human-readable -e $pullSsh @rsyncArgs $src ./
        $rc = $LASTEXITCODE
        if ($rc -eq 0) {
            $need = $null
            $created = 0
            foreach ($line in $stats) {
                if ($line -match '^Total transferred file size: ([0-9.,]+) bytes') {
                    $need = [long]($Matches[1] -replace '[.,]', '')
                }
                elseif ($line -match '^Number of created files: ([0-9.,]+)') {
                    $created = [long]($Matches[1] -replace '[.,]', '')
                }
            }
            $avail = $null
            try {
                # The volume of the path's root: a volume mounted in a folder is not seen, a UNC path throws
                $avail = (New-Object System.IO.DriveInfo ([System.IO.Path]::GetPathRoot($tmp))).AvailableFreeSpace
            }
            catch {
                Write-Host "Cannot read the free space of ${tmp}: $($_.Exception.Message)"
            }

            if ($null -ne $need -and $null -ne $avail) {
                # Bytes alone undercount many small files (thumbnails): add up to one 4 KiB block per created file or dir
                $need += $created * 4096
                $room = '{0} needed, {1} free' -f (& $formatSize $need), (& $formatSize $avail)
                if ($need -gt $avail) {
                    Write-Host "Not enough room in ${tmp}: $room. Free some space, or stage elsewhere with -t <dir>"
                    $enoughRoom = $false
                }
                else {
                    Write-Host $room
                }
            }
            else {
                Write-Host "Room not checked: cannot read the dry-run size or the free space of $tmp"
            }
        }

        if ($rc -eq 0 -and $enoughRoom) {
            $staged = $true
            # Pull: no remote owner, and owner-only rw modes. Staged files (wp-config.php...) stay private to this user, and
            # a read-only remote mode cannot become an NTFS read-only attribute that blocks the cleanup. The push resets
            # every bit
            Write-Host "=== Pull: $src -> $tmp ==="
            rsync -avz --info=progress2 --no-owner --no-group '--chmod=u+rwX,go-rwx' -e $pullSsh @rsyncArgs $src ./
            $rc = $LASTEXITCODE
        }

        if ($rc -eq 0 -and $staged) {
            Write-Host "=== Push: $tmp -> $dst ==="
            rsync -avz --info=progress2 -e $pushSsh --no-owner --no-group '--chmod=Dug=rwx,Do=rx,Fug=rw,Fo=r' @rsyncArgs ./ $dst
            $rc = $LASTEXITCODE
        }
    }
    finally {
        Pop-Location
    }

    if (-not $staged) {
        if ($rc -ne 0) { Write-Host "rrelay failed (dry-run rsync exit $rc)" }
        if ($ownTmp) {
            try {
                # Non-recursive: nothing was staged, and a dir that is not empty after all must stay
                [System.IO.Directory]::Delete($tmp, $false)
            }
            catch {
                Write-Host "Cannot remove the empty staging dir ${tmp}: $($_.Exception.Message)"
            }
        }
        return
    }
    if ($rc -ne 0) {
        Write-Host "rrelay failed (rsync exit $rc). Staging kept: $tmp (rerun with -t $tmp)"
        return
    }
    if (-not $ownTmp) {
        Write-Host "Done. Staging kept: $tmp"
        return
    }
    try {
        # Not Remove-Item: under 5.1, -Recurse follows a directory symlink and empties its target
        [System.IO.Directory]::Delete($tmp, $true)
    }
    catch {
        Write-Host "Relayed, but the staging dir could not be removed: $tmp ($($_.Exception.Message))"
        return
    }
    Write-Host 'Done.'
}
