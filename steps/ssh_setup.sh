#!/bin/bash

# Step Definition
STEP_ID="ssh_setup"
STEP_NAME="SSH Key Generation and GitHub Authentication"
STEP_DESCRIPTION="Generates SSH keys, configures SSH, and authenticates with GitHub"
STEP_DEPENDENCIES=("prerequisites")
STEP_ESTIMATED_TIME=120  # seconds (includes user interaction)
STEP_CATEGORY="authentication"
STEP_CRITICAL=true

# Source required libraries
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh"
elif [ -f "lib/progress.sh" ]; then
    source "lib/progress.sh"
fi

# Configuration
SSH_DIR="${HOME}/.ssh"
SSH_KEY_PATH="${SSH_DIR}/id_rsa"
SSH_CONFIG_PATH="${SSH_DIR}/config"
SSH_EMAIL="tom.hendra@outlook.com"

execute_ssh_setup_step() {
    log_operation "Starting SSH setup and GitHub authentication" "info"

    # Create SSH directory
    if ! setup_ssh_directory; then
        return 1
    fi

    # Setup SSH configuration
    if ! setup_ssh_config; then
        return 1
    fi

    # Generate or reuse SSH key
    if ! setup_ssh_key; then
        return 1
    fi

    # Authenticate with GitHub
    if ! authenticate_github; then
        return 1
    fi

    log_operation "SSH setup and GitHub authentication completed successfully" "success"
    return 0
}

setup_ssh_directory() {
    log_operation "Setting up SSH directory" "info"

    if [ ! -d "$SSH_DIR" ]; then
        if ! mkdir -p "$SSH_DIR"; then
            log_operation "Failed to create SSH directory: $SSH_DIR" "error"
            return 1
        fi
        chmod 700 "$SSH_DIR"
        log_operation "Created SSH directory: $SSH_DIR" "success"
    else
        log_operation "SSH directory already exists: $SSH_DIR" "info"
    fi

    return 0
}

setup_ssh_config() {
    log_operation "Setting up SSH configuration" "info"

    if [ ! -f "$SSH_CONFIG_PATH" ]; then
        cat > "$SSH_CONFIG_PATH" << EOF
Host *
    PreferredAuthentications publickey
    UseKeychain yes
    IdentityFile ${SSH_KEY_PATH}
EOF
        chmod 600 "$SSH_CONFIG_PATH"
        log_operation "Created SSH config file: $SSH_CONFIG_PATH" "success"
    else
        log_operation "SSH config file already exists, checking configuration" "info"

        # Check if our configuration is present
        if ! grep -q "IdentityFile ${SSH_KEY_PATH}" "$SSH_CONFIG_PATH"; then
            log_operation "Adding identity file configuration to existing SSH config" "info"
            echo "" >> "$SSH_CONFIG_PATH"
            echo "# Added by dotfiles installation" >> "$SSH_CONFIG_PATH"
            echo "Host *" >> "$SSH_CONFIG_PATH"
            echo "    IdentityFile ${SSH_KEY_PATH}" >> "$SSH_CONFIG_PATH"
        fi
    fi

    return 0
}

setup_ssh_key() {
    log_operation "Setting up SSH key" "info"

    if [ -f "$SSH_KEY_PATH" ]; then
        log_operation "SSH key already exists, validating" "info"

        # Validate existing key
        if ssh-keygen -l -f "$SSH_KEY_PATH" &>/dev/null; then
            log_operation "Existing SSH key is valid, reusing" "success"

            # Add to SSH agent if not already added
            if ! ssh-add -l | grep -q "$SSH_KEY_PATH" 2>/dev/null; then
                log_operation "Adding existing SSH key to agent" "info"
                ssh-add "$SSH_KEY_PATH" 2>/dev/null || true
            fi
        else
            log_operation "Existing SSH key is invalid, generating new one" "warning"
            backup_existing_key
            generate_new_key
        fi
    else
        log_operation "No SSH key found, generating new one" "info"
        generate_new_key
    fi

    return 0
}

backup_existing_key() {
    local backup_path="${SSH_KEY_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    log_operation "Backing up existing SSH key to: $backup_path" "info"

    cp "$SSH_KEY_PATH" "$backup_path" 2>/dev/null || true
    cp "${SSH_KEY_PATH}.pub" "${backup_path}.pub" 2>/dev/null || true
}

generate_new_key() {
    log_operation "Generating new SSH key" "info"

    if ! ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -C "$SSH_EMAIL" -N ""; then
        log_operation "Failed to generate SSH key" "error"
        return 1
    fi

    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "${SSH_KEY_PATH}.pub"

    log_operation "SSH key generated successfully" "success"

    # Start SSH agent and add key
    if ! start_ssh_agent; then
        log_operation "Warning: Could not start SSH agent" "warning"
    fi

    return 0
}

start_ssh_agent() {
    log_operation "Starting SSH agent and adding key" "info"

    # Start SSH agent if not running
    if [ -z "${SSH_AUTH_SOCK:-}" ]; then
        eval "$(ssh-agent -s)" > "${HOME}/.ssh-agent-info"
    fi

    # Add key to agent
    if ! ssh-add "$SSH_KEY_PATH" 2>/dev/null; then
        log_operation "Could not add SSH key to agent" "warning"
        return 1
    fi

    log_operation "SSH key added to agent" "success"
    return 0
}

authenticate_github() {
    log_operation "Setting up GitHub authentication" "info"

    # Copy public key to clipboard
    if command -v pbcopy >/dev/null 2>&1; then
        pbcopy < "${SSH_KEY_PATH}.pub"
        log_operation "Public key copied to clipboard" "success"
    else
        log_operation "pbcopy not available, please manually copy the public key" "warning"
        echo "Public key content:"
        cat "${SSH_KEY_PATH}.pub"
    fi

    # Prompt user to add key to GitHub
    log_operation "Prompting user to add SSH key to GitHub" "info"

    if command -v osascript >/dev/null 2>&1; then
        osascript -e 'display dialog "📋 Public key copied to clipboard. Press OK to add it to GitHub..." buttons {"OK"}' 2>/dev/null || {
            echo "📋 Public key copied to clipboard. Press Enter to continue to GitHub..."
            read -r
        }

        # Open GitHub SSH keys page
        if command -v open >/dev/null 2>&1; then
            open https://github.com/settings/keys
        else
            echo "Please visit: https://github.com/settings/keys"
        fi

        osascript -e 'display dialog "🔑 Press OK after you have added the SSH key to your GitHub account..." buttons {"OK"}' 2>/dev/null || {
            echo "🔑 Press Enter after you have added the SSH key to your GitHub account..."
            read -r
        }
    else
        echo "📋 Public key copied to clipboard."
        echo "Please add it to GitHub at: https://github.com/settings/keys"
        echo "Press Enter after you have added the SSH key to your GitHub account..."
        read -r
    fi

    # Test GitHub authentication
    log_operation "Testing GitHub SSH authentication" "info"

    local auth_attempts=0
    local max_attempts=3

    while [ $auth_attempts -lt $max_attempts ]; do
        if ssh -T git@github.com -o ConnectTimeout=10 -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
            log_operation "GitHub authentication successful" "success"
            return 0
        fi

        auth_attempts=$((auth_attempts + 1))
        if [ $auth_attempts -lt $max_attempts ]; then
            log_operation "GitHub authentication failed, retrying in 5 seconds... (attempt $auth_attempts/$max_attempts)" "warning"
            sleep 5
        fi
    done

    log_operation "GitHub authentication failed after $max_attempts attempts" "error"
    echo "Please verify that:"
    echo "1. You have added the SSH key to your GitHub account"
    echo "2. Your internet connection is working"
    echo "3. GitHub is accessible from your network"
    return 1
}

validate_ssh_setup_step() {
    log_operation "Validating SSH setup" "info"

    # Check SSH key exists and is valid
    if [ ! -f "$SSH_KEY_PATH" ] || ! ssh-keygen -l -f "$SSH_KEY_PATH" &>/dev/null; then
        log_operation "SSH key validation failed" "error"
        return 1
    fi

    # Check SSH config exists
    if [ ! -f "$SSH_CONFIG_PATH" ]; then
        log_operation "SSH config validation failed" "error"
        return 1
    fi

    # Test GitHub authentication
    if ! ssh -T git@github.com -o ConnectTimeout=10 2>&1 | grep -q "successfully authenticated"; then
        log_operation "GitHub authentication validation failed" "error"
        return 1
    fi

    log_operation "SSH setup validation successful" "success"
    return 0
}

rollback_ssh_setup_step() {
    log_operation "Rolling back SSH setup" "info"

    # Remove generated SSH key if it was created in this session
    local backup_files
    backup_files=$(find "$SSH_DIR" -name "id_rsa.backup.*" 2>/dev/null | head -1)

    if [ -n "$backup_files" ]; then
        log_operation "Restoring backed up SSH key" "info"
        cp "$backup_files" "$SSH_KEY_PATH" 2>/dev/null || true
        cp "${backup_files}.pub" "${SSH_KEY_PATH}.pub" 2>/dev/null || true
    else
        log_operation "Removing generated SSH key" "info"
        rm -f "$SSH_KEY_PATH" "${SSH_KEY_PATH}.pub" 2>/dev/null || true
    fi

    # Remove SSH config if we created it
    if [ -f "$SSH_CONFIG_PATH" ] && grep -q "Added by dotfiles installation" "$SSH_CONFIG_PATH"; then
        log_operation "Removing SSH config modifications" "info"
        sed -i '' '/# Added by dotfiles installation/,$d' "$SSH_CONFIG_PATH" 2>/dev/null || true
    fi

    log_operation "SSH setup rollback completed" "info"
    return 0
}
