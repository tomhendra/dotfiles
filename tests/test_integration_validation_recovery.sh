#!/usr/bin/env bash

# Integration tests for validation and recovery systems

# Source all required libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/state.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/executor.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/validator.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/recovery.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/selective.sh"

# Test full installation validation flow
test_full_validation_flow() {
    init_state_dir

    # Simulate a partial installation
    save_state "prerequisites" "completed" '{"duration": 30}'
    save_state "ssh_setup" "completed" '{"duration": 45}'
    save_state "homebrew" "failed" '{"error_type": "network", "exit_code": 1}'
    save_state "rust" "completed" '{"duration": 120}'

    # Test individual step validations
    validate_step "prerequisites"
    local prereq_result=$?

    validate_step "ssh_setup"
    local ssh_result=$?

    validate_step "rust"
    local rust_result=$?

    # Test full installation validation
    local validation_output
    validation_output=$(validate_full_installation 2>&1)
    local validation_result=$?

    # Validation should run without crashing
    if [[ $validation_result -ne 0 && $validation_result -ne 1 ]]; then
        echo "Full validation should return 0 or 1, got $validation_result"
        return 1
    fi

    # Should contain validation summary
    assert_contains "$validation_output" "VALIDATION SUMMARY" "Should show validation summary"
    assert_contains "$validation_output" "Total checks:" "Should show check count"

    # Test validation report generation
    local report_file="$TEMP_TEST_DIR/validation_report.txt"
    generate_validation_report "$report_file" >/dev/null 2>&1

    assert_file_exists "$report_file" "Validation report should be generated"

    local report_content=$(cat "$report_file")
    assert_contains "$report_content" "VALIDATION REPORT" "Report should contain header"
}

# Test recovery and rollback flow
test_recovery_rollback_flow() {
    init_state_dir

    # Simulate installation with rollback data
    save_state "ssh_setup" "completed"
    save_rollback_info "ssh_setup" '{"ssh_key_created": "/tmp/test_key", "backup_created": true}'

    save_state "homebrew" "completed"
    save_rollback_info "homebrew" '{"homebrew_installed": "true", "path_backup": "/original/path"}'

    save_state "symlinks" "completed"
    save_rollback_info "symlinks" '{"created_symlinks": ["/tmp/test_link"], "backed_up_files": {}}'

    # Test individual step rollbacks
    rollback_step "ssh_setup"
    local ssh_rollback_result=$?

    rollback_step "symlinks"
    local symlinks_rollback_result=$?

    # Results should be 0 or 1 (success or expected failure)
    if [[ $ssh_rollback_result -ne 0 && $ssh_rollback_result -ne 1 ]]; then
        echo "SSH rollback should return 0 or 1"
        return 1
    fi

    if [[ $symlinks_rollback_result -ne 0 && $symlinks_rollback_result -ne 1 ]]; then
        echo "Symlinks rollback should return 0 or 1"
        return 1
    fi

    # Verify steps were marked as rolled back
    local ssh_status=$(get_step_status "ssh_setup")
    assert_equals "rolled_back" "$ssh_status" "SSH step should be marked as rolled back"

    # Test full session rollback
    rollback_session >/dev/null 2>&1
    local session_rollback_result=$?

    if [[ $session_rollback_result -ne 0 && $session_rollback_result -ne 1 ]]; then
        echo "Session rollback should return 0 or 1"
        return 1
    fi

    # Test recovery status
    local recovery_status
    recovery_status=$(get_recovery_status)
    assert_contains "$recovery_status" "Steps rolled back:" "Should show recovery status"
}

# Test selective installation with validation
test_selective_installation_with_validation() {
    init_state_dir

    # Test building installation plan
    local options='{"selected_components": ["prerequisites", "ssh_setup"], "excluded_components": [], "categories": [], "dry_run": false, "show_help": false}'
    local plan
    plan=$(build_installation_plan "$options")

    assert_contains "$plan" "prerequisites" "Plan should include prerequisites"
    assert_contains "$plan" "ssh_setup" "Plan should include SSH setup"

    # Validate the component selection
    local plan_array=($plan)
    validate_component_selection "${plan_array[@]}"
    local validation_result=$?

    assert_success $validation_result "Component selection should be valid"

    # Test dry run preview
    local preview
    preview=$(show_dry_run_preview "${plan_array[@]}")

    assert_contains "$preview" "DRY RUN" "Should show dry run preview"
    assert_contains "$preview" "prerequisites" "Should list selected components"

    # Test with categories
    options='{"selected_components": [], "excluded_components": [], "categories": ["system"], "dry_run": true, "show_help": false}'
    plan=$(build_installation_plan "$options")

    assert_contains "$plan" "prerequisites" "Category selection should include system components"
}

# Test error handling and recovery integration
test_error_handling_recovery_integration() {
    init_state_dir

    # Simulate a failed critical step
    save_state "ssh_setup" "failed" '{"error_type": "permission", "exit_code": 126}'
    save_rollback_info "ssh_setup" '{"ssh_key_created": "/tmp/test_key"}'

    # Test automatic rollback trigger
    AUTO_ROLLBACK_ENABLED=true trigger_automatic_rollback "ssh_setup" "permission"
    local auto_rollback_result=$?

    if [[ $auto_rollback_result -ne 0 && $auto_rollback_result -ne 1 ]]; then
        echo "Automatic rollback should return 0 or 1"
        return 1
    fi

    # Test validation after rollback
    validate_step "ssh_setup"
    local validation_after_rollback=$?

    # Should fail validation since step was rolled back
    assert_failure $validation_after_rollback "Validation should fail for rolled back step"

    # Test recovery status after automatic rollback
    local recovery_status
    recovery_status=$(get_recovery_status)
    assert_contains "$recovery_status" "Steps rolled back:" "Should show recovery information"
}

# Test advanced retry mechanisms integration
test_advanced_retry_integration() {
    init_state_dir

    # Create a test function that fails initially
    create_flaky_test_function() {
        local function_name="$1"
        local failure_count="${2:-2}"

        cat > "$TEMP_TEST_DIR/${function_name}.sh" << EOF
#!/bin/bash
COUNTER_FILE="$TEMP_TEST_DIR/${function_name}_counter"
if [[ ! -f "\$COUNTER_FILE" ]]; then
    echo "1" > "\$COUNTER_FILE"
    echo "Network error: connection failed" >&2
    exit 7  # Network error exit code
elif [[ \$(cat "\$COUNTER_FILE") -lt $failure_count ]]; then
    count=\$(cat "\$COUNTER_FILE")
    echo "\$((count + 1))" > "\$COUNTER_FILE"
    echo "Network error: timeout" >&2
    exit 28  # Timeout error exit code
else
    echo "Success after retries"
    exit 0
fi
EOF
        chmod +x "$TEMP_TEST_DIR/${function_name}.sh"
    }

    # Test network retry with backoff
    create_flaky_test_function "network_test" 2

    retry_with_backoff "$TEMP_TEST_DIR/network_test.sh" 3 "network"
    local retry_result=$?

    assert_success $retry_result "Network retry should eventually succeed"

    # Test adaptive retry
    adaptive_retry "$TEMP_TEST_DIR/network_test.sh" 3
    local adaptive_result=$?

    assert_success $adaptive_result "Adaptive retry should succeed"

    # Test circuit breaker
    create_flaky_test_function "circuit_test" 10  # Always fails

    execute_with_circuit_breaker "$TEMP_TEST_DIR/circuit_test.sh" 3 60
    local circuit_result1=$?
    assert_failure $circuit_result1 "Circuit breaker should fail initially"

    # Subsequent calls should be blocked by circuit breaker
    execute_with_circuit_breaker "$TEMP_TEST_DIR/circuit_test.sh" 3 60
    local circuit_result2=$?
    assert_failure $circuit_result2 "Circuit breaker should block subsequent calls"
}

# Test state consistency across validation and recovery
test_state_consistency() {
    init_state_dir

    # Create complex state with multiple steps
    save_state "step1" "completed" '{"duration": 30}'
    save_state "step2" "failed" '{"error_type": "network", "attempts": 3}'
    save_state "step3" "in_progress" '{"started_at": "2023-01-01T00:00:00Z"}'
    save_state "step4" "rolled_back" '{"rolled_back_at": "2023-01-01T01:00:00Z"}'

    # Add rollback information
    save_rollback_info "step1" '{"backup_created": true}'
    save_rollback_info "step2" '{"partial_install": true}'

    # Test state loading and consistency
    local state=$(load_state)

    # Verify JSON validity
    if ! echo "$state" | python3 -c "import json, sys; json.load(sys.stdin)" >/dev/null 2>&1; then
        echo "State should be valid JSON"
        return 1
    fi

    # Test concurrent operations don't corrupt state
    save_state "concurrent1" "completed" &
    save_state "concurrent2" "failed" &
    rollback_step "step1" >/dev/null 2>&1 &
    validate_step "step1" >/dev/null 2>&1 &

    wait  # Wait for all background operations

    # State should still be valid JSON
    state=$(load_state)
    if ! echo "$state" | python3 -c "import json, sys; json.load(sys.stdin)" >/dev/null 2>&1; then
        echo "State should remain valid JSON after concurrent operations"
        return 1
    fi

    # Test installation summary with complex state
    local summary
    summary=$(get_installation_summary)
    assert_contains "$summary" "Total steps:" "Summary should show step count"
    assert_contains "$summary" "Completed:" "Summary should show completed count"
    assert_contains "$summary" "Failed:" "Summary should show failed count"
}

# Test performance with large number of components
test_performance_with_scale() {
    init_state_dir

    # Create many steps to test performance
    for i in {1..100}; do
        save_state "perf_step_$i" "completed" '{"duration": 10}'
        if [[ $((i % 10)) -eq 0 ]]; then
            save_rollback_info "perf_step_$i" '{"test_data": "rollback_info"}'
        fi
    done

    # Test validation performance
    local start_time=$(date +%s)
    validate_full_installation >/dev/null 2>&1
    local end_time=$(date +%s)
    local validation_duration=$((end_time - start_time))

    # Should complete within reasonable time (60 seconds for 100 steps)
    if [[ $validation_duration -gt 60 ]]; then
        echo "Validation took too long: ${validation_duration}s (should be under 60s)"
        return 1
    fi

    # Test rollback performance
    start_time=$(date +%s)
    rollback_session >/dev/null 2>&1
    end_time=$(date +%s)
    local rollback_duration=$((end_time - start_time))

    # Should complete within reasonable time
    if [[ $rollback_duration -gt 60 ]]; then
        echo "Rollback took too long: ${rollback_duration}s (should be under 60s)"
        return 1
    fi

    # Test selective installation performance
    start_time=$(date +%s)
    local options='{"selected_components": [], "excluded_components": [], "categories": [], "dry_run": true, "show_help": false}'
    build_installation_plan "$options" >/dev/null
    end_time=$(date +%s)
    local selective_duration=$((end_time - start_time))

    # Should be very fast for planning
    if [[ $selective_duration -gt 10 ]]; then
        echo "Selective installation planning took too long: ${selective_duration}s (should be under 10s)"
        return 1
    fi
}

# Test end-to-end workflow simulation
test_end_to_end_workflow() {
    init_state_dir

    echo "=== Testing End-to-End Workflow ==="

    # 1. Start with selective installation planning
    echo "1. Planning selective installation..."
    local options='{"selected_components": ["prerequisites", "ssh_setup", "homebrew"], "excluded_components": [], "categories": [], "dry_run": true, "show_help": false}'
    local plan
    plan=$(build_installation_plan "$options")

    assert_contains "$plan" "prerequisites" "Plan should include prerequisites"

    # 2. Simulate installation execution with some failures
    echo "2. Simulating installation execution..."
    local plan_array=($plan)
    for component in "${plan_array[@]}"; do
        if [[ "$component" == "homebrew" ]]; then
            # Simulate homebrew failure
            save_state "$component" "failed" '{"error_type": "network", "exit_code": 1}'
            save_rollback_info "$component" '{"homebrew_installed": "true"}'
        else
            # Simulate success
            save_state "$component" "completed" '{"duration": 30}'
            save_rollback_info "$component" '{"backup_created": true}'
        fi
    done

    # 3. Validate installation
    echo "3. Validating installation..."
    validate_full_installation >/dev/null 2>&1
    local validation_result=$?

    # Should complete validation (may pass or fail)
    if [[ $validation_result -ne 0 && $validation_result -ne 1 ]]; then
        echo "Validation should return 0 or 1"
        return 1
    fi

    # 4. Trigger recovery due to critical failure
    echo "4. Testing recovery..."
    trigger_automatic_rollback "homebrew" "network" >/dev/null 2>&1
    local recovery_result=$?

    if [[ $recovery_result -ne 0 && $recovery_result -ne 1 ]]; then
        echo "Recovery should return 0 or 1"
        return 1
    fi

    # 5. Generate final reports
    echo "5. Generating reports..."
    local report_file="$TEMP_TEST_DIR/final_report.txt"
    generate_validation_report "$report_file" >/dev/null 2>&1

    assert_file_exists "$report_file" "Final report should be generated"

    local recovery_status
    recovery_status=$(get_recovery_status)
    assert_contains "$recovery_status" "Steps rolled back:" "Should show recovery status"

    echo "=== End-to-End Workflow Test Complete ==="
}
