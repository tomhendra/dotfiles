# CodeWhisperer pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.pre.zsh"

# $PATH variable additions
source ${HOME}/.dotfiles/zsh/path.zsh

# Environment variables
source ${HOME}/.dotfiles/zsh/vars.zsh

# Aliases
source ${HOME}/.dotfiles/zsh/aliases.zsh

# Starship init
eval "$(starship init zsh)"

# Java for React Native
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

# CodeWhisperer post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.post.zsh"
