#!/usr/bin/env bash

# Validation Engine for Resilient Installation
# Provides comprehensive validation of system state and installation completeness

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/state.sh"

# Configuration
readonly VALIDATION_TIMEOUT=30
readonly SYMLINK_CHECK_TIMEOUT=10

# Log levels for validation
readonly VALIDATION_ERROR=1
readonly VALIDATION_WARN=2
readonly VALIDATION_INFO=3
readonly VALIDATION_DEBUG=4

# Current validation log level
VALIDATION_LOG_LEVEL=${VALIDATION_LOG_LEVEL:-$VALIDATION_INFO}

# Validation logging function
validation_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ $level -le $VALIDATION_LOG_LEVEL ]]; then
        case $level in
            $VALIDATION_ERROR) echo "[$timestamp] VALIDATION ERROR: $message" >&2 ;;
            $VALIDATION_WARN)  echo "[$timestamp] VALIDATION WARN:  $message" >&2 ;;
            $VALIDATION_INFO)  echo "[$timestamp] VALIDATION INFO:  $message" ;;
            $VALIDATION_DEBUG) echo "[$timestamp] VALIDATION DEBUG: $message" ;;
        esac
    fi

    # Always log to file if state directory exists
    if [[ -d "$STATE_DIR" ]]; then
        local level_name
        case $level in
            $VALIDATION_ERROR) level_name="VALIDATION_ERROR" ;;
            $VALIDATION_WARN)  level_name="VALIDATION_WARN" ;;
            $VALIDATION_INFO)  level_name="VALIDATION_INFO" ;;
            $VALIDATION_DEBUG) level_name="VALIDATION_DEBUG" ;;
        esac
        echo "[$timestamp] $level_name: $message" >> "$LOG_FILE"
    fi
}

# Check if command exists and is executable
command_exists() {
    local command="$1"
    command -v "$command" >/dev/null 2>&1
}

# Validate system prerequisites
validate_prerequisites() {
    validation_log $VALIDATION_INFO "Starting prerequisite validation"

    local validation_errors=()
    local validation_warnings=()

    # Check macOS version
    local macos_version=$(sw_vers -productVersion 2>/dev/null)
    if [[ -n "$macos_version" ]]; then
        validation_log $VALIDATION_INFO "macOS version: $macos_version"

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
        validation_log $VALIDATION_INFO "Available disk space: ${available_space}GB"

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

    # Check internet connectivity
    if ! curl -s --connect-timeout 5 --max-time 10 "https://github.com" >/dev/null 2>&1; then
        validation_warnings+=("No internet connectivity detected")
    fi

    # Check required system tools
    local required_tools=("curl" "git" "python3" "bash" "zsh")
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            validation_errors+=("Required tool not found: $tool")
        fi
    done

    # Report results
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        validation_log $VALIDATION_ERROR "Prerequisite validation failed with ${#validation_errors[@]} errors:"
        for error in "${validation_errors[@]}"; do
            validation_log $VALIDATION_ERROR "  - $error"
        done
        return 1
    fi

    if [[ ${#validation_warnings[@]} -gt 0 ]]; then
        validation_log $VALIDATION_WARN "Prerequisite validation completed with ${#validation_warnings[@]} warnings:"
        for warning in "${validation_warnings[@]}"; do
            validation_log $VALIDATION_WARN "  - $warning"
        done
    fi

    validation_log $VALIDATION_INFO "Prerequisite validation completed successfully"
    return 0
}

# Validate tool functionality
check_tool_functionality() {
    local tool_name="$1"
    local test_command="${2:-}"

    validation_log $VALIDATION_DEBUG "Checking functionality of tool: $tool_name"

    # Check if tool exists
    if ! command_exists "$tool_name"; then
        validation_log $VALIDATION_ERROR "Tool not found: $tool_name"
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
        validation_log $VALIDATION_DEBUG "Tool functionality verified: $tool_name"
        return 0
    else
        validation_log $VALIDATION_ERROR "Tool functionality test failed: $tool_name"
        return 1
    fi
}

# Validate symlink integrity
validate_symlinks() {
    validation_log $VALIDATION_INFO "Starting symlink validation"

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

        validation_log $VALIDATION_DEBUG "Checking symlink: $link_path -> $target_path"

        if [[ -L "$link_path" ]]; then
            # It's a symlink, check if it points to the right place
            local actual_target=$(readlink "$link_path")

            if [[ "$actual_target" == "$target_path" ]]; then
                # Check if target exists
                if [[ -e "$target_path" ]]; then
                    validation_log $VALIDATION_DEBUG "Symlink valid: $link_path -> $target_path"
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
            validation_log $VALIDATION_DEBUG "Checking for broken symlinks in: $dir"

            while IFS= read -r -d '' broken_link; do
                symlink_errors+=("Broken symlink found: $broken_link")
            done < <(find "$dir" -maxdepth 2 -type l ! -exec test -e {} \; -print0 2>/dev/null)
        fi
    done

    # Report results
    if [[ ${#symlink_errors[@]} -gt 0 ]]; then
        validation_log $VALIDATION_ERROR "Symlink validation failed with ${#symlink_errors[@]} errors:"
        for error in "${symlink_errors[@]}"; do
            validation_log $VALIDATION_ERROR "  - $error"
        done
        return 1
    fi

    if [[ ${#symlink_warnings[@]} -gt 0 ]]; then
        validation_log $VALIDATION_WARN "Symlink validation completed with ${#symlink_warnings[@]} warnings:"
        for warning in "${symlink_warnings[@]}"; do
            validation_log $VALIDATION_WARN "  - $warning"
        done
    fi

    validation_log $VALIDATION_INFO "Symlink validation completed successfully"
    return 0
}

# Validate specific step completion
validate_step() {
    local step_id="$1"

    validation_log $VALIDATION_INFO "Validating step: $step_id"

    # Check if step is marked as completed in state
    if ! is_step_completed "$step_id"; then
        validation_log $VALIDATION_ERROR "Step not marked as completed: $step_id"
        return 1
    fi

    # Step-specific validation
    case "$step_id" in
        "prerequisites")
            validate_prerequisites
            ;;
        "ssh_setup")
            validate_ssh_setup
            ;;
        "github_auth")
            validate_github_auth
            ;;
        "homebrew")
            validate_homebrew_installation
            ;;
        "rust")
            validate_rust_installation
            ;;
        "nodejs")
            validate_nodejs_installation
            ;;
        "configurations")
            validate_configurations
            ;;
        "symlinks")
            validate_symlinks
            ;;
        *)
            validation_log $VALIDATION_WARN "No specific validation available for step: $step_id"
            return 0
            ;;
    esac
}

# Validate SSH setup
validate_ssh_setup() {
    validation_log $VALIDATION_DEBUG "Validating SSH setup"

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
            validation_log $VALIDATION_DEBUG "SSH key found: $key_file"

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
        validation_log $VALIDATION_ERROR "SSH validation failed:"
        for error in "${ssh_errors[@]}"; do
            validation_log $VALIDATION_ERROR "  - $error"
        done
        return 1
    fi

    validation_log $VALIDATION_INFO "SSH setup validation completed successfully"
    return 0
}

# Validate GitHub authentication
validate_github_auth() {
    validation_log $VALIDATION_DEBUG "Validating GitHub authentication"

    # Test GitHub SSH connection
    if ssh -T git@github.com -o ConnectTimeout=10 -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
        validation_log $VALIDATION_INFO "GitHub SSH authentication verified"
        return 0
    else
        validation_log $VALIDATION_ERROR "GitHub SSH authentication failed"
        return 1
    fi
}

# Validate Homebrew installation
validate_homebrew_installation() {
    validation_log $VALIDATION_DEBUG "Validating Homebrew installation"

    local brew_errors=()

    # Check if brew command exists
    if ! command_exists "brew"; then
        brew_errors+=("Homebrew not installed or not in PATH")
        return 1
    fi

    # Check brew functionality
    if ! check_tool_functionality "brew"; then
        brew_errors+=("Homebrew functionality test failed")
    fi

    # Check if Brewfile exists and validate some key packages
    if [[ -f "$HOME/.dotfiles/Brewfile" ]]; then
        local key_packages=("git" "curl" "wget" "bat" "ripgrep")
        for package in "${key_packages[@]}"; do
            if ! command_exists "$package"; then
                brew_errors+=("Expected Homebrew package not found: $package")
            fi
        done
    fi

    # Report results
    if [[ ${#brew_errors[@]} -gt 0 ]]; then
        validation_log $VALIDATION_ERROR "Homebrew validation failed:"
        for error in "${brew_errors[@]}"; do
            validation_log $VALIDATION_ERROR "  - $error"
        done
        return 1
    fi

    validation_log $VALIDATION_INFO "Homebrew installation validation completed successfully"
    return 0
}

# Validate Rust installation
validate_rust_installation() {
    validation_log $VALIDATION_DEBUG "Validating Rust installation"

    local rust_errors=()

    # Check Rust tools
    local rust_tools=("rustc" "cargo")
    for tool in "${rust_tools[@]}"; do
        if ! check_tool_functionality "$tool"; then
            rust_errors+=("Rust tool not working: $tool")
        fi
    done

    # Report results
    if [[ ${#rust_errors[@]} -gt 0 ]]; then
        validation_log $VALIDATION_ERROR "Rust validation failed:"
        for error in "${rust_errors[@]}"; do
            validation_log $VALIDATION_ERROR "  - $error"
        done
        return 1
    fi

    validation_log $VALIDATION_INFO "Rust installation validation completed successfully"
    return 0
}

# Validate Node.js installation
validate_nodejs_installation() {
    validation_log $VALIDATION_DEBUG "Validating Node.js installation"

    local nodejs_errors=()

    # Check Node.js tools
    local nodejs_tools=("node" "npm")
    for tool in "${nodejs_tools[@]}"; do
        if ! check_tool_functionality "$tool"; then
            nodejs_errors+=("Node.js tool not working: $tool")
        fi
    done

    # Check if fnm is installed (Node version manager)
    if ! command_exists "fnm"; then
        nodejs_errors+=("fnm (Node version manager) not found")
    fi

    # Report results
    if [[ ${#nodejs_errors[@]} -gt 0 ]]; then
        validation_log $VALIDATION_ERROR "Node.js validation failed:"
        for error in "${nodejs_errors[@]}"; do
            validation_log $VALIDATION_ERROR "  - $error"
        done
        return 1
    fi

    validation_log $VALIDATION_INFO "Node.js installation validation completed successfully"
    return 0
}

# Validate configurations
validate_configurations() {
    validation_log $VALIDATION_DEBUG "Validating configurations"

    local config_errors=()

    # Check key configuration files exist
    local config_files=(
        "$HOME/.dotfiles/zsh/.zshrc"
        "$HOME/.dotfiles/git/.gitconfig"
        "$HOME/.dotfiles/ghostty/config"
        "$HOME/.dotfiles/starship.toml"
    )

    for config_file in "${config_files[@]}"; do
        if [[ ! -f "$config_file" ]]; then
            config_errors+=("Configuration file missing: $config_file")
        fi
    done

    # Test shell configuration
    if [[ -f "$HOME/.zshrc" ]]; then
        # Test if zsh config loads without errors
        if ! zsh -n "$HOME/.zshrc" 2>/dev/null; then
            config_errors+=("Zsh configuration has syntax errors")
        fi
    fi

    # Report results
    if [[ ${#config_errors[@]} -gt 0 ]]; then
        validation_log $VALIDATION_ERROR "Configuration validation failed:"
        for error in "${config_errors[@]}"; do
            validation_log $VALIDATION_ERROR "  - $error"
        done
        return 1
    fi

    validation_log $VALIDATION_INFO "Configuration validation completed successfully"
    return 0
}

# Comprehensive validation of full installation
validate_full_installation() {
    validation_log $VALIDATION_INFO "Starting comprehensive installation validation"

    local overall_errors=0
    local validation_results=()

    # Get list of completed steps
    local completed_steps=($(list_completed_steps))

    if [[ ${#completed_steps[@]} -eq 0 ]]; then
        validation_log $VALIDATION_ERROR "No completed steps found"
        return 1
    fi

    validation_log $VALIDATION_INFO "Validating ${#completed_steps[@]} completed steps"

    # Validate each completed step
    for step_id in "${completed_steps[@]}"; do
        if validate_step "$step_id"; then
            validation_results+=("✓ $step_id: PASS")
        else
            validation_results+=("✗ $step_id: FAIL")
            ((overall_errors++))
        fi
    done

    # Additional comprehensive checks
    validation_log $VALIDATION_INFO "Running additional comprehensive checks"

    # Overall system validation
    if validate_prerequisites; then
        validation_results+=("✓ System Prerequisites: PASS")
    else
        validation_results+=("✗ System Prerequisites: FAIL")
        ((overall_errors++))
    fi

    # Overall symlink validation
    if validate_symlinks; then
        validation_results+=("✓ Symlink Integrity: PASS")
    else
        validation_results+=("✗ Symlink Integrity: FAIL")
        ((overall_errors++))
    fi

    # Print validation summary
    echo
    echo "==================================="
    echo "INSTALLATION VALIDATION SUMMARY"
    echo "==================================="
    echo

    for result in "${validation_results[@]}"; do
        echo "$result"
    done

    echo
    echo "Total checks: ${#validation_results[@]}"
    echo "Passed: $((${#validation_results[@]} - overall_errors))"
    echo "Failed: $overall_errors"

    if [[ $overall_errors -eq 0 ]]; then
        echo
        validation_log $VALIDATION_INFO "✓ OVERALL VALIDATION: PASS"
        echo "Installation validation completed successfully!"
        return 0
    else
        echo
        validation_log $VALIDATION_ERROR "✗ OVERALL VALIDATION: FAIL"
        echo "Installation validation failed with $overall_errors errors."
        echo "Check the log file for detailed error information: $LOG_FILE"
        return 1
    fi
}

# Generate validation report
generate_validation_report() {
    local output_file="${1:-${STATE_DIR}/validation_report.txt}"

    validation_log $VALIDATION_INFO "Generating validation report: $output_file"

    {
        echo "DOTFILES INSTALLATION VALIDATION REPORT"
        echo "======================================="
        echo "Generated: $(date)"
        echo "System: $(uname -a)"
        echo "User: $(whoami)"
        echo

        # Run validation and capture output
        validate_full_installation

        echo
        echo "DETAILED LOGS"
        echo "============="
        if [[ -f "$LOG_FILE" ]]; then
            tail -50 "$LOG_FILE"
        else
            echo "No log file found"
        fi

    } > "$output_file"

    validation_log $VALIDATION_INFO "Validation report saved to: $output_file"
}

# Export functions for use in other scripts
export -f validate_prerequisites
export -f validate_step
export -f validate_full_installation
export -f check_tool_functionality
export -f validate_symlinks
export -f generate_validation_report
