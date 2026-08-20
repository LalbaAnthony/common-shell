# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

# Folders
alias ll='ls -lah --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias f='find . -name' # Search for a file in the current directory

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias www='cd /var/www'
alias html='cd /var/www/html'
alias home='cd ~'

# Commands
alias cls='clear'
alias please='sudo'
alias plz='sudo'
alias pleasefuck='sudo $(fc -ln -1)' # Repeat last command with sudo, works even if last command had arguments
alias plzfuck='sudo $(fc -ln -1)'
alias fuck='fc -e nano' # Edit last command in nano
alias again='fc -s' # Repeat last command
alias h='history | tail -n 30'
alias hfreq='history | awk "{print \$2}" | sort | uniq -c | sort -nr | head -n 20' # Most frequently used commands

# Random
alias weather='curl wttr.in' # Get weather for current location
alias hxy='npx @lalba-anthony/hexasky "Toulouse"'

# Bash
alias shp='echo "Profile file: ~/.bashrc"'

# System
alias syslog='tail -n 1000 /var/log/syslog'
alias reload='source ~/.bashrc'
alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && echo "System updated"'
alias jlog='sudo journalctl -xe' # Recent system errors

# Disk
alias du20='du -ah . | sort -rh | head -n 20' # Show top 20 largest files/folders in current directory
alias watchspace='watch -n5 "df -hT | grep -E \"Filesystem|/dev/\""' # Monitor disk space every 5 seconds

# Performance
alias topcpu='ps aux --sort=-%cpu | head -n 11' # Top 10 CPU consumers
alias topmem='ps aux --sort=-%mem | head -n 11' # Top 10 RAM consumers

# Create a folder and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

# Extract various archive types with a single command
extractt() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.dmg)       hdiutil mount "$1" ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.ZIP)       unzip "$1"      ;;
            *.rar)       unrar x "$1"    ;;
            *.RAR)       unrar x "$1"    ;;
            *.7z)        7z x "$1"       ;;
            *.tar.xz)    tar xJf "$1"    ;;
            *.txz)       tar xJf "$1"    ;;
            *.tar.zst)   tar --zstd -xf "$1" ;;
            *.zst)       unzstd "$1"     ;;
            *)           echo "'$1' is not handled by extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Backup any folder quickly to timestamped tar
backupp() {
    tar -czf "$1_$(date +%F_%H-%M-%S).tar.gz" "$1";
}

# Replace string in all files recursively
rreplace() {
    grep -rl "$1" . | xargs sed -i "s/$1/$2/g";
}

# Compare two dirs visually
diffd() {
    diff -qr "$1" "$2" | less;
}

# Reload or restart a systemd service with one command
reloadd() {
    if [ -z "$1" ]; then
        echo "Usage: reloadd <file_or_folder>"
        return 1
    fi

    sudo systemctl reload "$1" || sudo systemctl restart "$1" || echo "Failed to reload or restart $1"
}
