# This fragment is concatenated into ~/.bashrc_extra, which is sourced from
# ~/.bashrc, so it carries no shebang.
# shellcheck shell=bash
#
# File-wide ShellCheck exemptions, all specific to an interactive profile:
#   SC1091 - sourced paths (e.g. .venv/bin/activate) only exist at runtime.
#   SC2034 - colour variables are consumed by PS1 and by interactive use.
#   SC2142 - `$2` inside single-quoted awk programs is an awk field, not an arg.
#   SC2154 - variables in single-quoted alias bodies are expanded by the subshell.
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

# =================================================================================
# Linux config
# =================================================================================

RED='\[\e[31m\]'
GREEN='\[\e[32m\]'
YELLOW='\[\e[33m\]'
BLUE='\[\e[34m\]'
MAGENTA='\[\e[35m\]'
CYAN='\[\e[36m\]'
WHITE='\[\e[97m\]'
GRAY='\[\e[90m\]'
RESET='\[\e[0m\]'

# Theme
export PS1="\$([ \"\$(id -u)\" = \"0\" ] && echo \"${RED}\" || echo \"${CYAN}\")\u${WHITE}@${GREEN}\h${RESET}:${YELLOW}\w\$(branch=\$(git branch 2>/dev/null | grep '^*' | colrm 1 2); [ -n \"\$branch\" ] && echo \"${GRAY} (\$branch)${RESET}\")${RESET} \$ "

# History
export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTIGNORE="&:ls:cd:cd -:pwd:exit:clear"
shopt -s histappend
