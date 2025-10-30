# Usage Examples

This document provides practical examples of using the Resilient Installation System in various scenarios.

## Basic Usage

### 1. First-Time Setup (Fresh macOS)

Complete automated setup for a new Mac:

```bash
# Download and run the installation
curl -fsSL https://raw.githubusercontent.com/tomhendra/dotfiles/main/install_enhanced.sh | bash

# Or clone and run locally
git clone https://github.com/tomhendra/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install_enhanced.sh --non-interactive --backup-configs
```

### 2. Interactive Setup with Confirmations

For users who want control over the installation process:

```bash
# Interactive mode with prompts for each decision
./install_enhanced.sh --interactive --verbose

# Preview what will be installed first
./install_enhanced.sh --dry-run --verbose
# Then run the actual installation
./install_enhanced.sh --interactive
```

### 3. Quick Validation Check

Verify your current development environment:

```bash
# Quick validation
./validate_installation.sh

# Detailed validation with remediation suggestions
./validate_installation.sh --verbose

# Check specific category
./validate_installation.sh --category tools --verbose
```

## Selective Installation

### 4. Install Only Development Tools

Skip system configuration and focus on tools:

```bash
# Install only Homebrew, Node.js, and Rust
./install_enhanced.sh --components homebrew,nodejs,rust --non-interactive

# Skip global packages if not needed
./install_enhanced.sh --components homebrew,nodejs,rust --skip global_packages
```

### 5. Configuration Files Only

Update just the configuration files without reinstalling tools:

```bash
# Update configurations with interactive conflict resolution
./install_enhanced.sh --components configurations,symlinks --interactive

# Force update configurations (backup existing)
./install_enhanced.sh --components configurations,symlinks --force --backup-configs
```

### 6. Minimal Installation for CI/CD

Lightweight installation for automated environments:

```bash
# Minimal setup for CI environments
./install_enhanced.sh \
    --components prerequisites,homebrew,nodejs \
    --non-interactive \
    --quiet

# Validate the minimal setup
./validate_installation.sh --category tools --quiet
```

## Recovery and Maintenance

### 7. Resume Interrupted Installation

When installation is interrupted by network issues or system restart:

```bash
# Resume from the last successful step
./install_enhanced.sh --resume --verbose

# If resume fails, reset and start over
./install_enhanced.sh --reset --force --verbose
```

### 8. Fix Broken Installation

When some components are not working correctly:

```bash
# Validate to identify issues
./validate_installation.sh --verbose

# Fix specific components
./install_enhanced.sh --components homebrew,nodejs --force

# Complete reset and reinstall
./install_enhanced.sh --reset --force --backup-configs
```

### 9. Update Existing Installation

Keep your development environment up to date:

```bash
# Update dotfiles repository
cd ~/.dotfiles
git pull origin main

# Update configurations
./install_enhanced.sh --components configurations,symlinks --force

# Update and validate everything
./install_enhanced.sh --force --verbose
./validate_installation.sh
```

## Advanced Scenarios

### 10. Corporate Environment Setup

Installation behind corporate firewall with proxy:

```bash
# Set proxy environment variables
export https_proxy=http://proxy.company.com:8080
export http_proxy=http://proxy.company.com:8080

# Configure git proxy
git config --global http.proxy http://proxy.company.com:8080

# Run installation with increased timeouts
export NETWORK_TIMEOUT=120
./install_enhanced.sh --non-interactive --verbose
```

### 11. Development Machine Migration

Moving from an old Mac to a new one:

```bash
# On old Mac: Create backup
./install_enhanced.sh --backup-configs
tar -czf dotfiles_backup.tar.gz ~/.dotfiles_backup_*

# On new Mac: Restore and install
scp old-mac:dotfiles_backup.tar.gz .
tar -xzf dotfiles_backup.tar.gz
./install_enhanced.sh --non-interactive
```

### 12. Multiple User Setup

Setting up multiple user accounts on the same Mac:

```bash
# User 1: Full installation
sudo -u user1 ./install_enhanced.sh --non-interactive

# User 2: Shared Homebrew, individual configs
sudo -u user2 ./install_advanced.sh --skip homebrew --components configurations,symlinks
```

## Testing and Development

### 13. Testing Configuration Changes

Before applying changes to your main environment:

```bash
# Test in dry-run mode
./install_enhanced.sh --dry-run --verbose --components configurations

# Test specific component
./install_enhanced.sh --components symlinks --dry-run

# Apply changes with backup
./install_enhanced.sh --components configurations --backup-configs --force
```

### 14. Component Development

When developing new installation components:

```bash
# Test new component in isolation
./install_enhanced.sh --components new_component --dry-run --verbose

# Test with existing components
./install_enhanced.sh --components homebrew,new_component --dry-run

# Validate new component
./validate_installation.sh --category functionality
```

### 15. Performance Testing

Measure installation performance and optimize:

```bash
# Time the installation
time ./install_enhanced.sh --non-interactive --quiet

# Enable detailed timing
export LOG_LEVEL=4
./install_enhanced.sh --verbose

# Test parallel execution (if supported)
export PARALLEL_EXECUTION=true
./install_enhanced.sh --components homebrew,nodejs,rust
```

## Troubleshooting Scenarios

### 16. Network Issues

When dealing with unreliable internet connection:

```bash
# Increase retry attempts and timeouts
export MAX_NETWORK_RETRIES=5
export NETWORK_TIMEOUT=60

# Resume installation after network recovery
./install_enhanced.sh --resume --verbose

# Use cached downloads if available
export USE_CACHE=true
./install_enhanced.sh --resume
```

### 17. Permission Problems

Resolving file system permission issues:

```bash
# Fix common permission issues
sudo chown -R $(whoami) ~/.dotfiles
chmod -R 755 ~/.dotfiles

# Run installation with verbose logging
./install_enhanced.sh --verbose --components configurations

# Check validation for permission issues
./validate_installation.sh --category permissions
```

### 18. Debugging Failed Steps

When specific steps consistently fail:

```bash
# Enable debug logging
export LOG_LEVEL=4
./install_enhanced.sh --components failing_step --verbose

# Check error logs
cat ~/.dotfiles_state/errors.log | grep failing_step

# Manual step execution for debugging
source lib/executor.sh
execute_step "failing_step" "step_failing_step"
```

## Integration Examples

### 19. Ansible Integration

Using the installation system with Ansible:

```yaml
# ansible-playbook.yml
- name: Setup development environment
  hosts: localhost
  tasks:
    - name: Clone dotfiles
      git:
        repo: https://github.com/tomhendra/dotfiles.git
        dest: ~/.dotfiles

    - name: Run installation
      shell: |
        cd ~/.dotfiles
        ./install_enhanced.sh --non-interactive --components {{ components | default('all') }}
      register: install_result

    - name: Validate installation
      shell: ~/.dotfiles/validate_installation.sh --quiet
      register: validation_result
```

### 20. Docker Development Environment

Creating a containerized development environment:

```dockerfile
# Dockerfile
FROM ubuntu:22.04

# Install prerequisites
RUN apt-get update && apt-get install -y curl git

# Copy dotfiles
COPY . /dotfiles
WORKDIR /dotfiles

# Run minimal installation
RUN ./install_enhanced.sh \
    --components prerequisites,homebrew,nodejs \
    --non-interactive \
    --quiet

# Validate installation
RUN ./validate_installation.sh --category tools
```

### 21. GitHub Actions CI/CD

Automated testing of the installation system:

```yaml
# .github/workflows/test-installation.yml
name: Test Installation

on: [push, pull_request]

jobs:
  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Test dry run
        run: ./install_enhanced.sh --dry-run --verbose

      - name: Test minimal installation
        run: ./install_enhanced.sh --components prerequisites,homebrew --non-interactive

      - name: Validate installation
        run: ./validate_installation.sh --category system

      - name: Test resume functionality
        run: |
          # Simulate interruption
          timeout 30 ./install_enhanced.sh --components homebrew,nodejs || true
          # Resume installation
          ./install_enhanced.sh --resume --non-interactive
```

## Customization Examples

### 22. Custom Component Creation

Adding your own installation components:

```bash
# Create custom step function
step_custom_tools() {
    log_operation "Installing custom development tools" "info"

    # Install custom tools
    brew install your-custom-tool
    npm install -g your-custom-package

    # Validate installation
    if command -v your-custom-tool >/dev/null 2>&1; then
        log_operation "Custom tools installed successfully" "success"
        return 0
    else
        show_error "custom_tools" "Failed to install custom tools" 1
        return 1
    fi
}

# Add to installation plan
CUSTOM_STEPS=("${DEFAULT_INSTALLATION_STEPS[@]}" "custom_tools")
./install_enhanced.sh --components custom_tools
```

### 23. Environment-Specific Configuration

Different configurations for different environments:

```bash
# Development environment
export ENVIRONMENT=development
./install_enhanced.sh --components configurations --interactive

# Production environment (minimal)
export ENVIRONMENT=production
./install_enhanced.sh --components prerequisites,homebrew,nodejs --non-interactive

# Testing environment
export ENVIRONMENT=testing
./install_enhanced.sh --dry-run --verbose
```

### 24. Conditional Installation

Installing components based on system conditions:

```bash
# Check system architecture and install accordingly
if [[ $(uname -m) == "arm64" ]]; then
    # Apple Silicon specific components
    ./install_enhanced.sh --components homebrew,nodejs,rust
else
    # Intel specific components
    ./install_enhanced.sh --components homebrew,nodejs --skip rust
fi

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion | cut -d. -f1)
if [[ $MACOS_VERSION -ge 12 ]]; then
    ./install_enhanced.sh --components all
else
    ./install_enhanced.sh --components prerequisites,homebrew,nodejs
fi
```

## Monitoring and Reporting

### 25. Installation Monitoring

Monitor installation progress and generate reports:

```bash
# Monitor installation in real-time
./install_enhanced.sh --show-progress --verbose &
INSTALL_PID=$!

# Monitor progress in another terminal
watch -n 2 "tail -5 ~/.dotfiles_state/installation.log"

# Generate report after completion
wait $INSTALL_PID
./validate_installation.sh --verbose > installation_report.txt
```

### 26. Automated Reporting

Generate automated reports for system administrators:

```bash
#!/bin/bash
# automated_report.sh

# Run validation
./validate_installation.sh --verbose > /tmp/validation.txt

# Extract key metrics
TOTAL_TESTS=$(grep "Total tests:" /tmp/validation.txt | awk '{print $3}')
PASSED_TESTS=$(grep "Passed:" /tmp/validation.txt | awk '{print $2}')
FAILED_TESTS=$(grep "Failed:" /tmp/validation.txt | awk '{print $2}')

# Send report
echo "System Validation Report
Total Tests: $TOTAL_TESTS
Passed: $PASSED_TESTS
Failed: $FAILED_TESTS
" | mail -s "Development Environment Report" admin@company.com
```

---

These examples cover the most common use cases for the Resilient Installation System. For more specific scenarios or custom requirements, refer to the main documentation or create custom step functions as shown in the customization examples.
