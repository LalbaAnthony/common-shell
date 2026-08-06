# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias ipl='hostname -I' # Get local IP address
alias ipp='curl ifconfig.me && echo' # Get public IP address
alias ports='netstat -tulanp' # List all listening ports
alias randpass='openssl rand -base64 20'
alias nettop='sudo netstat -tulpen | sort -k3' # Show open TCP connections sorted
alias dnscheck='for d in 1.1.1.1 8.8.8.8 9.9.9.9; do ping -c2 $d; done' # Ping all DNS providers (Cloudflare, Google, Quad9)

killport() {
    if [ -z "$1" ]; then
        echo "Usage: killport <port_number>"
        return 1
    fi

    sudo lsof -t -i:"$1" | xargs sudo kill -9
}

nlighthouse() {
    if [ -z "$1" ]; then
        echo "Usage: nlighthouse <url>"
        return 1
    fi

    npm install -g lighthouse && lighthouse "$1"
}
