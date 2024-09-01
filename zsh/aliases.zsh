# General
alias brewup="brew upgrade && brew cleanup && brew doctor"
alias chrome="open -a 'Google Chrome'"
alias firefox="open -a 'Firefox Developer Edition'"
alias cafe="caffeinate -u -t 3600"
alias copyssh="pbcopy < ${HOME}/.ssh/id_rsa.pub"
alias reloadzsh="source ${HOME}/.zshrc"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
alias balk="echo 'ಠ_ಠ' | pbcopy"
alias strong='ᕦ(ಠ_ಠ)ᕤ'
alias rage="echo '(╯°□°）╯︵ ┻━┻' | pbcopy"
alias cheer="echo '✧*｡٩(ˊᗜˋ*)و✧*｡' | pbcopy"
alias sol="echo '◎' | pbcopy"
alias stx="echo 'Ӿ' | pbcopy"
alias refresh-dock-icons="rm /var/folders/*/*/*/com.apple.dock.iconcache; killall Dock"

# Network
alias pingg="echo 'tom: Pinging Google' && ping www.google.com";
alias myip="dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com"
alias flushdns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"

# Zed
alias zed="open -a Zed.app"
alias z="zed ."
alias dfz="zed ${DOTFILES}"

# VS Code
alias c="code ."
alias dfc="code ${DOTFILES}"
alias lgsc="code ${LOGSEQ}/logseq/config.edn"

# Files & Directories
alias ..="cd .."
alias dl="cd ${HOME}/Downloads"
alias dv="cd ${DEVELOPER}"
alias w3="cd ${DEVELOPER}/web3"
alias df="cd ${DOTFILES}"
alias lib="cd ${HOME}/Library"
alias obsidian-dir="cd ${OBSIDIAN}"
alias logseq-dir="cd ${LOGSEQ}"

# trash-cli
alias tp="trash-put"
alias te="trash-empty"
alias tl="trash-list"
alias tr="trash-restore"
alias trm="trash-rm"

# Git
alias gs="git status -sb"
alias gst="git status"
alias gd="git diff"
alias gl="git log --oneline --decorate --color"
alias gb="git branch"
alias gc="git checkout"
alias gabandon="git checkout -- ."
alias gcom="git add . && git commit -am"
alias resolve="git commit -am --no-edit"
alias amend="git commit -am --amend --no-edit"
alias pull="git pull"
alias push="git push"
alias force="git push --force"
alias dangerously-reset="git clean -df && git reset --hard"
alias pop="git stash pop"
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
alias nodelts="pnpm env use --global lts"
alias nodelatest="pnpm env use --global latest"

# Deno
alias dts="deno task start"
alias dtc="deno task check"
alias dtb="deno task build"
alias dtp="deno task preview"
alias dtu="deno task update"

# Bun
alias br="bun run"
alias bd="bun run dev"

# pnpm
alias pnewversion="curl -fsSL https://get.pnpm.io/install.sh | sh -"
alias pi="pnpm install"
alias pa="pnpm add"
alias pap="pnpm add --save-peer"
alias pag="pnpm add --global"
alias dlx="pnpm dlx"
alias pr="pnpm remove"
alias pu="pnpm update --interactive"
alias pug="pnpm update --global --interactive"
alias pd="pnpm dev"
alias ps="pnpm start"
alias pt="pnpm test"
alias pb="pnpm build"

alias pdir="cd $PNPM_HOME"
alias paip="pnpm config set auto-install-peers true"
alias pt="pnpm t"
alias pnx="pnpm nx"

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

# Xcode
alias xc-erase-all-simulators="sudo xcrun simctl erase all"
alias xc-accept-license="sudo xcodebuild -license accept"

# Android Studio
alias adbdark='adb shell "cmd uimode night yes"'
alias adblight='adb shell "cmd uimode night no"'
