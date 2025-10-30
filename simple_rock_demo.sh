#!/usr/bin/env bash

# Simple Rock.js Style Demo - Clean, reliable, works everywhere
source lib/simple_rock.sh

# Demo step functions
demo_check_system() {
    sleep 1

    if [[ "$(uname)" != "Darwin" ]]; then
        return 1
    fi

    if ! resilient_command_exists "brew"; then
        return 1
    fi

    return 0
}

demo_backup_configs() {
    sleep 0.5

    for config_file in ".zshrc" ".gitconfig"; do
        local full_path="$HOME/$config_file"
        if [[ -f "$full_path" ]]; then
            resilient_backup_file "$full_path" "$config_file" >/dev/null
        fi
    done

    return 0
}

demo_install_packages() {
    sleep 2

    local required_tools=("git" "curl" "python3")

    for tool in "${required_tools[@]}"; do
        if ! resilient_command_exists "$tool"; then
            return 1
        fi
    done

    return 0
}

demo_apply_template() {
    sleep 3
    return 0
}

demo_git_init() {
    sleep 0.5
    return 0
}

demo_network_operations() {
    sleep 1

    if resilient_check_network; then
        return 0
    else
        return 1
    fi
}

demo_simulate_failure() {
    sleep 1
    return 1
}

# Main demo
main() {
    clear

    # Dotfiles setup header
    echo
    printf "Welcome to ${C_CYAN}Resilient Dotfiles${C_RESET}!\n"
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

    # Dotfiles setup questions
    printf "${C_DIM}◇${C_RESET} What is your development environment?\n"
    printf "${C_DIM}│${C_RESET} ${C_DIM}macOS with Homebrew${C_RESET}\n"
    printf "${C_DIM}│${C_RESET}\n"

    printf "${C_DIM}◇${C_RESET} Which shell do you want to configure?\n"
    printf "${C_DIM}│${C_RESET} ${C_DIM}zsh${C_RESET}\n"
    printf "${C_DIM}│${C_RESET}\n"

    printf "${C_DIM}◇${C_RESET} Ready to set up your dotfiles?\n"
    printf "${C_DIM}│${C_RESET} ${C_DIM}Press enter to continue${C_RESET}\n"
    read -r
    printf "${C_DIM}│${C_RESET}\n"

    # Execute steps
    resilient_execute_step "check_system" "demo_check_system" "Check system requirements"
    resilient_execute_step "backup_configs" "demo_backup_configs" "Backup existing configurations"
    resilient_execute_step "install_packages" "demo_install_packages" "Install required packages"
    resilient_execute_step "apply_template" "demo_apply_template" "Apply dotfiles configuration"
    resilient_execute_step "git_init" "demo_git_init" "Initialize git repository"
    resilient_execute_step "network_operations" "demo_network_operations" "Test network connectivity"
    resilient_execute_step "simulate_failure" "demo_simulate_failure" "Simulate network failure"

    # Final results
    resilient_show_progress "${steps[@]}"

    # Dotfiles "Next steps" box
    local next_steps=(
        "cd ~/.dotfiles"
        "source ~/.zshrc"
        "git status"
        "git add ."
        "git commit -m \"Initial dotfiles setup\""
    )

    resilient_show_box "Next steps" "${next_steps[@]}"

    echo
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
