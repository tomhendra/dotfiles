#!/bin/sh

echo "🚀 Hello $(whoami), let's setup your developer environment!"

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'
# Ask for the administrator password upfront
sudo -v
# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Install Xcode CLT as required by Homebrew.
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

# Install LTS & latest versions of Node via n-install to custom .n directory.
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

# dotfiles path variable.
dotfiles="${HOME}/.dotfiles"

# Clone dotfiles repo. 
echo 'Cloning dotfiles...'
  git clone git@github.com:tomhendra/dotfiles.git ${dotfiles}

# Install Homebrew packges & apps with brew bundle.
echo 'Installing Homebrew packages, fonts and applications...'
  brew update
  brew tap homebrew/bundle
  brew bundle --file=${dotfiles}/Brewfile
  brew cleanup

# Create symlinks from dotfiles.
echo 'Creating symlinks from dotfiles...' 
  sh ${dotfiles}/create-symlinks.sh

# Quicklook plugins: remove the quarantine attribute (https://github.com/sindresorhus/quick-look-plugins)
echo 'Removing quarantine attribute from Quicklook plugins...' 
  xattr -d -r com.apple.quarantine ${HOME}/Library/QuickLook

# Install global NPM packages.
echo 'Installing global npm packages...'
  # reload .zshrc to use Node & npm via n.
  . ${HOME}/.zshrc
  sh ${dotfiles}/install-npm-global.sh

# Create ~/Dev directory & Clone GitHub project repos into it.
echo 'Cloning GitHub repos into Dev...'
  mkdir -p ${HOME}/Dev
  sh ${dotfiles}/git/clone-projects.sh

echo "✅ $(whoami)'s developer environment setup is complete!"

# Apply macOS system preferences from dotfiles (this will reload the shell).
echo 'Applying System Preferences. Restart terminal when it closes...'
  source ${dotfiles}/.macos