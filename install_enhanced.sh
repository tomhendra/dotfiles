#!/usr/bin/env bash

# Enhanced Resilient Installation Script for Dotfiles
# Integrates all modular components for robust, recoverable installation

set -euo pipefail

# Script metadata
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="${HOME}/.dotfiles"

# Source all library modules
for lib in state executor progress interactive config_manager error_handler validator recovery selective; do
    if [[ -f "$SCRIPT_DIR/lib/${lib}.sh" ]]; then
        source "$SCRIPT_DIR/lib/${lib}.sh"
    fi
done

# Installation configuration
readonly DEFAULT_INSTALLATION_STEPS=(
    "prerequisites"
    "ssh_setup"
    "github_auth"
    "clone_dotfiles"
    "clone_repos"
    "homebrew"
    "rust"
    "nodejs"
    "global_packages"
    "configurations"
    "symlinks"
    "final_validation"
)

# Command line options
INTERACTIVE_MODE="auto"
FORCE_MODE="false"
DRY_RUN="false"
SELECTED_COMPONENTS=()
RESUME_MODE="false"
RESET_STATE="false"
SHOW_HELP="false"
VERBOSE="false"
QUIET="false"

# Show usage information
show_usage() {
    cat << EOF
Enhanced Dotfiles Installation Script v${SCRIPT_VERSION}

Usage: $0 [OPTIONS]

A resilient, modular installation system for macOS development environment setup.

OPTIONS:
  -h, --help              Show this help message
  -v, --verbose           Enable verbose output and detailed logging
  -q, --quiet             Suppress non-essential output
  -f, --force             Force installation, overwrite existing files
  -n, --dry-run           Preview installation without making changes
  -i, --interactive       Force interactive mode (prompt for confirmations)
  -y, --non-interactive   Force non-interactive mode (use defaults)
  -r, --resume            Resume previous installation from last checkpoint
  -R, --reset             Reset installation state and start fresh
  -c, --components LIST   Install only specified components (comma-separated)
  -s, --skip LIST         Skip specified components (comma-separated)
  --validate-only         Only run validation, don't install anything
  --show-progress         Show real-time progress updates
  --backup-configs        Create backup of existing configurations before install

COMPONENTS:
  prerequisites           System requirements and Xcode Command Line Tools
  ssh_setup              SSH key generation and configuration
  github_auth            GitHub authentication setup
  clone_dotfiles         Clone dotfiles repository
  clone_repos            Clone development repositories
  homebrew               Homebrew package manager and packages
  rust                   Rust programming language toolchain
  nodejs                 Node.js runtime and package managers
  global_packages        Global npm packages installation
  configurations         Configuration files deployment
  symlinks               Symbolic links creation
  final_validation       Comprehensive system validation

EXAMPLES:
  $0                                    # Full installation with prompts
  $0 --non-interactive                  # Automated installation
  $0 --components homebrew,nodejs       # Install only specific components
  $0 --dry-run                         # Preview what would be installed
  $0 --resume                          # Resume interrupted installation
  $0 --validate-only                   # Only validate current setup
  $0 --force --reset                   # Force clean installation

EXIT CODES:
  0: Installation completed successfully
  1: Installation completed with warnings
  2: Installation failed
  3: User cancelled installation
  4: System requirements not met

For more information, visit: https://github.com/tomhendra/dotfiles
EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                SHOW_HELP="true"
                shift
                ;;
            -v|--verbose)
                VERBOSE="true"
                export LOG_LEVEL=4
                shift
                ;;
            -q|--quiet)
                QUIET="true"
                export LOG_LEVEL=1
                shift
                ;;
            -f|--force)
                FORCE_MODE="true"
                shift
                ;;
            -n|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -i|--interactive)
                INTERACTIVE_MODE="true"
                shift
                ;;
            -y|--non-interactive)
                INTERACTIVE_MODE="false"
                shift
                ;;
            -r|--resume)
                RESUME_MODE="true"
                shift
                ;;
            -R|--reset)
                RESET_STATE="true"
                shift
                ;;
            -c|--components)
                IFS=',' read -ra SELECTED_COMPONENTS <<< "$2"
                shift 2
                ;;
            -s|--skip)
                IFS=',' read -ra SKIP_COMPONENTS <<< "$2"
                shift 2
                ;;
            --validate-only)
                VALIDATE_ONLY="true"
                shift
                ;;
            --show-progress)
                SHOW_PROGRESS="true"
                shift
                ;;
            --backup-configs)
                BACKUP_CONFIGS="true"
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_usage >&2
                exit 1
                ;;
        esac
    done
}

# Initialize installation environment
init_installation() {
    # Set up output preferences
    if [[ "$QUIET" == "true" ]]; then
        exec 1>/dev/null
    fi

    # Initialize state management
    init_state_management

    # Initialize error tracking
    if declare -f "init_error_tracking" >/dev/null 2>&1; then
        init_error_tracking
    fi

    # Reset state if requested
    if [[ "$RESET_STATE" == "true" ]]; then
        if [[ "$INTERACTIVE_MODE" != "false" ]]; then
            local confirm=$(prompt_yes_no "Reset all installation state and start fresh?" "n")
            if [[ "$confirm" != "y" ]]; then
                echo "Reset cancelled by user"
                exit 3
            fi
        fi
        reset_state
        log_operation "Installation state reset" "info"
    fi

    # Create backup if requested
    if [[ "$BACKUP_CONFIGS" == "true" ]] && declare -f "backup_configs" >/dev/null 2>&1; then
        backup_configs
    fi
}

# Show installation header
show_header() {
    if [[ "$QUIET" != "true" ]]; then
        echo
        print_color "$COLOR_BOLD$COLOR_BLUE" "🚀 Enhanced Dotfiles Installation v${SCRIPT_VERSION}"
        echo
        print_color "$COLOR_BLUE" "Setting up development environment for $(whoami)"
        echo

        if [[ "$DRY_RUN" == "true" ]]; then
            print_color "$COLOR_YELLOW" "🔍 DRY RUN MODE - No changes will be made"
            echo
        fi

        if [[ "$FORCE_MODE" == "true" ]]; then
            print_color "$COLOR_YELLOW" "⚡ FORCE MODE - Existing files will be overwritten"
            echo
        fi
    fi
}

# Get installation plan based on options
get_installation_plan() {
    local installation_steps=()

    if [[ ${#SELECTED_COMPONENTS[@]} -gt 0 ]]; then
        # Use selected components
        installation_steps=("${SELECTED_COMPONENTS[@]}")
    else
        # Use default steps, filtering out skipped components
        for step in "${DEFAULT_INSTALLATION_STEPS[@]}"; do
            local skip_step=false

            if [[ -n "${SKIP_COMPONENTS:-}" ]]; then
                for skip in "${SKIP_COMPONENTS[@]}"; do
                    if [[ "$step" == "$skip" ]]; then
                        skip_step=true
                        break
                    fi
                done
            fi

            if [[ "$skip_step" == "false" ]]; then
                installation_steps+=("$step")
            fi
        done
    fi

    printf "%s\n" "${installation_steps[@]}"
}

# Show installation plan
show_installation_plan() {
    local steps=("$@")

    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "📋 Installation Plan"
    echo

    for i in "${!steps[@]}"; do
        local step="${steps[$i]}"
        local step_number=$((i + 1))

        printf "  %2d. %s\n" "$step_number" "$step"
    done

    echo
    print_color "$COLOR_GRAY" "Total steps: ${#steps[@]}"

    if [[ "$INTERACTIVE_MODE" != "false" ]]; then
        echo
        local proceed=$(prompt_yes_no "Proceed with this installation plan?" "y")
        if [[ "$proceed" != "y" ]]; then
            echo "Installation cancelled by user"
            exit 3
        fi
    fi

    echo
}

# Prerequisites step
step_prerequisites() {
    log_operation "Checking system prerequisites" "info"

    # Check macOS version
    local macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    if [[ "$macos_version" == "unknown" ]]; then
        show_error "prerequisites" "Could not determine macOS version" 1
        return 1
    fi

    local major_version=$(echo "$macos_version" | cut -d. -f1)
    if [[ $major_version -lt 11 ]]; then
        show_error "prerequisites" "macOS $macos_version is not supported (requires macOS 11+)" 1
        return 1
    fi

    log_operation "macOS $macos_version detected (supported)" "info"

    # Check Xcode Command Line Tools
    if ! xcode-select -p >/dev/null 2>&1; then
        show_error "prerequisites" "Xcode Command Line Tools not installed" 127
        return 1
    fi

    # Accept Xcode license
    if ! sudo xcodebuild -license accept 2>/dev/null; then
        log_operation "Failed to accept Xcode license automatically" "warn"
    fi

    # Check disk space (require at least 5GB)
    local available_gb=$(df -g "$HOME" | awk 'NR==2 {print $4}')
    if [[ $available_gb -lt 5 ]]; then
        show_error "prerequisites" "Insufficient disk space: ${available_gb}GB available (5GB required)" 1
        return 1
    fi

    log_operation "Prerequisites check completed successfully" "success"
    return 0
}

# SSH setup step
step_ssh_setup() {
    log_operation "Setting up SSH configuration" "info"

    local ssh_dir="${HOME}/.ssh"
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    # Create SSH config if it doesn't exist
    if [[ ! -f "${ssh_dir}/config" ]]; then
        cat > "${ssh_dir}/config" << EOF
Host *
    PreferredAuthentications publickey
    UseKeychain yes
    IdentityFile ${ssh_dir}/id_rsa
EOF
        chmod 600 "${ssh_dir}/config"
        log_operation "Created SSH config file" "info"
    fi

    # Generate SSH key if it doesn't exist
    if [[ ! -f "${ssh_dir}/id_rsa" ]]; then
        log_operation "Generating RSA SSH key" "info"
        ssh-keygen -t rsa -b 4096 -f "${ssh_dir}/id_rsa" -C "tom.hendra@outlook.com" -N ""

        # Add to SSH agent
        eval "$(ssh-agent -s)"
        ssh-add "${ssh_dir}/id_rsa"

        log_operation "SSH key generated and added to agent" "success"
    else
        log_operation "SSH key already exists, adding to agent" "info"
        ssh-add "${ssh_dir}/id_rsa" 2>/dev/null || true
    fi

    return 0
}

# GitHub authentication step
step_github_auth() {
    log_operation "Setting up GitHub authentication" "info"

    local ssh_dir="${HOME}/.ssh"

    if [[ ! -f "${ssh_dir}/id_rsa.pub" ]]; then
        show_error "github_auth" "SSH public key not found" 1
        return 1
    fi

    # Copy public key to clipboard
    pbcopy < "${ssh_dir}/id_rsa.pub"
    log_operation "SSH public key copied to clipboard" "info"

    if [[ "$INTERACTIVE_MODE" != "false" ]]; then
        echo
        print_color "$COLOR_BOLD$COLOR_BLUE" "🔑 GitHub SSH Key Setup"
        echo
        print_color "$COLOR_BLUE" "Your SSH public key has been copied to the clipboard."
        echo
        print_color "$COLOR_YELLOW" "Please add it to your GitHub account:"
        print_color "$COLOR_GRAY" "1. Go to GitHub Settings > SSH and GPG keys"
        print_color "$COLOR_GRAY" "2. Click 'New SSH key'"
        print_color "$COLOR_GRAY" "3. Paste the key and save"
        echo

        local open_github=$(prompt_yes_no "Open GitHub SSH settings page?" "y")
        if [[ "$open_github" == "y" ]]; then
            open "https://github.com/settings/keys"
        fi

        echo
        prompt_yes_no "Press Enter after adding the SSH key to GitHub..." "y" >/dev/null
    fi

    # Test GitHub authentication
    log_operation "Testing GitHub SSH authentication" "info"
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_operation "GitHub authentication successful" "success"
        return 0
    else
        show_error "github_auth" "GitHub SSH authentication failed" 1
        return 1
    fi
}

# Clone dotfiles step
step_clone_dotfiles() {
    log_operation "Cloning dotfiles repository" "info"

    if [[ -d "$DOTFILES_DIR" ]]; then
        if [[ "$FORCE_MODE" == "true" ]]; then
            log_operation "Removing existing dotfiles directory" "warn"
            rm -rf "$DOTFILES_DIR"
        else
            log_operation "Dotfiles directory already exists, skipping clone" "info"
            return 0
        fi
    fi

    if ! git clone git@github.com:tomhendra/dotfiles.git "$DOTFILES_DIR"; then
        show_error "clone_dotfiles" "Failed to clone dotfiles repository" $?
        return 1
    fi

    log_operation "Dotfiles repository cloned successfully" "success"
    return 0
}

# Clone repositories step
step_clone_repos() {
    log_operation "Cloning development repositories" "info"

    local developer_dir="${HOME}/Developer"
    mkdir -p "$developer_dir"

    if [[ -f "$DOTFILES_DIR/git/get_repos.sh" ]]; then
        if bash "$DOTFILES_DIR/git/get_repos.sh"; then
            log_operation "Development repositories cloned successfully" "success"
            return 0
        else
            show_error "clone_repos" "Failed to clone development repositories" $?
            return 1
        fi
    else
        log_operation "Repository clone script not found, skipping" "warn"
        return 0
    fi
}

# Homebrew installation step
step_homebrew() {
    log_operation "Installing Homebrew and packages" "info"

    # Install Homebrew if not present
    if ! command -v brew >/dev/null 2>&1; then
        log_operation "Installing Homebrew package manager" "info"

        if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            show_error "homebrew" "Failed to install Homebrew" $?
            return 1
        fi

        # Add Homebrew to PATH
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
        fi
    fi

    # Update Homebrew
    brew update

    # Install packages from Brewfile
    if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
        log_operation "Installing Homebrew packages from Brewfile" "info"

        if brew bundle --file="$DOTFILES_DIR/Brewfile"; then
            brew cleanup
            log_operation "Homebrew packages installed successfully" "success"
            return 0
        else
            show_error "homebrew" "Failed to install Homebrew packages" $?
            return 1
        fi
    else
        log_operation "Brewfile not found, skipping package installation" "warn"
        return 0
    fi
}

# Rust installation step
step_rust() {
    log_operation "Installing Rust toolchain" "info"

    if command -v rustc >/dev/null 2>&1; then
        log_operation "Rust already installed, skipping" "info"
        return 0
    fi

    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        source "$HOME/.cargo/env"
        log_operation "Rust toolchain installed successfully" "success"
        return 0
    else
        show_error "rust" "Failed to install Rust toolchain" $?
        return 1
    fi
}

# Node.js installation step
step_nodejs() {
    log_operation "Installing Node.js runtime" "info"

    # Ensure fnm is available
    if ! command -v fnm >/dev/null 2>&1; then
        show_error "nodejs" "fnm (Fast Node Manager) not found - install via Homebrew first" 127
        return 1
    fi

    # Set up fnm environment
    eval "$(fnm env --use-on-cd)"

    # Install Node.js 22
    if fnm install 22 && fnm use 22 && fnm default 22; then
        # Enable Corepack for pnpm/yarn
        corepack enable
        corepack enable pnpm
        corepack enable yarn

        log_operation "Node.js 22 installed and configured successfully" "success"
        return 0
    else
        show_error "nodejs" "Failed to install Node.js 22" $?
        return 1
    fi
}

# Global packages installation step
step_global_packages() {
    log_operation "Installing global Node.js packages" "info"

    if [[ -f "$DOTFILES_DIR/global_pkg.sh" ]]; then
        if bash "$DOTFILES_DIR/global_pkg.sh"; then
            log_operation "Global packages installed successfully" "success"
            return 0
        else
            show_error "global_packages" "Failed to install global packages" $?
            return 1
        fi
    else
        log_operation "Global packages script not found, skipping" "warn"
        return 0
    fi
}

# Configurations deployment step
step_configurations() {
    log_operation "Deploying configuration files" "info"

    # Deploy configurations using config manager if available
    if declare -f "deploy_all_configs" >/dev/null 2>&1; then
        if deploy_all_configs "$DOTFILES_DIR" "$FORCE_MODE"; then
            log_operation "Configuration files deployed successfully" "success"
            return 0
        else
            show_error "configurations" "Failed to deploy configuration files" 1
            return 1
        fi
    else
        # Fallback to manual configuration deployment
        log_operation "Using fallback configuration deployment" "info"

        # Starship config
        mkdir -p "${HOME}/.config"
        if [[ -f "$DOTFILES_DIR/starship.toml" ]]; then
            cp "$DOTFILES_DIR/starship.toml" "${HOME}/.config/"
        fi

        # Bat config
        if command -v bat >/dev/null 2>&1; then
            local bat_config_dir="$(bat --config-dir)"
            mkdir -p "$bat_config_dir/themes"

            if [[ -f "$DOTFILES_DIR/bat/themes/Enki-Tokyo-Night.tmTheme" ]]; then
                cp "$DOTFILES_DIR/bat/themes/Enki-Tokyo-Night.tmTheme" "$bat_config_dir/themes/"
            fi

            if [[ -f "$DOTFILES_DIR/bat/bat.conf" ]]; then
                cp "$DOTFILES_DIR/bat/bat.conf" "$bat_config_dir/"
            fi

            bat cache --build
        fi

        log_operation "Basic configurations deployed" "success"
        return 0
    fi
}

# Symlinks creation step
step_symlinks() {
    log_operation "Creating symbolic links" "info"

    if [[ -f "$DOTFILES_DIR/create_symlinks.sh" ]]; then
        if bash "$DOTFILES_DIR/create_symlinks.sh"; then
            log_operation "Symbolic links created successfully" "success"
            return 0
        else
            show_error "symlinks" "Failed to create symbolic links" $?
            return 1
        fi
    else
        show_error "symlinks" "Symlink creation script not found" 1
        return 1
    fi
}

# Final validation step
step_final_validation() {
    log_operation "Running final validation" "info"

    if [[ -f "$SCRIPT_DIR/validate_installation.sh" ]]; then
        if bash "$SCRIPT_DIR/validate_installation.sh" --quiet; then
            log_operation "Final validation passed" "success"
            return 0
        else
            local exit_code=$?
            if [[ $exit_code -eq 1 ]]; then
                log_operation "Final validation completed with warnings" "warn"
                return 0
            else
                show_error "final_validation" "Final validation failed" $exit_code
                return 1
            fi
        fi
    else
        log_operation "Validation script not found, skipping final validation" "warn"
        return 0
    fi
}

# Run installation steps
run_installation() {
    local steps=("$@")
    local failed_steps=()
    local completed_steps=0

    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🚀 Starting Installation"
    echo

    for step in "${steps[@]}"; do
        local step_function="step_${step}"

        # Check if step function exists
        if ! declare -f "$step_function" >/dev/null 2>&1; then
            log_operation "Step function '$step_function' not found, skipping" "warn"
            continue
        fi

        # Show current step
        if declare -f "show_current_step" >/dev/null 2>&1; then
            show_current_step "$step" "$step"
        else
            echo "Executing step: $step"
        fi

        # Execute step (with dry-run support)
        if [[ "$DRY_RUN" == "true" ]]; then
            log_operation "DRY RUN: Would execute step '$step'" "info"
            ((completed_steps++))
        else
            if declare -f "execute_step" >/dev/null 2>&1; then
                # Use enhanced executor if available
                if execute_step "$step" "$step_function"; then
                    ((completed_steps++))
                else
                    failed_steps+=("$step")
                fi
            else
                # Direct function execution
                if "$step_function"; then
                    ((completed_steps++))
                    log_operation "Step '$step' completed successfully" "success"
                else
                    failed_steps+=("$step")
                    log_operation "Step '$step' failed" "error"
                fi
            fi
        fi

        # Show progress if function is available
        if declare -f "show_progress" >/dev/null 2>&1; then
            show_progress "${steps[@]}"
        fi
    done

    # Show installation summary
    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "📊 Installation Summary"
    echo

    print_color "$COLOR_GREEN" "✅ Completed steps: $completed_steps/${#steps[@]}"

    if [[ ${#failed_steps[@]} -gt 0 ]]; then
        print_color "$COLOR_RED" "❌ Failed steps: ${#failed_steps[@]}"
        echo
        print_color "$COLOR_RED" "Failed steps:"
        for step in "${failed_steps[@]}"; do
            print_color "$COLOR_RED" "  - $step"
        done
        echo
        return 2
    else
        echo
        print_color "$COLOR_BOLD$COLOR_GREEN" "🎉 Installation completed successfully!"
        echo
        return 0
    fi
}

# Main installation function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Show help if requested
    if [[ "$SHOW_HELP" == "true" ]]; then
        show_usage
        exit 0
    fi

    # Handle validation-only mode
    if [[ "${VALIDATE_ONLY:-false}" == "true" ]]; then
        if [[ -f "$SCRIPT_DIR/validate_installation.sh" ]]; then
            exec bash "$SCRIPT_DIR/validate_installation.sh" "$@"
        else
            echo "Validation script not found" >&2
            exit 1
        fi
    fi

    # Initialize installation environment
    init_installation

    # Show header
    show_header

    # Get installation plan
    local installation_steps
    mapfile -t installation_steps < <(get_installation_plan)

    # Show installation plan
    show_installation_plan "${installation_steps[@]}"

    # Run installation
    local exit_code=0
    if run_installation "${installation_steps[@]}"; then
        exit_code=0
    else
        exit_code=$?
    fi

    # Show final status
    echo
    if [[ $exit_code -eq 0 ]]; then
        print_color "$COLOR_BOLD$COLOR_GREEN" "✅ Installation completed successfully!"
        echo
        print_color "$COLOR_BLUE" "Your development environment is ready to use."
        echo
        print_color "$COLOR_GRAY" "You may need to restart your terminal or run 'source ~/.zshrc' to apply all changes."
    else
        print_color "$COLOR_BOLD$COLOR_RED" "❌ Installation completed with errors"
        echo
        print_color "$COLOR_YELLOW" "Check the logs above for details on failed steps."
        echo
        print_color "$COLOR_BLUE" "You can resume the installation by running: $0 --resume"
    fi

    echo
    exit $exit_code
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
