#!/bin/bash

# Step Definition
STEP_ID="configurations"
STEP_NAME="Setup Configurations and Symlinks"
STEP_DESCRIPTION="Creates configuration files and symlinks for development tools"
STEP_DEPENDENCIES=("prerequisites" "homebrew" "nodejs")
STEP_ESTIMATED_TIME=60  # seconds
STEP_CATEGORY="configuration"
STEP_CRITICAL=true

# Source required libraries
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh"
elif [ -f "lib/progress.sh" ]; then
    source "lib/progress.sh"
fi

# Configuration
DOTFILES_DIR="${HOME}/.dotfiles"
CONFIG_DIR="${HOME}/.config"
CONFIG_BACKUP_DIR="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

execute_configurations_step() {
    log_operation "Starting configuration setup and symlink creation" "info"

    # Verify dotfiles directory exists
    if ! verify_dotfiles_directory; then
        return 1
    fi

    # Setup configuration directories
    if ! setup_config_directories; then
        return 1
    fi

    # Setup Starship configuration
    if ! setup_starship_config; then
        return 1
    fi

    # Setup bat configuration
    if ! setup_bat_config; then
        return 1
    fi

    # Create symlinks
    if ! create_symlinks; then
        return 1
    fi

    log_operation "Configuration setup and symlink creation completed successfully" "success"
    return 0
}

verify_dotfiles_directory() {
    log_operation "Verifying dotfiles directory" "info"

    if [ ! -d "$DOTFILES_DIR" ]; then
        log_operation "Dotfiles directory not found: $DOTFILES_DIR" "error"
        echo "Please ensure the dotfiles repository is cloned first"
        return 1
    fi

    log_operation "Dotfiles directory found: $DOTFILES_DIR" "success"
    return 0
}

setup_config_directories() {
    log_operation "Setting up configuration directories" "info"

    # Create .config directory if it doesn't exist
    if [ ! -d "$CONFIG_DIR" ]; then
        if ! mkdir -p "$CONFIG_DIR"; then
            log_operation "Failed to create config directory: $CONFIG_DIR" "error"
            return 1
        fi
        log_operation "Created config directory: $CONFIG_DIR" "success"
    else
        log_operation "Config directory already exists: $CONFIG_DIR" "info"
    fi

    return 0
}

setup_starship_config() {
    log_operation "Setting up Starship configuration" "info"

    local starship_source="${DOTFILES_DIR}/starship.toml"
    local starship_target="${CONFIG_DIR}/starship.toml"

    # Verify source file exists
    if [ ! -f "$starship_source" ]; then
        log_operation "Starship config source not found: $starship_source" "error"
        return 1
    fi

    # Backup existing config if it exists
    if [ -f "$starship_target" ]; then
        backup_file "$starship_target"
    fi

    # Copy Starship configuration
    if ! cp "$starship_source" "$starship_target"; then
        log_operation "Failed to copy Starship configuration" "error"
        return 1
    fi

    log_operation "Starship configuration setup completed" "success"
    return 0
}

setup_bat_config() {
    log_operation "Setting up bat configuration" "info"

    # Get bat config directory
    local bat_config_dir
    if command -v bat >/dev/null 2>&1; then
        bat_config_dir=$(bat --config-dir 2>/dev/null)
    else
        log_operation "bat command not found, skipping bat configuration" "warning"
        return 0
    fi

    if [ -z "$bat_config_dir" ]; then
        log_operation "Could not determine bat config directory" "error"
        return 1
    fi

    # Create bat config and themes directories
    mkdir -p "$bat_config_dir/themes"

    # Setup bat theme
    local theme_source="${DOTFILES_DIR}/bat/themes/Enki-Tokyo-Night.tmTheme"
    local theme_target="${bat_config_dir}/themes/Enki-Tokyo-Night.tmTheme"

    if [ -f "$theme_source" ]; then
        if ! cp "$theme_source" "$theme_target"; then
            log_operation "Failed to copy bat theme" "error"
            return 1
        fi
        log_operation "bat theme installed" "success"
    else
        log_operation "bat theme source not found: $theme_source" "warning"
    fi

    # Setup bat configuration
    local config_source="${DOTFILES_DIR}/bat/bat.conf"
    local config_target="${bat_config_dir}/bat.conf"

    if [ -f "$config_source" ]; then
        # Backup existing config
        if [ -f "$config_target" ]; then
            backup_file "$config_target"
        fi

        if ! cp "$config_source" "$config_target"; then
            log_operation "Failed to copy bat configuration" "error"
            return 1
        fi
        log_operation "bat configuration installed" "success"
    else
        log_operation "bat config source not found: $config_source" "warning"
    fi

    # Build bat cache
    if ! bat cache --build >/dev/null 2>&1; then
        log_operation "Failed to build bat cache (non-critical)" "warning"
    else
        log_operation "bat cache built successfully" "success"
    fi

    return 0
}

create_symlinks() {
    log_operation "Creating symlinks from dotfiles" "info"

    local symlink_script="${DOTFILES_DIR}/create_symlinks.sh"

    # Verify symlink script exists
    if [ ! -f "$symlink_script" ]; then
        log_operation "Symlink script not found: $symlink_script" "error"
        return 1
    fi

    # Make script executable
    chmod +x "$symlink_script"

    # Run symlink creation with conflict detection
    if ! run_symlink_script_with_backup "$symlink_script"; then
        return 1
    fi

    log_operation "Symlinks created successfully" "success"
    return 0
}

run_symlink_script_with_backup() {
    local script_path=$1

    log_operation "Running symlink creation script with backup support" "info"

    # Create backup directory
    mkdir -p "$CONFIG_BACKUP_DIR"

    # Export backup directory for the script to use
    export DOTFILES_BACKUP_DIR="$CONFIG_BACKUP_DIR"

    # Run the symlink script
    if sh "$script_path"; then
        log_operation "Symlink script executed successfully" "success"

        # Check if any backups were created
        if [ -n "$(ls -A "$CONFIG_BACKUP_DIR" 2>/dev/null)" ]; then
            log_operation "Existing configurations backed up to: $CONFIG_BACKUP_DIR" "info"
        else
            # Remove empty backup directory
            rmdir "$CONFIG_BACKUP_DIR" 2>/dev/null || true
        fi

        return 0
    else
        log_operation "Symlink script failed" "error"
        return 1
    fi
}

backup_file() {
    local file_path=$1
    local backup_path="${CONFIG_BACKUP_DIR}/$(basename "$file_path").$(date +%Y%m%d_%H%M%S)"

    # Create backup directory if it doesn't exist
    mkdir -p "$CONFIG_BACKUP_DIR"

    if cp "$file_path" "$backup_path" 2>/dev/null; then
        log_operation "Backed up existing file: $file_path -> $backup_path" "info"
    else
        log_operation "Failed to backup file: $file_path" "warning"
    fi
}

validate_configurations_step() {
    log_operation "Validating configuration setup" "info"

    # Check Starship configuration
    local starship_config="${CONFIG_DIR}/starship.toml"
    if [ ! -f "$starship_config" ]; then
        log_operation "Starship configuration not found: $starship_config" "error"
        return 1
    fi

    # Check bat configuration (if bat is available)
    if command -v bat >/dev/null 2>&1; then
        local bat_config_dir
        bat_config_dir=$(bat --config-dir 2>/dev/null)

        if [ -n "$bat_config_dir" ] && [ ! -f "$bat_config_dir/bat.conf" ]; then
            log_operation "bat configuration not found" "warning"
            # Not critical, continue
        fi
    fi

    # Verify some key symlinks exist
    local key_symlinks=("${HOME}/.zshrc" "${HOME}/.gitconfig")
    local missing_symlinks=()

    for symlink in "${key_symlinks[@]}"; do
        if [ ! -L "$symlink" ] && [ ! -f "$symlink" ]; then
            missing_symlinks+=("$symlink")
        fi
    done

    if [ ${#missing_symlinks[@]} -gt 0 ]; then
        log_operation "Missing key configuration files: ${missing_symlinks[*]}" "error"
        return 1
    fi

    log_operation "Configuration setup validation successful" "success"
    return 0
}

rollback_configurations_step() {
    log_operation "Rolling back configuration setup" "info"

    # Restore backed up files if backup directory exists
    if [ -d "$CONFIG_BACKUP_DIR" ] && [ -n "$(ls -A "$CONFIG_BACKUP_DIR" 2>/dev/null)" ]; then
        log_operation "Restoring backed up configurations from: $CONFIG_BACKUP_DIR" "info"

        for backup_file in "$CONFIG_BACKUP_DIR"/*; do
            if [ -f "$backup_file" ]; then
                local original_name
                original_name=$(basename "$backup_file" | sed 's/\.[0-9]*_[0-9]*$//')
                local restore_path="${HOME}/${original_name}"

                if cp "$backup_file" "$restore_path" 2>/dev/null; then
                    log_operation "Restored: $restore_path" "info"
                else
                    log_operation "Failed to restore: $restore_path" "warning"
                fi
            fi
        done
    fi

    # Remove created symlinks (run delete script if available)
    local delete_script="${DOTFILES_DIR}/delete_symlinks.sh"
    if [ -f "$delete_script" ]; then
        log_operation "Removing created symlinks" "info"
        chmod +x "$delete_script"
        sh "$delete_script" 2>/dev/null || true
    fi

    # Remove copied configuration files
    rm -f "${CONFIG_DIR}/starship.toml" 2>/dev/null || true

    # Remove bat configuration
    if command -v bat >/dev/null 2>&1; then
        local bat_config_dir
        bat_config_dir=$(bat --config-dir 2>/dev/null)
        if [ -n "$bat_config_dir" ]; then
            rm -f "$bat_config_dir/bat.conf" 2>/dev/null || true
            rm -f "$bat_config_dir/themes/Enki-Tokyo-Night.tmTheme" 2>/dev/null || true
        fi
    fi

    log_operation "Configuration setup rollback completed" "info"
    return 0
}
