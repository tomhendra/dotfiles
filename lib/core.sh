#!/usr/bin/env bash

# Core Resilient Installation Library
# Combines essential state management, execution, and logging in one clean file

# Configuration - use unique variable names to avoid conflicts
readonly RESILIENT_STATE_DIR="${HOME}/.dotfiles_install_state"
readonly RESILIENT_STATE_FILE="${RESILIENT_STATE_DIR}/state.json"
readonly RESILIENT_BACKUP_DIR="${RESILIENT_STATE_DIR}/backups"
readonly RESILIENT_LOG_FILE="${RESILIENT_STATE_DIR}/install.log"

# Retry configuration
readonly RESILIENT_MAX_RETRIES=3
readonly RESILIENT_RETRY_DELAY=2

# Colors (Rock.js style - subtle and minimal)
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    readonly RESILIENT_COLOR_RED='\033[0;31m'
    readonly RESILIENT_COLOR_GREEN='\033[0;32m'
    readonly RESILIENT_COLOR_YELLOW='\033[0;33m'
    readonly RESILIENT_COLOR_BLUE='\033[0;34m'
    readonly RESILIENT_COLOR_CYAN='\033[0;36m'
    readonly RESILIENT_COLOR_GRAY='\033[0;90m'
    readonly RESILIENT_COLOR_DIM='\033[2m'
    readonly RESILIENT_COLOR_RESET='\033[0m'
else
    readonly RESILIENT_COLOR_RED=''
    readonly RESILIENT_COLOR_GREEN=''
    readonly RESILIENT_COLOR_YELLOW=''
    readonly RESILIENT_COLOR_BLUE=''
    readonly RESILIENT_COLOR_CYAN=''
    readonly RESILIENT_COLOR_GRAY=''
    readonly RESILIENT_COLOR_DIM=''
    readonly RESILIENT_COLOR_RESET=''
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

# Logging function
resilient_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log to file
    echo "[$timestamp] $level: $message" >> "$RESILIENT_LOG_FILE"

    # Log to console with colors
    case "$level" in
        "ERROR")
            printf "${RESILIENT_COLOR_RED}[ERROR]${RESILIENT_COLOR_RESET} %s\n" "$message" >&2
            ;;
        "WARN")
            printf "${RESILIENT_COLOR_YELLOW}[WARN]${RESILIENT_COLOR_RESET} %s\n" "$message" >&2
            ;;
        "INFO")
            printf "${RESILIENT_COLOR_BLUE}[INFO]${RESILIENT_COLOR_RESET} %s\n" "$message"
            ;;
        "SUCCESS")
            printf "${RESILIENT_COLOR_GREEN}[SUCCESS]${RESILIENT_COLOR_RESET} %s\n" "$message"
            ;;
    esac
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

    # Use Python for reliable JSON manipulation
    python3 << EOF > "$temp_file"
import json
import sys

try:
    with open("$RESILIENT_STATE_FILE", "r") as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {"installation_id": "", "started_at": "", "last_updated": "", "steps": {}, "backups": {}}

# Set installation metadata
if not data.get("installation_id"):
    data["installation_id"] = "$(resilient_generate_id)"
if not data.get("started_at"):
    data["started_at"] = "$timestamp"
data["last_updated"] = "$timestamp"

# Update step
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

    # Atomic move
    if [[ -f "$temp_file" ]]; then
        mv "$temp_file" "$RESILIENT_STATE_FILE"
    else
        resilient_log "ERROR" "Failed to update state for step: $step_id"
        return 1
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

# Backup a file
resilient_backup_file() {
    local filepath="$1"
    local backup_name="${2:-$(basename "$filepath")}"

    if [[ ! -f "$filepath" ]]; then
        resilient_log "WARN" "File does not exist for backup: $filepath"
        return 1
    fi

    resilient_init

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${RESILIENT_BACKUP_DIR}/${backup_name}_${timestamp}"

    if cp "$filepath" "$backup_file"; then
        resilient_log "INFO" "Backed up: $filepath -> $backup_file"
        echo "$backup_file"
        return 0
    else
        resilient_log "ERROR" "Failed to backup: $filepath"
        return 1
    fi
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

# Execute step with retry logic
resilient_execute_step() {
    local step_id="$1"
    local step_function="$2"
    local step_description="${3:-$step_id}"

    # Show current step with Rock.js style
    resilient_show_current_step "$step_description" "Starting..."
    resilient_log "INFO" "Starting: $step_description"

    # Skip if already completed
    if resilient_is_completed "$step_id"; then
        resilient_log "INFO" "Skipping completed step: $step_id"
        return 0
    fi

    # Check if function exists
    if ! declare -f "$step_function" >/dev/null 2>&1; then
        resilient_log "ERROR" "Step function not found: $step_function"
        resilient_save_step "$step_id" "failed"
        return 1
    fi

    local start_time=$(date +%s)
    local attempt=1

    while [[ $attempt -le $RESILIENT_MAX_RETRIES ]]; do
        resilient_log "INFO" "Attempt $attempt/$RESILIENT_MAX_RETRIES: $step_description"

        # Execute the step function
        if "$step_function"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))

            resilient_log "SUCCESS" "Completed: $step_description (${duration}s)"
            resilient_save_step "$step_id" "completed" "$duration"
            return 0
        else
            local exit_code=$?
            resilient_log "WARN" "Step failed (attempt $attempt): $step_description"

            if [[ $attempt -lt $RESILIENT_MAX_RETRIES ]]; then
                resilient_log "INFO" "Retrying in ${RESILIENT_RETRY_DELAY}s..."
                sleep "$RESILIENT_RETRY_DELAY"
            fi
        fi

        ((attempt++))
    done

    # All attempts failed
    resilient_log "ERROR" "Step failed after $RESILIENT_MAX_RETRIES attempts: $step_description"
    resilient_save_step "$step_id" "failed"
    return 1
}

# Draw progress bar (Rock.js style)
resilient_draw_progress_bar() {
    local completed="$1"
    local total="$2"
    local width="${3:-40}"

    if [[ $total -eq 0 ]]; then
        printf "[%*s] 0%%" "$width" ""
        return
    fi

    local percentage=$((completed * 100 / total))
    local filled=$((completed * width / total))
    local empty=$((width - filled))

    printf "["

    # Filled portion (green)
    if [[ $filled -gt 0 ]]; then
        printf "${RESILIENT_COLOR_GREEN}%*s${RESILIENT_COLOR_RESET}" "$filled" "" | tr ' ' '█'
    fi

    # Empty portion (gray)
    if [[ $empty -gt 0 ]]; then
        printf "%*s" "$empty" "" | tr ' ' '░'
    fi

    printf "] ${RESILIENT_COLOR_BLUE}%3d%%${RESILIENT_COLOR_RESET}" "$percentage"
}

# Show spinner animation
resilient_spinner() {
    local pid="$1"
    local message="$2"
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    # Only show spinner if terminal supports it
    if [[ ! -t 1 ]]; then
        return
    fi

    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r${RESILIENT_COLOR_BLUE}%c${RESILIENT_COLOR_RESET} %s" "$spinstr" "$message"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done

    printf "\r%*s\r" $((${#message} + 3)) ""
}

# Show current step with Rock.js style formatting
resilient_show_current_step() {
    local step_description="$1"
    local operation="${2:-}"

    echo
    printf "${RESILIENT_COLOR_BLUE}▶${RESILIENT_COLOR_RESET} ${RESILIENT_COLOR_BLUE}%s${RESILIENT_COLOR_RESET}" "$step_description"

    if [[ -n "$operation" ]]; then
        printf " ${RESILIENT_COLOR_YELLOW}%s${RESILIENT_COLOR_RESET}" "$operation"
    fi
    echo
}

# Show progress summary (Rock.js inspired)
resilient_show_progress() {
    local steps=("$@")

    if [[ ! -f "$RESILIENT_STATE_FILE" ]]; then
        echo
        printf "${RESILIENT_COLOR_YELLOW}⚠${RESILIENT_COLOR_RESET}  No installation state found\n"
        return
    fi

    echo
    printf "${RESILIENT_COLOR_BLUE}📋 Installation Progress${RESILIENT_COLOR_RESET}\n"
    printf "${RESILIENT_COLOR_BLUE}========================${RESILIENT_COLOR_RESET}\n"

    local completed=0
    local failed=0
    local in_progress=0
    local total=${#steps[@]}

    # Count statuses and display steps
    for step_id in "${steps[@]}"; do
        local status=$(resilient_get_step_status "$step_id")
        local symbol
        local color

        case "$status" in
            "completed")
                symbol="✅"
                color="$RESILIENT_COLOR_GREEN"
                ((completed++))
                ;;
            "failed")
                symbol="❌"
                color="$RESILIENT_COLOR_RED"
                ((failed++))
                ;;
            "in_progress")
                symbol="🔄"
                color="$RESILIENT_COLOR_YELLOW"
                ((in_progress++))
                ;;
            *)
                symbol="⏸️ "
                color="$RESILIENT_COLOR_YELLOW"
                ;;
        esac

        printf " %s ${color}%s${RESILIENT_COLOR_RESET} [%s]\n" "$symbol" "$step_id" "${status^^}"
    done

    echo
    printf "${RESILIENT_COLOR_BLUE}Overall Progress:${RESILIENT_COLOR_RESET} "
    resilient_draw_progress_bar "$completed" "$total"
    printf " (%d/%d steps)\n" "$completed" "$total"

    echo
    printf "${RESILIENT_COLOR_BLUE}📊 Statistics:${RESILIENT_COLOR_RESET}\n"
    printf "  ${RESILIENT_COLOR_GREEN}✅ Completed: %d${RESILIENT_COLOR_RESET}  " "$completed"

    if [[ $failed -gt 0 ]]; then
        printf "${RESILIENT_COLOR_RED}❌ Failed: %d${RESILIENT_COLOR_RESET}  " "$failed"
    fi

    if [[ $in_progress -gt 0 ]]; then
        printf "${RESILIENT_COLOR_YELLOW}🔄 In Progress: %d${RESILIENT_COLOR_RESET}  " "$in_progress"
    fi

    local remaining=$((total - completed - failed - in_progress))
    if [[ $remaining -gt 0 ]]; then
        printf "${RESILIENT_COLOR_YELLOW}⏸️  Remaining: %d${RESILIENT_COLOR_RESET}" "$remaining"
    fi

    echo
    echo
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
        resilient_log "INFO" "State backed up before reset: $backup_name"
    fi

    rm -f "$RESILIENT_STATE_FILE"
    resilient_init
    resilient_log "INFO" "Installation state reset"
}

# Get installation summary
resilient_summary() {
    if [[ ! -f "$RESILIENT_STATE_FILE" ]]; then
        echo "No installation state found"
        return
    fi

    python3 -c "
import json
try:
    with open('$RESILIENT_STATE_FILE', 'r') as f:
        data = json.load(f)

    steps = data.get('steps', {})
    total = len(steps)
    completed = sum(1 for step in steps.values() if step.get('status') == 'completed')
    failed = sum(1 for step in steps.values() if step.get('status') == 'failed')

    print(f'Installation Summary:')
    print(f'  Total steps: {total}')
    print(f'  Completed: {completed}')
    print(f'  Failed: {failed}')
    print(f'  Success rate: {(completed/total*100):.1f}%' if total > 0 else '  Success rate: 0%')

    if data.get('started_at'):
        print(f'  Started: {data[\"started_at\"]}')
    if data.get('last_updated'):
        print(f'  Last updated: {data[\"last_updated\"]}')

except Exception as e:
    print(f'Error reading state: {e}')
"
}

# Export main functions
export -f resilient_init
export -f resilient_log
export -f resilient_execute_step
export -f resilient_backup_file
export -f resilient_is_completed
export -f resilient_show_progress
export -f resilient_show_current_step
export -f resilient_draw_progress_bar
export -f resilient_spinner
export -f resilient_summary
export -f resilient_reset
