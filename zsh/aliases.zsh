# General
alias brewup="brew upgrade && brew cleanup && brew doctor"
alias c="code ."
alias chrome="open -a 'Google Chrome'"
alias firefox="open -a 'Firefox Developer Edition'"
alias cafe="caffeinate -u -t 3600"
alias copyssh="pbcopy < ${HOME}/.ssh/id_rsa.pub"
alias flushdns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias pingg="echo 'tom: Pinging Google' && ping www.google.com";
alias reloadzsh="source ${HOME}/.zshrc"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
alias balk="echo 'ಠ_ಠ' | pbcopy"
alias strong='ᕦ(ಠ_ಠ)ᕤ'
alias rage="echo '(╯°□°）╯︵ ┻━┻' | pbcopy"
alias cheer="echo '✧*｡٩(ˊᗜˋ*)و✧*｡' | pbcopy"
alias wen="echo 'https://tenor.com/view/when-wen-naru-yummi-yummi-universe-gif-23030317' | pbcopy"
alias sol="echo '◎' | pbcopy"
alias stx="echo 'Ӿ' | pbcopy"
alias refresh-dock-icons="rm /var/folders/*/*/*/com.apple.dock.iconcache; killall Dock"

# Files & Directories
alias ..="cd .."
alias dl="cd ${HOME}/Downloads"
alias dv="cd ${DEVELOPER}"
alias w3="cd ${DEVELOPER}/web3"
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
alias gd="git diff"
alias gl="git log --oneline --decorate --color"
alias gb="git branch"
alias gc="git checkout"
alias gabandon="git checkout -- ."
alias gcom="git add . && git commit -m"
alias resolve="git add . && git commit --no-edit"
alias amend="git add . && git commit --amend --no-edit"
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

# pnpm
alias enable-pnpm="corepack prepare pnpm@latest --activate"
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
alias pults="pnpm env use --global lts"
alias pulatest="pnpm env use --global latest"
alias pdir="cd $PNPM_HOME"
alias paip="pnpm config set auto-install-peers true"
alias pt="pnpm t"
alias pnx="pnpm nx"

# Deno
alias dts="deno task start"
alias dtc="deno task check"
alias dtb="deno task build"
alias dtp="deno task preview"
alias dtu="deno task update"

# Bun
alias br="bun run"

# Xcode
alias simulator-erase-all-devices="sudo xcrun simctl erase all"
alias accept-license="sudo xcodebuild -license accept"
