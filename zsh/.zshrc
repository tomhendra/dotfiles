# Starship init
eval "$(starship init zsh)"

# Antibody init
source <(antibody init)

# Source zsh plugins.
antibody bundle < ${HOME}/.dotfiles/zsh/plugins.txt

# Set theme.
antibody bundle ohmyzsh/ohmyzsh path:themes/cloud.zsh-theme

# Aliases
source ${HOME}/.dotfiles/zsh/aliases.zsh

# Paths
source ${HOME}/.dotfiles/zsh/paths.zsh
