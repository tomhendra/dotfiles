# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
# $PATH variable additions
source ${HOME}/.dotfiles/zsh/path.zsh

# Environment variables
source ${HOME}/.dotfiles/zsh/vars.zsh

# Aliases
source ${HOME}/.dotfiles/zsh/aliases.zsh

# Starship init
eval "$(starship init zsh)"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "/Users/tom/.bun/_bun" ] && source "/Users/tom/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Added by Docker Desktop
source /Users/tom/.docker/init-zsh.sh || true 

# bun completions
[ -s "/Users/tomhendra/.bun/_bun" ] && source "/Users/tomhendra/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"