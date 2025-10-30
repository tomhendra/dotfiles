#!/usr/bin/env bash

# Rock.js Enhanced Demo - with spinners, boxes, and real-time updates
source lib/rock_enhanced.sh

# Demo step functions with realistic timing
demo_check_system() {
    sleep 1.2

    if [[ "$(uname)" != "Darwin" ]]; then
        return 1
    fi

    if ! resilient_command_exists "brew"; then
        return 1
    fi

    return 0
}

demo_backup_configs() {
    sleep 0.8

    for config_file in ".zshrc" ".gitconfig"; do
        local full_path="$HOME/$config_file"
        if [[ -f "$full_path" ]]; then
            resilient_backup_file "$full_path" "$config_file" >/dev/null
        fi
    done

    return 0
}

demo_install_packages() {
    sleep 2.1  # Longer operation to show spinner

    local required_tools=("git" "curl" "python3")

    for tool in "${required_tools[@]}"; do
        if ! resilient_command_exists "$tool"; then
            return 1
        fi
    done

    return 0
}

demo_apply_template() {
    sleep 3.2  # Long operation like in Rock.js screenshot
    return 0
}

demo_git_init() {
    sleep 0.6
    return 0
}

demo_network_operations() {
    sleep 1.5

    if resilient_check_network; then
        return 0
    else
        return 1
    fi
}

demo_simulate_failure() {
    sleep 1.8
    return 1
}

# Main demo with Rock.js enhanced features
main() {
    clear

    # Rock.js style header
    echo
    printf "Welcome to ${ROCK_COLOR_CYAN}Resilient Installation${ROCK_COLOR_RESET}!\n"
    echo

    # Define installation steps
    local steps=(
        "check_system"
        "backup_configs"
        "install_packages"
        "apply_template"
        "git_init"
        "network_operations"
        "simulate_failure"
    )

    # Rock.js style question
    printf "${ROCK_COLOR_DIM}◇${ROCK_COLOR_RESET} What is your project name?\n"
    printf "  ${ROCK_COLOR_DIM}resilient-dotfiles${ROCK_COLOR_RESET}\n"
    echo

    printf "${ROCK_COLOR_DIM}◇${ROCK_COLOR_RESET} Ready to set up your development environment?\n"
    printf "  ${ROCK_COLOR_DIM}Press enter to continue${ROCK_COLOR_RESET}\n"
    read -r
    echo

    # Execute steps with Rock.js style spinners and updates
    resilient_execute_step "check_system" "demo_check_system" "Check system requirements"
    resilient_execute_step "backup_configs" "demo_backup_configs" "Backup existing configurations"
    resilient_execute_step "install_packages" "demo_install_packages" "Install required packages"
    resilient_execute_step "apply_template" "demo_apply_template" "Applied template, platforms and plugins"
    resilient_execute_step "git_init" "demo_git_init" "Git repo initialized"
    resilient_execute_step "network_operations" "demo_network_operations" "Test network connectivity"
    resilient_execute_step "simulate_failure" "demo_simulate_failure" "Simulate network failure"

    # Final results
    resilient_show_progress "${steps[@]}"

    # Rock.js style "Next steps" box
    local next_steps=(
        "cd resilient-dotfiles"
        "source ~/.zshrc"
        "git status"
        "git add ."
        "git commit -m \"Initial setup\""
    )

    resilient_show_box "Next steps" "${next_steps[@]}"

    echo
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
