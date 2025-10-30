#!/usr/bin/env bash

# Simple test framework for resilient installation system
# Provides basic test functionality similar to bats

# Test configuration
readonly TEST_DIR="$(dirname "${BASH_SOURCE[0]}")"
readonly LIB_DIR="$(dirname "$TEST_DIR")/lib"
readonly TEMP_TEST_DIR="/tmp/resilient_install_tests_$$"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

# Colors for output
if [[ -t 1 ]]; then
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_YELLOW='\033[0;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_RESET='\033[0m'
else
    readonly COLOR_GREEN=''
    readonly COLOR_RED=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_RESET=''
fi

# Setup test environment
setup_test_env() {
    mkdir -p "$TEMP_TEST_DIR"
    export HOME="$TEMP_TEST_DIR"
    export STATE_DIR="$TEMP_TEST_DIR/.dotfiles_install_state"
}

# Cleanup test environment
cleanup_test_env() {
    rm -rf "$TEMP_TEST_DIR"
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        return 1
    fi
}

assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"

    if [[ "$expected" != "$actual" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $message"
        echo "  Expected NOT: '$expected'"
        echo "  Actual:       '$actual'"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"

    if [[ -f "$file" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $message"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local message="${2:-File should not exist: $file}"

    if [[ ! -f "$file" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $message"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $message"
        echo "  String: '$haystack'"
        echo "  Should contain: '$needle'"
        return 1
    fi
}

assert_success() {
    local exit_code="$1"
    local message="${2:-Command should succeed}"

    if [[ $exit_code -eq 0 ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $message"
        echo "  Exit code: $exit_code"
        return 1
    fi
}

assert_failure() {
    local exit_code="$1"
    local message="${2:-Command should fail}"

    if [[ $exit_code -ne 0 ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $message"
        echo "  Expected failure but got success (exit code: $exit_code)"
        return 1
    fi
}

# Run a single test
run_test() {
    local test_name="$1"
    local test_function="$2"

    CURRENT_TEST="$test_name"
    ((TESTS_RUN++))

    printf "  %-50s " "$test_name"

    # Setup fresh environment for each test
    setup_test_env

    # Run the test function
    local test_output
    local exit_code=0

    test_output=$("$test_function" 2>&1) || exit_code=$?

    # Cleanup
    cleanup_test_env

    if [[ $exit_code -eq 0 ]]; then
        printf "${COLOR_GREEN}✓ PASS${COLOR_RESET}\n"
        ((TESTS_PASSED++))
    else
        printf "${COLOR_RED}✗ FAIL${COLOR_RESET}\n"
        if [[ -n "$test_output" ]]; then
            echo "$test_output" | sed 's/^/    /'
        fi
        ((TESTS_FAILED++))
    fi
}

# Run all tests in a file
run_test_file() {
    local test_file="$1"

    if [[ ! -f "$test_file" ]]; then
        echo "Test file not found: $test_file"
        return 1
    fi

    echo
    printf "${COLOR_BLUE}Running tests from: %s${COLOR_RESET}\n" "$(basename "$test_file")"
    echo "=================================================="

    # Source the test file
    source "$test_file"

    # Find all test functions (functions starting with test_)
    local test_functions
    test_functions=$(declare -F | grep "declare -f test_" | awk '{print $3}')

    if [[ -z "$test_functions" ]]; then
        echo "No test functions found in $test_file"
        return 1
    fi

    # Run each test function
    while IFS= read -r test_func; do
        local test_name="${test_func#test_}"
        test_name="${test_name//_/ }"
        run_test "$test_name" "$test_func"
    done <<< "$test_functions"
}

# Print test summary
print_summary() {
    echo
    echo "=================================================="
    printf "Tests run: %d, " "$TESTS_RUN"
    printf "${COLOR_GREEN}Passed: %d${COLOR_RESET}, " "$TESTS_PASSED"
    printf "${COLOR_RED}Failed: %d${COLOR_RESET}\n" "$TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        printf "\n${COLOR_GREEN}All tests passed!${COLOR_RESET}\n"
        return 0
    else
        printf "\n${COLOR_RED}Some tests failed.${COLOR_RESET}\n"
        return 1
    fi
}

# Main test runner
main() {
    local test_files=("$@")

    if [[ ${#test_files[@]} -eq 0 ]]; then
        # Define test files in order of dependency
        test_files=(
            "$TEST_DIR/test_state.sh"
            "$TEST_DIR/test_executor.sh"
            "$TEST_DIR/test_progress.sh"
            "$TEST_DIR/test_validator.sh"
            "$TEST_DIR/test_recovery.sh"
            "$TEST_DIR/test_selective.sh"
            "$TEST_DIR/test_integration_validation_recovery.sh"
        )
    fi

    echo "Resilient Installation Test Runner"
    echo "=================================="

    for test_file in "${test_files[@]}"; do
        if [[ -f "$test_file" ]]; then
            run_test_file "$test_file"
        else
            echo "Warning: Test file not found: $test_file"
        fi
    done

    print_summary
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
