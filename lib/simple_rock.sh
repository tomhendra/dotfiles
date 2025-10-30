#!/usr/bin/env bash

# Simple Rock.js Style CLI for Bash
# Clean, minimal, reliable - inspired by @clack/prompts

# Configuration
readonly RESILIENT_STATE_DIR="${HOME}/.dotfiles_install_state"
readonly RESILIENT_STATE_FILE="${RESILIENT_STATE_DIR}/state.json"
readonly RESILIENT_BACKUP_DIR="${RESILIENT_STATE_DIR}/backups"
readonly RESILIENT_LOG_FILE="${RESILIENT_STATE_DIR}/install.log"
readonly RESILIENT_MAX_RETRIES=3
readonly RESILIENT_RETRY_DELAY=2

# Simple colors that work everywhere
if [[ -t 1 ]]; then
    readonly C_CYAN='\033[36m'
    readonly C_GREEN='\033[32m'
    readonly C_RED='\033[31m'
    readonly C_YELLOW='\033[33m'
    readonly C_DIM='\033[2m'
    readonly C_RESET='\033[0m'
else
    readonly C_CYAN=''
    readonly C_GREEN=''
    readonly C_RED=''
    readonly C_YELLOW=''
    readonly C_DIM=''
    readonly C_RESET=''
fi

# Initialize state directory and files
resilient_init() {
    mkdir -p "$RESILIENT_STATE_DIR" "$RESILIENT_BACKUP_DIR"

    if [[ ! -f "$RESILIENT_STATE_FILE" ]]; then
        cat > "$RESILIENT_STATE_FILE" << 'EOF'
{
  "installation_id": "",
  "started_at": "",
  "last_updated": "",
  "steps": {},
  "backups": {}
}
EOF
    fi
}

# Generate unique installation ID
resilient_generate_id() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        echo "install_$(date +%s)_$RANDOM"
    fi
}

# Save step state
resilient_save_step() {
    local step_id="$1"
    local status="$2"
    local duration="${3:-0}"

    resilient_init

    local temp_file="${RESILIENT_STATE_FILE}.tmp"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    python3 << EOF > "$temp_file"
import json
import sys

try:
    with open("$RESILIENT_STATE_FILE", "r") as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {"installation_id": "", "started_at": "", "last_updated": "", "steps": {}, "backups": {}}

if not data.get("installation_id"):
    data["installation_id"] = "$(resilient_generate_id)"
if not data.get("started_at"):
    data["started_at"] = "$timestamp"
data["last_updated"] = "$timestamp"

if "steps" not in data:
    data["steps"] = {}
if "$step_id" not in data["steps"]:
    data["steps"]["$step_id"] = {"attempts": 0}

data["steps"]["$step_id"]["status"] = "$status"
data["steps"]["$step_id"]["completed_at"] = "$timestamp"
data["steps"]["$step_id"]["attempts"] = data["steps"]["$step_id"].get("attempts", 0) + 1
if $duration > 0:
    data["steps"]["$step_id"]["duration"] = $duration

print(json.dumps(data, indent=2))
EOF

    if [[ -f "$temp_file" ]]; then
        mv "$temp_file" "$RESILIENT_STATE_FILE"
    fi
}

# Get step status
resilient_get_step_status() {
    local step_id="$1"

    if [[ ! -f "$RESILIENT_STATE_FILE" ]]; then
        echo "not_started"
        return
    fi

    python3 -c "
import json
try:
    with open('$RESILIENT_STATE_FILE', 'r') as f:
        data = json.load(f)
    step = data.get('steps', {}).get('$step_id', {})
    print(step.get('status', 'not_started'))
except:
    print('not_started')
"
}

# Check if step is completed
resilient_is_completed() {
    local step_id="$1"
    local status=$(resilient_get_step_status "$step_id")
    [[ "$status" == "completed" ]]
}

# Check if command exists
resilient_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check network connectivity
resilient_check_network() {
    curl -s --connect-timeout 5 --max-time 10 "https://github.com" >/dev/null 2>&1
}

# Simple, reliable step execution (Rock.js style)
resilient_execute_step() {
    local step_id="$1"
    local step_function="$2"
    local step_description="${3:-$step_id}"

    # Skip if already completed
    if resilient_is_completed "$step_id"; then
        printf "${C_DIM}◇ %s${C_RESET}\n" "$step_description"
        return 0
    fi

    # Check if function exists
    if ! declare -f "$step_function" >/dev/null 2>&1; then
        printf "${C_RED}◇ %s ${C_DIM}(function not found)${C_RESET}\n" "$step_description"
        resilient_save_step "$step_id" "failed"
        return 1
    fi

    local start_time=$(date +%s)
    local attempt=1

    while [[ $attempt -le $RESILIENT_MAX_RETRIES ]]; do
        # Show step in progress (simple, no spinner)
        printf "${C_CYAN}◇${C_RESET} %s..." "$step_description"

        # Execute the step function
        local step_output
        local exit_code=0

        step_output=$("$step_function" 2>&1) || exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))

            # Success - clear line and show success
            printf "\r${C_GREEN}◇${C_RESET} %s\n" "$step_description"
            resilient_save_step "$step_id" "completed" "$duration"
            return 0
        else
            if [[ $attempt -lt $RESILIENT_MAX_RETRIES ]]; then
                # Show retry
                printf "\r${C_YELLOW}◇${C_RESET} %s ${C_DIM}(retry %d/%d)${C_RESET}\n" "$step_description" "$attempt" "$RESILIENT_MAX_RETRIES"
                sleep "$RESILIENT_RETRY_DELAY"
            fi
        fi

        ((attempt++))
    done

    # All attempts failed
    printf "\r${C_RED}◇${C_RESET} %s ${C_DIM}(failed)${C_RESET}\n" "$step_description"
    resilient_save_step "$step_id" "failed"
    return 1
}

# Rock.js style progress display
resilient_show_progress() {
    local steps=("$@")

    if [[ ! -f "$RESILIENT_STATE_FILE" ]]; then
        return
    fi

    echo

    local completed=0
    local failed=0
    local total=${#steps[@]}

    # Show each step with Rock.js style
    for step_id in "${steps[@]}"; do
        local status=$(resilient_get_step_status "$step_id")

        case "$status" in
            "completed")
                printf "${C_GREEN}◇${C_RESET} %s\n" "$step_id"
                ((completed++))
                ;;
            "failed")
                printf "${C_RED}◇${C_RESET} %s\n" "$step_id"
                ((failed++))
                ;;
            *)
                printf "${C_DIM}◇ %s${C_RESET}\n" "$step_id"
                ;;
        esac
    done

    echo

    # Rock.js style completion message
    if [[ $completed -eq $total ]]; then
        printf "${C_GREEN}Success${C_RESET} 🎉.\n"
    elif [[ $failed -gt 0 ]]; then
        printf "${C_YELLOW}Completed with errors${C_RESET} ${C_DIM}(%d/%d successful)${C_RESET}.\n" "$completed" "$total"
    else
        printf "${C_CYAN}In progress${C_RESET} ${C_DIM}(%d/%d completed)${C_RESET}.\n" "$completed" "$total"
    fi
}

# Rock.js style bordered box
resilient_show_box() {
    local title="$1"
    shift
    local lines=("$@")

    echo
    printf "${C_DIM}┌─ %s${C_RESET}\n" "$title"
    printf "${C_DIM}│${C_RESET}\n"

    for line in "${lines[@]}"; do
        printf "${C_DIM}│${C_RESET}  %s\n" "$line"
    done

    printf "${C_DIM}│${C_RESET}\n"
    printf "${C_DIM}└${C_RESET}\n"
}

# Backup a file
resilient_backup_file() {
    local filepath="$1"
    local backup_name="${2:-$(basename "$filepath")}"

    if [[ ! -f "$filepath" ]]; then
        return 1
    fi

    resilient_init

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${RESILIENT_BACKUP_DIR}/${backup_name}_${timestamp}"

    if cp "$filepath" "$backup_file"; then
        echo "$backup_file"
        return 0
    else
        return 1
    fi
}

# Reset installation state
resilient_reset() {
    local confirm="${1:-}"

    if [[ "$confirm" != "--force" ]]; then
        echo "This will reset all installation progress."
        echo "Use 'resilient_reset --force' to confirm."
        return 1
    fi

    if [[ -f "$RESILIENT_STATE_FILE" ]]; then
        local backup_name="state_reset_$(date +%Y%m%d_%H%M%S).json"
        cp "$RESILIENT_STATE_FILE" "${RESILIENT_BACKUP_DIR}/${backup_name}"
    fi

    rm -f "$RESILIENT_STATE_FILE"
    resilient_init
}

# Export main functions
export -f resilient_init
export -f resilient_execute_step
export -f resilient_backup_file
export -f resilient_is_completed
export -f resilient_show_progress
export -f resilient_show_box
export -f resilient_reset
