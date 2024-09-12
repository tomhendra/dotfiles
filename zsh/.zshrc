# Environment variables
export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
export DEVELOPER="${HOME}/Developer"
export DOTFILES="${HOME}/.dotfiles"
export LOGSEQ="${HOME}/Library/Mobile Documents/iCloud~com~logseq~logseq/Documents"
export OBSIDIAN="${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/"
export PNPM_HOME="${HOME}/Library/pnpm"
export ANDROID_HOME="${HOME}/Library/Android/sdk"

# Start SSH agent & add all SSH keys
eval "$(ssh-agent -s)"
ssh-add -A 2>/dev/null

# Path configurations
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

# Aliases
source "${DOTFILES}/zsh/zsh_aliases.zsh"

# Starship init
eval "$(starship init zsh)"

# Lazy-load antidote and generate the static load file only when needed
ZSH_PLUGINS=${HOME}/.zsh_plugins
if [[ ! ${ZSH_PLUGINS}.zsh -nt ${ZSH_PLUGINS}.txt ]]; then
  (
    source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
    antidote bundle <${DOTFILES}/zsh/zsh_plugins.txt >${zsh_plugins}.zsh
  )
fi
source ${zsh_plugins}.zsh

# bun completions
[ -s "${HOME}/.bun/_bun" ] && source "${HOME}/.bun/_bun"

# pnpm
export PNPM_HOME="/Users/tomhendra/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
