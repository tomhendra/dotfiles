# Shortcuts
alias brewup="brew upgrade && brew cleanup && brew doctor"
alias copyssh="pbcopy < ${HOME}/.ssh/id_rsa.pub"
alias flushdns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias pingoo="echo 'Pinging Google' && ping www.google.com";
alias reloadshell="source ${HOME}/.zshrc"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"

# Directories
alias ..="cd .."
alias d="cd ${DEV}"
alias cw="cd ${DEV}/coursework"
alias cwc="code ${DEV}/coursework"
alias df="cd ${DOTFILES}"
alias dfc="code ${DOTFILES}"
alias lib="cd ${HOME}/Library"

# JS
alias yfresh="rm -rf node_modules/ yarn.lock && yarn"
alias ywatch="yarn watch"

# Git
alias gs="git status -sb"
alias gst="git status"
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
