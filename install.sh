#!/bin/sh

echo "👋 Hello $(whoami)! Let's setup the developer environment for this Mac."

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'
# Ask for the administrator password upfront
sudo -v
# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Generate SSH keys for GitHub authentication
ssh="${HOME}/.ssh"
mkdir -p ${ssh}

echo "Generating RSA token for SSH authentication..."
  echo "Host github.com\n HostName github.com\n User git\n PreferredAuthentications publickey\n AddKeysToAgent yes\n UseKeychain yes\n IdentityFile ${ssh}/id_rsa\n" > ${ssh}/config
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "tom.hendra@outlook.com"
  eval "$(ssh-agent -s)"

echo 'Public key copied to clipboard. Paste it into your GitHub account for tomhendra - then logout in preparation for the next key...'
  pbcopy < ${ssh}/id_rsa.pub
  open 'https://github.com/account/ssh'

# Define dotfiles path variable.
dotfiles="${HOME}/.dotfiles"

# Clone dotfiles repo. 
echo 'Cloning dotfiles...'
  git clone git@github.com:tomhendra/dotfiles.git ${dotfiles}

# Create ~/Developer directory & Clone GitHub project repos into it.
echo 'Cloning GitHub repos into Developer...'
  mkdir -p ${HOME}/Developer
  sh ${dotfiles}/git/projects.sh

# Install pnpm
echo "installing pnpm..."
  curl -fsSL https://get.pnpm.io/install.sh | sh -

# Install node via pnpm
echo "installing Node..."
  pnpm env use --global lts

# Install global  packages.
echo 'Installing global packages...'
# reload .zshrc to use pnpm / Node
. ${HOME}/.zshrc
sh ${dotfiles}/global-pkg.sh

# Install Rust via rustup
echo "installing Rust..."
  curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh

# Install Xcode CLT as required by Homebrew.
if ! xcode-select --print-path &> /dev/null; then
  echo 'Installing Xcode CLT. Close the dialog box once complete...'
  xcode-select --install &> /dev/null
  # Wait until the Xcode Command Line Tools are installed
  until xcode-select --print-path &> /dev/null; do
      sleep 8
  done
fi

# Install Homebrew.
if test ! $(which brew); then
  echo 'Installing Homebrew...' 
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# Install Homebrew packges & apps with brew bundle.
echo 'Installing Homebrew packages, fonts and applications...'
  brew update
  brew tap homebrew/bundle
  brew bundle --file=${dotfiles}/Brewfile
  brew cleanup

# Quicklook plugins: remove the quarantine attribute (https://github.com/sindresorhus/quick-look-plugins)
echo 'Removing quarantine attribute from Quicklook plugins...' 
  xattr -d -r com.apple.quarantine ${HOME}/Library/QuickLook

# Bat colour theme
echo 'Installing colour stheme for bat...'
  mkdir -p ~/.config/bat/themes
  cp ${dotfiles}/Enki-Tokyo-night.tmTheme ~/.config/bat/themes/Enki-Tokyo-Night.tmTheme
  bat cache --build

# Create symlinks from custom dotfiles, overwriting system defaults.
echo 'Creating symlinks from dotfiles...' 
  sh ${dotfiles}/create-symlinks.sh

echo "✅ $(whoami)'s developer environment setup is complete!"

# Apply macOS system preferences from dotfiles (this will reload the shell).
echo 'Applying System Preferences. Restart terminal when it closes...'
  source ${dotfiles}/.macos