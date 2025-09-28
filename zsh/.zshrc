# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

# default language
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Environment variables
export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
export DEVELOPER="${HOME}/Developer"
export DOTFILES="${HOME}/.dotfiles"
export OBSIDIAN="${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/"
export PNPM_HOME="${HOME}/Library/pnpm"
export ANDROID_HOME="${HOME}/Library/Android/sdk"
export BAT_CONFIG_PATH="${HOME}/.config/bat/bat.conf"
export GHOSTTY_CONFIG_PATH="${HOME}/.config/ghostty/config"

# Start SSH agent & add all SSH keys
eval "$(ssh-agent -s)"
ssh-add -A 2>/dev/null

# Path configurations
typeset -U path  # Ensures unique entries in PATH

path=(
    "$HOME/.rbenv/bin"
    "$PNPM_HOME"
    "./node_modules/.bin"
    "./vendor/bin"
    "$HOME/.cargo/bin"
    "$HOME/.local/share/solana/install/active_release/bin"
    "$ANDROID_HOME/emulator"
    "$ANDROID_HOME/platform-tools"
    "/usr/local/sbin"
    $path
)

export PATH

# Ruby version management init
eval "$(rbenv init -)"

# Aliases
source "${DOTFILES}/zsh/zsh_aliases.zsh"

# Starship init
eval "$(starship init zsh)"

# bun completions
[ -s "${HOME}/.bun/_bun" ] && source "${HOME}/.bun/_bun"

# pnpm
export PNPM_HOME="/Users/tomhendra/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
