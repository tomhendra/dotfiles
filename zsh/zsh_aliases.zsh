# General
alias brewup="brew upgrade && brew cleanup && brew doctor"
alias chrome="open -a 'Google Chrome'"
alias firefox="open -a 'Firefox Developer Edition'"
alias cafe="caffeinate -u -t 3600"
alias sshcopy="pbcopy < ${HOME}/.ssh/id_rsa.pub"
alias reloadzsh="source ${HOME}/.zshrc"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
alias gimme="echo '༼ つ ◕_◕ ༽つ' | pbcopy"
alias disapprove="echo 'ಠ_ಠ' | pbcopy"
alias strong='ᕦ(ಠ_ಠ)ᕤ'
alias rage="echo '(╯°□°）╯︵ ┻━┻' | pbcopy"
alias cheer="echo '✧*｡٩(ˊᗜˋ*)و✧*｡' | pbcopy"
alias lenny="echo '( ͡° ͜ʖ ͡°)' | pbcopy"
alias why="echo 'ლ(ಠ_ಠ ლ)' | pbcopy"
alias bear="echo 'ʕ •ᴥ•ʔ' | pbcopy"
alias dead="echo '(✖╭╮✖)' | pbcopy"
alias love="echo '♥‿♥' | pbcopy"
alias dealwithit="echo '(⌐■_■)' | pbcopy"
alias wizard="echo '(ﾉಠヮಠ)ﾉ*:･ﾟ✧' | pbcopy"
alias sol="echo '◎' | pbcopy"
alias stx="echo 'Ӿ' | pbcopy"
alias refresh-dock-icons="rm /var/folders/*/*/*/com.apple.dock.iconcache; killall Dock"

# Network
alias ip="dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com"
alias flushdns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias pingoo="echo 'tom: Pinging Google' && ping www.google.com"

# Zed
alias zed="open -a Zed.app"
alias z="zed ."
alias dfz="zed ${DOTFILES}"

# VS Code
alias c="code ."
alias dfc="code ${DOTFILES}"

# Kiro
alias k="open -a Kiro ."
alias dfk="open -a Kiro ${DOTFILES}"

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

# Git Status
alias gs="git status -sb"
alias gsf="git status"
# Git diff and log
alias gd="git diff"
alias gl="git log --oneline --decorate --color"
# Git branch and checkout
alias gb="git branch"
alias gc="git checkout"
# Git resetting and cleaning
alias reset-soft="git checkout -- ."
alias reset-hard="git reset --hard HEAD"
alias reset-dangerous="git clean -fd && git reset --hard HEAD"
# Git commits
alias com="git add . && git commit -m"
alias resolve="git commit --no-edit"
alias amend="git commit --amend --no-edit"
# Git syncing
alias pull="git pull"
alias push="git push"
alias push-force="git push --force"
# Git stashing
alias pop="git stash pop"
alias stash="git stash -u"
# Git misc
alias unstage="git restore --staged ."
alias wip="git add . && git commit -m 'WIP'"

# Node
alias rnm="rm -rf node_modules"
alias node-lts="fnm install --lts && fnm use lts-latest"
alias node-latest="fnm install latest && fnm use latest"
# Node fnm
alias fnm-list="fnm list"
alias fnm-ls="fnm list"
alias fnm-use="fnm use"
alias fnm-install="fnm install"

# Deno
alias dts="deno task start"
alias dtc="deno task check"
alias dtb="deno task build"
alias dtp="deno task preview"
alias dtu="deno task update"

# Bun
alias bx="bunx"
alias bi="bun install"
alias ba="bun add"
alias bad="bun add --dev"
alias bag="bun add --global"
alias brm="bun remove"
alias bu="bun update"
alias bo="bun outdated"
alias br="bun run"
alias bd="bun run dev"
alias bs="bun run start"
alias bt="bun run test"
alias bb="bun run build"
alias bus="bun upgrade"
alias bdir="echo '${HOME}/.bun/install/global'"

# npm
alias nx="npx"
alias ni="npm install"
alias na="npm install"
alias nad="npm install --save-dev"
alias nag="npm install --global"
alias nrm="npm uninstall"
alias no="npm outdated"
alias nu="npm update"
alias nog="npm outdated -g"
alias nug="npm update -g"
alias nr="npm run"
alias nd="npm run dev"
alias ns="npm run start"
alias nsr="npm run start -- --reset-cache"
alias nt="npm run test"
alias nb="npm run build"
alias ndir="npm config get prefix"

# pnpm
alias px="pnpm dlx"
alias pi="pnpm install"
alias pa="pnpm add"
alias pad="pnpm add --dev"
alias pap="pnpm add --save-peer"
alias pag="pnpm add --global"
alias prm="pnpm remove"
alias pu="pnpm update --interactive"
alias pug="pnpm update --global --interactive"
alias po="pnpm outdated"
alias pd="pnpm dev"
alias ps="pnpm start"
alias pt="pnpm test"
alias pb="pnpm build"
alias paip="pnpm config set auto-install-peers true"
alias pus="corepack use pnpm@latest"
alias pdir="pnpm root -g"

# yarn
alias yx="yarn dlx"
alias yi="yarn install"
alias ya="yarn add"
alias yad="yarn add --dev"
alias yag="yarn global add"
alias yrm="yarn remove"
alias yu="yarn upgrade-interactive"
alias yo="yarn outdated"
alias yd="yarn dev"
alias ys="yarn start"
alias yt="yarn test"
alias yb="yarn build"
alias ynuke="rm -rf node_modules/ yarn.lock"
alias yw="yarn workspace"
alias yus="corepack use yarn@latest"
alias ydir="yarn global dir"

# Rust
alias rb="rustup doc --book"
alias cc="cargo check"
alias cr="cargo run"
alias cb="cargo build"
alias cbr="cargo build --release"

# Xcode
alias xcode-erase-all-simulators="sudo xcrun simctl erase all"
alias xccode-accept-license="sudo xcodebuild -license accept"

# Android Studio
alias adbdark='adb shell "cmd uimode night yes"'
alias adblight='adb shell "cmd uimode night no"'
