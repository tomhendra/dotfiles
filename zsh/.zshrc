# Paths
source ${HOME}/.dotfiles/zsh/paths.zsh

# Starship init
eval "$(starship init zsh)"

# Antibody init
source <(antibody init)

# Plugins
antibody bundle < ${HOME}/.dotfiles/zsh/plugins.zsh

# Theme
antibody bundle ohmyzsh/ohmyzsh path:themes/cloud.zsh-theme

# Aliases
source ${HOME}/.dotfiles/zsh/aliases.zsh
