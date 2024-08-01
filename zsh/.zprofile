# 1. Homebrew:
# The Homebrew initialization is typically placed in .zprofile for a reason. 
# It ensures that Homebrew's binaries are available in the PATH for login shells, 
# which includes GUI applications on macOS. Moving it to .zshrc might cause 
# issues with some applications that expect Homebrew to be initialized earlier 
# in the login process.

# 2. Amazon Q:
# The pre and post blocks in .zprofile and .zshrc are likely designed to work 
# together, with the .zprofile blocks running before the .zshrc blocks. Moving 
# them all to .zshrc could potentially disrupt their intended order of execution.

# Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh"
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
# Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh"