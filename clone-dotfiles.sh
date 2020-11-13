#!/bin/sh

dotfiles="$HOME/.dotfiles"

# Clone dotfiles repo to .dotfiles in $HOME.
git clone git@github.com:tomhendra/dotfiles.git $dotfiles

# Symlink .zshrc config.
rm -rf $HOME/.zshrc
ln -s $dotfiles/.zshrc $HOME/.zshrc

# Symlink Powerlevel10K config.
rm -rf $HOME/.p10k.zsh
ln -s $dotfiles/.p10k.zsh $HOME/.p10k.zsh

# Symlink bat config.
ln -s $dotfiles/bat.cfg ${HOME}/.config/bat/config

# Symlink Mackup config.
ln -s $dotfiles/.mackup.cfg $HOME/.mackup.cfg

# Symlink git files.
ln -s $dotfiles/.gitconfig $HOME/.gitconfig
ln -s $dotfiles/.gitignore_global $HOME/.gitignore_global