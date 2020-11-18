#!/bin/sh

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

echo "Hello $(whoami), let's setup your developer environment! 🚀"

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

# Clone dotfiles repo containing additional scripts & Brewfile. 
echo 'Downloading dotfiles repo...'
  git clone git@github.com:tomhendra/dotfiles.git ${dotfiles}

# Create Dev directory & Clone GitHub project repos.
echo 'Downloading project repos...'
  mkdir -p ${HOME}/Dev
  sh ${dotfiles}/git/clone-projects.sh

# Install paackges & apps with brew bundle.
echo 'Installing Homebrew packages, fonts and applications...'
  brew tap homebrew/bundle
  brew bundle --file=${dotfiles}/Brewfile

# Quicklook plugins: remove the quarantine attribute 9https://github.com/sindresorhus/quick-look-plugins)
echo 'Removing quarantine from Quicklook plugins...' 
  xattr -d -r com.apple.quarantine ${HOME}/Library/QuickLook

# Configure Node version management with n via Homebrew.
echo 'Configuring Node version management...'
  # Prevent Homebrew from updating the Node formula.
  brew pin node
  # To avoid requiring sudo for n and npm global installs (https://github.com/tj/n/blob/master/README.md#installation)
  # Make cache folder and take ownership.
  sudo mkdir -p /usr/local/n
  sudo chown -R $(whoami) /usr/local/n
  # Take ownership of node install destination folders.
  sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/include /usr/local/share

# Install global NPM packages.
echo 'Installing NPM packages...'
  sh ${dotfiles}/install-npm-global.sh

# Create symlinks from dotfiles.
echo 'Creating symlinks...'
  sh ${dotfiles}/create-symlinks.sh

# Install the Night Owl theme for bat / delta.
echo 'Configuring bat & delta...'  
  git clone https://github.com/batpigandme/night-owlish "${HOME}/.config/bat/themes/night-owlish"
  bat cache --build

echo "$(whoami)'s developer environment setup is complete! ✅"

# Apply macOS system preferences from dotfiles (this will reload the shell).
echo 'Applying System Preferences. Restart terminal when it closes...'
  source ${dotfiles}/.macos