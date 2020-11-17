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
  echo 'Installing Xcode Command Line Tools...'
  xcode-select --install &> /dev/null
  # Wait until the Xcode Command Line Tools are installed
  until xcode-select --print-path &> /dev/null; do
      sleep 8
  done
fi

# Install or update Homebrew.
if test ! $(which brew); then
  echo 'Installing Homebrew...' 
   bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
  # Update Homebrew recipes.
  echo 'Updating Homebrew...' 
    brew update
fi

# Install paackges & apps with brew bundle.
echo 'Installing applications...'
  brew tap homebrew/bundle
  brew bundle

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
  sh npm-g.sh

# Generate SSH key pair for GitHub authentication.
ssh="${HOME}/.ssh"
echo "Generating RSA token for SSH..."
  mkdir -p ${ssh} && touch ${ssh}/config
  echo "Host *\n AddKeysToAgent yes\n UseKeychain yes\n IdentityFile ${ssh}/id_rsa" >> ${ssh}/config
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "tom.hendra@outlook.com"
  eval "$(ssh-agent -s)"
# Authenticate with GitHub.
echo 'Public key copied to clipboard. Paste it into your GitHub account...'
  pbcopy < ${ssh}/id_rsa.pub
  open 'https://github.com/account/ssh'

# Create Dev directory & Clone GitHub project repos.
echo 'Downloading project repos...'
  # The -p flag will create nested directories, but only if they don't exist already
  mkdir -p ${HOME}/Dev
  sh clone-projects.sh

# Clone dotfiles repo & symlink.
echo 'Downloading dotfiles repo & symlinking to system...'
  git clone git@github.com:tomhendra/dotfiles.git ${HOME}/.dotfiles
  sh symlink-dotfiles.sh

# Install the Night Owl theme for bat / delta.
echo 'Configuring bat & delta...'  
  git clone https://github.com/batpigandme/night-owlish "${HOME}/.config/bat/themes/night-owlish"
  bat cache --build

# # Install the Night Owl theme for iTerm
# echo 'Insalling iTerm2 theme...'
  # file="${HOME}/Downloads/Night Owl.itermcolors"
  # curl https://raw.githubusercontent.com/jsit/night-owl-iterm2-theme/master/themes/Night%20Owl.itermcolors -s -o ${file}
  # open ${file}
  # rm -rf ${file}

echo "$(whoami)'s developer environment setup is complete! ✅"

# Apply macOS system preferences from dotfiles (last because this will reload the shell).
echo 'Applying Mac system preferences...'
  source .macos