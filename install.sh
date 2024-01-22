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
read -p "🤨 Have you installed Xcode Command Line Tools manually from https://developer.apple.com/download/all/ ? Press any key to confirm..."

# Accept Xcode license
sudo xcodebuild -license accept

# Not working for M2 + fresh install Sonoma! 🙁
# Install Xcode CLT as required by Homebrew.
# if ! xcode-select --print-path &> /dev/null; then
#   echo '🛠️ Installing Xcode CLT. Close the dialog box once complete...'
#     xcode-select --install &> /dev/null
#     # Wait until the Xcode Command Line Tools are installed
#     until xcode-select --print-path &> /dev/null; do
#       sleep 8
#     done
#  fi
#  read -p "🤨 Has Xcode finished to install? Press any key to confirm..."

# Generate SSH key & authenticate with GitHub
ssh="${HOME}/.ssh"
mkdir -p ${ssh}

echo "🛠️ Generating RSA token for SSH authentication..."
  echo "Host *\n PreferredAuthentications publickey\n UseKeychain yes\n IdentityFile ${ssh}/id_rsa\n" > ${ssh}/config
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "tom.hendra@wembleystudios.com"
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

# Install Bun
echo "🛠️ Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  until bun -v
  do
    source ${HOME}/.zshrc
  done

# Install global npm packages.
echo '🛠️ Installing global packages with bun...'
  sh ${dotfiles}/global_pkg.sh

# Install & load nvm
echo "🛠️ Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
  until nvm --version
  do
    source ${HOME}/.zshrc
  done
echo "🛠️ Loading nvm..."
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install node
echo "🛠️ Installing Node..."
  nvm install --lts

# Enable corepack
echo "🛠️ Enabling corepack..."
  corepack enable

# Install Yarn
echo "🛠️ Activating Yarn..."
  corepack prepare yarn@stable --activate

# Install pnpm
echo "🛠️ Activating pnpm..."
  corepack prepare pnpm@latest --activate

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

# iOS platform environment
echo '🛠️ Installing iOS platform for Simulator...'
  xcodebuild -downloadPlatform iOS

# Create symlinks from custom dotfiles, overwriting system defaults.
echo '🛠️ Creating symlinks from dotfiles...' 
  sh ${dotfiles}/create_symlinks.sh

echo "✅ $(whoami)'s developer environment setup is complete!"

