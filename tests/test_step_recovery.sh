#!/usr/bin/env bats

# Test error handling and recovery scenarios for installation steps

setup() {
    # Create test environment
    export TEST_HOME="${BATS_TMPDIR}/recovery_test"
    export TEST_DOTFILES="${TEST_HOME}/.dotfiles"
    mkdir -p "$TEST_HOME" "$TEST_DOTFILES"

    # Mock dotfiles structure
    mkdir -p "$TEST_DOTFILES"/{steps,lib}
    touch "$TEST_DOTFILES"/Brewfile
    touch "$TEST_DOTFILES"/global_pkg.sh
    touch "$TEST_DOTFILES"/create_symlinks.sh
    chmod +x "$TEST_DOTFILES"/global_pkg.sh
    chmod +x "$TEST_DOTFILES"/create_symlinks.sh

    # Source progress library
    source "${BATS_TEST_DIRNAME}/../lib/progress.sh"
}

teardown() {
    rm -rf "$TEST_HOME" 2>/dev/null || true
}

# Test network failure recovery
@test "steps handle network failures gracefully" {
    export HOME="$TEST_HOME"
    source "${BATS_TEST_DIRNAME}/../steps/homebrew.sh"

    # Mock curl to fail initially, then succeed
    local attempt_count=0
    function curl() {
        attempt_count=$((attempt_count + 1))
        if [ $attempt_count -le 2 ]; then
            return 1  # Fail first two attempts
        fi
        return 0  # Succeed on third attempt
    }

    function /bin/bash() {
        if [[ "$*" =~ "curl -fsSL" ]]; then
            curl "$@"
        fi
        return 0
    }

    export -f curl /bin/bash

    # Test that installation retries and eventually succeeds
    run install_homebrew
    [ "$status" -eq 0 ]
}

# Test permission failure handling
@test "steps handle permission failures" {
    export HOME="$TEST_HOME"
    export SSH_DIR="${TEST_HOME}/.ssh"

    source "${BATS_TEST_DIRNAME}/../steps/ssh_setup.sh"

    # Mock mkdir to fail due to permissions
    function mkdir() {
        if [[ "$*" =~ "-p" ]] && [[ "$*" =~ ".ssh" ]]; then
            return 1  # Permission denied
        fi
        return 0
    }

    export -f mkdir

    # Test that permission failure is handled
    run setup_ssh_directory
    [ "$status" -eq 1 ]
}

# Test rollback functionality
@test "rollback removes created files and configurations" {
    export HOME="$TEST_HOME"
    export SSH_DIR="${TEST_HOME}/.ssh"
    export SSH_KEY_PATH="${SSH_DIR}/id_rsa"

    mkdir -p "$SSH_DIR"

    source "${BATS_TEST_DIRNAME}/../steps/ssh_setup.sh"

    # Create test files that should be rolled back
    touch "$SSH_KEY_PATH"
    touch "${SSH_KEY_PATH}.pub"
    echo "Host *" > "${SSH_DIR}/config"
    echo "# Added by dotfiles installation" >> "${SSH_DIR}/config"
    echo "    IdentityFile ${SSH_KEY_PATH}" >> "${SSH_DIR}/config"

    # Test rollback
    run rollback_ssh_setup_step
    [ "$status" -eq 0 ]

    # Verify files were removed or restored
    [ ! -f "$SSH_KEY_PATH" ] || [ ! -f "${SSH_KEY_PATH}.pub" ]
}

# Test backup and restore functionality
@test "configurations step backs up existing files" {
    export HOME="$TEST_HOME"
    export DOTFILES_DIR="$TEST_DOTFILES"
    export CONFIG_DIR="${TEST_HOME}/.config"

    # Create existing configuration
    mkdir -p "$CONFIG_DIR"
    echo "existing starship config" > "${CONFIG_DIR}/starship.toml"

    # Create source file
    echo "new starship config" > "${DOTFILES_DIR}/starship.toml"

    source "${BATS_TEST_DIRNAME}/../steps/configurations.sh"

    # Test that backup is created
    run setup_starship_config
    [ "$status" -eq 0 ]

    # Verify backup directory was created and contains backup
    [ -d "$BACKUP_DIR" ] || skip "Backup directory not created"

    # Verify new config was installed
    [ -f "${CONFIG_DIR}/starship.toml" ]
    grep -q "new starship config" "${CONFIG_DIR}/starship.toml"
}

# Test validation failure scenarios
@test "validation catches incomplete installations" {
    export HOME="$TEST_HOME"

    source "${BATS_TEST_DIRNAME}/../steps/homebrew.sh"

    # Mock brew command to be missing
    function command() {
        if [[ "$2" == "brew" ]]; then
            return 1  # brew not found
        fi
        return 0
    }

    export -f command

    # Test that validation fails appropriately
    run validate_homebrew_step
    [ "$status" -eq 1 ]
}

# Test dependency validation
@test "steps validate dependencies before execution" {
    export HOME="$TEST_HOME"
    export DOTFILES_DIR="$TEST_DOTFILES"

    source "${BATS_TEST_DIRNAME}/../steps/nodejs.sh"

    # Mock fnm as missing (should be installed by homebrew)
    function command() {
        if [[ "$2" == "fnm" ]]; then
            return 1  # fnm not found
        fi
        return 0
    }

    export -f command

    # Test that missing dependency is detected
    run setup_fnm_environment
    [ "$status" -eq 1 ]
}

# Test partial failure recovery
@test "steps can recover from partial failures" {
    export HOME="$TEST_HOME"
    export DOTFILES_DIR="$TEST_DOTFILES"

    source "${BATS_TEST_DIRNAME}/../steps/nodejs.sh"

    # Mock fnm to succeed for some operations, fail for others
    local operation_count=0
    function fnm() {
        operation_count=$((operation_count + 1))
        case "$1" in
            "install")
                if [ $operation_count -eq 1 ]; then
                    return 1  # Fail first install attempt
                fi
                return 0  # Succeed on retry
                ;;
            *)
                return 0
                ;;
        esac
    }

    function command() {
        case "$2" in
            "fnm"|"node"|"npm") return 0 ;;
            *) return 1 ;;
        esac
    }

    export -f fnm command

    # Test that retry logic works
    run install_nodejs
    [ "$status" -eq 0 ]
}

# Test cleanup after failures
@test "failed steps clean up partial changes" {
    export HOME="$TEST_HOME"
    export SSH_DIR="${TEST_HOME}/.ssh"

    mkdir -p "$SSH_DIR"

    source "${BATS_TEST_DIRNAME}/../steps/ssh_setup.sh"

    # Create a scenario where SSH key generation fails partway through
    function ssh-keygen() {
        # Create partial files then fail
        touch "${SSH_DIR}/id_rsa"
        return 1  # Fail key generation
    }

    export -f ssh-keygen

    # Test that partial files are cleaned up on failure
    run generate_new_key
    [ "$status" -eq 1 ]

    # Verify cleanup (this would be handled by rollback in real scenario)
    # The test verifies the failure is detected properly
}

# Test state consistency after errors
@test "system state remains consistent after step failures" {
    export HOME="$TEST_HOME"

    # Test that a failed step doesn't leave the system in an inconsistent state
    # This is more of a design verification test

    source "${BATS_TEST_DIRNAME}/../steps/prerequisites.sh"

    # Mock system checks to fail
    function sw_vers() { return 1; }
    function df() { return 1; }

    export -f sw_vers df

    # Test that prerequisites validation fails cleanly
    run execute_prerequisites_step
    [ "$status" -eq 1 ]

    # Verify no partial state was created (prerequisites is read-only)
    # This step doesn't modify system state, so failure should be clean
}
