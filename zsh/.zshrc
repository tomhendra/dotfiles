# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

# environment variables
export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
export DEVELOPER="${HOME}/Developer"
export DOTFILES="${HOME}/.dotfiles"
export LOGSEQ="${HOME}/Library/Mobile Documents/iCloud~com~logseq~logseq/Documents"
export OBSIDIAN="${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/"
export PNPM_HOME="${HOME}/Library/pnpm"
export ANDROID_HOME="${HOME}/Library/Android/sdk"
export ZNAP="${HOME}/.zsh_plugins/znap"

# Start SSH agent & add all SSH keys
eval "$(ssh-agent -s)"
ssh-add -A 2>/dev/null

# path configurations
typeset -U path  # Ensures unique entries in PATH

path=(
    "$PNPM_HOME"
    "./node_modules/.bin"
    "./vendor/bin"
    "$ANDROID_HOME/emulator"
    "$ANDROID_HOME/platform-tools"
    "$HOME/.dotnet/tools"
    "$HOME/.local/share/solana/install/active_release/bin"
    "/usr/local/sbin"
    $path
)

export PATH

# aliases
source "${HOME}/.dotfiles/zsh/aliases.zsh"

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

# Download Znap, if it's not there yet.
[[ -r ${ZNAP}/znap.zsh ]] ||
    git clone --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git ${ZNAP}
source ${ZNAP}/znap.zsh  # Start Znap

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
