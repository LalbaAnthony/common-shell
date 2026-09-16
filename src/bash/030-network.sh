# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias ipl='hostname -I' # Get local IP address
alias ipp='curl ifconfig.me && echo' # Get public IP address
alias ports='netstat -tulanp' # List all listening ports
alias randpass='openssl rand -base64 20' # Generate a random password
alias nettop='sudo netstat -tulpen | sort -k3' # Show open TCP connections sorted
alias dnscheck='for d in 1.1.1.1 8.8.8.8 9.9.9.9; do ping -c2 $d; done' # Ping all DNS providers (Cloudflare, Google, Quad9)

# Kill whatever holds a port, reporting each process by name
killport() {
    if [ -z "$1" ]; then
        echo "Usage: killport <port_number>"
        return 1
    fi

    local pids pid name
    pids=$(sudo lsof -t -i:"$1" 2>/dev/null | sort -u | grep -v -x "$$")

    if [ -z "$pids" ]; then
        echo "Nothing listening on port $1"
        return 0
    fi

    for pid in $pids; do
        name=$(ps -p "$pid" -o comm= 2>/dev/null)
        if sudo kill -9 "$pid" 2>/dev/null; then
            echo "Killed $name ($pid) on port $1"
        else
            echo "Failed to kill $name ($pid) - try an elevated shell"
        fi
    done
}

nlighthouse() {
    if [ -z "$1" ]; then
        echo "Usage: nlighthouse <url>"
        return 1
    fi

    npm install -g lighthouse >/dev/null || {
        echo "Failed to install lighthouse"
        return 1
    }

    lighthouse "$1"
}
