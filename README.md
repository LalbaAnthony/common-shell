# Configs PowerShell

Useful aliases and functions to boost your productivity in the terminal.

## 🚀 Setup

### Bash

Empty `.bash_aliases` if needed:
```sh
> ~/.bash_aliases
```

```sh
# Install or Update
bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/install.sh)

# Uninstall
bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/uninstall.sh)
```

### PowerShell

Empty `$PROFILE` if needed:
```ps1
$null > $PROFILE
```

```powershell
# Install or Update
irm https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/install.ps1 | iex

# Uninstall
irm https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/uninstall.ps1 | iex
```

## 🔄 Migrate from an older version

```sh
rm -f ~/.bashrc_extra # Remove the old bashrc_extra file
sed -i '0,/bashrc_extra/{/bashrc_extra/d;}' fichier.sh # Remove the old hook
bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/install.sh) # Brand new install
```

```powershell
$ExtraFile = Join-Path $HOME "profile_extra.ps1" ; if (Test-Path $ExtraFile) { Remove-Item -Path $ExtraFile -Force } # Remove the old profile_extra.ps1 file
(Get-Content $PROFILE) -notmatch 'profile_extra.ps1' | Set-Content $PROFILE # Remove the old hook
irm https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/install.ps1 | iex # Brand new install
``` 
