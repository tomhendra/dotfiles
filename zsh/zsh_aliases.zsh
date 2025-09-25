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
alias ip="dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com"
alias flushdns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias pingoo="echo 'tom: Pinging Google' && ping www.google.com"

# Kiro
alias k="kiro ."
alias dfk="kiro ${DOTFILES}"

# VS Code
alias c="code ."
alias dfc="code ${DOTFILES}"

# Zed
alias zed="open -a Zed.app"
alias z="zed ."
alias dfz="zed ${DOTFILES}"

# Files & Directories
alias ..="cd .."
alias dl="cd ${HOME}/Downloads"
alias dv="cd ${DEVELOPER}"
alias w3="cd ${DEVELOPER}/web3"
alias df="cd ${DOTFILES}"
alias lib="cd ${HOME}/Library"
alias obsidian-dir="cd ${OBSIDIAN}"

# trash-cli
alias tp="trash-put"
alias te="trash-empty"
alias tl="trash-list"
alias tr="trash-restore"
alias trm="trash-rm"

# Git
# Status
alias gs="git status -sb"
alias gsf="git status"
# Diff and log
alias gd="git diff"
alias gl="git log --oneline --decorate --color"
# Branch and checkout
alias gb="git branch"
alias gc="git checkout"
# Resetting and cleaning
alias reset-soft="git checkout -- ."
alias reset-hard="git reset --hard HEAD"
alias reset-dangerous="git clean -fd && git reset --hard HEAD"
# Committing
alias com="git add . && git commit -m"
alias resolve="git commit --no-edit"
alias amend="git commit --amend --no-edit"
# Syncing
alias pull="git pull"
alias push="git push"
alias push-force="git push --force"
# Stashing
alias pop="git stash pop"
alias stash="git stash -u"
# Misc
alias unstage="git restore --staged ."
alias wip="git add . && git commit -m 'WIP'"

# Rust
alias rb="rustup doc --book"
alias cc="cargo check"
alias cr="cargo run"
alias cb="cargo build"
alias cbr="cargo build --release"

# Node
alias rnm="rm -rf node_modules"
alias node-lts="pnpm env use --global lts"
alias node-latest="pnpm env use --global latest"

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
alias pnpx="pnpm dlx"
alias pi="pnpm install"
alias pa="pnpm add"
alias pap="pnpm add --save-peer"
alias pag="pnpm add --global"
alias dlx="pnpm dlx"
alias pr="pnpm remove"
alias pu="pnpm update --interactive"
alias pug="pnpm update --global --interactive"
alias pus="pnpm self-update"
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
alias xcode-erase-all-simulators="sudo xcrun simctl erase all"
alias xccode-accept-license="sudo xcodebuild -license accept"

# Android Studio
alias adbdark='adb shell "cmd uimode night yes"'
alias adblight='adb shell "cmd uimode night no"'
