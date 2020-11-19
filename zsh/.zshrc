# Antibody init
source <(antibody init)

# Plugins
antibody bundle < ${HOME}/.dotfiles/zsh/plugins.zsh

# $PATH additions
source ${HOME}/.dotfiles/zsh/paths.zsh

# Environment variables
source ${HOME}/.dotfiles/zsh/env.zsh

# Aliases
source ${HOME}/.dotfiles/zsh/aliases.zsh

# Starship init
eval "$(starship init zsh)"