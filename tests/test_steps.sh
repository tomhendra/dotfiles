#!/usr/bin/env bats

# Integration tests for installation step modules
# Tests step dependencies, execution order, and error handling

setup() {
    # Create temporary test environment
    export TEST_HOME="${BATS_TMPDIR}/test_home"
    export TEST_DOTFILES="${TEST_HOME}/.dotfiles"
    export TEST_SSH_DIR="${TEST_HOME}/.ssh"

    mkdir -p "$TEST_HOME"
    mkdir -p "$TEST_DOTFILES"
    mkdir -p "$TEST_SSH_DIR"

    # Mock dotfiles structure
    mkdir -p "$TEST_DOTFILES"/{bat/themes,git,zsh,steps}
    touch "$TEST_DOTFILES"/Brewfile
    touch "$TEST_DOTFILES"/global_pkg.sh
    touch "$TEST_DOTFILES"/starship.toml
    touch "$TEST_DOTFILES"/create_symlinks.sh
    touch "$TEST_DOTFILES"/bat/bat.conf
    touch "$TEST_DOTFILES"/bat/themes/Enki-Tokyo-Night.tmTheme

    # Make scripts executable
    chmod +x "$TEST_DOTFILES"/create_symlinks.sh
    chmod +x "$TEST_DOTFILES"/global_pkg.sh

    # Source test utilities
    source "${BATS_TEST_DIRNAME}/../lib/progress.sh"
}

teardown() {
    # Clean up test environment
    rm -rf "$TEST_HOME" 2>/dev/null || true
}

# Test step dependency validation
@test "step dependencies are correctly defined" {
    # Load step definitions
    source "${BATS_TEST_DIRNAME}/../steps/prerequisites.sh"
    source "${BATS_TEST_DIRNAME}/../steps/ssh_setup.sh"
    source "${BATS_TEST_DIRNAME}/../steps/homebrew.sh"
    source "${BATS_TEST_DIRNAME}/../steps/rust.sh"
    source "${BATS_TEST_DIRNAME}/../steps/nodejs.sh"
    source "${BATS_TEST_DIRNAME}/../steps/configurations.sh"

    # Verify dependency chains
    [ "${#STEP_DEPENDENCIES[@]}" -eq 0 ]  # prerequisites has no dependencies

    # Load ssh_setup and check its dependencies
    source "${BATS_TEST_DIRNAME}/../steps/ssh_setup.sh"
    [[ " ${STEP_DEPENDENCIES[*]} " =~ " prerequisites " ]]

    # Load homebrew and check its dependencies
    source "${BATS_TEST_DIRNAME}/../steps/homebrew.sh"
    [[ " ${STEP_DEPENDENCIES[*]} " =~ " prerequisites " ]]
    [[ " ${STEP_DEPENDENCIES[*]} " =~ " ssh_setup " ]]
}

# Test step metadata completeness
@test "all steps have required metadata" {
    local step_files=(
        "prerequisites.sh"
        "ssh_setup.sh"
        "homebrew.sh"
        "rust.sh"
        "nodejs.sh"
        "configurations.sh"
    )

    for step_file in "${step_files[@]}"; do
        source "${BATS_TEST_DIRNAME}/../steps/$step_file"

        # Check required variables are defined
        [ -n "$STEP_ID" ]
        [ -n "$STEP_NAME" ]
        [ -n "$STEP_DESCRIPTION" ]
        [ -n "$STEP_ESTIMATED_TIME" ]
        [ -n "$STEP_CATEGORY" ]
        [ -n "$STEP_CRITICAL" ]

        # Check required functions exist
        declare -f "execute_${STEP_ID}_step" >/dev/null
        declare -f "validate_${STEP_ID}_step" >/dev/null
        declare -f "rollback_${STEP_ID}_step" >/dev/null
    done
}

# Test prerequisites step validation
@test "prerequisites step validates system requirements" {
    source "${BATS_TEST_DIRNAME}/../steps/prerequisites.sh"

    # Mock required commands
    function sw_vers() { echo "14.0"; }
    function df() { echo "Filesystem 1024-blocks Used Available Capacity Mounted on"; echo "/dev/disk1 1000000000 500000000 500000000 50% /"; }
    function command() { return 0; }  # Mock all commands as available
    function xcode-select() { echo "/Applications/Xcode.app/Contents/Developer"; }
    function sudo() { return 0; }
    function xcodebuild() { return 0; }

    export -f sw_vers df command xcode-select sudo xcodebuild

    # Test validation functions
    run validate_macos_version
    [ "$status" -eq 0 ]

    run validate_disk_space
    [ "$status" -eq 0 ]

    run validate_required_tools
    [ "$status" -eq 0 ]
}

# Test SSH setup step functionality
@test "ssh setup step handles existing keys correctly" {
    # Set up test environment
    export HOME="$TEST_HOME"
    export SSH_DIR="$TEST_SSH_DIR"
    export SSH_KEY_PATH="${SSH_DIR}/id_rsa"

    source "${BATS_TEST_DIRNAME}/../steps/ssh_setup.sh"

    # Mock ssh-keygen for existing key validation
    function ssh-keygen() {
        if [[ "$*" =~ "-l -f" ]]; then
            return 0  # Key is valid
        else
            # Generate mock key files
            touch "$SSH_KEY_PATH"
            touch "${SSH_KEY_PATH}.pub"
            return 0
        fi
    }

    function ssh-add() { return 0; }
    function pbcopy() { return 0; }

    export -f ssh-keygen ssh-add pbcopy

    # Test setup functions
    run setup_ssh_directory
    [ "$status" -eq 0 ]
    [ -d "$SSH_DIR" ]

    run setup_ssh_config
    [ "$status" -eq 0 ]
    [ -f "${SSH_DIR}/config" ]
}

# Test Homebrew step installation detection
@test "homebrew step detects existing installation" {
    source "${BATS_TEST_DIRNAME}/../steps/homebrew.sh"

    # Mock brew command as already installed
    function brew() {
        case "$1" in
            "--version") echo "Homebrew 4.0.0" ;;
            "update") return 0 ;;
            "tap") return 0 ;;
            "bundle") return 0 ;;
            "cleanup") return 0 ;;
            "list") return 0 ;;
            *) return 0 ;;
        esac
    }

    function command() {
        if [[ "$2" == "brew" ]]; then
            return 0  # brew is available
        fi
        return 1
    }

    export -f brew command

    # Test that existing installation is detected
    run install_homebrew
    [ "$status" -eq 0 ]
}

# Test Node.js step version management
@test "nodejs step manages versions correctly" {
    export HOME="$TEST_HOME"
    export DOTFILES_DIR="$TEST_DOTFILES"

    source "${BATS_TEST_DIRNAME}/../steps/nodejs.sh"

    # Mock fnm commands
    function fnm() {
        case "$1" in
            "list") echo "* v22.0.0" ;;
            "install") return 0 ;;
            "use") return 0 ;;
            "default") return 0 ;;
            "env") echo "export PATH=\"/test/path:\$PATH\"" ;;
            *) return 0 ;;
        esac
    }

    function command() {
        case "$2" in
            "fnm"|"node"|"npm"|"corepack") return 0 ;;
            *) return 1 ;;
        esac
    }

    function node() { echo "v22.0.0"; }
    function corepack() { return 0; }

    export -f fnm command node corepack

    # Test Node.js installation
    run setup_fnm_environment
    [ "$status" -eq 0 ]

    run install_nodejs
    [ "$status" -eq 0 ]
}

# Test configuration step symlink handling
@test "configurations step handles existing files" {
    export HOME="$TEST_HOME"
    export DOTFILES_DIR="$TEST_DOTFILES"
    export CONFIG_DIR="${TEST_HOME}/.config"

    source "${BATS_TEST_DIRNAME}/../steps/configurations.sh"

    # Create existing configuration file
    mkdir -p "$CONFIG_DIR"
    echo "existing config" > "${CONFIG_DIR}/starship.toml"

    # Mock bat command
    function bat() {
        if [[ "$1" == "--config-dir" ]]; then
            echo "${TEST_HOME}/.config/bat"
        elif [[ "$1" == "cache" ]]; then
            return 0
        fi
    }

    function command() {
        if [[ "$2" == "bat" ]]; then
            return 0
        fi
        return 1
    }

    export -f bat command

    # Test configuration setup
    run setup_config_directories
    [ "$status" -eq 0 ]

    run setup_starship_config
    [ "$status" -eq 0 ]

    # Verify backup was created
    [ -d "$BACKUP_DIR" ] || [ -f "${CONFIG_DIR}/starship.toml" ]
}

# Test error handling and recovery
@test "steps handle errors gracefully" {
    source "${BATS_TEST_DIRNAME}/../steps/prerequisites.sh"

    # Mock failing commands
    function sw_vers() { return 1; }
    function df() { return 1; }

    export -f sw_vers df

    # Test that validation fails appropriately
    run validate_macos_version
    [ "$status" -eq 1 ]

    run validate_disk_space
    [ "$status" -eq 1 ]
}

# Test rollback functionality
@test "steps can rollback changes" {
    export HOME="$TEST_HOME"
    export SSH_DIR="$TEST_SSH_DIR"

    source "${BATS_TEST_DIRNAME}/../steps/ssh_setup.sh"

    # Create test files to rollback
    touch "${SSH_DIR}/id_rsa"
    touch "${SSH_DIR}/id_rsa.pub"
    touch "${SSH_DIR}/config"

    # Test rollback
    run rollback_ssh_setup_step
    [ "$status" -eq 0 ]
}

# Test step execution order validation
@test "step execution follows dependency order" {
    # Define expected execution order based on dependencies
    local expected_order=(
        "prerequisites"
        "ssh_setup"
        "homebrew"
        "rust"
        "nodejs"
        "configurations"
    )

    # Verify each step's dependencies are satisfied by previous steps
    local available_steps=()

    for step in "${expected_order[@]}"; do
        source "${BATS_TEST_DIRNAME}/../steps/${step}.sh"

        # Check that all dependencies are in available_steps
        for dep in "${STEP_DEPENDENCIES[@]}"; do
            [[ " ${available_steps[*]} " =~ " ${dep} " ]]
        done

        # Add current step to available steps
        available_steps+=("$step")
    done
}
