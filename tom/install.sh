#!/bin/sh

# Check shell is set to zsh.
[ "${SHELL##/*/}" != "zsh" ] && echo 'You may need to set the default shell to zsh: `chsh -s /bin/zsh`'

# Create Dev directory, clone dotfiles repo & create hidden .dotfiles directory.
dir="$HOME/Dev"
mkdir -p $dir
cd $dir
git clone --recursive https://github.com/tomhendra/dotfiles.git
mv dotfiles .dotfiles
cd .dotfiles

# Bootstrap system
echo 'Setting up system...'
sh etc/bootstrap-macos.sh
echo 'System setup complete.'
