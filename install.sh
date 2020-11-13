#!/bin/sh

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

echo "Hello $(whoami)! Let's get you set up... 🚀"
echo ""

# Create Dev directory.
echo 'Creating Dev Directory...'
  dev="$HOME/Dev"
  # The pushd command saves the current working directory in memory so it can be returned to at any time
  pushd .
  # The -p flag will create nested directories, but only if they don't exist already
  mkdir -p $dev
  cd $dev

# Set hostname / computer name.
echo 'Enter a hostname for the new machine (e.g. macbook-pro-name)...'
  read hostname
echo "Setting new hostname to $hostname..."
  scutil --set HostName "$hostname"
  compname=$(sudo scutil --get HostName | tr '-' '.')
echo "Setting computer name to $compname..."
  scutil --set ComputerName "$compname"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$compname"

# Install Xcode command line tools if required -- Credit: https://github.com/alrra/dotfiles/blob/ff123ca9b9b/os/os_x/installs/install_xcode.sh
if ! xcode-select --print-path &> /dev/null; then
    # Prompt user to install the XCode Command Line Tools
    xcode-select --install &> /dev/null
    # Wait until the XCode Command Line Tools are installed
    until xcode-select --print-path &> /dev/null; do
        sleep 5
    done

    print_result $? 'Install XCode Command Line Tools'
    # Prompt user to agree to the terms of the Xcode license
    # https://github.com/alrra/dotfiles/issues/10
    sudo xcodebuild -license
    print_result $? 'Agree with the XCode Command Line Tools licence'
fi

# Setup SSH.
echo "Creating RSA token for SSH..."
  ssh=$HOME/.ssh
  mkdir -p $ssh
  touch $ssh/config
  ssh-keygen -t rsa -b 4096 -C "tom.hendra@outlook.com"
  echo "Host *\n AddKeysToAgent yes\n UseKeychain yes\n IdentityFile $ssh/id_rsa" | tee $ssh/config
  eval "$(ssh-agent -s)"

# Authenticate with GitHub.
echo 'Copying public key to clipboard. Paste it into your GitHub account...'
  pbcopy < $ssh/id_rsa.pub
  open 'https://github.com/account/ssh'

# Install Node.js
echo "installing node (via n-install)..."
  curl -L https://git.io/n-install | bash

echo "node --version: $(node --version)"
echo "npm --version: $(npm --version)"

echo "installing global npm packages..."
  npm install -g serve vercel @sanity/cli parcel-bundler /
  fkill-cli npm-quick-run semantic-release-cli npm-check-updates yarn 

# Install Oh My Zsh.
echo 'Installing Oh My Zsh...'
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Oh My Zsh extensions & theme.
echo 'Installing Oh My Zsh extensions...'  
sh clone-omz-exts.sh

# Configure bat and delta.
echo 'Configureing bat & delta...'  
  mkdir -p "${HOME}/.config/bat/themes"
  git clone https://github.com/batpigandme/night-owlish "${HOME}/.config/bat/themes/night-owlish"
  bat cache --build

# Install Homebrew if not already installed.
if test ! $(which brew); then
  echo 'Installing Homebrew...' 
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# Update Homebrew recipes.
echo 'Updating Homebrew...' 
  brew update

# Install all dependencies with brew bundle.
echo 'Installing Homebrew packages...'
  brew tap homebrew/bundle
  brew bundle

# Install dotfiles & symlink to $HOME.
echo "Cloning dotfiles & symlinking to system..."
  sh clone-dotfiles.sh

# Clone GitHub project repositories into Dev directory.
echo "Cloning project repos..."
  sh clone-projects.sh

# The popd command returns to the path at the top of the directory stack.
echo "Developer environment setup complete."
  popd

# Apply macOS preferences from dotfiles (last because this will reload the shell).
echo "Applying Mac system preferences..."
  source .macos