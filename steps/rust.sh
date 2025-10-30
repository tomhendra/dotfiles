#!/bin/bash

# Step Definition
STEP_ID="rust"
STEP_NAME="Install Rust Toolchain"
STEP_DESCRIPTION="Installs Rust programming language and toolchain via rustup"
STEP_DEPENDENCIES=("prerequisites" "homebrew")
STEP_ESTIMATED_TIME=180  # seconds
STEP_CATEGORY="language_runtime"
STEP_CRITICAL=false

# Source required libraries
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh"
elif [ -f "lib/progress.sh" ]; then
    source "lib/progress.sh"
fi

# Configuration
RUST_INSTALL_URL="https://sh.rustup.rs"
CARGO_ENV_FILE="${HOME}/.cargo/env"

execute_rust_step() {
    log_operation "Starting Rust toolchain installation" "info"

    # Check if Rust is already installed
    if check_existing_rust_installation; then
        log_operation "Rust is already installed, skipping installation" "info"
        return 0
    fi

    # Install Rust
    if ! install_rust; then
        return 1
    fi

    # Setup Rust environment
    if ! setup_rust_environment; then
        return 1
    fi

    # Verify installation
    if ! verify_rust_installation; then
        return 1
    fi

    log_operation "Rust toolchain installation completed successfully" "success"
    return 0
}

check_existing_rust_installation() {
    log_operation "Checking for existing Rust installation" "info"

    # Check if rustc is available
    if command -v rustc >/dev/null 2>&1; then
        local rust_version
        rust_version=$(rustc --version 2>/dev/null)
        log_operation "Found existing Rust installation: $rust_version" "success"
        return 0
    fi

    # Check if cargo is available (alternative check)
    if command -v cargo >/dev/null 2>&1; then
        local cargo_version
        cargo_version=$(cargo --version 2>/dev/null)
        log_operation "Found existing Cargo installation: $cargo_version" "success"
        return 0
    fi

    log_operation "No existing Rust installation found" "info"
    return 1
}

install_rust() {
    log_operation "Installing Rust via rustup" "info"

    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        log_operation "Rust installation attempt $attempt/$max_attempts" "info"

        # Download and run rustup installer
        if curl --proto '=https' --tlsv1.2 -sSf "$RUST_INSTALL_URL" | sh -s -- -y; then
            log_operation "Rust installed successfully" "success"
            return 0
        fi

        log_operation "Rust installation attempt $attempt failed" "warning"
        attempt=$((attempt + 1))

        if [ $attempt -le $max_attempts ]; then
            log_operation "Retrying in 10 seconds..." "info"
            sleep 10
        fi
    done

    log_operation "Failed to install Rust after $max_attempts attempts" "error"
    echo "Please check your internet connection and try again"
    echo "You can also install Rust manually from: https://rustup.rs"
    return 1
}

setup_rust_environment() {
    log_operation "Setting up Rust environment" "info"

    # Source Cargo environment for current session
    if [ -f "$CARGO_ENV_FILE" ]; then
        # shellcheck source=/dev/null
        source "$CARGO_ENV_FILE"
        log_operation "Rust environment loaded for current session" "success"
    else
        log_operation "Cargo environment file not found: $CARGO_ENV_FILE" "error"
        return 1
    fi

    return 0
}

verify_rust_installation() {
    log_operation "Verifying Rust installation" "info"

    # Verify rustc is available
    if ! command -v rustc >/dev/null 2>&1; then
        log_operation "rustc command not found after installation" "error"
        return 1
    fi

    # Verify cargo is available
    if ! command -v cargo >/dev/null 2>&1; then
        log_operation "cargo command not found after installation" "error"
        return 1
    fi

    # Get versions
    local rustc_version cargo_version
    rustc_version=$(rustc --version 2>/dev/null)
    cargo_version=$(cargo --version 2>/dev/null)

    log_operation "Rust installation verified: $rustc_version" "success"
    log_operation "Cargo installation verified: $cargo_version" "success"

    return 0
}

validate_rust_step() {
    log_operation "Validating Rust installation" "info"

    # Check if Rust commands are available
    if ! command -v rustc >/dev/null 2>&1 || ! command -v cargo >/dev/null 2>&1; then
        log_operation "Rust tools not found" "error"
        return 1
    fi

    # Test basic functionality
    if ! rustc --version >/dev/null 2>&1; then
        log_operation "rustc is not working properly" "error"
        return 1
    fi

    if ! cargo --version >/dev/null 2>&1; then
        log_operation "cargo is not working properly" "error"
        return 1
    fi

    log_operation "Rust installation validation successful" "success"
    return 0
}

rollback_rust_step() {
    log_operation "Rolling back Rust installation" "info"

    # Remove Rust installation using rustup
    if command -v rustup >/dev/null 2>&1; then
        log_operation "Removing Rust toolchain via rustup" "info"
        rustup self uninstall -y 2>/dev/null || true
    fi

    # Remove Cargo directory
    if [ -d "${HOME}/.cargo" ]; then
        log_operation "Removing Cargo directory" "info"
        rm -rf "${HOME}/.cargo" 2>/dev/null || true
    fi

    # Remove Rustup directory
    if [ -d "${HOME}/.rustup" ]; then
        log_operation "Removing Rustup directory" "info"
        rm -rf "${HOME}/.rustup" 2>/dev/null || true
    fi

    log_operation "Rust installation rollback completed" "info"
    return 0
}
