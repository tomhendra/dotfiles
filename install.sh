#!/bin/sh

# Close any open System Preferences panes, to prevent them from overriding settings we’re about to change.
osascript -e 'tell application "System Preferences" to quit'

echo "Hello $(whoami), let's get you set up! 🚀"

# Ask for the administrator password upfront
sudo -v

# Set hostname / computer name.
echo 'Enter a hostname for the new machine (e.g. Toms-MacBook-Pro)...'
  read hostname
echo "Setting new hostname to $hostname..."
  scutil --set HostName "$hostname"
  compname=$(sudo scutil --get HostName | tr '-' '.')
echo "Setting computer name to $compname..."
  scutil --set ComputerName "$compname"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$compname"

# Install Xcode command line tools if required.
# (Credit: https://github.com/alrra/dotfiles/blob/ff123ca9b9b/os/os_x/installs/install_xcode.sh)
if ! xcode-select --print-path &> /dev/null; then
    # Prompt user to install the Xcode Command Line Tools
    xcode-select --install &> /dev/null
    # Wait until the Xcode Command Line Tools are installed
    until xcode-select --print-path &> /dev/null; do
        sleep 5
    done

    print_result $? 'Install Xcode Command Line Tools'
    # Prompt user to agree to the terms of the Xcode license
    # https://github.com/alrra/dotfiles/issues/10
    sudo xcodebuild -license
    print_result $? 'Agree with the Xcode Command Line Tools licence'
fi

# Setup SSH.
echo "Creating RSA token for SSH..."
  ssh=$HOME/.ssh
  mkdir -p $ssh
  touch $ssh/config
  ssh-keygen -t rsa -b 4096 -C "tom.hendra@outlook.com"
  echo "Host *\n AddKeysToAgent yes\n UseKeychain yes\n IdentityFile $ssh/id_rsa" | tee $ssh/config
  eval "$(ssh-agent -s)"

# Authenticate with GitHub via SSH.
echo 'Copying public key to clipboard. Paste it into your GitHub account...'
  pbcopy < $ssh/id_rsa.pub
  open 'https://github.com/account/ssh'

# Install Node.js.
echo "installing node (via n-install)..."
  curl -L https://git.io/n-install | bash
  echo "node --version: $(node --version)"
  echo "npm --version: $(npm --version)"

# Install global NPM packages.
echo "installing global npm packages..."
  sh npm-g.sh

# Install Homebrew if not already installed.
if test ! $(which brew); then
  echo 'Installing Homebrew...' 
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# Update Homebrew recipes.
echo 'Updating Homebrew...' 
  brew update

# Install dependencies with brew bundle.
echo 'Installing Homebrew packages...'
  brew tap homebrew/bundle
  brew bundle

# Install bat / delta theme.
echo 'Configuring bat & delta...'  
  mkdir -p "${HOME}/.config/bat/themes"
  git clone https://github.com/batpigandme/night-owlish "${HOME}/.config/bat/themes/night-owlish"

# Install Oh My Zsh & plugins.
echo 'Installing Oh My Zsh...'
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  sh clone-omz-exts.sh

# Install dotfiles & symlink.
echo "Cloning dotfiles & symlinking to system..."
  sh clone-dotfiles.sh

# Clone GitHub project repositories into Dev directory.
echo "Cloning project repos..."
  # The -p flag will create nested directories, but only if they don't exist already
  mkdir -p $HOME/Dev
  sh clone-projects.sh

echo "$(whoami)'s developer environment setup is complete! ✅"

# Apply MacOS system preferences from dotfiles (last because this will reload the shell).
echo "Applying Mac system preferences..."
  source .macos