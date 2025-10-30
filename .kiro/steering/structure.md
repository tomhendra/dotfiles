# Project Structure

## Root Directory Organization

```
tomdot/
├── .git/                    # Git repository data
├── .kiro/                   # Kiro IDE configuration
├── README.md                # Main documentation
├── SETUP-CHECKLIST.md       # Step-by-step setup guide
├── install.sh               # Main installation script
├── create_symlinks.sh       # Creates symlinks to dotfiles
├── delete_symlinks.sh       # Removes symlinks
├── .macos                   # macOS system preferences
├── Brewfile                 # Homebrew package definitions
├── global_pkg.sh            # Global Node.js packages
└── starship.toml            # Starship prompt configuration
```

## Configuration Directories

### Application Configs

- `bat/` - Enhanced cat tool configuration and themes
- `ghostty/` - Terminal emulator config and Tokyo Night theme
- `git/` - Git configuration and global gitignore
- `iterm2/` - iTerm2 color schemes (legacy)
- `kitty/` - Kitty terminal config and themes (legacy)
- `vscode/` - VS Code custom styling
- `zed/` - Zed editor settings
- `zsh/` - Shell configuration and aliases

### Key Files by Category

**Shell & Terminal**

- `zsh/.zshrc` - Main zsh configuration
- `zsh/.zprofile` - zsh profile settings
- `zsh/zsh_aliases.zsh` - Custom command aliases
- `ghostty/config` - Terminal appearance and behavior
- `starship.toml` - Cross-shell prompt configuration

**Development Tools**

- `git/.gitconfig` - Git user settings and preferences
- `git/.gitignore_global` - Global gitignore patterns
- `bat/bat.conf` - Syntax highlighting configuration

**Package Management**

- `Brewfile` - Homebrew formulae and casks
- `global_pkg.sh` - npm global packages list
- `git/get_repos.sh` - GitHub repositories to clone

## Symlink Strategy

The `create_symlinks.sh` script creates symbolic links from `~/.dotfiles/` to their expected locations in the home directory:

- `~/.dotfiles/zsh/.zshrc` → `~/.zshrc`
- `~/.dotfiles/git/.gitconfig` → `~/.gitconfig`
- `~/.dotfiles/ghostty/` → `~/.config/ghostty/`
- And more...

## Theme Consistency

Tokyo Night Storm theme is applied across:

- Ghostty terminal
- bat syntax highlighting
- Git delta diffs
- Various editor configurations

## Installation Flow

1. `install.sh` - Main orchestrator
2. SSH key generation and GitHub auth
3. Clone this repository to `~/.dotfiles`
4. Clone development repositories to `~/Developer`
5. Install Homebrew and packages
6. Install language runtimes (Node.js, Rust)
7. Create configuration symlinks
8. Apply system preferences (optional)
