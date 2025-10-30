#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error when substituting

# Tomdot - Enhanced macOS development environment installer
# Uses the new resilient installation framework with Rock.js-inspired UI

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Initialize state and logging early
export TOMDOT_STATE_DIR="${HOME}/.tomdot_install_state"
export TOMDOT_STATE_FILE="${TOMDOT_STATE_DIR}/state.json"
export TOMDOT_BACKUP_DIR="${TOMDOT_STATE_DIR}/backups"
export TOMDOT_LOG_FILE="${TOMDOT_STATE_DIR}/install.log"

# Source the tomdot installation framework components
if [[ -f "${SCRIPT_DIR}/lib/tomdot_installer.sh" ]]; then
    source "${SCRIPT_DIR}/lib/tomdot_installer.sh"
else
    echo "Error: tomdot installation framework not found at ${SCRIPT_DIR}/lib/tomdot_installer.sh"
    echo "Please ensure the lib/ directory is present with the required framework files."
    exit 1
fi

# Verify all framework components are loaded
if ! declare -f tomdot_install >/dev/null 2>&1; then
    echo "Error: tomdot_installer.sh functions not properly loaded"
    exit 1
fi

if ! declare -f ui_start_section >/dev/null 2>&1; then
    echo "Error: tomdot_ui.sh functions not properly loaded"
    exit 1
fi

# Cleanup function for trap handler
cleanup() {
    local exit_code=$?

    # Stop any running spinners
    if [[ -n "${TOMDOT_SPINNER_PID:-}" ]]; then
        kill "$TOMDOT_SPINNER_PID" 2>/dev/null || true
        wait "$TOMDOT_SPINNER_PID" 2>/dev/null || true
    fi

    # Log cleanup
    if [[ $exit_code -ne 0 ]]; then
        tomdot_log "ERROR" "Installation interrupted with exit code: $exit_code"
        echo
        echo "Installation was interrupted. You can resume later with:"
        echo "  $0 --resume"
        echo
        echo "Or check the log file for details:"
        echo "  cat $TOMDOT_LOG_FILE"
    fi

    exit $exit_code
}

# Set up trap handler for cleanup
trap cleanup EXIT INT TERM

# Check for required tools
command -v git >/dev/null 2>&1 || { echo "Error: git is required but not installed" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 is required but not installed" >&2; exit 1; }

# Parse command line arguments
TOMDOT_MODE="install"
TOMDOT_STEP=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --step)
            TOMDOT_MODE="step"
            TOMDOT_STEP="$2"
            shift 2
            ;;
        --resume)
            TOMDOT_MODE="resume"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --step STEP    Run individual installation step"
            echo "                 Available steps: ssh, homebrew, packages, languages, symlinks"
            echo "  --resume       Resume installation from failure point"
            echo "  --help, -h     Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Full installation"
            echo "  $0 --step ssh         # Run SSH setup only"
            echo "  $0 --resume           # Resume from failure"
            echo ""
            echo "Entry point compatibility:"
            echo "  curl -ssL https://git.io/tomdot | sh"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main execution logic with enhanced error handling
main() {
    # Initialize state and logging
    tomdot_init_state

    # Log installation start
    tomdot_log "INFO" "Starting tomdot installation (mode: $TOMDOT_MODE)"

    case "$TOMDOT_MODE" in
        "step")
            if [[ -z "$TOMDOT_STEP" ]]; then
                echo "Error: --step requires a step name"
                echo "Available steps: ssh, homebrew, packages, languages, symlinks"
                exit 1
            fi

            tomdot_log "INFO" "Running individual step: $TOMDOT_STEP"

            # Validate prerequisites for individual steps
            if ! tomdot_check_prerequisites; then
                echo "Prerequisites validation failed. Please resolve issues before continuing."
                exit 1
            fi

            tomdot_run_step "$TOMDOT_STEP"
            ;;
        "resume")
            tomdot_log "INFO" "Resuming installation from previous state"

            if ! tomdot_can_resume; then
                echo "No previous installation found to resume. Starting fresh installation..."
                tomdot_install
            else
                tomdot_resume
            fi
            ;;
        "install")
            tomdot_log "INFO" "Starting full installation"

            # Validate prerequisites before starting
            if ! tomdot_check_prerequisites; then
                echo "Prerequisites validation failed. Please resolve issues before continuing."
                exit 1
            fi

            tomdot_install
            ;;
    esac

    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        tomdot_log "INFO" "Installation completed successfully"

        # Run final validation
        echo
        ui_start_section "Final Validation"
        if tomdot_validate_installation; then
            printf "${C_DIM}│${C_RESET} ${C_GREEN}✅ All validations passed${C_RESET}\n"
            printf "${C_DIM}│${C_RESET}\n"
        else
            printf "${C_DIM}│${C_RESET} ${C_YELLOW}⚠️  Some validations failed${C_RESET}\n"
            printf "${C_DIM}│${C_RESET}\n"
        fi
    else
        tomdot_log "ERROR" "Installation failed with exit code: $exit_code"
    fi

    return $exit_code
}

# Execute main function
main "$@"
