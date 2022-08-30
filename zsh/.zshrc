# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && . "$HOME/.fig/shell/zshrc.pre.zsh"

# clone antidote if necessary
if ! [[ -e ${ZDOTDIR:-~}/.antidote ]]; then
  git clone https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
fi

# source antidote
source ${ZDOTDIR:-~}/.antidote/antidote.zsh

# generate and source plugins from ~/.zsh_plugins.txt
antidote load

# $PATH additions
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
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && . "$HOME/.fig/shell/zshrc.post.zsh"