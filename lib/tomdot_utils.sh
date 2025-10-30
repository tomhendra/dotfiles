#!/usr/bin/env bash

# Tomdot Utilities - Consolidated helper functions
# Validation, backup, recovery, and configuration management

# Source UI framework for consistent messaging
TOMDOT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${TOMDOT_LIB_DIR}/tomdot_ui.sh"

# Configuration
if [[ -z "${TOMDOT_BACKUP_DIR:-}" ]]; then
    readonly TOMDOT_BACKUP_DIR="${HOME}/.tomdot_install_state/backups"
    readonly TOMDOT_LOG_FILE="${HOME}/.tomdot_install_state/install.log"
    readonly TOMDOT_STATE_FILE="${HOME}/.tomdot_install_state/state.json"
    readonly TOMDOT_STATE_DIR="${HOME}/.tomdot_install_state"
fi

# Validation constants
readonly VALIDATION_TIMEOUT=30
readonly VALIDATION_ERROR=1
readonly VALIDATION_WARN=2
readonly VALIDATION_INFO=3
readonly VALIDATION_DEBUG=4

# Recovery constants
readonly ROLLBACK_TIMEOUT=60
readonly BACKUP_RETENTION_DAYS=30

# Configuration file mappings
declare -A CONFIG_MAPPINGS=(
    ["zsh/.zshrc"]="$HOME/.zshrc"
    ["zsh/.zprofile"]="$HOME/.zprofile"
    ["zsh/zsh_aliases.zsh"]="$HOME/.zsh_aliases"
    ["git/.gitconfig"]="$HOME/.gitconfig"
    ["git/.gitignore_global"]="$HOME/.gitignore_global"
    ["ghostty/config"]="$HOME/.config/ghostty/config"
    ["bat/bat.conf"]="$HOME/.config/bat/config"
    ["starship.toml"]="$HOME/.config/starship.toml"
)

# Configuration types for intelligent handling
declare -A CONFIG_TYPES=(
    [".zshrc"]="shell"
    [".zprofile"]="shell"
    [".zsh_aliases"]="shell"
    [".gitconfig"]="git"
    [".gitignore_global"]="text"
    ["config"]="text"
    ["starship.toml"]="toml"
    ["bat.conf"]="text"
)

# =============================================================================
# CORE UTILITY FUNCTIONS
# =============================================================================

# Check if command exists
tomdot_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check network connectivity with retry logic
tomdot_check_network() {
    local retries="${1:-3}"
    local timeout="${2:-10}"

    for ((i=1; i<=retries; i++)); do
        if curl -s --connect-timeout 5 --max-time "$timeout" "https://github.com" >/dev/null 2>&1; then
            return 0
        fi

        if [[ $i -lt $retries ]]; then
            tomdot_log "WARNING" "Network check failed (attempt $i/$retries), retrying..."
            sleep $((i * 2))  # Exponential backoff
        fi
    done

    return 1
}

# Enhanced logging with levels
tomdot_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    mkdir -p "$(dirname "$TOMDOT_LOG_FILE")"
    echo "[$timestamp] [$level] $message" >> "$TOMDOT_LOG_FILE"

    # Also log to stderr for errors and warnings
    case "$level" in
        "ERROR"|"WARNING")
            echo "[$timestamp] [$level] $message" >&2
            ;;
    esac
}

# Backup existing configuration file
tomdot_backup_file() {
    local filepath="$1"
    local backup_name="${2:-$(basename "$filepath")}"

    if [[ ! -f "$filepath" ]]; then
        tomdot_log "WARNING" "File not found for backup: $filepath"
        return 1
    fi

    mkdir -p "$TOMDOT_BACKUP_DIR"

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${TOMDOT_BACKUP_DIR}/${backup_name}_${timestamp}"

    if cp "$filepath" "$backup_file"; then
        tomdot_log "INFO" "Backed up $filepath to $backup_file"
        echo "$backup_file"
        return 0
    else
        tomdot_log "ERROR" "Failed to backup $filepath"
        return 1
    fi
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Comprehensive prerequisites validation
tomdot_check_prerequisites() {
    tomdot_log "INFO" "Starting prerequisite validation"

    local validation_errors=()
    local validation_warnings=()

    # Check macOS version
    local macos_version=$(sw_vers -productVersion 2>/dev/null)
    if [[ -n "$macos_version" ]]; then
        tomdot_log "INFO" "macOS version: $macos_version"

        # Check if version is supported (macOS 10.15+)
        local major_version=$(echo "$macos_version" | cut -d. -f1)
        local minor_version=$(echo "$macos_version" | cut -d. -f2)

        if [[ $major_version -lt 10 ]] || [[ $major_version -eq 10 && $minor_version -lt 15 ]]; then
            validation_errors+=("Unsupported macOS version: $macos_version (requires 10.15+)")
        fi
    else
        validation_errors+=("Unable to determine macOS version")
    fi

    # Check available disk space
    local available_space=$(df -h "$HOME" | awk 'NR==2 {print $4}' | sed 's/[^0-9.]//g')
    if [[ -n "$available_space" ]]; then
        tomdot_log "INFO" "Available disk space: ${available_space}GB"

        # Check if we have at least 5GB free
        if (( $(echo "$available_space < 5" | bc -l 2>/dev/null || echo "0") )); then
            validation_warnings+=("Low disk space: ${available_space}GB (recommended: 5GB+)")
        fi
    else
        validation_warnings+=("Unable to determine available disk space")
    fi

    # Check user permissions
    if [[ ! -w "$HOME" ]]; then
        validation_errors+=("No write permission to home directory: $HOME")
    fi

    # Check if running as root (not recommended)
    if [[ $EUID -eq 0 ]]; then
        validation_warnings+=("Running as root is not recommended")
    fi

    # Check required system tools
    local required_tools=("curl" "git" "python3" "bash" "zsh")
    for tool in "${required_tools[@]}"; do
        if ! tomdot_command_exists "$tool"; then
            validation_errors+=("Required tool not found: $tool")
        fi
    done

    # Check network connectivity
    if ! tomdot_check_network; then
        validation_warnings+=("No internet connectivity detected")
    fi

    # Report results
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        tomdot_log "ERROR" "Prerequisite validation failed with ${#validation_errors[@]} errors:"
        for error in "${validation_errors[@]}"; do
            tomdot_log "ERROR" "  - $error"
        done
        return 1
    fi

    if [[ ${#validation_warnings[@]} -gt 0 ]]; then
        tomdot_log "WARNING" "Prerequisite validation completed with ${#validation_warnings[@]} warnings:"
        for warning in "${validation_warnings[@]}"; do
            tomdot_log "WARNING" "  - $warning"
        done
    fi

    tomdot_log "INFO" "Prerequisites validation completed successfully"
    return 0
}

# Validate tool functionality
tomdot_check_tool_functionality() {
    local tool_name="$1"
    local test_command="${2:-}"

    tomdot_log "DEBUG" "Checking functionality of tool: $tool_name"

    # Check if tool exists
    if ! tomdot_command_exists "$tool_name"; then
        tomdot_log "ERROR" "Tool not found: $tool_name"
        return 1
    fi

    # Run basic functionality test
    local test_result=0
    case "$tool_name" in
        "git")
            git --version >/dev/null 2>&1
            test_result=$?
            ;;
        "brew")
            brew --version >/dev/null 2>&1
            test_result=$?
            ;;
        "node")
            node --version >/dev/null 2>&1
            test_result=$?
            ;;
        "npm")
            npm --version >/dev/null 2>&1
            test_result=$?
            ;;
        "cargo")
            cargo --version >/dev/null 2>&1
            test_result=$?
            ;;
        "rustc")
            rustc --version >/dev/null 2>&1
            test_result=$?
            ;;
        "zsh")
            zsh --version >/dev/null 2>&1
            test_result=$?
            ;;
        "python3")
            python3 --version >/dev/null 2>&1
            test_result=$?
            ;;
        *)
            # Generic test - just check if command runs
            if [[ -n "$test_command" ]]; then
                eval "$test_command" >/dev/null 2>&1
                test_result=$?
            else
                "$tool_name" --version >/dev/null 2>&1 || "$tool_name" --help >/dev/null 2>&1
                test_result=$?
            fi
            ;;
    esac

    if [[ $test_result -eq 0 ]]; then
        tomdot_log "DEBUG" "Tool functionality verified: $tool_name"
        return 0
    else
        tomdot_log "ERROR" "Tool functionality test failed: $tool_name"
        return 1
    fi
}

# Validate symlink integrity
tomdot_validate_symlinks() {
    tomdot_log "INFO" "Starting symlink validation"

    local symlink_errors=()
    local symlink_warnings=()

    # Common dotfile symlinks to check
    local expected_symlinks=(
        "$HOME/.zshrc:$HOME/.dotfiles/zsh/.zshrc"
        "$HOME/.zprofile:$HOME/.dotfiles/zsh/.zprofile"
        "$HOME/.gitconfig:$HOME/.dotfiles/git/.gitconfig"
        "$HOME/.gitignore_global:$HOME/.dotfiles/git/.gitignore_global"
        "$HOME/.config/ghostty:$HOME/.dotfiles/ghostty"
        "$HOME/.config/starship.toml:$HOME/.dotfiles/starship.toml"
    )

    for symlink_spec in "${expected_symlinks[@]}"; do
        IFS=':' read -r link_path target_path <<< "$symlink_spec"

        tomdot_log "DEBUG" "Checking symlink: $link_path -> $target_path"

        if [[ -L "$link_path" ]]; then
            # It's a symlink, check if it points to the right place
            local actual_target=$(readlink "$link_path")

            if [[ "$actual_target" == "$target_path" ]]; then
                # Check if target exists
                if [[ -e "$target_path" ]]; then
                    tomdot_log "DEBUG" "Symlink valid: $link_path -> $target_path"
                else
                    symlink_errors+=("Symlink target missing: $link_path -> $target_path")
                fi
            else
                symlink_warnings+=("Symlink points to unexpected target: $link_path -> $actual_target (expected: $target_path)")
            fi
        elif [[ -e "$link_path" ]]; then
            # File exists but is not a symlink
            symlink_warnings+=("Expected symlink but found regular file: $link_path")
        else
            # Symlink doesn't exist
            symlink_warnings+=("Expected symlink not found: $link_path")
        fi
    done

    # Check for broken symlinks in common directories
    local check_dirs=("$HOME" "$HOME/.config")
    for dir in "${check_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            tomdot_log "DEBUG" "Checking for broken symlinks in: $dir"

            while IFS= read -r -d '' broken_link; do
                symlink_errors+=("Broken symlink found: $broken_link")
            done < <(find "$dir" -maxdepth 2 -type l ! -exec test -e {} \; -print0 2>/dev/null)
        fi
    done

    # Report results
    if [[ ${#symlink_errors[@]} -gt 0 ]]; then
        tomdot_log "ERROR" "Symlink validation failed with ${#symlink_errors[@]} errors:"
        for error in "${symlink_errors[@]}"; do
            tomdot_log "ERROR" "  - $error"
        done
        return 1
    fi

    if [[ ${#symlink_warnings[@]} -gt 0 ]]; then
        tomdot_log "WARNING" "Symlink validation completed with ${#symlink_warnings[@]} warnings:"
        for warning in "${symlink_warnings[@]}"; do
            tomdot_log "WARNING" "  - $warning"
        done
    fi

    tomdot_log "INFO" "Symlink validation completed successfully"
    return 0
}

# Validate specific installation components
tomdot_validate_ssh_setup() {
    tomdot_log "DEBUG" "Validating SSH setup"

    local ssh_errors=()

    # Check if SSH directory exists
    if [[ ! -d "$HOME/.ssh" ]]; then
        ssh_errors+=("SSH directory not found: $HOME/.ssh")
        return 1
    fi

    # Check for SSH keys
    local key_files=("$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ed25519")
    local key_found=false

    for key_file in "${key_files[@]}"; do
        if [[ -f "$key_file" ]]; then
            key_found=true
            tomdot_log "DEBUG" "SSH key found: $key_file"

            # Check key permissions
            local perms=$(stat -f "%A" "$key_file" 2>/dev/null || stat -c "%a" "$key_file" 2>/dev/null)
            if [[ "$perms" != "600" ]]; then
                ssh_errors+=("Incorrect SSH key permissions: $key_file ($perms, should be 600)")
            fi
        fi
    done

    if [[ "$key_found" == false ]]; then
        ssh_errors+=("No SSH keys found")
    fi

    # Report results
    if [[ ${#ssh_errors[@]} -gt 0 ]]; then
        tomdot_log "ERROR" "SSH validation failed:"
        for error in "${ssh_errors[@]}"; do
            tomdot_log "ERROR" "  - $error"
        done
        return 1
    fi

    tomdot_log "INFO" "SSH setup validation completed successfully"
    return 0
}

# Validate GitHub authentication
tomdot_validate_github_auth() {
    tomdot_log "DEBUG" "Validating GitHub authentication"

    # Test GitHub SSH connection
    if ssh -T git@github.com -o ConnectTimeout=10 -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
        tomdot_log "INFO" "GitHub SSH authentication verified"
        return 0
    else
        tomdot_log "ERROR" "GitHub SSH authentication failed"
        return 1
    fi
}

# Validate Homebrew installation
tomdot_validate_homebrew() {
    tomdot_log "DEBUG" "Validating Homebrew installation"

    local brew_errors=()

    # Check if brew command exists
    if ! tomdot_command_exists "brew"; then
        brew_errors+=("Homebrew not installed or not in PATH")
        return 1
    fi

    # Check brew functionality
    if ! tomdot_check_tool_functionality "brew"; then
        brew_errors+=("Homebrew functionality test failed")
    fi

    # Check if Brewfile exists and validate some key packages
    if [[ -f "$HOME/.dotfiles/Brewfile" ]]; then
        local key_packages=("git" "curl" "wget" "bat" "ripgrep")
        for package in "${key_packages[@]}"; do
            if ! tomdot_command_exists "$package"; then
                brew_errors+=("Expected Homebrew package not found: $package")
            fi
        done
    fi

    # Report results
    if [[ ${#brew_errors[@]} -gt 0 ]]; then
        tomdot_log "ERROR" "Homebrew validation failed:"
        for error in "${brew_errors[@]}"; do
            tomdot_log "ERROR" "  - $error"
        done
        return 1
    fi

    tomdot_log "INFO" "Homebrew installation validation completed successfully"
    return 0
}

# =============================================================================
# CONFIGURATION MANAGEMENT FUNCTIONS
# =============================================================================

# Get configuration type for a file
tomdot_get_config_type() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    local extension="${filename##*.}"

    # Check specific filename mappings first
    if [[ -n "${CONFIG_TYPES[$filename]:-}" ]]; then
        echo "${CONFIG_TYPES[$filename]}"
        return
    fi

    # Check by extension
    case "$extension" in
        "json") echo "json" ;;
        "toml") echo "toml" ;;
        "yml"|"yaml") echo "yaml" ;;
        "sh"|"zsh"|"bash") echo "shell" ;;
        *) echo "text" ;;
    esac
}

# Check if configuration file exists and get its status
tomdot_check_config_status() {
    local source_file="$1"
    local target_file="$2"

    if [[ ! -f "$target_file" ]]; then
        echo "new"
        return
    fi

    if [[ ! -f "$source_file" ]]; then
        echo "source_missing"
        return
    fi

    # Compare files
    if cmp -s "$source_file" "$target_file"; then
        echo "identical"
    elif [[ "$target_file" -ot "$source_file" ]]; then
        echo "outdated"
    else
        echo "modified"
    fi
}

# Comprehensive conflict detection
tomdot_detect_conflicts() {
    local dotfiles_dir="${1:-$HOME/.dotfiles}"
    local conflicts=()

    for source_rel in "${!CONFIG_MAPPINGS[@]}"; do
        local source_file="$dotfiles_dir/$source_rel"
        local target_file="${CONFIG_MAPPINGS[$source_rel]}"

        if [[ -f "$target_file" && -f "$source_file" ]]; then
            local status=$(tomdot_check_config_status "$source_file" "$target_file")
            if [[ "$status" == "modified" || "$status" == "outdated" ]]; then
                conflicts+=("$target_file")
            fi
        fi
    done

    if [[ ${#conflicts[@]} -gt 0 ]]; then
        tomdot_log "WARNING" "Configuration conflicts detected: ${conflicts[*]}"
        printf "%s\n" "${conflicts[@]}"
        return 0
    fi

    tomdot_log "INFO" "No configuration conflicts detected"
    return 1
}

# Deploy a single configuration file with conflict resolution
tomdot_deploy_config_file() {
    local source_file="$1"
    local target_file="$2"
    local force_mode="${3:-false}"

    # Ensure target directory exists
    local target_dir=$(dirname "$target_file")
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
        tomdot_log "INFO" "Created directory: $target_dir"
    fi

    local status=$(tomdot_check_config_status "$source_file" "$target_file")

    case "$status" in
        "new")
            tomdot_log "INFO" "Deploying new configuration: $target_file"
            cp "$source_file" "$target_file"
            return 0
            ;;
        "identical")
            tomdot_log "INFO" "Configuration up to date: $target_file"
            return 0
            ;;
        "source_missing")
            tomdot_log "ERROR" "Source file missing: $source_file"
            return 1
            ;;
        "outdated"|"modified")
            if [[ "$force_mode" == "true" ]]; then
                # Force mode: backup and replace
                local backup_file
                backup_file=$(tomdot_backup_file "$target_file")
                cp "$source_file" "$target_file"
                tomdot_log "INFO" "Force replaced $target_file (backup: $backup_file)"
                return 0
            fi

            # Interactive conflict resolution
            local choice
            choice=$(ui_question "Configuration conflict for $(basename "$target_file"). Replace, backup, or skip? (replace/backup/skip)" "backup")

            case "$choice" in
                "replace"|"r")
                    local backup_file
                    backup_file=$(tomdot_backup_file "$target_file")
                    cp "$source_file" "$target_file"
                    tomdot_log "INFO" "Replaced $target_file (backup: $backup_file)"
                    return 0
                    ;;
                "backup"|"b")
                    local backup_file
                    backup_file=$(tomdot_backup_file "$target_file")
                    cp "$source_file" "$target_file"
                    tomdot_log "INFO" "Backed up and replaced $target_file"
                    return 0
                    ;;
                "skip"|"s")
                    tomdot_log "INFO" "Skipped configuration: $target_file"
                    return 0
                    ;;
                *)
                    tomdot_log "ERROR" "Invalid choice: $choice"
                    return 1
                    ;;
            esac
            ;;
    esac
}

# Deploy all configuration files
tomdot_deploy_all_configs() {
    local dotfiles_dir="${1:-$HOME/.dotfiles}"
    local force_mode="${2:-false}"
    local failed_configs=()

    ui_start_section "Deploying Configuration Files"

    for source_rel in "${!CONFIG_MAPPINGS[@]}"; do
        local source_file="$dotfiles_dir/$source_rel"
        local target_file="${CONFIG_MAPPINGS[$source_rel]}"

        if [[ ! -f "$source_file" ]]; then
            tomdot_log "WARNING" "Source file not found: $source_file"
            continue
        fi

        printf "${C_DIM}│${C_RESET} Processing: %s\n" "$(basename "$target_file")"

        if ! tomdot_deploy_config_file "$source_file" "$target_file" "$force_mode"; then
            failed_configs+=("$target_file")
            printf "${C_DIM}│${C_RESET} ${C_RED}❌ Failed: %s${C_RESET}\n" "$(basename "$target_file")"
        else
            printf "${C_DIM}│${C_RESET} ${C_GREEN}✅ Success: %s${C_RESET}\n" "$(basename "$target_file")"
        fi
    done

    if [[ ${#failed_configs[@]} -gt 0 ]]; then
        tomdot_log "ERROR" "Configuration deployment failed for: ${failed_configs[*]}"
        return 1
    else
        tomdot_log "INFO" "All configurations deployed successfully"
        return 0
    fi
}

# Validate deployed configurations
tomdot_validate_configs() {
    local validation_errors=()

    ui_start_section "Validating Configuration Files"

    for source_rel in "${!CONFIG_MAPPINGS[@]}"; do
        local target_file="${CONFIG_MAPPINGS[$source_rel]}"
        local config_name=$(basename "$target_file")

        printf "${C_DIM}│${C_RESET} Checking %s... " "$config_name"

        if [[ ! -f "$target_file" ]]; then
            printf "${C_RED}❌ Missing${C_RESET}\n"
            validation_errors+=("$target_file: File not found")
            continue
        fi

        # Basic validation based on file type
        local config_type=$(tomdot_get_config_type "$target_file")
        local validation_result=""

        case "$config_type" in
            "json")
                if tomdot_command_exists "jq"; then
                    if jq empty "$target_file" >/dev/null 2>&1; then
                        validation_result="valid"
                    else
                        validation_result="invalid JSON syntax"
                    fi
                else
                    validation_result="valid (jq not available)"
                fi
                ;;
            "shell")
                if bash -n "$target_file" >/dev/null 2>&1; then
                    validation_result="valid"
                else
                    validation_result="syntax error"
                fi
                ;;
            *)
                # Basic file checks
                if [[ -r "$target_file" ]]; then
                    validation_result="valid"
                else
                    validation_result="not readable"
                fi
                ;;
        esac

        if [[ "$validation_result" == "valid"* ]]; then
            printf "${C_GREEN}✅ %s${C_RESET}\n" "$validation_result"
        else
            printf "${C_RED}❌ %s${C_RESET}\n" "$validation_result"
            validation_errors+=("$target_file: $validation_result")
        fi
    done

    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        tomdot_log "ERROR" "Configuration validation failed:"
        for error in "${validation_errors[@]}"; do
            tomdot_log "ERROR" "  - $error"
        done
        return 1
    fi

    tomdot_log "INFO" "All configurations validated successfully"
    return 0
}

# Interactive conflict resolution
tomdot_resolve_conflicts() {
    local conflicts=()
    mapfile -t conflicts < <(tomdot_detect_conflicts)

    if [[ ${#conflicts[@]} -eq 0 ]]; then
        return 0
    fi

    ui_start_section "Configuration conflicts detected"
    printf "${C_DIM}│${C_RESET} The following files already exist:\n"

    for conflict in "${conflicts[@]}"; do
        printf "${C_DIM}│${C_RESET}   - %s\n" "$conflict"
    done

    printf "${C_DIM}│${C_RESET}\n"

    local choice
    choice=$(ui_question "How would you like to proceed? (backup/overwrite/skip)" "backup")

    case "$choice" in
        "backup"|"b")
            for conflict in "${conflicts[@]}"; do
                tomdot_backup_file "$conflict"
            done
            tomdot_log "INFO" "Backed up existing configuration files"
            return 0
            ;;
        "overwrite"|"o")
            tomdot_log "WARNING" "User chose to overwrite existing files"
            return 0
            ;;
        "skip"|"s")
            tomdot_log "INFO" "User chose to skip conflicting files"
            return 2
            ;;
        *)
            tomdot_log "ERROR" "Invalid choice: $choice"
            return 1
            ;;
    esac
}

# Validate successful installation - see enhanced version below

# =============================================================================
# RECOVERY AND ROLLBACK FUNCTIONS
# =============================================================================

# Check if step is critical (failure should trigger rollback)
tomdot_is_critical_step() {
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
tomdot_save_rollback_info() {
    local step_id="$1"
    local rollback_data="$2"

    tomdot_log "DEBUG" "Saving rollback info for step: $step_id"

    mkdir -p "$TOMDOT_STATE_DIR"

    # Create rollback info file
    local rollback_file="${TOMDOT_STATE_DIR}/rollback_${step_id}.json"
    echo "$rollback_data" > "$rollback_file"

    tomdot_log "DEBUG" "Rollback info saved for step: $step_id"
    return 0
}

# Get rollback information for a step
tomdot_get_rollback_info() {
    local step_id="$1"
    local rollback_file="${TOMDOT_STATE_DIR}/rollback_${step_id}.json"

    if [[ -f "$rollback_file" ]]; then
        cat "$rollback_file"
    else
        echo "{}"
    fi
}

# Rollback SSH setup
tomdot_rollback_ssh_step() {
    tomdot_log "INFO" "Rolling back SSH setup"

    local rollback_info=$(tomdot_get_rollback_info "ssh_setup")
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
        tomdot_log "INFO" "Removing SSH key: $ssh_key_created"
        if rm -f "$ssh_key_created" "${ssh_key_created}.pub"; then
            tomdot_log "INFO" "SSH key removed successfully"
        else
            rollback_errors+=("Failed to remove SSH key: $ssh_key_created")
        fi
    fi

    # Report results
    if [[ ${#rollback_errors[@]} -gt 0 ]]; then
        tomdot_log "ERROR" "SSH rollback completed with errors:"
        for error in "${rollback_errors[@]}"; do
            tomdot_log "ERROR" "  - $error"
        done
        return 1
    fi

    tomdot_log "INFO" "SSH setup rollback completed successfully"
    return 0
}

# Rollback symlink creation
tomdot_rollback_symlinks_step() {
    tomdot_log "INFO" "Rolling back symlink creation"

    local rollback_info=$(tomdot_get_rollback_info "symlinks")
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
                tomdot_log "INFO" "Removing symlink: $symlink_path"
                if rm -f "$symlink_path"; then
                    tomdot_log "DEBUG" "Symlink removed: $symlink_path"
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
                tomdot_log "INFO" "Restoring backup: $backup_path -> $original_path"
                if cp "$backup_path" "$original_path"; then
                    tomdot_log "DEBUG" "File restored: $original_path"
                else
                    rollback_errors+=("Failed to restore file: $original_path")
                fi
            fi
        done <<< "$backed_up_files"
    fi

    # Report results
    if [[ ${#rollback_errors[@]} -gt 0 ]]; then
        tomdot_log "ERROR" "Symlinks rollback completed with errors:"
        for error in "${rollback_errors[@]}"; do
            tomdot_log "ERROR" "  - $error"
        done
        return 1
    fi

    tomdot_log "INFO" "Symlinks rollback completed successfully"
    return 0
}

# Rollback specific step
tomdot_rollback_step() {
    local step_id="$1"

    tomdot_log "INFO" "Starting rollback for step: $step_id"

    # Check if step has rollback information
    local rollback_info=$(tomdot_get_rollback_info "$step_id")
    if [[ "$rollback_info" == "{}" ]]; then
        tomdot_log "WARNING" "No rollback information available for step: $step_id"
        return 0
    fi

    # Execute step-specific rollback
    case "$step_id" in
        "ssh_setup")
            tomdot_rollback_ssh_step
            ;;
        "symlinks")
            tomdot_rollback_symlinks_step
            ;;
        *)
            tomdot_log "WARNING" "No specific rollback procedure for step: $step_id"
            return 0
            ;;
    esac

    local rollback_result=$?

    if [[ $rollback_result -eq 0 ]]; then
        tomdot_log "INFO" "Step rollback completed successfully: $step_id"
    else
        tomdot_log "ERROR" "Step rollback failed: $step_id"
    fi

    return $rollback_result
}

# Recovery mechanism for failed operations with enhanced options
tomdot_recover_from_failure() {
    local failed_step="$1"
    local recovery_action="${2:-prompt}"

    tomdot_log "WARNING" "Attempting recovery from failed step: $failed_step"

    case "$recovery_action" in
        "retry")
            tomdot_log "INFO" "Retrying failed step: $failed_step"
            return 0
            ;;
        "skip")
            tomdot_log "WARNING" "Skipping failed step: $failed_step"
            return 2
            ;;
        "rollback")
            tomdot_log "INFO" "Rolling back failed step: $failed_step"
            tomdot_rollback_step "$failed_step"
            return 3
            ;;
        "prompt"|*)
            local choice
            choice=$(ui_question "Step '$failed_step' failed. What would you like to do? (retry/skip/rollback/abort)" "retry")

            case "$choice" in
                "retry"|"r")
                    tomdot_log "INFO" "User chose to retry failed step"
                    return 0
                    ;;
                "skip"|"s")
                    tomdot_log "WARNING" "User chose to skip failed step"
                    return 2
                    ;;
                "rollback"|"rb")
                    tomdot_log "INFO" "User chose to rollback failed step"
                    tomdot_rollback_step "$failed_step"
                    return 3
                    ;;
                "abort"|"a"|*)
                    tomdot_log "ERROR" "User chose to abort installation"
                    return 1
                    ;;
            esac
            ;;
    esac
}

# Clean up temporary files and state
tomdot_cleanup() {
    local keep_logs="${1:-true}"

    if [[ "$keep_logs" != "true" ]]; then
        rm -f "$TOMDOT_LOG_FILE"
        tomdot_log "INFO" "Cleaned up log files"
    fi

    # Clean up any temporary files that might have been created
    find /tmp -name "tomdot_*" -type f -mtime +1 -delete 2>/dev/null || true

    tomdot_log "INFO" "Cleanup completed"
}

# Show system information for debugging
tomdot_show_system_info() {
    echo "System Information:"
    echo "  OS: $(uname -s) $(uname -r)"
    echo "  Architecture: $(uname -m)"
    echo "  Shell: $SHELL"
    echo "  User: $USER"
    echo "  Home: $HOME"
    echo "  Working Directory: $(pwd)"
    echo
}

# =============================================================================
# ERROR HANDLING AND RETRY LOGIC
# =============================================================================

# Error categories and their properties
declare -A TOMDOT_ERROR_CATEGORIES=(
    ["network"]="Network connectivity or download issues"
    ["permission"]="File system permissions or access rights"
    ["dependency"]="Missing dependencies or prerequisites"
    ["configuration"]="Configuration file or setting issues"
    ["system"]="System compatibility or resource issues"
    ["user"]="User input or authentication issues"
    ["critical"]="Critical system errors requiring immediate attention"
    ["recoverable"]="Temporary issues that can be retried"
)

# Categorize error based on message and context
tomdot_categorize_error() {
    local error_message="$1"
    local exit_code="${2:-1}"
    local command="${3:-}"

    # Convert to lowercase for pattern matching
    local msg_lower="${error_message,,}"

    # Network-related errors
    if [[ "$msg_lower" =~ (network|connection|timeout|dns|curl|wget|download|unreachable) ]]; then
        echo "network"
        return
    fi

    # Permission errors
    if [[ "$msg_lower" =~ (permission|denied|access|forbidden|unauthorized|sudo) ]] || [[ $exit_code -eq 126 ]]; then
        echo "permission"
        return
    fi

    # Dependency errors
    if [[ "$msg_lower" =~ (command.*not.*found|no.*such.*file|missing|dependency|require) ]] || [[ $exit_code -eq 127 ]]; then
        echo "dependency"
        return
    fi

    # Configuration errors
    if [[ "$msg_lower" =~ (config|syntax|invalid|malformed|parse) ]]; then
        echo "configuration"
        return
    fi

    # System errors
    if [[ "$msg_lower" =~ (disk.*full|no.*space|memory|system|kernel|hardware) ]]; then
        echo "system"
        return
    fi

    # User/authentication errors
    if [[ "$msg_lower" =~ (auth|login|credential|password|key|token) ]]; then
        echo "user"
        return
    fi

    # Critical system errors
    if [[ $exit_code -ge 128 ]] || [[ "$msg_lower" =~ (critical|fatal|panic|abort|segmentation) ]]; then
        echo "critical"
        return
    fi

    # Default to recoverable for unknown errors
    echo "recoverable"
}

# Network retry logic with exponential backoff
tomdot_retry_network_operation() {
    local command="$1"
    local max_retries="${2:-3}"
    local base_delay="${3:-2}"
    local max_delay="${4:-30}"

    local attempt=1
    local delay=$base_delay

    while [[ $attempt -le $max_retries ]]; do
        tomdot_log "INFO" "Network operation attempt $attempt/$max_retries: $command"

        # Execute the command
        if eval "$command"; then
            tomdot_log "INFO" "Network operation succeeded on attempt $attempt"
            return 0
        fi

        local exit_code=$?
        tomdot_log "WARNING" "Network operation failed on attempt $attempt (exit code: $exit_code)"

        # Don't retry on the last attempt
        if [[ $attempt -eq $max_retries ]]; then
            tomdot_log "ERROR" "Network operation failed after $max_retries attempts"
            return $exit_code
        fi

        # Calculate next delay with exponential backoff
        tomdot_log "INFO" "Waiting ${delay}s before retry..."
        sleep "$delay"

        # Exponential backoff with jitter and max delay
        delay=$((delay * 2))
        if [[ $delay -gt $max_delay ]]; then
            delay=$max_delay
        fi

        # Add some jitter (±25%)
        local jitter=$((delay / 4))
        local random_jitter=$((RANDOM % (jitter * 2) - jitter))
        delay=$((delay + random_jitter))

        ((attempt++))
    done

    return 1
}

# Enhanced file operation with retry logic
tomdot_retry_file_operation() {
    local operation="$1"
    local max_retries="${2:-2}"

    local attempt=1

    while [[ $attempt -le $max_retries ]]; do
        tomdot_log "DEBUG" "File operation attempt $attempt/$max_retries: $operation"

        if eval "$operation"; then
            tomdot_log "DEBUG" "File operation succeeded on attempt $attempt"
            return 0
        fi

        local exit_code=$?
        tomdot_log "WARNING" "File operation failed on attempt $attempt (exit code: $exit_code)"

        # Don't retry on the last attempt
        if [[ $attempt -eq $max_retries ]]; then
            tomdot_log "ERROR" "File operation failed after $max_retries attempts"
            return $exit_code
        fi

        # Brief delay before retry
        sleep 1
        ((attempt++))
    done

    return 1
}

# Comprehensive error handler
tomdot_handle_error() {
    local step_id="$1"
    local error_message="$2"
    local exit_code="${3:-1}"
    local command="${4:-}"

    local category=$(tomdot_categorize_error "$error_message" "$exit_code" "$command")

    tomdot_log "ERROR" "Error in step '$step_id': $error_message (category: $category, exit: $exit_code)"

    # Show user-friendly error message
    ui_start_section "Error Detected"
    printf "${C_DIM}│${C_RESET} ${C_RED}❌ Step: %s${C_RESET}\n" "$step_id"
    printf "${C_DIM}│${C_RESET} ${C_RED}Category: %s${C_RESET}\n" "$category"
    printf "${C_DIM}│${C_RESET} ${C_RED}Message: %s${C_RESET}\n" "$error_message"

    if [[ -n "$command" ]]; then
        printf "${C_DIM}│${C_RESET} ${C_GRAY}Command: %s${C_RESET}\n" "$command"
    fi

    # Provide category-specific guidance
    case "$category" in
        "network")
            printf "${C_DIM}│${C_RESET}\n"
            printf "${C_DIM}│${C_RESET} ${C_BLUE}💡 Network Issue Suggestions:${C_RESET}\n"
            printf "${C_DIM}│${C_RESET}   - Check your internet connection\n"
            printf "${C_DIM}│${C_RESET}   - Verify DNS settings\n"
            printf "${C_DIM}│${C_RESET}   - Try again in a few minutes\n"
            ;;
        "permission")
            printf "${C_DIM}│${C_RESET}\n"
            printf "${C_DIM}│${C_RESET} ${C_BLUE}💡 Permission Issue Suggestions:${C_RESET}\n"
            printf "${C_DIM}│${C_RESET}   - Check file and directory permissions\n"
            printf "${C_DIM}│${C_RESET}   - Ensure write access to target location\n"
            ;;
        "dependency")
            printf "${C_DIM}│${C_RESET}\n"
            printf "${C_DIM}│${C_RESET} ${C_BLUE}💡 Dependency Issue Suggestions:${C_RESET}\n"
            printf "${C_DIM}│${C_RESET}   - Install the missing dependency\n"
            printf "${C_DIM}│${C_RESET}   - Check if required tools are in PATH\n"
            ;;
    esac

    # Return appropriate recovery action based on category
    case "$category" in
        "network"|"recoverable")
            return 0  # Suggest retry
            ;;
        "critical")
            return 1  # Suggest abort
            ;;
        *)
            return 2  # Suggest skip or manual intervention
            ;;
    esac
}

# Validate successful operation
tomdot_validate_operation() {
    local operation_type="$1"
    local target="${2:-}"

    case "$operation_type" in
        "file_exists")
            if [[ -f "$target" ]]; then
                tomdot_log "DEBUG" "Validation passed: File exists - $target"
                return 0
            else
                tomdot_log "ERROR" "Validation failed: File missing - $target"
                return 1
            fi
            ;;
        "directory_exists")
            if [[ -d "$target" ]]; then
                tomdot_log "DEBUG" "Validation passed: Directory exists - $target"
                return 0
            else
                tomdot_log "ERROR" "Validation failed: Directory missing - $target"
                return 1
            fi
            ;;
        "command_available")
            if tomdot_command_exists "$target"; then
                tomdot_log "DEBUG" "Validation passed: Command available - $target"
                return 0
            else
                tomdot_log "ERROR" "Validation failed: Command not available - $target"
                return 1
            fi
            ;;
        "symlink_valid")
            if [[ -L "$target" && -e "$target" ]]; then
                tomdot_log "DEBUG" "Validation passed: Valid symlink - $target"
                return 0
            else
                tomdot_log "ERROR" "Validation failed: Invalid symlink - $target"
                return 1
            fi
            ;;
        *)
            tomdot_log "WARNING" "Unknown validation type: $operation_type"
            return 1
            ;;
    esac
}

# Enhanced installation validation with detailed reporting
tomdot_validate_installation() {
    local validation_errors=()
    local validation_warnings=()

    printf "${C_DIM}│${C_RESET} ${C_CYAN}◇${C_RESET} Validating installation...\n"

    # Check key files exist
    local expected_files=(
        "$HOME/.zshrc"
        "$HOME/.gitconfig"
        "$HOME/.config/ghostty/config"
        "$HOME/.config/bat/bat.conf"
        "$HOME/.config/starship.toml"
    )

    for file in "${expected_files[@]}"; do
        if tomdot_validate_operation "file_exists" "$file"; then
            :  # Silent success
        else
            printf "${C_DIM}│${C_RESET} ${C_RED}◇${C_RESET} File %s missing\n" "$(basename "$file")"
            validation_errors+=("Missing file: $file")
        fi
    done

    # Check key tools are available
    local expected_tools=("brew" "git" "node")

    for tool in "${expected_tools[@]}"; do
        if tomdot_validate_operation "command_available" "$tool"; then
            :  # Silent success
        else
            printf "${C_DIM}│${C_RESET} ${C_RED}◇${C_RESET} Tool %s missing\n" "$tool"
            validation_errors+=("Missing tool: $tool")
        fi
    done

    # Check symlinks - all symlinks created during installation
    local expected_symlinks=(
        "$HOME/.config/bat/bat.conf"
        "$HOME/.gitconfig"
        "$HOME/.gitignore_global"
        "$HOME/.config/starship.toml"
        "$HOME/.config/ghostty"
        "$HOME/.zshrc"
        "$HOME/.zprofile"
    )

    for symlink in "${expected_symlinks[@]}"; do
        if tomdot_validate_operation "symlink_valid" "$symlink"; then
            :  # Silent success
        else
            printf "${C_DIM}│${C_RESET} ${C_YELLOW}◇${C_RESET} Symlink %s issue\n" "$(basename "$symlink")"
            validation_warnings+=("Symlink issue: $symlink")
        fi
    done

    # Report results
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        tomdot_log "ERROR" "Installation validation failed with ${#validation_errors[@]} errors"
        for error in "${validation_errors[@]}"; do
            tomdot_log "ERROR" "  - $error"
        done
        return 1
    fi

    if [[ ${#validation_warnings[@]} -gt 0 ]]; then
        tomdot_log "WARNING" "Installation validation completed with ${#validation_warnings[@]} warnings"
        for warning in "${validation_warnings[@]}"; do
            tomdot_log "WARNING" "  - $warning"
        done
    fi

    tomdot_log "INFO" "Installation validation completed successfully"
    return 0
}

# =============================================================================
# EXPORT FUNCTIONS
# =============================================================================

# Core utility functions
export -f tomdot_command_exists
export -f tomdot_check_network
export -f tomdot_log
export -f tomdot_backup_file
export -f tomdot_cleanup
export -f tomdot_show_system_info

# Validation functions
export -f tomdot_check_prerequisites
export -f tomdot_check_tool_functionality
export -f tomdot_validate_symlinks
export -f tomdot_validate_ssh_setup
export -f tomdot_validate_github_auth
export -f tomdot_validate_homebrew
export -f tomdot_validate_installation

# Configuration management functions
export -f tomdot_get_config_type
export -f tomdot_check_config_status
export -f tomdot_detect_conflicts
export -f tomdot_resolve_conflicts
export -f tomdot_deploy_config_file
export -f tomdot_deploy_all_configs
export -f tomdot_validate_configs

# Recovery and rollback functions
export -f tomdot_is_critical_step
export -f tomdot_save_rollback_info
export -f tomdot_get_rollback_info
export -f tomdot_rollback_step
export -f tomdot_recover_from_failure

# Error handling and retry functions
export -f tomdot_categorize_error
export -f tomdot_retry_network_operation
export -f tomdot_retry_file_operation
export -f tomdot_handle_error
export -f tomdot_validate_operation
