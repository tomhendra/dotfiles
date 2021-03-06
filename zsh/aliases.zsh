# Shortcuts
alias brewup="brew upgrade && brew cleanup && brew doctor"
alias cafe="caffeinate -u -t 3600"
alias chrome="open -a 'Google Chrome Dev'"
alias copyssh="pbcopy < ${HOME}/.ssh/id_rsa.pub"
alias flushdns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias pingoogle="echo 'th: Pinging Google' && ping www.google.com";
alias reloadshell="source ${HOME}/.zshrc"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
alias disapprove="echo ಠ_ಠ | pbcopy"
alias rage="echo (╯°□°）╯︵ ┻━┻ | pbcopy"

# Directories
alias ..="cd .."
alias d="cd ${DEV}"
alias cw="cd ${DEV}/coursework"
alias cwc="code ${DEV}/coursework"
alias df="cd ${DOTFILES}"
alias dfc="code ${DOTFILES}"
alias lib="cd ${HOME}/Library"
alias c="code ."

# npm
alias npmclean="rm -rf node_modules package-lock.json"
alias npmfresh="npmclean && npm i"
alias npmb="npm build"
alias npmd="npm run dev"
alias npms="npm start"
alias npmw="echo 'when will npm support workspace targeting? 👀'"

# yarn
alias yclean="rm -rf node_modules/ yarn.lock"
alias yfresh="yclean && yarn"
alias yb="yarn build"
alias yd="yarn dev"
alias ys="yarn start"
alias yt="yarn test"
alias yw="yarn workspace"

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

# aws amplify
alias apush="amplify push --y"
alias apull="amplify pull"
