#!/bin/bash

# Step Definition
STEP_ID="nodejs"
STEP_NAME="Install Node.js and Package Managers"
STEP_DESCRIPTION="Installs Node.js via fnm and enables Corepack for pnpm/yarn"
STEP_DEPENDENCIES=("prerequisites" "homebrew")
STEP_ESTIMATED_TIME=120  # seconds
STEP_CATEGORY="language_runtime"
STEP_CRITICAL=true

# Source required libraries
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh"
elif [ -f "lib/progress.sh" ]; then
    source "lib/progress.sh"
fi

# Configuration
NODE_VERSION="22"
DOTFILES_DIR="${HOME}/.dotfiles"
GLOBAL_PACKAGES_SCRIPT="${DOTFILES_DIR}/global_pkg.sh"

execute_nodejs_step() {
    log_operation "Starting Node.js installation and setup" "info"

    # Setup fnm environment
    if ! setup_fnm_environment; then
        return 1
    fi

    # Install Node.js
    if ! install_nodejs; then
        return 1
    fi

    # Enable Corepack
    if ! enable_corepack; then
        return 1
    fi

    # Install global packages
    if ! install_global_packages; then
        return 1
    fi

    log_operation "Node.js installation and setup completed successfully" "success"
    return 0
}

setup_fnm_environment() {
    log_operation "Setting up fnm environment" "info"

    # Verify fnm is installed (should be from Homebrew)
    if ! command -v fnm >/dev/null 2>&1; then
        log_operation "fnm not found, it should be installed via Homebrew" "error"
        echo "Please ensure Homebrew packages are installed first"
        return 1
    fi

    # Setup fnm environment for current session
    export PATH="/opt/homebrew/bin:${PATH}"
    eval "$(fnm env --use-on-cd)"

    log_operation "fnm environment configured" "success"
    return 0
}

install_nodejs() {
    log_operation "Installing Node.js version $NODE_VERSION" "info"

    # Check if Node.js version is already installed
    if fnm list | grep -q "v$NODE_VERSION"; then
        log_operation "Node.js $NODE_VERSION is already installed" "info"
        fnm use "$NODE_VERSION"
        fnm default "$NODE_VERSION"
        return 0
    fi

    # Install Node.js with retry logic
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        log_operation "Node.js installation attempt $attempt/$max_attempts" "info"

        if fnm install "$NODE_VERSION"; then
            log_operation "Node.js $NODE_VERSION installed successfully" "success"

            # Set as default version
            fnm use "$NODE_VERSION"
            fnm default "$NODE_VERSION"

            return 0
        fi

        log_operation "Node.js installation attempt $attempt failed" "warning"
        attempt=$((attempt + 1))

        if [ $attempt -le $max_attempts ]; then
            log_operation "Retrying in 10 seconds..." "info"
            sleep 10
        fi
    done

    log_operation "Failed to install Node.js after $max_attempts attempts" "error"
    echo "Please check your internet connection and try again"
    return 1
}

enable_corepack() {
    log_operation "Enabling Corepack for package manager support" "info"

    # Verify Node.js is available
    if ! command -v node >/dev/null 2>&1; then
        log_operation "Node.js not found, cannot enable Corepack" "error"
        return 1
    fi

    # Enable Corepack
    if ! corepack enable; then
        log_operation "Failed to enable Corepack" "error"
        return 1
    fi

    # Enable specific package managers
    if ! corepack enable pnpm; then
        log_operation "Failed to enable pnpm via Corepack" "warning"
        # Continue as this is not critical
    fi

    if ! corepack enable yarn; then
        log_operation "Failed to enable yarn via Corepack" "warning"
        # Continue as this is not critical
    fi

    log_operation "Corepack enabled successfully" "success"
    return 0
}

install_global_packages() {
    log_operation "Installing global Node.js packages" "info"

    # Verify global packages script exists
    if [ ! -f "$GLOBAL_PACKAGES_SCRIPT" ]; then
        log_operation "Global packages script not found: $GLOBAL_PACKAGES_SCRIPT" "error"
        echo "Please ensure the dotfiles repository is cloned first"
        return 1
    fi

    # Make script executable
    chmod +x "$GLOBAL_PACKAGES_SCRIPT"

    # Run global packages installation with retry logic
    local max_attempts=2
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        log_operation "Installing global packages (attempt $attempt/$max_attempts)" "info"

        if sh "$GLOBAL_PACKAGES_SCRIPT"; then
            log_operation "Global packages installed successfully" "success"
            return 0
        fi

        log_operation "Global packages installation attempt $attempt failed" "warning"
        attempt=$((attempt + 1))

        if [ $attempt -le $max_attempts ]; then
            log_operation "Retrying in 15 seconds..." "info"
            sleep 15
        fi
    done

    log_operation "Failed to install global packages after $max_attempts attempts" "error"
    echo "You can install global packages manually by running: $GLOBAL_PACKAGES_SCRIPT"
    return 1
}

validate_nodejs_step() {
    log_operation "Validating Node.js installation" "info"

    # Check if Node.js is available
    if ! command -v node >/dev/null 2>&1; then
        log_operation "Node.js command not found" "error"
        return 1
    fi

    # Check if npm is available
    if ! command -v npm >/dev/null 2>&1; then
        log_operation "npm command not found" "error"
        return 1
    fi

    # Verify Node.js version
    local node_version
    node_version=$(node --version 2>/dev/null | sed 's/v//')

    if [[ ! "$node_version" =~ ^$NODE_VERSION\. ]]; then
        log_operation "Node.js version mismatch. Expected: $NODE_VERSION.x, Found: $node_version" "error"
        return 1
    fi

    # Check if Corepack is enabled
    if ! command -v corepack >/dev/null 2>&1; then
        log_operation "Corepack not found" "error"
        return 1
    fi

    # Verify some global packages are installed
    local key_packages=("pnpm" "yarn")
    local missing_packages=()

    for package in "${key_packages[@]}"; do
        if ! command -v "$package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_operation "Missing key packages: ${missing_packages[*]}" "warning"
        # This is not critical, continue
    fi

    log_operation "Node.js installation validation successful" "success"
    return 0
}

rollback_nodejs_step() {
    log_operation "Rolling back Node.js installation" "info"

    # Remove installed Node.js version
    if command -v fnm >/dev/null 2>&1; then
        log_operation "Removing Node.js $NODE_VERSION via fnm" "info"
        fnm uninstall "$NODE_VERSION" 2>/dev/null || true
    fi

    # Note: We don't remove fnm itself as it was installed via Homebrew
    # and might be used for other Node.js versions

    log_operation "Node.js installation rollback completed" "info"
    echo "Note: fnm and global packages were not removed."
    echo "To completely clean up:"
    echo "1. Remove Node.js versions: fnm uninstall <version>"
    echo "2. Remove global packages manually if needed"

    return 0
}
