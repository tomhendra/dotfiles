#!/bin/bash

# Simple test runner for step modules (without bats dependency)
# Tests step structure, dependencies, and basic functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
FAILED_TESTS=()

# Helper functions
log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS+=("$1")
}

# Test step file structure and metadata
test_step_structure() {
    local step_file=$1
    local step_name=$(basename "$step_file" .sh)

    log_test "Testing step structure: $step_name"

    # Source the step file
    if ! source "$step_file" 2>/tmp/source_error.log; then
        log_fail "Failed to source $step_file: $(cat /tmp/source_error.log)"
        return 1
    fi

    # Check required variables
    local required_vars=("STEP_ID" "STEP_NAME" "STEP_DESCRIPTION" "STEP_ESTIMATED_TIME" "STEP_CATEGORY" "STEP_CRITICAL")

    for var in "${required_vars[@]}"; do
        if [ -z "${!var+x}" ]; then
            log_fail "$step_name: Missing required variable $var"
            return 1
        fi
    done

    # Check STEP_DEPENDENCIES array separately
    if ! declare -p STEP_DEPENDENCIES >/dev/null 2>&1; then
        log_fail "$step_name: Missing required variable STEP_DEPENDENCIES"
        return 1
    fi

    # Check required functions
    local required_functions=("execute_${STEP_ID}_step" "validate_${STEP_ID}_step" "rollback_${STEP_ID}_step")

    for func in "${required_functions[@]}"; do
        if ! declare -f "$func" >/dev/null 2>&1; then
            log_fail "$step_name: Missing required function $func"
            return 1
        fi
    done

    log_pass "$step_name: Structure validation passed"
    return 0
}

# Test step dependencies
test_step_dependencies() {
    log_test "Testing step dependency chains"

    # Define expected dependency relationships using a function
    get_expected_deps() {
        case "$1" in
            "prerequisites") echo "" ;;
            "ssh_setup") echo "prerequisites" ;;
            "homebrew") echo "prerequisites ssh_setup" ;;
            "rust") echo "prerequisites homebrew" ;;
            "nodejs") echo "prerequisites homebrew" ;;
            "configurations") echo "prerequisites homebrew nodejs" ;;
            *) echo "" ;;
        esac
    }

    local all_valid=true

    for step_file in steps/*.sh; do
        if [ ! -f "$step_file" ]; then
            continue
        fi

        # Source step file
        source "$step_file"

        local step_name="$STEP_ID"
        local expected=$(get_expected_deps "$step_name")

        # Convert arrays to strings for comparison
        local actual_deps="${STEP_DEPENDENCIES[*]}"

        # Check if dependencies match expected (order doesn't matter)
        local deps_valid=true

        # Check each expected dependency is present
        for expected_dep in $expected; do
            if [[ ! " $actual_deps " =~ " $expected_dep " ]]; then
                log_fail "$step_name: Missing expected dependency $expected_dep"
                deps_valid=false
                all_valid=false
            fi
        done

        # Check no unexpected dependencies
        for actual_dep in $actual_deps; do
            if [[ ! " $expected " =~ " $actual_dep " ]]; then
                log_fail "$step_name: Unexpected dependency $actual_dep"
                deps_valid=false
                all_valid=false
            fi
        done

        if [ "$deps_valid" = true ]; then
            log_pass "$step_name: Dependencies are correct"
        fi
    done

    if [ "$all_valid" = true ]; then
        log_pass "All step dependencies are valid"
        return 0
    else
        log_fail "Some step dependencies are invalid"
        return 1
    fi
}

# Test execution order validation
test_execution_order() {
    log_test "Testing step execution order"

    # Define correct execution order
    local execution_order=("prerequisites" "ssh_setup" "homebrew" "rust" "nodejs" "configurations")

    # Track available steps
    local available_steps=()

    for step in "${execution_order[@]}"; do
        local step_file="steps/${step}.sh"

        if [ ! -f "$step_file" ]; then
            log_fail "Step file not found: $step_file"
            return 1
        fi

        # Source step file
        source "$step_file"

        # Check that all dependencies are satisfied
        for dep in "${STEP_DEPENDENCIES[@]}"; do
            if [[ ! " ${available_steps[*]} " =~ " ${dep} " ]]; then
                log_fail "$step: Dependency $dep not satisfied in execution order"
                return 1
            fi
        done

        # Add current step to available steps
        available_steps+=("$step")
    done

    log_pass "Step execution order is valid"
    return 0
}

# Test function existence and basic syntax
test_function_syntax() {
    log_test "Testing function syntax and structure"

    local all_valid=true

    for step_file in steps/*.sh; do
        if [ ! -f "$step_file" ]; then
            continue
        fi

        local step_name=$(basename "$step_file" .sh)

        # Check if file can be sourced without errors
        if ! bash -n "$step_file" 2>/dev/null; then
            log_fail "$step_name: Syntax errors detected"
            all_valid=false
            continue
        fi

        # Source and check functions can be called (dry run)
        source "$step_file"

        # Test that functions exist and are callable
        local functions=("execute_${STEP_ID}_step" "validate_${STEP_ID}_step" "rollback_${STEP_ID}_step")

        for func in "${functions[@]}"; do
            if ! declare -f "$func" >/dev/null 2>&1; then
                log_fail "$step_name: Function $func not properly defined"
                all_valid=false
            fi
        done

        if [ "$all_valid" = true ]; then
            log_pass "$step_name: Function syntax is valid"
        fi
    done

    if [ "$all_valid" = true ]; then
        log_pass "All step functions have valid syntax"
        return 0
    else
        log_fail "Some step functions have syntax issues"
        return 1
    fi
}

# Test library dependencies
test_library_dependencies() {
    log_test "Testing library dependencies"

    # Check that progress.sh exists and can be sourced
    if [ ! -f "lib/progress.sh" ]; then
        log_fail "Required library lib/progress.sh not found"
        return 1
    fi

    if ! source "lib/progress.sh" 2>/dev/null; then
        log_fail "Failed to source lib/progress.sh"
        return 1
    fi

    # Check that required functions exist in progress.sh
    local required_functions=("log_operation")

    for func in "${required_functions[@]}"; do
        if ! declare -f "$func" >/dev/null 2>&1; then
            log_fail "Required function $func not found in progress.sh"
            return 1
        fi
    done

    log_pass "Library dependencies are satisfied"
    return 0
}

# Main test execution
main() {
    echo "Running step module integration tests..."
    echo "========================================"

    # Change to project root directory
    cd "$(dirname "${BASH_SOURCE[0]}")/.."

    # Run tests
    test_library_dependencies

    # Test each step file
    for step_file in steps/*.sh; do
        if [ -f "$step_file" ]; then
            test_step_structure "$step_file"
        fi
    done

    test_step_dependencies
    test_execution_order
    test_function_syntax

    # Print summary
    echo ""
    echo "========================================"
    echo "Test Summary:"
    echo "  Tests run: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"

    if [ $TESTS_FAILED -gt 0 ]; then
        echo ""
        echo "Failed tests:"
        for failed_test in "${FAILED_TESTS[@]}"; do
            echo "  - $failed_test"
        done
        exit 1
    else
        echo ""
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
