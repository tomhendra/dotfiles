#!/usr/bin/env bash

# Verify that core libraries can be loaded and basic functions work
set -e

echo "Verifying core libraries..."

# Test 1: State management library
echo "1. Testing state management library..."
(
    source lib/state.sh

    # Test initialization
    init_state_dir

    # Test state operations
    save_state "test_step" "completed" '{"duration": 30}'
    status=$(get_step_status "test_step")

    if [[ "$status" == "completed" ]]; then
        echo "   ✓ State management functions work"
    else
        echo "   ✗ State management failed"
        exit 1
    fi
)

# Test 2: Executor library (in isolation)
echo "2. Testing executor library..."
(
    source lib/executor.sh

    # Test command existence
    if command_exists "bash"; then
        echo "   ✓ Command existence check works"
    else
        echo "   ✗ Command existence check failed"
        exit 1
    fi

    # Test error classification
    error_type=$(classify_error 7 "connection failed" "curl")
    if [[ "$error_type" == "network" ]]; then
        echo "   ✓ Error classification works"
    else
        echo "   ✗ Error classification failed"
        exit 1
    fi
)

# Test 3: Progress library (in isolation)
echo "3. Testing progress library..."
(
    # Set up minimal environment to avoid conflicts
    export STATE_DIR="/tmp/test_state_$$"
    export STATE_FILE="$STATE_DIR/state.json"
    export BACKUP_DIR="$STATE_DIR/backups"
    export LOG_FILE="$STATE_DIR/log"

    source lib/progress.sh

    # Test duration formatting
    duration=$(format_duration 90)
    if [[ "$duration" == "1m 30s" ]]; then
        echo "   ✓ Duration formatting works"
    else
        echo "   ✗ Duration formatting failed (got: $duration)"
        exit 1
    fi

    # Test progress bar
    progress=$(draw_progress_bar 5 10 20)
    if [[ "$progress" == *"50%"* ]]; then
        echo "   ✓ Progress bar drawing works"
    else
        echo "   ✗ Progress bar drawing failed"
        exit 1
    fi

    # Cleanup
    rm -rf "$STATE_DIR"
)

echo "All library verifications passed!"
echo ""
echo "Core libraries created:"
echo "  - lib/state.sh (state management with JSON persistence)"
echo "  - lib/executor.sh (step execution with retry logic)"
echo "  - lib/progress.sh (progress tracking and display)"
echo ""
echo "Test framework created:"
echo "  - tests/test_*.sh (comprehensive test suites)"
echo "  - tests/verify_libs.sh (basic verification)"
