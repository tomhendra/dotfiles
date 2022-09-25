# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"

# $PATH variables
source ${HOME}/.dotfiles/zsh/paths.zsh

# Environment variables
source ${HOME}/.dotfiles/zsh/env.zsh

# Aliases
source ${HOME}/.dotfiles/zsh/aliases.zsh

# Starship init
eval "$(starship init zsh)"

# pnpm path variables
export PNPM_HOME="/Users/tom/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
