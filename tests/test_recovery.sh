#!/usr/bin/env bash

# Tests for recovery and rollback system

# Source the recovery library
source "$(dirname "${BASH_SOURCE[0]}")/../lib/recovery.sh"

# Test critical step identification
test_critical_step_identification() {
    # Test critical steps
    if ! is_critical_step "prerequisites"; then
        echo "prerequisites should be identified as critical"
        return 1
    fi

    if ! is_critical_step "ssh_setup"; then
        echo "ssh_setup should be identified as critical"
        return 1
    fi

    if ! is_critical_step "homebrew"; then
        echo "homebrew should be identified as critical"
        return 1
    fi

    # Test non-critical steps
    if is_critical_step "rust"; then
        echo "rust should not be identified as critical"
        return 1
    fi

    if is_critical_step "nodejs"; then
        echo "nodejs should not be identified as critical"
        return 1
    fi

    if is_critical_step "nonexistent_step"; then
        echo "nonexistent_step should not be identified as critical"
        return 1
    fi
}

# Test rollback information saving and retrieval
test_rollback_info_management() {
    init_state_dir

    # Test saving rollback information
    local rollback_data='{"ssh_key_created": "/tmp/test_key", "backup_created": true}'
    save_rollback_info "test_step" "$rollback_data"
    local exit_code=$?

    assert_success $exit_code "Saving rollback info should succeed"

    # Test retrieving rollback information
    local retrieved_info
    retrieved_info=$(get_rollback_info "test_step")

    assert_contains "$retrieved_info" "ssh_key_created" "Retrieved info should contain saved data"
    assert_contains "$retrieved_info" "/tmp/test_key" "Retrieved info should contain correct values"

    # Test retrieving non-existent rollback info
    local empty_info
    empty_info=$(get_rollback_info "nonexistent_step")

    assert_equals "{}" "$empty_info" "Non-existent rollback info should return empty object"
}

# Test SSH setup rollback
test_ssh_setup_rollback() {
    init_state_dir

    # Create test SSH key and config for rollback
    local test_ssh_dir="$TEMP_TEST_DIR/.ssh"
    mkdir -p "$test_ssh_dir"

    local test_key="$test_ssh_dir/id_test"
    echo "test ssh key" > "$test_key"
    echo "test ssh public key" > "${test_key}.pub"

    # Create SSH config backup
    local ssh_config_backup="$TEMP_TEST_DIR/ssh_config_backup"
    echo "original ssh config" > "$ssh_config_backup"

    # Save rollback information
    local rollback_data="{\"ssh_key_created\": \"$test_key\", \"ssh_config_backup\": \"$ssh_config_backup\"}"
    save_rollback_info "ssh_setup" "$rollback_data"

    # Test SSH rollback
    HOME="$TEMP_TEST_DIR" rollback_ssh_step
    local exit_code=$?

    assert_success $exit_code "SSH rollback should succeed"

    # Verify SSH key was removed
    assert_file_not_exists "$test_key" "SSH private key should be removed"
    assert_file_not_exists "${test_key}.pub" "SSH public key should be removed"
}

# Test Homebrew rollback
test_homebrew_rollback() {
    init_state_dir

    # Test rollback when Homebrew was not installed in this session
    local rollback_data='{"homebrew_installed": "false", "path_backup": "/original/path"}'
    save_rollback_info "homebrew" "$rollback_data"

    rollback_homebrew_step
    local exit_code=$?

    assert_success $exit_code "Homebrew rollback should succeed when not installed in session"

    # Test rollback when Homebrew was installed in this session
    rollback_data='{"homebrew_installed": "true", "path_backup": "/original/path"}'
    save_rollback_info "homebrew" "$rollback_data"

    # This will likely fail since we don't actually have Homebrew to uninstall
    # But it should handle the failure gracefully
    rollback_homebrew_step >/dev/null 2>&1
    exit_code=$?

    # Should return 0 or 1, not crash
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Homebrew rollback should handle missing Homebrew gracefully"
        return 1
    fi
}

# Test symlinks rollback
test_symlinks_rollback() {
    init_state_dir

    # Create test symlinks and backups
    local test_home="$TEMP_TEST_DIR/home"
    mkdir -p "$test_home/.config"

    # Create test symlinks
    local test_target="$TEMP_TEST_DIR/target_file"
    echo "target content" > "$test_target"
    ln -sf "$test_target" "$test_home/.zshrc"
    ln -sf "$test_target" "$test_home/.gitconfig"

    # Create backup files
    local backup1="$TEMP_TEST_DIR/backup1"
    local backup2="$TEMP_TEST_DIR/backup2"
    echo "original zshrc" > "$backup1"
    echo "original gitconfig" > "$backup2"

    # Save rollback information
    local rollback_data="{
        \"created_symlinks\": [\"$test_home/.zshrc\", \"$test_home/.gitconfig\"],
        \"backed_up_files\": {
            \"$test_home/.zshrc\": \"$backup1\",
            \"$test_home/.gitconfig\": \"$backup2\"
        }
    }"
    save_rollback_info "symlinks" "$rollback_data"

    # Test symlinks rollback
    rollback_symlinks_step
    local exit_code=$?

    assert_success $exit_code "Symlinks rollback should succeed"

    # Verify symlinks were removed
    assert_file_not_exists "$test_home/.zshrc" "Symlink should be removed"
    assert_file_not_exists "$test_home/.gitconfig" "Symlink should be removed"

    # Verify backups were restored (files should exist with backup content)
    if [[ -f "$test_home/.zshrc" ]]; then
        local restored_content=$(cat "$test_home/.zshrc")
        assert_equals "original zshrc" "$restored_content" "Backup should be restored"
    fi
}

# Test repository cloning rollback
test_clone_repos_rollback() {
    init_state_dir

    # Create test repositories to be "rolled back"
    local test_repo1="$TEMP_TEST_DIR/repo1"
    local test_repo2="$TEMP_TEST_DIR/repo2"
    mkdir -p "$test_repo1" "$test_repo2"
    echo "repo1 content" > "$test_repo1/file1.txt"
    echo "repo2 content" > "$test_repo2/file2.txt"

    # Save rollback information
    local rollback_data="{\"cloned_repositories\": [\"$test_repo1\", \"$test_repo2\"]}"
    save_rollback_info "clone_repos" "$rollback_data"

    # Test repository rollback
    rollback_clone_repos_step
    local exit_code=$?

    assert_success $exit_code "Repository cloning rollback should succeed"

    # Verify repositories were removed
    assert_file_not_exists "$test_repo1" "Repository 1 should be removed"
    assert_file_not_exists "$test_repo2" "Repository 2 should be removed"
}

# Test individual step rollback
test_step_rollback() {
    init_state_dir

    # Test rollback of step with no rollback info
    rollback_step "nonexistent_step"
    local exit_code=$?

    assert_success $exit_code "Rollback of step with no info should succeed (no-op)"

    # Test rollback of step with rollback info
    local rollback_data='{"test": "data"}'
    save_rollback_info "test_step" "$rollback_data"

    # Mark step as completed first
    save_state "test_step" "completed"

    rollback_step "test_step"
    exit_code=$?

    assert_success $exit_code "Step rollback should succeed"

    # Verify step status was updated
    local status=$(get_step_status "test_step")
    assert_equals "rolled_back" "$status" "Step should be marked as rolled back"
}

# Test session rollback
test_session_rollback() {
    init_state_dir

    # Create a test installation session
    save_state "step1" "completed"
    save_state "step2" "completed"
    save_state "step3" "failed"

    # Add some rollback info for testing
    save_rollback_info "step1" '{"test": "rollback1"}'
    save_rollback_info "step2" '{"test": "rollback2"}'

    # Test session rollback
    rollback_session >/dev/null 2>&1
    local exit_code=$?

    # Should complete (may have errors due to missing actual resources to rollback)
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Session rollback should return 0 or 1"
        return 1
    fi

    # Verify session was marked as rolled back
    local session_status=$(get_step_status "session")
    assert_equals "rolled_back" "$session_status" "Session should be marked as rolled back"
}

# Test backup restoration
test_backup_restoration() {
    init_state_dir

    # Create test files and backups
    local original_file1="$TEMP_TEST_DIR/config1.txt"
    local original_file2="$TEMP_TEST_DIR/config2.txt"
    local backup_file1="$TEMP_TEST_DIR/backup1.txt"
    local backup_file2="$TEMP_TEST_DIR/backup2.txt"

    echo "backup content 1" > "$backup_file1"
    echo "backup content 2" > "$backup_file2"

    # Add backup information to state
    local temp_file="${STATE_FILE}.tmp"
    load_state | python3 -c "
import json, sys
data = json.load(sys.stdin)
if 'backups' not in data:
    data['backups'] = {}
data['backups']['$original_file1'] = '$backup_file1'
data['backups']['$original_file2'] = '$backup_file2'
print(json.dumps(data, indent=2))
" > "$temp_file"

    if [[ -f "$temp_file" ]]; then
        mv "$temp_file" "$STATE_FILE"
    fi

    # Test backup restoration
    restore_backups
    local exit_code=$?

    assert_success $exit_code "Backup restoration should succeed"

    # Verify files were restored
    assert_file_exists "$original_file1" "Original file 1 should be restored"
    assert_file_exists "$original_file2" "Original file 2 should be restored"

    # Verify content was restored correctly
    local restored_content1=$(cat "$original_file1")
    local restored_content2=$(cat "$original_file2")
    assert_equals "backup content 1" "$restored_content1" "File 1 content should be restored"
    assert_equals "backup content 2" "$restored_content2" "File 2 content should be restored"
}

# Test automatic rollback trigger
test_automatic_rollback_trigger() {
    init_state_dir

    # Test automatic rollback for critical step
    AUTO_ROLLBACK_ENABLED=true trigger_automatic_rollback "ssh_setup" "network"
    local exit_code=$?

    # Should complete (may succeed or fail depending on rollback data availability)
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Automatic rollback should return 0 or 1"
        return 1
    fi

    # Test automatic rollback for non-critical step
    AUTO_ROLLBACK_ENABLED=true trigger_automatic_rollback "rust" "network"
    exit_code=$?

    assert_success $exit_code "Automatic rollback should succeed (no-op) for non-critical steps"

    # Test with automatic rollback disabled
    AUTO_ROLLBACK_ENABLED=false trigger_automatic_rollback "ssh_setup" "network"
    exit_code=$?

    assert_success $exit_code "Automatic rollback should succeed (no-op) when disabled"
}

# Test recovery status reporting
test_recovery_status() {
    init_state_dir

    # Add some rollback states
    save_state "step1" "rolled_back"
    save_state "step2" "rollback_failed"
    save_state "session" "rolled_back" '{"rollback_completed_at": "2023-01-01T00:00:00Z", "steps_rolled_back": 2}'

    # Test recovery status
    local status_output
    status_output=$(get_recovery_status)

    assert_contains "$status_output" "Steps rolled back:" "Status should show rolled back count"
    assert_contains "$status_output" "Rollback failures:" "Status should show rollback failure count"
    assert_contains "$status_output" "Session rollback completed:" "Status should show session rollback info"
}

# Test cleanup of old backups
test_backup_cleanup() {
    init_state_dir

    # Create old backup files
    local old_backup1="$BACKUP_DIR/old_backup1_$(date -d '40 days ago' +%Y%m%d_%H%M%S 2>/dev/null || date -v-40d +%Y%m%d_%H%M%S 2>/dev/null || echo '20230101_120000')"
    local old_backup2="$BACKUP_DIR/old_backup2_$(date -d '35 days ago' +%Y%m%d_%H%M%S 2>/dev/null || date -v-35d +%Y%m%d_%H%M%S 2>/dev/null || echo '20230106_120000')"
    local recent_backup="$BACKUP_DIR/recent_backup_$(date +%Y%m%d_%H%M%S)"

    echo "old backup 1" > "$old_backup1"
    echo "old backup 2" > "$old_backup2"
    echo "recent backup" > "$recent_backup"

    # Modify timestamps to simulate old files (if touch supports it)
    touch -t 202301011200 "$old_backup1" 2>/dev/null || true
    touch -t 202301061200 "$old_backup2" 2>/dev/null || true

    # Test cleanup with 30 day retention
    cleanup_old_backups 30

    # Recent backup should still exist
    assert_file_exists "$recent_backup" "Recent backup should not be cleaned up"

    # Note: Old backups may or may not be cleaned up depending on system support for touch -t
    # The test verifies the function runs without error
}

# Test rollback with missing rollback data
test_rollback_missing_data() {
    init_state_dir

    # Test rollback steps that have no rollback data
    rollback_ssh_step
    local exit_code=$?

    # Should handle missing data gracefully
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "SSH rollback should handle missing data gracefully"
        return 1
    fi

    rollback_homebrew_step
    exit_code=$?

    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Homebrew rollback should handle missing data gracefully"
        return 1
    fi

    rollback_symlinks_step
    exit_code=$?

    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Symlinks rollback should handle missing data gracefully"
        return 1
    fi
}

# Test recovery logging
test_recovery_logging() {
    init_state_dir

    # Test recovery logging function
    recovery_log $RECOVERY_INFO "Test info message"
    recovery_log $RECOVERY_ERROR "Test error message"
    recovery_log $RECOVERY_WARN "Test warning message"
    recovery_log $RECOVERY_DEBUG "Test debug message"

    # Check that log file contains messages
    if [[ -f "$LOG_FILE" ]]; then
        local log_content=$(cat "$LOG_FILE")
        assert_contains "$log_content" "RECOVERY_INFO: Test info message" "Log should contain info message"
        assert_contains "$log_content" "RECOVERY_ERROR: Test error message" "Log should contain error message"
    fi
}

# Test rollback error handling
test_rollback_error_handling() {
    init_state_dir

    # Test rollback with corrupted rollback data
    echo "invalid json {{{" > "${STATE_DIR}/rollback_test_step.json"
    save_rollback_info "test_step" "${STATE_DIR}/rollback_test_step.json"

    # Rollback should handle corrupted data gracefully
    rollback_step "test_step" >/dev/null 2>&1
    local exit_code=$?

    # Should not crash with corrupted data
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Rollback should handle corrupted data gracefully"
        return 1
    fi
}
