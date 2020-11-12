#!/usr/bin/env zsh

# Set machine hostname.
echo 'Enter new hostname of the machine (e.g. macbook-pro-name)'
  read hostname
  echo "Setting new hostname to $hostname..."
  scutil --set HostName "$hostname"
  compname=$(sudo scutil --get HostName | tr '-' '.')
  echo "Setting computer name to $compname..."
  scutil --set ComputerName "$compname"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$compname"

# Setup SSH.
pub=$HOME/.ssh/id_ed25519.pub
echo 'Checking for SSH key, generating one if required...'
  [[ -f $pub ]] || ssh-keygen -t ed25519

# Authenticate with GutHub.
echo 'Copying public key to clipboard. Paste it into your GitHub account...'
  [[ -f $pub ]] && cat $pub | pbcopy
  open 'https://github.com/account/ssh'

# If system is MacOS, install Homebrew.
if [[ `uname` == 'Darwin' ]]; then
  which -s brew
  if [[ $? != 0 ]]; then
    echo 'Installing Homebrew...'
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install Homebrew packages.
brew install diff-so-fancy gnupg htop node pbzip2 python python@2 ruby postgresql wget

# Install Homebrew casks.
# echo 'Installing Homebrew casks...'
#   brew tap phinze/homebrew-cask
#   brew install caskroom/cask/brew-cask
#   brew cask install suspicious-package quicklook-json qlmarkdown qlstephen qlcolorcode
# fi

# Install applications.
# echo 'Installing applications to MacOs...'

# Apply MacOS system preferences.
echo 'Applying system preferences...'
  source 'macos-settings.sh'

# Symlink dotfiles config to home directory files.
echo 'Symlinking config files...'
  source 'symlink-dotfiles.sh'

popd
