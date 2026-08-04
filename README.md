# Configs PowerShell

Useful aliases and functions to boost your productivity in the terminal.

## 🚀 Setup

### Bash

Empty `.bash_aliases` if needed:
```sh
> ~/.bash_aliases
```

Install or Update:
```sh
bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/install.sh)
```

Uninstall:
```sh
bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/uninstall.sh)
```

### PowerShell

Empty `$PROFILE` if needed:
```ps1
$null > $PROFILE
```

Install or Update:
```sh
irm https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/install.ps1 | iex
```

Uninstall:
```sh
irm https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/uninstall.ps1 | iex
```
