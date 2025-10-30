# Troubleshooting Guide

This guide covers common issues you might encounter with the Resilient Installation System and their solutions.

## Quick Diagnostics

### Check System Status

```bash
# Run comprehensive validation
./validate_installation.sh

# Check specific category
./validate_installation.sh --category system

# View installation logs
tail -f ~/.dotfiles_state/installation.log

# Check error summary
cat ~/.dotfiles_state/error_summary.json
```

### Common Commands

```bash
# Resume failed installation
./install_enhanced.sh --resume --verbose

# Reset and start fresh
./install_enhanced.sh --reset --force

# Validate without installing
./install_enhanced.sh --dry-run --verbose
```

## Installation Issues

### 1. Installation Hangs or Freezes

**Symptoms:**

- Installation stops responding
- No progress updates for extended periods
- Terminal appears frozen

**Causes:**

- Network connectivity issues
- Waiting for user input in background process
- System resource constraints

**Solutions:**

1. **Check for background prompts:**

   ```bash
   # Look for password prompts or confirmations
   ps aux | grep -E "(sudo|osascript|installer)"
   ```

2. **Test network connectivity:**

   ```bash
   # Test basic connectivity
   ping -c 3 github.com
   curl -I https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
   ```

3. **Resume with verbose logging:**

   ```bash
   # Kill current process (Ctrl+C) then resume
   ./install_enhanced.sh --resume --verbose
   ```

4. **Check system resources:**
   ```bash
   # Check available memory and CPU
   top -l 1 | head -20
   df -h
   ```

### 2. Permission Denied Errors

**Symptoms:**

- "Permission denied" messages
- "Operation not permitted" errors
- Files cannot be created or modified

**Causes:**

- Insufficient file system permissions
- macOS System Integrity Protection (SIP)
- Incorrect ownership of directories

**Solutions:**

1. **Fix directory permissions:**

   ```bash
   # Fix common directory permissions
   sudo chown -R $(whoami) ~/.dotfiles
   chmod -R 755 ~/.dotfiles

   # Fix Homebrew permissions
   sudo chown -R $(whoami) /opt/homebrew
   ```

2. **Check SIP status:**

   ```bash
   # Check if SIP is causing issues
   csrutil status

   # If needed, disable SIP temporarily (requires reboot to Recovery Mode)
   # This should be a last resort
   ```

3. **Use correct installation method:**

   ```bash
   # Don't run the installer with sudo
   ./install_enhanced.sh  # ✅ Correct

   # sudo ./install_enhanced.sh  # ❌ Incorrect
   ```

### 3. Network and Download Failures

**Symptoms:**

- "Connection timeout" errors
- "Failed to download" messages
- SSL/TLS certificate errors

**Causes:**

- Unstable internet connection
- Firewall or proxy restrictions
- DNS resolution issues
- Rate limiting by servers

**Solutions:**

1. **Test and fix connectivity:**

   ```bash
   # Test DNS resolution
   nslookup github.com
   nslookup raw.githubusercontent.com

   # Test HTTPS connectivity
   curl -v https://github.com
   ```

2. **Configure proxy if needed:**

   ```bash
   # Set proxy environment variables
   export https_proxy=http://proxy.company.com:8080
   export http_proxy=http://proxy.company.com:8080

   # Configure git proxy
   git config --global http.proxy http://proxy.company.com:8080
   ```

3. **Retry with increased timeout:**

   ```bash
   # Increase network timeout
   export NETWORK_TIMEOUT=120
   ./install_enhanced.sh --resume
   ```

4. **Use alternative download methods:**
   ```bash
   # Download Homebrew installer manually
   curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > /tmp/brew_install.sh
   bash /tmp/brew_install.sh
   ```

### 4. Homebrew Installation Issues

**Symptoms:**

- Homebrew installation fails
- Package installation errors
- "Formula not found" errors

**Causes:**

- Incomplete Homebrew installation
- Outdated package definitions
- Architecture conflicts (Intel vs Apple Silicon)

**Solutions:**

1. **Clean Homebrew installation:**

   ```bash
   # Uninstall Homebrew completely
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

   # Reinstall Homebrew
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Update and fix Homebrew:**

   ```bash
   # Update Homebrew
   brew update

   # Fix common issues
   brew doctor

   # Clean up
   brew cleanup
   ```

3. **Fix PATH issues:**

   ```bash
   # Add Homebrew to PATH (Apple Silicon)
   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
   eval "$(/opt/homebrew/bin/brew shellenv)"

   # Add Homebrew to PATH (Intel)
   echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
   eval "$(/usr/local/bin/brew shellenv)"
   ```

### 5. SSH and GitHub Authentication Issues

**Symptoms:**

- "Permission denied (publickey)" errors
- "Could not read from remote repository" messages
- SSH key authentication failures

**Causes:**

- SSH key not added to GitHub account
- SSH agent not running
- Incorrect SSH key permissions

**Solutions:**

1. **Verify SSH key setup:**

   ```bash
   # Check if SSH key exists
   ls -la ~/.ssh/id_*

   # Check SSH key permissions
   chmod 600 ~/.ssh/id_rsa
   chmod 644 ~/.ssh/id_rsa.pub
   ```

2. **Add SSH key to agent:**

   ```bash
   # Start SSH agent
   eval "$(ssh-agent -s)"

   # Add SSH key
   ssh-add ~/.ssh/id_rsa

   # Verify key is loaded
   ssh-add -l
   ```

3. **Test GitHub connection:**

   ```bash
   # Test SSH connection to GitHub
   ssh -T git@github.com

   # Should return: "Hi username! You've successfully authenticated..."
   ```

4. **Re-add SSH key to GitHub:**

   ```bash
   # Copy public key to clipboard
   pbcopy < ~/.ssh/id_rsa.pub

   # Open GitHub SSH settings
   open https://github.com/settings/keys

   # Add the key manually
   ```

## Configuration Issues

### 1. Configuration File Conflicts

**Symptoms:**

- "Configuration conflict detected" messages
- Existing settings being overwritten
- Applications not using new configurations

**Causes:**

- Existing configuration files
- Conflicting settings between old and new configs
- Incorrect file permissions

**Solutions:**

1. **Use interactive conflict resolution:**

   ```bash
   # Run installation in interactive mode
   ./install_enhanced.sh --interactive --components configurations
   ```

2. **Backup existing configurations:**

   ```bash
   # Create backup before installation
   ./install_enhanced.sh --backup-configs

   # List available backups
   ls -la ~/.dotfiles_backup_*
   ```

3. **Merge configurations manually:**

   ```bash
   # View differences
   diff ~/.zshrc ~/.dotfiles/zsh/.zshrc

   # Merge manually or use merge tool
   vimdiff ~/.zshrc ~/.dotfiles/zsh/.zshrc
   ```

### 2. Symlink Issues

**Symptoms:**

- Broken symlinks
- "No such file or directory" errors
- Configuration changes not taking effect

**Causes:**

- Target files moved or deleted
- Incorrect symlink paths
- Permission issues

**Solutions:**

1. **Validate symlinks:**

   ```bash
   # Check symlink integrity
   ./validate_installation.sh --category symlinks

   # Find broken symlinks
   find ~ -maxdepth 2 -type l ! -exec test -e {} \; -print
   ```

2. **Recreate symlinks:**

   ```bash
   # Remove broken symlinks
   find ~ -maxdepth 2 -type l ! -exec test -e {} \; -delete

   # Recreate symlinks
   ./install_enhanced.sh --components symlinks --force
   ```

3. **Fix symlink permissions:**

   ```bash
   # Fix target file permissions
   chmod 644 ~/.dotfiles/zsh/.zshrc

   # Recreate symlink
   ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
   ```

## Tool-Specific Issues

### 1. Node.js and npm Issues

**Symptoms:**

- "node: command not found"
- npm permission errors
- Package installation failures

**Causes:**

- Node.js not in PATH
- Incorrect npm permissions
- Version conflicts

**Solutions:**

1. **Fix Node.js PATH:**

   ```bash
   # Check if fnm is installed
   which fnm

   # Set up fnm environment
   eval "$(fnm env --use-on-cd)"

   # Install and use Node.js
   fnm install 22
   fnm use 22
   fnm default 22
   ```

2. **Fix npm permissions:**

   ```bash
   # Use fnm (recommended) instead of fixing npm permissions
   # fnm manages Node.js versions without permission issues

   # If using system npm, fix permissions
   sudo chown -R $(whoami) ~/.npm
   ```

3. **Clear npm cache:**

   ```bash
   # Clear npm cache
   npm cache clean --force

   # Verify npm configuration
   npm config list
   ```

### 2. Git Configuration Issues

**Symptoms:**

- Git commands fail with configuration errors
- "Please tell me who you are" messages
- Credential helper issues

**Causes:**

- Missing git user configuration
- Incorrect credential helpers
- Global gitignore issues

**Solutions:**

1. **Configure git user:**

   ```bash
   # Set git user information
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"

   # Verify configuration
   git config --global --list
   ```

2. **Fix credential helper:**

   ```bash
   # Set up credential helper for macOS
   git config --global credential.helper osxkeychain

   # Clear stored credentials if needed
   git config --global --unset credential.helper
   ```

3. **Fix global gitignore:**

   ```bash
   # Check global gitignore path
   git config --global core.excludesfile

   # Set correct path
   git config --global core.excludesfile ~/.gitignore_global
   ```

### 3. Shell and Terminal Issues

**Symptoms:**

- New shell configuration not loading
- Command aliases not working
- Terminal theme not applied

**Causes:**

- Shell not reloaded after configuration changes
- Incorrect shell configuration
- Terminal application caching

**Solutions:**

1. **Reload shell configuration:**

   ```bash
   # Reload zsh configuration
   source ~/.zshrc

   # Or restart terminal
   exec zsh
   ```

2. **Check shell configuration:**

   ```bash
   # Verify current shell
   echo $SHELL

   # Check if zsh is default
   chsh -s /bin/zsh
   ```

3. **Fix terminal theme:**

   ```bash
   # Check if theme files exist
   ls -la ~/.config/ghostty/

   # Restart terminal application
   killall Ghostty
   ```

## System-Specific Issues

### 1. macOS Version Compatibility

**Symptoms:**

- "Unsupported macOS version" errors
- Tools failing to install
- Compatibility warnings

**Causes:**

- Running on unsupported macOS version
- Outdated system components
- Missing system updates

**Solutions:**

1. **Check macOS version:**

   ```bash
   # Check current macOS version
   sw_vers -productVersion

   # Check system requirements
   ./validate_installation.sh --category system
   ```

2. **Update macOS:**

   ```bash
   # Check for system updates
   softwareupdate -l

   # Install available updates
   sudo softwareupdate -i -a
   ```

3. **Install Command Line Tools:**

   ```bash
   # Install Xcode Command Line Tools
   xcode-select --install

   # Accept license
   sudo xcodebuild -license accept
   ```

### 2. Architecture Issues (Intel vs Apple Silicon)

**Symptoms:**

- "Architecture mismatch" errors
- Some tools not working correctly
- Performance issues

**Causes:**

- Running Intel binaries on Apple Silicon
- Incorrect Homebrew installation path
- Mixed architecture installations

**Solutions:**

1. **Check system architecture:**

   ```bash
   # Check system architecture
   uname -m
   # arm64 = Apple Silicon, x86_64 = Intel

   # Check Homebrew architecture
   brew config | grep "CPU:"
   ```

2. **Use correct Homebrew path:**

   ```bash
   # Apple Silicon Homebrew path
   /opt/homebrew/bin/brew

   # Intel Homebrew path
   /usr/local/bin/brew
   ```

3. **Reinstall for correct architecture:**
   ```bash
   # Uninstall and reinstall Homebrew for correct architecture
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

## Recovery Procedures

### 1. Complete System Reset

If the installation is severely corrupted:

```bash
# 1. Reset installation state
./install_enhanced.sh --reset

# 2. Clean up existing installations
rm -rf ~/.dotfiles
brew uninstall --force --ignore-dependencies $(brew list --formula)
brew uninstall --cask --force $(brew list --cask)

# 3. Start fresh installation
./install_enhanced.sh --force --verbose
```

### 2. Partial Recovery

If only specific components are failing:

```bash
# 1. Identify failing components
./validate_installation.sh --verbose

# 2. Reset specific component state
# Edit ~/.dotfiles_state/state.json to remove failing step

# 3. Reinstall specific components
./install_enhanced.sh --components homebrew,nodejs --force
```

### 3. Restore from Backup

If you need to restore previous configurations:

```bash
# 1. List available backups
ls -la ~/.dotfiles_backup_*

# 2. Restore from backup
cp -r ~/.dotfiles_backup_20240101_120000/* ~/

# 3. Verify restoration
./validate_installation.sh
```

## Getting Help

### Collecting Diagnostic Information

When reporting issues, include:

```bash
# System information
sw_vers
uname -a
echo $SHELL

# Installation state
cat ~/.dotfiles_state/state.json

# Recent logs
tail -50 ~/.dotfiles_state/installation.log
tail -20 ~/.dotfiles_state/errors.log

# Validation report
./validate_installation.sh --verbose > validation_report.txt
```

### Common Log Locations

- Installation logs: `~/.dotfiles_state/installation.log`
- Error logs: `~/.dotfiles_state/errors.log`
- State file: `~/.dotfiles_state/state.json`
- Validation reports: `~/.dotfiles_validation_*.json`

### Support Channels

1. **Self-Service**: Use this troubleshooting guide
2. **Validation**: Run `./validate_installation.sh --verbose`
3. **Documentation**: Check `RESILIENT_INSTALLATION.md`
4. **GitHub Issues**: Report bugs with diagnostic information

---

**Remember**: Always backup your important configurations before making changes, and test solutions in a safe environment when possible.
