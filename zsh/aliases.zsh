# Shortcuts
alias copyssh="pbcopy < ${HOME}/.ssh/id_rsa.pub"
alias flushdns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias reloadshell="source ${HOME}/.zshrc"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"

# Directories
alias ..="cd .."
alias cw="cd ${DEV}/coursework"
alias d="cd ${DEV}"
alias df="cd ${DOTFILES}"
alias bu="brew update && brew cleanup && brew doctor"
alias lib="cd ${HOME}/Library"
alias pg="echo 'Pinging Google' && ping www.google.com";

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
