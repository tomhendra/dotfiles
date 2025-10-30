#!/usr/bin/env bash

# Rock.js Enhanced Style - with spinners, lines, and real-time updates
# Matches the exact aesthetic from Rock.js CLI

# Configuration
readonly RESILIENT_STATE_DIR="${HOME}/.dotfiles_install_state"
readonly RESILIENT_STATE_FILE="${RESILIENT_STATE_DIR}/state.json"
readonly RESILIENT_BACKUP_DIR="${RESILIENT_STATE_DIR}/backups"
readonly RESILIENT_LOG_FILE="${RESILIENT_STATE_DIR}/install.log"
readonly RESILIENT_MAX_RETRIES=3
readonly RESILIENT_RETRY_DELAY=2

# Rock.js colors - exactly matching the screenshots
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    readonly ROCK_COLOR_CYAN='\033[0;36m'      # For active spinners
    readonly ROCK_COLOR_GREEN='\033[0;32m'     # For completed steps
    readonly ROCK_COLOR_RED='\033[0;31m'       # For failed steps
    readonly ROCK_COLOR_YELLOW='\033[0;33m'    # For warnings
    readonly ROCK_COLOR_DIM='\033[2m'          # For muted text
    readonly ROCK_COLOR_PURPLE='\033[0;35m'    # For special states
    readonly ROCK_COLOR_RESET='\033[0m'
else
    readonly ROCK_COLOR_CYAN=''
    readonly ROCK_COLOR_GREEN=''
    readonly ROCK_COLOR_RED=''
    readonly ROCK_COLOR_YELLOW=''
    readonly ROCK_COLOR_DIM=''
    readonly ROCK_COLOR_PURPLE=''
    readonly ROCK_COLOR_RESET=''
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
    local test_urls=("https://github.com" "https://google.com")

    for url in "${test_urls[@]}"; do
        if curl -s --connect-timeout 5 --max-time 10 "$url" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

# Rock.js style spinner (exactly like the screenshots)
resilient_show_spinner() {
    local message="$1"
    local delay=0.08
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    while true; do
        local temp=${spinstr#?}
        printf "\r${ROCK_COLOR_PURPLE}%c${ROCK_COLOR_RESET} %s" "$spinstr" "$message"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
}

# Rock.js style step execution with real-time updates
resilient_execute_step() {
    local step_id="$1"
    local step_function="$2"
    local step_description="${3:-$step_id}"

    # Skip if already completed
    if resilient_is_completed "$step_id"; then
        printf "${ROCK_COLOR_DIM}◇ %s${ROCK_COLOR_RESET}\n" "$step_description"
        return 0
    fi

    # Check if function exists
    if ! declare -f "$step_function" >/dev/null 2>&1; then
        printf "${ROCK_COLOR_RED}◇ %s ${ROCK_COLOR_DIM}(function not found)${ROCK_COLOR_RESET}\n" "$step_description"
        resilient_save_step "$step_id" "failed"
        return 1
    fi

    local start_time=$(date +%s)
    local attempt=1

    while [[ $attempt -le $RESILIENT_MAX_RETRIES ]]; do
        # Show spinner during execution (Rock.js style)
        resilient_show_spinner "$step_description..." &
        local spinner_pid=$!

        # Execute the step function
        local step_output
        local exit_code=0

        step_output=$("$step_function" 2>&1) || exit_code=$?

        # Stop spinner
        kill $spinner_pid 2>/dev/null
        wait $spinner_pid 2>/dev/null

        if [[ $exit_code -eq 0 ]]; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))

            # Success - Rock.js style (replace spinner line)
            printf "\r${ROCK_COLOR_GREEN}◇${ROCK_COLOR_RESET} %s\n" "$step_description"
            resilient_save_step "$step_id" "completed" "$duration"
            return 0
        else
            if [[ $attempt -lt $RESILIENT_MAX_RETRIES ]]; then
                # Show retry (Rock.js style)
                printf "\r${ROCK_COLOR_YELLOW}◇${ROCK_COLOR_RESET} %s ${ROCK_COLOR_DIM}(retry %d/%d)${ROCK_COLOR_RESET}\n" "$step_description" "$attempt" "$RESILIENT_MAX_RETRIES"
                sleep "$RESILIENT_RETRY_DELAY"
            fi
        fi

        ((attempt++))
    done

    # All attempts failed
    printf "\r${ROCK_COLOR_RED}◇${ROCK_COLOR_RESET} %s ${ROCK_COLOR_DIM}(failed)${ROCK_COLOR_RESET}\n" "$step_description"
    resilient_save_step "$step_id" "failed"
    return 1
}

# Rock.js style bordered box (like "Next steps")
resilient_show_box() {
    local title="$1"
    shift
    local lines=("$@")

    echo
    printf "${ROCK_COLOR_DIM}┌─ %s${ROCK_COLOR_RESET}\n" "$title"
    printf "${ROCK_COLOR_DIM}│${ROCK_COLOR_RESET}\n"

    for line in "${lines[@]}"; do
        printf "${ROCK_COLOR_DIM}│${ROCK_COLOR_RESET}  %s\n" "$line"
    done

    printf "${ROCK_COLOR_DIM}│${ROCK_COLOR_RESET}\n"
    printf "${ROCK_COLOR_DIM}└${ROCK_COLOR_RESET}\n"
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
                printf "${ROCK_COLOR_GREEN}◇${ROCK_COLOR_RESET} %s\n" "$step_id"
                ((completed++))
                ;;
            "failed")
                printf "${ROCK_COLOR_RED}◇${ROCK_COLOR_RESET} %s\n" "$step_id"
                ((failed++))
                ;;
            *)
                printf "${ROCK_COLOR_DIM}◇ %s${ROCK_COLOR_RESET}\n" "$step_id"
                ;;
        esac
    done

    echo

    # Rock.js style completion message
    if [[ $completed -eq $total ]]; then
        printf "${ROCK_COLOR_GREEN}Success${ROCK_COLOR_RESET} ${ROCK_COLOR_DIM}🎉${ROCK_COLOR_RESET}.\n"
    elif [[ $failed -gt 0 ]]; then
        printf "${ROCK_COLOR_YELLOW}Completed with errors${ROCK_COLOR_RESET} ${ROCK_COLOR_DIM}(%d/%d successful)${ROCK_COLOR_RESET}.\n" "$completed" "$total"
    else
        printf "${ROCK_COLOR_CYAN}In progress${ROCK_COLOR_RESET} ${ROCK_COLOR_DIM}(%d/%d completed)${ROCK_COLOR_RESET}.\n" "$completed" "$total"
    fi
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
