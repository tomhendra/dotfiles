#!/usr/bin/env bats

# Test step execution order and dependency resolution

setup() {
    # Create test environment
    export TEST_DIR="${BATS_TMPDIR}/step_execution_test"
    mkdir -p "$TEST_DIR"

    # Create execution log
    export EXECUTION_LOG="${TEST_DIR}/execution.log"
    touch "$EXECUTION_LOG"
}

teardown() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
}

# Helper function to simulate step execution
simulate_step_execution() {
    local step_id=$1
    echo "EXECUTED: $step_id" >> "$EXECUTION_LOG"
}

# Helper function to check if dependencies are satisfied
check_dependencies() {
    local step_id=$1
    shift
    local dependencies=("$@")

    for dep in "${dependencies[@]}"; do
        if ! grep -q "EXECUTED: $dep" "$EXECUTION_LOG"; then
            return 1
        fi
    done
    return 0
}

@test "prerequisites step can execute without dependencies" {
    source "${BATS_TEST_DIRNAME}/../steps/prerequisites.sh"

    # Prerequisites should have no dependencies
    [ "${#STEP_DEPENDENCIES[@]}" -eq 0 ]

    # Should be able to execute first
    simulate_step_execution "$STEP_ID"
    grep -q "EXECUTED: prerequisites" "$EXECUTION_LOG"
}

@test "ssh_setup step requires prerequisites" {
    source "${BATS_TEST_DIRNAME}/../steps/ssh_setup.sh"

    # Check dependencies
    [[ " ${STEP_DEPENDENCIES[*]} " =~ " prerequisites " ]]

    # Should fail without prerequisites
    run check_dependencies "$STEP_ID" "${STEP_DEPENDENCIES[@]}"
    [ "$status" -eq 1 ]

    # Should succeed after prerequisites
    simulate_step_execution "prerequisites"
    run check_dependencies "$STEP_ID" "${STEP_DEPENDENCIES[@]}"
    [ "$status" -eq 0 ]
}

@test "homebrew step requires prerequisites and ssh_setup" {
    source "${BATS_TEST_DIRNAME}/../steps/homebrew.sh"

    # Check dependencies
    [[ " ${STEP_DEPENDENCIES[*]} " =~ " prerequisites " ]]
    [[ " ${STEP_DEPENDENCIES[*]} " =~ " ssh_setup " ]]

    # Should fail without dependencies
    run check_dependencies "$STEP_ID" "${STEP_DEPENDENCIES[@]}"
    [ "$status" -eq 1 ]

    # Should succeed after all dependencies
    simulate_step_execution "prerequisites"
    simulate_step_execution "ssh_setup"
    run check_dependencies "$STEP_ID" "${STEP_DEPENDENCIES[@]}"
    [ "$status" -eq 0 ]
}

@test "language runtime steps require homebrew" {
    # Test Rust step
    source "${BATS_TEST_DIRNAME}/../steps/rust.sh"
    [[ " ${STEP_DEPENDENCIES[*]} " =~ " homebrew " ]]

    # Test Node.js step
    source "${BATS_TEST_DIRNAME}/../steps/nodejs.sh"
    [[ " ${STEP_DEPENDENCIES[*]} " =~ " homebrew " ]]
}

@test "configurations step requires multiple dependencies" {
    source "${BATS_TEST_DIRNAME}/../steps/configurations.sh"

    # Should require prerequisites, homebrew, and nodejs
    [[ " ${STEP_DEPENDENCIES[*]} " =~ " prerequisites " ]]
    [[ " ${STEP_DEPENDENCIES[*]} " =~ " homebrew " ]]
    [[ " ${STEP_DEPENDENCIES[*]} " =~ " nodejs " ]]
}

@test "complete execution order is valid" {
    # Simulate complete installation in correct order
    local execution_order=(
        "prerequisites"
        "ssh_setup"
        "homebrew"
        "rust"
        "nodejs"
        "configurations"
    )

    for step in "${execution_order[@]}"; do
        # Load step definition
        source "${BATS_TEST_DIRNAME}/../steps/${step}.sh"

        # Check that dependencies are satisfied
        run check_dependencies "$STEP_ID" "${STEP_DEPENDENCIES[@]}"
        [ "$status" -eq 0 ]

        # Execute step
        simulate_step_execution "$STEP_ID"
    done

    # Verify all steps were executed
    for step in "${execution_order[@]}"; do
        grep -q "EXECUTED: $step" "$EXECUTION_LOG"
    done
}

@test "parallel execution of independent steps is possible" {
    # Prerequisites must be first
    simulate_step_execution "prerequisites"

    # SSH setup can run after prerequisites
    simulate_step_execution "ssh_setup"

    # Homebrew can run after prerequisites and ssh_setup
    simulate_step_execution "homebrew"

    # Rust and Node.js can potentially run in parallel after homebrew
    # (they don't depend on each other)
    source "${BATS_TEST_DIRNAME}/../steps/rust.sh"
    local rust_deps=("${STEP_DEPENDENCIES[@]}")

    source "${BATS_TEST_DIRNAME}/../steps/nodejs.sh"
    local nodejs_deps=("${STEP_DEPENDENCIES[@]}")

    # Both should be able to run after homebrew
    run check_dependencies "rust" "${rust_deps[@]}"
    [ "$status" -eq 0 ]

    run check_dependencies "nodejs" "${nodejs_deps[@]}"
    [ "$status" -eq 0 ]

    # Neither should depend on the other
    [[ ! " ${rust_deps[*]} " =~ " nodejs " ]]
    [[ ! " ${nodejs_deps[*]} " =~ " rust " ]]
}
