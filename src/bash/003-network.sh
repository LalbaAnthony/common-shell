# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias ipl='hostname -I' # Get local IP address
alias ipp='curl ifconfig.me && echo' # Get public IP address
alias ports='netstat -tulanp' # List all listening ports
alias randpass='openssl rand -base64 20' # Generate a random password
alias nettop='sudo netstat -tulpen | sort -k3' # Show open TCP connections sorted
alias dnscheck='for d in 1.1.1.1 8.8.8.8 9.9.9.9; do ping -c2 $d; done' # Ping all DNS providers (Cloudflare, Google, Quad9)

# Flush the local DNS cache of every caching resolver that is running
dnsflush() {
    local found=0 failed=0

    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        found=1
        if sudo resolvectl flush-caches; then
            echo "Flushed systemd-resolved cache"
        else
            echo "Failed to flush systemd-resolved cache"
            failed=1
        fi
    fi

    if systemctl is-active --quiet nscd 2>/dev/null; then
        found=1
        if sudo nscd --invalidate=hosts; then
            echo "Flushed nscd hosts cache"
        else
            echo "Failed to flush nscd hosts cache"
            failed=1
        fi
    fi

    if systemctl is-active --quiet dnsmasq 2>/dev/null; then
        found=1
        if sudo systemctl kill --signal=HUP dnsmasq; then # dnsmasq clears its cache on SIGHUP
            echo "Flushed dnsmasq cache"
        else
            echo "Failed to flush dnsmasq cache"
            failed=1
        fi
    fi

    if [ "$found" -eq 0 ]; then
        echo "No local DNS cache running (systemd-resolved, nscd, dnsmasq) - nothing to flush"
    fi

    return "$failed"
}

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

# Measure latency, download and upload against Cloudflare's speed test - one stream, at most 10 s per direction
speedcheck() {
    local base='https://speed.cloudflare.com'
    local bytes=99999999 # Largest payload the endpoint serves - 100000000 and up gets a 403
    local out rc payload

    # Five empty requests over one connection: first byte minus pre-transfer time is one round trip
    out=$(curl -fsS -w '%{time_starttransfer} %{time_pretransfer}\n' \
        "$base/__down?bytes=0" "$base/__down?bytes=0" "$base/__down?bytes=0" "$base/__down?bytes=0" "$base/__down?bytes=0") || {
        echo "Latency test failed"
        return 1
    }
    echo "$out" | awk '{ print ($1 - $2) * 1000 }' | LC_ALL=C sort -n |
        awk '{ v[NR] = $1 } END { printf "Latency:  %.1f ms\n", v[int((NR + 1) / 2)] }'

    # Rates exclude handshake time; curl exit 28 is the time limit, which ends the transfer below ~80 Mbps
    out=$(curl -fs -o /dev/null --max-time 10 -w '%{size_download} %{time_starttransfer} %{time_total}' "$base/__down?bytes=$bytes")
    rc=$?
    if [ "$rc" -ne 0 ] && [ "$rc" -ne 28 ]; then
        echo "Download test failed (curl exit $rc)"
        return 1
    fi
    echo "$out" | awk '{ d = $3 - $2; printf "Download: %.1f Mbps\n", (d > 0 ? $1 * 8 / d / 1e6 : 0) }'

    payload=$(mktemp) || {
        echo "Upload test failed: cannot create a temporary file"
        return 1
    }
    # Sparse file: sized without writing 100 MB to disk
    if ! dd if=/dev/zero of="$payload" bs=1 count=0 seek="$bytes" 2>/dev/null; then
        rm -f "$payload"
        echo "Upload test failed: cannot size the payload"
        return 1
    fi
    out=$(curl -fs -o /dev/null --max-time 10 -X POST -T "$payload" -w '%{size_upload} %{time_pretransfer} %{time_total}' "$base/__up")
    rc=$?
    rm -f "$payload"
    if [ "$rc" -ne 0 ] && [ "$rc" -ne 28 ]; then
        echo "Upload test failed (curl exit $rc)"
        return 1
    fi
    echo "$out" | awk '{ d = $3 - $2; printf "Upload:   %.1f Mbps\n", (d > 0 ? $1 * 8 / d / 1e6 : 0) }'
}
