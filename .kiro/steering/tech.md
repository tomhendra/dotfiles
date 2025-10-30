# Technology Stack

## Core Technologies

- **Shell**: zsh with custom configuration
- **Package Management**: Homebrew for system packages, npm/pnpm/bun for Node.js
- **Version Management**: fnm for Node.js, rbenv for Ruby
- **Languages**: JavaScript/TypeScript (primary), Rust, Python, Ruby
- **Terminal**: Ghostty with Tokyo Night Storm theme
- **Editor**: VS Code, Zed, Kiro
- **Git**: Enhanced with delta for diffs

## Development Tools

### CLI Tools

- `bat` - Enhanced cat with syntax highlighting
- `ripgrep` - Fast text search
- `starship` - Cross-shell prompt
- `git-delta` - Enhanced git diffs
- `trash-cli` - Safe file deletion
- `gh` - GitHub CLI

### Mobile Development

- React Native via Expo
- Android Studio with emulator
- Fastlane for deployment
- Watchman for file watching

### Web3/Blockchain

- Solana CLI tools
- Rust for smart contracts

## Common Commands

### Environment Setup

```bash
# Full environment setup (fresh macOS)
curl -ssL https://git.io/tomdot | sh

# Create symlinks
./create_symlinks.sh

# Delete symlinks
./delete_symlinks.sh

# Apply macOS settings
./.macos
```

### Package Management

```bash
# Update Homebrew
brewup

# Node.js version management
fnm install 22
fnm use 22
fnm default 22

# Global Node packages
./global_pkg.sh
```

### Development Workflow

```bash
# Quick project access
dv          # cd to ~/Developer
df          # cd to ~/.dotfiles
k           # Open Kiro in current directory
c           # Open VS Code in current directory
z           # Open Zed in current directory
```

## Configuration Files

- **Shell**: `.zshrc`, `.zprofile`, `zsh_aliases.zsh`
- **Git**: `.gitconfig`, `.gitignore_global`
- **Terminal**: `ghostty/config`, `starship.toml`
- **Tools**: `bat/bat.conf`, various theme files
- **Package Lists**: `Brewfile`, `global_pkg.sh`
