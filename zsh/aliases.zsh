# Shortcuts
alias copyssh="pbcopy < ${HOME}/.ssh/id_rsa.pub"
alias reloadshell="source ${HOME}/.zshrc"
alias flushdns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"

# Directories
alias dotfiles="cd ${DOTFILES}"
alias library="cd ${HOME}/Library"
alias dev="cd ${HOME}/Dev"

# JS
alias yfresh="rm -rf node_modules/ yarn.lock && yarn"
alias ywatch="yarn watch"

# Git
alias gst="git status"
alias gs="git status -sb"
alias gb="git branch"
alias gc="git checkout"
alias gl="git log --oneline --decorate --color"
alias amend="git add . && git commit --amend --no-edit"
alias commit="git add . && git commit -m"
alias diff="git diff"
alias force="git push --force"
alias nuke="git clean -df && git reset --hard"
alias pop="git stash pop"
alias pull="git pull"
alias push="git push"
alias resolve="git add . && git commit --no-edit"
alias stash="git stash -u"
alias unstage="git restore --staged ."
alias wip="commit wip"
