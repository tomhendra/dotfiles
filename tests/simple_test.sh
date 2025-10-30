#!/usr/bin/env bash

# Simple test to verify core libraries work
set -e

echo "Testing core libraries..."

# Test state management
echo "Testing state management..."
source lib/state.sh

# Initialize and test basic functionality
init_state_dir
echo "✓ State directory initialized"

# Test saving and loading state
save_state "test_step" "completed" '{"test": true}'
status=$(get_step_status "test_step")
if [[ "$status" == "completed" ]]; then
    echo "✓ State save/load works"
else
    echo "✗ State save/load failed"
    exit 1
fi

# Test step completion check
if is_step_completed "test_step"; then
    echo "✓ Step completion check works"
else
    echo "✗ Step completion check failed"
    exit 1
fi

# Test executor
echo "Testing executor..."
source lib/executor.sh

# Test command existence check
if command_exists "bash"; then
    echo "✓ Command existence check works"
else
    echo "✗ Command existence check failed"
    exit 1
fi

# Test progress tracking
echo "Testing progress tracking..."
source lib/progress.sh

# Test duration formatting
duration=$(format_duration 90)
if [[ "$duration" == "1m 30s" ]]; then
    echo "✓ Duration formatting works"
else
    echo "✗ Duration formatting failed (got: $duration)"
    exit 1
fi

echo "All basic tests passed!"
