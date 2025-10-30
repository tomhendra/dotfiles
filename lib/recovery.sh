#!/usr/bin/env bash

# Recovery and Rollback System for Resilient Installation
# Provides automatic rollback for critical failures and manual rollback functionality

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/state.sh"

# Configuration
readonly ROLLBACK_TIMEOUT=60
readonly BACKUP_RETENTION_DAYS=30

# Log levels for recovery operations
readonly RECOVERY_ERROR=1
readonly RECOVERY_WARN=2
readonly RECOVERY_INFO=3
readonly RECOVERY_DEBUG=4

# Current recovery log level
RECOVERY_LOG_LEVEL=${RECOVERY_LOG_LEVEL:-$RECOVERY_INFO}

# Recovery logging function
recovery_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ $level -le $RECOVERY_LOG_LEVEL ]]; then
        case $level in
            $RECOVERY_ERROR) echo "[$timestamp] RECOVERY ERROR: $message" >&2 ;;
            $RECOVERY_WARN)  echo "[$timestamp] RECOVERY WARN:  $message" >&2 ;;
            $RECOVERY_INFO)  echo "[$timestamp] RECOVERY INFO:  $message" ;;
            $RECOVERY_DEBUG) echo "[$timestamp] RECOVERY DEBUG: $message" ;;
        esac
    fi

    # Always log to file if state directory exists
    if [[ -d "$STATE_DIR" ]]; then
        local level_name
        case $level in
            $RECOVERY_ERROR) level_name="RECOVERY_ERROR" ;;
            $RECOVERY_WARN)  level_name="RECOVERY_WARN" ;;
            $RECOVERY_INFO)  level_name="RECOVERY_INFO" ;;
            $RECOVERY_DEBUG) level_name="RECOVERY_DEBUG" ;;
        esac
        echo "[$timestamp] $level_name: $message" >> "$LOG_FILE"
    fi
}

# Check if step is critical (failure should trigger rollback)
is_critical_step() {
    local step_id="$1"

    # Define critical steps that should trigger automatic rollback on failure
    local critical_steps=(
        "prerequisites"
        "ssh_setup"
        "github_auth"
        "clone_dotfiles"
        "homebrew"
        "symlinks"
    )

    for critical_step in "${critical_steps[@]}"; do
        if [[ "$step_id" == "$critical_step" ]]; then
            return 0
        fi
    done

    return 1
}

# Save rollback information for a step
save_rollback_info() {
    local step_id="$1"
    local rollback_data="$2"

    recovery_log $RECOVERY_DEBUG "Saving rollback info for step: $step_id"

    # Create rollback info file
    local rollback_file="${STATE_DIR}/rollback_${step_id}.json"
    echo "$rollback_data" > "$rollback_file"

    # Update state with rollback reference
    local temp_file="${STATE_FILE}.tmp"
    load_state | python3 -c "
import json, sys
data = json.load(sys.stdin)
if 'rollback_info' not in data:
    data['rollback_info'] = {}
data['rollback_info']['$step_id'] = '$rollback_file'
print(json.dumps(data, indent=2))
" > "$temp_file"

    if [[ -f "$temp_file" ]]; then
        mv "$temp_file" "$STATE_FILE"
        recovery_log $RECOVERY_DEBUG "Rollback info saved for step: $step_id"
        return 0
    else
        recovery_log $RECOVERY_ERROR "Failed to save rollback info for step: $step_id"
        return 1
    fi
}

# Get rollback information for a step
get_rollback_info() {
    local step_id="$1"

    local rollback_file=$(load_state | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    rollback_info = data.get('rollback_info', {})
    print(rollback_info.get('$step_id', ''))
except:
    print('')
")

    if [[ -n "$rollback_file" && -f "$rollback_file" ]]; then
        cat "$rollback_file"
    else
        echo "{}"
    fi
}

# Rollback SSH setup
rollback_ssh_step() {
    recovery_log $RECOVERY_INFO "Rolling back SSH setup"

    local rollback_info=$(get_rollback_info "ssh_setup")
    local ssh_key_created=$(echo "$rollback_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('ssh_key_created', ''))
except:
    print('')
")

    local rollback_errors=()

    # Remove SSH key if it was created during this installation
    if [[ -n "$ssh_key_created" && -f "$ssh_key_created" ]]; then
        recovery_log $RECOVERY_INFO "Removing SSH key: $ssh_key_created"
        if rm -f "$ssh_key_created" "${ssh_key_created}.pub"; then
            recovery_log $RECOVERY_INFO "SSH key removed successfully"
        else
            rollback_errors+=("Failed to remove SSH key: $ssh_key_created")
        fi
    fi

    # Remove SSH config entries if they were added
    local ssh_config_backup=$(echo "$rollback_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('ssh_config_backup', ''))
except:
    print('')
")

    if [[ -n "$ssh_config_backup" && -f "$ssh_config_backup" ]]; then
        recovery_log $RECOVERY_INFO "Restoring SSH config from backup"
        if cp "$ssh_config_backup" "$HOME/.ssh/config"; then
            recovery_log $RECOVERY_INFO "SSH config restored successfully"
        else
            rollback_errors+=("Failed to restore SSH config from backup")
        fi
    fi

    # Report results
    if [[ ${#rollback_errors[@]} -gt 0 ]]; then
        recovery_log $RECOVERY_ERROR "SSH rollback completed with errors:"
        for error in "${rollback_errors[@]}"; do
            recovery_log $RECOVERY_ERROR "  - $error"
        done
        return 1
    fi

    recovery_log $RECOVERY_INFO "SSH setup rollback completed successfully"
    return 0
}

# Rollback Homebrew installation
rollback_homebrew_step() {
    recovery_log $RECOVERY_INFO "Rolling back Homebrew installation"

    local rollback_info=$(get_rollback_info "homebrew")
    local homebrew_installed=$(echo "$rollback_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('homebrew_installed', 'false'))
except:
    print('false')
")

    local rollback_errors=()

    # Only uninstall Homebrew if it was installed during this session
    if [[ "$homebrew_installed" == "true" ]]; then
        recovery_log $RECOVERY_INFO "Uninstalling Homebrew (installed during this session)"

        # Use Homebrew's official uninstall script
        if command -v brew >/dev/null 2>&1; then
            local uninstall_script="/tmp/homebrew_uninstall.sh"
            if curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh -o "$uninstall_script" 2>/dev/null; then
                if bash "$uninstall_script" --force >/dev/null 2>&1; then
                    recovery_log $RECOVERY_INFO "Homebrew uninstalled successfully"
                else
                    rollback_errors+=("Failed to uninstall Homebrew")
                fi
                rm -f "$uninstall_script"
            else
                rollback_errors+=("Failed to download Homebrew uninstall script")
            fi
        fi
    else
        recovery_log $RECOVERY_INFO "Homebrew was pre-existing, skipping uninstall"
    fi

    # Restore PATH if it was modified
    local path_backup=$(echo "$rollback_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('path_backup', ''))
except:
    print('')
")

    if [[ -n "$path_backup" ]]; then
        recovery_log $RECOVERY_INFO "Restoring PATH from backup"
        export PATH="$path_backup"
    fi

    # Report results
    if [[ ${#rollback_errors[@]} -gt 0 ]]; then
        recovery_log $RECOVERY_ERROR "Homebrew rollback completed with errors:"
        for error in "${rollback_errors[@]}"; do
            recovery_log $RECOVERY_ERROR "  - $error"
        done
        return 1
    fi

    recovery_log $RECOVERY_INFO "Homebrew rollback completed successfully"
    return 0
}

# Rollback symlink creation
rollback_symlinks_step() {
    recovery_log $RECOVERY_INFO "Rolling back symlink creation"

    local rollback_info=$(get_rollback_info "symlinks")
    local created_symlinks=$(echo "$rollback_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    symlinks = data.get('created_symlinks', [])
    for symlink in symlinks:
        print(symlink)
except:
    pass
")

    local rollback_errors=()

    # Remove created symlinks
    if [[ -n "$created_symlinks" ]]; then
        while IFS= read -r symlink_path; do
            if [[ -n "$symlink_path" && -L "$symlink_path" ]]; then
                recovery_log $RECOVERY_INFO "Removing symlink: $symlink_path"
                if rm -f "$symlink_path"; then
                    recovery_log $RECOVERY_DEBUG "Symlink removed: $symlink_path"
                else
                    rollback_errors+=("Failed to remove symlink: $symlink_path")
                fi
            fi
        done <<< "$created_symlinks"
    fi

    # Restore backed up files
    local backed_up_files=$(echo "$rollback_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    backups = data.get('backed_up_files', {})
    for original, backup in backups.items():
        print(f'{original}:{backup}')
except:
    pass
")

    if [[ -n "$backed_up_files" ]]; then
        while IFS=':' read -r original_path backup_path; do
            if [[ -n "$original_path" && -n "$backup_path" && -f "$backup_path" ]]; then
                recovery_log $RECOVERY_INFO "Restoring backup: $backup_path -> $original_path"
                if cp "$backup_path" "$original_path"; then
                    recovery_log $RECOVERY_DEBUG "File restored: $original_path"
                else
                    rollback_errors+=("Failed to restore file: $original_path")
                fi
            fi
        done <<< "$backed_up_files"
    fi

    # Report results
    if [[ ${#rollback_errors[@]} -gt 0 ]]; then
        recovery_log $RECOVERY_ERROR "Symlinks rollback completed with errors:"
        for error in "${rollback_errors[@]}"; do
            recovery_log $RECOVERY_ERROR "  - $error"
        done
        return 1
    fi

    recovery_log $RECOVERY_INFO "Symlinks rollback completed successfully"
    return 0
}

# Rollback repository cloning
rollback_clone_repos_step() {
    recovery_log $RECOVERY_INFO "Rolling back repository cloning"

    local rollback_info=$(get_rollback_info "clone_repos")
    local cloned_repos=$(echo "$rollback_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    repos = data.get('cloned_repositories', [])
    for repo in repos:
        print(repo)
except:
    pass
")

    local rollback_errors=()

    # Remove cloned repositories
    if [[ -n "$cloned_repos" ]]; then
        while IFS= read -r repo_path; do
            if [[ -n "$repo_path" && -d "$repo_path" ]]; then
                recovery_log $RECOVERY_INFO "Removing cloned repository: $repo_path"
                if rm -rf "$repo_path"; then
                    recovery_log $RECOVERY_DEBUG "Repository removed: $repo_path"
                else
                    rollback_errors+=("Failed to remove repository: $repo_path")
                fi
            fi
        done <<< "$cloned_repos"
    fi

    # Report results
    if [[ ${#rollback_errors[@]} -gt 0 ]]; then
        recovery_log $RECOVERY_ERROR "Repository cloning rollback completed with errors:"
        for error in "${rollback_errors[@]}"; do
            recovery_log $RECOVERY_ERROR "  - $error"
        done
        return 1
    fi

    recovery_log $RECOVERY_INFO "Repository cloning rollback completed successfully"
    return 0
}

# Rollback specific step
rollback_step() {
    local step_id="$1"

    recovery_log $RECOVERY_INFO "Starting rollback for step: $step_id"

    # Check if step has rollback information
    local rollback_info=$(get_rollback_info "$step_id")
    if [[ "$rollback_info" == "{}" ]]; then
        recovery_log $RECOVERY_WARN "No rollback information available for step: $step_id"
        return 0
    fi

    # Execute step-specific rollback
    case "$step_id" in
        "ssh_setup")
            rollback_ssh_step
            ;;
        "homebrew")
            rollback_homebrew_step
            ;;
        "symlinks")
            rollback_symlinks_step
            ;;
        "clone_repos"|"clone_dotfiles")
            rollback_clone_repos_step
            ;;
        *)
            recovery_log $RECOVERY_WARN "No specific rollback procedure for step: $step_id"
            return 0
            ;;
    esac

    local rollback_result=$?

    # Update step status to indicate rollback
    if [[ $rollback_result -eq 0 ]]; then
        save_state "$step_id" "rolled_back" "{\"rolled_back_at\":\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}"
        recovery_log $RECOVERY_INFO "Step rollback completed successfully: $step_id"
    else
        save_state "$step_id" "rollback_failed" "{\"rollback_failed_at\":\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}"
        recovery_log $RECOVERY_ERROR "Step rollback failed: $step_id"
    fi

    return $rollback_result
}

# Rollback current installation session
rollback_session() {
    recovery_log $RECOVERY_INFO "Starting session rollback"

    local session_errors=0
    local rollback_steps=()

    # Get current installation ID
    local installation_id=$(load_state | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('installation_id', ''))
except:
    print('')
")

    if [[ -z "$installation_id" ]]; then
        recovery_log $RECOVERY_ERROR "No installation session found to rollback"
        return 1
    fi

    recovery_log $RECOVERY_INFO "Rolling back installation session: $installation_id"

    # Get steps that were completed or failed in this session
    local session_steps=$(load_state | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    steps = data.get('steps', {})
    for step_id, step_data in steps.items():
        status = step_data.get('status', '')
        if status in ['completed', 'failed', 'in_progress']:
            print(step_id)
except:
    pass
")

    # Convert to array and reverse order for rollback
    if [[ -n "$session_steps" ]]; then
        while IFS= read -r step_id; do
            rollback_steps=("$step_id" "${rollback_steps[@]}")
        done <<< "$session_steps"
    fi

    if [[ ${#rollback_steps[@]} -eq 0 ]]; then
        recovery_log $RECOVERY_INFO "No steps to rollback in current session"
        return 0
    fi

    recovery_log $RECOVERY_INFO "Rolling back ${#rollback_steps[@]} steps in reverse order"

    # Rollback steps in reverse order
    for step_id in "${rollback_steps[@]}"; do
        recovery_log $RECOVERY_INFO "Rolling back step: $step_id"

        if ! rollback_step "$step_id"; then
            recovery_log $RECOVERY_ERROR "Failed to rollback step: $step_id"
            ((session_errors++))
        fi
    done

    # Restore backed up files
    restore_backups

    # Report results
    if [[ $session_errors -eq 0 ]]; then
        recovery_log $RECOVERY_INFO "Session rollback completed successfully"

        # Mark session as rolled back
        save_state "session" "rolled_back" "{\"rollback_completed_at\":\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",\"steps_rolled_back\":${#rollback_steps[@]}}"

        return 0
    else
        recovery_log $RECOVERY_ERROR "Session rollback completed with $session_errors errors"
        return 1
    fi
}

# Restore backed up files
restore_backups() {
    recovery_log $RECOVERY_INFO "Restoring backed up files"

    local restore_errors=()

    # Get backup information from state
    local backups=$(load_state | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    backups = data.get('backups', {})
    for original, backup in backups.items():
        print(f'{original}:{backup}')
except:
    pass
")

    if [[ -z "$backups" ]]; then
        recovery_log $RECOVERY_INFO "No backed up files to restore"
        return 0
    fi

    # Restore each backed up file
    while IFS=':' read -r original_path backup_path; do
        if [[ -n "$original_path" && -n "$backup_path" ]]; then
            if [[ -f "$backup_path" ]]; then
                recovery_log $RECOVERY_INFO "Restoring: $backup_path -> $original_path"

                # Create directory if needed
                local dir_path=$(dirname "$original_path")
                mkdir -p "$dir_path"

                if cp "$backup_path" "$original_path"; then
                    recovery_log $RECOVERY_DEBUG "File restored successfully: $original_path"
                else
                    restore_errors+=("Failed to restore file: $original_path")
                fi
            else
                restore_errors+=("Backup file not found: $backup_path")
            fi
        fi
    done <<< "$backups"

    # Report results
    if [[ ${#restore_errors[@]} -gt 0 ]]; then
        recovery_log $RECOVERY_ERROR "File restoration completed with errors:"
        for error in "${restore_errors[@]}"; do
            recovery_log $RECOVERY_ERROR "  - $error"
        done
        return 1
    fi

    recovery_log $RECOVERY_INFO "File restoration completed successfully"
    return 0
}

# Automatic rollback for critical failures
trigger_automatic_rollback() {
    local failed_step="$1"
    local error_type="${2:-unknown}"

    recovery_log $RECOVERY_ERROR "Critical failure detected in step: $failed_step (error type: $error_type)"

    # Check if automatic rollback is enabled
    local auto_rollback_enabled=${AUTO_ROLLBACK_ENABLED:-true}

    if [[ "$auto_rollback_enabled" != "true" ]]; then
        recovery_log $RECOVERY_INFO "Automatic rollback is disabled"
        return 0
    fi

    # Only trigger automatic rollback for critical steps
    if ! is_critical_step "$failed_step"; then
        recovery_log $RECOVERY_INFO "Step '$failed_step' is not critical, skipping automatic rollback"
        return 0
    fi

    recovery_log $RECOVERY_INFO "Triggering automatic rollback for critical step: $failed_step"

    # Perform rollback
    if rollback_session; then
        recovery_log $RECOVERY_INFO "Automatic rollback completed successfully"
        return 0
    else
        recovery_log $RECOVERY_ERROR "Automatic rollback failed"
        return 1
    fi
}

# Clean up old backup files
cleanup_old_backups() {
    local retention_days="${1:-$BACKUP_RETENTION_DAYS}"

    recovery_log $RECOVERY_INFO "Cleaning up backup files older than $retention_days days"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        recovery_log $RECOVERY_DEBUG "Backup directory does not exist: $BACKUP_DIR"
        return 0
    fi

    # Find and remove old backup files
    local removed_count=0
    while IFS= read -r -d '' backup_file; do
        recovery_log $RECOVERY_DEBUG "Removing old backup: $backup_file"
        if rm -f "$backup_file"; then
            ((removed_count++))
        fi
    done < <(find "$BACKUP_DIR" -type f -mtime +$retention_days -print0 2>/dev/null)

    recovery_log $RECOVERY_INFO "Cleaned up $removed_count old backup files"
}

# Get recovery status
get_recovery_status() {
    local state=$(load_state)

    echo "$state" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    steps = data.get('steps', {})

    rolled_back = sum(1 for step in steps.values() if step.get('status') == 'rolled_back')
    rollback_failed = sum(1 for step in steps.values() if step.get('status') == 'rollback_failed')

    print(f'Steps rolled back: {rolled_back}')
    print(f'Rollback failures: {rollback_failed}')

    session_data = steps.get('session', {})
    if session_data.get('status') == 'rolled_back':
        metadata = session_data.get('metadata', {})
        print(f'Session rollback completed: {metadata.get(\"rollback_completed_at\", \"unknown\")}')
        print(f'Steps in rollback: {metadata.get(\"steps_rolled_back\", 0)}')

except Exception as e:
    print(f'Error reading recovery status: {e}')
"
}

# Export functions for use in other scripts
export -f rollback_step
export -f rollback_session
export -f restore_backups
export -f trigger_automatic_rollback
export -f save_rollback_info
export -f cleanup_old_backups
export -f get_recovery_status
