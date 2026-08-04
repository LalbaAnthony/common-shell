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
