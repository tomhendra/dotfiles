# General
alias brewup="brew upgrade && brew cleanup && brew doctor"
alias c="code ."
alias chrome="open -a 'Google Chrome'"
alias brave="open -a 'Brave Browser'"
alias firefox="open -a 'Firefox Developer Edition'"
alias cafe="caffeinate -u -t 3600"
alias copyssh="pbcopy < ${HOME}/.ssh/id_rsa.pub"
alias flushdns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias pingg="echo 'tom: Pinging Google' && ping www.google.com";
alias reloadzsh="source ${HOME}/.zshrc"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
alias balk="echo 'ಠ_ಠ' | pbcopy"
alias strong'ᕦ(ಠ_ಠ)ᕤ'
alias rage="echo '(╯°□°）╯︵ ┻━┻' | pbcopy"
alias sol="echo '◎' | pbcopy"
alias stx="echo 'Ӿ' | pbcopy"
alias wen="echo 'https://tenor.com/view/when-wen-naru-yummi-yummi-universe-gif-23030317' | pbcopy"

# Files & Directories
alias ..="cd .."
alias d="cd ~/Downloads"
alias dv="cd ${DEVELOPER}"
alias df="cd ${DOTFILES}"
alias dfc="code ${DOTFILES}"
alias lib="cd ${HOME}/Library"
alias logseq-dir="cd ${LOGSEQ}"
alias logseq-config="code ${LOGSEQ}/logseq/config.edn"
alias tp="trash-put"
alias te="trash-empty"
alias tl="trash-list"
alias tr="trash-restore"
alias trm="trash-rm"

# Git
alias gs="git status -sb"
alias gst="git status"
alias gb="git branch"
alias gc="git checkout"
alias gl="git log --oneline --decorate --color"
alias commit="git add . && git commit -m"
alias amend="git add . && git commit --amend --no-edit"
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

# Cargo
alias cc="cargo check"
alias cr="cargo run"
alias cb="cargo build"
alias cbr="cargo build --release"

# Node
alias rnm="rm -rf node_modules"

# pnpm
alias pni="pnpm install"
alias pna="pnpm add"
alias pnap="pnpm add --save-peer"
alias pnag="pnpm add --global"
alias pnr="pnpm remove"
alias pnu="pnpm update --interactive"
alias pnug="pnpm update --global"
alias pnd="pnpm dev"
alias pns="pnpm start"
alias pnt="pnpm test"
alias pnb="pnpm build"
alias pnlts="pnpm env use --global lts"
alias pnlatest="pnpm env use --global latest"
alias pndir cd $PNPM_HOME

# npm
alias ni="npm install"
alias nr="npm remove"
alias nd="npm run dev"
alias ns="npm run start"
alias nt="npm run test"
alias nb="npm run build"

# yarn
alias yd="yarn dev"
alias ys="yarn start"
alias yt="yarn test"
alias yb="yarn build"
alias ynuke="rm -rf node_modules/ yarn.lock"
alias yw="yarn workspace"