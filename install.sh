#!/bin/sh

echo "Hello $(whoami), let's setup your developer environment! 🚀"

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'
# Ask for the administrator password upfront
sudo -v
# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Install Xcode CLT if required.
if ! xcode-select --print-path &> /dev/null; then
  echo 'Installing Xcode CLT. Close dialog box once complete...'
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

# Update Homebrew recipes.
echo 'Updating Homebrew...' 
  brew update

# Install Node via n-install to ~/.n directory.
echo "installing Node via n-install..."
  curl -L https://git.io/n-install | N_PREFIX=${HOME}/.n bash -s -- -y lts latest

# Generate SSH key pair for GitHub authentication.
ssh="${HOME}/.ssh"
echo "Generating RSA token for SSH..."
  mkdir -p ${ssh}
  echo "Host *\n AddKeysToAgent yes\n UseKeychain yes\n IdentityFile ${ssh}/id_rsa" > ${ssh}/config
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "tom.hendra@outlook.com"
  eval "$(ssh-agent -s)"
# Authenticate with GitHub.
echo 'Public key copied to clipboard. Paste it into your GitHub account...'
  pbcopy < ${ssh}/id_rsa.pub
  open 'https://github.com/account/ssh'

# dotfiles path variable to be used throughout the rest of this script.
dotfiles="${HOME}/.dotfiles"

# Clone dotfiles repo containing additional installation scripts. 
echo 'Downloading dotfiles repo...'
  git clone git@github.com:tomhendra/dotfiles.git ${dotfiles}

# Clone GitHub project repos to ~/Dev directory.
echo 'Downloading project repos...'
  mkdir -p ${HOME}/Dev
  sh ${dotfiles}/git/clone-projects.sh

# Install Homebrew paackges & apps with brew bundle.
echo 'Installing Homebrew packages, fonts and applications...'
  brew tap homebrew/bundle
  brew bundle --file=${dotfiles}/Brewfile
  brew cleanup

# Quicklook plugins: remove the quarantine attribute (https://github.com/sindresorhus/quick-look-plugins)
echo 'Removing quarantine from Quicklook plugins...' 
  xattr -d -r com.apple.quarantine ${HOME}/Library/QuickLook

# Create symlinks from dotfiles.
echo 'Creating symlinks...'
  sh ${dotfiles}/create-symlinks.sh

# reload .zshrc to use of Node via n.
. ${HOME}/.zshrc

# Install global NPM packages.
echo 'Installing NPM packages...'
  sh ${dotfiles}/install-npm-global.sh

# Install the Night Owl theme for bat / delta.
echo 'Configuring bat & delta...'  
  git clone https://github.com/batpigandme/night-owlish "${HOME}/.config/bat/themes/night-owlish"
  bat cache --build

echo "$(whoami)'s developer environment setup is complete! ✅"

# Apply macOS system preferences from dotfiles (this will reload the shell).
echo 'Applying System Preferences. Restart terminal when it closes...'
  source ${dotfiles}/.macos