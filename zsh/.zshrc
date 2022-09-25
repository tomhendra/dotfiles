# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"

# Aliases
source ${HOME}/.dotfiles/zsh/aliases.zsh

# Environment variables
source ${HOME}/.dotfiles/zsh/envs.zsh

# $PATH variables
source ${HOME}/.dotfiles/zsh/paths.zsh

# pnpm $PATH variables
export PNPM_HOME="/Users/tom/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Starship init
eval "$(starship init zsh)"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
