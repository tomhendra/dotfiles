#!/usr/bin/env bash

# Tests for step executor framework

# Source the executor library
source "$(dirname "${BASH_SOURCE[0]}")/../lib/executor.sh"

# Test helper functions
create_test_step_function() {
    local function_name="$1"
    local exit_code="${2:-0}"
    local output="${3:-test output}"

    eval "$function_name() { echo '$output'; return $exit_code; }"
}

create_slow_test_function() {
    local function_name="$1"
    local sleep_time="${2:-2}"

    eval "$function_name() { sleep $sleep_time; echo 'slow operation complete'; }"
}

# Test successful step execution
test_successful_step_execution() {
    init_state_dir

    # Create a test step function
    create_test_step_function "test_success_step" 0 "success output"

    # Execute the step
    execute_step "test_step" "test_success_step" "Test Step"
    local exit_code=$?

    assert_success $exit_code "Step execution should succeed"

    # Verify step was marked as completed
    local status=$(get_step_status "test_step")
    assert_equals "completed" "$status" "Step should be marked as completed"
}

# Test failed step execution
test_failed_step_execution() {
    init_state_dir

    # Create a failing test step function
    create_test_step_function "test_fail_step" 1 "error output"

    # Execute the step
    execute_step "test_step" "test_fail_step" "Test Step"
    local exit_code=$?

    assert_failure $exit_code "Step execution should fail"

    # Verify step was marked as failed
    local status=$(get_step_status "test_step")
    assert_equals "failed" "$status" "Step should be marked as failed"
}

# Test skipping already completed steps
test_skip_completed_steps() {
    init_state_dir

    # Mark step as completed
    save_state "test_step" "completed"

    # Create a step function that should not be called
    create_test_step_function "test_skip_step" 1 "should not run"

    # Execute the step
    execute_step "test_step" "test_skip_step" "Test Step"
    local exit_code=$?

    assert_success $exit_code "Completed step should be skipped successfully"

    # Status should remain completed
    local status=$(get_step_status "test_step")
    assert_equals "completed" "$status" "Step should remain completed"
}

# Test network connectivity check
test_network_connectivity_check() {
    # This test may fail in environments without internet
    # We'll test the function exists and returns a boolean result

    check_network_connectivity
    local exit_code=$?

    # Should return either 0 (connected) or 1 (not connected)
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Network connectivity check should return 0 or 1"
        return 1
    fi
}

# Test command existence check
test_command_exists() {
    # Test with a command that should exist
    if ! command_exists "bash"; then
        echo "bash command should exist"
        return 1
    fi

    # Test with a command that should not exist
    if command_exists "nonexistent_command_12345"; then
        echo "nonexistent command should not exist"
        return 1
    fi
}

# Test timeout functionality
test_timeout_functionality() {
    # Create a slow function
    create_slow_test_function "slow_function" 3

    # Test with short timeout (should timeout)
    local start_time=$(date +%s)
    run_with_timeout 1 "slow_function"
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Should fail due to timeout and complete in roughly 1 second
    assert_failure $exit_code "Slow command should timeout"

    if [[ $duration -gt 5 ]]; then
        echo "Timeout should prevent long execution (took ${duration}s)"
        return 1
    fi
}

# Test retry with backoff
test_retry_with_backoff() {
    init_state_dir

    # Create a function that fails twice then succeeds
    cat > "$TEMP_TEST_DIR/retry_test.sh" << 'EOF'
#!/bin/bash
COUNTER_FILE="$TEMP_TEST_DIR/retry_counter"
if [[ ! -f "$COUNTER_FILE" ]]; then
    echo "1" > "$COUNTER_FILE"
    exit 1
elif [[ $(cat "$COUNTER_FILE") == "1" ]]; then
    echo "2" > "$COUNTER_FILE"
    exit 1
else
    echo "success"
    exit 0
fi
EOF
    chmod +x "$TEMP_TEST_DIR/retry_test.sh"

    # Test retry functionality
    retry_with_backoff "$TEMP_TEST_DIR/retry_test.sh" 3
    local exit_code=$?

    assert_success $exit_code "Retry should eventually succeed"
}

# Test retry failure after max attempts
test_retry_max_attempts() {
    # Create a function that always fails
    create_test_step_function "always_fail" 1 "always fails"

    # Test retry with max attempts
    retry_with_backoff "always_fail" 2
    local exit_code=$?

    assert_failure $exit_code "Retry should fail after max attempts"
}

# Test error classification
test_error_classification() {
    # Test network error classification
    local error_type
    error_type=$(classify_error 7 "curl: connection failed" "curl")
    assert_equals "network" "$error_type" "Should classify curl connection error as network"

    # Test permission error classification
    error_type=$(classify_error 126 "permission denied" "mkdir")
    assert_equals "permission" "$error_type" "Should classify permission denied as permission error"

    # Test dependency error classification
    error_type=$(classify_error 1 "command not found" "somecommand")
    assert_equals "dependency" "$error_type" "Should classify not found as dependency error"

    # Test generic error classification
    error_type=$(classify_error 1 "unknown error" "somecommand")
    assert_equals "generic" "$error_type" "Should classify unknown errors as generic"
}

# Test step prerequisites validation
test_step_prerequisites_validation() {
    # Test with existing commands
    validate_step_prerequisites "test_step" "bash" "echo"
    local exit_code=$?
    assert_success $exit_code "Should validate existing commands successfully"

    # Test with non-existing command
    validate_step_prerequisites "test_step" "nonexistent_command_12345"
    exit_code=$?
    assert_failure $exit_code "Should fail validation for non-existing commands"
}

# Test step sequence execution
test_step_sequence_execution() {
    init_state_dir

    # Create test step functions
    create_test_step_function "step1_func" 0 "step1 output"
    create_test_step_function "step2_func" 0 "step2 output"
    create_test_step_function "step3_func" 0 "step3 output"

    # Execute step sequence
    local steps=(
        "step1:step1_func:Step 1"
        "step2:step2_func:Step 2"
        "step3:step3_func:Step 3"
    )

    execute_step_sequence "${steps[@]}"
    local exit_code=$?

    assert_success $exit_code "Step sequence should execute successfully"

    # Verify all steps completed
    assert_equals "completed" "$(get_step_status "step1")" "Step 1 should be completed"
    assert_equals "completed" "$(get_step_status "step2")" "Step 2 should be completed"
    assert_equals "completed" "$(get_step_status "step3")" "Step 3 should be completed"
}

# Test step sequence failure handling
test_step_sequence_failure() {
    init_state_dir

    # Create test step functions (second one fails)
    create_test_step_function "step1_func" 0 "step1 output"
    create_test_step_function "step2_func" 1 "step2 error"
    create_test_step_function "step3_func" 0 "step3 output"

    # Execute step sequence
    local steps=(
        "step1:step1_func:Step 1"
        "step2:step2_func:Step 2"
        "step3:step3_func:Step 3"
    )

    execute_step_sequence "${steps[@]}"
    local exit_code=$?

    assert_failure $exit_code "Step sequence should fail when a step fails"

    # Verify step states
    assert_equals "completed" "$(get_step_status "step1")" "Step 1 should be completed"
    assert_equals "failed" "$(get_step_status "step2")" "Step 2 should be failed"
    assert_equals "not_started" "$(get_step_status "step3")" "Step 3 should not have started"
}

# Test step summary generation
test_step_summary() {
    init_state_dir

    # Create and execute a test step
    create_test_step_function "test_step_func" 0 "test output"
    execute_step "test_step" "test_step_func" "Test Step"

    # Get step summary
    local summary
    summary=$(get_step_summary "test_step")

    assert_contains "$summary" "Step ID: test_step" "Summary should contain step ID"
    assert_contains "$summary" "Status: completed" "Summary should contain status"
    assert_contains "$summary" "Attempts:" "Summary should contain attempt count"
}

# Test nonexistent step function handling
test_nonexistent_step_function() {
    init_state_dir

    # Try to execute non-existent step function
    execute_step "test_step" "nonexistent_function" "Test Step"
    local exit_code=$?

    assert_failure $exit_code "Should fail when step function doesn't exist"

    # Verify step was marked as failed
    local status=$(get_step_status "test_step")
    assert_equals "failed" "$status" "Step should be marked as failed"
}
