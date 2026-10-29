#!/bin/bash

if [ "$HOSTNAME" = "SRV-DEV-ROSE-04" ]; then # AGORA
    # rm -rf ~/.ssh
    # rm -rf ~/.claude
    # rm -rf /var/www/html
    # cshdel
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
    :
fi
