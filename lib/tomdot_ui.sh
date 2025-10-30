#!/usr/bin/env bash

# Tomdot UI Framework - Rock.js-inspired CLI styling
# Exact styling from simple_rock_demo.sh preserved

# Simple colors that work everywhere
if [[ -z "${C_CYAN:-}" ]]; then
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

    # Export for use in other scripts
    export C_CYAN C_GREEN C_RED C_YELLOW C_DIM C_RESET
fi

# Spinner state variables
TOMDOT_SPINNER_PID=""
TOMDOT_SPINNER_MESSAGE=""

# Start a section with diamond symbol and connecting line
ui_start_section() {
    local section_title="$1"
    printf "${C_DIM}◇${C_RESET} %s\n" "$section_title"
    printf "${C_DIM}│${C_RESET}\n"
}

# Show progress step with visual hierarchy
ui_progress_step() {
    local step_description="$1"
    local step_status="${2:-in_progress}"
    local add_connector="${3:-true}"

    case "$step_status" in
        "completed")
            printf "${C_GREEN}◇${C_RESET} %s\n" "$step_description"
            ;;
        "failed")
            printf "${C_RED}◇${C_RESET} %s ${C_DIM}(failed)${C_RESET}\n" "$step_description"
            ;;
        "in_progress")
            printf "${C_CYAN}◇${C_RESET} %s..." "$step_description"
            ;;
        *)
            printf "${C_DIM}◇ %s${C_RESET}\n" "$step_description"
            ;;
    esac

    [[ "$add_connector" == "true" ]] && printf "${C_DIM}│${C_RESET}\n"
}

# Animated spinner functions
ui_spinner_start() {
    local message="$1"
    TOMDOT_SPINNER_MESSAGE="$message"

    # Start spinner in background
    {
        local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        local i=0

        while true; do
            local char="${spinner_chars:$((i % ${#spinner_chars})):1}"
            printf "\r${C_CYAN}%s${C_RESET} %s" "$char" "$TOMDOT_SPINNER_MESSAGE"
            sleep 0.1
            ((i++))
        done
    } &

    TOMDOT_SPINNER_PID=$!
}

ui_spinner_stop() {
    local result="${1:-success}"

    if [[ -n "$TOMDOT_SPINNER_PID" ]]; then
        kill "$TOMDOT_SPINNER_PID" 2>/dev/null
        wait "$TOMDOT_SPINNER_PID" 2>/dev/null
        TOMDOT_SPINNER_PID=""
    fi

    case "$result" in
        "success")
            printf "\r${C_GREEN}◇${C_RESET} %s\n" "$TOMDOT_SPINNER_MESSAGE"
            ;;
        "failed")
            printf "\r${C_RED}◇${C_RESET} %s ${C_DIM}(failed)${C_RESET}\n" "$TOMDOT_SPINNER_MESSAGE"
            ;;
        *)
            printf "\r${C_DIM}◇ %s${C_RESET}\n" "$TOMDOT_SPINNER_MESSAGE"
            ;;
    esac

    printf "${C_DIM}│${C_RESET}\n"
    TOMDOT_SPINNER_MESSAGE=""
}

# Interactive question with Rock.js styling
ui_question() {
    local question="$1"
    local default_answer="${2:-}"

    printf "${C_DIM}◇${C_RESET} %s" "$question"
    if [[ -n "$default_answer" ]]; then
        printf " ${C_DIM}(%s)${C_RESET}"  "$default_answer"
    fi
    printf "\n${C_DIM}│${C_RESET} "

    local answer
    read -r answer
    printf "${C_DIM}│${C_RESET}\n"

    if [[ -z "$answer" && -n "$default_answer" ]]; then
        echo "$default_answer"
    else
        echo "$answer"
    fi
}

# Rock.js style bordered box for next steps
ui_bordered_box() {
    local title="$1"
    shift
    local lines=("$@")

    echo
    # Rock.js style box - simple and clean
    printf "${C_DIM}┌─ %s${C_RESET}\n" "$title"
    printf "${C_DIM}│${C_RESET}\n"

    for line in "${lines[@]}"; do
        printf "${C_DIM}│${C_RESET}  %s\n" "$line"
    done

    printf "${C_DIM}│${C_RESET}\n"
    printf "${C_DIM}└${C_RESET}\n"
}

# Show overall progress with Rock.js styling
ui_show_progress() {
    local steps=("$@")
    local completed=0
    local failed=0
    local total=${#steps[@]}

    # Count step statuses (this would integrate with state management)
    for step in "${steps[@]}"; do
        # This is a placeholder - actual implementation would check step status
        # from the state management system in tomdot_installer.sh
        case "$step" in
            *"completed"*) ((completed++)) ;;
            *"failed"*) ((failed++)) ;;
        esac
    done

    echo

    # Rock.js style completion message
    if [[ $completed -eq $total ]]; then
        printf "${C_GREEN}Success${C_RESET} 🎉\n"
    elif [[ $failed -gt 0 ]]; then
        printf "${C_YELLOW}Completed with errors${C_RESET} ${C_DIM}(%d/%d successful)${C_RESET}\n" "$completed" "$total"
    else
        printf "${C_CYAN}In progress${C_RESET} ${C_DIM}(%d/%d completed)${C_RESET}\n" "$completed" "$total"
    fi
}

# Welcome header for tomdot installation
ui_welcome_header() {
    clear
    echo
    printf "Welcome to ${C_CYAN}tomdot${C_RESET}!\n"
    echo
}

# Export main UI functions
export -f ui_start_section
export -f ui_progress_step
export -f ui_spinner_start
export -f ui_spinner_stop
export -f ui_question
export -f ui_bordered_box
export -f ui_show_progress
export -f ui_welcome_header
