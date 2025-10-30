#!/bin/bash

# Step Definition
STEP_ID="homebrew"
STEP_NAME="Install Homebrew and Packages"
STEP_DESCRIPTION="Installs Homebrew package manager and all required packages from Brewfile"
STEP_DEPENDENCIES=("prerequisites" "ssh_setup")
STEP_ESTIMATED_TIME=300  # seconds
STEP_CATEGORY="package_management"
STEP_CRITICAL=true

# Source required libraries
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh"
elif [ -f "lib/progress.sh" ]; then
    source "lib/progress.sh"
fi

# Configuration
HOMEBREW_PREFIX="/opt/homebrew"
HOMEBREW_BIN="${HOMEBREW_PREFIX}/bin/brew"
DOTFILES_DIR="${HOME}/.dotfiles"
BREWFILE_PATH="${DOTFILES_DIR}/Brewfile"

execute_homebrew_step() {
    log_operation "Starting Homebrew installation and package setup" "info"

    # Install Homebrew if not present
    if ! install_homebrew; then
        return 1
    fi

    # Setup Homebrew environment
    if ! setup_homebrew_environment; then
        return 1
    fi

    # Install packages from Brewfile
    if ! install_homebrew_packages; then
        return 1
    fi

    # Cleanup Homebrew
    if ! cleanup_homebrew; then
        return 1
    fi

    log_operation "Homebrew installation and package setup completed successfully" "success"
    return 0
}

install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        log_operation "Homebrew is already installed" "info"
        return 0
    fi

    log_operation "Installing Homebrew package manager" "info"

    # Download and install Homebrew
    local install_script_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        log_operation "Homebrew installation attempt $attempt/$max_attempts" "info"

        if /bin/bash -c "$(curl -fsSL $install_script_url)"; then
            log_operation "Homebrew installed successfully" "success"
            return 0
        fi

        log_operation "Homebrew installation attempt $attempt failed" "warning"
        attempt=$((attempt + 1))

        if [ $attempt -le $max_attempts ]; then
            log_operation "Retrying in 10 seconds..." "info"
            sleep 10
        fi
    done

    log_operation "Failed to install Homebrew after $max_attempts attempts" "error"
    echo "Please check your internet connection and try again"
    echo "You can also install Homebrew manually from: https://brew.sh"
    return 1
}

setup_homebrew_environment() {
    log_operation "Setting up Homebrew environment" "info"

    # Add Homebrew to PATH in .zprofile if not already present
    local zprofile_path="${HOME}/.zprofile"
    local homebrew_env_line='eval "$(/opt/homebrew/bin/brew shellenv)"'

    if [ ! -f "$zprofile_path" ] || ! grep -q "brew shellenv" "$zprofile_path"; then
        log_operation "Adding Homebrew to shell environment" "info"
        echo "" >> "$zprofile_path"
        echo "# Homebrew environment setup" >> "$zprofile_path"
        echo "$homebrew_env_line" >> "$zprofile_path"
    else
        log_operation "Homebrew environment already configured" "info"
    fi

    # Source Homebrew environment for current session
    if [ -f "$HOMEBREW_BIN" ]; then
        eval "$($HOMEBREW_BIN shellenv)"
        log_operation "Homebrew environment loaded for current session" "success"
    else
        log_operation "Homebrew binary not found at expected location: $HOMEBREW_BIN" "error"
        return 1
    fi

    return 0
}

install_homebrew_packages() {
    log_operation "Installing Homebrew packages from Brewfile" "info"

    # Verify Brewfile exists
    if [ ! -f "$BREWFILE_PATH" ]; then
        log_operation "Brewfile not found at: $BREWFILE_PATH" "error"
        echo "Please ensure the dotfiles repository is cloned first"
        return 1
    fi

    # Update Homebrew
    log_operation "Updating Homebrew" "info"
    if ! brew update; then
        log_operation "Failed to update Homebrew" "warning"
        # Continue anyway as this is not critical
    fi

    # Add homebrew/bundle tap if not present
    log_operation "Adding homebrew/bundle tap" "info"
    if ! brew tap homebrew/bundle; then
        log_operation "Failed to add homebrew/bundle tap" "error"
        return 1
    fi

    # Install packages with retry logic
    local max_attempts=2
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        log_operation "Installing packages from Brewfile (attempt $attempt/$max_attempts)" "info"

        if brew bundle --file="$BREWFILE_PATH"; then
            log_operation "Homebrew packages installed successfully" "success"
            return 0
        fi

        log_operation "Package installation attempt $attempt failed" "warning"
        attempt=$((attempt + 1))

        if [ $attempt -le $max_attempts ]; then
            log_operation "Retrying package installation in 15 seconds..." "info"
            sleep 15

            # Try to fix any issues before retry
            log_operation "Running brew doctor to check for issues" "info"
            brew doctor || true
        fi
    done

    log_operation "Failed to install packages after $max_attempts attempts" "error"
    echo "Some packages may have failed to install. You can:"
    echo "1. Run 'brew bundle --file=$BREWFILE_PATH' manually"
    echo "2. Check 'brew doctor' for potential issues"
    echo "3. Install failed packages individually"
    return 1
}

cleanup_homebrew() {
    log_operation "Cleaning up Homebrew" "info"

    # Clean up old versions and cache
    if brew cleanup; then
        log_operation "Homebrew cleanup completed" "success"
    else
        log_operation "Homebrew cleanup failed (non-critical)" "warning"
    fi

    return 0
}

validate_homebrew_step() {
    log_operation "Validating Homebrew installation" "info"

    # Check if Homebrew is installed and accessible
    if ! command -v brew >/dev/null 2>&1; then
        log_operation "Homebrew command not found" "error"
        return 1
    fi

    # Check Homebrew installation
    if ! brew --version >/dev/null 2>&1; then
        log_operation "Homebrew is not working properly" "error"
        return 1
    fi

    # Verify some key packages are installed
    local key_packages=("git" "curl" "fnm")
    local missing_packages=()

    for package in "${key_packages[@]}"; do
        if ! brew list "$package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_operation "Missing key packages: ${missing_packages[*]}" "error"
        return 1
    fi

    # Check if Homebrew environment is properly configured
    if [ -z "${HOMEBREW_PREFIX:-}" ]; then
        log_operation "Homebrew environment not properly configured" "error"
        return 1
    fi

    log_operation "Homebrew installation validation successful" "success"
    return 0
}

rollback_homebrew_step() {
    log_operation "Rolling back Homebrew installation" "info"

    # Note: Complete Homebrew removal is complex and potentially destructive
    # We'll focus on removing what we can safely remove

    # Remove Homebrew environment from .zprofile
    local zprofile_path="${HOME}/.zprofile"
    if [ -f "$zprofile_path" ] && grep -q "brew shellenv" "$zprofile_path"; then
        log_operation "Removing Homebrew environment from .zprofile" "info"

        # Create backup
        cp "$zprofile_path" "${zprofile_path}.backup.$(date +%Y%m%d_%H%M%S)"

        # Remove Homebrew lines
        sed -i '' '/# Homebrew environment setup/,+1d' "$zprofile_path" 2>/dev/null || true
    fi

    # Warn about manual Homebrew removal
    log_operation "Homebrew rollback completed" "info"
    echo "Note: Homebrew packages were not automatically removed."
    echo "To completely remove Homebrew, run:"
    echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\""

    return 0
}
