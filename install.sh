#!/bin/sh

echo "👋 Hello $(whoami)! Let's setup the dev environment for this Mac."

# close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'
# ask for the administrator password upfront
sudo -v
# keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

read -p "🤨 Have you logged in to your GitHub account? Press any key to confirm..."
read -p "🤨 Have you installed Xcode from the App Store & the bundled Command Line Tools? Press any key to confirm..."

# accept Xcode license
sudo xcodebuild -license accept

# generate SSH key & authenticate with GitHub
ssh="${HOME}/.ssh"
mkdir -p ${ssh}

echo "🛠️ Generating RSA token for SSH authentication..."
  echo "Host *\n PreferredAuthentications publickey\n UseKeychain yes\n IdentityFile ${ssh}/id_rsa\n" > ${ssh}/config
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "tom.hendra@outlook.com"
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_rsa
  pbcopy < ${ssh}/id_rsa.pub
  read -p "📋 Public key copied to clipboard. Press any key to add it to GitHub..."
  open https://github.com/settings/keys
  read -p "🔑 Press any key to authenticate with GitHub using your new SSH key..."
  ssh -T git@github.com

# define dotfiles path variable
dotfiles="${HOME}/.dotfiles"

# clone dotfiles repo
echo '🛠️ Cloning dotfiles...'
 git clone git@github.com:tomhendra/dotfiles.git ${dotfiles}

# create ~/Developer directory & clone GitHub project repos into it
echo '🛠️ Cloning GitHub repos into Developer...'
mkdir -p ${HOME}/Developer
  sh ${dotfiles}/git/get_repos.sh

# Homebrew
 if test ! $(which brew); then
   echo '🛠️ Installing Homebrew...'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/tom/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
 fi

# Homebrew packges & apps with brew bundle.
echo '🛠️ Installing Homebrew brews & casks...'
  brew update
  brew tap homebrew/bundle
  brew bundle --file=${dotfiles}/Brewfile
  brew cleanup

# Node.js
echo "🛠️ Installing Node.js..."
  # pnpm
  curl -fsSL https://get.pnpm.io/install.sh | sh -
  source ${HOME}/.zshrc
  # node lts
  pnpm env use -g lts

# global packages
echo '🛠️ Installing global Node.js dependencies...'
  sh ${dotfiles}/global_pkg.sh

# iOS platform environment
echo '🛠️ Installing iOS platform for Simulator...'
  xcodebuild -downloadPlatform iOS

# bat colour theme
echo '🛠️ Creating directory for bat theme...'
  mkdir -p ~/.config/bat/themes
  cp ~/.dotfiles/Enki-Tokyo-night.tmTheme ~/.config/bat/themes/Enki-Tokyo-Night.tmTheme
  bat cache --build

# symlinks from custom dotfiles, overwrite system defaults
echo '🛠️ Creating symlinks from dotfiles...'
  sh ${dotfiles}/create_symlinks.sh

echo "✅ $(whoami)'s developer environment setup is complete!"
