#!/usr/bin/env bash

# Rock.js style demo of the resilient installation framework
source lib/core.sh

# Demo step functions with realistic timing
demo_check_system() {
    echo "Checking system requirements..."
    sleep 0.5

    if [[ "$(uname)" != "Darwin" ]]; then
        echo "Not macOS - would install different packages"
        return 1
    fi

    echo "✓ macOS detected"
    sleep 0.3

    if ! resilient_command_exists "brew"; then
        echo "✗ Homebrew not found - would install it"
        return 1
    fi

    echo "✓ Homebrew available"
    sleep 0.2
    echo "System check completed"
    return 0
}

demo_backup_configs() {
    echo "Backing up existing configurations..."
    sleep 0.3

    local backed_up=0
    for config_file in ".zshrc" ".gitconfig" ".vimrc"; do
        local full_path="$HOME/$config_file"
        if [[ -f "$full_path" ]]; then
            resilient_backup_file "$full_path" "$config_file" >/dev/null
            echo "✓ Backed up $config_file"
            ((backed_up++))
            sleep 0.2
        fi
    done

    echo "Backup completed ($backed_up files backed up)"
    return 0
}

demo_install_packages() {
    echo "Installing required packages..."
    sleep 0.5

    local required_tools=("git" "curl" "python3" "node" "ruby")
    local installed=0

    for tool in "${required_tools[@]}"; do
        if resilient_command_exists "$tool"; then
            echo "✓ $tool is available"
            ((installed++))
        else
            echo "⚠ $tool is missing (would install)"
        fi
        sleep 0.2
    done

    echo "Package check completed ($installed/$((${#required_tools[@]})) available)"
    return 0
}

demo_network_operations() {
    echo "Testing network connectivity..."
    sleep 0.3

    if resilient_check_network; then
        echo "✓ Network connectivity confirmed"
        sleep 0.2

        echo "Downloading configuration files..."
        # Simulate download with progress
        for i in {1..5}; do
            echo "  Downloading file $i/5..."
            sleep 0.3
        done
        echo "✓ All files downloaded"
        return 0
    else
        echo "✗ Network connectivity failed"
        return 1
    fi
}

demo_create_symlinks() {
    echo "Creating configuration symlinks..."
    sleep 0.3

    local configs=("zshrc" "gitconfig" "vimrc" "tmux.conf")

    for config in "${configs[@]}"; do
        echo "  Creating symlink for $config..."
        sleep 0.2

        # Create temporary demo (cleaned up immediately)
        local temp_config="/tmp/demo_${config}_$$"
        echo "# Demo $config" > "$temp_config"

        local demo_link="$HOME/.demo_${config}_$$"
        if ln -sf "$temp_config" "$demo_link"; then
            echo "  ✓ $config symlink created"
            # Clean up immediately
            rm -f "$demo_link" "$temp_config"
        else
            echo "  ✗ Failed to create $config symlink"
            return 1
        fi
    done

    echo "Symlink creation completed"
    return 0
}

demo_finalize_setup() {
    echo "Finalizing installation..."
    sleep 0.5

    echo "✓ Setting up shell environment"
    sleep 0.3
    echo "✓ Configuring git settings"
    sleep 0.3
    echo "✓ Installing global packages"
    sleep 0.4
    echo "✓ Updating system PATH"
    sleep 0.2

    echo "Installation finalized successfully!"
    return 0
}

demo_simulate_failure() {
    echo "Simulating network timeout..."
    sleep 1
    echo "Connection timed out after 30 seconds"
    return 1
}

# Main demo with Rock.js style presentation
main() {
    clear

    # Header with Rock.js style
    echo
    printf "${RESILIENT_COLOR_BLUE}🚀 Resilient Installation Framework${RESILIENT_COLOR_RESET}\n"
    printf "${RESILIENT_COLOR_BLUE}====================================${RESILIENT_COLOR_RESET}\n"
    echo
    printf "${RESILIENT_COLOR_YELLOW}Setting up your development environment with style!${RESILIENT_COLOR_RESET}\n"
    echo

    # Define installation steps
    local steps=(
        "system_check"
        "backup_configs"
        "install_packages"
        "network_operations"
        "create_symlinks"
        "finalize_setup"
        "simulate_failure"
    )

    # Show initial progress
    resilient_show_progress "${steps[@]}"

    printf "${RESILIENT_COLOR_BLUE}⏱️  Estimated time: 2-3 minutes${RESILIENT_COLOR_RESET}\n"
    echo

    read -p "Press Enter to start the installation..."
    echo

    # Execute each step with enhanced UI
    resilient_execute_step "system_check" "demo_check_system" "Check System Requirements"
    resilient_show_progress "${steps[@]}"

    resilient_execute_step "backup_configs" "demo_backup_configs" "Backup Existing Configurations"
    resilient_show_progress "${steps[@]}"

    resilient_execute_step "install_packages" "demo_install_packages" "Install Required Packages"
    resilient_show_progress "${steps[@]}"

    resilient_execute_step "network_operations" "demo_network_operations" "Network Operations"
    resilient_show_progress "${steps[@]}"

    resilient_execute_step "create_symlinks" "demo_create_symlinks" "Create Configuration Symlinks"
    resilient_show_progress "${steps[@]}"

    resilient_execute_step "finalize_setup" "demo_finalize_setup" "Finalize Installation"
    resilient_show_progress "${steps[@]}"

    # This will fail to demonstrate error handling
    resilient_execute_step "simulate_failure" "demo_simulate_failure" "Simulate Network Failure" || true

    # Final results
    clear
    printf "${RESILIENT_COLOR_GREEN}🎉 Installation Complete!${RESILIENT_COLOR_RESET}\n"
    printf "${RESILIENT_COLOR_GREEN}=========================${RESILIENT_COLOR_RESET}\n"
    echo

    resilient_show_progress "${steps[@]}"
    resilient_summary

    echo
    printf "${RESILIENT_COLOR_BLUE}📁 Files and logs saved to:${RESILIENT_COLOR_RESET}\n"
    printf "   State: %s\n" "$RESILIENT_STATE_FILE"
    printf "   Logs:  %s\n" "$RESILIENT_LOG_FILE"
    echo
    printf "${RESILIENT_COLOR_YELLOW}💡 To reset and try again:${RESILIENT_COLOR_RESET}\n"
    printf "   source lib/core.sh && resilient_reset --force\n"
    echo
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
