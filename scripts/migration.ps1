if ($env:COMPUTERNAME -eq "AGO26L004") { # AGORA
    # Remove-Item "C:\Users\a.lalba\.ssh" -Recurse -Force -ErrorAction SilentlyContinue
    # Remove-Item "C:\Users\a.lalba\.claude" -Recurse -Force -ErrorAction SilentlyContinue
    # Remove-Item "C:\Users\a.lalba\projects" -Recurse -Force -ErrorAction SilentlyContinue
    # Remove-Item "C:\Users\a.lalba\Desktop\Projets" -Recurse -Force -ErrorAction SilentlyContinue
    # cshdel

    Remove-Item "C:\Users\a.lalba\projects\common-shell-migrations" -Recurse -Force -ErrorAction SilentlyContinue
    # ...
} elseif ($env:COMPUTERNAME -eq "DESKTOP-OOQN3HB") { # DESKTOP
    Remove-Item "C:\Users\antho\projects\common-shell-migrations" -Recurse -Force -ErrorAction SilentlyContinue
    # ...
} elseif ($env:COMPUTERNAME -eq "ZENBOOK") { # LAPTOP
    Remove-Item "C:\Users\antho\projects\common-shell-migrations" -Recurse -Force -ErrorAction SilentlyContinue
    # ...
}