# Configs PowerShell

Useful aliases and functions to boost your productivity in the terminal.

## 🚀 Setup

### Bash

```sh
# Empty .bash_aliases if needed:
> ~/.bash_aliases
```

```sh
# Install or Update
bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/install.sh)

# Uninstall
bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/uninstall.sh)
```

### PowerShell

```ps1
# Empty $PROFILE if needed:
$null > $PROFILE
```

```powershell
# Install or Update
irm https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/install.ps1 | iex

# Uninstall
irm https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/uninstall.ps1 | iex
```

## 🔄 Migrate from an older version

### Bash

```sh
rm -f ~/.bashrc_extra # Remove the old bashrc_extra file
sed -i '0,/bashrc_extra/{/bashrc_extra/d;}' ~/.bashrc # Remove the old hook
bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/install.sh) # Brand new install
```

### PowerShell

```powershell
$ExtraFile = Join-Path $HOME "profile_extra.ps1" ; if (Test-Path $ExtraFile) { Remove-Item -Path $ExtraFile -Force } # Remove the old profile_extra.ps1 file
(Get-Content $PROFILE) -notmatch 'profile_extra.ps1' | Set-Content $PROFILE # Remove the old hook
irm https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/install.ps1 | iex # Brand new install
``` 

## 📂 Layout

Each profile lives as one file per section under `src/`. The installer downloads `manifest.txt`, then the parts it names, and concatenates them into the single file your shell sources — so your home directory still holds exactly one file per shell.

| Repo                                           | Installed to              |
| ---------------------------------------------- | ------------------------- |
| `src/bash/manifest.txt` + `src/bash/NNN-*.sh`  | `~/.bashrc_extra`         |
| `src/pwsh/manifest.txt` + `src/pwsh/NNN-*.ps1` | `$HOME/profile_extra.ps1` |

Part files are numbered `000-`, `010-`, … stepping by 10, so a directory listing reads in install order and a new section fits between two existing ones without renumbering.

Adding a section takes two edits: create the part file **and** list it in that directory's `manifest.txt`. The manifest sets the concatenation order, and an unlisted part is silently dropped from every install — CI fails the build if the two ever disagree.

Do not edit the installed `*_extra` file directly; the next `cshupd` overwrites it.
