# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

authlogs() {
    tail -f /var/log/auth.log
}
