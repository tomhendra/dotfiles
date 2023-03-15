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

# pnpm
export PNPM_HOME="/Users/tom/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
