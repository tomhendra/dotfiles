#!/bin/sh

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error when substituting

# Define error message function
error_exit() {
    echo -e "\033[1;31m🚨 Error: $1\033[0m" >&2
    exit 1
}

# Check for required tools
command -v git >/dev/null 2>&1 || error_exit "git is required but not installed"
command -v osascript >/dev/null 2>&1 || error_exit "osascript is required but not installed"

echo "👋 Hello $(whoami)! Let's setup the dev environment for this Mac."

# Close any open System Preferences panes
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Prompt for GitHub login & Xcode installation
osascript -e 'display dialog "🤨 Have you logged in to your GitHub account?" buttons {"YES"}'
osascript -e 'display dialog "🤨 Have you installed Xcode from the App Store & the bundled Command Line Tools?" buttons {"YES"}'
osascript -e 'display dialog "🤨 Have you run the system update to be certain CLT is totally up-to-date?" buttons {"YES"}'

# Check if Xcode Command Line Tools are installed
if ! xcode-select -p &> /dev/null; then
    error_exit "Xcode Command Line Tools not found. Please install them and try again."
fi

# Accept Xcode license
sudo xcodebuild -license accept

# Generate SSH key & authenticate with GitHub
ssh="${HOME}/.ssh"
mkdir -p ${ssh}

echo "🛠️ Generating RSA token for SSH authentication..."
echo "Host *\n PreferredAuthentications publickey\n UseKeychain yes\n IdentityFile ${ssh}/id_rsa\n" > ${ssh}/config
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "tom.hendra@outlook.com"
ssh-agent -s > "${HOME}/.ssh-agent-info"
source "${HOME}/.ssh-agent-info"
ssh-add ~/.ssh/id_rsa
pbcopy < ${ssh}/id_rsa.pub

osascript -e 'display dialog "📋 Public key copied to clipboard. Press OK to add it to GitHub..." buttons {"OK"}'
open https://github.com/settings/keys
osascript -e 'display dialog "🔑 Press OK after you have added the SSH key to your GitHub account..." buttons {"OK"}'

ssh -T git@github.com || error_exit "Failed to authenticate with GitHub"

# Define dotfiles path variable
dotfiles="${HOME}/.dotfiles"

# Clone dotfiles repo
echo '🛠️ Cloning dotfiles...'
git clone git@github.com:tomhendra/dotfiles.git ${dotfiles} || error_exit "Failed to clone dotfiles repository"

# Create ~/Developer directory & clone GitHub project repos into it
echo '🛠️ Cloning GitHub repos into Developer...'
mkdir -p ${HOME}/Developer
sh ${dotfiles}/git/get_repos.sh || error_exit "Failed to clone GitHub repositories"

# Homebrew
if test ! $(which brew); then
    echo '🛠️ Installing Homebrew...'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error_exit "Failed to install Homebrew"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> "${HOME}/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Homebrew packages & apps with brew bundle.
echo '🛠️ Installing Homebrew brews & casks...'
brew update
brew tap homebrew/bundle
brew bundle --file=${dotfiles}/Brewfile || error_exit "Failed to install Homebrew packages"
brew cleanup

# Rust
echo "🛠️ Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh || error_exit "Failed to install Rust"
. "$HOME/.cargo/env"

# Solana
echo "🛠️ Installing Solana..."
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)" || error_exit "Failed to install Solana"
source ~/.zshrc

# Anchor
echo "🛠️ Installing Anchor..."
cargo install --git https://github.com/coral-xyz/anchor avm --force
avm --version
avm install latest

# Node.js
echo "🛠️ Installing Node.js..."
# pnpm
curl -fsSL https://get.pnpm.io/install.sh | sh - || error_exit "Failed to install pnpm"
[ -f "${HOME}/.zshrc" ] && source "${HOME}/.zshrc"
# Node LTS
pnpm env use -g lts || error_exit "Failed to install Node.js LTS"

# Global packages
echo '🛠️ Installing global Node.js dependencies...'
sh ${dotfiles}/global_pkg.sh || error_exit "Failed to install global Node.js packages"

# config Starship
cp ${dotfiles}/starship.toml ${HOME}/.config

# config bat
# mkdir -p "$(bat --config-dir)/themes"
# cp ${dotfiles}/bat/themes/Enki-Tokyo-Night.tmTheme "$(bat --config-dir)/themes"
# cp ${dotfiles}/bat/bat.conf "$(bat --config-dir)"
# bat cache --build

# Symlinks from custom dotfiles, overwrite system defaults
echo '🛠️ Creating symlinks from dotfiles...'
sh ${dotfiles}/create_symlinks.sh || error_exit "Failed to create symlinks"

echo "✅ $(whoami)'s developer environment setup is complete!"
