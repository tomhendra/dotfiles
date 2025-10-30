#!/usr/bin/env bash

# Simple demo to test core functionality
source lib/state.sh
source lib/executor.sh

echo "=== Simple Resilient Installation Demo ==="
echo

# Test step functions
test_success_step() {
    echo "Performing successful operation..."
    sleep 1
    echo "Operation completed successfully"
    return 0
}

test_network_step() {
    echo "Testing network connectivity..."
    if curl -s --connect-timeout 3 --max-time 5 "https://github.com" >/dev/null; then
        echo "Network test passed"
        return 0
    else
        echo "Network test failed"
        return 1
    fi
}

test_failure_step() {
    echo "This step will fail to demonstrate error handling"
    return 1
}

echo "1. Testing successful step execution..."
execute_step "test_success" "test_success_step" "Test Success Step"
echo "   Status: $(get_step_status "test_success")"
echo

echo "2. Testing network operation with retry..."
execute_step "test_network" "test_network_step" "Test Network Step"
echo "   Status: $(get_step_status "test_network")"
echo

echo "3. Testing failure handling..."
execute_step "test_failure" "test_failure_step" "Test Failure Step" || echo "   (Expected failure handled)"
echo "   Status: $(get_step_status "test_failure")"
echo

echo "4. State summary:"
get_installation_summary
echo

echo "5. Testing step completion check..."
if is_step_completed "test_success"; then
    echo "   ✓ Success step correctly marked as completed"
else
    echo "   ✗ Success step not marked as completed"
fi

if is_step_completed "test_failure"; then
    echo "   ✗ Failure step incorrectly marked as completed"
else
    echo "   ✓ Failure step correctly not marked as completed"
fi

echo
echo "Demo completed! State saved to: $STATE_FILE"
