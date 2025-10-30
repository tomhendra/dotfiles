#!/usr/bin/env bash

# Standalone Validation Script for Resilient Installation
# Provides comprehensive validation of system state and installation completeness

set -euo pipefail

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# Source libraries if available
if [[ -f "$SCRIPT_DIR/lib/validator.sh" ]]; then
    source "$SCRIPT_DIR/lib/validator.sh"
fi

if [[ -f "$SCRIPT_DIR/lib/progress.sh" ]]; then
    source "$SCRIPT_DIR/lib/progress.sh"
fi

if [[ -f "$SCRIPT_DIR/lib/error_handler.sh" ]]; then
    source "$SCRIPT_DIR/lib/error_handler.sh"
fi

# Configuration
readonly VALIDATION_REPORT_FILE="$HOME/.dotfiles_validation_$(date +%Y%m%d_%H%M%S).json"
readonly VALIDATION_LOG_FILE="$HOME/.dotfiles_validation.log"

# Validation categories
declare -A VALIDATION_CATEGORIES=(
    ["system"]="System requirements and compatibility"
    ["tools"]="Development tools and utilities"
    ["configurations"]="Configuration files and settings"
    ["symlinks"]="Symbolic links integrity"
    ["permissions"]="File and directory permissions"
    ["functionality"]="Tool functionality and integration"
)

# Initialize validation tracking
init_validation() {
    echo "# Validation Log - $(date)" > "$VALIDATION_LOG_FILE"
    echo '{"validation_id":"'$(uuidgen 2>/dev/null || date +%s)'","started_at":"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'","categories":{},"summary":{"total":0,"passed":0,"failed":0,"warnings":0}}' > "$VALIDATION_REPORT_FILE"
}

# Log validation result
log_validation_result() {
    local category="$1"
    local test_name="$2"
    local status="$3"  # passed, failed, warning
    local message="$4"
    local details="${5:-}"

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Log to file
    {
        echo "[$timestamp] [$category] $test_name: $status"
        echo "  Message: $message"
        if [[ -n "$details" ]]; then
            echo "  Details: $details"
        fi
        echo "---"
    } >> "$VALIDATION_LOG_FILE"

    # Update JSON report
    local temp_report=$(mktemp)
    python3 -c "
import json
import sys

try:
    with open('$VALIDATION_REPORT_FILE', 'r') as f:
        data = json.load(f)
except:
    data = {'validation_id': '', 'started_at': '', 'categories': {}, 'summary': {'total': 0, 'passed': 0, 'failed': 0, 'warnings': 0}}

# Initialize category if not exists
if '$category' not in data['categories']:
    data['categories']['$category'] = {'tests': [], 'summary': {'total': 0, 'passed': 0, 'failed': 0, 'warnings': 0}}

# Add test result
test_result = {
    'name': '$test_name',
    'status': '$status',
    'message': '$message',
    'details': '$details',
    'timestamp': '$timestamp'
}

data['categories']['$category']['tests'].append(test_result)

# Update counters
data['categories']['$category']['summary']['total'] += 1
data['categories']['$category']['summary']['$status'] += 1
data['summary']['total'] += 1
data['summary']['$status'] += 1

# Write updated report
with open('$temp_report', 'w') as f:
    json.dump(data, f, indent=2)
" && mv "$temp_report" "$VALIDATION_REPORT_FILE"
}

# Validate system requirements
validate_system_requirements() {
    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🖥️  Validating System Requirements"
    echo

    # macOS version
    local macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    if [[ "$macos_version" != "unknown" ]]; then
        local major_version=$(echo "$macos_version" | cut -d. -f1)
        if [[ $major_version -ge 11 ]]; then
            print_color "$COLOR_GREEN" "   ✅ macOS version: $macos_version (supported)"
            log_validation_result "system" "macos_version" "passed" "macOS $macos_version is supported"
        else
            print_color "$COLOR_YELLOW" "   ⚠️  macOS version: $macos_version (may have compatibility issues)"
            log_validation_result "system" "macos_version" "warning" "macOS $macos_version may have compatibility issues"
        fi
    else
        print_color "$COLOR_RED" "   ❌ Could not determine macOS version"
        log_validation_result "system" "macos_version" "failed" "Could not determine macOS version"
    fi

    # Disk space
    local available_space=$(df -h "$HOME" | awk 'NR==2 {print $4}' | sed 's/[^0-9.]//g')
    if [[ -n "$available_space" ]] && (( $(echo "$available_space > 5" | bc -l 2>/dev/null || echo 0) )); then
        print_color "$COLOR_GREEN" "   ✅ Disk space: ${available_space}GB available"
        log_validation_result "system" "disk_space" "passed" "${available_space}GB available"
    else
        print_color "$COLOR_YELLOW" "   ⚠️  Disk space: Low available space"
        log_validation_result "system" "disk_space" "warning" "Low disk space detected"
    fi

    # Architecture
    local arch=$(uname -m)
    case "$arch" in
        "x86_64"|"arm64")
            print_color "$COLOR_GREEN" "   ✅ Architecture: $arch (supported)"
            log_validation_result "system" "architecture" "passed" "Architecture $arch is supported"
            ;;
        *)
            print_color "$COLOR_YELLOW" "   ⚠️  Architecture: $arch (untested)"
            log_validation_result "system" "architecture" "warning" "Architecture $arch is untested"
            ;;
    esac

    # Command Line Tools
    if xcode-select -p >/dev/null 2>&1; then
        print_color "$COLOR_GREEN" "   ✅ Xcode Command Line Tools: installed"
        log_validation_result "system" "xcode_tools" "passed" "Xcode Command Line Tools are installed"
    else
        print_color "$COLOR_RED" "   ❌ Xcode Command Line Tools: not installed"
        log_validation_result "system" "xcode_tools" "failed" "Xcode Command Line Tools are not installed"
    fi
}

# Validate development tools
validate_development_tools() {
    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🛠️  Validating Development Tools"
    echo

    # Define required tools with their validation commands
    local -A tools=(
        ["git"]="git --version"
        ["brew"]="brew --version"
        ["node"]="node --version"
        ["npm"]="npm --version"
        ["rustc"]="rustc --version"
        ["cargo"]="cargo --version"
        ["gh"]="gh --version"
        ["bat"]="bat --version"
        ["rg"]="rg --version"
        ["starship"]="starship --version"
    )

    for tool in "${!tools[@]}"; do
        local cmd="${tools[$tool]}"
        printf "   Checking %s... " "$tool"

        if command -v "$tool" >/dev/null 2>&1; then
            local version_output
            if version_output=$(eval "$cmd" 2>/dev/null); then
                local version=$(echo "$version_output" | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 || echo "unknown")
                print_color "$COLOR_GREEN" "✅ $version"
                log_validation_result "tools" "$tool" "passed" "Tool $tool is installed (version: $version)"
            else
                print_color "$COLOR_YELLOW" "⚠️  installed but version check failed"
                log_validation_result "tools" "$tool" "warning" "Tool $tool is installed but version check failed"
            fi
        else
            print_color "$COLOR_RED" "❌ not found"
            log_validation_result "tools" "$tool" "failed" "Tool $tool is not installed or not in PATH"
        fi
        echo
    done

    # Check global npm packages
    echo
    printf "   Checking global npm packages... "
    if command -v npm >/dev/null 2>&1; then
        local global_packages=$(npm list -g --depth=0 2>/dev/null | grep -c "├──\|└──" || echo "0")
        if [[ $global_packages -gt 0 ]]; then
            print_color "$COLOR_GREEN" "✅ $global_packages packages installed"
            log_validation_result "tools" "npm_global_packages" "passed" "$global_packages global npm packages installed"
        else
            print_color "$COLOR_YELLOW" "⚠️  no global packages found"
            log_validation_result "tools" "npm_global_packages" "warning" "No global npm packages found"
        fi
    else
        print_color "$COLOR_RED" "❌ npm not available"
        log_validation_result "tools" "npm_global_packages" "failed" "npm not available for package check"
    fi
    echo
}

# Validate configuration files
validate_configurations() {
    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "⚙️  Validating Configuration Files"
    echo

    # Define configuration files to check
    local -A config_files=(
        [".zshrc"]="$HOME/.zshrc"
        [".zprofile"]="$HOME/.zprofile"
        [".gitconfig"]="$HOME/.gitconfig"
        [".gitignore_global"]="$HOME/.gitignore_global"
        ["ghostty_config"]="$HOME/.config/ghostty/config"
        ["bat_config"]="$HOME/.config/bat/config"
        ["starship_config"]="$HOME/.config/starship.toml"
    )

    for config_name in "${!config_files[@]}"; do
        local config_path="${config_files[$config_name]}"
        printf "   Checking %s... " "$config_name"

        if [[ -f "$config_path" ]]; then
            # Check if file is readable
            if [[ -r "$config_path" ]]; then
                # Basic syntax validation based on file type
                local validation_result="valid"
                local file_size=$(wc -c < "$config_path")

                case "$config_name" in
                    *".toml")
                        # TOML syntax check if available
                        if command -v python3 >/dev/null 2>&1; then
                            if ! python3 -c "import tomllib; tomllib.load(open('$config_path', 'rb'))" 2>/dev/null; then
                                validation_result="syntax_error"
                            fi
                        fi
                        ;;
                    *"zsh"*|*"bash"*)
                        # Shell syntax check
                        if ! bash -n "$config_path" 2>/dev/null; then
                            validation_result="syntax_error"
                        fi
                        ;;
                esac

                if [[ "$validation_result" == "valid" ]]; then
                    print_color "$COLOR_GREEN" "✅ valid (${file_size} bytes)"
                    log_validation_result "configurations" "$config_name" "passed" "Configuration file is valid (${file_size} bytes)"
                else
                    print_color "$COLOR_RED" "❌ syntax error"
                    log_validation_result "configurations" "$config_name" "failed" "Configuration file has syntax errors"
                fi
            else
                print_color "$COLOR_RED" "❌ not readable"
                log_validation_result "configurations" "$config_name" "failed" "Configuration file is not readable"
            fi
        else
            print_color "$COLOR_YELLOW" "⚠️  not found"
            log_validation_result "configurations" "$config_name" "warning" "Configuration file not found"
        fi
        echo
    done
}

# Validate symbolic links
validate_symlinks() {
    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🔗 Validating Symbolic Links"
    echo

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        print_color "$COLOR_YELLOW" "   ⚠️  Dotfiles directory not found: $DOTFILES_DIR"
        log_validation_result "symlinks" "dotfiles_directory" "warning" "Dotfiles directory not found at $DOTFILES_DIR"
        return
    fi

    # Find all symlinks in home directory that point to dotfiles
    local symlink_count=0
    local valid_symlinks=0
    local broken_symlinks=0

    while IFS= read -r -d '' symlink; do
        ((symlink_count++))
        local target=$(readlink "$symlink")
        local symlink_name=$(basename "$symlink")

        printf "   Checking %s... " "$symlink_name"

        if [[ -e "$target" ]]; then
            print_color "$COLOR_GREEN" "✅ valid → $target"
            ((valid_symlinks++))
            log_validation_result "symlinks" "$symlink_name" "passed" "Symlink points to valid target: $target"
        else
            print_color "$COLOR_RED" "❌ broken → $target"
            ((broken_symlinks++))
            log_validation_result "symlinks" "$symlink_name" "failed" "Symlink points to missing target: $target"
        fi
        echo
    done < <(find "$HOME" -maxdepth 3 -type l -lname "*/.dotfiles/*" -print0 2>/dev/null)

    echo
    if [[ $symlink_count -eq 0 ]]; then
        print_color "$COLOR_YELLOW" "   ⚠️  No dotfiles symlinks found"
        log_validation_result "symlinks" "symlink_summary" "warning" "No dotfiles symlinks found"
    else
        print_color "$COLOR_BLUE" "   📊 Summary: $valid_symlinks valid, $broken_symlinks broken (total: $symlink_count)"
        if [[ $broken_symlinks -eq 0 ]]; then
            log_validation_result "symlinks" "symlink_summary" "passed" "$valid_symlinks valid symlinks, no broken links"
        else
            log_validation_result "symlinks" "symlink_summary" "failed" "$broken_symlinks broken symlinks found"
        fi
    fi
}

# Validate tool functionality
validate_tool_functionality() {
    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🧪 Validating Tool Functionality"
    echo

    # Git functionality
    printf "   Testing git functionality... "
    if command -v git >/dev/null 2>&1; then
        local git_user=$(git config --global user.name 2>/dev/null || echo "")
        local git_email=$(git config --global user.email 2>/dev/null || echo "")

        if [[ -n "$git_user" && -n "$git_email" ]]; then
            print_color "$COLOR_GREEN" "✅ configured ($git_user <$git_email>)"
            log_validation_result "functionality" "git_config" "passed" "Git is configured with user: $git_user <$git_email>"
        else
            print_color "$COLOR_YELLOW" "⚠️  not fully configured"
            log_validation_result "functionality" "git_config" "warning" "Git user configuration incomplete"
        fi
    else
        print_color "$COLOR_RED" "❌ git not available"
        log_validation_result "functionality" "git_config" "failed" "Git is not available"
    fi
    echo

    # SSH functionality
    printf "   Testing SSH key setup... "
    if [[ -f "$HOME/.ssh/id_rsa" || -f "$HOME/.ssh/id_ed25519" ]]; then
        local key_count=$(find "$HOME/.ssh" -name "id_*" -not -name "*.pub" 2>/dev/null | wc -l)
        print_color "$COLOR_GREEN" "✅ SSH keys found ($key_count keys)"
        log_validation_result "functionality" "ssh_keys" "passed" "$key_count SSH keys found"
    else
        print_color "$COLOR_YELLOW" "⚠️  no SSH keys found"
        log_validation_result "functionality" "ssh_keys" "warning" "No SSH keys found"
    fi
    echo

    # Shell integration
    printf "   Testing shell integration... "
    if [[ "$SHELL" == *"zsh"* ]]; then
        if [[ -f "$HOME/.zshrc" ]]; then
            print_color "$COLOR_GREEN" "✅ zsh with .zshrc"
            log_validation_result "functionality" "shell_integration" "passed" "zsh shell with .zshrc configuration"
        else
            print_color "$COLOR_YELLOW" "⚠️  zsh without .zshrc"
            log_validation_result "functionality" "shell_integration" "warning" "zsh shell but no .zshrc found"
        fi
    else
        print_color "$COLOR_YELLOW" "⚠️  not using zsh ($SHELL)"
        log_validation_result "functionality" "shell_integration" "warning" "Not using zsh shell: $SHELL"
    fi
    echo

    # Homebrew functionality
    printf "   Testing Homebrew functionality... "
    if command -v brew >/dev/null 2>&1; then
        local brew_packages=$(brew list --formula 2>/dev/null | wc -l || echo "0")
        local brew_casks=$(brew list --cask 2>/dev/null | wc -l || echo "0")
        print_color "$COLOR_GREEN" "✅ $brew_packages formulae, $brew_casks casks"
        log_validation_result "functionality" "homebrew" "passed" "Homebrew working with $brew_packages formulae and $brew_casks casks"
    else
        print_color "$COLOR_RED" "❌ Homebrew not available"
        log_validation_result "functionality" "homebrew" "failed" "Homebrew is not available"
    fi
    echo
}

# Generate validation summary
generate_validation_summary() {
    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "📋 Validation Summary"
    echo

    # Read and display summary from JSON report
    if [[ -f "$VALIDATION_REPORT_FILE" ]]; then
        python3 -c "
import json
try:
    with open('$VALIDATION_REPORT_FILE', 'r') as f:
        data = json.load(f)

    summary = data.get('summary', {})
    total = summary.get('total', 0)
    passed = summary.get('passed', 0)
    failed = summary.get('failed', 0)
    warnings = summary.get('warnings', 0)

    print(f'Total tests: {total}')
    print(f'✅ Passed: {passed}')
    print(f'❌ Failed: {failed}')
    print(f'⚠️  Warnings: {warnings}')

    if total > 0:
        success_rate = (passed / total) * 100
        print(f'Success rate: {success_rate:.1f}%')

    print()

    # Category breakdown
    categories = data.get('categories', {})
    if categories:
        print('By Category:')
        for category, cat_data in categories.items():
            cat_summary = cat_data.get('summary', {})
            cat_total = cat_summary.get('total', 0)
            cat_passed = cat_summary.get('passed', 0)
            cat_failed = cat_summary.get('failed', 0)
            cat_warnings = cat_summary.get('warnings', 0)

            status_icon = '✅' if cat_failed == 0 else '❌' if cat_failed > cat_warnings else '⚠️'
            print(f'  {status_icon} {category}: {cat_passed}/{cat_total} passed')

    # Overall status
    print()
    if failed == 0:
        if warnings == 0:
            print('🎉 All validations passed!')
            exit_code = 0
        else:
            print('⚠️  Validation completed with warnings')
            exit_code = 1
    else:
        print('❌ Validation failed - issues need attention')
        exit_code = 2

    print(f'📁 Detailed report: $VALIDATION_REPORT_FILE')
    print(f'📁 Validation log: $VALIDATION_LOG_FILE')

    exit(exit_code)

except Exception as e:
    print(f'Error generating summary: {e}')
    exit(3)
"
    else
        print_color "$COLOR_RED" "❌ Validation report not found"
        return 1
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Standalone validation script for dotfiles installation"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -q, --quiet             Suppress non-essential output"
    echo "  -c, --category CATEGORY Only validate specific category"
    echo "  -r, --report-only       Only generate and show summary report"
    echo "  --dotfiles-dir DIR      Specify dotfiles directory (default: ~/.dotfiles)"
    echo
    echo "Categories:"
    for category in "${!VALIDATION_CATEGORIES[@]}"; do
        echo "  $category: ${VALIDATION_CATEGORIES[$category]}"
    done
    echo
    echo "Exit codes:"
    echo "  0: All validations passed"
    echo "  1: Validations passed with warnings"
    echo "  2: Validation failures detected"
    echo "  3: Script error"
}

# Main validation function
main() {
    local category_filter=""
    local report_only=false
    local verbose=false
    local quiet=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -c|--category)
                category_filter="$2"
                shift 2
                ;;
            -r|--report-only)
                report_only=true
                shift
                ;;
            --dotfiles-dir)
                DOTFILES_DIR="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_usage >&2
                exit 1
                ;;
        esac
    done

    # Set output preferences
    if [[ "$quiet" == "true" ]]; then
        exec 1>/dev/null
    fi

    # Show header
    if [[ "$report_only" == "false" ]]; then
        echo
        print_color "$COLOR_BOLD$COLOR_BLUE" "🔍 Dotfiles Installation Validation"
        echo
        print_color "$COLOR_BLUE" "Starting comprehensive validation..."
        echo

        # Initialize validation tracking
        init_validation

        # Run validation categories
        if [[ -z "$category_filter" || "$category_filter" == "system" ]]; then
            validate_system_requirements
        fi

        if [[ -z "$category_filter" || "$category_filter" == "tools" ]]; then
            validate_development_tools
        fi

        if [[ -z "$category_filter" || "$category_filter" == "configurations" ]]; then
            validate_configurations
        fi

        if [[ -z "$category_filter" || "$category_filter" == "symlinks" ]]; then
            validate_symlinks
        fi

        if [[ -z "$category_filter" || "$category_filter" == "functionality" ]]; then
            validate_tool_functionality
        fi
    fi

    # Generate and show summary
    generate_validation_summary
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
