#!/usr/bin/env bash

# Tomdot UI - simple CLI styling

if [[ -t 1 ]]; then
    C_CYAN='\033[36m'
    C_GREEN='\033[32m'
    C_RED='\033[31m'
    C_YELLOW='\033[33m'
    C_DIM='\033[2m'
    C_RESET='\033[0m'
else
    C_CYAN=''
    C_GREEN=''
    C_RED=''
    C_YELLOW=''
    C_DIM=''
    C_RESET=''
fi

_UI_HAS_DETAILS=false

ui_header() {
    clear
    local username
    username=$(whoami)
    echo
    printf "Hello %s, welcome to ${C_CYAN}tomdot${C_RESET}!\n" "$username"
    echo
}

ui_step_start() {
    _UI_HAS_DETAILS=false
    printf "${C_DIM}│${C_RESET}\n"
    printf "${C_CYAN}◇${C_RESET} %s...\n" "$1"
}

ui_step_skip() {
    printf "${C_DIM}│${C_RESET}\n"
    printf "${C_DIM}◇ %s (already done)${C_RESET}\n" "$1"
}

ui_step_ok() {
    if [[ "$_UI_HAS_DETAILS" == "true" ]]; then
        # Move up 2 lines (progress line + step line), clear both, reprint
        printf "\033[A\033[2K\033[A\033[2K${C_GREEN}◇${C_RESET} %s ${C_GREEN}✓${C_RESET}\n" "$1"
    else
        # Just overwrite the step line
        printf "\033[A\033[2K${C_GREEN}◇${C_RESET} %s ${C_GREEN}✓${C_RESET}\n" "$1"
    fi
}

ui_step_fail() {
    if [[ "$_UI_HAS_DETAILS" == "true" ]]; then
        printf "\033[A\033[2K\033[A\033[2K${C_RED}◇${C_RESET} %s ${C_RED}✗${C_RESET}\n" "$1"
    else
        printf "\033[A\033[2K${C_RED}◇${C_RESET} %s ${C_RED}✗${C_RESET}\n" "$1"
    fi
}

ui_step_dry() {
    printf "${C_DIM}│${C_RESET}\n"
    printf "${C_YELLOW}◇${C_RESET} %s ${C_DIM}(dry run)${C_RESET}\n" "$1"
}

ui_detail() {
    # Truncate to terminal width to prevent line wrapping (which breaks cursor-up)
    local cols
    cols=$(tput cols 2>/dev/null || echo 80)
    local prefix="│   "
    local max_text=$((cols - ${#prefix}))
    local text="$1"
    if [[ ${#text} -gt $max_text ]]; then
        text="${text:0:$((max_text - 1))}…"
    fi

    if [[ "$_UI_HAS_DETAILS" == "true" ]]; then
        printf "\033[A\033[2K${C_DIM}│${C_RESET}   %s\n" "$text"
    else
        _UI_HAS_DETAILS=true
        printf "${C_DIM}│${C_RESET}   %s\n" "$text"
    fi
}

ui_done() {
    printf "${C_DIM}│${C_RESET}\n"
    printf "${C_GREEN}◇${C_RESET} Installation complete ${C_GREEN}✓${C_RESET}\n"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        return 0
    fi

    echo
    echo "  Press Enter to reload your shell..."
    read -r
    exec zsh -l
}
