# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

# =================================================================================
# Python
# =================================================================================

pysetup() {
    python -m venv .venv
    . .venv/bin/activate
    pip install -r requirements.txt
}
