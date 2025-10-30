#!/usr/bin/env bash

# Comprehensive Error Reporting for Resilient Installation
# Provides user-friendly error messages, technical logging, and remediation guidance

# Source dependencies
if [ -f "$(dirname "${BASH_SOURCE[0]}")/progress.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/progress.sh"
elif [ -f "lib/progress.sh" ]; then
    source "lib/progress.sh"
fi

# Error categories and their properties
declare -A ERROR_CATEGORIES=(
    ["network"]="Network connectivity or download issues"
    ["permission"]="File system permissions or access rights"
    ["dependency"]="Missing dependencies or prerequisites"
    ["configuration"]="Configuration file or setting issues"
    ["system"]="System compatibility or resource issues"
    ["user"]="User input or authentication issues"
    ["critical"]="Critical system errors requiring immediate attention"
    ["recoverable"]="Temporary issues that can be retried"
)

# Error severity levels
declare -A ERROR_SEVERITY=(
    ["low"]="Minor issue, installation can continue"
    ["medium"]="Moderate issue, may affect functionality"
    ["high"]="Serious issue, step will fail but installation can continue"
    ["critical"]="Critical issue, installation must stop"
)

# Common error patterns and their remediation
declare -A ERROR_REMEDIATION=(
    ["command_not_found"]="Install the missing command or check PATH"
    ["permission_denied"]="Check file permissions or run with appropriate privileges"
    ["network_timeout"]="Check internet connection and retry"
    ["disk_full"]="Free up disk space and retry"
    ["invalid_syntax"]="Check configuration file syntax"
    ["authentication_failed"]="Verify credentials and authentication setup"
    ["dependency_missing"]="Install required dependencies first"
    ["version_incompatible"]="Update to compatible version"
)

# Initialize error tracking
init_error_tracking() {
    export ERROR_LOG_FILE="${ERROR_LOG_FILE:-$STATE_DIR/errors.log}"
    export ERROR_SUMMARY_FILE="${ERROR_SUMMARY_FILE:-$STATE_DIR/error_summary.json}"

    # Create error log if it doesn't exist
    if [[ ! -f "$ERROR_LOG_FILE" ]]; then
        touch "$ERROR_LOG_FILE"
    fi

    # Initialize error summary
    if [[ ! -f "$ERROR_SUMMARY_FILE" ]]; then
        echo '{"errors": [], "summary": {"total": 0, "by_category": {}, "by_severity": {}}}' > "$ERROR_SUMMARY_FILE"
    fi
}

# Categorize error based on message and context
categorize_error() {
    local error_message="$1"
    local exit_code="${2:-1}"
    local command="${3:-}"

    # Convert to lowercase for pattern matching
    local msg_lower="${error_message,,}"

    # Network-related errors
    if [[ "$msg_lower" =~ (network|connection|timeout|dns|curl|wget|download|unreachable) ]]; then
        echo "network"
        return
    fi

    # Permission errors
    if [[ "$msg_lower" =~ (permission|denied|access|forbidden|unauthorized|sudo) ]] || [[ $exit_code -eq 126 ]]; then
        echo "permission"
        return
    fi

    # Dependency errors
    if [[ "$msg_lower" =~ (command.*not.*found|no.*such.*file|missing|dependency|require) ]] || [[ $exit_code -eq 127 ]]; then
        echo "dependency"
        return
    fi

    # Configuration errors
    if [[ "$msg_lower" =~ (config|syntax|invalid|malformed|parse) ]]; then
        echo "configuration"
        return
    fi

    # System errors
    if [[ "$msg_lower" =~ (disk.*full|no.*space|memory|system|kernel|hardware) ]]; then
        echo "system"
        return
    fi

    # User/authentication errors
    if [[ "$msg_lower" =~ (auth|login|credential|password|key|token) ]]; then
        echo "user"
        return
    fi

    # Critical system errors
    if [[ $exit_code -ge 128 ]] || [[ "$msg_lower" =~ (critical|fatal|panic|abort|segmentation) ]]; then
        echo "critical"
        return
    fi

    # Default to recoverable for unknown errors
    echo "recoverable"
}

# Determine error severity
determine_severity() {
    local category="$1"
    local exit_code="${2:-1}"
    local step_critical="${3:-false}"

    case "$category" in
        "critical")
            echo "critical"
            ;;
        "system"|"dependency")
            if [[ "$step_critical" == "true" ]]; then
                echo "critical"
            else
                echo "high"
            fi
            ;;
        "permission"|"configuration")
            echo "high"
            ;;
        "network"|"user")
            echo "medium"
            ;;
        "recoverable")
            echo "low"
            ;;
        *)
            echo "medium"
            ;;
    esac
}

# Generate remediation suggestions
generate_remediation() {
    local category="$1"
    local error_message="$2"
    local command="${3:-}"

    local suggestions=()
    local msg_lower="${error_message,,}"

    case "$category" in
        "network")
            suggestions+=(
                "Check your internet connection"
                "Verify DNS settings"
                "Try again in a few minutes"
                "Check if you're behind a firewall or proxy"
            )
            if [[ "$msg_lower" =~ curl|wget ]]; then
                suggestions+=("Try using a different download method")
            fi
            ;;
        "permission")
            suggestions+=(
                "Check file and directory permissions"
                "Ensure you have write access to the target location"
            )
            if [[ "$msg_lower" =~ sudo ]]; then
                suggestions+=("Run the command with appropriate privileges")
            else
                suggestions+=("Try running with 'sudo' if appropriate")
            fi
            ;;
        "dependency")
            suggestions+=(
                "Install the missing dependency"
                "Check if the required tool is in your PATH"
                "Update your package manager"
            )
            if [[ -n "$command" ]]; then
                suggestions+=("Install '$command' using your package manager")
            fi
            ;;
        "configuration")
            suggestions+=(
                "Check configuration file syntax"
                "Verify configuration values are correct"
                "Compare with example configurations"
                "Reset to default configuration if needed"
            )
            ;;
        "system")
            if [[ "$msg_lower" =~ space|disk ]]; then
                suggestions+=(
                    "Free up disk space"
                    "Clean temporary files"
                    "Check available disk space with 'df -h'"
                )
            else
                suggestions+=(
                    "Check system requirements"
                    "Verify macOS version compatibility"
                    "Check system resources (memory, CPU)"
                )
            fi
            ;;
        "user")
            suggestions+=(
                "Verify your credentials"
                "Check authentication setup"
                "Ensure SSH keys are properly configured"
                "Re-authenticate if necessary"
            )
            ;;
        *)
            suggestions+=(
                "Check the error message for specific details"
                "Try running the command manually"
                "Consult the documentation for the failing component"
            )
            ;;
    esac

    printf "%s\n" "${suggestions[@]}"
}

# Record error with full context
record_error() {
    local step_id="$1"
    local error_message="$2"
    local exit_code="${3:-1}"
    local command="${4:-}"
    local step_critical="${5:-false}"

    init_error_tracking

    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    local category=$(categorize_error "$error_message" "$exit_code" "$command")
    local severity=$(determine_severity "$category" "$exit_code" "$step_critical")

    # Create error record
    local error_record=$(cat <<EOF
{
    "timestamp": "$timestamp",
    "step_id": "$step_id",
    "category": "$category",
    "severity": "$severity",
    "exit_code": $exit_code,
    "message": "$error_message",
    "command": "$command",
    "step_critical": $step_critical
}
EOF
)

    # Log to detailed error log
    {
        echo "[$timestamp] ERROR in $step_id (exit: $exit_code, category: $category, severity: $severity)"
        echo "Command: $command"
        echo "Message: $error_message"
        echo "---"
    } >> "$ERROR_LOG_FILE"

    # Update error summary
    local temp_summary=$(mktemp)
    if [[ -f "$ERROR_SUMMARY_FILE" ]]; then
        python3 -c "
import json
import sys

# Read existing summary
try:
    with open('$ERROR_SUMMARY_FILE', 'r') as f:
        data = json.load(f)
except:
    data = {'errors': [], 'summary': {'total': 0, 'by_category': {}, 'by_severity': {}}}

# Add new error
error_record = $error_record
data['errors'].append(error_record)

# Update summary
data['summary']['total'] = len(data['errors'])

# Count by category
data['summary']['by_category'] = {}
data['summary']['by_severity'] = {}

for error in data['errors']:
    cat = error['category']
    sev = error['severity']

    data['summary']['by_category'][cat] = data['summary']['by_category'].get(cat, 0) + 1
    data['summary']['by_severity'][sev] = data['summary']['by_severity'].get(sev, 0) + 1

# Write updated summary
with open('$temp_summary', 'w') as f:
    json.dump(data, f, indent=2)
" && mv "$temp_summary" "$ERROR_SUMMARY_FILE"
    fi

    # Return error info for immediate use
    echo "$category|$severity|$error_message"
}

# Display user-friendly error message
show_error() {
    local step_id="$1"
    local error_message="$2"
    local exit_code="${3:-1}"
    local command="${4:-}"
    local step_critical="${5:-false}"

    # Record the error
    local error_info=$(record_error "$step_id" "$error_message" "$exit_code" "$command" "$step_critical")
    IFS='|' read -r category severity message <<< "$error_info"

    echo
    print_color "$COLOR_BOLD$COLOR_RED" "❌ Error in Step: $step_id"
    echo

    # Error header with category and severity
    printf "   Category: "
    case "$category" in
        "critical") print_color "$COLOR_BRIGHT_RED" "🚨 $category" ;;
        "network") print_color "$COLOR_BRIGHT_YELLOW" "🌐 $category" ;;
        "permission") print_color "$COLOR_BRIGHT_YELLOW" "🔒 $category" ;;
        "dependency") print_color "$COLOR_BRIGHT_BLUE" "📦 $category" ;;
        *) print_color "$COLOR_YELLOW" "⚠️  $category" ;;
    esac
    echo

    printf "   Severity: "
    case "$severity" in
        "critical") print_color "$COLOR_BRIGHT_RED" "🔴 CRITICAL" ;;
        "high") print_color "$COLOR_RED" "🟠 HIGH" ;;
        "medium") print_color "$COLOR_YELLOW" "🟡 MEDIUM" ;;
        "low") print_color "$COLOR_GREEN" "🟢 LOW" ;;
    esac
    echo

    # Error message
    echo
    print_color "$COLOR_BOLD" "📋 Error Details:"
    echo
    print_color "$COLOR_RED" "   $error_message"
    echo

    if [[ -n "$command" ]]; then
        print_color "$COLOR_GRAY" "   Failed command: $command"
        echo
    fi

    if [[ $exit_code -ne 0 ]]; then
        print_color "$COLOR_GRAY" "   Exit code: $exit_code"
        echo
    fi

    # Remediation suggestions
    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "🔧 Suggested Solutions:"
    echo

    local remediation_suggestions
    remediation_suggestions=$(generate_remediation "$category" "$error_message" "$command")

    local counter=1
    while IFS= read -r suggestion; do
        if [[ -n "$suggestion" ]]; then
            print_color "$COLOR_BLUE" "   $counter. $suggestion"
            echo
            ((counter++))
        fi
    done <<< "$remediation_suggestions"

    # Additional context based on severity
    case "$severity" in
        "critical")
            echo
            print_color "$COLOR_BOLD$COLOR_RED" "⚠️  CRITICAL ERROR: Installation cannot continue safely."
            print_color "$COLOR_RED" "   Please resolve this issue before proceeding."
            ;;
        "high")
            echo
            print_color "$COLOR_BOLD$COLOR_YELLOW" "⚠️  This error may prevent proper functionality."
            print_color "$COLOR_YELLOW" "   Consider resolving before continuing."
            ;;
    esac

    echo
}

# Show error summary report
show_error_summary() {
    init_error_tracking

    if [[ ! -f "$ERROR_SUMMARY_FILE" ]]; then
        print_color "$COLOR_GREEN" "✅ No errors recorded"
        return 0
    fi

    echo
    print_color "$COLOR_BOLD$COLOR_BLUE" "📊 Error Summary Report"
    echo

    local summary_info=$(python3 -c "
import json
try:
    with open('$ERROR_SUMMARY_FILE', 'r') as f:
        data = json.load(f)

    summary = data.get('summary', {})
    total = summary.get('total', 0)

    if total == 0:
        print('No errors recorded')
        exit(0)

    print(f'Total errors: {total}')
    print()

    # By severity
    by_severity = summary.get('by_severity', {})
    if by_severity:
        print('By Severity:')
        for severity in ['critical', 'high', 'medium', 'low']:
            count = by_severity.get(severity, 0)
            if count > 0:
                print(f'  {severity}: {count}')
        print()

    # By category
    by_category = summary.get('by_category', {})
    if by_category:
        print('By Category:')
        for category, count in by_category.items():
            print(f'  {category}: {count}')
        print()

    # Recent errors
    errors = data.get('errors', [])
    if errors:
        print('Recent Errors:')
        for error in errors[-5:]:  # Last 5 errors
            step = error.get('step_id', 'unknown')
            category = error.get('category', 'unknown')
            severity = error.get('severity', 'unknown')
            message = error.get('message', '')[:60] + '...' if len(error.get('message', '')) > 60 else error.get('message', '')
            print(f'  [{step}] {category}/{severity}: {message}')

except Exception as e:
    print(f'Error reading summary: {e}')
")

    if [[ "$summary_info" == "No errors recorded" ]]; then
        print_color "$COLOR_GREEN" "✅ No errors recorded"
        return 0
    fi

    echo "$summary_info"
    echo

    # Show log file location
    print_color "$COLOR_GRAY" "📁 Detailed error log: $ERROR_LOG_FILE"
    print_color "$COLOR_GRAY" "📁 Error summary: $ERROR_SUMMARY_FILE"
    echo
}

# Clear error logs
clear_error_logs() {
    init_error_tracking

    local confirm=$(prompt_yes_no "Clear all error logs?" "n")
    if [[ "$confirm" == "y" ]]; then
        > "$ERROR_LOG_FILE"
        echo '{"errors": [], "summary": {"total": 0, "by_category": {}, "by_severity": {}}}' > "$ERROR_SUMMARY_FILE"
        print_color "$COLOR_GREEN" "✅ Error logs cleared"
    else
        print_color "$COLOR_YELLOW" "❌ Clear cancelled"
    fi
}

# Get error count by severity
get_error_count() {
    local severity="${1:-}"

    init_error_tracking

    if [[ ! -f "$ERROR_SUMMARY_FILE" ]]; then
        echo "0"
        return
    fi

    python3 -c "
import json
try:
    with open('$ERROR_SUMMARY_FILE', 'r') as f:
        data = json.load(f)

    if '$severity':
        count = data.get('summary', {}).get('by_severity', {}).get('$severity', 0)
    else:
        count = data.get('summary', {}).get('total', 0)

    print(count)
except:
    print(0)
"
}

# Check if there are critical errors
has_critical_errors() {
    local critical_count=$(get_error_count "critical")
    [[ $critical_count -gt 0 ]]
}

# Export functions for use in other scripts
export -f init_error_tracking
export -f record_error
export -f show_error
export -f show_error_summary
export -f clear_error_logs
export -f get_error_count
export -f has_critical_errors
export -f categorize_error
export -f determine_severity
export -f generate_remediation
