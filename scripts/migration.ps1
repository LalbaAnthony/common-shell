if ($env:COMPUTERNAME -eq "AGO26L004") { # AGORA
    # Remove-Item "C:\Users\a.lalba\.ssh" -Recurse -Force -ErrorAction SilentlyContinue
    # Remove-Item "C:\Users\a.lalba\.claude" -Recurse -Force -ErrorAction SilentlyContinue
    # Remove-Item "C:\Users\a.lalba\projects" -Recurse -Force -ErrorAction SilentlyContinue
    # Remove-Item "C:\Users\a.lalba\Desktop\Projets" -Recurse -Force -ErrorAction SilentlyContinue
    # cshdel

    & C:\Users\a.lalba\projects\antho-scripts\anthropic\agora-claude-to-dev.ps1 # Copy local Claude config to remote dev machine

    # ...
} elseif ($env:COMPUTERNAME -eq "DESKTOP-OOQN3HB") { # DESKTOP
    Remove-Item "C:\Users\antho\projects\common-shell-migrations" -Recurse -Force -ErrorAction SilentlyContinue
    # ...
} elseif ($env:COMPUTERNAME -eq "ZENBOOK") { # LAPTOP
    Remove-Item "C:\Users\antho\projects\borreze-project" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Users\antho\projects\common-shell-migrations" -Recurse -Force -ErrorAction SilentlyContinue
    # ...
} else {
    # ...
}