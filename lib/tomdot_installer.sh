#!/usr/bin/env bash

# Tomdot Installation Engine - Core resilient installation functionality
# Handles state management, retry logic, and all installation steps

# Configuration
if [[ -z "${TOMDOT_STATE_DIR:-}" ]]; then
    readonly TOMDOT_STATE_DIR="${HOME}/.tomdot_install_state"
    readonly TOMDOT_STATE_FILE="${TOMDOT_STATE_DIR}/state.json"
    readonly TOMDOT_BACKUP_DIR="${TOMDOT_STATE_DIR}/backups"
    readonly TOMDOT_LOG_FILE="${TOMDOT_STATE_DIR}/install.log"
fi

# Retry configuration (always set these)
if [[ -z "${TOMDOT_MAX_RETRIES:-}" ]]; then
    readonly TOMDOT_MAX_RETRIES=3
    readonly TOMDOT_RETRY_DELAY=2
fi

# Source framework components
TOMDOT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${TOMDOT_LIB_DIR}/tomdot_ui.sh"
source "${TOMDOT_LIB_DIR}/tomdot_utils.sh"

# Initialize state directory and files
tomdot_init_state() {
    mkdir -p "$TOMDOT_STATE_DIR" "$TOMDOT_BACKUP_DIR"

    if [[ ! -f "$TOMDOT_STATE_FILE" ]]; then
        cat > "$TOMDOT_STATE_FILE" << 'EOF'
{
  "version": "1.0",
  "installation_id": "",
  "started_at": "",
  "last_updated": "",
  "current_step": "",
  "completed_steps": [],
  "failed_steps": [],
  "backups": {},
  "configuration": {}
}
EOF
    fi
}

# Generate unique installation ID
tomdot_generate_id() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        echo "tomdot_$(date +%s)_$RANDOM"
    fi
}

# Save step state to JSON
tomdot_save_step_state() {
    local step_name="$1"
    local status="$2"
    local failure_reason="${3:-}"

    tomdot_init_state

    local temp_file="${TOMDOT_STATE_FILE}.tmp"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    python3 << EOF > "$temp_file"
import json
import sys

try:
    with open("$TOMDOT_STATE_FILE", "r") as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {
        "version": "1.0",
        "installation_id": "",
        "started_at": "",
        "last_updated": "",
        "current_step": "",
        "completed_steps": [],
        "failed_steps": [],
        "step_details": {},
        "backups": {},
        "configuration": {}
    }

if not data.get("installation_id"):
    data["installation_id"] = "$(tomdot_generate_id)"
if not data.get("started_at"):
    data["started_at"] = "$timestamp"

data["last_updated"] = "$timestamp"
data["current_step"] = "$step_name"

# Initialize step_details if not present
if "step_details" not in data:
    data["step_details"] = {}

# Update step status
if "$status" == "completed":
    if "$step_name" not in data["completed_steps"]:
        data["completed_steps"].append("$step_name")
    if "$step_name" in data["failed_steps"]:
        data["failed_steps"].remove("$step_name")
    data["step_details"]["$step_name"] = {
        "status": "completed",
        "completed_at": "$timestamp"
    }
elif "$status" == "failed":
    if "$step_name" not in data["failed_steps"]:
        data["failed_steps"].append("$step_name")
    data["step_details"]["$step_name"] = {
        "status": "failed",
        "failed_at": "$timestamp",
        "failure_reason": "$failure_reason"
    }
elif "$status" == "started":
    data["step_details"]["$step_name"] = {
        "status": "started",
        "started_at": "$timestamp"
    }

print(json.dumps(data, indent=2))
EOF

    if [[ -f "$temp_file" ]]; then
        mv "$temp_file" "$TOMDOT_STATE_FILE"
    fi
}

# Check if step is completed
tomdot_is_step_completed() {
    local step_name="$1"

    if [[ ! -f "$TOMDOT_STATE_FILE" ]]; then
        return 1
    fi

    python3 -c "
import json
try:
    with open('$TOMDOT_STATE_FILE', 'r') as f:
        data = json.load(f)
    completed_steps = data.get('completed_steps', [])
    exit(0 if '$step_name' in completed_steps else 1)
except:
    exit(1)
"
}

# Get installation state information
tomdot_get_state() {
    local query="$1"

    if [[ ! -f "$TOMDOT_STATE_FILE" ]]; then
        return 1
    fi

    python3 -c "
import json
try:
    with open('$TOMDOT_STATE_FILE', 'r') as f:
        data = json.load(f)

    if '$query' == 'completed_steps':
        print(' '.join(data.get('completed_steps', [])))
    elif '$query' == 'failed_steps':
        print(' '.join(data.get('failed_steps', [])))
    elif '$query' == 'current_step':
        print(data.get('current_step', ''))
    elif '$query' == 'installation_id':
        print(data.get('installation_id', ''))
    elif '$query' == 'started_at':
        print(data.get('started_at', ''))
    else:
        print(json.dumps(data, indent=2))
except:
    exit(1)
"
}

# Find next step to resume from
tomdot_find_resume_step() {
    local all_steps=("$@")
    local completed_steps

    if [[ ! -f "$TOMDOT_STATE_FILE" ]]; then
        echo "${all_steps[0]}"
        return 0
    fi

    completed_steps=$(tomdot_get_state "completed_steps")

    for step in "${all_steps[@]}"; do
        if ! echo "$completed_steps" | grep -q "$step"; then
            echo "$step"
            return 0
        fi
    done

    # All steps completed
    echo ""
}

# Check if installation can be resumed
tomdot_can_resume() {
    [[ -f "$TOMDOT_STATE_FILE" ]] && [[ -n "$(tomdot_get_state "started_at")" ]]
}

# Execute installation step with retry logic
tomdot_execute_step() {
    local step_name="$1"
    local step_function="$2"
    local step_description="${3:-$step_name}"

    # Skip if already completed
    if tomdot_is_step_completed "$step_name"; then
        printf "${C_GREEN}◇${C_RESET} %s ${C_DIM}(already completed)${C_RESET}\n" "$step_description"
        printf "${C_DIM}│${C_RESET}\n"
        return 0
    fi

    # Check if function exists
    if ! declare -f "$step_function" >/dev/null 2>&1; then
        local error_msg="Function '$step_function' not found"
        printf "${C_RED}◇${C_RESET} %s ${C_RED}✗${C_RESET}\n" "$step_description"
        tomdot_save_step_state "$step_name" "failed" "$error_msg"
        echo "ERROR: $error_msg" | tee -a "$TOMDOT_LOG_FILE"
        return 1
    fi

    # No backup needed - original install.sh didn't have backups

    # Mark step as started
    tomdot_save_step_state "$step_name" "started"

    local attempt=1
    local last_error=""

    while [[ $attempt -le $TOMDOT_MAX_RETRIES ]]; do
        # Show simple progress indicator
        printf "${C_DIM}│${C_RESET}\n"
        printf "${C_CYAN}◇${C_RESET} %s...\n" "$step_description"

        # Execute the step function directly - NO BACKGROUND PROCESSES
        local exit_code=0
        local step_output
        step_output=$("$step_function" 2>&1) || exit_code=$?

        # Show the output with proper UI formatting
        if [[ -n "$step_output" ]]; then
            # Format each line with the connector
            echo "$step_output" | while IFS= read -r line; do
                printf "${C_DIM}│${C_RESET} %s\n" "$line"
            done | tee -a "$TOMDOT_LOG_FILE"
        fi

        if [[ $exit_code -eq 0 ]]; then
            # Validate the step completion
            local validation_output
            validation_output=$(tomdot_validate_step "$step_name" 2>&1)
            if [[ $? -eq 0 ]]; then
                # Format validation output with connectors
                if [[ -n "$validation_output" ]]; then
                    echo "$validation_output" | while IFS= read -r line; do
                        printf "${C_DIM}│${C_RESET} %s\n" "$line"
                    done | tee -a "$TOMDOT_LOG_FILE"
                fi
                printf "${C_GREEN}◇${C_RESET} %s ${C_GREEN}✓${C_RESET}\n" "$step_description"
                printf "${C_DIM}│${C_RESET}\n"
                tomdot_save_step_state "$step_name" "completed"
                return 0
            else
                last_error="Step completed but validation failed"
                exit_code=1
            fi
        else
            last_error="Exit code: $exit_code"
        fi

        # Handle failure
        if [[ $exit_code -ne 0 ]]; then
            if [[ $attempt -lt $TOMDOT_MAX_RETRIES ]]; then
                printf "${C_YELLOW}◇${C_RESET} %s ${C_YELLOW}⚠${C_RESET} ${C_DIM}(retry $attempt/$TOMDOT_MAX_RETRIES)${C_RESET}\n" "$step_description"
                sleep "$TOMDOT_RETRY_DELAY"
            else
                printf "${C_RED}◇${C_RESET} %s ${C_RED}✗${C_RESET}\n" "$step_description"
                printf "${C_DIM}│${C_RESET}\n"
            fi
        fi

        ((attempt++))
    done

    # All attempts failed
    tomdot_save_step_state "$step_name" "failed" "$last_error"
    echo "ERROR: Step '$step_name' failed after $TOMDOT_MAX_RETRIES attempts: $last_error" | tee -a "$TOMDOT_LOG_FILE"
    return 1
}

# Installation step functions
install_ssh_setup() {
    local ssh_dir="${HOME}/.ssh"
    local ssh_key="${ssh_dir}/id_rsa"
    local ssh_config="${ssh_dir}/config"

    # Create SSH directory
    mkdir -p "$ssh_dir"

    # Create SSH config if it doesn't exist
    if [[ ! -f "$ssh_config" ]]; then
        cat > "$ssh_config" << 'EOF'
Host *
 PreferredAuthentications publickey
 UseKeychain yes
 IdentityFile ~/.ssh/id_rsa
EOF
        chmod 600 "$ssh_config"
        echo "Created SSH config file"
    fi

    # Generate SSH key if it doesn't exist
    if [[ ! -f "$ssh_key" ]]; then
        echo "Generating RSA SSH key..."
        ssh-keygen -t rsa -b 4096 -f "$ssh_key" -C "tom.hendra@outlook.com" -N ""

        # Start SSH agent and add key
        eval "$(ssh-agent -s)"
        ssh-add "$ssh_key"

        echo "✅ SSH key generated successfully"
    else
        echo "✅ SSH key already exists"

        # Test if SSH key is already working with GitHub
        if ssh -T git@github.com -o ConnectTimeout=5 -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
            echo "✅ SSH key already configured and working with GitHub"
            return 0
        fi

        echo "Adding existing SSH key to agent..."
        # Try to add key without prompting for passphrase if possible
        ssh-add -K "$ssh_key" 2>/dev/null || ssh-add "$ssh_key" 2>/dev/null || true
    fi

    # Copy public key to clipboard
    if command -v pbcopy >/dev/null 2>&1; then
        pbcopy < "${ssh_key}.pub"
        echo ""
        echo "📋 SSH public key copied to clipboard"
    fi

    # Interactive GitHub setup with clear instructions
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔑 GitHub SSH Key Setup Required"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Please add the SSH key to your GitHub account:"
    echo ""
    echo "  1. Go to https://github.com/settings/keys"
    echo "  2. Click 'New SSH key'"
    echo "  3. Paste (Cmd+V) the key from your clipboard"
    echo "  4. Give it a title (e.g., 'MacBook Pro')"
    echo "  5. Click 'Add SSH key'"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Press Enter when you've added the key to continue..."
    read -r

    # Test GitHub connection
    local max_attempts=3
    local attempt=1

    echo ""
    echo "Testing GitHub SSH connection..."

    while [[ $attempt -le $max_attempts ]]; do
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            echo "✅ GitHub SSH authentication successful!"
            return 0
        else
            if [[ $attempt -lt $max_attempts ]]; then
                echo "❌ GitHub authentication failed (attempt $attempt/$max_attempts)"
                echo ""
                echo "Please ensure the SSH key is added to GitHub and try again."
                echo "Press Enter to retry..."
                read -r
            fi
        fi
        ((attempt++))
    done

    echo ""
    echo "❌ Failed to authenticate with GitHub after $max_attempts attempts"
    echo "You may need to add the SSH key manually later."
    return 1
}

install_homebrew() {
    # Check if Homebrew is already installed
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew already installed"
        return 0
    fi

    echo "Installing Homebrew..."

    # Download and install Homebrew
    if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        echo "Failed to install Homebrew"
        return 1
    fi

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "${HOME}/.zprofile"
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    # Verify installation
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew installed successfully"
        return 0
    else
        echo "Homebrew installation verification failed"
        return 1
    fi
}

install_packages() {
    local dotfiles_dir="${HOME}/.dotfiles"
    local brewfile="${dotfiles_dir}/Brewfile"

    # Ensure dotfiles directory exists
    if [[ ! -d "$dotfiles_dir" ]]; then
        echo "Cloning dotfiles repository..."
        if ! git clone git@github.com:tomhendra/dotfiles.git "$dotfiles_dir"; then
            echo "Failed to clone dotfiles repository"
            return 1
        fi
    fi

    # Verify Brewfile exists
    if [[ ! -f "$brewfile" ]]; then
        echo "Brewfile not found at $brewfile"
        return 1
    fi

    echo "Updating Homebrew..."
    brew update

    echo "Installing Homebrew bundle..."
    # Note: homebrew/bundle is now built into Homebrew, no need to tap

    if ! brew bundle --file="$brewfile"; then
        echo "Failed to install packages from Brewfile"
        return 1
    fi

    echo "Cleaning up Homebrew..."
    brew cleanup

    echo "Packages installed successfully"
    return 0
}

install_languages() {
    local dotfiles_dir="${HOME}/.dotfiles"

    # Install Rust
    echo "Installing Rust..."
    if ! command -v rustc >/dev/null 2>&1; then
        if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
            echo "Failed to install Rust"
            return 1
        fi
        # Source Rust environment
        source "$HOME/.cargo/env"
    else
        echo "Rust already installed"
    fi

    # Install Node.js via fnm
    echo "Setting up Node.js..."

    # Ensure fnm is available (should be installed via Homebrew)
    if ! command -v fnm >/dev/null 2>&1; then
        echo "fnm not found - should be installed via Homebrew"
        return 1
    fi

    # Setup fnm environment
    eval "$(fnm env --use-on-cd)"

    # Install Node.js 22
    if ! fnm list | grep -q "v22"; then
        echo "Installing Node.js 22..."
        if ! fnm install 22; then
            echo "Failed to install Node.js 22"
            return 1
        fi
    else
        echo "Node.js 22 already installed"
    fi

    # Set as default
    fnm use 22
    fnm default 22

    # Enable Corepack for pnpm/yarn
    echo "Enabling Corepack..."
    corepack enable
    corepack enable pnpm
    corepack enable yarn

    # Install global Node.js packages
    echo "Installing global Node.js packages..."
    if [[ -f "${dotfiles_dir}/global_pkg.sh" ]]; then
        if ! sh "${dotfiles_dir}/global_pkg.sh"; then
            echo "Failed to install global Node.js packages"
            return 1
        fi
    else
        echo "global_pkg.sh not found, skipping global packages"
    fi

    echo "Language toolchains installed successfully"
    return 0
}

create_symlinks() {
    local dotfiles_dir="${HOME}/.dotfiles"

    # Ensure dotfiles directory exists
    if [[ ! -d "$dotfiles_dir" ]]; then
        echo "Dotfiles directory not found at $dotfiles_dir"
        return 1
    fi

    # Create necessary directories
    mkdir -p "${HOME}/.config/bat"
    mkdir -p "${HOME}/.config/ghostty"
    mkdir -p "${HOME}/.config/zed"

    # Function to create symlink safely
    create_symlink() {
        local source_path="${dotfiles_dir}/$1"
        local target_path="${HOME}/$2"
        local target_dir=$(dirname "$target_path")

        # Create target directory if it doesn't exist
        mkdir -p "$target_dir"

        # Remove existing file/symlink if it exists
        if [[ -e "$target_path" || -L "$target_path" ]]; then
            rm -f "$target_path"
        fi

        # Create symlink
        if ln -sf "$source_path" "$target_path"; then
            echo "Created symlink: $target_path -> $source_path"
        else
            echo "Failed to create symlink: $target_path"
            return 1
        fi
    }

    # Create symlinks for configuration files
    create_symlink "bat/bat.conf" ".config/bat/bat.conf"
    create_symlink "git/.gitconfig" ".gitconfig"
    create_symlink "git/.gitignore_global" ".gitignore_global"
    create_symlink "ghostty/config" ".config/ghostty/config"
    create_symlink "ghostty/themes" ".config/ghostty/themes"
    create_symlink "zed/settings.json" ".config/zed/settings.json"
    create_symlink "starship.toml" ".config/starship.toml"
    create_symlink "zsh/.zshrc" ".zshrc"
    create_symlink "zsh/.zprofile" ".zprofile"

    # Setup bat themes
    local bat_themes_dir="$(bat --config-dir)/themes"
    mkdir -p "$bat_themes_dir"

    if [[ -f "${dotfiles_dir}/bat/themes/Enki-Tokyo-Night.tmTheme" ]]; then
        cp "${dotfiles_dir}/bat/themes/Enki-Tokyo-Night.tmTheme" "$bat_themes_dir/"
        echo "Copied bat theme: Enki-Tokyo-Night.tmTheme"
    fi

    # Build bat cache
    if command -v bat >/dev/null 2>&1; then
        bat cache --build
        echo "Built bat cache"
    fi

    # Clone GitHub repositories
    if [[ -f "${dotfiles_dir}/git/get_repos.sh" ]]; then
        mkdir -p "${HOME}/Developer"
        if ! sh "${dotfiles_dir}/git/get_repos.sh"; then
            echo "Warning: Failed to clone some GitHub repositories"
            # Don't fail the entire step for this
        fi
    fi

    return 0
}

# Main installation orchestrator
tomdot_install() {
    local steps=(
        "ssh_setup"
        "homebrew"
        "packages"
        "languages"
        "symlinks"
    )

    ui_welcome_header

    # Show prerequisite information
    ui_start_section "Prerequisites Check"
    printf "${C_DIM}│${C_RESET} ${C_DIM}Before we begin, please ensure:${C_RESET}\n"
    printf "${C_DIM}│${C_RESET} ${C_DIM}• You are logged into the App Store${C_RESET}\n"
    printf "${C_DIM}│${C_RESET} ${C_DIM}• Xcode + Command Line Tools are installed${C_RESET}\n"
    printf "${C_DIM}│${C_RESET} ${C_DIM}• macOS is updated to the latest version${C_RESET}\n"
    printf "${C_DIM}│${C_RESET}\n"

    # Run prerequisite validation
    if ! tomdot_check_prerequisites; then
        printf "${C_DIM}│${C_RESET} ${C_RED}Prerequisites validation failed!${C_RESET}\n"
        printf "${C_DIM}│${C_RESET} ${C_DIM}Please resolve the issues above before continuing.${C_RESET}\n"
        printf "${C_DIM}│${C_RESET}\n"
        return 1
    fi

    printf "${C_DIM}│${C_RESET} ${C_GREEN}✓ Prerequisites validated${C_RESET}\n"
    printf "${C_DIM}│${C_RESET}\n"

    ui_end_section

    ui_start_section "Ready to setup your macOS environment?"
    printf "${C_DIM}│${C_RESET}   Press enter to continue\n"
    read -r
    printf "${C_DIM}│${C_RESET}\n"
    printf "${C_DIM}│${C_RESET} ${C_GREEN}✓${C_RESET} ${C_DIM}Starting installation...${C_RESET}\n"
    printf "${C_DIM}│${C_RESET}\n"

    ui_end_section

    # Execute installation steps
    tomdot_execute_step "ssh_setup" "install_ssh_setup" "Set up SSH keys and GitHub authentication"
    tomdot_execute_step "homebrew" "install_homebrew" "Install Homebrew package manager"
    tomdot_execute_step "packages" "install_packages" "Install packages from Brewfile"
    tomdot_execute_step "languages" "install_languages" "Install Node.js and Rust toolchains"
    tomdot_execute_step "symlinks" "create_symlinks" "Create dotfiles symlinks"

    # End the installation section properly
    ui_end_section
}

# Resume installation from failure point
tomdot_resume() {
    local steps=(
        "ssh_setup"
        "homebrew"
        "packages"
        "languages"
        "symlinks"
    )

    if ! tomdot_can_resume; then
        echo "No previous installation found. Starting fresh installation..."
        tomdot_install
        return $?
    fi

    local installation_id=$(tomdot_get_state "installation_id")
    local started_at=$(tomdot_get_state "started_at")
    local completed_steps=$(tomdot_get_state "completed_steps")
    local failed_steps=$(tomdot_get_state "failed_steps")

    clear
    local username=$(whoami)
    echo
    printf "Hello ${username}, welcome back to ${C_CYAN}tomdot${C_RESET}!\n"
    echo

    ui_start_section "Resuming installation"
    printf "${C_DIM}│${C_RESET} ${C_DIM}Installation ID: $installation_id${C_RESET}\n"
    printf "${C_DIM}│${C_RESET} ${C_DIM}Started: $started_at${C_RESET}\n"
    printf "${C_DIM}│${C_RESET} ${C_DIM}Completed steps: ${completed_steps:-none}${C_RESET}\n"
    if [[ -n "$failed_steps" ]]; then
        printf "${C_DIM}│${C_RESET} ${C_RED}Failed steps: $failed_steps${C_RESET}\n"
    fi
    printf "${C_DIM}│${C_RESET}\n"

    local resume_step=$(tomdot_find_resume_step "${steps[@]}")

    if [[ -z "$resume_step" ]]; then
        ui_start_section "Installation already complete!"
        printf "${C_DIM}│${C_RESET} ${C_GREEN}All steps have been completed successfully${C_RESET}\n"
        printf "${C_DIM}│${C_RESET}\n"

        # All steps already completed
        return 0
    fi

    ui_start_section "Ready to resume from '$resume_step'?"
    printf "${C_DIM}│${C_RESET} ${C_DIM}Press enter to continue${C_RESET}\n"
    read -r
    printf "${C_DIM}│${C_RESET}\n"

    # Execute remaining steps
    local found_resume_point=false
    for step in "${steps[@]}"; do
        if [[ "$step" == "$resume_step" ]]; then
            found_resume_point=true
        fi

        if [[ "$found_resume_point" == true ]]; then
            case "$step" in
                "ssh_setup")
                    tomdot_execute_step "ssh_setup" "install_ssh_setup" "Set up SSH keys and GitHub authentication"
                    ;;
                "homebrew")
                    tomdot_execute_step "homebrew" "install_homebrew" "Install Homebrew package manager"
                    ;;
                "packages")
                    tomdot_execute_step "packages" "install_packages" "Install packages from Brewfile"
                    ;;
                "languages")
                    tomdot_execute_step "languages" "install_languages" "Install Node.js and Rust toolchains"
                    ;;
                "symlinks")
                    tomdot_execute_step "symlinks" "create_symlinks" "Create dotfiles symlinks"
                    ;;
            esac
        fi
    done

    # Resume completed
}

# Run individual installation step
tomdot_run_step() {
    local step_name="$1"

    case "$step_name" in
        "ssh"|"ssh_setup")
            tomdot_execute_step "ssh_setup" "install_ssh_setup" "Set up SSH keys and GitHub authentication"
            ;;
        "homebrew"|"brew")
            tomdot_execute_step "homebrew" "install_homebrew" "Install Homebrew package manager"
            ;;
        "packages"|"pkg")
            tomdot_execute_step "packages" "install_packages" "Install packages from Brewfile"
            ;;
        "languages"|"lang")
            tomdot_execute_step "languages" "install_languages" "Install Node.js and Rust toolchains"
            ;;
        "symlinks"|"links")
            tomdot_execute_step "symlinks" "create_symlinks" "Create dotfiles symlinks"
            ;;
        *)
            echo "Unknown step: $step_name"
            echo "Available steps: ssh, homebrew, packages, languages, symlinks"
            return 1
            ;;
    esac
}

# Backup and rollback functions
tomdot_backup_file() {
    local file_path="$1"
    local backup_name="${2:-$(basename "$file_path")}"

    if [[ ! -e "$file_path" ]]; then
        echo "File does not exist: $file_path"
        return 0  # Not an error if file doesn't exist
    fi

    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_path="${TOMDOT_BACKUP_DIR}/${backup_name}.backup.${timestamp}"

    # Create backup directory if it doesn't exist
    mkdir -p "$TOMDOT_BACKUP_DIR"

    if cp -R "$file_path" "$backup_path"; then
        echo "Backed up: $file_path -> $backup_path"

        # Record backup in state
        tomdot_record_backup "$file_path" "$backup_path"
        return 0
    else
        echo "Failed to backup: $file_path"
        return 1
    fi
}

tomdot_record_backup() {
    local original_path="$1"
    local backup_path="$2"

    local temp_file="${TOMDOT_STATE_FILE}.tmp"

    python3 << EOF > "$temp_file"
import json

try:
    with open("$TOMDOT_STATE_FILE", "r") as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {"backups": {}}

if "backups" not in data:
    data["backups"] = {}

data["backups"]["$original_path"] = "$backup_path"

print(json.dumps(data, indent=2))
EOF

    if [[ -f "$temp_file" ]]; then
        mv "$temp_file" "$TOMDOT_STATE_FILE"
    fi
}

tomdot_backup_existing_configs() {
    echo "Backing up existing configurations..."

    # List of files to backup before modification
    local files_to_backup=(
        "${HOME}/.gitconfig"
        "${HOME}/.gitignore_global"
        "${HOME}/.zshrc"
        "${HOME}/.zprofile"
        "${HOME}/.config/starship.toml"
        "${HOME}/.config/bat/bat.conf"
        "${HOME}/.config/ghostty/config"
        "${HOME}/.ssh/config"
    )

    local backup_count=0

    for file_path in "${files_to_backup[@]}"; do
        if [[ -e "$file_path" ]]; then
            if tomdot_backup_file "$file_path"; then
                ((backup_count++))
            fi
        fi
    done

    echo "Backed up $backup_count configuration files"
    return 0
}

tomdot_rollback_step() {
    local step_name="$1"

    echo "Rolling back step: $step_name"

    case "$step_name" in
        "ssh_setup")
            tomdot_rollback_ssh_setup
            ;;
        "homebrew")
            echo "Warning: Homebrew rollback not implemented (complex operation)"
            ;;
        "packages")
            echo "Warning: Package rollback not implemented (would require uninstalling all packages)"
            ;;
        "languages")
            tomdot_rollback_languages
            ;;
        "symlinks")
            tomdot_rollback_symlinks
            ;;
        *)
            echo "Unknown step for rollback: $step_name"
            return 1
            ;;
    esac
}

tomdot_rollback_ssh_setup() {
    local ssh_dir="${HOME}/.ssh"

    # Restore SSH config from backup
    if [[ -f "$TOMDOT_STATE_FILE" ]]; then
        local backup_path=$(python3 -c "
import json
try:
    with open('$TOMDOT_STATE_FILE', 'r') as f:
        data = json.load(f)
    backups = data.get('backups', {})
    print(backups.get('${ssh_dir}/config', ''))
except:
    pass
")

        if [[ -n "$backup_path" && -f "$backup_path" ]]; then
            cp "$backup_path" "${ssh_dir}/config"
            echo "Restored SSH config from backup"
        fi
    fi

    # Note: We don't remove SSH keys as they might be used elsewhere
    echo "SSH setup rollback completed (SSH keys preserved)"
}

tomdot_rollback_languages() {
    # Remove fnm Node.js installations (keep fnm itself)
    if command -v fnm >/dev/null 2>&1; then
        echo "Removing Node.js installations..."
        fnm list | grep -E "v[0-9]+" | while read -r version; do
            fnm uninstall "$version" 2>/dev/null || true
        done
    fi

    # Note: We don't remove Rust as it's installed to user directory
    echo "Language rollback completed"
}

tomdot_rollback_symlinks() {
    echo "Removing symlinks and restoring backups..."

    # List of symlinks to remove
    local symlinks=(
        "${HOME}/.gitconfig"
        "${HOME}/.gitignore_global"
        "${HOME}/.zshrc"
        "${HOME}/.zprofile"
        "${HOME}/.config/starship.toml"
        "${HOME}/.config/bat/bat.conf"
        "${HOME}/.config/ghostty/config"
    )

    # Remove symlinks and restore from backups
    for symlink_path in "${symlinks[@]}"; do
        if [[ -L "$symlink_path" ]]; then
            rm -f "$symlink_path"
            echo "Removed symlink: $symlink_path"

            # Restore from backup if available
            if [[ -f "$TOMDOT_STATE_FILE" ]]; then
                local backup_path=$(python3 -c "
import json
try:
    with open('$TOMDOT_STATE_FILE', 'r') as f:
        data = json.load(f)
    backups = data.get('backups', {})
    print(backups.get('$symlink_path', ''))
except:
    pass
")

                if [[ -n "$backup_path" && -f "$backup_path" ]]; then
                    cp "$backup_path" "$symlink_path"
                    echo "Restored from backup: $symlink_path"
                fi
            fi
        fi
    done

    echo "Symlinks rollback completed"
}

tomdot_validate_step() {
    local step_name="$1"

    case "$step_name" in
        "ssh_setup")
            tomdot_validate_ssh_setup
            ;;
        "homebrew")
            tomdot_validate_homebrew
            ;;
        "packages")
            tomdot_validate_packages
            ;;
        "languages")
            tomdot_validate_languages
            ;;
        "symlinks")
            tomdot_validate_symlinks
            ;;
        *)
            echo "Unknown step for validation: $step_name"
            return 1
            ;;
    esac
}

tomdot_validate_ssh_setup() {
    local ssh_key="${HOME}/.ssh/id_rsa"
    local ssh_config="${HOME}/.ssh/config"

    # Check SSH key exists
    if [[ ! -f "$ssh_key" ]]; then
        echo "Validation failed: SSH key not found"
        return 1
    fi

    # Check SSH config exists
    if [[ ! -f "$ssh_config" ]]; then
        echo "Validation failed: SSH config not found"
        return 1
    fi

    # Test GitHub connection
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "SSH setup validation passed"
        return 0
    else
        echo "Validation failed: GitHub SSH authentication failed"
        return 1
    fi
}

tomdot_validate_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew validation passed"
        return 0
    else
        echo "Validation failed: Homebrew not found"
        return 1
    fi
}

tomdot_validate_packages() {
    # Check for key packages that should be installed
    local key_packages=("git" "fnm" "bat" "starship")
    local missing_packages=()

    for package in "${key_packages[@]}"; do
        if ! command -v "$package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        echo "Package validation passed"
        return 0
    else
        echo "Validation failed: Missing packages: ${missing_packages[*]}"
        return 1
    fi
}

tomdot_validate_languages() {
    # Check Rust - source environment if needed
    if ! command -v rustc >/dev/null 2>&1; then
        # Try sourcing Rust environment
        if [[ -f "$HOME/.cargo/env" ]]; then
            source "$HOME/.cargo/env"
        fi

        # Check again after sourcing
        if ! command -v rustc >/dev/null 2>&1; then
            echo "Validation failed: Rust not found"
            return 1
        fi
    fi

    # Check Node.js
    if ! command -v node >/dev/null 2>&1; then
        echo "Validation failed: Node.js not found"
        return 1
    fi

    # Check fnm
    if ! command -v fnm >/dev/null 2>&1; then
        echo "Validation failed: fnm not found"
        return 1
    fi

    echo "Language validation passed"
    return 0
}

tomdot_validate_symlinks() {
    local symlinks=(
        "${HOME}/.gitconfig"
        "${HOME}/.zshrc"
        "${HOME}/.config/starship.toml"
    )

    local missing_symlinks=()

    for symlink_path in "${symlinks[@]}"; do
        if [[ ! -L "$symlink_path" ]]; then
            missing_symlinks+=("$symlink_path")
        fi
    done

    if [[ ${#missing_symlinks[@]} -eq 0 ]]; then
        echo "Symlinks validation passed"
        return 0
    else
        echo "Validation failed: Missing symlinks: ${missing_symlinks[*]}"
        return 1
    fi
}

# Export main functions
export -f tomdot_init_state
export -f tomdot_execute_step
export -f tomdot_install
export -f tomdot_resume
export -f tomdot_run_step
export -f tomdot_backup_existing_configs
export -f tomdot_rollback_step
export -f tomdot_validate_step
