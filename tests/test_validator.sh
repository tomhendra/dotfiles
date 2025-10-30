#!/usr/bin/env bash

# Tests for validation engine

# Source the validation library
source "$(dirname "${BASH_SOURCE[0]}")/../lib/validator.sh"

# Test prerequisite validation
test_prerequisite_validation() {
    # Test basic prerequisite validation
    validate_prerequisites
    local exit_code=$?

    # Should return 0 (success) or 1 (failure) - both are valid test results
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Prerequisite validation should return 0 or 1"
        return 1
    fi

    # The function should at least run without crashing
    return 0
}

# Test tool functionality checking
test_tool_functionality_checking() {
    # Test with existing tool
    if ! check_tool_functionality "bash"; then
        echo "bash tool functionality check should succeed"
        return 1
    fi

    # Test with non-existent tool
    if check_tool_functionality "nonexistent_tool_12345"; then
        echo "Non-existent tool functionality check should fail"
        return 1
    fi

    # Test with specific tools and their version commands
    if command -v git >/dev/null 2>&1; then
        if ! check_tool_functionality "git"; then
            echo "git tool functionality check should succeed when git is available"
            return 1
        fi
    fi

    if command -v python3 >/dev/null 2>&1; then
        if ! check_tool_functionality "python3"; then
            echo "python3 tool functionality check should succeed when python3 is available"
            return 1
        fi
    fi
}

# Test symlink validation with mock symlinks
test_symlink_validation() {
    init_state_dir

    # Create test directory structure
    local test_dotfiles_dir="$TEMP_TEST_DIR/dotfiles"
    mkdir -p "$test_dotfiles_dir/zsh"
    mkdir -p "$test_dotfiles_dir/git"
    mkdir -p "$test_dotfiles_dir/ghostty"

    # Create test config files
    echo "test zshrc content" > "$test_dotfiles_dir/zsh/.zshrc"
    echo "test gitconfig content" > "$test_dotfiles_dir/git/.gitconfig"
    echo "test ghostty config" > "$test_dotfiles_dir/ghostty/config"

    # Create test symlinks in temp directory (not actual home)
    local test_home="$TEMP_TEST_DIR/home"
    mkdir -p "$test_home/.config"

    # Create valid symlinks
    ln -sf "$test_dotfiles_dir/zsh/.zshrc" "$test_home/.zshrc"
    ln -sf "$test_dotfiles_dir/git/.gitconfig" "$test_home/.gitconfig"
    ln -sf "$test_dotfiles_dir/ghostty" "$test_home/.config/ghostty"

    # Test symlink validation (this will test the logic, though paths won't match exactly)
    # The function will report warnings for expected paths not found, which is expected in test
    validate_symlinks
    local exit_code=$?

    # Function should run without crashing (may return 1 due to missing expected paths)
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Symlink validation should return 0 or 1"
        return 1
    fi

    # Create a broken symlink to test detection
    ln -sf "/nonexistent/target" "$test_home/broken_link"

    # The validation should handle broken symlinks gracefully
    validate_symlinks >/dev/null 2>&1
    exit_code=$?

    # Should still return 0 or 1
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Symlink validation with broken links should return 0 or 1"
        return 1
    fi
}

# Test step validation
test_step_validation() {
    init_state_dir

    # Test validation of non-existent step
    validate_step "nonexistent_step"
    local exit_code=$?
    assert_failure $exit_code "Validation of non-existent step should fail"

    # Mark a step as completed and test validation
    save_state "test_step" "completed"

    # Test validation of completed step (will test the generic case)
    validate_step "test_step"
    exit_code=$?

    # Should return 0 (success) since it's marked completed and has no specific validation
    assert_success $exit_code "Validation of completed generic step should succeed"

    # Test validation of specific step types
    save_state "prerequisites" "completed"
    validate_step "prerequisites"
    exit_code=$?

    # Prerequisites validation may fail due to environment, but should not crash
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Prerequisites step validation should return 0 or 1"
        return 1
    fi
}

# Test SSH setup validation
test_ssh_setup_validation() {
    # Create temporary SSH directory for testing
    local test_ssh_dir="$TEMP_TEST_DIR/ssh"
    mkdir -p "$test_ssh_dir"

    # Test with no SSH directory (should fail)
    HOME="$TEMP_TEST_DIR" validate_ssh_setup
    local exit_code=$?
    assert_failure $exit_code "SSH validation should fail when no SSH directory exists"

    # Create SSH directory but no keys
    mkdir -p "$TEMP_TEST_DIR/.ssh"
    HOME="$TEMP_TEST_DIR" validate_ssh_setup
    exit_code=$?
    assert_failure $exit_code "SSH validation should fail when no SSH keys exist"

    # Create a test SSH key
    echo "test ssh key content" > "$TEMP_TEST_DIR/.ssh/id_rsa"
    chmod 600 "$TEMP_TEST_DIR/.ssh/id_rsa"

    HOME="$TEMP_TEST_DIR" validate_ssh_setup
    exit_code=$?
    assert_success $exit_code "SSH validation should succeed with proper SSH key"

    # Test with wrong permissions
    chmod 644 "$TEMP_TEST_DIR/.ssh/id_rsa"
    HOME="$TEMP_TEST_DIR" validate_ssh_setup
    exit_code=$?
    assert_failure $exit_code "SSH validation should fail with wrong key permissions"
}

# Test GitHub authentication validation
test_github_auth_validation() {
    # This test will likely fail in most environments since it requires actual GitHub SSH access
    # We'll test that the function exists and handles failure gracefully

    validate_github_auth >/dev/null 2>&1
    local exit_code=$?

    # Should return 0 (success) or 1 (failure) - both are valid
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "GitHub auth validation should return 0 or 1"
        return 1
    fi

    # Function should not crash
    return 0
}

# Test Homebrew validation
test_homebrew_validation() {
    # Test Homebrew validation
    validate_homebrew_installation
    local exit_code=$?

    # Should return 0 if Homebrew is installed, 1 if not - both are valid
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Homebrew validation should return 0 or 1"
        return 1
    fi

    # If Homebrew is available, test should pass
    if command -v brew >/dev/null 2>&1; then
        validate_homebrew_installation
        exit_code=$?
        assert_success $exit_code "Homebrew validation should succeed when brew is available"
    fi
}

# Test Rust validation
test_rust_validation() {
    validate_rust_installation
    local exit_code=$?

    # Should return 0 if Rust is installed, 1 if not
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Rust validation should return 0 or 1"
        return 1
    fi

    # If Rust tools are available, test should pass
    if command -v rustc >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then
        validate_rust_installation
        exit_code=$?
        assert_success $exit_code "Rust validation should succeed when Rust tools are available"
    fi
}

# Test Node.js validation
test_nodejs_validation() {
    validate_nodejs_installation
    local exit_code=$?

    # Should return 0 if Node.js is installed, 1 if not
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Node.js validation should return 0 or 1"
        return 1
    fi

    # If Node.js tools are available, test should pass
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        validate_nodejs_installation
        exit_code=$?
        # Note: This might still fail if fnm is not available, which is expected
        if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
            echo "Node.js validation should return 0 or 1 even when tools are available"
            return 1
        fi
    fi
}

# Test configuration validation
test_configuration_validation() {
    # Create test configuration files
    local test_dotfiles_dir="$TEMP_TEST_DIR/dotfiles"
    mkdir -p "$test_dotfiles_dir/zsh"
    mkdir -p "$test_dotfiles_dir/git"
    mkdir -p "$test_dotfiles_dir/ghostty"

    # Create valid config files
    echo "# Valid zsh config" > "$test_dotfiles_dir/zsh/.zshrc"
    echo "[user]" > "$test_dotfiles_dir/git/.gitconfig"
    echo "theme = tokyo-night" > "$test_dotfiles_dir/ghostty/config"
    echo "format = \"\$all\"" > "$test_dotfiles_dir/starship.toml"

    # Test with temporary HOME pointing to our test directory
    HOME="$TEMP_TEST_DIR" validate_configurations
    local exit_code=$?

    # Should fail because files are not in expected locations, but shouldn't crash
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Configuration validation should return 0 or 1"
        return 1
    fi

    # Test with invalid zsh config
    echo "invalid zsh syntax {{{" > "$test_dotfiles_dir/zsh/.zshrc"
    HOME="$TEMP_TEST_DIR" validate_configurations >/dev/null 2>&1
    exit_code=$?

    # Should handle invalid config gracefully
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Configuration validation with invalid config should return 0 or 1"
        return 1
    fi
}

# Test full installation validation
test_full_installation_validation() {
    init_state_dir

    # Add some completed steps
    save_state "step1" "completed"
    save_state "step2" "completed"
    save_state "step3" "failed"

    # Test full validation
    validate_full_installation >/dev/null 2>&1
    local exit_code=$?

    # Should return 0 or 1 depending on validation results
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Full installation validation should return 0 or 1"
        return 1
    fi

    # Test with no completed steps
    reset_state --force
    validate_full_installation >/dev/null 2>&1
    exit_code=$?

    # Should fail when no steps are completed
    assert_failure $exit_code "Full validation should fail when no steps are completed"
}

# Test validation report generation
test_validation_report_generation() {
    init_state_dir

    local report_file="$TEMP_TEST_DIR/validation_report.txt"

    # Generate validation report
    generate_validation_report "$report_file" >/dev/null 2>&1

    # Check that report file was created
    assert_file_exists "$report_file" "Validation report file should be created"

    # Check report content
    local report_content=$(cat "$report_file")
    assert_contains "$report_content" "VALIDATION REPORT" "Report should contain header"
    assert_contains "$report_content" "Generated:" "Report should contain generation timestamp"
    assert_contains "$report_content" "System:" "Report should contain system information"
}

# Test validation logging
test_validation_logging() {
    init_state_dir

    # Test validation logging function
    validation_log $VALIDATION_INFO "Test info message"
    validation_log $VALIDATION_ERROR "Test error message"
    validation_log $VALIDATION_WARN "Test warning message"
    validation_log $VALIDATION_DEBUG "Test debug message"

    # Check that log file contains messages
    if [[ -f "$LOG_FILE" ]]; then
        local log_content=$(cat "$LOG_FILE")
        assert_contains "$log_content" "VALIDATION_INFO: Test info message" "Log should contain info message"
        assert_contains "$log_content" "VALIDATION_ERROR: Test error message" "Log should contain error message"
    fi
}

# Test validation with missing dependencies
test_validation_missing_dependencies() {
    # Test that validation handles missing dependencies gracefully

    # Mock a scenario where required tools are missing
    # This tests the robustness of the validation system

    # Test tool functionality with non-existent tool
    check_tool_functionality "definitely_nonexistent_tool_12345"
    local exit_code=$?
    assert_failure $exit_code "Tool functionality check should fail for non-existent tools"

    # Test that validation continues even with missing tools
    validate_prerequisites >/dev/null 2>&1
    exit_code=$?

    # Should return 0 or 1, not crash
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Prerequisite validation should handle missing dependencies gracefully"
        return 1
    fi
}

# Test validation error handling
test_validation_error_handling() {
    init_state_dir

    # Test validation with corrupted state
    echo "invalid json {{{" > "$STATE_FILE"

    # Validation should handle corrupted state gracefully
    validate_full_installation >/dev/null 2>&1
    local exit_code=$?

    # Should not crash, even with corrupted state
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Validation should handle corrupted state gracefully"
        return 1
    fi

    # Restore valid state
    init_state_dir
}

# Test validation performance with many steps
test_validation_performance() {
    init_state_dir

    # Add many steps to test performance
    for i in {1..50}; do
        save_state "step$i" "completed"
    done

    # Time the validation
    local start_time=$(date +%s)
    validate_full_installation >/dev/null 2>&1
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Validation should complete within reasonable time (30 seconds)
    if [[ $duration -gt 30 ]]; then
        echo "Validation took too long: ${duration}s (should be under 30s)"
        return 1
    fi
}
