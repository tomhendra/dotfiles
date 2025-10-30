#!/usr/bin/env bash

# Tests for progress tracking system

# Source the progress library
source "$(dirname "${BASH_SOURCE[0]}")/../lib/state.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/progress.sh"

# Test duration formatting
test_duration_formatting() {
    local formatted

    # Test seconds
    formatted=$(format_duration 30)
    assert_equals "30s" "$formatted" "Should format seconds correctly"

    # Test minutes and seconds
    formatted=$(format_duration 90)
    assert_equals "1m 30s" "$formatted" "Should format minutes and seconds correctly"

    # Test hours, minutes, and seconds
    formatted=$(format_duration 3665)
    assert_equals "1h 1m 5s" "$formatted" "Should format hours, minutes, and seconds correctly"

    # Test zero duration
    formatted=$(format_duration 0)
    assert_equals "0s" "$formatted" "Should format zero duration correctly"
}

# Test color support detection
test_color_support_detection() {
    # This test checks that the function exists and returns a boolean
    supports_color
    local exit_code=$?

    # Should return either 0 (supports color) or 1 (no color support)
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
        echo "Color support detection should return 0 or 1"
        return 1
    fi
}

# Test progress bar drawing
test_progress_bar_drawing() {
    # Test basic progress bar
    local progress_bar
    progress_bar=$(draw_progress_bar 5 10 20)

    # Should contain brackets and percentage
    assert_contains "$progress_bar" "[" "Progress bar should contain opening bracket"
    assert_contains "$progress_bar" "]" "Progress bar should contain closing bracket"
    assert_contains "$progress_bar" "50%" "Progress bar should show correct percentage"

    # Test zero total (edge case)
    progress_bar=$(draw_progress_bar 0 0 10)
    assert_contains "$progress_bar" "[" "Zero total progress bar should contain brackets"

    # Test complete progress
    progress_bar=$(draw_progress_bar 10 10 20)
    assert_contains "$progress_bar" "100%" "Complete progress should show 100%"
}

# Test step duration tracking
test_step_duration_tracking() {
    init_state_dir

    # Add steps with duration metadata
    save_state "step1" "completed" '{"duration": 30}'
    save_state "step2" "completed" '{"duration": 45}'
    save_state "step3" "completed" '{"duration": 60}'

    # Get durations
    local durations
    durations=$(get_step_durations)

    assert_contains "$durations" "30" "Should include step1 duration"
    assert_contains "$durations" "45" "Should include step2 duration"
    assert_contains "$durations" "60" "Should include step3 duration"
}

# Test time estimation
test_time_estimation() {
    init_state_dir

    # Test with no historical data
    local estimated
    estimated=$(estimate_time_remaining 3)

    # Should return some positive estimate
    if [[ $estimated -le 0 ]]; then
        echo "Time estimation should return positive value"
        return 1
    fi

    # Add historical data
    save_state "step1" "completed" '{"duration": 30}'
    save_state "step2" "completed" '{"duration": 40}'

    # Test with historical data
    estimated=$(estimate_time_remaining 2)

    # Should be based on average (35s per step * 2 = 70s)
    if [[ $estimated -lt 50 || $estimated -gt 100 ]]; then
        echo "Time estimation should be reasonable based on history (got ${estimated}s)"
        return 1
    fi

    # Test zero remaining steps
    estimated=$(estimate_time_remaining 0)
    assert_equals "0" "$estimated" "Zero remaining steps should estimate zero time"
}

# Test progress display functionality
test_progress_display() {
    init_state_dir

    # Setup test steps
    local test_steps=("step1" "step2" "step3" "step4")

    # Add various step statuses
    save_state "step1" "completed"
    save_state "step2" "failed"
    save_state "step3" "in_progress"
    # step4 remains not_started

    # Generate progress display
    local progress_output
    progress_output=$(show_progress "${test_steps[@]}")

    # Check that output contains expected elements
    assert_contains "$progress_output" "Installation Progress" "Should show progress header"
    assert_contains "$progress_output" "step1" "Should list step1"
    assert_contains "$progress_output" "step2" "Should list step2"
    assert_contains "$progress_output" "step3" "Should list step3"
    assert_contains "$progress_output" "step4" "Should list step4"
    assert_contains "$progress_output" "Completed:" "Should show completed count"
    assert_contains "$progress_output" "Failed:" "Should show failed count"
    assert_contains "$progress_output" "Remaining:" "Should show remaining count"
}

# Test current step display
test_current_step_display() {
    local step_output
    step_output=$(show_current_step "test_step" "Test Step Description" "Running tests")

    assert_contains "$step_output" "Current Step" "Should show current step header"
    assert_contains "$step_output" "Test Step Description" "Should show step description"
    assert_contains "$step_output" "Running tests" "Should show current operation"
}

# Test log operation functionality
test_log_operation() {
    init_state_dir

    # Test different log levels
    local log_output

    # Test info level (default)
    log_output=$(log_operation "Test info message" 2>&1)
    assert_contains "$log_output" "INFO: Test info message" "Should log info message"

    # Test error level
    log_output=$(log_operation "Test error message" "error" 2>&1)
    assert_contains "$log_output" "ERROR: Test error message" "Should log error message"

    # Test with step ID
    log_output=$(log_operation "Test message" "info" "test_step" 2>&1)
    assert_contains "$log_output" "[test_step]" "Should include step ID in log"

    # Verify log file was created
    if [[ -f "$LOG_FILE" ]]; then
        local log_content=$(cat "$LOG_FILE")
        assert_contains "$log_content" "Test info message" "Should write to log file"
    fi
}

# Test installation summary
test_installation_summary() {
    init_state_dir

    # Setup test data
    local test_steps=("step1" "step2" "step3" "step4")

    save_state "step1" "completed" '{"duration": 30}'
    save_state "step2" "completed" '{"duration": 45}'
    save_state "step3" "failed"
    # step4 not started

    # Generate summary
    local summary_output
    summary_output=$(show_installation_summary "${test_steps[@]}")

    assert_contains "$summary_output" "Installation Summary" "Should show summary header"
    assert_contains "$summary_output" "Total steps:" "Should show total steps"
    assert_contains "$summary_output" "Completed:" "Should show completed count"
    assert_contains "$summary_output" "Failed:" "Should show failed count"
    assert_contains "$summary_output" "Success rate:" "Should show success rate"
    assert_contains "$summary_output" "Total duration:" "Should show total duration"
}

# Test progress clearing
test_progress_clearing() {
    # Test that clear_progress function exists and runs without error
    clear_progress
    local exit_code=$?

    assert_success $exit_code "Clear progress should execute without error"
}

# Test spinner functionality (basic test)
test_spinner_functionality() {
    # Create a background process that runs briefly
    sleep 0.1 &
    local pid=$!

    # Test spinner with the background process
    show_spinner "$pid" "Testing spinner" &
    local spinner_pid=$!

    # Wait for background process to complete
    wait "$pid"

    # Kill spinner
    kill "$spinner_pid" 2>/dev/null || true
    wait "$spinner_pid" 2>/dev/null || true

    # Test passes if no errors occurred
    return 0
}

# Test progress with empty step list
test_progress_empty_steps() {
    init_state_dir

    # Test progress display with no steps
    local progress_output
    progress_output=$(show_progress)

    assert_contains "$progress_output" "Installation Progress" "Should show header even with no steps"
}

# Test progress with all completed steps
test_progress_all_completed() {
    init_state_dir

    local test_steps=("step1" "step2" "step3")

    # Mark all steps as completed
    save_state "step1" "completed"
    save_state "step2" "completed"
    save_state "step3" "completed"

    # Generate progress display
    local progress_output
    progress_output=$(show_progress "${test_steps[@]}")

    assert_contains "$progress_output" "100%" "Should show 100% completion"
    assert_contains "$progress_output" "Remaining: 0" "Should show 0 remaining steps"
}

# Test log operation with special characters
test_log_special_characters() {
    init_state_dir

    # Test logging message with special characters
    local special_message="Test with \"quotes\" and 'apostrophes' and \$variables"
    local log_output
    log_output=$(log_operation "$special_message" "info" 2>&1)

    # Should handle special characters without breaking
    assert_contains "$log_output" "Test with" "Should handle special characters in log messages"
}
