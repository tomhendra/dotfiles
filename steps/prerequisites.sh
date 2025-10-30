#!/bin/bash

# Step Definition
STEP_ID="prerequisites"
STEP_NAME="Validate System Prerequisites"
STEP_DESCRIPTION="Validates system requirements, macOS version, disk space, and permissions"
STEP_DEPENDENCIES=()
STEP_ESTIMATED_TIME=30  # seconds
STEP_CATEGORY="validation"
STEP_CRITICAL=true

# Source required libraries
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh"
elif [ -f "lib/progress.sh" ]; then
    source "lib/progress.sh"
fi

# Minimum requirements
MIN_MACOS_VERSION="12.0"  # macOS Monterey
MIN_DISK_SPACE_GB=10
REQUIRED_TOOLS=("git" "curl" "osascript" "xcode-select")

execute_prerequisites_step() {
    log_operation "Starting prerequisite validation" "info"

    # Check macOS version
    if ! validate_macos_version; then
        return 1
    fi

    # Check disk space
    if ! validate_disk_space; then
        return 1
    fi

    # Check required tools
    if ! validate_required_tools; then
        return 1
    fi

    # Check permissions
    if ! validate_permissions; then
        return 1
    fi

    # Check Xcode Command Line Tools
    if ! validate_xcode_tools; then
        return 1
    fi

    log_operation "All prerequisites validated successfully" "success"
    return 0
}

validate_macos_version() {
    log_operation "Checking macOS version compatibility" "info"

    local current_version
    current_version=$(sw_vers -productVersion)

    if ! version_compare "$current_version" "$MIN_MACOS_VERSION"; then
        log_operation "macOS version $current_version is below minimum required version $MIN_MACOS_VERSION" "error"
        echo "Please upgrade to macOS $MIN_MACOS_VERSION or later"
        return 1
    fi

    log_operation "macOS version $current_version meets requirements" "success"
    return 0
}

validate_disk_space() {
    log_operation "Checking available disk space" "info"

    local available_space_kb
    available_space_kb=$(df -k "$HOME" | awk 'NR==2 {print $4}')
    local available_space_gb=$((available_space_kb / 1024 / 1024))

    if [ "$available_space_gb" -lt "$MIN_DISK_SPACE_GB" ]; then
        log_operation "Insufficient disk space: ${available_space_gb}GB available, ${MIN_DISK_SPACE_GB}GB required" "error"
        echo "Please free up disk space and try again"
        return 1
    fi

    log_operation "Sufficient disk space available: ${available_space_gb}GB" "success"
    return 0
}

validate_required_tools() {
    log_operation "Checking required command-line tools" "info"

    local missing_tools=()

    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_operation "Missing required tools: ${missing_tools[*]}" "error"
        echo "Please install the following tools and try again:"
        for tool in "${missing_tools[@]}"; do
            case "$tool" in
                "git")
                    echo "  - Install Xcode Command Line Tools: xcode-select --install"
                    ;;
                "curl")
                    echo "  - curl should be pre-installed on macOS"
                    ;;
                "osascript")
                    echo "  - osascript should be pre-installed on macOS"
                    ;;
                "xcode-select")
                    echo "  - Install Xcode Command Line Tools from App Store or developer.apple.com"
                    ;;
                *)
                    echo "  - $tool: Please install manually"
                    ;;
            esac
        done
        return 1
    fi

    log_operation "All required tools are available" "success"
    return 0
}

validate_permissions() {
    log_operation "Checking system permissions" "info"

    # Check if we can write to home directory
    if [ ! -w "$HOME" ]; then
        log_operation "Cannot write to home directory: $HOME" "error"
        echo "Please ensure you have write permissions to your home directory"
        return 1
    fi

    # Check if we can create directories in home
    local test_dir="$HOME/.dotfiles_test_$$"
    if ! mkdir -p "$test_dir" 2>/dev/null; then
        log_operation "Cannot create directories in home directory" "error"
        echo "Please ensure you have permissions to create directories in $HOME"
        return 1
    fi
    rmdir "$test_dir" 2>/dev/null || true

    # Test sudo access (will prompt if needed)
    log_operation "Verifying sudo access (may prompt for password)" "info"
    if ! sudo -v; then
        log_operation "Cannot obtain sudo privileges" "error"
        echo "Administrator privileges are required for this installation"
        return 1
    fi

    log_operation "System permissions validated" "success"
    return 0
}

validate_xcode_tools() {
    log_operation "Checking Xcode Command Line Tools installation" "info"

    if ! xcode-select -p &>/dev/null; then
        log_operation "Xcode Command Line Tools not installed" "error"
        echo "Please install Xcode Command Line Tools:"
        echo "  1. Run: xcode-select --install"
        echo "  2. Follow the installation prompts"
        echo "  3. Run this script again"
        return 1
    fi

    local xcode_path
    xcode_path=$(xcode-select -p)
    log_operation "Xcode Command Line Tools found at: $xcode_path" "success"

    # Accept Xcode license if needed
    if ! sudo xcodebuild -checkFirstLaunchStatus &>/dev/null; then
        log_operation "Accepting Xcode license agreement" "info"
        if ! sudo xcodebuild -license accept; then
            log_operation "Failed to accept Xcode license" "error"
            return 1
        fi
    fi

    return 0
}

validate_prerequisites_step() {
    execute_prerequisites_step
}

rollback_prerequisites_step() {
    # Prerequisites validation doesn't modify system state, so no rollback needed
    log_operation "No rollback needed for prerequisites validation" "info"
    return 0
}

# Helper function to compare version numbers
version_compare() {
    local version1=$1
    local version2=$2

    # Convert versions to comparable format (remove dots, pad with zeros)
    local v1_num v2_num
    v1_num=$(echo "$version1" | sed 's/\.//g' | sed 's/$/000/' | cut -c1-6)
    v2_num=$(echo "$version2" | sed 's/\.//g' | sed 's/$/000/' | cut -c1-6)

    [ "$v1_num" -ge "$v2_num" ]
}
