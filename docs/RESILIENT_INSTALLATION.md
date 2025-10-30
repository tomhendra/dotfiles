# Resilient Installation System

A comprehensive, fault-tolerant installation framework for macOS development environment setup with advanced error handling, recovery mechanisms, and progress tracking.

## Overview

The Resilient Installation System transforms the traditional dotfiles installation process into a robust, modular framework that can handle failures gracefully, provide detailed feedback, and resume from interruption points.

### Key Features

- **🔄 Resumable Installation**: Automatically resumes from the last successful step after interruptions
- **🛡️ Error Recovery**: Intelligent error categorization with automated retry strategies
- **📊 Progress Tracking**: Real-time progress indicators with time estimation
- **🎯 Selective Installation**: Install only specific components or skip unwanted ones
- **🔍 Comprehensive Validation**: Standalone validation with detailed reporting
- **⚙️ Interactive Configuration**: Smart conflict resolution for existing configurations
- **📋 Detailed Logging**: Comprehensive logging with multiple verbosity levels
- **🔄 Rollback Support**: Automatic rollback for critical failures

## Quick Start

### Basic Installation

```bash
# Full automated installation
./install_enhanced.sh --non-interactive

# Interactive installation with prompts
./install_enhanced.sh --interactive

# Preview what would be installed
./install_enhanced.sh --dry-run
```

### Selective Installation

```bash
# Install only specific components
./install_enhanced.sh --components homebrew,nodejs,configurations

# Skip specific components
./install_enhanced.sh --skip rust,global_packages

# Resume interrupted installation
./install_enhanced.sh --resume
```

### Validation and Troubleshooting

```bash
# Validate current installation
./validate_installation.sh

# Validate specific category
./validate_installation.sh --category tools

# Show detailed validation report
./validate_installation.sh --verbose
```

## Installation Components

### Core Components

| Component          | Description                                      | Dependencies   |
| ------------------ | ------------------------------------------------ | -------------- |
| `prerequisites`    | System requirements and Xcode Command Line Tools | None           |
| `ssh_setup`        | SSH key generation and configuration             | prerequisites  |
| `github_auth`      | GitHub authentication setup                      | ssh_setup      |
| `clone_dotfiles`   | Clone dotfiles repository                        | github_auth    |
| `homebrew`         | Homebrew package manager and packages            | prerequisites  |
| `rust`             | Rust programming language toolchain              | homebrew       |
| `nodejs`           | Node.js runtime and package managers             | homebrew       |
| `global_packages`  | Global npm packages installation                 | nodejs         |
| `configurations`   | Configuration files deployment                   | clone_dotfiles |
| `symlinks`         | Symbolic links creation                          | configurations |
| `final_validation` | Comprehensive system validation                  | All components |

### Optional Components

- `clone_repos` - Development repositories cloning
- Custom components can be added by creating step functions

## Command Line Options

### Installation Options

```bash
-h, --help              Show help message
-v, --verbose           Enable verbose output and detailed logging
-q, --quiet             Suppress non-essential output
-f, --force             Force installation, overwrite existing files
-n, --dry-run           Preview installation without making changes
-i, --interactive       Force interactive mode (prompt for confirmations)
-y, --non-interactive   Force non-interactive mode (use defaults)
```

### State Management

```bash
-r, --resume            Resume previous installation from last checkpoint
-R, --reset             Reset installation state and start fresh
--backup-configs        Create backup of existing configurations
```

### Component Selection

```bash
-c, --components LIST   Install only specified components (comma-separated)
-s, --skip LIST         Skip specified components (comma-separated)
--validate-only         Only run validation, don't install anything
```

### Progress and Logging

```bash
--show-progress         Show real-time progress updates
--verbose               Enable detailed logging
--quiet                 Minimal output mode
```

## Architecture

### Modular Design

The system is built with a modular architecture where each component is independent and can be developed, tested, and maintained separately.

```
resilient-installation/
├── install_enhanced.sh          # Main installation script
├── validate_installation.sh     # Standalone validation
├── lib/                        # Core library modules
│   ├── state.sh               # State management and persistence
│   ├── executor.sh            # Step execution with error handling
│   ├── progress.sh            # Progress tracking and display
│   ├── interactive.sh         # User interaction and prompts
│   ├── config_manager.sh      # Configuration file management
│   ├── error_handler.sh       # Comprehensive error reporting
│   ├── validator.sh           # System validation engine
│   ├── recovery.sh            # Rollback and recovery mechanisms
│   └── selective.sh           # Component selection logic
├── steps/                     # Individual installation steps
│   ├── prerequisites.sh
│   ├── homebrew.sh
│   ├── nodejs.sh
│   └── ...
└── tests/                     # Test suite
    ├── test_*.sh
    └── integration/
```

### State Management

The system maintains installation state in JSON format, tracking:

- Step completion status
- Error information and retry attempts
- Timing and performance data
- Configuration backups
- User preferences

```json
{
  "installation_id": "uuid",
  "started_at": "2024-01-01T12:00:00Z",
  "steps": {
    "homebrew": {
      "status": "completed",
      "completed_at": "2024-01-01T12:05:00Z",
      "duration": 300,
      "attempts": 1
    }
  }
}
```

## Error Handling

### Error Categories

The system categorizes errors for appropriate handling:

- **Network**: Connectivity issues, download failures
- **Permission**: File system access, privilege requirements
- **Dependency**: Missing prerequisites, tool availability
- **Configuration**: Syntax errors, invalid settings
- **System**: Resource constraints, compatibility issues
- **User**: Authentication, input validation
- **Critical**: System corruption, security violations
- **Recoverable**: Temporary issues, retry candidates

### Error Responses

Each error category has specific response strategies:

```bash
# Network errors: Retry with exponential backoff
# Permission errors: Prompt for elevation or manual fix
# Dependency errors: Install missing components
# Critical errors: Immediate rollback and exit
```

### Remediation Guidance

The system provides specific remediation steps for common issues:

```
❌ Error: Command not found: brew
🔧 Suggested Solutions:
   1. Install Homebrew using the official installer
   2. Check if Homebrew is in your PATH
   3. Restart your terminal session
```

## Configuration Management

### Conflict Resolution

When existing configurations are detected, the system offers multiple resolution strategies:

- **Replace**: Backup existing and install new (with confirmation)
- **Merge**: Intelligently combine configurations
- **Skip**: Keep existing configuration unchanged
- **Diff**: Show differences before deciding
- **Manual**: Pause for manual resolution

### Intelligent Merging

The system supports intelligent merging for different file types:

- **Shell files**: Preserve custom settings, append new configurations
- **Git config**: Merge sections and update individual settings
- **JSON files**: Deep merge objects and arrays
- **Generic files**: Concatenate with clear separation

## Validation System

### Comprehensive Checks

The validation system performs multi-level checks:

1. **System Requirements**: macOS version, disk space, architecture
2. **Tool Installation**: Verify all required tools are installed and functional
3. **Configuration Integrity**: Syntax validation, file permissions
4. **Symlink Validation**: Ensure all links point to valid targets
5. **Functional Testing**: Test tool integration and workflows

### Validation Categories

```bash
# System validation
./validate_installation.sh --category system

# Tool functionality
./validate_installation.sh --category tools

# Configuration files
./validate_installation.sh --category configurations

# Symlink integrity
./validate_installation.sh --category symlinks
```

### Validation Reports

Detailed JSON reports are generated with:

- Test results by category
- Pass/fail statistics
- Remediation suggestions
- System information snapshot

## Usage Examples

### Common Scenarios

#### Fresh macOS Setup

```bash
# Complete automated setup
./install_enhanced.sh --non-interactive --backup-configs

# With progress monitoring
./install_enhanced.sh --show-progress --verbose
```

#### Partial Updates

```bash
# Update only development tools
./install_enhanced.sh --components homebrew,nodejs,rust

# Update configurations only
./install_enhanced.sh --components configurations,symlinks --force
```

#### Troubleshooting

```bash
# Validate current setup
./validate_installation.sh --verbose

# Reset and retry failed installation
./install_enhanced.sh --reset --resume

# Force reinstall with detailed logging
./install_enhanced.sh --force --verbose
```

#### Development and Testing

```bash
# Preview changes without installation
./install_enhanced.sh --dry-run --verbose

# Test specific components
./install_enhanced.sh --components prerequisites,homebrew --dry-run
```

### Advanced Usage

#### Custom Component Installation

```bash
# Create custom step function
step_custom_tool() {
    log_operation "Installing custom tool" "info"
    # Installation logic here
    return 0
}

# Add to installation plan
CUSTOM_STEPS=("${DEFAULT_INSTALLATION_STEPS[@]}" "custom_tool")
./install_enhanced.sh --components custom_tool
```

#### Automated CI/CD Integration

```bash
# Non-interactive installation for CI
./install_enhanced.sh \
    --non-interactive \
    --components prerequisites,homebrew,nodejs \
    --quiet

# Validation in CI pipeline
./validate_installation.sh --report-only --quiet
if [ $? -eq 0 ]; then
    echo "✅ Environment validation passed"
else
    echo "❌ Environment validation failed"
    exit 1
fi
```

## Troubleshooting Guide

### Common Issues

#### Installation Hangs or Fails

1. **Check network connectivity**

   ```bash
   # Test basic connectivity
   curl -I https://github.com

   # Resume with network retry
   ./install_enhanced.sh --resume --verbose
   ```

2. **Permission issues**

   ```bash
   # Check file permissions
   ls -la ~/.dotfiles

   # Fix permissions
   chmod -R 755 ~/.dotfiles
   ```

3. **Disk space issues**

   ```bash
   # Check available space
   df -h

   # Clean up if needed
   brew cleanup
   npm cache clean --force
   ```

#### Configuration Conflicts

1. **View differences**

   ```bash
   # Show what would change
   ./install_enhanced.sh --dry-run --verbose
   ```

2. **Backup existing configs**

   ```bash
   # Create backup before installation
   ./install_enhanced.sh --backup-configs
   ```

3. **Selective updates**
   ```bash
   # Update only specific configs
   ./install_enhanced.sh --components configurations --interactive
   ```

#### Validation Failures

1. **Detailed validation report**

   ```bash
   ./validate_installation.sh --verbose
   ```

2. **Category-specific validation**

   ```bash
   ./validate_installation.sh --category tools
   ```

3. **Fix and re-validate**
   ```bash
   # Fix issues manually, then re-validate
   ./validate_installation.sh
   ```

### Recovery Procedures

#### Reset Installation State

```bash
# Complete reset
./install_enhanced.sh --reset --force

# Reset specific component
rm -f ~/.dotfiles_state/state.json
./install_enhanced.sh --components homebrew
```

#### Restore from Backup

```bash
# List available backups
ls -la ~/.dotfiles_backup_*

# Restore specific backup
./restore_backup.sh ~/.dotfiles_backup_20240101_120000
```

#### Manual Recovery

```bash
# Check installation logs
tail -f ~/.dotfiles_state/installation.log

# Check error details
cat ~/.dotfiles_state/errors.log

# Manual step execution
source lib/executor.sh
execute_step "homebrew" "step_homebrew"
```

## Performance Optimization

### Parallel Execution

Some steps can be executed in parallel for faster installation:

```bash
# Enable parallel execution (experimental)
export PARALLEL_EXECUTION=true
./install_enhanced.sh
```

### Caching

The system caches downloaded files and build artifacts:

```bash
# Clear caches if needed
rm -rf ~/.dotfiles_cache
```

### Network Optimization

```bash
# Use faster mirrors
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles

# Increase timeout for slow connections
export NETWORK_TIMEOUT=60
```

## Contributing

### Adding New Components

1. Create step function in `steps/component_name.sh`
2. Add validation logic in `validate_installation.sh`
3. Update component list in `install_enhanced.sh`
4. Add tests in `tests/test_component_name.sh`

### Testing

```bash
# Run unit tests
./tests/run_tests.sh

# Run integration tests
./tests/run_integration_tests.sh

# Test specific component
./tests/test_homebrew.sh
```

### Documentation

- Update this README for new features
- Add inline documentation for complex functions
- Include usage examples for new options

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:

1. Check the troubleshooting guide above
2. Review the validation report for specific errors
3. Check the installation logs for detailed information
4. Open an issue on GitHub with logs and system information

---

**Note**: This system is designed for macOS environments. Some features may not work on other operating systems.
