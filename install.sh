#!/bin/sh

echo "👋 Hello $(whoami)! Let's setup the dev environment for this Mac."

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'
# Ask for the administrator password upfront
sudo -v
# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

read -p "🤨 Have you logged in to your GitHub account? Press any key to confirm..."
read -p "🤨 Have you installed Xcode from the App Store & the bundled Command Line Tools? Press any key to confirm..."

# Accept Xcode license
sudo xcodebuild -license accept

# Generate SSH key & authenticate with GitHub
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

# Define dotfiles path variable.
dotfiles="${HOME}/.dotfiles"

# Clone dotfiles repo.
echo '🛠️ Cloning dotfiles...'
 git clone git@github.com:tomhendra/dotfiles.git ${dotfiles}

# Create ~/Developer directory & Clone GitHub project repos into it.
echo '🛠️ Cloning GitHub repos into Developer...'
mkdir -p ${HOME}/Developer
  sh ${dotfiles}/git/get_repos.sh

# Install Homebrew.
 if test ! $(which brew); then
   echo '🛠️ Installing Homebrew...' 
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/tom/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
 fi

# Install Homebrew packges & apps with brew bundle.
echo '🛠️ Installing Homebrew packages, fonts and applications...'
  brew update
  brew tap homebrew/bundle
  brew bundle --file=${dotfiles}/Brewfile
  brew cleanup

# Quicklook plugins: remove the quarantine attribute (https://github.com/sindresorhus/quick-look-plugins)
echo '🛠️ Removing quarantine attribute from Quicklook plugins...' 
  xattr -d -r com.apple.quarantine ${HOME}/Library/QuickLook

# Bat colour theme
echo '🛠️ Installing colour theme for bat...'
  mkdir -p ~/.config/bat/themes
  cp ${dotfiles}/Enki-Tokyo-night.tmTheme ~/.config/bat/themes/Enki-Tokyo-Night.tmTheme
  bat cache --build

# Install Node.
echo "🛠️ Installing Node.js..."
  # ensure n is available after brew install
  until n --version
    do
      source ${HOME}/.zshrc
    done
  # take ownership of n
  sudo chown -R $(whoami) /usr/local/n
  # make sure the required folders exist (safe to execute even if they already exist)
  sudo mkdir -p /usr/local/bin /usr/local/lib /usr/local/include /usr/local/share
  # take ownership of Node.js install destination folders
  sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/include /usr/local/share
  # install Node.js
  sudo n lts

# Install global npm packages
echo '🛠️ Installing global npm packages...'
  sh ${dotfiles}/global_pkg.sh

# Enable corepack
echo "🛠️ Enabling corepack for Yarn & pnpm use..."
  corepack enable

# iOS platform environment
echo '🛠️ Installing iOS platform for Simulator...'
  xcodebuild -downloadPlatform iOS

# Create symlinks from custom dotfiles, overwriting system defaults.
echo '🛠️ Creating symlinks from dotfiles...' 
  sh ${dotfiles}/create_symlinks.sh

echo "✅ $(whoami)'s developer environment setup is complete!"
