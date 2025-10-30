#!/usr/bin/env bash

# Interactive Installation Options for Resilient Installation
# Handles user confirmations, choices, and conflict resolution

# Source dependencies
if [ -f "$(dirname "${BASH_SOURCE[0]}")/progress.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/progress.sh"
elif [ -f "lib/progress.sh" ]; then
    source "lib/progress.sh"
fi

# Configuration
readonly INTERACTIVE_TIMEOUT="${INTERACTIVE_TIMEOUT:-30}"
readonly DEFAULT_CHOICE="${DEFAULT_CHOICE:-n}"

# Interactive mode detection
is_interactive() {
    [[ -t 0 ]] && [[ -t 1 ]] && [[ "${INTERACTIVE_MODE:-auto}" != "false" ]]
}

# Prompt user for yes/no confirmation with timeout
prompt_yes_no() {
    local message="$1"
    local default="${2:-n}"
    local timeout="${3:-$INTERACTIVE_TIMEOUT}"

    if ! is_interactive; then
        echo "$default"
        return
    fi

    local prompt_text
    if [[ "$default" == "y" ]]; then
        prompt_text="[Y/n]"
    else
        prompt_text="[y/N]"
    fi

    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🤔 $message"
    echo

    local response
    if command -v timeout >/dev/null 2>&1; then
        printf "   %s (timeout in %ds): " "$prompt_text" "$timeout"
        if ! response=$(timeout "$timeout" bash -c 'read -r response; echo "$response"'); then
            echo
            print_color "$COLOR_YELLOW" "   ⏰ Timeout reached, using default: $default"
            echo "$default"
            return
        fi
    else
        printf "   %s: " "$prompt_text"
        read -r response
    fi

    case "${response,,}" in
        y|yes|true|1)
            echo "y"
            ;;
        n|no|false|0)
            echo "n"
            ;;
        "")
            echo "$default"
            ;;
        *)
            print_color "$COLOR_YELLOW" "   ⚠️  Invalid response. Using default: $default"
            echo "$default"
            ;;
    esac
}

# Prompt user for multiple choice selection
prompt_choice() {
    local message="$1"
    shift
    local choices=("$@")
    local default_index=0

    if ! is_interactive; then
        echo "${choices[$default_index]}"
        return
    fi

    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🤔 $message"
    echo

    # Display choices
    for i in "${!choices[@]}"; do
        local marker=" "
        if [[ $i -eq $default_index ]]; then
            marker="*"
            print_color "$COLOR_BRIGHT_BLUE" "   $((i + 1)). ${choices[$i]} (default)"
        else
            print_color "$COLOR_BLUE" "   $((i + 1)). ${choices[$i]}"
        fi
        echo
    done

    echo
    printf "   Enter choice [1-%d]: " "${#choices[@]}"

    local response
    read -r response

    # Validate response
    if [[ -z "$response" ]]; then
        echo "${choices[$default_index]}"
        return
    fi

    if [[ "$response" =~ ^[0-9]+$ ]] && [[ $response -ge 1 ]] && [[ $response -le ${#choices[@]} ]]; then
        echo "${choices[$((response - 1))]}"
    else
        print_color "$COLOR_YELLOW" "   ⚠️  Invalid choice. Using default: ${choices[$default_index]}"
        echo "${choices[$default_index]}"
    fi
}

# Handle existing configuration file conflicts
handle_config_conflict() {
    local config_file="$1"
    local backup_file="$2"
    local config_type="${3:-configuration}"

    echo
    print_color "$COLOR_BOLD$COLOR_YELLOW" "⚠️  Configuration Conflict Detected"
    echo
    print_color "$COLOR_YELLOW" "   File: $config_file"
    print_color "$COLOR_YELLOW" "   Type: $config_type"
    echo

    if [[ -f "$config_file" ]]; then
        print_color "$COLOR_GRAY" "   Current file size: $(wc -c < "$config_file") bytes"
        print_color "$COLOR_GRAY" "   Last modified: $(date -r "$config_file" '+%Y-%m-%d %H:%M:%S')"
    fi

    local choices=(
        "Replace (backup existing)"
        "Merge configurations"
        "Keep existing (skip)"
        "View differences first"
        "Manual resolution"
    )

    local choice=$(prompt_choice "How would you like to handle this conflict?" "${choices[@]}")

    case "$choice" in
        "Replace (backup existing)")
            echo "replace"
            ;;
        "Merge configurations")
            echo "merge"
            ;;
        "Keep existing (skip)")
            echo "skip"
            ;;
        "View differences first")
            echo "diff"
            ;;
        "Manual resolution")
            echo "manual"
            ;;
        *)
            echo "skip"  # Default to safe option
            ;;
    esac
}

# Show configuration differences
show_config_diff() {
    local existing_file="$1"
    local new_file="$2"
    local config_type="${3:-configuration}"

    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "📋 Configuration Differences"
    echo
    print_color "$COLOR_BLUE" "   Comparing: $config_type"
    print_color "$COLOR_GRAY" "   Existing: $existing_file"
    print_color "$COLOR_GRAY" "   New:      $new_file"
    echo

    if command -v diff >/dev/null 2>&1; then
        # Use colored diff if available
        if command -v colordiff >/dev/null 2>&1; then
            colordiff -u "$existing_file" "$new_file" 2>/dev/null || diff -u "$existing_file" "$new_file"
        else
            diff -u "$existing_file" "$new_file"
        fi
    else
        print_color "$COLOR_YELLOW" "   ⚠️  diff command not available"
        echo
        print_color "$COLOR_GRAY" "   Existing file preview (first 10 lines):"
        head -10 "$existing_file" 2>/dev/null | sed 's/^/     /'
        echo
        print_color "$COLOR_GRAY" "   New file preview (first 10 lines):"
        head -10 "$new_file" 2>/dev/null | sed 's/^/     /'
    fi

    echo
}

# Merge configuration files intelligently
merge_configurations() {
    local existing_file="$1"
    local new_file="$2"
    local output_file="$3"
    local config_type="${4:-configuration}"

    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🔄 Merging Configurations"
    echo

    # Create backup first
    local backup_file="${existing_file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$existing_file" "$backup_file"
    print_color "$COLOR_GREEN" "   ✅ Backup created: $backup_file"

    # Attempt intelligent merge based on file type
    case "$config_type" in
        "shell"|"zsh"|"bash")
            merge_shell_config "$existing_file" "$new_file" "$output_file"
            ;;
        "git")
            merge_git_config "$existing_file" "$new_file" "$output_file"
            ;;
        "json")
            merge_json_config "$existing_file" "$new_file" "$output_file"
            ;;
        *)
            merge_generic_config "$existing_file" "$new_file" "$output_file"
            ;;
    esac
}

# Merge shell configuration files
merge_shell_config() {
    local existing_file="$1"
    local new_file="$2"
    local output_file="$3"

    {
        echo "# Merged configuration - $(date)"
        echo "# Original file backed up"
        echo

        # Add existing custom configurations
        echo "# === Existing Custom Configuration ==="
        grep -v "^#.*dotfiles" "$existing_file" 2>/dev/null || cat "$existing_file"
        echo

        # Add new dotfiles configuration
        echo "# === Dotfiles Configuration ==="
        cat "$new_file"

    } > "$output_file"

    print_color "$COLOR_GREEN" "   ✅ Shell configuration merged"
}

# Merge Git configuration files
merge_git_config() {
    local existing_file="$1"
    local new_file="$2"
    local output_file="$3"

    # Use git config to merge intelligently
    cp "$existing_file" "$output_file"

    # Extract settings from new file and apply them
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[.*\]$ ]]; then
            current_section="$line"
        elif [[ "$line" =~ ^[[:space:]]*([^=]+)=[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]// /}"
            local value="${BASH_REMATCH[2]}"

            # Add or update the setting
            if grep -q "^[[:space:]]*$key[[:space:]]*=" "$output_file"; then
                # Update existing
                sed -i.tmp "s|^[[:space:]]*$key[[:space:]]*=.*|    $key = $value|" "$output_file"
                rm -f "$output_file.tmp"
            else
                # Add new setting to appropriate section
                if [[ -n "$current_section" ]]; then
                    sed -i.tmp "/^\\$current_section$/a\\
    $key = $value" "$output_file"
                    rm -f "$output_file.tmp"
                fi
            fi
        fi
    done < "$new_file"

    print_color "$COLOR_GREEN" "   ✅ Git configuration merged"
}

# Merge JSON configuration files
merge_json_config() {
    local existing_file="$1"
    local new_file="$2"
    local output_file="$3"

    if command -v jq >/dev/null 2>&1; then
        # Use jq for intelligent JSON merging
        jq -s '.[0] * .[1]' "$existing_file" "$new_file" > "$output_file"
        print_color "$COLOR_GREEN" "   ✅ JSON configuration merged using jq"
    else
        # Fallback to simple concatenation with warning
        merge_generic_config "$existing_file" "$new_file" "$output_file"
        print_color "$COLOR_YELLOW" "   ⚠️  jq not available, used generic merge"
    fi
}

# Generic configuration merge (fallback)
merge_generic_config() {
    local existing_file="$1"
    local new_file="$2"
    local output_file="$3"

    {
        echo "# Merged configuration - $(date)"
        echo "# Original configuration preserved above new settings"
        echo
        cat "$existing_file"
        echo
        echo "# === New dotfiles configuration ==="
        cat "$new_file"
    } > "$output_file"

    print_color "$COLOR_GREEN" "   ✅ Generic configuration merge completed"
}

# Confirm dangerous operations
confirm_dangerous_operation() {
    local operation="$1"
    local details="${2:-}"

    echo
    print_color "$COLOR_BOLD$COLOR_RED" "⚠️  Potentially Dangerous Operation"
    echo
    print_color "$COLOR_RED" "   Operation: $operation"

    if [[ -n "$details" ]]; then
        print_color "$COLOR_YELLOW" "   Details: $details"
    fi

    echo
    print_color "$COLOR_YELLOW" "   This operation may modify or replace existing files."
    print_color "$COLOR_YELLOW" "   Backups will be created when possible."
    echo

    local confirm=$(prompt_yes_no "Are you sure you want to proceed?" "n" 15)

    if [[ "$confirm" == "y" ]]; then
        print_color "$COLOR_GREEN" "   ✅ Operation confirmed"
        return 0
    else
        print_color "$COLOR_YELLOW" "   ❌ Operation cancelled by user"
        return 1
    fi
}

# Show installation options menu
show_installation_options() {
    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🛠️  Installation Options"
    echo
    print_color "$COLOR_BLUE" "   Choose your installation preferences:"
    echo

    local choices=(
        "Full installation (recommended)"
        "Minimal installation (core tools only)"
        "Custom installation (select components)"
        "Dry run (preview changes only)"
        "Resume previous installation"
    )

    local choice=$(prompt_choice "Select installation type:" "${choices[@]}")
    echo "$choice"
}

# Get user preferences for component installation
get_component_preferences() {
    local components=("$@")
    local selected_components=()

    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🎯 Component Selection"
    echo
    print_color "$COLOR_BLUE" "   Select components to install:"
    echo

    for component in "${components[@]}"; do
        local install_component=$(prompt_yes_no "Install $component?" "y" 10)
        if [[ "$install_component" == "y" ]]; then
            selected_components+=("$component")
        fi
    done

    printf "%s\n" "${selected_components[@]}"
}

# Export functions for use in other scripts
export -f is_interactive
export -f prompt_yes_no
export -f prompt_choice
export -f handle_config_conflict
export -f show_config_diff
export -f merge_configurations
export -f confirm_dangerous_operation
export -f show_installation_options
export -f get_component_preferences
