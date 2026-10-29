#!/bin/bash

if [ "$HOSTNAME" = "SRV-DEV-ROSE-04" ]; then # AGORA
    # rm -rf ~/.ssh
    # rm -rf ~/.claude
    # rm -rf /var/www/html
    # bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/uninstall.sh)
    :
elif [ "$HOSTNAME" = "vps-33aa7a06" ]; then # BRZ
    :
elif [ "$HOSTNAME" = "srv700069" ]; then # PERSO
    :
elif [ "$HOSTNAME" = "raspberrypi" ]; then # RASPBERRYPI
    :
elif [ "$HOSTNAME" = "debian" ]; then # DEBIAN LAPTOP
    :
else
    # If the computer is not recognized, uninstall common-shell to avoid potential issues
    # Same call as cshdel but without relying on the alias
    bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/uninstall.sh)
fi
