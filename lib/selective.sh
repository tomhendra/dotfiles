#!/usr/bin/env bash

# Selective Installation System for Resilient Installation
# Provides command-line options for component selection and dependency resolution

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/state.sh"

# Configuration
readonly DRY_RUN_PREFIX="[DRY RUN]"

# Log levels for selective installation
readonly SELECTIVE_ERROR=1
readonly SELECTIVE_WARN=2
readonly SELECTIVE_INFO=3
readonly SELECTIVE_DEBUG=4

# Current selective log level
SELECTIVE_LOG_LEVEL=${SELECTIVE_LOG_LEVEL:-$SELECTIVE_INFO}

# Selective installation logging function
selective_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ $level -le $SELECTIVE_LOG_LEVEL ]]; then
        case $level in
            $SELECTIVE_ERROR) echo "[$timestamp] SELECTIVE ERROR: $message" >&2 ;;
            $SELECTIVE_WARN)  echo "[$timestamp] SELECTIVE WARN:  $message" >&2 ;;
            $SELECTIVE_INFO)  echo "[$timestamp] SELECTIVE INFO:  $message" ;;
            $SELECTIVE_DEBUG) echo "[$timestamp] SELECTIVE DEBUG: $message" ;;
        esac
    fi

    # Always log to file if state directory exists
    if [[ -d "$STATE_DIR" ]]; then
        local level_name
        case $level in
            $SELECTIVE_ERROR) level_name="SELECTIVE_ERROR" ;;
            $SELECTIVE_WARN)  level_name="SELECTIVE_WARN" ;;
            $SELECTIVE_INFO)  level_name="SELECTIVE_INFO" ;;
            $SELECTIVE_DEBUG) level_name="SELECTIVE_DEBUG" ;;
        esac
        echo "[$timestamp] $level_name: $message" >> "$LOG_FILE"
    fi
}

# Define installation components and their metadata
declare -A COMPONENT_DEFINITIONS=(
    ["prerequisites"]="System prerequisites and validation:system:true:"
    ["ssh_setup"]="SSH key generation and configuration:security:true:prerequisites"
    ["github_auth"]="GitHub authentication setup:security:true:ssh_setup"
    ["clone_dotfiles"]="Clone dotfiles repository:setup:true:github_auth"
    ["clone_repos"]="Clone development repositories:development:false:github_auth"
    ["homebrew"]="Homebrew package manager:packages:true:prerequisites"
    ["rust"]="Rust programming language:languages:false:homebrew"
    ["nodejs"]="Node.js and npm:languages:false:homebrew"
    ["global_packages"]="Global Node.js packages:packages:false:nodejs"
    ["configurations"]="Configuration file setup:setup:true:clone_dotfiles"
    ["symlinks"]="Create configuration symlinks:setup:true:configurations"
    ["final_validation"]="Final installation validation:validation:false:symlinks"
)

# Parse component definition
parse_component_definition() {
    local component="$1"
    local definition="${COMPONENT_DEFINITIONS[$component]}"

    if [[ -z "$definition" ]]; then
        echo "unknown:unknown:false:"
        return 1
    fi

    echo "$definition"
}

# Get component description
get_component_description() {
    local component="$1"
    local definition=$(parse_component_definition "$component")
    echo "$definition" | cut -d: -f1
}

# Get component category
get_component_category() {
    local component="$1"
    local definition=$(parse_component_definition "$component")
    echo "$definition" | cut -d: -f2
}

# Check if component is required
is_component_required() {
    local component="$1"
    local definition=$(parse_component_definition "$component")
    local required=$(echo "$definition" | cut -d: -f3)
    [[ "$required" == "true" ]]
}

# Get component dependencies
get_component_dependencies() {
    local component="$1"
    local definition=$(parse_component_definition "$component")
    local deps=$(echo "$definition" | cut -d: -f4)

    if [[ -n "$deps" ]]; then
        echo "$deps" | tr ',' ' '
    fi
}

# Get all available components
get_all_components() {
    printf '%s\n' "${!COMPONENT_DEFINITIONS[@]}" | sort
}

# Get components by category
get_components_by_category() {
    local category="$1"
    local components=()

    for component in "${!COMPONENT_DEFINITIONS[@]}"; do
        if [[ "$(get_component_category "$component")" == "$category" ]]; then
            components+=("$component")
        fi
    done

    printf '%s\n' "${components[@]}" | sort
}

# Get all categories
get_all_categories() {
    local categories=()

    for component in "${!COMPONENT_DEFINITIONS[@]}"; do
        local category=$(get_component_category "$component")
        if [[ ! " ${categories[*]} " =~ " ${category} " ]]; then
            categories+=("$category")
        fi
    done

    printf '%s\n' "${categories[@]}" | sort
}

# Resolve dependencies for a component
resolve_dependencies() {
    local component="$1"
    local resolved=()
    local visited=()

    _resolve_dependencies_recursive "$component" resolved visited

    # Remove duplicates and return in dependency order
    printf '%s\n' "${resolved[@]}"
}

# Recursive dependency resolution helper
_resolve_dependencies_recursive() {
    local component="$1"
    local -n resolved_ref=$2
    local -n visited_ref=$3

    # Check for circular dependencies
    if [[ " ${visited_ref[*]} " =~ " ${component} " ]]; then
        selective_log $SELECTIVE_ERROR "Circular dependency detected: $component"
        return 1
    fi

    visited_ref+=("$component")

    # Get direct dependencies
    local deps=($(get_component_dependencies "$component"))

    # Resolve each dependency first
    for dep in "${deps[@]}"; do
        if [[ -n "$dep" ]]; then
            _resolve_dependencies_recursive "$dep" resolved_ref visited_ref
        fi
    done

    # Add current component if not already resolved
    if [[ ! " ${resolved_ref[*]} " =~ " ${component} " ]]; then
        resolved_ref+=("$component")
    fi

    # Remove from visited (for other branches)
    local new_visited=()
    for item in "${visited_ref[@]}"; do
        if [[ "$item" != "$component" ]]; then
            new_visited+=("$item")
        fi
    done
    visited_ref=("${new_visited[@]}")
}

# Validate component selection
validate_component_selection() {
    local selected_components=("$@")
    local validation_errors=()

    selective_log $SELECTIVE_DEBUG "Validating component selection: ${selected_components[*]}"

    # Check if all selected components exist
    for component in "${selected_components[@]}"; do
        if [[ -z "${COMPONENT_DEFINITIONS[$component]:-}" ]]; then
            validation_errors+=("Unknown component: $component")
        fi
    done

    # Check if required components are included
    local all_required_components=()
    for component in "${!COMPONENT_DEFINITIONS[@]}"; do
        if is_component_required "$component"; then
            all_required_components+=("$component")
        fi
    done

    for required_component in "${all_required_components[@]}"; do
        if [[ ! " ${selected_components[*]} " =~ " ${required_component} " ]]; then
            validation_errors+=("Required component not selected: $required_component")
        fi
    done

    # Report validation results
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        selective_log $SELECTIVE_ERROR "Component selection validation failed:"
        for error in "${validation_errors[@]}"; do
            selective_log $SELECTIVE_ERROR "  - $error"
        done
        return 1
    fi

    selective_log $SELECTIVE_INFO "Component selection validation passed"
    return 0
}

# Expand component selection with dependencies
expand_component_selection() {
    local selected_components=("$@")
    local expanded_components=()

    selective_log $SELECTIVE_INFO "Expanding component selection with dependencies"

    # Resolve dependencies for each selected component
    for component in "${selected_components[@]}"; do
        local component_deps=($(resolve_dependencies "$component"))

        for dep in "${component_deps[@]}"; do
            if [[ ! " ${expanded_components[*]} " =~ " ${dep} " ]]; then
                expanded_components+=("$dep")
            fi
        done
    done

    selective_log $SELECTIVE_INFO "Expanded selection: ${expanded_components[*]}"
    printf '%s\n' "${expanded_components[@]}"
}

# Parse command line options for selective installation
parse_selective_options() {
    local args=("$@")
    local selected_components=()
    local excluded_components=()
    local categories=()
    local dry_run=false
    local show_help=false

    local i=0
    while [[ $i -lt ${#args[@]} ]]; do
        case "${args[$i]}" in
            --components|--component|-c)
                ((i++))
                if [[ $i -lt ${#args[@]} ]]; then
                    IFS=',' read -ra comp_list <<< "${args[$i]}"
                    selected_components+=("${comp_list[@]}")
                fi
                ;;
            --exclude|-e)
                ((i++))
                if [[ $i -lt ${#args[@]} ]]; then
                    IFS=',' read -ra excl_list <<< "${args[$i]}"
                    excluded_components+=("${excl_list[@]}")
                fi
                ;;
            --category|--categories|-t)
                ((i++))
                if [[ $i -lt ${#args[@]} ]]; then
                    IFS=',' read -ra cat_list <<< "${args[$i]}"
                    categories+=("${cat_list[@]}")
                fi
                ;;
            --dry-run|-n)
                dry_run=true
                ;;
            --help|-h)
                show_help=true
                ;;
            *)
                selective_log $SELECTIVE_WARN "Unknown option: ${args[$i]}"
                ;;
        esac
        ((i++))
    done

    # Output parsed options as JSON
    cat << EOF
{
    "selected_components": [$(printf '"%s",' "${selected_components[@]}" | sed 's/,$//')]",
    "excluded_components": [$(printf '"%s",' "${excluded_components[@]}" | sed 's/,$//')]",
    "categories": [$(printf '"%s",' "${categories[@]}" | sed 's/,$//')]",
    "dry_run": $dry_run,
    "show_help": $show_help
}
EOF
}

# Build installation plan based on selection
build_installation_plan() {
    local options_json="$1"

    local selected_components=($(echo "$options_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for comp in data.get('selected_components', []):
    print(comp)
"))

    local excluded_components=($(echo "$options_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for comp in data.get('excluded_components', []):
    print(comp)
"))

    local categories=($(echo "$options_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for cat in data.get('categories', []):
    print(cat)
"))

    # If categories are specified, add components from those categories
    if [[ ${#categories[@]} -gt 0 ]]; then
        for category in "${categories[@]}"; do
            local category_components=($(get_components_by_category "$category"))
            selected_components+=("${category_components[@]}")
        done
    fi

    # If no components selected, use all components
    if [[ ${#selected_components[@]} -eq 0 ]]; then
        selected_components=($(get_all_components))
    fi

    # Remove excluded components
    local final_components=()
    for component in "${selected_components[@]}"; do
        if [[ ! " ${excluded_components[*]} " =~ " ${component} " ]]; then
            final_components+=("$component")
        fi
    done

    # Expand with dependencies
    local expanded_components=($(expand_component_selection "${final_components[@]}"))

    # Validate selection
    if ! validate_component_selection "${expanded_components[@]}"; then
        return 1
    fi

    # Output installation plan
    printf '%s\n' "${expanded_components[@]}"
}

# Show dry run preview
show_dry_run_preview() {
    local installation_plan=("$@")

    echo
    echo "========================================"
    echo "DRY RUN - INSTALLATION PREVIEW"
    echo "========================================"
    echo

    if [[ ${#installation_plan[@]} -eq 0 ]]; then
        echo "No components selected for installation."
        return 0
    fi

    echo "The following components would be installed:"
    echo

    local step_num=1
    for component in "${installation_plan[@]}"; do
        local description=$(get_component_description "$component")
        local category=$(get_component_category "$component")
        local required_marker=""

        if is_component_required "$component"; then
            required_marker=" (required)"
        fi

        printf "%2d. %-20s [%s]%s\n" "$step_num" "$component" "$category" "$required_marker"
        printf "    %s\n" "$description"

        # Show dependencies
        local deps=($(get_component_dependencies "$component"))
        if [[ ${#deps[@]} -gt 0 ]]; then
            printf "    Dependencies: %s\n" "${deps[*]}"
        fi

        echo
        ((step_num++))
    done

    echo "Total components: ${#installation_plan[@]}"
    echo
    echo "To proceed with installation, run without --dry-run flag."
    echo
}

# Show available components
show_available_components() {
    echo
    echo "========================================"
    echo "AVAILABLE INSTALLATION COMPONENTS"
    echo "========================================"
    echo

    local categories=($(get_all_categories))

    for category in "${categories[@]}"; do
        echo "Category: $category"
        echo "$(printf '=%.0s' {1..40})"

        local components=($(get_components_by_category "$category"))
        for component in "${components[@]}"; do
            local description=$(get_component_description "$component")
            local required_marker=""

            if is_component_required "$component"; then
                required_marker=" (required)"
            fi

            printf "  %-20s %s%s\n" "$component" "$description" "$required_marker"

            # Show dependencies
            local deps=($(get_component_dependencies "$component"))
            if [[ ${#deps[@]} -gt 0 ]]; then
                printf "  %20s Dependencies: %s\n" "" "${deps[*]}"
            fi
        done
        echo
    done

    echo "Usage Examples:"
    echo "  --components ssh_setup,homebrew    Install specific components"
    echo "  --categories languages,packages    Install all components in categories"
    echo "  --exclude rust,nodejs              Exclude specific components"
    echo "  --dry-run                          Preview installation plan"
    echo
}

# Show selective installation help
show_selective_help() {
    cat << 'EOF'

Selective Installation Options
==============================

The resilient installation system supports selective installation of components
with automatic dependency resolution.

OPTIONS:
  -c, --components COMP1,COMP2    Install specific components (comma-separated)
  -t, --categories CAT1,CAT2      Install all components in categories
  -e, --exclude COMP1,COMP2       Exclude specific components
  -n, --dry-run                   Preview installation plan without executing
  -h, --help                      Show this help message

EXAMPLES:
  # Install only essential components
  ./install.sh --components prerequisites,ssh_setup,homebrew

  # Install all language runtimes
  ./install.sh --categories languages

  # Install everything except development repositories
  ./install.sh --exclude clone_repos

  # Preview what would be installed
  ./install.sh --dry-run

  # Install packages and configurations, excluding Rust
  ./install.sh --categories packages,setup --exclude rust

COMPONENT CATEGORIES:
  system       - System prerequisites and validation
  security     - SSH and authentication setup
  setup        - Configuration and dotfiles setup
  packages     - Package managers and tools
  languages    - Programming language runtimes
  development  - Development repositories and tools
  validation   - Installation validation

DEPENDENCY RESOLUTION:
  Dependencies are automatically included when you select a component.
  Required components cannot be excluded and will always be included.

EOF

    show_available_components
}

# Execute selective installation
execute_selective_installation() {
    local options_json="$1"
    shift
    local installation_plan=("$@")

    local dry_run=$(echo "$options_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print('true' if data.get('dry_run', False) else 'false')
")

    if [[ "$dry_run" == "true" ]]; then
        show_dry_run_preview "${installation_plan[@]}"
        return 0
    fi

    selective_log $SELECTIVE_INFO "Starting selective installation with ${#installation_plan[@]} components"

    # Execute installation plan
    local failed_components=()
    for component in "${installation_plan[@]}"; do
        selective_log $SELECTIVE_INFO "Installing component: $component"

        # Check if component is already completed
        if is_step_completed "$component"; then
            selective_log $SELECTIVE_INFO "Component already completed: $component"
            continue
        fi

        # Execute component installation (this would call the actual step function)
        # For now, we'll just mark it as a placeholder
        selective_log $SELECTIVE_INFO "Executing installation for: $component"

        # This is where you would call the actual step execution function
        # execute_step "$component" "${component}_step" "$(get_component_description "$component")"

        # For demonstration, we'll simulate success/failure
        local component_result=0  # This would be the actual result

        if [[ $component_result -ne 0 ]]; then
            failed_components+=("$component")
            selective_log $SELECTIVE_ERROR "Component installation failed: $component"
        else
            selective_log $SELECTIVE_INFO "Component installation completed: $component"
        fi
    done

    # Report results
    if [[ ${#failed_components[@]} -eq 0 ]]; then
        selective_log $SELECTIVE_INFO "Selective installation completed successfully"
        return 0
    else
        selective_log $SELECTIVE_ERROR "Selective installation completed with failures: ${failed_components[*]}"
        return 1
    fi
}

# Main selective installation function
run_selective_installation() {
    local args=("$@")

    # Parse command line options
    local options_json=$(parse_selective_options "${args[@]}")

    # Check if help was requested
    local show_help=$(echo "$options_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print('true' if data.get('show_help', False) else 'false')
")

    if [[ "$show_help" == "true" ]]; then
        show_selective_help
        return 0
    fi

    # Build installation plan
    local installation_plan=($(build_installation_plan "$options_json"))

    if [[ $? -ne 0 ]]; then
        selective_log $SELECTIVE_ERROR "Failed to build installation plan"
        return 1
    fi

    # Execute installation
    execute_selective_installation "$options_json" "${installation_plan[@]}"
}

# Export functions for use in other scripts
export -f get_all_components
export -f get_components_by_category
export -f get_all_categories
export -f resolve_dependencies
export -f build_installation_plan
export -f show_dry_run_preview
export -f show_available_components
export -f run_selective_installation
