#!/usr/bin/env bash

# Tomdot - macOS development environment installer
# Can be run directly or piped from curl

# Bootstrap: when piped from curl, clone repo then re-exec with bash
# This block runs before set -eu to handle sh/bash detection safely
if [ -z "${BASH_SOURCE:-}" ] || [ "$0" = "bash" ] || [ "$0" = "sh" ] || [ "$0" = "-bash" ] || [ "$0" = "-sh" ]; then
    dotfiles_dir="${HOME}/.dotfiles"
    if [ ! -d "$dotfiles_dir" ]; then
        echo "Cloning dotfiles repository..."
        git clone https://github.com/tomhendra/dotfiles.git "$dotfiles_dir"
    fi
    exec bash "$dotfiles_dir/install.sh" "$@"
fi

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
            if [[ $# -lt 2 ]]; then
                echo "Error: --step requires a step name"
                echo "Steps: ssh, homebrew, packages, fonts, languages, claude, symlinks"
                exit 1
            fi
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
