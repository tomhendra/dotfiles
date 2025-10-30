#!/usr/bin/env bash

# Simple Resilient Installation Library - Pure Bash, No Python Dependencies
# Uses simple text files instead of JSON for maximum compatibility

# Configuration
readonly RESILIENT_STATE_DIR="${HOME}/.dotfiles_install_state"
readonly RESILIENT_STEPS_FILE="${RESILIENT_STATE_DIR}/steps.state"
readonly RESILIENT_METADATA_FILE="${RESILIENT_STATE_DIR}/metadata"
readonly RESILIENT_BACKUP_DIR="${RESILIENT_STATE_DIR}/backups"
readonly RESILIENT_LOG_FILE="${RESILIENT_STATE_DIR}/install.log"

# Retry configuration
readonly RESILIENT_MAX_RETRIES=3
readonly RESILIENT_RETRY_DELAY=2

# Colors (only if terminal supports them)
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    readonly RESILIENT_COLOR_RED='\033[0;31m'
    readonly RESILIENT_COLOR_GREEN='\033[0;32m'
    readonly RESILIENT_COLOR_YELLOW='\033[0;33m'
    readonly RESILIENT_COLOR_BLUE='\033[0;34m'
    readonly RESILIENT_COLOR_RESET='\033[0m'
else
    readonly RESILIENT_COLOR_RED=''
    readonly RESILIENT_COLOR_GREEN=''
    readonly RESILIENT_COLOR_YELLOW=''
    readonly RESILIENT_COLOR_BLUE=''
    readonly RESILIENT_COLOR_RESET=''
fi

# Initialize state directory and files
resilient_init() {
    mkdir -p "$RESILIENT_STATE_DIR" "$RESILIENT_BACKUP_DIR"

    # Create installation ID if it doesn't exist
    if [[ ! -f "${RESILIENT_STATE_DIR}/install_id" ]]; then
        resilient_generate_id > "${RESILIENT_STATE_DIR}/install_id"
    fi

    # Initialize metadata file
    if [[ ! -f "$RESILIENT_METADATA_FILE" ]]; then
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "STARTED_AT=$timestamp" > "$RESILIENT_METADATA_FILE"
        echo "LAST_UPDATED=$timestamp" >> "$RESILIENT_METADATA_FILE"
    fi

    # Initialize steps file
    touch "$RESILIENT_STEPS_FILE"
}

# Generate unique installation ID
resilient_generate_id() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        echo "install_$(date +%s)_$RANDOM"
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

# Save step state using simple text format
# Format: step_id:status:timestamp:attempts:duration
resilient_save_step() {
    local step_id="$1"
    local status="$2"
    local duration="${3:-0}"

    resilient_init

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local temp_file="${RESILIENT_STEPS_FILE}.tmp"

    # Update last updated time in metadata
    local temp_metadata="${RESILIENT_METADATA_FILE}.tmp"
    grep -v "^LAST_UPDATED=" "$RESILIENT_METADATA_FILE" > "$temp_metadata" 2>/dev/null || true
    echo "LAST_UPDATED=$timestamp" >> "$temp_metadata"
    mv "$temp_metadata" "$RESILIENT_METADATA_FILE"

    # Get current attempt count
    local attempts=1
    if grep -q "^${step_id}:" "$RESILIENT_STEPS_FILE" 2>/dev/null; then
        attempts=$(grep "^${step_id}:" "$RESILIENT_STEPS_FILE" | tail -1 | cut -d: -f4)
        attempts=$((attempts + 1))
    fi

    # Remove existing entries for this step and add new one
    grep -v "^${step_id}:" "$RESILIENT_STEPS_FILE" > "$temp_file" 2>/dev/null || true
    echo "${step_id}:${status}:${timestamp}:${attempts}:${duration}" >> "$temp_file"

    # Atomic move
    mv "$temp_file" "$RESILIENT_STEPS_FILE"
}

# Get step status
resilient_get_step_status() {
    local step_id="$1"

    if [[ ! -f "$RESILIENT_STEPS_FILE" ]]; then
        echo "not_started"
        return
    fi

    # Get the latest entry for this step
    local step_line=$(grep "^${step_id}:" "$RESILIENT_STEPS_FILE" | tail -1)

    if [[ -n "$step_line" ]]; then
        echo "$step_line" | cut -d: -f2
    else
        echo "not_started"
    fi
}

# Check if step is completed
resilient_is_completed() {
    local step_id="$1"
    local status=$(resilient_get_step_status "$step_id")
    [[ "$status" == "completed" ]]
}

# Get step attempts count
resilient_get_step_attempts() {
    local step_id="$1"

    if [[ ! -f "$RESILIENT_STEPS_FILE" ]]; then
        echo "0"
        return
    fi

    local step_line=$(grep "^${step_id}:" "$RESILIENT_STEPS_FILE" | tail -1)

    if [[ -n "$step_line" ]]; then
        echo "$step_line" | cut -d: -f4
    else
        echo "0"
    fi
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

        # Record backup in simple format
        echo "${filepath}:${backup_file}:${timestamp}" >> "${RESILIENT_STATE_DIR}/backups.list"

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

# Show progress summary
resilient_show_progress() {
    local steps=("$@")

    if [[ ! -f "$RESILIENT_STEPS_FILE" ]]; then
        echo "No installation state found"
        return
    fi

    echo
    echo "Installation Progress"
    echo "===================="

    local completed=0
    local failed=0
    local total=${#steps[@]}

    for step_id in "${steps[@]}"; do
        local status=$(resilient_get_step_status "$step_id")
        local attempts=$(resilient_get_step_attempts "$step_id")
        local symbol

        case "$status" in
            "completed")
                symbol="${RESILIENT_COLOR_GREEN}✓${RESILIENT_COLOR_RESET}"
                ((completed++))
                ;;
            "failed")
                symbol="${RESILIENT_COLOR_RED}✗${RESILIENT_COLOR_RESET}"
                ((failed++))
                ;;
            "in_progress")
                symbol="${RESILIENT_COLOR_YELLOW}⟳${RESILIENT_COLOR_RESET}"
                ;;
            *)
                symbol="${RESILIENT_COLOR_YELLOW}○${RESILIENT_COLOR_RESET}"
                ;;
        esac

        printf " %s %s" "$symbol" "$step_id"
        if [[ $attempts -gt 0 ]]; then
            printf " (attempts: %d)" "$attempts"
        fi
        echo
    done

    echo
    printf "Progress: %d/%d completed" "$completed" "$total"
    if [[ $failed -gt 0 ]]; then
        printf ", %d failed" "$failed"
    fi
    echo

    if [[ $total -gt 0 ]]; then
        local percentage=$((completed * 100 / total))
        printf "Success rate: %d%%\n" "$percentage"
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

    if [[ -d "$RESILIENT_STATE_DIR" ]]; then
        local backup_name="state_reset_$(date +%Y%m%d_%H%M%S)"
        local backup_dir="${RESILIENT_BACKUP_DIR}/${backup_name}"
        mkdir -p "$backup_dir"

        # Backup current state files
        for file in "$RESILIENT_STEPS_FILE" "$RESILIENT_METADATA_FILE" "${RESILIENT_STATE_DIR}/install_id"; do
            if [[ -f "$file" ]]; then
                cp "$file" "$backup_dir/"
            fi
        done

        resilient_log "INFO" "State backed up before reset: $backup_dir"
    fi

    # Remove state files but keep backups and logs
    rm -f "$RESILIENT_STEPS_FILE" "$RESILIENT_METADATA_FILE" "${RESILIENT_STATE_DIR}/install_id"

    resilient_init
    resilient_log "INFO" "Installation state reset"
}

# Get installation summary
resilient_summary() {
    if [[ ! -f "$RESILIENT_STEPS_FILE" ]]; then
        echo "No installation state found"
        return
    fi

    echo "Installation Summary:"

    # Count steps by status
    local total=$(wc -l < "$RESILIENT_STEPS_FILE" 2>/dev/null || echo "0")
    local completed=$(grep ":completed:" "$RESILIENT_STEPS_FILE" 2>/dev/null | wc -l || echo "0")
    local failed=$(grep ":failed:" "$RESILIENT_STEPS_FILE" 2>/dev/null | wc -l || echo "0")

    echo "  Total steps: $total"
    echo "  Completed: $completed"
    echo "  Failed: $failed"

    if [[ $total -gt 0 ]]; then
        local percentage=$((completed * 100 / total))
        echo "  Success rate: ${percentage}%"
    fi

    # Show metadata
    if [[ -f "$RESILIENT_METADATA_FILE" ]]; then
        local started_at=$(grep "^STARTED_AT=" "$RESILIENT_METADATA_FILE" 2>/dev/null | cut -d= -f2)
        local last_updated=$(grep "^LAST_UPDATED=" "$RESILIENT_METADATA_FILE" 2>/dev/null | cut -d= -f2)

        if [[ -n "$started_at" ]]; then
            echo "  Started: $started_at"
        fi
        if [[ -n "$last_updated" ]]; then
            echo "  Last updated: $last_updated"
        fi
    fi

    # Show installation ID
    if [[ -f "${RESILIENT_STATE_DIR}/install_id" ]]; then
        local install_id=$(cat "${RESILIENT_STATE_DIR}/install_id")
        echo "  Installation ID: $install_id"
    fi
}

# Export main functions
export -f resilient_init
export -f resilient_log
export -f resilient_execute_step
export -f resilient_backup_file
export -f resilient_is_completed
export -f resilient_show_progress
export -f resilient_summary
export -f resilient_reset
