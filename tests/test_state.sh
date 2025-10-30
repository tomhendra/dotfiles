#!/usr/bin/env bash

# Tests for state management system

# Source the state management library
source "$(dirname "${BASH_SOURCE[0]}")/../lib/state.sh"

# Test state initialization
test_state_initialization() {
    init_state_dir

    assert_file_exists "$STATE_DIR" "State directory should be created"
    assert_file_exists "$STATE_FILE" "State file should be created"
    assert_file_exists "$BACKUP_DIR" "Backup directory should be created"

    # Check initial state structure
    local state=$(load_state)
    assert_contains "$state" '"installation_id"' "State should contain installation_id field"
    assert_contains "$state" '"steps"' "State should contain steps field"
    assert_contains "$state" '"backups"' "State should contain backups field"
}

# Test saving and loading state
test_save_and_load_state() {
    init_state_dir

    # Save a test step
    save_state "test_step" "completed" '{"test": "metadata"}'

    # Load and verify
    local state=$(load_state)
    assert_contains "$state" "test_step" "State should contain saved step"
    assert_contains "$state" "completed" "State should contain step status"

    # Test step status retrieval
    local status=$(get_step_status "test_step")
    assert_equals "completed" "$status" "Step status should be completed"
}

# Test step completion check
test_step_completion_check() {
    init_state_dir

    # Test non-existent step
    if is_step_completed "nonexistent_step"; then
        echo "Non-existent step should not be completed"
        return 1
    fi

    # Save completed step and test
    save_state "completed_step" "completed"

    if ! is_step_completed "completed_step"; then
        echo "Completed step should return true"
        return 1
    fi

    # Test failed step
    save_state "failed_step" "failed"

    if is_step_completed "failed_step"; then
        echo "Failed step should not be completed"
        return 1
    fi
}

# Test state reset functionality
test_state_reset() {
    init_state_dir

    # Add some state
    save_state "test_step1" "completed"
    save_state "test_step2" "failed"

    # Verify state exists
    local status1=$(get_step_status "test_step1")
    assert_equals "completed" "$status1" "Step 1 should be completed before reset"

    # Reset state
    reset_state --force

    # Verify state is cleared
    local status_after=$(get_step_status "test_step1")
    assert_equals "not_started" "$status_after" "Step should be not_started after reset"
}

# Test file backup functionality
test_file_backup() {
    init_state_dir

    # Create a test file
    local test_file="$TEMP_TEST_DIR/test_config.txt"
    echo "test content" > "$test_file"

    # Backup the file
    local backup_location
    backup_location=$(backup_file "$test_file")

    assert_success $? "Backup should succeed"
    assert_file_exists "$backup_location" "Backup file should exist"

    # Verify backup content
    local backup_content=$(cat "$backup_location")
    assert_equals "test content" "$backup_content" "Backup content should match original"

    # Test backup location retrieval
    local retrieved_location
    retrieved_location=$(get_backup_location "$test_file")
    assert_equals "$backup_location" "$retrieved_location" "Retrieved backup location should match"
}

# Test backup of non-existent file
test_backup_nonexistent_file() {
    init_state_dir

    # Try to backup non-existent file
    backup_file "/nonexistent/file.txt" >/dev/null 2>&1
    local exit_code=$?

    assert_failure $exit_code "Backup of non-existent file should fail"
}

# Test listing completed steps
test_list_completed_steps() {
    init_state_dir

    # Add various step statuses
    save_state "step1" "completed"
    save_state "step2" "failed"
    save_state "step3" "completed"
    save_state "step4" "in_progress"

    # Get completed steps
    local completed_steps
    completed_steps=$(list_completed_steps)

    assert_contains "$completed_steps" "step1" "Should list step1 as completed"
    assert_contains "$completed_steps" "step3" "Should list step3 as completed"

    # Should not contain non-completed steps
    if echo "$completed_steps" | grep -q "step2"; then
        echo "Should not list failed step as completed"
        return 1
    fi

    if echo "$completed_steps" | grep -q "step4"; then
        echo "Should not list in-progress step as completed"
        return 1
    fi
}

# Test installation summary
test_installation_summary() {
    init_state_dir

    # Add test steps
    save_state "step1" "completed"
    save_state "step2" "completed"
    save_state "step3" "failed"

    # Get summary
    local summary
    summary=$(get_installation_summary)

    assert_contains "$summary" "Total steps: 3" "Summary should show total steps"
    assert_contains "$summary" "Completed: 2" "Summary should show completed count"
    assert_contains "$summary" "Failed: 1" "Summary should show failed count"
}

# Test concurrent state updates (basic atomicity test)
test_concurrent_state_updates() {
    init_state_dir

    # Simulate concurrent updates
    save_state "step1" "in_progress" &
    save_state "step2" "completed" &
    save_state "step3" "failed" &

    # Wait for all background processes
    wait

    # Verify all steps were saved
    local status1=$(get_step_status "step1")
    local status2=$(get_step_status "step2")
    local status3=$(get_step_status "step3")

    assert_not_equals "not_started" "$status1" "Step1 should have been updated"
    assert_not_equals "not_started" "$status2" "Step2 should have been updated"
    assert_not_equals "not_started" "$status3" "Step3 should have been updated"

    # Verify state file is still valid JSON
    local state=$(load_state)
    if ! echo "$state" | python3 -c "import json, sys; json.load(sys.stdin)" >/dev/null 2>&1; then
        echo "State file should remain valid JSON after concurrent updates"
        return 1
    fi
}

# Test metadata handling
test_metadata_handling() {
    init_state_dir

    # Save step with complex metadata
    local metadata='{"duration": 45, "retry_count": 2, "error_type": "network"}'
    save_state "test_step" "failed" "$metadata"

    # Verify metadata is preserved
    local state=$(load_state)
    assert_contains "$state" '"duration": 45' "Metadata should contain duration"
    assert_contains "$state" '"retry_count": 2' "Metadata should contain retry count"
    assert_contains "$state" '"error_type": "network"' "Metadata should contain error type"
}

# Test invalid JSON metadata handling
test_invalid_metadata_handling() {
    init_state_dir

    # Save step with invalid JSON metadata
    save_state "test_step" "completed" "invalid json {{"

    # Should still save the step status
    local status=$(get_step_status "test_step")
    assert_equals "completed" "$status" "Step status should be saved despite invalid metadata"

    # State file should remain valid
    local state=$(load_state)
    if ! echo "$state" | python3 -c "import json, sys; json.load(sys.stdin)" >/dev/null 2>&1; then
        echo "State file should remain valid JSON despite invalid metadata"
        return 1
    fi
}
