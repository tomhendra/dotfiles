#!/usr/bin/env bash

set -eu

# Tomdot - macOS development environment installer
# Can be run directly or piped from curl

# Bootstrap - clones repo if needed when run via curl
bootstrap_tomdot() {
    local dotfiles_dir="${HOME}/.dotfiles"
    if [[ ! -d "$dotfiles_dir" ]]; then
        echo "Cloning dotfiles repository..."
        git clone https://github.com/tomhendra/dotfiles.git "$dotfiles_dir"
        cd "$dotfiles_dir"
        exec bash "$dotfiles_dir/install.sh" "$@"
    fi
}

# Detect if piped from curl
if [[ -n "${BASH_SOURCE:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ "$0" != "bash" && "$0" != "sh" && "$0" != "-bash" && "$0" != "-sh" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
    bootstrap_tomdot "$@"
    exit $?
fi

source "${SCRIPT_DIR}/lib/tomdot_ui.sh"
source "${SCRIPT_DIR}/lib/tomdot_installer.sh"

# Parse arguments
MODE="install"
STEP=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --step)
            MODE="step"
            STEP="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run      Show what would be done without making changes"
            echo "  --step STEP    Run individual step"
            echo "                 Steps: ssh, homebrew, packages, fonts, languages, claude, symlinks"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

export DRY_RUN

# Check prerequisites
command -v git >/dev/null 2>&1 || { echo "Error: git is required"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "Error: curl is required"; exit 1; }

if [[ "$MODE" == "step" ]]; then
    run_step "$STEP"
else
    run_all
fi
