#!/usr/bin/env bash

# Rock.js style demo - clean, minimal, elegant
source lib/rock_core.sh

# Demo step functions
demo_check_system() {
    sleep 0.5

    if [[ "$(uname)" != "Darwin" ]]; then
        return 1
    fi

    if ! resilient_command_exists "brew"; then
        return 1
    fi

    return 0
}

demo_backup_configs() {
    sleep 0.3

    for config_file in ".zshrc" ".gitconfig"; do
        local full_path="$HOME/$config_file"
        if [[ -f "$full_path" ]]; then
            resilient_backup_file "$full_path" "$config_file" >/dev/null
        fi
    done

    return 0
}

demo_install_packages() {
    sleep 0.8

    local required_tools=("git" "curl" "python3")

    for tool in "${required_tools[@]}"; do
        if ! resilient_command_exists "$tool"; then
            return 1
        fi
    done

    return 0
}

demo_network_operations() {
    sleep 0.4

    if resilient_check_network; then
        return 0
    else
        return 1
    fi
}

demo_create_symlinks() {
    sleep 0.6

    # Create and clean up demo symlinks
    local temp_config="/tmp/demo_config_$$"
    echo "# Demo config" > "$temp_config"

    local demo_link="$HOME/.demo_config_$$"
    if ln -sf "$temp_config" "$demo_link"; then
        rm -f "$demo_link" "$temp_config"
        return 0
    else
        return 1
    fi
}

demo_finalize_setup() {
    sleep 0.7
    return 0
}

demo_simulate_failure() {
    sleep 0.5
    return 1
}

# Main demo with Rock.js style
main() {
    clear

    # Rock.js style header - clean and minimal
    echo
    printf "Welcome to ${ROCK_COLOR_CYAN}tomdot${ROCK_COLOR_RESET}!\n"
    echo

    # Define installation steps
    local steps=(
        "check_system"
        "backup_configs"
        "install_packages"
        "network_operations"
        "create_symlinks"
        "finalize_setup"
        "simulate_failure"
    )

    # Simple question (Rock.js style)
    printf "${ROCK_COLOR_DIM}◇${ROCK_COLOR_RESET} Ready to set up your development environment?\n"
    printf "  ${ROCK_COLOR_DIM}Press enter to continue${ROCK_COLOR_RESET}\n"
    read -r
    echo

    # Execute steps with Rock.js style output
    resilient_execute_step "check_system" "demo_check_system" "Check system requirements"
    resilient_execute_step "backup_configs" "demo_backup_configs" "Backup existing configurations"
    resilient_execute_step "install_packages" "demo_install_packages" "Install required packages"
    resilient_execute_step "network_operations" "demo_network_operations" "Test network connectivity"
    resilient_execute_step "create_symlinks" "demo_create_symlinks" "Create configuration symlinks"
    resilient_execute_step "finalize_setup" "demo_finalize_setup" "Finalize installation"
    resilient_execute_step "simulate_failure" "demo_simulate_failure" "Simulate network failure"

    # Final results (Rock.js style)
    resilient_show_progress "${steps[@]}"

    echo
    printf "${ROCK_COLOR_DIM}Next steps${ROCK_COLOR_RESET}\n"
    echo
    printf "  cd ~/.dotfiles\n"
    printf "  source ~/.zshrc\n"
    printf "  git status\n"
    echo

    resilient_summary
    echo
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
