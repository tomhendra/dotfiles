#!/usr/bin/env bash

# Pure Bash Demo - No Python Dependencies
source lib/simple_core.sh

# Demo step functions
demo_check_system() {
    echo "Checking system requirements..."

    if [[ "$(uname)" != "Darwin" ]]; then
        echo "Not macOS - would install different packages"
        return 1
    fi

    if ! resilient_command_exists "bash"; then
        echo "Bash not found - critical error"
        return 1
    fi

    echo "System check passed"
    return 0
}

demo_backup_configs() {
    echo "Backing up existing configurations..."

    # Backup existing files if they exist
    for config_file in ".zshrc" ".gitconfig"; do
        local full_path="$HOME/$config_file"
        if [[ -f "$full_path" ]]; then
            resilient_backup_file "$full_path" "$config_file"
        else
            echo "  $config_file not found, skipping backup"
        fi
    done

    echo "Backup completed"
    return 0
}

demo_install_packages() {
    echo "Checking required packages..."

    # Check for required tools
    local required_tools=("git" "curl" "brew")
    local missing_tools=()

    for tool in "${required_tools[@]}"; do
        if resilient_command_exists "$tool"; then
            echo "  ✓ $tool is available"
        else
            missing_tools+=("$tool")
            echo "  ✗ $tool is missing"
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "Would install: ${missing_tools[*]}"
        # Simulate installation time
        sleep 1
    fi

    echo "Package check completed"
    return 0
}

demo_network_test() {
    echo "Testing network connectivity..."

    if resilient_check_network; then
        echo "Network connectivity confirmed"
        return 0
    else
        echo "Network connectivity failed - would retry"
        return 1
    fi
}

demo_create_symlinks() {
    echo "Creating configuration symlinks..."

    # Create a temporary demo
    local temp_config="/tmp/demo_config_$$"
    echo "# Demo configuration" > "$temp_config"

    local demo_link="$HOME/.demo_config_$$"
    if ln -sf "$temp_config" "$demo_link"; then
        echo "Created symlink: $demo_link"
        # Verify it works
        if [[ -L "$demo_link" ]]; then
            echo "Symlink verification passed"
        fi
        # Clean up immediately
        rm -f "$demo_link" "$temp_config"
        echo "Demo symlink cleaned up"
        return 0
    else
        echo "Failed to create symlink"
        return 1
    fi
}

demo_intentional_failure() {
    echo "This step will fail to demonstrate error handling and retry logic"
    sleep 1
    return 1
}

# Main demo
main() {
    echo "Pure Bash Resilient Installation Demo"
    echo "====================================="
    echo "No Python dependencies - uses only standard Unix tools"
    echo

    # Define installation steps
    local steps=(
        "system_check"
        "backup_configs"
        "install_packages"
        "network_test"
        "create_symlinks"
        "intentional_failure"
    )

    echo "This demo will run the following steps:"
    for step in "${steps[@]}"; do
        echo "  - $step"
    done
    echo

    read -p "Press Enter to start..."
    echo

    # Execute each step
    resilient_execute_step "system_check" "demo_check_system" "Check System Requirements"
    resilient_execute_step "backup_configs" "demo_backup_configs" "Backup Existing Configurations"
    resilient_execute_step "install_packages" "demo_install_packages" "Check Required Packages"
    resilient_execute_step "network_test" "demo_network_test" "Test Network Connectivity"
    resilient_execute_step "create_symlinks" "demo_create_symlinks" "Create Configuration Symlinks"

    # This will fail to show error handling
    resilient_execute_step "intentional_failure" "demo_intentional_failure" "Demonstrate Failure Handling" || true

    echo
    echo "Demo completed!"
    echo

    # Show results
    resilient_show_progress "${steps[@]}"
    echo
    resilient_summary

    echo
    echo "Files created (all plain text, no JSON):"
    echo "  State directory: $RESILIENT_STATE_DIR"
    echo "  Steps file: $RESILIENT_STEPS_FILE"
    echo "  Metadata: $RESILIENT_METADATA_FILE"
    echo "  Logs: $RESILIENT_LOG_FILE"
    echo
    echo "To inspect state:"
    echo "  cat $RESILIENT_STEPS_FILE"
    echo "  cat $RESILIENT_METADATA_FILE"
    echo
    echo "To reset: source lib/simple_core.sh && resilient_reset --force"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
