#!/bin/sh

dotfiles="${HOME}/.dotfiles"

# Clone dotfiles repo to .dotfiles in home dir.
git clone git@github.com:tomhendra/dotfiles.git ${dotfiles}

# Symlink bat config.
ln -s ${dotfiles}/bat.cfg ${HOME}/.config/bat/config
bat cache --build

# Symlink git files.
ln -s ${dotfiles}/.gitconfig ${HOME}/.gitconfig
ln -s ${dotfiles}/.gitignore_global ${HOME}/.gitignore_global

# Symlink Mackup config.
ln -s ${dotfiles}/.mackup.cfg ${HOME}/.mackup.cfg

# Symlink Powerlevel10K config.
rm -rf ${HOME}/.p10k.zsh
ln -s ${dotfiles}/.p10k.zsh ${HOME}/.p10k.zsh

# Symlink .zshrc config.
rm -rf ${HOME}/.zshrc
ln -s ${dotfiles}/.zshrc ${HOME}/.zshrc