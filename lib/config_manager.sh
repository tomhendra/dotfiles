#!/usr/bin/env bash

# Configuration Management for Resilient Installation
# Handles configuration file deployment, conflict resolution, and merging

# Source dependencies
if [ -f "$(dirname "${BASH_SOURCE[0]}")/interactive.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/interactive.sh"
elif [ -f "lib/interactive.sh" ]; then
    source "lib/interactive.sh"
fi

if [ -f "$(dirname "${BASH_SOURCE[0]}")/state.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/state.sh"
elif [ -f "lib/state.sh" ]; then
    source "lib/state.sh"
fi

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

# Get configuration type for a file
get_config_type() {
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
check_config_status() {
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

# Deploy a single configuration file with conflict resolution
deploy_config_file() {
    local source_file="$1"
    local target_file="$2"
    local force_mode="${3:-false}"

    # Ensure target directory exists
    local target_dir=$(dirname "$target_file")
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
        log_operation "Created directory: $target_dir" "info"
    fi

    local status=$(check_config_status "$source_file" "$target_file")
    local config_type=$(get_config_type "$target_file")

    case "$status" in
        "new")
            log_operation "Deploying new configuration: $target_file" "info"
            cp "$source_file" "$target_file"
            return 0
            ;;
        "identical")
            log_operation "Configuration up to date: $target_file" "info"
            return 0
            ;;
        "source_missing")
            log_operation "Source file missing: $source_file" "error"
            return 1
            ;;
        "outdated"|"modified")
            if [[ "$force_mode" == "true" ]]; then
                # Force mode: backup and replace
                local backup_file="${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
                cp "$target_file" "$backup_file"
                cp "$source_file" "$target_file"
                log_operation "Force replaced $target_file (backup: $backup_file)" "info"
                return 0
            fi

            # Interactive conflict resolution
            local resolution=$(handle_config_conflict "$target_file" "$source_file" "$config_type")

            case "$resolution" in
                "replace")
                    local backup_file="${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
                    cp "$target_file" "$backup_file"
                    cp "$source_file" "$target_file"
                    log_operation "Replaced $target_file (backup: $backup_file)" "info"
                    return 0
                    ;;
                "merge")
                    local temp_merged=$(mktemp)
                    merge_configurations "$target_file" "$source_file" "$temp_merged" "$config_type"
                    mv "$temp_merged" "$target_file"
                    log_operation "Merged configuration: $target_file" "info"
                    return 0
                    ;;
                "skip")
                    log_operation "Skipped configuration: $target_file" "info"
                    return 0
                    ;;
                "diff")
                    show_config_diff "$target_file" "$source_file" "$config_type"
                    # Recurse to get new decision after showing diff
                    deploy_config_file "$source_file" "$target_file" "$force_mode"
                    return $?
                    ;;
                "manual")
                    echo
                    print_color "$COLOR_BOLD$COLOR_BLUE" "🛠️  Manual Resolution Required"
                    echo
                    print_color "$COLOR_BLUE" "   Target file: $target_file"
                    print_color "$COLOR_BLUE" "   Source file: $source_file"
                    echo
                    print_color "$COLOR_YELLOW" "   Please resolve the conflict manually and re-run the installation."
                    return 1
                    ;;
            esac
            ;;
    esac
}

# Deploy all configuration files
deploy_all_configs() {
    local dotfiles_dir="${1:-$HOME/.dotfiles}"
    local force_mode="${2:-false}"
    local failed_configs=()

    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "📁 Deploying Configuration Files"
    echo

    for source_rel in "${!CONFIG_MAPPINGS[@]}"; do
        local source_file="$dotfiles_dir/$source_rel"
        local target_file="${CONFIG_MAPPINGS[$source_rel]}"

        if [[ ! -f "$source_file" ]]; then
            log_operation "Source file not found: $source_file" "warn"
            continue
        fi

        print_color "$COLOR_BLUE" "   Processing: $(basename "$target_file")"

        if ! deploy_config_file "$source_file" "$target_file" "$force_mode"; then
            failed_configs+=("$target_file")
            print_color "$COLOR_RED" "   ❌ Failed: $(basename "$target_file")"
        else
            print_color "$COLOR_GREEN" "   ✅ Success: $(basename "$target_file")"
        fi
    done

    echo

    if [[ ${#failed_configs[@]} -gt 0 ]]; then
        print_color "$COLOR_BOLD$COLOR_RED" "❌ Configuration Deployment Issues"
        echo
        for config in "${failed_configs[@]}"; do
            print_color "$COLOR_RED" "   - $config"
        done
        echo
        return 1
    else
        print_color "$COLOR_BOLD$COLOR_GREEN" "✅ All Configurations Deployed Successfully"
        echo
        return 0
    fi
}

# Validate deployed configurations
validate_configs() {
    local validation_errors=()

    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🔍 Validating Configuration Files"
    echo

    for source_rel in "${!CONFIG_MAPPINGS[@]}"; do
        local target_file="${CONFIG_MAPPINGS[$source_rel]}"
        local config_name=$(basename "$target_file")

        printf "   Checking %s... " "$config_name"

        if [[ ! -f "$target_file" ]]; then
            print_color "$COLOR_RED" "❌ Missing"
            validation_errors+=("$target_file: File not found")
            echo
            continue
        fi

        # Basic validation based on file type
        local config_type=$(get_config_type "$target_file")
        local validation_result=""

        case "$config_type" in
            "json")
                if command -v jq >/dev/null 2>&1; then
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
            print_color "$COLOR_GREEN" "✅ $validation_result"
        else
            print_color "$COLOR_RED" "❌ $validation_result"
            validation_errors+=("$target_file: $validation_result")
        fi
        echo
    done

    echo

    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        print_color "$COLOR_BOLD$COLOR_RED" "❌ Configuration Validation Errors"
        echo
        for error in "${validation_errors[@]}"; do
            print_color "$COLOR_RED" "   - $error"
        done
        echo
        return 1
    else
        print_color "$COLOR_BOLD$COLOR_GREEN" "✅ All Configurations Valid"
        echo
        return 0
    fi
}

# Create configuration backup
backup_configs() {
    local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    local backed_up_files=()

    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "💾 Creating Configuration Backup"
    echo

    mkdir -p "$backup_dir"

    for target_file in "${CONFIG_MAPPINGS[@]}"; do
        if [[ -f "$target_file" ]]; then
            local backup_path="$backup_dir/$(basename "$target_file")"
            cp "$target_file" "$backup_path"
            backed_up_files+=("$(basename "$target_file")")
            print_color "$COLOR_GREEN" "   ✅ Backed up: $(basename "$target_file")"
        fi
    done

    echo

    if [[ ${#backed_up_files[@]} -gt 0 ]]; then
        print_color "$COLOR_BOLD$COLOR_GREEN" "✅ Backup Created: $backup_dir"
        echo
        print_color "$COLOR_GRAY" "   Files backed up: ${#backed_up_files[@]}"
        echo "$backup_dir"
    else
        rmdir "$backup_dir" 2>/dev/null
        print_color "$COLOR_YELLOW" "⚠️  No existing configurations to backup"
        echo
    fi
}

# Restore configuration from backup
restore_configs() {
    local backup_dir="$1"

    if [[ ! -d "$backup_dir" ]]; then
        log_operation "Backup directory not found: $backup_dir" "error"
        return 1
    fi

    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🔄 Restoring Configuration Backup"
    echo
    print_color "$COLOR_YELLOW" "   Source: $backup_dir"
    echo

    local confirm=$(prompt_yes_no "This will overwrite current configurations. Continue?" "n")
    if [[ "$confirm" != "y" ]]; then
        print_color "$COLOR_YELLOW" "   ❌ Restore cancelled"
        return 1
    fi

    local restored_files=()

    for target_file in "${CONFIG_MAPPINGS[@]}"; do
        local backup_file="$backup_dir/$(basename "$target_file")"

        if [[ -f "$backup_file" ]]; then
            cp "$backup_file" "$target_file"
            restored_files+=("$(basename "$target_file")")
            print_color "$COLOR_GREEN" "   ✅ Restored: $(basename "$target_file")"
        fi
    done

    echo

    if [[ ${#restored_files[@]} -gt 0 ]]; then
        print_color "$COLOR_BOLD$COLOR_GREEN" "✅ Configurations Restored"
        echo
        print_color "$COLOR_GRAY" "   Files restored: ${#restored_files[@]}"
    else
        print_color "$COLOR_YELLOW" "⚠️  No files were restored"
    fi

    echo
}

# Export functions for use in other scripts
export -f deploy_config_file
export -f deploy_all_configs
export -f validate_configs
export -f backup_configs
export -f restore_configs
export -f check_config_status
export -f get_config_type
